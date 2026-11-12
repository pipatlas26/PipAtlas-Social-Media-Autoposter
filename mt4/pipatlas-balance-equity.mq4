//+------------------------------------------------------------------+
//|                                    PipAtlas Balance & Equity.mq4 |
//|                         https://pipatlas.com/tools                |
//|  Plots account balance and equity forward from the moment you     |
//|  attach it (one sample per bar), with drawdown-from-peak and      |
//|  margin-level alerts. It records what happens from now on - it    |
//|  cannot rebuild the curve for time before it was attached.        |
//|  Education only, never financial advice.                          |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/tools"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  clrSteelBlue
#property indicator_color2  clrOrangeRed
#property indicator_width1  2
#property indicator_width2  2
#property indicator_label1  "Balance"
#property indicator_label2  "Equity"

input double InpMarginLevelAlert = 150.0; // Margin level alert below (%)
input double InpEquityDropAlert  = 10.0;  // Equity drop from peak alert (%)
input bool   InpAlertsOn         = true;  // Enable alerts

double BalanceBuf[], EquityBuf[];
double peakEquity = 0.0;
bool   marginWarned = false, dropWarned = false;
datetime lastBar = 0;

int OnInit()
  {
   SetIndexBuffer(0, BalanceBuf);
   SetIndexBuffer(1, EquityBuf);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrSteelBlue);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrOrangeRed);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   ArraySetAsSeries(BalanceBuf, true);
   ArraySetAsSeries(EquityBuf, true);
   IndicatorShortName("PipAtlas Balance/Equity (records from attach time)");
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   double eq = AccountEquity();
   if(eq > peakEquity) peakEquity = eq;

   datetime t = iTime(Symbol(), Period(), 0);
   if(t != lastBar)
     {
      lastBar = t;
      BalanceBuf[0] = AccountBalance();
      EquityBuf[0]  = eq;
     }

   if(!InpAlertsOn) return;

   double ml = (AccountMargin() > 0) ? eq / AccountMargin() * 100.0 : 100000.0;
   if(ml < InpMarginLevelAlert)
     {
      if(!marginWarned) { Alert("PipAtlas: margin level ", DoubleToString(ml, 1), "% below ", DoubleToString(InpMarginLevelAlert, 1), "%"); marginWarned = true; }
     }
   else marginWarned = false;

   double drop = (peakEquity > 0) ? (peakEquity - eq) / peakEquity * 100.0 : 0.0;
   if(drop >= InpEquityDropAlert)
     {
      if(!dropWarned) { Alert("PipAtlas: equity down ", DoubleToString(drop, 1), "% from peak"); dropWarned = true; }
     }
   else dropWarned = false;
  }
//+------------------------------------------------------------------+
