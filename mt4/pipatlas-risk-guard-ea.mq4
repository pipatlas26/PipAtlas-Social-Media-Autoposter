//+------------------------------------------------------------------+
//|                                            PipAtlas Risk Guard  |
//|                             https://pipatlas.com/tools           |
//|  EDUCATION ONLY - DEMO ACCOUNT ONLY. This EA can send close    |
//|  requests on a daily-loss breach. It uses account equity but    |
//|  attempts to close only chart-symbol orders, once per breach.   |
//|  Pending orders, other symbols, failed closes and new trades    |
//|  may remain. It does not lock trading or guarantee protection.  |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/tools"
#property version   "1.00"
#property strict

input double MaxDailyLossPct  = 2.0;   // Threshold vs equity captured on attach or server-day rollover
input double MaxLotExposure   = 0.5;   // Chart-symbol lots threshold; breach alerts, not a close
input int    MaxOpenTrades    = 3;     // Chart-symbol order count threshold; breach alerts only
input bool   CloseAllOnBreach  = true; // Attempt chart-symbol closes on daily-loss breach only
input bool   PopupAlertOnBreach = true;// Popup when a limit is breached

double   dayStartEquity = 0;
datetime currentDay     = 0;
bool     halted         = false;

int OnInit()
{
   dayStartEquity = AccountEquity();
   currentDay     = TimeDay(TimeCurrent());
   halted         = false;
   Print("Risk Guard armed. Day-start equity ", DoubleToString(dayStartEquity, 2),
         " limit ", DoubleToString(MaxDailyLossPct, 2), "%");
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(TimeDay(TimeCurrent()) != currentDay)
   {
      currentDay     = TimeDay(TimeCurrent());
      dayStartEquity = AccountEquity();
      halted         = false;
   }
   if(dayStartEquity <= 0) return;

   double lossPct = (dayStartEquity - AccountEquity()) / dayStartEquity * 100.0;
   if(lossPct >= MaxDailyLossPct && !halted)
   {
      halted = true;
      Print("Risk Guard: daily loss ", DoubleToString(lossPct, 2), "% reached the limit of ",
            DoubleToString(MaxDailyLossPct, 2), "%. New entries are not taken by this EA (it opens none).");
      if(PopupAlertOnBreach) Alert("Risk Guard: daily loss limit reached on ", Symbol());
      if(CloseAllOnBreach) CloseEverything("daily loss limit");
   }

   double lots = 0;
   int    open = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol()) continue;
      lots += OrderLots();
      open++;
   }
   if((lots > MaxLotExposure || open > MaxOpenTrades) && !halted)
   {
      halted = true;
      Print("Risk Guard: exposure ", DoubleToString(lots, 2), " lots across ", open,
            " trades exceeds the limit set in the inputs.");
      if(PopupAlertOnBreach) Alert("Risk Guard: exposure limit exceeded on ", Symbol());
   }
}

void CloseEverything(string reason)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol()) continue;
      /* Attempt a close; pending orders and failed requests may remain. */
      int type = (OrderType() == OP_BUY) ? OP_SELL : OP_BUY;
      bool ok = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 30, clrGray);
      if(!ok) Print("Risk Guard: could not close #", OrderTicket(), " (", reason, ") error ", GetLastError());
   }
}
//+------------------------------------------------------------------+
