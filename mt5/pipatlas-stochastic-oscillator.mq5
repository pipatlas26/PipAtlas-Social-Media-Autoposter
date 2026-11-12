//+------------------------------------------------------------------+
//|                                  PipAtlas Stochastic Oscillator  |
//|                                     https://pipatlas.com/tools    |
//|  Draws the stochastic oscillator (%K / %D) with overbought and    |
//|  oversold bands, plus an optional higher-timeframe trend filter.  |
//|  Education only, never financial advice.                          |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_height 20
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
// reason a trend filter is offered here.

double Kbuf[];
double Dbuf[];
string gPrefix = "PASTOCH_";

int OnInit()
{
   SetIndexBuffer(0, Kbuf, INDICATOR_DATA);
   SetIndexBuffer(1, Dbuf, INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME, "PipAtlas Stochastic(" + IntegerToString(InpKPeriod) + "," + IntegerToString(InpSlowing) + "," + IntegerToString(InpDPeriod) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, 1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpKPeriod + InpSlowing + InpDPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpKPeriod + InpSlowing + InpDPeriod);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, gPrefix);
}

double HighestHigh(const double &hgh[], const int idx, const int period)
{
   double v = -DBL_MAX;
   for(int i = 0; i < period; i++)
   {
      if(idx - i < 0) break;
      if(hgh[idx - i] > v) v = hgh[idx - i];
   }
   return v;
}
double LowestLow(const double &low[], const int idx, const int period)
{
   double v = DBL_MAX;
   for(int i = 0; i < period; i++)
   {
      if(idx - i < 0) break;
      if(low[idx - i] < v) v = low[idx - i];
   }
   return v;
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
   const int start = (prev_calculated > 1 ? prev_calculated - 1 : InpKPeriod + InpSlowing + InpDPeriod);
   if(rates_total < InpKPeriod + InpSlowing + InpDPeriod + 2) return 0;

   for(int bar = start; bar < rates_total; bar++)
   {
      /* the raw stochastic for every bar needed by the slowing average */
      double raw[64];
      const int need = MathMin(InpSlowing, 64);
      for(int j = 0; j < need; j++)
      {
         const int idx = bar - j;
         if(idx < InpKPeriod - 1) { raw[j] = 50.0; continue; }
         const double hh = HighestHigh(high, idx, InpKPeriod);
         const double ll = LowestLow(low, idx, InpKPeriod);
         raw[j] = (hh - ll) > 0.0 ? 100.0 * (close[idx] - ll) / (hh - ll) : 50.0;
      }
      double sum = 0.0;
      for(int j = 0; j < need; j++) sum += raw[j];
      Kbuf[bar] = sum / need;

      /* %D is the SMA of %K */
      double dsum = 0.0;
      bool ok = true;
      for(int j = 0; j < InpDPeriod; j++)
      {
         if(bar - j - 1 < 0){ ok = false; break; }
         dsum += Kbuf[bar - j - 1];
      }
      Dbuf[bar] = ok ? dsum / InpDPeriod : Kbuf[bar];

   }

   /* an honest signal needs context: a cross inside a zone, in the direction of the
      higher-timeframe trend when the filter is on. Printed to the log rather than
      fired as an alert, so it cannot be mistaken for a trading system. */
   const int last = rates_total - 1;
   if(last > 2)
   {
      const bool crossUp = Kbuf[last] > Dbuf[last] && Kbuf[last-1] <= Dbuf[last-1];
      const bool crossDn = Kbuf[last] < Dbuf[last] && Kbuf[last-1] >= Dbuf[last-1];
      bool trendOk = true;
      if(InpUseHtf)
      {
         double htfClose = iClose(_Symbol, InpHtf, 0);
         double htfMa    = iMA(_Symbol, InpHtf, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
         trendOk = (htfClose > htfMa && crossUp) || (htfClose < htfMa && crossDn);
      }
      if(trendOk && crossUp && Kbuf[last] < InpOversold)
         Print("PipAtlas Stochastic: %K crossed above %D from the oversold zone on ", _Symbol, " ", EnumToString(_Period));
      if(trendOk && crossDn && Kbuf[last] > InpOverbought)
         Print("PipAtlas Stochastic: %K crossed below %D from the overbought zone on ", _Symbol, " ", EnumToString(_Period));
   }
   return(rates_total);
}
