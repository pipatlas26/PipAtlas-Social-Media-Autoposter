//+------------------------------------------------------------------+
//|                                        PipAtlas Fair Value Gaps  |
//|                                     https://pipatlas.com/tools    |
//|  Draws three-candle fair value gaps (imbalance boxes).            |
//|  Education only, never financial advice.                         |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_plots   0

input int          InpLookback   = 300;          // Bars to scan
input int          InpMaxBoxes   = 15;           // Max boxes drawn
input bool         InpShowFilled = false;        // Keep boxes after they fill
input color        InpBullColor  = clrDodgerBlue;// Bullish gap colour
input color        InpBearColor  = clrCrimson;   // Bearish gap colour
input ENUM_LINE_STYLE InpStyle   = STYLE_DOT;    // Box border style

// A bullish gap: candle 3's low sits above candle 1's high (3 consecutive
// candles, oldest first). The zone is [High(c1), Low(c3)]. A gap counts as
// filled once any later bar trades fully through the zone.

string Prefix() { return "PAFVG_"; }

void DeleteBoxes()
{
   ObjectsDeleteAll(0, Prefix());
}

bool IsFilled(const double top, const double bottom, const bool bull, const int startShift)
{
   // startShift = shift of the gap's newest candle; bars 1..startShift-1 are "later"
   for(int j = startShift - 1; j >= 1; j--)
   {
      if(bull)
      {
         if(Low[j] <= bottom) return(true);   // traded fully through down
      }
      else
      {
         if(High[j] >= top) return(true);     // traded fully through up
      }
   }
   return(false);
}

void DrawBox(const string name, const datetime t1, const datetime t2,
             const double top, const double bottom, const color clr)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, top, t2, bottom);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, InpStyle);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_FILL, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   }
   else
   {
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, top);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, bottom);
   }
}

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   DeleteBoxes();
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
   static datetime lastBar = 0;
   if(Time[0] == lastBar) return(rates_total);
   lastBar = Time[0];

   DeleteBoxes();
   int drawn = 0;
   int limit = MathMin(InpLookback - 3, Bars - 4);
   for(int i = limit; i >= 1 && drawn < InpMaxBoxes; i--)
   {
      // candles: i+2 = oldest (c1), i+1 = middle (c2), i = newest (c3)
      double c1h = High[i + 2], c1l = Low[i + 2];
      double c3h = High[i],     c3l = Low[i];
      double top = 0, bottom = 0;
      bool bull = false;
      if(c3l > c1h)      { bull = true;  bottom = c1h; top = c3l; }
      else if(c3h < c1l) { bull = false; bottom = c3h; top = c1l; }
      else continue;

      if(!InpShowFilled && IsFilled(top, bottom, bull, i)) continue;

      datetime t1 = Time[i + 2];
      datetime t2 = Time[0];
      string name = Prefix() + IntegerToString((int)t1) + "_" + (bull ? "B" : "S");
      DrawBox(name, t1, t2, top, bottom, bull ? InpBullColor : InpBearColor);
      drawn++;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
