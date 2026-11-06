//+------------------------------------------------------------------+
//|                         SamuSignal News Pusher v1.02.mq5          |
//|  MT5 ka apna Economic Calendar -> Firebase /feed/news ->          |
//|  SAMUSIGNAL AI ka NEWS page (news.html). Asli (actual) number     |
//|  release ke kuch second me apne aap — haath se daalna nahi padta. |
//|                                                                    |
//|  Kya likhta hai (FirebaseURL wahi jo Data Feed / PERSONAL FX me):  |
//|   /feed/news/meta        {at, ver, acct, off, n}  (har 30 sec)     |
//|   /feed/news/cal         {at, list:[{id,t,title,imp,kind,fc,pv,act}]}|
//|                          aage DaysAhead din + pichhla 1 din,      |
//|                          har CalMin min + naya number aate hi      |
//|   /feed/news/act/<id>    {t,title,act,fc,pv,mi,seen,px:{XAUUSD,..}}|
//|                          number aate hi TURANT (1 sec ke andar)   |
//|   t / seen = UTC seconds. mi = MT5 ka andaza: +1 currency mazboot, |
//|   -1 kamzor, 0 pata nahi. px = usi pal ka bid (entry ke liye).     |
//|                                                                    |
//|  Lagana: VPS pe kisi bhi EK chart pe (Data Feed wale terminal pe   |
//|  theek, 434476133). Tools > Options > Expert Advisors > Allow      |
//|  WebRequest me Firebase URL pehle se hona chahiye.                |
//|  Trade KUCH NAHI karta.                                            |
//|                                                                    |
//|  v1.01: FIX — Firebase mana kare (401) to har 0.5 sec dobara nahi; |
//|         calendar 30 sec, 401 pe 2 min baad. Meta bhi 401 pe 2 min. |
//|  v1.02: TAPE — number aate hi 6 min tak HAR SECOND ka bid          |
//|         /feed/news/tape/<key> {t0, XAUUSD:"b,b,..", EURUSD:..}    |
//|         (har 3 sec bhejta hai). act me "tape":"<key>". App isse  |
//|         'maine trade liya' ka 1 min exit / $ target sahi ginta hai.|
//+------------------------------------------------------------------+
#property copyright   "SamuSignal"
#property description "SamuSignal News Pusher v1.02 — MT5 calendar ka actual number -> Firebase /feed/news (NEWS page auto signal). Trade nahi karta."
#property version     "1.02"
#property strict

input group "========== FIREBASE =========="
input string FirebaseURL   = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // Data Feed wala hi
input string FirebaseAuth  = "";        // sirf agar Firebase rules me chahiye

input group "========== NEWS =========="
input string Currencies    = "USD";     // comma se: USD,EUR
input bool   WithMedium    = true;      // Medium impact bhi bhejo (page pe setting se dikhti hai)
input int    DaysAhead     = 7;         // calendar aage kitne din
input int    CalMin        = 10;        // poora calendar har itne min
input string PricePairs    = "XAUUSD,EURUSD"; // number aate hi in ka bid bhi saath (entry)
input string SymbolSuffix  = "";        // khaali = khud dhoondho (XAUUSD -> XAUUSDm)

string   g_Cur[];
string   g_PxKey[], g_PxSym[];
ulong    g_Change = 0;
ulong    g_Sent[];            // jin value id ka actual bhej chuke
datetime g_LastCal = 0, g_LastMeta = 0, g_CalDue = 0;
bool     g_UrlWarned = false;
string   g_Status = "start", g_Last = "-";
int      g_LastCode = 0;      // v1.01: aakhri HTTP code (401 = auth chahiye)
#define  TAPE_SEC 360           // v1.02: news ke baad itne sec har second ka bhaav
string   g_TapeKey = "";
long     g_TapeT0 = 0;          // UTC sec
string   g_TapeV[];             // har pair ki "b,b,b"
int      g_TapeN = 0;           // kitne second bhar chuke
datetime g_TapeSent = 0;

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
   string u = Base()+"/feed/news/"+path+".json";
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
   return u;
}
bool Send(string path, string body)
{
   char data[], result[];
   string rh, hdr = "Content-Type: application/json\r\nX-HTTP-Method-Override: PUT\r\n";
   int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(n>0) ArrayResize(data, n-1);
   ResetLastError();
   int code = WebRequest("POST", Url(path), hdr, 5000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_Status = "URL ALLOW KARO";
         if(!g_UrlWarned){ g_UrlWarned = true; Alert("News Pusher: MT5 > Tools > Options > Expert Advisors > 'Allow WebRequest' me ye URL add karo: ", Base()); }
      }
      else g_Status = "NET ERR "+IntegerToString(err);
      return false;
   }
   g_LastCode = code;
   if(code<200 || code>=300)
   {
      g_Status = "HTTP "+IntegerToString(code);
      Print("News Pusher: HTTP ", code, " on ", path, " | ", StringSubstr(CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8), 0, 160),
            (code==401 || code==403) ? "  -> FirebaseAuth input bharo" : "");
      return false;
   }
   g_Status = "ON";
   return true;
}

