//+------------------------------------------------------------------+
//|                                    PipAtlas strategy template    |
//|                             https://pipatlas.com/learn/conversions|
//|  Skeleton expert advisor for MT5. It shows the four pieces that   |
//|  every EA needs before the idea inside it can be judged: entry,   |
//|  exit, a stop decided before the order, and size from risk.       |
//|  The idea here is a placeholder. Education only, never advice.    |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/learn/conversions"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>

CTrade  trade;
input int    FastPeriod   = 20;      // Fast EMA
input int    SlowPeriod   = 50;      // Slow EMA
input double RiskPercent  = 1.0;     // Risk per trade (% of equity)
input double AtrMultiple  = 2.0;     // Stop distance = ATR x this
input ulong  MagicNumber  = 960001;  // This EA's tag on every order

int fastHandle = INVALID_HANDLE;
int slowHandle = INVALID_HANDLE;
int atrHandle  = INVALID_HANDLE;

int OnInit()
{
   fastHandle = iMA(_Symbol, _Period, FastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, _Period, SlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   atrHandle  = iATR(_Symbol, _Period, 14);
   if(fastHandle == INVALID_HANDLE || slowHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
   {
      Print("Strategy template: indicator handle failed.");
      return(INIT_FAILED);
   }
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(fastHandle != INVALID_HANDLE) IndicatorRelease(fastHandle);
   if(slowHandle != INVALID_HANDLE) IndicatorRelease(slowHandle);
   if(atrHandle  != INVALID_HANDLE) IndicatorRelease(atrHandle);
}

bool HavePosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber) return true;
   }
   return false;
}

/* size from the distance to the stop: risk in cash divided by risk per lot */
double LotForRisk(double stopDistance)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || tickSize <= 0 || stopDistance <= 0) return 0;
   double riskCash  = AccountInfoDouble(ACCOUNT_EQUITY) * RiskPercent / 100.0;
   double perLot    = stopDistance / tickSize * tickValue;
   if(perLot <= 0) return 0;
   double lots      = riskCash / perLot;
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLots   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLots   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step > 0) lots = MathFloor(lots / step) * step;
   return MathMax(minLots, MathMin(maxLots, lots));
}

void OnTick()
{
   if(HavePosition()) return;
   if(Bars(_Symbol, _Period) < SlowPeriod + 2) return;

   double fast[], slow[], atr[];
   if(CopyBuffer(fastHandle, 0, 0, 2, fast) < 2) return;
   if(CopyBuffer(slowHandle, 0, 0, 2, slow) < 2) return;
   if(CopyBuffer(atrHandle,  0, 0, 2, atr)  < 2) return;

   /* judge on the last closed bar, never on the bar in progress */
   bool crossUp   = (fast[0] <= slow[0] && fast[1] > slow[1]);
   bool crossDown = (fast[0] >= slow[0] && fast[1] < slow[1]);
   if(!crossUp && !crossDown) return;

   double stopDistance = atr[1] * AtrMultiple;
   double lots         = LotForRisk(stopDistance);
   if(lots <= 0) return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;

   if(crossUp)
   {
      double sl = tick.ask - stopDistance;
      double tp = tick.ask + stopDistance * 2.0;
      if(!trade.Buy(lots, _Symbol, 0.0, sl, tp, "PipAtlas template long"))
         Print("Buy failed: ", trade.ResultRetcode(), " ", trade.ResultComment());
   }
   if(crossDown)
   {
      double sl = tick.bid + stopDistance;
      double tp = tick.bid - stopDistance * 2.0;
      if(!trade.Sell(lots, _Symbol, 0.0, sl, tp, "PipAtlas template short"))
         Print("Sell failed: ", trade.ResultRetcode(), " ", trade.ResultComment());
   }
}
//+------------------------------------------------------------------+
