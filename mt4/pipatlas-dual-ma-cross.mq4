//+------------------------------------------------------------------+
//|                                          PipAtlas Dual MA Cross  |
//|                             https://pipatlas.com/tools           |
//|  Draws a fast/slow moving-average cross with one arrow per cross |
//|  and an optional alert. It marks a cross; it does not trade it,  |
//|  and a cross is not a signal on its own. Education only.         |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/tools"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrOrangeRed

input int    FastPeriod   = 20;          // Fast MA period
input int    SlowPeriod   = 50;          // Slow MA period
input ENUM_MA_METHOD MAMethod = MODE_EMA; // MA method
input bool   ShowArrows   = true;        // Draw cross arrows
input bool   PopupAlert   = false;       // Alert on closed-bar cross

double FastBuf[];
double SlowBuf[];
datetime lastAlertBar = 0;

int OnInit()
{
   SetIndexBuffer(0, FastBuf);
   SetIndexStyle(0, DRAW_LINE);
   SetIndexLabel(0, "Fast MA " + IntegerToString(FastPeriod));
   SetIndexBuffer(1, SlowBuf);
   SetIndexStyle(1, DRAW_LINE);
   SetIndexLabel(1, "Slow MA " + IntegerToString(SlowPeriod));
   if(FastPeriod >= SlowPeriod)
   {
      Print("Dual MA Cross: FastPeriod must be smaller than SlowPeriod.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   return(INIT_SUCCEEDED);
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
   if(rates_total < SlowPeriod + 2) return(0);
   int start = (prev_calculated > SlowPeriod) ? prev_calculated - 1 : SlowPeriod;
   for(int i = start; i < rates_total; i++)
   {
      FastBuf[i] = iMA(NULL, 0, FastPeriod, 0, MAMethod, PRICE_CLOSE, rates_total - i - 1);
      SlowBuf[i] = iMA(NULL, 0, SlowPeriod, 0, MAMethod, PRICE_CLOSE, rates_total - i - 1);
   }
   /* a cross is only a cross on a closed bar: compare bar i with bar i-1 */
   for(int i = rates_total - 2; i < rates_total; i++)
   {
      if(i < 1) continue;
      bool up   = (FastBuf[i-1] <= SlowBuf[i-1] && FastBuf[i] > SlowBuf[i]);
      bool down = (FastBuf[i-1] >= SlowBuf[i-1] && FastBuf[i] < SlowBuf[i]);
      if(!ShowArrows) continue;
      if(up)
      {
         string name = "pacross_up_" + IntegerToString((int)time[i]);
         ObjectDelete(0, name);
         ObjectCreate(0, name, OBJ_ARROW_UP, 0, time[i], low[i] - 10 * Point);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
      }
      if(down)
      {
         string name2 = "pacross_dn_" + IntegerToString((int)time[i]);
         ObjectDelete(0, name2);
         ObjectCreate(0, name2, OBJ_ARROW_DOWN, 0, time[i], high[i] + 10 * Point);
         ObjectSetInteger(0, name2, OBJPROP_COLOR, clrOrangeRed);
      }
      if(PopupAlert && (up || down) && lastAlertBar != time[i])
      {
         lastAlertBar = time[i];
         Alert("Dual MA Cross ", Symbol(), " ", Period(), " -> ", up ? "fast above slow" : "fast below slow");
      }
   }
   return(rates_total);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "pacross_");
}
//+------------------------------------------------------------------+
