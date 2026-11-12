//+------------------------------------------------------------------+
//|                                        PipAtlas - ATR Stop.mq4  |
//|            MIT License - original PipAtlas code, education only  |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - MIT"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property description "ATR trailing stop line + 1%-risk lot size hint. Educational - test on demo."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  clrTeal
#property indicator_color2  clrGoldenrod
#property indicator_width1  2
#property indicator_width2  2

extern int    AtrPeriod = 14;    // ATR period
extern double Mult      = 2.5;   // ATR multiplier
extern double RiskPct   = 1.0;   // Risk % per trade
extern double Budget    = 1000;  // Account balance for the hint

double StopLong[], StopShort[];

int OnInit()
{
   SetIndexBuffer(0, StopLong);  SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(1, StopShort); SetIndexStyle(1, DRAW_LINE);
   SetIndexEmptyValue(0, EMPTY_VALUE); SetIndexEmptyValue(1, EMPTY_VALUE);
   IndicatorShortName("PipAtlas ATR Stop(" + AtrPeriod + ")");
   return(INIT_SUCCEEDED);
}

int start()
{
   int counted = IndicatorCounted();
   if(counted < 0) return(-1);
   int limit = Bars - counted - AtrPeriod - 1;
   if(limit > Bars - AtrPeriod - 2) limit = Bars - AtrPeriod - 2;

   double up = Close[0], dn = Close[0];
   for(int i = limit; i >= 0; i--)
   {
      double a = iATR(NULL, 0, AtrPeriod, i);
      if(a <= 0) { StopLong[i] = EMPTY_VALUE; StopShort[i] = EMPTY_VALUE; continue; }
      double cand  = Close[i] - Mult * a;
      up = (cand > up || Close[i] > Close[i+1]) ? MathMax(cand, up) : up;
      StopLong[i]  = up;
      double candS = Close[i] + Mult * a;
      dn = (candS < dn || Close[i] < Close[i+1]) ? MathMin(candS, dn) : dn;
      StopShort[i] = dn;

      if(i == 0)
      {
         double pipSize = Point;
         if(StringFind(Symbol(), "JPY") >= 0) pipSize = 0.01;
         double stopDist = MathAbs(Close[0] - StopLong[0]) / pipSize;
         double riskCash = Budget * RiskPct / 100.0;
         double lots = riskCash / (stopDist * 10.0);
         Comment("PipAtlas ATR Stop\n",
                 "Long stop : ", DoubleToString(StopLong[0], Digits),
                 "  (", DoubleToString(stopDist, 0), " pips)\n",
                 "1%-risk hint: ~", DoubleToString(lots, 2), " lots on $", DoubleToString(Budget, 0),
                 "\nEducation only - verify in the PipAtlas calculators.");
      }
   }
   return(0);
}
