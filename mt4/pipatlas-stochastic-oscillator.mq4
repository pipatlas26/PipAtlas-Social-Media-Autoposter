//+------------------------------------------------------------------+
//|                                  PipAtlas Stochastic Oscillator  |
//|                                     https://pipatlas.com/tools    |
//|  Draws the stochastic oscillator (%K / %D) with overbought and    |
//|  oversold bands, plus an optional higher-timeframe trend filter.  |
//|  Education only, never financial advice.                          |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.01"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_label1  "%K"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2

#property indicator_label2  "%D"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

input int    InpKPeriod   = 14;     // %K period
input int    InpSlowing   = 3;      // %K slowing
input int    InpDPeriod   = 3;      // %D period
input double InpOverbought= 80.0;   // Overbought level
input double InpOversold  = 20.0;   // Oversold level
input bool   InpShowBands = true;   // Draw the 80/20 bands
input bool   InpUseHtf    = false;  // Only signal with a higher-TF trend
input ENUM_TIMEFRAMES InpHtf = PERIOD_H4; // Higher timeframe

// %K = 100 * (Close - LowestLow) / (HighestHigh - LowestLow), smoothed.
// %D = SMA(%K, InpDPeriod). Readings above 80 mean price is closing near
// the top of its recent range; in a trend they persist, which is the whole
// reason a trend filter is offered here. Nothing in the formula knows about
// trends, volume or news — it is a position-in-range gauge.

double Kbuf[];
double Dbuf[];
string gPrefix = "PASTOCH_";

int OnInit()
{
   SetIndexBuffer(0, Kbuf);
   SetIndexBuffer(1, Dbuf);
   IndicatorSetString(INDICATOR_SHORTNAME, "PipAtlas Stochastic(" + IntegerToString(InpKPeriod) + "," + IntegerToString(InpSlowing) + "," + IntegerToString(InpDPeriod) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, 1);
   IndicatorSetDouble(INDICATOR_LEVEL1, InpOversold);
   IndicatorSetDouble(INDICATOR_LEVEL2, InpOverbought);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR1, clrSilver);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR2, clrSilver);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, gPrefix);
}

double HighestHigh(const int shift, const int period)
{
   double v = -DBL_MAX;
   for(int i = 0; i < period; i++){ double h = High[shift + i]; if(h > v) v = h; }
   return v;
}
double LowestLow(const int shift, const int period)
{
   double v = DBL_MAX;
   for(int i = 0; i < period; i++){ double l = Low[shift + i]; if(l < v) v = l; }
   return v;
}

double RawK(const int shift)
{
   const double hh = HighestHigh(shift, InpKPeriod);
   const double ll = LowestLow(shift, InpKPeriod);
   return (hh - ll) > 0.0 ? 100.0 * (Close[shift] - ll) / (hh - ll) : 50.0;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   const int warmup = InpKPeriod + InpSlowing + InpDPeriod;
   if(rates_total < warmup + 2) return 0;

   /* MQL4 indicators are handed the series form (index 0 = newest bar), and the
      buffers are series as well, so one descending loop keeps every array on the
      same index. */
   int limit = rates_total - prev_calculated;
   if(prev_calculated == 0) limit = rates_total - warmup - 1;
   if(limit > rates_total - warmup - 1) limit = rates_total - warmup - 1;

   for(int i = limit; i >= 0 && !IsStopped(); i--)
   {
      /* %K is the slowing average of the raw stochastic over the last InpSlowing bars */
      double sum = 0.0;
      for(int j = 0; j < InpSlowing; j++) sum += RawK(i + j);
      Kbuf[i] = sum / InpSlowing;

      /* %D is the SMA of %K, including the bar being calculated */
      double dsum = 0.0;
      for(int j = 0; j < InpDPeriod; j++) dsum += Kbuf[i + j];
      Dbuf[i] = dsum / InpDPeriod;

      if(InpShowBands && i == 0)
      {
         ObjectDelete(0, gPrefix + "OB");
         ObjectDelete(0, gPrefix + "OS");
      }
   }

   /* an honest signal needs context: a cross inside a zone, in the direction of
      the higher-timeframe trend when the filter is on. Logged rather than fired as
      an alert, so it cannot be mistaken for a trading system. */
   if(prev_calculated != rates_total)
   {
      const bool crossUp = Kbuf[0] > Dbuf[0] && Kbuf[1] <= Dbuf[1];
      const bool crossDn = Kbuf[0] < Dbuf[0] && Kbuf[1] >= Dbuf[1];
      bool trendOk = true;
      if(InpUseHtf)
      {
         double htfClose = iClose(Symbol(), InpHtf, 0);
         double htfMa    = iMA(Symbol(), InpHtf, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
         trendOk = (htfClose > htfMa && crossUp) || (htfClose < htfMa && crossDn);
      }
      if(trendOk && crossUp && Kbuf[0] < InpOversold)
         Print("PipAtlas Stochastic: %K crossed above %D from the oversold zone on ", Symbol(), " ", EnumToString((ENUM_TIMEFRAMES)Period()));
      if(trendOk && crossDn && Kbuf[0] > InpOverbought)
         Print("PipAtlas Stochastic: %K crossed below %D from the overbought zone on ", Symbol(), " ", EnumToString((ENUM_TIMEFRAMES)Period()));
   }
   return(rates_total);
}
