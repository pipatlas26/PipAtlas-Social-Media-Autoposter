//+------------------------------------------------------------------+
//|                                    PipAtlas - Session Range.mq4 |
//|            MIT License - original PipAtlas code, education only  |
//+------------------------------------------------------------------+
#property copyright "PipAtlas - MIT"
#property link      "https://pipatlas.com"
#property version   "1.00"
#property description "Draws session range boxes (Asia, London, New York). Educational example - test on demo."
#property indicator_chart_window
#property indicator_buffers 0

extern int  AsiaStart   = 0;     // Asia start hour (server time)
extern int  AsiaEnd     = 9;     // Asia end hour
extern int  LondonStart = 8;     // London start hour
extern int  LondonEnd   = 17;    // London end hour
extern int  NYStart     = 13;    // New York start hour
extern int  NYEnd       = 21;    // New York end hour
extern int  DaysBack    = 10;    // days of history to draw
extern color AsiaClr    = clrDimGray;
extern color LondonClr  = clrTeal;
extern color NYClr      = clrGoldenrod;

string Pref="PA-SR-";

int OnInit(){ return(INIT_SUCCEEDED); }
void OnDeinit(const int reason){ for(int i=ObjectsTotal()-1;i>=0;i--){ string n=ObjectName(i); if(StringFind(n,Pref)==0) ObjectDelete(n);} }

void DrawSession(string tag,datetime t1,datetime t2,double hi,double lo,color clr)
{
   string name=Pref+tag+TimeToStr(t1,TIME_DATE);
   if(ObjectFind(name)<0) ObjectCreate(name,OBJ_RECTANGLE,0,t1,hi,t2,lo);
   else { ObjectSet(name,OBJPROP_TIME1,t1); ObjectSet(name,OBJPROP_PRICE1,hi);
          ObjectSet(name,OBJPROP_TIME2,t2); ObjectSet(name,OBJPROP_PRICE2,lo); }
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet(name,OBJPROP_BACK,true);
   ObjectSet(name,OBJPROP_SELECTABLE,false);
}

bool RangeFor(datetime day,int h1,int h2,datetime &t1,datetime &t2,double &hi,double &lo)
{
   t1=day+h1*3600; t2=day+h2*3600;
   if(t2>TimeCurrent()) t2=TimeCurrent();
   if(t2<=t1) return false;
   int i1=iBarShift(NULL,0,t1,false);
   int i2=iBarShift(NULL,0,t2,false);
   if(i1<0||i2<0) return false;
   int cnt=i1-i2+1; if(cnt<2) return false;
   int iH=iHighest(NULL,0,MODE_HIGH,cnt,i2);
   int iL=iLowest (NULL,0,MODE_LOW ,cnt,i2);
   if(iH<0||iL<0) return false;
   hi=High[iH]; lo=Low[iL];
   return true;
}

int start()
{
   static datetime lastDay=0;
   datetime now=Time[0];
   datetime dayNow=now-(now%86400);
   if(dayNow==lastDay) return(0);
   lastDay=dayNow;

   for(int i=ObjectsTotal()-1;i>=0;i--){ string n=ObjectName(i); if(StringFind(n,Pref)==0) ObjectDelete(n); }
   for(int d=DaysBack; d>=0; d--)
   {
      datetime day=dayNow-d*86400;
      datetime t1,t2; double hi,lo;
      if(RangeFor(day,AsiaStart,AsiaEnd,t1,t2,hi,lo)) DrawSession("AS",t1,t2,hi,lo,AsiaClr);
      if(RangeFor(day,LondonStart,LondonEnd,t1,t2,hi,lo)) DrawSession("LO",t1,t2,hi,lo,LondonClr);
      if(RangeFor(day,NYStart,NYEnd,t1,t2,hi,lo)) DrawSession("NY",t1,t2,hi,lo,NYClr);
   }
   return(0);
}
