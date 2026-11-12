//+------------------------------------------------------------------+
//|                                    PipAtlas RSI Alerts (.mq4)    |
//|                     Copyright 2026 PipAtlas · MIT License        |
//|  Original free indicator: RSI sub-window + OB/OS cross alerts.   |
//|  EDUCATION ONLY — compile in MetaEditor 4.                       |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1

input int    InpRSIPeriod = 14;    // RSI period
input double InpUpper     = 70.0;  // Overbought level
input double InpLower     = 30.0;  // Oversold level
input bool   InpAlerts    = true;  // Alert on level cross

double RsiBuf[];

int OnInit()
  {
   SetIndexBuffer(0, RsiBuf);
   SetIndexStyle(0, DRAW_LINE, EMPTY, 2, clrTeal);
   SetIndexLabel(0, "RSI");
   SetLevelStyle(DRAW_LINE, STYLE_DOT, clrSilver);
   SetLevelValue(0, InpUpper);
   SetLevelValue(1, InpLower);
   IndicatorShortName("PipAtlas RSI (" + IntegerToString(InpRSIPeriod) + ")");
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
  {
   for(int i = MathMax(rates_total - InpRSIPeriod - 2, 1); i < rates_total; i++)
      RsiBuf[i] = iRSI(NULL, 0, InpRSIPeriod, PRICE_CLOSE, i);
   static datetime lastAlert = 0;
   if(InpAlerts && rates_total > 2 && time[rates_total-1] != lastAlert)
     {
      double r1 = RsiBuf[rates_total-2], r0 = RsiBuf[rates_total-1];
      bool up = (r1 <= InpUpper && r0 > InpUpper);
      bool dn = (r1 >= InpLower && r0 < InpLower);
      if(up || dn)
        {
         Alert(_Symbol, ": RSI ", up ? "crossed ABOVE overbought" : "crossed BELOW oversold");
         lastAlert = time[rates_total-1];
        }
     }
   return rates_total;
  }
