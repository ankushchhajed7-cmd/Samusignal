//+------------------------------------------------------------------+
//|                              SamuSignal Data Feed v1.0.mq5         |
//|  MT5 (broker) ka bhaav -> Firebase /feed  ->  SamuSignal app +     |
//|  Auto Alert robot. TwelveData ki jagah broker ka EXACT data,       |
//|  koi credit nahi.                                                  |
//|                                                                    |
//|  Kya likhta hai (Firebase, FirebaseURL wahi jo PERSONAL FX me):    |
//|   /feed/meta              {at, off, acct, ver, n}  (har LiveSec)   |
//|   /feed/live/<SYM>        {b, a, sp, t, f:{1min,5min,15min,1h,1day}}|
//|                           f = abhi bann rahi candle [t,o,h,l,c]    |
//|   /feed/bars/<tf>/<SYM>   "t,o,h,l,c;t,o,h,l,c;..." band candles   |
//|                           (aakhri Bars_N, purani pehle). tf =       |
//|                           1min / 5min / 15min / 1h. Nayi candle     |
//|                           band hote hi + har ResendMin min.         |
//|   t = UTC seconds. SYM = broker suffix ke bina (EURUSDm -> EURUSD). |
//|                                                                    |
//|  Lagana: VPS pe kisi bhi EK chart pe (demo account theek hai).     |
//|  MT5 > Tools > Options > Expert Advisors > Allow WebRequest me      |
//|  Firebase URL (PERSONAL FX wala hi) pehle se hona chahiye.         |
//|  Trade KUCH NAHI karta.                                            |
//+------------------------------------------------------------------+
#property copyright   "SamuSignal"
#property description "SamuSignal Data Feed v1.0 — broker candles + live price -> Firebase /feed (app + Auto Alert). Trade nahi karta."
#property version     "1.00"
#property strict

input group "========== FIREBASE =========="
input string FirebaseURL   = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // PERSONAL FX / app wala hi
input string FirebaseAuth  = "";        // sirf agar Firebase rules me chahiye (app jaisa)

input group "========== FEED =========="
input string Pairs         = "EURUSD,GBPUSD,USDJPY,USDCHF,USDCAD,AUDUSD,NZDUSD,EURJPY,EURGBP,EURCHF,EURCAD,EURAUD,EURNZD,GBPJPY,GBPCHF,GBPCAD,GBPAUD,GBPNZD,AUDJPY,AUDCHF,AUDCAD,AUDNZD,NZDJPY,NZDCHF,NZDCAD,CADCHF,CADJPY,CHFJPY,XAUUSD,BTCUSD";
input string SymbolSuffix  = "";        // khaali = khud dhoondho (EURUSD -> EURUSDm). Ya force jaise "m"
input int    Bars_N        = 250;       // har timeframe ki band candles
input int    LiveSec       = 10;        // live bhaav + bann rahi candle har itne sec
input int    ResendMin     = 5;         // band candles bina nayi candle ke bhi itne min me dobara

#define NTF 4
string          g_TfName[NTF] = {"1min","5min","15min","1h"};
ENUM_TIMEFRAMES g_Tf[NTF]     = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1};

string   g_Key[];       // app ka naam: EURUSD
string   g_Sym[];       // broker ka naam: EURUSDm
datetime g_LastBar[NTF];
datetime g_LastSend[NTF];
datetime g_LastLive = 0;
bool     g_UrlWarned = false;
string   g_Status = "start";

//+------------------------------------------------------------------+
string Base()
{
   string u = FirebaseURL;
   StringTrimLeft(u); StringTrimRight(u);
   while(StringLen(u)>0 && StringGetCharacter(u, StringLen(u)-1)=='/')
      u = StringSubstr(u, 0, StringLen(u)-1);
   if(u!="" && StringFind(u,"http")!=0) u = "https://"+u;
   return u;
}
string Url(string path)
{
   string u = Base()+(path=="" ? "/feed.json" : "/feed/"+path+".json");
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
   return u;
}

// PUT / PATCH (method override - har MT5 build pe chalta hai)
bool Send(string path, string body, bool patch)
{
   char data[], result[];
   string rh;
   string hdr = "Content-Type: application/json\r\n";
   if(patch) hdr += "X-HTTP-Method-Override: PATCH\r\n";
   else      hdr += "X-HTTP-Method-Override: PUT\r\n";
   int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(n>0) ArrayResize(data, n-1);
   ResetLastError();
   int code = WebRequest("POST", Url(path), hdr, 8000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_Status = "URL ALLOW KARO";
         if(!g_UrlWarned){ g_UrlWarned = true; Alert("Data Feed: MT5 > Tools > Options > Expert Advisors > 'Allow WebRequest' me ye URL add karo: ", Base()); }
      }
      else g_Status = "NET ERR "+IntegerToString(err);
      return false;
   }
   if(code<200 || code>=300)
   {
      string resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      g_Status = "HTTP "+IntegerToString(code);
      Print("Data Feed: HTTP ", code, " on ", path, " | ", StringSubstr(resp, 0, 160),
            (code==401 || code==403) ? "  -> Firebase rules: FirebaseAuth input bharo (app wala secret)" : "");
      return false;
   }
   g_Status = "ON";
   return true;
}

string ResolveSymbol(string want)
{
   if(SymbolSuffix!="")
   {
      string s = want+SymbolSuffix;
      return SymbolSelect(s,true) ? s : "";
   }
   if(SymbolSelect(want,true)) return want;
   int total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false), up = s;
      StringToUpper(up);
      if(StringFind(up,want)==0 && SymbolSelect(s,true)) return s;
   }
   return "";
}

