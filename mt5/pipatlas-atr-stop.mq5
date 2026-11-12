//+------------------------------------------------------------------+
//|                                              PipAtlas ATR Stop  |
//|                             https://pipatlas.com/tools           |
//|  Prints the initial stop distance implied by ATR x multiplier    |
//|  and draws it on the last closed bar. It suggests a width; it     |
//|  does not place, trail or manage an order. Education only.       |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/tools"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 1
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrGoldenrod
#property indicator_label1 "ATR stop"

input int    AtrPeriod    = 14;    // ATR period
input double AtrMultiple  = 2.0;   // Multiplier (2.0 is a convention, not an optimum)
input bool   ShowLongs    = true;  // Draw the stop implied for a long
input bool   ShowShorts   = true;  // Draw the stop implied for a short

int atrHandle = INVALID_HANDLE;

int OnInit()
{
   atrHandle = iATR(_Symbol, _Period, AtrPeriod);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("ATR Stop: could not create the ATR handle.");
      return(INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   ObjectDelete(0, "pa_atr_stop_long");
   ObjectDelete(0, "pa_atr_stop_short");
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
   if(rates_total < AtrPeriod + 2) return(0);

   double atr[];
   if(CopyBuffer(atrHandle, 0, 0, 2, atr) < 2) return(prev_calculated);

   double width = atr[1] * AtrMultiple;
   int    bar   = rates_total - 2;
   if(bar < 1) return(prev_calculated);

   static datetime drawnBar = 0;
   if(drawnBar == time[bar]) return(rates_total);
   drawnBar = time[bar];

   if(ShowLongs)
   {
      ObjectDelete(0, "pa_atr_stop_long");
      ObjectCreate(0, "pa_atr_stop_long", OBJ_HLINE, 0, 0, close[bar] - width);
      ObjectSetInteger(0, "pa_atr_stop_long", OBJPROP_COLOR, clrSeaGreen);
      ObjectSetString(0, "pa_atr_stop_long", OBJPROP_TEXT,
                      StringFormat("ATR stop (long): %s", DoubleToString(close[bar] - width, _Digits)));
   }
   if(ShowShorts)
   {
      ObjectDelete(0, "pa_atr_stop_short");
      ObjectCreate(0, "pa_atr_stop_short", OBJ_HLINE, 0, 0, close[bar] + width);
      ObjectSetInteger(0, "pa_atr_stop_short", OBJPROP_COLOR, clrIndianRed);
      ObjectSetString(0, "pa_atr_stop_short", OBJPROP_TEXT,
                      StringFormat("ATR stop (short): %s", DoubleToString(close[bar] + width, _Digits)));
   }
   ChartRedraw();
   return(rates_total);
}
//+------------------------------------------------------------------+
