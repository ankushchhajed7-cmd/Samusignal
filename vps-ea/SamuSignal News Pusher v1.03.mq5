//+------------------------------------------------------------------+
//|                         SamuSignal News Pusher v1.03.mq5          |
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
//|  v1.03: App band ho tab bhi —                                      |
//|   * PHONE PUSH (MT5 app): High news se 5 min / 1 min pehle, number |
//|     aate hi BUY/SELL, 1 min baad nateeja, $ target aane par.       |
//|     Tools > Options > Notifications me MetaQuotes ID + Enable.     |
//|   * AUTO PAPER TRADE yahin (VPS pe): har High news signal = paper  |
//|     trade (usi pal ka bid, 0.01 lot). 1 min exit / $ target (gold  |
//|     $10, baaki $3, na aaye to 30 min) / 5 min. -> /feed/news/paper |
//|     /<id>. App History isi ko dikhata hai. ORDER KABHI NAHI.       |
//|   Niyam (app jaisa): USD data forecast se zyada = USD mazboot ->   |
//|   XAUUSD/EURUSD SELL (USDxxx BUY); Unemployment/Claims me ulta;    |
//|   speech/statement = no trade; naam na pehchane to MT5 ka andaza.  |
//+------------------------------------------------------------------+
#property copyright   "SamuSignal"
#property description "SamuSignal News Pusher v1.03 — MT5 calendar ka actual number -> Firebase /feed/news (NEWS page auto signal). Trade nahi karta."
#property version     "1.03"
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

input group "========== PHONE PUSH (MT5 app) =========="
input bool   PushOn        = true;      // Tools > Options > Notifications: MetaQuotes ID + Enable
input string PushBeforeMin = "5,1";     // High news se itne min pehle yaad

input group "========== AUTO PAPER TRADE (sirf hisaab, ORDER NAHI) =========="
input bool   PaperOn       = true;
input double PaperLot      = 0.01;
input double TgtGold       = 10;        // XAUUSD target $
input double TgtOther      = 3;         // baaki pairs (EURUSD) target $

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
// v1.03: aane wali High news (pehle ki yaad) + paper trade
long     g_UpT[];  string g_UpName[], g_UpFc[], g_UpRule[]; string g_PreSent[];
int      g_PreMin[];
struct PTrade { string vid; string key; string sym; int dir; double entry, tp, lot, tgt, cs; long at; double p1, u1, p5, u5, uT; int hit; bool d1, d5, dT; };
struct PEv    { string vid; string head; string title; long at; bool dirty, push1, done; };
PTrade   g_P[];
PEv      g_E[];

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
//| v1.03: niyam (app ke newsrules.js jaisa)                          |
//+------------------------------------------------------------------+
bool HasAny(string low, string &w[]){ for(int i=0;i<ArraySize(w);i++) if(StringFind(low, w[i])>=0) return true; return false; }
bool Speechy(string name)
{
   string low = name; StringToLower(low);
   string w[] = {"speaks","speech","testifies","testimony","press conference","minutes","statement","member","meeting","beige","auction","bill ","bond","holiday","president","chair"};
   return HasAny(low, w);
}
int Polarity(string name)            // +1 zyada = USD mazboot, -1 zyada = USD kamzor, 0 niyam nahi
{
   if(Speechy(name)) return 0;
   string low = name; StringToLower(low);
   string neg[] = {"unemployment","jobless","claims"};
   if(HasAny(low, neg)) return -1;
   string pos[] = {"non-farm","nonfarm","nfp","employment change","average hourly","payroll","cpi","ppi","pce","retail sales","gdp","ism","pmi","durable",
                   "industrial production","consumer confidence","consumer sentiment","michigan","uom","jolts","job openings","housing starts","building permits",
                   "home sales","federal funds","interest rate","core "};
   return HasAny(low, pos) ? 1 : 0;
}
int PairDir(string key, int usd){ return StringFind(key, "USD")==0 ? usd : -usd; }   // +1 BUY / -1 SELL
string DirS(int d){ return d>0 ? "BUY" : "SELL"; }
string Ist(long utc){ return StringSubstr(TimeToString((datetime)(utc+19800), TIME_DATE|TIME_MINUTES), 11); }
void Push(string msg)
{
   if(!PushOn || msg=="") return;
   msg = StringSubstr(msg, 0, 250);
   if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)){ Print("News Pusher PUSH (band — Options > Notifications): ", msg); return; }
   if(!SendNotification(msg)) Print("News Pusher: push nahi gaya (", GetLastError(), "): ", msg);
}
string Num(double v, int d){ return DoubleToString(v, d); }
string Usd(double v){ return (v>=0 ? "+$" : "-$")+DoubleToString(MathAbs(v), 2); }