string Esc(string s)
{
   StringReplace(s, "\\", "\\\\");
   StringReplace(s, "\"", "\\\"");
   return s;
}
long ServerOffset()
{
   long off = (long)(TimeTradeServer() - TimeGMT());
   return (long)MathRound(off/1800.0)*1800;
}
string ResolveSymbol(string want)
{
   if(SymbolSuffix!=""){ string s = want+SymbolSuffix; return SymbolSelect(s,true) ? s : ""; }
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
bool CurOk(string c)
{
   for(int i=0;i<ArraySize(g_Cur);i++) if(g_Cur[i]==c) return true;
   return false;
}
bool ImpOk(const MqlCalendarEvent &e)
{
   return e.importance==CALENDAR_IMPORTANCE_HIGH || (WithMedium && e.importance==CALENDAR_IMPORTANCE_MODERATE);
}
bool WasSent(ulong id)
{
   for(int i=0;i<ArraySize(g_Sent);i++) if(g_Sent[i]==id) return true;
   return false;
}
void MarkSent(ulong id)
{
   int n = ArraySize(g_Sent);
   if(n>=300){ ArrayRemove(g_Sent, 0, 100); n = ArraySize(g_Sent); }
   ArrayResize(g_Sent, n+1); g_Sent[n] = id;
}

// MT5 value (x 10^6) -> "0.4%" / "227K" / "-1.2B" (LONG_MIN = khaali)
string Fmt(long v, const MqlCalendarEvent &e)
{
   if(v==LONG_MIN) return "";
   string s = DoubleToString(v/1000000.0, (int)MathMax(0, MathMin(4, e.digits)));
   string m = "";
   switch(e.multiplier)
   {
      case CALENDAR_MULTIPLIER_THOUSANDS: m = "K"; break;
      case CALENDAR_MULTIPLIER_MILLIONS:  m = "M"; break;
      case CALENDAR_MULTIPLIER_BILLIONS:  m = "B"; break;
      case CALENDAR_MULTIPLIER_TRILLIONS: m = "T"; break;
      default: m = "";
   }
   if(e.unit==CALENDAR_UNIT_PERCENT) return s+"%";
   return s+m;
}
bool EventOf(const MqlCalendarValue &v, MqlCalendarEvent &e, string &cur)
{
   if(!CalendarEventById(v.event_id, e)) return false;
   MqlCalendarCountry c;
   if(!CalendarCountryById(e.country_id, c)) return false;
   cur = c.currency;
   return true;
}

//+------------------------------------------------------------------+
//| poora calendar (aage DaysAhead din + pichhla 1 din)               |
//+------------------------------------------------------------------+
bool SendCal()
{
   long off = ServerOffset();
   datetime now = TimeTradeServer();
   string list = "";
   int cnt = 0;
   for(int k=0;k<ArraySize(g_Cur);k++)
   {
      MqlCalendarValue vals[];
      int n = CalendarValueHistory(vals, now-86400, now+DaysAhead*86400, NULL, g_Cur[k]);
      for(int i=0;i<n;i++)
      {
         MqlCalendarEvent e; string cur;
         if(!EventOf(vals[i], e, cur) || !ImpOk(e) || e.type==CALENDAR_TYPE_HOLIDAY) continue;
         if(list!="") list += ",";
         list += "{\"id\":\""+IntegerToString((long)vals[i].id)+"\",\"t\":"+IntegerToString((long)vals[i].time-off)
               + ",\"title\":\""+Esc(e.name)+"\",\"cur\":\""+cur+"\",\"imp\":\""+(e.importance==CALENDAR_IMPORTANCE_HIGH ? "High" : "Medium")+"\""
               + ",\"kind\":\""+(e.type==CALENDAR_TYPE_INDICATOR ? "ind" : "event")+"\""
               + ",\"fc\":\""+Fmt(vals[i].forecast_value, e)+"\",\"pv\":\""+Fmt(vals[i].revised_prev_value!=LONG_MIN ? vals[i].revised_prev_value : vals[i].prev_value, e)+"\""
               + ",\"act\":\""+Fmt(vals[i].actual_value, e)+"\"}";
         cnt++;
      }
   }
   bool ok = Send("cal", "{\"at\":"+IntegerToString((long)TimeGMT())+",\"n\":"+IntegerToString(cnt)+",\"list\":["+list+"]}");
   if(ok) g_LastCal = TimeLocal();
   return ok;
}

string Prices()
{
   string p = "";
   for(int i=0;i<ArraySize(g_PxKey);i++)
   {
      MqlTick tk;
      if(!SymbolInfoTick(g_PxSym[i], tk) || tk.bid<=0) continue;
      if(p!="") p += ",";
      p += "\""+g_PxKey[i]+"\":"+DoubleToString(tk.bid, (int)SymbolInfoInteger(g_PxSym[i], SYMBOL_DIGITS));
   }
   return "{"+p+"}";
}

//+------------------------------------------------------------------+
//| v1.02: TAPE — news ke baad 6 min har second ka bid                |
//+------------------------------------------------------------------+
string TapeStart()
{
   long now = (long)TimeGMT();
   if(g_TapeKey!="" && now - g_TapeT0 < 10) return g_TapeKey;     // saath aayi news -> wahi tape
   g_TapeKey = IntegerToString(now); g_TapeT0 = now; g_TapeN = 0; g_TapeSent = 0;
   ArrayResize(g_TapeV, ArraySize(g_PxKey));
   for(int i=0;i<ArraySize(g_TapeV);i++) g_TapeV[i] = "";
   return g_TapeKey;
}
void TapeTick()
{
   if(g_TapeKey=="") return;
   long sec = (long)TimeGMT() - g_TapeT0;
   bool done = sec >= TAPE_SEC;
   if(sec > TAPE_SEC) sec = TAPE_SEC;
   bool add = false;
   while(g_TapeN <= sec && g_TapeN <= TAPE_SEC)               // timer der se aaye to beech ke second bhi bharo
   {
      for(int i=0;i<ArraySize(g_PxKey);i++)
      {
         MqlTick tk; string v = "0";
         if(SymbolInfoTick(g_PxSym[i], tk) && tk.bid>0) v = DoubleToString(tk.bid, (int)SymbolInfoInteger(g_PxSym[i], SYMBOL_DIGITS));
         g_TapeV[i] += (g_TapeN>0 ? "," : "") + v;
      }
      g_TapeN++; add = true;
   }
   if((add && TimeLocal() - g_TapeSent >= 3) || done)
   {
      string b = "{\"t0\":"+IntegerToString(g_TapeT0)+",\"n\":"+IntegerToString(g_TapeN);
      for(int i=0;i<ArraySize(g_PxKey);i++) b += ",\""+g_PxKey[i]+"\":\""+g_TapeV[i]+"\"";
      if(Send("tape/"+g_TapeKey, b+"}")) g_TapeSent = TimeLocal();
   }
   if(done){ Print("News Pusher: tape poora ", g_TapeKey, " (", g_TapeN, " sec)"); g_TapeKey = ""; }
}

//+------------------------------------------------------------------+
//| naya number? -> turant /feed/news/act/<id>                       |
//+------------------------------------------------------------------+
void CheckActual()
{
   MqlCalendarValue vals[];
   int n = CalendarValueLast(g_Change, vals);
   if(n<=0) return;
   long off = ServerOffset();
   datetime srv = TimeTradeServer();
   bool any = false;
   for(int i=0;i<n;i++)
   {
      if(vals[i].actual_value==LONG_MIN || WasSent(vals[i].id)) continue;
      if(srv - vals[i].time > 6*3600 || vals[i].time - srv > 600) continue;   // purani / door ki revision nahi
      MqlCalendarEvent e; string cur;
      if(!EventOf(vals[i], e, cur) || !CurOk(cur) || !ImpOk(e)) continue;
      int mi = vals[i].impact_type==CALENDAR_IMPACT_POSITIVE ? 1 : vals[i].impact_type==CALENDAR_IMPACT_NEGATIVE ? -1 : 0;
      string tape = TapeStart();
      string body = "{\"t\":"+IntegerToString((long)vals[i].time-off)+",\"title\":\""+Esc(e.name)+"\",\"cur\":\""+cur+"\""
                  + ",\"act\":\""+Fmt(vals[i].actual_value, e)+"\",\"fc\":\""+Fmt(vals[i].forecast_value, e)+"\""
                  + ",\"pv\":\""+Fmt(vals[i].revised_prev_value!=LONG_MIN ? vals[i].revised_prev_value : vals[i].prev_value, e)+"\""
                  + ",\"mi\":"+IntegerToString(mi)+",\"seen\":"+IntegerToString((long)TimeGMT())+",\"px\":"+Prices()+",\"tape\":\""+tape+"\"}";
      if(Send("act/"+IntegerToString((long)vals[i].id), body))
      {
         MarkSent(vals[i].id); any = true;
         g_Last = e.name+" "+Fmt(vals[i].actual_value, e)+" @ "+TimeToString(TimeLocal(), TIME_SECONDS);
         Print("News Pusher: ", g_Last);
      }
   }
   if(any) g_CalDue = TimeLocal()+3;      // calendar me bhi actual aa jaaye
}

//+------------------------------------------------------------------+
int OnInit()
{
   string parts[];
   ArrayResize(g_Cur, 0);
   int n = StringSplit(Currencies, ',', parts);
   for(int i=0;i<n;i++){ string c = parts[i]; StringTrimLeft(c); StringTrimRight(c); StringToUpper(c); if(c=="") continue; int m = ArraySize(g_Cur); ArrayResize(g_Cur, m+1); g_Cur[m] = c; }
   ArrayResize(g_PxKey, 0); ArrayResize(g_PxSym, 0);
   n = StringSplit(PricePairs, ',', parts);
   for(int i=0;i<n;i++)
   {
      string k = parts[i]; StringTrimLeft(k); StringTrimRight(k); StringToUpper(k);
      if(k=="") continue;
      string s = ResolveSymbol(k); if(s=="") continue;
      int m = ArraySize(g_PxKey); ArrayResize(g_PxKey, m+1); ArrayResize(g_PxSym, m+1); g_PxKey[m] = k; g_PxSym[m] = s;
   }
   MqlCalendarValue tmp[];
   g_Change = 0;
   CalendarValueLast(g_Change, tmp);           // pehli baar: sirf "abhi tak" ka nishaan, purane nahi
   Print("SamuSignal News Pusher v1.02 | ", Currencies, " | -> ", Base(), "/feed/news | change_id ", g_Change);
   g_CalDue = TimeLocal();
   EventSetMillisecondTimer(500);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason){ EventKillTimer(); Comment(""); }

void OnTimer()
{
   CheckActual();
   TapeTick();
   if(TimeLocal() >= g_CalDue)                         // v1.01: sirf g_CalDue (fail pe spam nahi)
   {
      g_CalDue = TimeLocal() + CalMin*60;
      if(!SendCal()) g_CalDue = TimeLocal() + ((g_LastCode==401 || g_LastCode==403) ? 120 : 30);
   }
   if(TimeLocal() - g_LastMeta >= ((g_LastCode==401 || g_LastCode==403) ? 120 : 30))
   {
      g_LastMeta = TimeLocal();
      Send("meta", "{\"at\":"+IntegerToString((long)TimeGMT())+",\"ver\":\"1.02\",\"acct\":"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))
                 + ",\"off\":"+IntegerToString(ServerOffset())+",\"n\":"+IntegerToString(ArraySize(g_Sent))+"}");
   }
   Comment("SamuSignal News Pusher v1.02 | ", g_Status, " | ", Currencies, " | aakhri: ", g_Last);
}
void OnTick(){}
//+------------------------------------------------------------------+
