//+------------------------------------------------------------------+
//|                                      PipAtlas Economic Calendar  |
//|                                     https://pipatlas.com/tools    |
//|  Event lines + next-events panel + pre-event alerts on the chart. |
//|  Schedule = your own event list (input string or CSV file in      |
//|  MQL4/Files). Times are chart/server time. Education only,        |
//|  never financial advice.                                          |
//+------------------------------------------------------------------+
#property copyright "PipAtlas"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_plots   0

input string InpEvents    = "";     // Events: YYYY.MM.DD HH:MM|CUR|Name|impact;...
input string InpCsvFile   = "";     // Optional CSV in MQL4/Files: time,cur,name,impact
input int    InpAlertMin  = 15;     // Alert N minutes before an event (0 = off)
input int    InpDays      = 7;      // Days ahead to draw and announce
input bool   InpPanel     = true;   // Show next-events panel
input int    InpPanelRows = 6;      // Panel rows
input color  InpHigh      = clrCrimson;
input color  InpMed       = clrDarkOrange;
input color  InpLow       = clrGray;

struct EconEvent
{
   datetime when;
   string   cur;
   string   name;
   string   impact;
   bool     alerted;
};

EconEvent evs[];

string Pfx() { return "PAEC_"; }

int OnInit()
{
   LoadEvents();
   DrawAll();
   EventSetTimer(2);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, Pfx());
   EventKillTimer();
}

void OnTimer()
{
   CheckAlerts();
   DrawAll();
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
   return(rates_total);
}

// ---- schedule loading -------------------------------------------------
void LoadEvents()
{
   ArrayResize(evs, 0);
   if(StringLen(InpEvents) > 0) ParseBlock(InpEvents);
   if(StringLen(InpCsvFile) > 0) LoadCsv();
   for(int i = 1; i < ArraySize(evs); i++)           // insertion sort, lists are small
   {
      EconEvent tmp = evs[i];
      int j = i - 1;
      while(j >= 0 && evs[j].when > tmp.when) { evs[j + 1] = evs[j]; j--; }
      evs[j + 1] = tmp;
   }
}

void ParseBlock(const string block)
{
   string parts[];
   int n = StringSplit(block, StringGetCharacter(';', 0), parts);
   for(int i = 0; i < n; i++)
   {
      string item = parts[i];
      StringTrimLeft(item);
      StringTrimRight(item);
      if(StringLen(item) == 0) continue;
      string f[];
      if(StringSplit(item, StringGetCharacter('|', 0), f) >= 4)
         AddEvent(StringToTime(f[0]), f[1], f[2], f[3]);
   }
}

void LoadCsv()
{
   int h = FileOpen(InpCsvFile, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(h == INVALID_HANDLE) { Print("PipAtlas EC: cannot open ", InpCsvFile); return; }
   while(!FileIsEnding(h))
   {
      string t = FileReadString(h);
      if(StringLen(t) == 0 && FileIsEnding(h)) break;
      string c = FileReadString(h);
      string nm = FileReadString(h);
      string im = FileReadString(h);
      AddEvent(StringToTime(t), c, nm, im);
   }
   FileClose(h);
}

void AddEvent(const datetime when, const string cur, const string name, const string impact)
{
   if(when <= 0) return;
   int sz = ArraySize(evs);
   ArrayResize(evs, sz + 1);
   evs[sz].when = when;
   evs[sz].cur = cur;
   evs[sz].name = name;
   evs[sz].impact = impact;
   evs[sz].alerted = false;
}

color ImpactColor(const string impact)
{
   string im = impact;
   StringToLower(im);
   if(StringFind(im, "high") == 0 || StringFind(im, "red") == 0) return InpHigh;
   if(StringFind(im, "med") == 0 || StringFind(im, "oran") == 0) return InpMed;
   return InpLow;
}

// ---- drawing ----------------------------------------------------------
void DrawAll()
{
   ObjectsDeleteAll(0, Pfx());
   datetime now = TimeCurrent();
   datetime horizon = now + InpDays * 86400;

   for(int i = 0; i < ArraySize(evs); i++)
   {
      if(evs[i].when < now - 86400 || evs[i].when > horizon) continue;
      string tag = Pfx() + IntegerToString((long)evs[i].when) + "_" + IntegerToString(i);
      ObjectCreate(0, tag, OBJ_VLINE, 0, evs[i].when, 0);
      ObjectSetInteger(0, tag, OBJPROP_COLOR, ImpactColor(evs[i].impact));
      ObjectSetInteger(0, tag, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, tag, OBJPROP_BACK, true);
      ObjectSetInteger(0, tag, OBJPROP_SELECTABLE, false);
   }

   if(!InpPanel) return;
   int row = 0;
   for(int k = 0; k < ArraySize(evs) && row < InpPanelRows; k++)
   {
      if(evs[k].when < now || evs[k].when > horizon) continue;
      string nm = Pfx() + "P" + IntegerToString(row);
      string txt = TimeToString(evs[k].when, TIME_DATE | TIME_MINUTES) + "  " +
                   evs[k].cur + "  " + evs[k].name + "  [" + evs[k].impact + "]";
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, 1);          // top-right
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, 8);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, 18 + row * 16);
      ObjectSetInteger(0, nm, OBJPROP_COLOR, ImpactColor(evs[k].impact));
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, nm, OBJPROP_TEXT, txt);
      row++;
   }
   if(row > 0)
   {
      ObjectCreate(0, Pfx() + "PH", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, Pfx() + "PH", OBJPROP_CORNER, 1);
      ObjectSetInteger(0, Pfx() + "PH", OBJPROP_XDISTANCE, 8);
      ObjectSetInteger(0, Pfx() + "PH", OBJPROP_YDISTANCE, 4);
      ObjectSetInteger(0, Pfx() + "PH", OBJPROP_COLOR, clrNavy);
      ObjectSetInteger(0, Pfx() + "PH", OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, Pfx() + "PH", OBJPROP_TEXT, "PipAtlas — next events:");
   }
}

// ---- alerts -----------------------------------------------------------
void CheckAlerts()
{
   if(InpAlertMin <= 0) return;
   datetime now = TimeCurrent();
   for(int i = 0; i < ArraySize(evs); i++)
   {
      if(evs[i].alerted) continue;
      if(evs[i].when < now || evs[i].when > now + InpAlertMin * 60) continue;
      Alert("PipAtlas EC: ", evs[i].cur, " ", evs[i].name, " in ",
            IntegerToString((int)((evs[i].when - now) / 60) + 1), " min [", evs[i].impact, "]");
      evs[i].alerted = true;
   }
}
//+------------------------------------------------------------------+