//+------------------------------------------------------------------+
//| poora calendar (aage DaysAhead din + pichhla 1 din)               |
//+------------------------------------------------------------------+
bool SendCal()
{
   long off = ServerOffset();
   datetime now = TimeTradeServer();
   string list = "";
   int cnt = 0;
   ArrayResize(g_UpT, 0); ArrayResize(g_UpName, 0); ArrayResize(g_UpFc, 0); ArrayResize(g_UpRule, 0);
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
         long tu = (long)vals[i].time-off;
         if(e.importance==CALENDAR_IMPORTANCE_HIGH && tu > (long)TimeGMT() && g_Cur[k]=="USD")
         {
            int pol = Polarity(e.name);
            if(pol==0 && (e.type!=CALENDAR_TYPE_INDICATOR || Speechy(e.name))) continue;     // speech: yaad nahi
            int m = ArraySize(g_UpT);
            ArrayResize(g_UpT, m+1); ArrayResize(g_UpName, m+1); ArrayResize(g_UpFc, m+1); ArrayResize(g_UpRule, m+1);
            g_UpT[m] = tu; g_UpName[m] = e.name; g_UpFc[m] = Fmt(vals[i].forecast_value, e);
            g_UpRule[m] = pol==0 ? "MT5 andaza" : ("zyada="+DirS(PairDir("XAUUSD", pol))+" kam="+DirS(PairDir("XAUUSD", -pol)));
         }
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
//| v1.03: High news se pehle yaad (ek time ki saari news ek push me) |
//+------------------------------------------------------------------+
bool PreDone(string k){ for(int i=0;i<ArraySize(g_PreSent);i++) if(g_PreSent[i]==k) return true; return false; }
void PreAlerts()
{
   long now = (long)TimeGMT();
   for(int m=0;m<ArraySize(g_PreMin);m++)
   {
      int pm = g_PreMin[m];
      string msg = ""; long tt = 0;
      for(int i=0;i<ArraySize(g_UpT);i++)
      {
         long left = g_UpT[i] - now;
         if(left > pm*60 || left <= pm*60 - 90) continue;
         string k = IntegerToString(g_UpT[i])+"|"+g_UpName[i]+"|"+IntegerToString(pm);
         if(PreDone(k)) continue;
         int n = ArraySize(g_PreSent); if(n>=200){ ArrayResize(g_PreSent, 0); n = 0; }
         ArrayResize(g_PreSent, n+1); g_PreSent[n] = k;
         msg += (msg=="" ? "" : " | ")+g_UpName[i]+" F "+(g_UpFc[i]=="" ? "-" : g_UpFc[i])+" ("+g_UpRule[i]+")";
         tt = g_UpT[i];
      }
      if(msg!="") Push("NEWS "+IntegerToString(pm)+" min me ("+Ist(tt)+" IST): "+msg+" — gold/EURUSD. News page kholo.");
   }
}

//+------------------------------------------------------------------+
//| v1.03: AUTO PAPER TRADE (VPS pe, ORDER NAHI)                      |
//+------------------------------------------------------------------+
int EvIdx(string vid){ for(int i=0;i<ArraySize(g_E);i++) if(g_E[i].vid==vid) return i; return -1; }
string PNum(double v, bool ok, int d){ return ok ? DoubleToString(v, d) : "null"; }
void PaperWrite(int ei)
{
   string sg = "";
   for(int i=0;i<ArraySize(g_P);i++)
   {
      if(g_P[i].vid!=g_E[ei].vid) continue;
      int dg = (int)SymbolInfoInteger(g_P[i].sym, SYMBOL_DIGITS);
      if(sg!="") sg += ",";
      sg += "\""+g_P[i].key+"\":{\"dir\":\""+DirS(g_P[i].dir)+"\",\"entry\":"+Num(g_P[i].entry, dg)+",\"tp\":"+Num(g_P[i].tp, dg)
          + ",\"lot\":"+Num(g_P[i].lot, 2)+",\"tgt\":"+Num(g_P[i].tgt, 2)
          + ",\"p1\":"+PNum(g_P[i].p1, g_P[i].d1, dg)+",\"u1\":"+PNum(g_P[i].u1, g_P[i].d1, 2)
          + ",\"p5\":"+PNum(g_P[i].p5, g_P[i].d5, dg)+",\"u5\":"+PNum(g_P[i].u5, g_P[i].d5, 2)
          + ",\"hit\":"+(g_P[i].hit>0 ? IntegerToString(g_P[i].hit) : "null")+",\"uT\":"+PNum(g_P[i].uT, g_P[i].dT, 2)+"}";
   }
   if(Send("paper/"+g_E[ei].vid, "{"+g_E[ei].head+",\"at\":"+IntegerToString(g_E[ei].at)+",\"done\":"+(g_E[ei].done ? "true" : "false")+",\"sigs\":{"+sg+"}}"))
      g_E[ei].dirty = false;
}
// number aate hi: signal + paper trade. return: push line
string PaperOpen(string vid, const MqlCalendarValue &v, const MqlCalendarEvent &e, int mi, long tUtc)
{
   if(e.importance!=CALENDAR_IMPORTANCE_HIGH) return "";
   string fc = Fmt(v.forecast_value, e), act = Fmt(v.actual_value, e);
   int pol = Polarity(e.name);
   bool mtOnly = (pol==0 && e.type==CALENDAR_TYPE_INDICATOR && !Speechy(e.name) && mi!=0);
   if(pol==0 && !mtOnly) return e.name+" "+act+": niyam nahi (speech/statement) — no trade";
   if(v.forecast_value==LONG_MIN) return e.name+" "+act+": forecast nahi — no trade";
   double a = v.actual_value/1000000.0, f = v.forecast_value/1000000.0;
   long pvl = v.revised_prev_value!=LONG_MIN ? v.revised_prev_value : v.prev_value;
   double p = pvl==LONG_MIN ? 0 : pvl/1000000.0;
   double sur = a - f;
   if(sur==0) return e.name+" "+act+" = forecast "+fc+": NO TRADE";
   int usd = mtOnly ? mi : (sur>0 ? 1 : -1)*pol;
   double scale = MathMax(MathMax(MathAbs(f), MathAbs(p)), 1e-9);
   int conf = 50 + (int)MathMin(15, MathRound(MathAbs(sur)/scale*30));
   long now = (long)TimeGMT();
   string line = "", pxs = "";
   if(PaperOn && EvIdx(vid)<0)
   {
      int ei = ArraySize(g_E); ArrayResize(g_E, ei+1);
      g_E[ei].vid = vid; g_E[ei].at = now; g_E[ei].title = e.name; g_E[ei].dirty = true; g_E[ei].push1 = false; g_E[ei].done = false;
      g_E[ei].head = "\"t\":"+IntegerToString(tUtc)+",\"title\":\""+Esc(e.name)+"\",\"act\":\""+act+"\",\"fc\":\""+fc+"\",\"pv\":\""+Fmt(pvl, e)+"\""
                   + ",\"usd\":"+IntegerToString(usd)+",\"conf\":"+IntegerToString(conf)+",\"mt\":"+(mtOnly ? "true" : "false");
   }
   for(int i=0;i<ArraySize(g_PxKey);i++)
   {
      MqlTick tk; if(!SymbolInfoTick(g_PxSym[i], tk) || tk.bid<=0) continue;
      int d = PairDir(g_PxKey[i], usd), dg = (int)SymbolInfoInteger(g_PxSym[i], SYMBOL_DIGITS);
      line += (line=="" ? "" : " ")+g_PxKey[i]+" "+DirS(d);
      pxs  += (pxs=="" ? "" : " ")+g_PxKey[i]+" "+Num(tk.bid, dg);
      if(!PaperOn) continue;
      double cs = SymbolInfoDouble(g_PxSym[i], SYMBOL_TRADE_CONTRACT_SIZE); if(cs<=0) cs = StringFind(g_PxKey[i],"XAU")==0 ? 100 : 100000;
      double tgt = StringFind(g_PxKey[i],"XAU")==0 ? TgtGold : TgtOther;
      int k = ArraySize(g_P); ArrayResize(g_P, k+1);
      g_P[k].vid = vid; g_P[k].key = g_PxKey[i]; g_P[k].sym = g_PxSym[i]; g_P[k].dir = d; g_P[k].entry = tk.bid; g_P[k].lot = PaperLot; g_P[k].tgt = tgt; g_P[k].cs = cs;
      g_P[k].tp = tk.bid + d*tgt/(cs*PaperLot); g_P[k].at = now; g_P[k].hit = 0; g_P[k].d1 = g_P[k].d5 = g_P[k].dT = false;
      g_P[k].p1 = g_P[k].u1 = g_P[k].p5 = g_P[k].u5 = g_P[k].uT = 0;
   }
   int ei2 = EvIdx(vid); if(ei2>=0) PaperWrite(ei2);
   return line+" | "+e.name+" "+act+" vs "+fc+" F | "+IntegerToString(conf)+"% | "+pxs;
}
void PaperTick()
{
   if(ArraySize(g_P)==0) return;
   long now = (long)TimeGMT();
   string tpMsg = "";
   for(int i=0;i<ArraySize(g_P);i++)
   {
      if(g_P[i].d1 && g_P[i].d5 && g_P[i].dT) continue;
      MqlTick tk; if(!SymbolInfoTick(g_P[i].sym, tk) || tk.bid<=0) continue;
      double b = tk.bid, mul = g_P[i].dir*g_P[i].cs*g_P[i].lot;
      int ei = EvIdx(g_P[i].vid);
      if(!g_P[i].d1 && now >= g_P[i].at+60){ g_P[i].d1 = true; g_P[i].p1 = b; g_P[i].u1 = MathRound((b-g_P[i].entry)*mul*100)/100; if(ei>=0) g_E[ei].dirty = true; }
      if(!g_P[i].d5 && now >= g_P[i].at+300){ g_P[i].d5 = true; g_P[i].p5 = b; g_P[i].u5 = MathRound((b-g_P[i].entry)*mul*100)/100; if(ei>=0) g_E[ei].dirty = true; }
      if(!g_P[i].dT)
      {
         if((g_P[i].dir>0 && b>=g_P[i].tp) || (g_P[i].dir<0 && b<=g_P[i].tp))
         {
            g_P[i].dT = true; g_P[i].hit = (int)MathMax(1, now-g_P[i].at); g_P[i].uT = g_P[i].tgt; if(ei>=0) g_E[ei].dirty = true;
            tpMsg += (tpMsg=="" ? "" : " | ")+g_P[i].key+" "+DirS(g_P[i].dir)+" $"+DoubleToString(g_P[i].tgt, 0)+" TP "+IntegerToString(g_P[i].hit)+"s me";
         }
         else if(now >= g_P[i].at+1800){ g_P[i].dT = true; g_P[i].uT = MathRound((b-g_P[i].entry)*mul*100)/100; if(ei>=0) g_E[ei].dirty = true; }
      }
   }
   if(tpMsg!="") Push("TARGET: "+tpMsg+" (paper)");
   for(int ei=ArraySize(g_E)-1; ei>=0; ei--)
   {
      bool all1 = true, all = true; string m1 = "";
      for(int i=0;i<ArraySize(g_P);i++)
      {
         if(g_P[i].vid!=g_E[ei].vid) continue;
         if(!g_P[i].d1) all1 = false; else m1 += (m1=="" ? "" : " ")+g_P[i].key+" "+Usd(g_P[i].u1);
         if(!(g_P[i].d1 && g_P[i].d5 && g_P[i].dT)) all = false;
      }
      if(all1 && !g_E[ei].push1){ g_E[ei].push1 = true; Push("1 MIN nateeja (paper): "+m1+" | "+g_E[ei].title); }
      if(all) g_E[ei].done = true;
      if(g_E[ei].dirty) PaperWrite(ei);
      if(g_E[ei].done && !g_E[ei].dirty)                     // poora -> memory se hatao
      {
         string vid = g_E[ei].vid; int w = 0;
         for(int i=0;i<ArraySize(g_P);i++) if(g_P[i].vid!=vid){ if(w!=i) g_P[w] = g_P[i]; w++; }
         ArrayResize(g_P, w);
         for(int j=ei;j<ArraySize(g_E)-1;j++) g_E[j] = g_E[j+1];
         ArrayResize(g_E, ArraySize(g_E)-1);
      }
   }
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
   string pushMsg = "";
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
         string pl = PaperOpen(IntegerToString((long)vals[i].id), vals[i], e, mi, (long)vals[i].time-off);   // v1.03
         if(pl!="") pushMsg += (pushMsg=="" ? "" : " || ")+pl;
         g_Last = e.name+" "+Fmt(vals[i].actual_value, e)+" @ "+TimeToString(TimeLocal(), TIME_SECONDS);
         Print("News Pusher: ", g_Last);
      }
   }
   if(pushMsg!="") Push("SIGNAL: "+pushMsg+" (paper)");
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
   ArrayResize(g_PreMin, 0);
   n = StringSplit(PushBeforeMin, ',', parts);
   for(int i=0;i<n;i++){ int v = (int)StringToInteger(parts[i]); if(v>0){ int m = ArraySize(g_PreMin); ArrayResize(g_PreMin, m+1); g_PreMin[m] = v; } }
   if(PushOn && !TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) Print("News Pusher: PHONE PUSH band hai — Tools > Options > Notifications me MetaQuotes ID daalo + Enable");
   MqlCalendarValue tmp[];
   g_Change = 0;
   CalendarValueLast(g_Change, tmp);           // pehli baar: sirf "abhi tak" ka nishaan, purane nahi
   Print("SamuSignal News Pusher v1.03 | ", Currencies, " | -> ", Base(), "/feed/news | change_id ", g_Change);
   g_CalDue = TimeLocal();
   EventSetMillisecondTimer(500);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason){ EventKillTimer(); Comment(""); }

void OnTimer()
{
   CheckActual();
   TapeTick();
   PaperTick();                                        // v1.03
   PreAlerts();
   if(TimeLocal() >= g_CalDue)                         // v1.01: sirf g_CalDue (fail pe spam nahi)
   {
      g_CalDue = TimeLocal() + CalMin*60;
      if(!SendCal()) g_CalDue = TimeLocal() + ((g_LastCode==401 || g_LastCode==403) ? 120 : 30);
   }
   if(TimeLocal() - g_LastMeta >= ((g_LastCode==401 || g_LastCode==403) ? 120 : 30))
   {
      g_LastMeta = TimeLocal();
      Send("meta", "{\"at\":"+IntegerToString((long)TimeGMT())+",\"ver\":\"1.03\",\"acct\":"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))
                 + ",\"off\":"+IntegerToString(ServerOffset())+",\"n\":"+IntegerToString(ArraySize(g_Sent))+"}");
   }
   Comment("SamuSignal News Pusher v1.03 | ", g_Status, " | ", Currencies, " | push ", (PushOn && TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) ? "ON" : "OFF",
           " | paper ", ArraySize(g_E), " | aakhri: ", g_Last);
}
void OnTick(){}
//+------------------------------------------------------------------+
