//+------------------------------------------------------------------+
//|                                     PipAtlas Bollinger Bands     |
//|                                     https://pipatlas.com/tools    |
//|  Draws the 20-period Bollinger Bands: a moving average with an    |
//|  upper and lower band two standard deviations away. The bands     |
//|  describe how far price has been travelling, not where it is      |
//|  going. Education only, never financial advice.                   |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "Middle"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_DASH
#property indicator_width1  2

#property indicator_label2  "Upper"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_width2  1

#property indicator_label3  "Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrCrimson
#property indicator_width3  1

input int    InpPeriod    = 20;    // Period
input double InpDeviation = 2.0;   // Deviations
input bool   InpPrintTags = true;  // Log a line when a bar closes outside a band

// Middle = SMA(Close, InpPeriod). Upper/Lower = Middle +/- InpDeviation * StdDev.
// The standard deviation below is the population form, the same one MetaTrader's
// own Bollinger Bands uses, so the two indicators line up bar for bar.
// A close outside a band says the move was large relative to recent noise. It
// does not say the move is over: in a trend price rides the band for weeks.

double Midbuf[];
double Upbuf[];
double Lnbuf[];

int OnInit()
{
   SetIndexBuffer(0, Midbuf);
   SetIndexBuffer(1, Upbuf);
   SetIndexBuffer(2, Lnbuf);
   IndicatorSetString(INDICATOR_SHORTNAME, "PipAtlas Bollinger(" + IntegerToString(InpPeriod) + "," + DoubleToString(InpDeviation, 2) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, Digits);
   SetIndexStyle(0, DRAW_LINE, STYLE_DASH, 2, clrDodgerBlue);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrCrimson);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, clrCrimson);
   return(INIT_SUCCEEDED);
}

double StdDevOf(const double &series[], const int shift, const int period, const double mean)
{
   double var = 0.0;
   for(int i = 0; i < period; i++)
   {
      const double d = series[shift + i] - mean;
      var += d * d;
   }
   return MathSqrt(var / period);
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
   if(rates_total <= InpPeriod) return(0);

   /* MQL4 hands indicators the series form: index 0 is the newest bar, and the
      buffers are series too, so the loop runs from the oldest uncalculated bar
      down to 0 and every array uses the same index. */
   int limit = rates_total - prev_calculated;
   if(prev_calculated == 0) limit = rates_total - InpPeriod - 1;
   if(limit > rates_total - InpPeriod - 1) limit = rates_total - InpPeriod - 1;

   for(int i = limit; i >= 0 && !IsStopped(); i--)
   {
      double sum = 0.0;
      for(int j = 0; j < InpPeriod; j++) sum += close[i + j];
      const double mean = sum / InpPeriod;
      const double sd   = StdDevOf(close, i, InpPeriod, mean);
      Midbuf[i] = mean;
      Upbuf[i]  = mean + InpDeviation * sd;
      Lnbuf[i]  = mean - InpDeviation * sd;
   }

   if(InpPrintTags && rates_total > InpPeriod + 1 && prev_calculated != rates_total)
   {
      const bool above = close[0] > Upbuf[0] && close[1] <= Upbuf[1];
      const bool below = close[0] < Lnbuf[0] && close[1] >= Lnbuf[1];
      if(above) Print("PipAtlas Bollinger: ", Symbol(), " ", EnumToString((ENUM_TIMEFRAMES)Period()), " closed above the upper band — a volatility observation, not a sell signal");
      if(below) Print("PipAtlas Bollinger: ", Symbol(), " ", EnumToString((ENUM_TIMEFRAMES)Period()), " closed below the lower band — a volatility observation, not a buy signal");
   }
   return(rates_total);
}
