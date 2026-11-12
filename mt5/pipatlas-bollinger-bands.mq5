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
// The deviation is the population form, the same one the terminal's own
// Bollinger Bands uses, so the two agree bar for bar.
// A close outside a band says the move was large relative to recent noise. It
// does not say the move is over: in a trend price rides the band for weeks.

double Midbuf[];
double Upbuf[];
double Lnbuf[];

int OnInit()
{
   SetIndexBuffer(0, Midbuf, INDICATOR_DATA);
   SetIndexBuffer(1, Upbuf,  INDICATOR_DATA);
   SetIndexBuffer(2, Lnbuf,  INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME, "PipAtlas Bollinger(" + IntegerToString(InpPeriod) + "," + DoubleToString(InpDeviation, 2) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_DASH);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   return(INIT_SUCCEEDED);
}

double StdDevOf(const double &series[], const int idx, const int period, const double mean)
{
   double var = 0.0;
   for(int i = 0; i < period; i++)
   {
      const double d = series[idx - i] - mean;
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

   /* MQL5 arrays and buffers are both plain oldest-first by default, so a single
      ascending index addresses the bar being calculated in every array. */
   int start = (prev_calculated > 1 ? prev_calculated - 1 : InpPeriod);
   if(start < InpPeriod) start = InpPeriod;

   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
      double sum = 0.0;
      for(int j = 0; j < InpPeriod; j++) sum += close[i - j];
      const double mean = sum / InpPeriod;
      const double sd   = StdDevOf(close, i, InpPeriod, mean);
      Midbuf[i] = mean;
      Upbuf[i]  = mean + InpDeviation * sd;
      Lnbuf[i]  = mean - InpDeviation * sd;
   }

   if(InpPrintTags && rates_total > InpPeriod + 1 && prev_calculated != rates_total)
   {
      const int last = rates_total - 1;
      const bool above = close[last] > Upbuf[last] && close[last - 1] <= Upbuf[last - 1];
      const bool below = close[last] < Lnbuf[last] && close[last - 1] >= Lnbuf[last - 1];
      if(above) Print("PipAtlas Bollinger: ", _Symbol, " ", EnumToString(_Period), " closed above the upper band — a volatility observation, not a sell signal");
      if(below) Print("PipAtlas Bollinger: ", _Symbol, " ", EnumToString(_Period), " closed below the lower band — a volatility observation, not a buy signal");
   }
   return(rates_total);
}
