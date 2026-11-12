//+------------------------------------------------------------------+
//|                                    PipAtlas - Session Range.mq5 |
//|            MIT License - original PipAtlas code, education only  |
//|   Draws Asia / London / New York session high-low boxes on chart |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - MIT"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property description "Draws session range boxes (Asia, London, New York). Educational example - test on demo."
#property indicator_chart_window
#property indicator_plots 0

input int  InpAsiaStart   = 0;    // Asia start hour (server time)
input int  InpAsiaEnd     = 9;    // Asia end hour (server time)
input int  InpLondonStart = 8;    // London start hour (server time)
input int  InpLondonEnd   = 17;   // London end hour (server time)
input int  InpNYStart     = 13;   // New York start hour (server time)
input int  InpNYEnd       = 21;   // New York end hour (server time)
input int  InpDaysBack    = 10;   // How many days to draw
input color InpAsiaClr    = clrDimGray;
input color InpLondonClr  = clrTeal;
input color InpNYClr      = clrGoldenrod;

string Pref="PA-SR-";

int OnInit(){ return(INIT_SUCCEEDED); }
void OnDeinit(const int reason){ ObjectsDeleteAll(0,Pref); }

void DrawSession(const string tag,const datetime t1,const datetime t2,
                 const double hi,const double lo,const color clr)
{
   string name=Pref+tag+TimeToString(t1,TIME_DATE);
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE,0,t1,hi,t2,lo);
   else{
      ObjectSetInteger(0,name,OBJPROP_TIME,0,t1);
      ObjectSetInteger(0,name,OBJPROP_TIME,1,t2);
      ObjectSetDouble(0,name,OBJPROP_PRICE,0,hi);
      ObjectSetDouble(0,name,OBJPROP_PRICE,1,lo);
   }
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

bool RangeFor(const datetime dayStart,const int h1,const int h2,
              datetime &t1,datetime &t2,double &hi,double &lo)
{
   t1=dayStart+h1*3600;
   t2=dayStart+h2*3600;
   if(t2>TimeCurrent()) t2=TimeCurrent();
   if(t2<=t1) return false;
   int i1=iBarShift(NULL,0,t1,false);
   int i2=iBarShift(NULL,0,t2,false);
   if(i1<0||i2<0) return false;
   int cnt=i1-i2+1; if(cnt<2) return false;
   int iH=iHighest(NULL,0,MODE_HIGH,cnt,i2);
   int iL=iLowest (NULL,0,MODE_LOW ,cnt,i2);
   if(iH<0||iL<0) return false;
   hi=iHigh(NULL,0,iH); lo=iLow(NULL,0,iL);
   return true;
}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],const double &high[],
                const double &low[],const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   static datetime lastDay=0;
   datetime dayNow=time[rates_total-1]-(time[rates_total-1]%86400);
   if(dayNow==lastDay && prev_calculated>0) return rates_total;
   lastDay=dayNow;

   ObjectsDeleteAll(0,Pref);
   for(int d=InpDaysBack; d>=0; d--)
   {
      datetime day=dayNow-d*86400;
      datetime t1,t2; double hi,lo;
      if(RangeFor(day,InpAsiaStart,InpAsiaEnd,t1,t2,hi,lo)) DrawSession("AS",t1,t2,hi,lo,InpAsiaClr);
      if(RangeFor(day,InpLondonStart,InpLondonEnd,t1,t2,hi,lo)) DrawSession("LO",t1,t2,hi,lo,InpLondonClr);
      if(RangeFor(day,InpNYStart,InpNYEnd,t1,t2,hi,lo)) DrawSession("NY",t1,t2,hi,lo,InpNYClr);
   }
   ChartRedraw();
   return rates_total;
}
