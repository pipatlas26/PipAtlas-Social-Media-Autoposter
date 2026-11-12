//+------------------------------------------------------------------+
//|                                  PipAtlas Dual MA Cross (.mq5)   |
//|                     Copyright 2026 PipAtlas · MIT License        |
//|  Original free indicator: two moving averages + cross alerts.    |
//|  EDUCATION ONLY — not a trading signal. Compile in MetaEditor 5. |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property license   "MIT"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "Fast MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTeal
#property indicator_width1  2
#property indicator_label2  "Slow MA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGoldenrod
#property indicator_width2  2

input int             InpFastPeriod = 20;         // Fast MA period
input int             InpSlowPeriod = 50;         // Slow MA period
input ENUM_MA_METHOD  InpMethod     = MODE_EMA;   // MA method
input bool            InpAlerts     = true;       // Alert on cross

double FastBuf[], SlowBuf[];
int fastHandle, slowHandle;

int OnInit()
  {
   fastHandle = iMA(_Symbol, _Period, InpFastPeriod, 0, InpMethod, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, _Period, InpSlowPeriod, 0, InpMethod, PRICE_CLOSE);
   if(fastHandle == INVALID_HANDLE || slowHandle == INVALID_HANDLE)
      return INIT_FAILED;
   SetIndexBuffer(0, FastBuf, INDICATOR_DATA);
   SetIndexBuffer(1, SlowBuf, INDICATOR_DATA);
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
  {
   if(BarsCalculated(fastHandle) < rates_total || BarsCalculated(slowHandle) < rates_total)
      return 0;
   if(CopyBuffer(fastHandle, 0, 0, rates_total, FastBuf) <= 0) return 0;
   if(CopyBuffer(slowHandle, 0, 0, rates_total, SlowBuf) <= 0) return 0;

   static datetime lastAlert = 0;
   if(InpAlerts && rates_total > 1)
     {
      bool crossUp = FastBuf[rates_total-2] <= SlowBuf[rates_total-2] && FastBuf[rates_total-1] > SlowBuf[rates_total-1];
      bool crossDn = FastBuf[rates_total-2] >= SlowBuf[rates_total-2] && FastBuf[rates_total-1] < SlowBuf[rates_total-1];
      if((crossUp || crossDn) && time[rates_total-1] != lastAlert)
        {
         Alert(_Symbol, ": ", crossUp ? "Fast MA crossed ABOVE slow MA" : "Fast MA crossed BELOW slow MA");
         lastAlert = time[rates_total-1];
        }
     }
   return rates_total;
  }
