//+------------------------------------------------------------------+
//|                                    PipAtlas strategy template    |
//|                             https://pipatlas.com/learn/conversions|
//|  Skeleton expert advisor for MT4, same four pieces as the MT5     |
//|  version: entry, exit, a stop decided before the order, and size  |
//|  from risk. The idea is a placeholder. Education only.            |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - https://pipatlas.com"
#property link      "https://pipatlas.com/learn/conversions"
#property version   "1.00"
#property strict

input int    FastPeriod    = 20;      // Fast EMA
input int    SlowPeriod    = 50;      // Slow EMA
input double RiskPercent   = 1.0;     // Risk per trade (% of equity)
input double AtrMultiple   = 2.0;     // Stop distance = ATR x this
input int    SlippagePips  = 3;       // Maximum slippage accepted
input int    MagicNumber   = 960001;  // This EA's tag on every order

bool HavePosition()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) return true;
   }
   return false;
}

/* size from the distance to the stop: risk in cash divided by risk per lot */
double LotForRisk(double stopDistance)
{
   if(stopDistance <= 0) return 0;
   double riskCash  = AccountEquity() * RiskPercent / 100.0;
   double perLot    = stopDistance / Point * MarketInfo(Symbol(), MODE_TICKVALUE);
   if(perLot <= 0) return 0;
   double lots      = riskCash / perLot;
   double step      = MarketInfo(Symbol(), MODE_LOTSTEP);
   double minLots   = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLots   = MarketInfo(Symbol(), MODE_MAXLOT);
   if(step > 0) lots = MathFloor(lots / step) * step;
   return MathMax(minLots, MathMin(maxLots, lots));
}

void OnTick()
{
   if(HavePosition()) return;
   if(Bars < SlowPeriod + 2) return;

   double fastNow  = iMA(NULL, 0, FastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double fastPrev = iMA(NULL, 0, FastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slowNow  = iMA(NULL, 0, SlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowPrev = iMA(NULL, 0, SlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double atr      = iATR(NULL, 0, 14, 1);

   bool crossUp   = (fastPrev <= slowPrev && fastNow > slowNow);
   bool crossDown = (fastPrev >= slowPrev && fastNow < slowNow);
   if(!crossUp && !crossDown) return;

   double stopDistance = atr * AtrMultiple;
   double lots         = LotForRisk(stopDistance);
   if(lots <= 0) return;

   double slip = SlippagePips * Point;
   if(crossUp)
   {
      double price = Ask;
      int ticket = OrderSend(Symbol(), OP_BUY, lots, price, (int)slip,
                             price - stopDistance, price + stopDistance * 2.0,
                             "PipAtlas template long", MagicNumber, 0, clrDodgerBlue);
      if(ticket < 0) Print("Buy failed: ", GetLastError());
   }
   if(crossDown)
   {
      double price2 = Bid;
      int ticket2 = OrderSend(Symbol(), OP_SELL, lots, price2, (int)slip,
                              price2 + stopDistance, price2 - stopDistance * 2.0,
                              "PipAtlas template short", MagicNumber, 0, clrOrangeRed);
      if(ticket2 < 0) Print("Sell failed: ", GetLastError());
   }
}
//+------------------------------------------------------------------+
