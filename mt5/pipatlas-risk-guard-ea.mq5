//+------------------------------------------------------------------+
//|                PipAtlas Risk Guard EA — template (.mq5)          |
//|                     Copyright 2026 PipAtlas · MIT License        |
//|  Original educational EA TEMPLATE: enforces fixed-fractional     |
//|  position sizing (the 1% rule) for your own entry logic.         |
//|  EDUCATION ONLY — DEMO FIRST. Contains NO entry signals.         |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property license   "MIT"
#include <Trade\Trade.mqh>
CTrade trade;

input double InpRiskPercent = 1.0;    // Risk per trade (% of balance)
input int    InpStopPips    = 25;     // Stop-loss distance (pips)
input double InpMaxDailyLoss = 3.0;   // Daily stop: max loss (% of balance) — enforce manually

int OnInit()
  {
   Comment("PipAtlas Risk Guard active · risk ", DoubleToString(InpRiskPercent,1),
           "% · stop ", InpStopPips, " pips");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason){ Comment(""); }

double LotForRisk(double stopPips)
  {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * InpRiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || tickSize <= 0 || stopPips <= 0) return 0.0;
   double valuePerPipPerLot = tickValue * (10.0 * _Point) / tickSize; // 5-digit FX approximation
   double lots = riskMoney / (valuePerPipPerLot * stopPips);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step > 0) lots = MathFloor(lots/step)*step;
   return MathMax(minL, MathMin(maxL, lots));
  }

void OnTick()
  {
   // Template: attach your own entry logic, then size every order with
   //   trade.Volume(LotForRisk(InpStopPips));
   // so each trade risks the same fixed fraction of the account.
   Comment("PipAtlas Risk Guard · suggested lot for a ", InpStopPips,
           "-pip stop on ", _Symbol, ": ",
           DoubleToString(LotForRisk(InpStopPips), 2));
  }
