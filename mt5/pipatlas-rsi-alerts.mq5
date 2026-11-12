//+------------------------------------------------------------------+
//|                                            PipAtlas RSI Alerts  |
//|                             https://pipatlas.com/tools           |
//|  Fires a terminal alert and an optional push notification when   |
//|  RSI closes across a level you choose. One alert per bar per      |
//|  level. It does not trade and it does not predict. Education     |
//|  only, never financial advice.                                   |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/tools"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrPurple
#property indicator_label1 "RSI"

input int    RsiPeriod      = 14;    // RSI period
input double UpperLevel     = 70.0;  // Overbought level watched
input double LowerLevel     = 30.0;  // Oversold level watched
input bool   TerminalAlert  = true;  // Alert() in the terminal
input bool   PushAlert      = false; // Push notification to the phone

int    rsiHandle = INVALID_HANDLE;
double rsiBuf[];
datetime lastAlertBar = 0;

int OnInit()
{
   SetIndexBuffer(0, rsiBuf, INDICATOR_DATA);
   rsiHandle = iRSI(_Symbol, _Period, RsiPeriod, PRICE_CLOSE);
   if(rsiHandle == INVALID_HANDLE)
   {
      Print("RSI Alerts: could not create the RSI handle.");
      return(INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
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
   if(rates_total < RsiPeriod + 2) return(0);
   int copied = CopyBuffer(rsiHandle, 0, 0, rates_total, rsiBuf);
   if(copied <= 0) return(prev_calculated);

   /* judge on the last CLOSED bar, so the alert is not a wick inside a live bar */
   int i = rates_total - 2;
   if(i < 1) return(rates_total);
   if(lastAlertBar == time[i]) return(rates_total);

   bool crossedUp   = (rsiBuf[i-1] <= UpperLevel && rsiBuf[i] > UpperLevel);
   bool crossedDown = (rsiBuf[i-1] >= LowerLevel && rsiBuf[i] < LowerLevel);
   if(!crossedUp && !crossedDown) return(rates_total);

   lastAlertBar = time[i];
   string msg = StringFormat("RSI Alerts %s %s: RSI closed at %.1f (%s %.0f)",
                             _Symbol, EnumToString(_Period), rsiBuf[i],
                             crossedUp ? "above" : "below",
                             crossedUp ? UpperLevel : LowerLevel);
   if(TerminalAlert) Alert(msg);
   if(PushAlert)     SendNotification(msg);
   return(rates_total);
}
//+------------------------------------------------------------------+