// server time -> UTC (aadhe ghante tak gol)
long ServerOffset()
{
   long off = (long)(TimeTradeServer() - TimeGMT());
   return (long)MathRound(off/1800.0)*1800;
}

string Px(string sym, double v)
{
   return DoubleToString(v, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
int OnInit()
{
   string parts[];
   int n = StringSplit(Pairs, ',', parts);
   ArrayResize(g_Key, 0); ArrayResize(g_Sym, 0);
   string miss = "";
   for(int i=0;i<n;i++)
   {
      string k = parts[i];
      StringTrimLeft(k); StringTrimRight(k); StringToUpper(k);
      if(k=="") continue;
      string s = ResolveSymbol(k);
      if(s==""){ miss += k+" "; continue; }
      int m = ArraySize(g_Key);
      ArrayResize(g_Key, m+1); ArrayResize(g_Sym, m+1);
      g_Key[m] = k; g_Sym[m] = s;
   }
   for(int t=0;t<NTF;t++){ g_LastBar[t] = 0; g_LastSend[t] = 0; }
   Print("SamuSignal Data Feed v1.0 | ", ArraySize(g_Key), " symbols -> ", Base(), "/feed",
         miss!="" ? " | NAHI MILE: "+miss : "", " | server offset ", ServerOffset()/3600.0, " h");
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

//+------------------------------------------------------------------+
//| live: bid/ask/spread + har TF ki bann rahi candle (ek hi PATCH)   |
//+------------------------------------------------------------------+
void SendLive()
{
   long off = ServerOffset();
   ENUM_TIMEFRAMES tfs[5] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_D1};
   string nm[5] = {"1min","5min","15min","1h","1day"};
   string live = "";
   int ok = 0;
   for(int i=0;i<ArraySize(g_Key);i++)
   {
      string s = g_Sym[i];
      MqlTick tk;
      if(!SymbolInfoTick(s, tk) || tk.bid<=0) continue;
      string f = "";
      for(int t=0;t<5;t++)
      {
         MqlRates r[];
         if(CopyRates(s, tfs[t], 0, 1, r)!=1) continue;
         if(f!="") f += ",";
         f += "\""+nm[t]+"\":["+IntegerToString((long)r[0].time-off)+","+Px(s,r[0].open)+","+Px(s,r[0].high)+","+Px(s,r[0].low)+","+Px(s,r[0].close)+"]";
      }
      if(live!="") live += ",";
      live += "\""+g_Key[i]+"\":{\"b\":"+Px(s,tk.bid)+",\"a\":"+Px(s,tk.ask)+",\"sp\":"+Px(s,tk.ask-tk.bid)
              +",\"t\":"+IntegerToString((long)tk.time-off)+",\"f\":{"+f+"}}";
      ok++;
   }
   string meta = "{\"at\":"+IntegerToString((long)TimeGMT())+",\"off\":"+IntegerToString(off)
                 +",\"acct\":"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+",\"ver\":\"1.0\",\"n\":"+IntegerToString(ok)+"}";
   Send("", "{\"meta\":"+meta+",\"live\":{"+live+"}}", true);
}

//+------------------------------------------------------------------+
//| band candles: ek TF ke saare symbols ek hi PUT me                 |
//+------------------------------------------------------------------+
bool SendBars(int t)
{
   long off = ServerOffset();
   string body = "";
   for(int i=0;i<ArraySize(g_Key);i++)
   {
      string s = g_Sym[i];
      MqlRates r[];
      int got = CopyRates(s, g_Tf[t], 1, Bars_N, r);       // 1 = sirf band candles
      if(got<=0) continue;
      string v = "";
      for(int k=0;k<got;k++)
      {
         if(k>0) v += ";";
         v += IntegerToString((long)r[k].time-off)+","+Px(s,r[k].open)+","+Px(s,r[k].high)+","+Px(s,r[k].low)+","+Px(s,r[k].close);
      }
      if(body!="") body += ",";
      body += "\""+g_Key[i]+"\":\""+v+"\"";
   }
   if(body=="") return false;
   return Send("bars/"+g_TfName[t], "{"+body+"}", false);
}

void OnTimer()
{
   if(ArraySize(g_Key)==0) return;
   datetime now = TimeCurrent();
   if(TimeLocal() - g_LastLive >= LiveSec)
   {
      g_LastLive = TimeLocal();
      SendLive();
   }
   for(int t=0;t<NTF;t++)
   {
      datetime last = iTime(g_Sym[0], g_Tf[t], 1);           // pehle symbol ki aakhri band candle
      bool newBar = (last>0 && last!=g_LastBar[t]);
      bool stale  = (TimeLocal() - g_LastSend[t] >= ResendMin*60);
      if(!newBar && !stale) continue;
      if(newBar) Sleep(1500);                                 // baaki pairs ki candle bhi band ho jaaye
      if(SendBars(t)){ g_LastBar[t] = last; g_LastSend[t] = TimeLocal(); }
      else g_LastSend[t] = TimeLocal() - ResendMin*60 + 30;  // fail -> 30 sec baad dobara
   }
   Comment("SamuSignal Data Feed v1.0 | ", g_Status, " | ", ArraySize(g_Key), " symbols | ", TimeToString(now, TIME_SECONDS));
}

void OnTick(){}
//+------------------------------------------------------------------+
