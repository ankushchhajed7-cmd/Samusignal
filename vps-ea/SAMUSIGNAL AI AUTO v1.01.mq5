//+------------------------------------------------------------------+
//|                                   SAMUSIGNAL AI AUTO v1.01.mq5   |
//|                                           Ankush New Vision      |
//+------------------------------------------------------------------+
//|  v1.01: Inputs ke naam saaf (MT5 note dikhata hai): FirebaseAuth, |
//|         TP $, SL $ ... Kaam me koi badlav nahi.                  |
//|  KAAM:                                                           |
//|   VPS Scanner (C:\SamuScanner, node scanner.mjs) har 15m candle  |
//|   par app wala engine + Gemini AI chalata hai. "AI sahmat" signal  |
//|   Firebase /samuai/auto/sig me aata hai -> ye EA LIMIT order.    |
//|                                                                  |
//|  NIYAM (user, 11 Nov 2026):                                      |
//|   - XAUUSD / BTCUSD nahi. Sirf AI sahmat (bharosa >= MinConf).   |
//|   - TP $0.25 / SL $1.50 (0.01 lot par; lot ke saath badhta).     |
//|   - 1 pair = 1 trade (EA ka trade / pending band hone tak naya   |
//|     nahi). Ek signal sirf ek baar. Jitne pair sahmat, sab le.    |
//|   - High news se 60 min pehle se 60 min baad tak naya order nahi |
//|     aur is beech EA ke saare PENDING cancel. Chalu trade chalta  |
//|     rehta hai (SL laga hai).                                     |
//|   - Spread filter: spread > TP doori ka MaxSpreadPctOfTP %.       |
//|   - Din me 4 loss YA din ka profit $5 -> us din naya trade nahi, |
//|     pending cancel; chalu trade apne TP / SL tak chalte hain.    |
//|   - LIMIT 60 min me na bhare -> cancel.                          |
//|   - SURAKSHA: REAL account par tabhi trade jab AllowReal = true  |
//|     (user ne DEMO kaha hai).                                     |
//|                                                                  |
//|  MT5: Tools > Options > Expert Advisors > Allow WebRequest me    |
//|  Firebase URL (News Pusher wala hi) hona chahiye. Push ke liye    |
//|  MetaQuotes ID set ho. EA kisi bhi EK chart par lagao.           |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.01"
#property description "SAMUSIGNAL AI AUTO - VPS scanner ke AI sahmat signal par LIMIT (TP $0.25 / SL $1.50), news + din ki seema"

#include <Trade\Trade.mqh>
CTrade trade;

input group "========== FIREBASE =========="
input string FirebaseURL       = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // FirebaseURL (mat badlo)
input string FirebaseAuth      = "";        // FirebaseAuth (News Pusher wala hi)

input group "========== TRADE =========="
input double Lot               = 0.01;      // Lot
input double TP_Usd            = 0.25;      // TP $ (0.01 lot par)
input double SL_Usd            = 1.50;      // SL $ (0.01 lot par)
input int    PendingMin        = 60;        // LIMIT kitne min me na bhare to cancel
input int    MaxSigAgeMin      = 15;        // Signal kitne min se purana ho to nahi
input int    MinConf           = 70;        // AI bharosa kam se kam %
input string ExcludeCSV        = "XAUUSD,BTCUSD"; // In pair par trade nahi
input string SymbolSuffix      = "";        // Symbol suffix (khaali = apne aap)
input long   Magic             = 7310001;   // Magic number
input bool   AllowReal         = false;     // REAL account par trade? (false = sirf DEMO)

input group "========== SPREAD =========="
input double MaxSpreadPctOfTP  = 25;        // Spread max % (TP doori ka)

input group "========== NEWS =========="
input bool   NewsOn            = true;      // News filter chalu
input int    NewsBeforeMin     = 60;        // News se kitne min pehle
input int    NewsAfterMin      = 60;        // News ke kitne min baad
input bool   NewsWithMedium    = false;     // Medium news bhi

input group "========== DIN KI SEEMA =========="
input int    MaxLossesPerDay   = 4;         // Din me kitne loss par band (0 = kabhi nahi)
input double DailyTargetUsd    = 5.0;       // Din ka profit target $ (0 = kabhi nahi)

input group "========== DUSRA =========="
input int    PollSec           = 5;         // Firebase har kitne sec dekhe
input bool   PushOn            = true;      // Phone par push

#define VER "1.01"
string PAIRS28[] = {"EURUSD","GBPUSD","USDJPY","USDCHF","USDCAD","AUDUSD","NZDUSD","EURJPY","EURGBP","EURCHF","EURCAD","EURAUD","EURNZD",
                    "GBPJPY","GBPCHF","GBPCAD","GBPAUD","GBPNZD","AUDJPY","AUDCHF","AUDCAD","AUDNZD","NZDJPY","NZDCHF","NZDCAD","CADCHF","CADJPY","CHFJPY"};

string   g_Done[400];  int g_DoneN = 0;
string   g_Status = "shuru...", g_LastSig = "-", g_ScanTxt = "-", g_StopWhy = "";
bool     g_Stop = false, g_Real = false, g_UrlWarned = false, g_NeedCheck = true;
int      g_Losses = 0, g_StopDay = -1;
double   g_Net = 0;
datetime g_NewsT[]; string g_NewsCur[], g_NewsName[]; datetime g_NewsLoaded = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(20);
   g_Real = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   if(g_Real && !AllowReal)
   {
      g_Status = "REAL account - AllowReal=false, trade NAHI";
      Alert("SAMUSIGNAL AI AUTO: ye REAL account hai. User ne DEMO kaha hai - is account par koi order nahi lagega (AllowReal=false).");
   }
   EventSetTimer(1);
   Print("SAMUSIGNAL AI AUTO v", VER, " shuru | TP $", DoubleToString(TP_Usd,2), " SL $", DoubleToString(SL_Usd,2),
         " lot ", DoubleToString(Lot,2), " | news ", NewsBeforeMin, "/", NewsAfterMin, " min | din: ", MaxLossesPerDay, " loss / $", DoubleToString(DailyTargetUsd,2));
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ EventKillTimer(); Comment(""); }
void OnTick(){}

void OnTimer()
{
   static datetime lastChk = 0, lastPoll = 0, lastState = 0, lastScan = 0;
   datetime now = TimeLocal();
   if(g_NeedCheck || now - lastChk >= 10)
   {
      g_NeedCheck = false; lastChk = now;
      CheckDay();
      CheckExpiry();
      CheckNewsPending();
   }
   if((int)(now - lastPoll) >= (PollSec < 2 ? 2 : PollSec)){ lastPoll = now; PollSigs(); }
   if(now - lastState >= 30){ lastState = now; PublishState(); }
   if(now - lastScan >= 60){ lastScan = now; ReadScan(); }
   Panel();
}

//+------------------------------------------------------------------+
//| Firebase                                                         |
//+------------------------------------------------------------------+
string FbBase()
{
   string u = FirebaseURL;
   StringTrimLeft(u); StringTrimRight(u);
   while(StringLen(u)>0 && StringGetCharacter(u, StringLen(u)-1)=='/') u = StringSubstr(u, 0, StringLen(u)-1);
   if(u!="" && StringFind(u,"http")!=0) u = "https://"+u;
   return u;
}
string FbUrl(string path, string query)
{
   string u = FbBase()+"/samuai/auto/"+path+".json";
   string q = query;
   if(FirebaseAuth!="") q = (q=="" ? "" : q+"&") + "auth="+FirebaseAuth;
   if(q!="") u += "?"+q;
   return u;
}
bool Http(string method, string url, string body, string extraHdr, string &resp, int &code)
{
   char data[], result[];
   string rh, hdr = "Content-Type: application/json\r\n" + extraHdr;
   if(body!="")
   {
      int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
      if(n>0) ArrayResize(data, n-1);
   }
   ResetLastError();
   code = WebRequest(method, url, hdr, 5000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_Status = "WebRequest me Firebase URL allow karo";
         if(!g_UrlWarned){ g_UrlWarned = true; Alert("SAMUSIGNAL AI AUTO: Tools > Options > Expert Advisors > Allow WebRequest me ye URL daalo: ", FbBase()); }
      }
      else g_Status = "net error "+IntegerToString(err);
      return false;
   }
   resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if(code<200 || code>=300){ g_Status = "Firebase HTTP "+IntegerToString(code)+(code==401?" (FirebaseAuth daalo)":""); return false; }
   return true;
}
string JsonSafe(string t)
{
   StringReplace(t, "\\", "/"); StringReplace(t, "\"", "'"); StringReplace(t, "{", "("); StringReplace(t, "}", ")");
   return t;
}
// signal par nateeja likho (app / scanner dekh sake): st = PLACED / SKIP / ERROR / CANCELLED / EXPIRED
void SetSig(string key, string st, string msg)
{
   string body = "{\"st\":\""+st+"\",\"msg\":\""+JsonSafe(msg)+"\",\"done\":"+IntegerToString((long)TimeGMT())+"}";
   string resp; int code;
   Http("POST", FbUrl("sig/"+key, ""), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code);
   Print("SAMUSIGNAL AI AUTO: ", key, " -> ", st, " | ", msg);
}

// ---- chhote JSON padhne wale (scanner ke flat objects) ----
string JsonStr(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return "";
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return "";
   p++;
   int n = StringLen(obj);
   while(p<n && StringGetCharacter(obj,p)==' ') p++;
   if(p>=n || StringGetCharacter(obj,p)!='"') return "";
   int q = p+1;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if(c=='\\'){ q+=2; continue; }
      if(c=='"') break;
      q++;
   }
   return StringSubstr(obj, p+1, q-p-1);
}
double JsonNum(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return 0;
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return 0;
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ' || StringGetCharacter(obj,p)=='"')) p++;
   int q = p;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if((c>='0' && c<='9') || c=='.' || c=='-' || c=='+' || c=='e' || c=='E') q++;
      else break;
   }
   if(q==p) return 0;
   return StringToDouble(StringSubstr(obj, p, q-p));
}
// {"k1":{...},"k2":{...}} -> keys[] / objs[]
int SplitRecords(string s, string &keys[], string &objs[])
{
   int n = StringLen(s), cnt = 0;
   ArrayResize(keys,0); ArrayResize(objs,0);
   int i = StringFind(s, "{");
   if(i<0) return 0;
   i++;
   while(i<n)
   {
      while(i<n && StringGetCharacter(s,i)!='"' && StringGetCharacter(s,i)!='}') i++;
      if(i>=n || StringGetCharacter(s,i)=='}') break;
      int k1 = i+1, k2 = StringFind(s, "\"", k1);
      if(k2<0) break;
      string key = StringSubstr(s, k1, k2-k1);
      i = StringFind(s, ":", k2);
      if(i<0) break;
      i++;
      while(i<n && StringGetCharacter(s,i)==' ') i++;
      if(i>=n) break;
      if(StringGetCharacter(s,i)!='{')
      {
         while(i<n && StringGetCharacter(s,i)!=',' && StringGetCharacter(s,i)!='}') i++;
         continue;
      }
      int depth=0; bool inStr=false; int start=i;
      for(; i<n; i++)
      {
         ushort c = StringGetCharacter(s,i);
         if(inStr){ if(c=='\\'){ i++; continue; } if(c=='"') inStr=false; continue; }
         if(c=='"') inStr=true;
         else if(c=='{') depth++;
         else if(c=='}'){ depth--; if(depth==0){ i++; break; } }
      }
      ArrayResize(keys,cnt+1); ArrayResize(objs,cnt+1);
      keys[cnt]=key; objs[cnt]=StringSubstr(s, start, i-start);
      cnt++;
   }
   return cnt;
}

bool IsDone(string key){ for(int i=0;i<g_DoneN;i++) if(g_Done[i]==key) return true; return false; }
void MarkDone(string key)
{
   if(IsDone(key)) return;
   if(g_DoneN>=400){ for(int i=1;i<400;i++) g_Done[i-1]=g_Done[i]; g_DoneN=399; }
   g_Done[g_DoneN++] = key;
}

//+------------------------------------------------------------------+
//| Symbol                                                           |
//+------------------------------------------------------------------+
string Name6(string sym){ string u = sym; StringToUpper(u); return StringSubstr(u, 0, 6); }
bool IsExcluded(string name)
{
   string parts[];
   int n = StringSplit(ExcludeCSV, ',', parts);
   for(int i=0;i<n;i++){ string p = parts[i]; StringTrimLeft(p); StringTrimRight(p); StringToUpper(p); if(p!="" && p==name) return true; }
   return false;
}
bool SymTradable(string s)
{
   long m = SymbolInfoInteger(s, SYMBOL_TRADE_MODE);
   return (m == SYMBOL_TRADE_MODE_FULL || m == SYMBOL_TRADE_MODE_LONGONLY || m == SYMBOL_TRADE_MODE_SHORTONLY);
}
string Resolve(string pair)
{
   if(SymbolSuffix!="")
   {
      string s = pair+SymbolSuffix;
      return SymbolSelect(s,true) ? s : "";
   }
   string want = pair; StringToUpper(want);
   string suf = (StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : ""); StringToUpper(suf);
   string best = "";
   int bestScore = -1, total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false), up = s;
      StringToUpper(up);
      if(StringFind(up,want)!=0 || StringLen(up) > StringLen(want)+4) continue;
      if(!SymTradable(s)) continue;
      string rest = StringSubstr(up, StringLen(want));
      int score = 1 + (rest==suf ? 2 : 0) + (rest=="" ? 1 : 0);
      if(score > bestScore){ bestScore = score; best = s; }
   }
   if(best=="" || !SymbolSelect(best,true)) return "";
   return best;
}
bool WaitPrice(string sym, int maxMs)
{
   MqlTick tk; int waited = 0;
   while(true)
   {
      if(SymbolInfoTick(sym, tk) && tk.bid > 0 && tk.ask > 0) return true;
      if(waited >= maxMs) return false;
      Sleep(100); waited += 100;
   }
   return false;
}
// 1.0 lot par 1 price-unit chalne ka $ (account currency)
double UsdPerPriceLot(string sym)
{
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT), price = SymbolInfoDouble(sym, SYMBOL_BID);
   if(pt<=0 || price<=0) return 0;
   double delta = pt*100.0, p = 0;
   if(OrderCalcProfit(ORDER_TYPE_BUY, sym, 1.0, price, price+delta, p) && p>0) return p/delta;
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(ts>0 && tv>0) return tv/ts;
   return 0;
}
// is symbol par EA ke trade + pending
int CountOurOn(string sym)
{
   int n = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      if(PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetString(POSITION_SYMBOL)==sym) n++;
   }
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong t = OrderGetTicket(i);
      if(t==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)==Magic && OrderGetString(ORDER_SYMBOL)==sym) n++;
   }
   return n;
}
bool AlreadyPlaced(string tag)
{
   for(int i=OrdersTotal()-1;i>=0;i--){ ulong t = OrderGetTicket(i); if(t>0 && OrderGetString(ORDER_COMMENT)==tag) return true; }
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t = PositionGetTicket(i); if(t>0 && PositionGetString(POSITION_COMMENT)==tag) return true; }
   return false;
}

//+------------------------------------------------------------------+
//| News (MT5 calendar, free)                                        |
//+------------------------------------------------------------------+
void NewsLoad()
{
   if(g_NewsLoaded>0 && TimeLocal() - g_NewsLoaded < 60) return;
   g_NewsLoaded = TimeLocal();
   ArrayResize(g_NewsT,0); ArrayResize(g_NewsCur,0); ArrayResize(g_NewsName,0);
   datetime now = TimeTradeServer();
   MqlCalendarValue v[];
   int n = CalendarValueHistory(v, now - (NewsAfterMin+5)*60, now + (NewsBeforeMin+65)*60);
   for(int i=0;i<n;i++)
   {
      MqlCalendarEvent e;
      if(!CalendarEventById(v[i].event_id, e)) continue;
      if(!(e.importance==CALENDAR_IMPORTANCE_HIGH || (NewsWithMedium && e.importance==CALENDAR_IMPORTANCE_MODERATE))) continue;
      if(e.type==CALENDAR_TYPE_HOLIDAY) continue;
      MqlCalendarCountry c;
      if(!CalendarCountryById(e.country_id, c)) continue;
      int m = ArraySize(g_NewsT);
      ArrayResize(g_NewsT,m+1); ArrayResize(g_NewsCur,m+1); ArrayResize(g_NewsName,m+1);
      g_NewsT[m] = v[i].time; g_NewsCur[m] = c.currency; g_NewsName[m] = e.name;
   }
}
// currency b / p (jaise EUR, USD) ki news window me?
bool NewsBlockCur(string b, string p, string &why)
{
   why = "";
   if(!NewsOn) return false;
   NewsLoad();
   datetime now = TimeTradeServer();
   for(int i=0;i<ArraySize(g_NewsT);i++)
   {
      if(g_NewsCur[i]!=b && g_NewsCur[i]!=p) continue;
      long left = (long)(g_NewsT[i] - now);
      if(left > NewsBeforeMin*60 || left < -NewsAfterMin*60) continue;
      long ist = (long)g_NewsT[i] - (long)(TimeTradeServer() - TimeGMT()) + 19800;
      why = g_NewsCur[i]+" "+g_NewsName[i]+" "+StringSubstr(TimeToString((datetime)ist, TIME_DATE|TIME_MINUTES), 11)+" IST"
            + (left>0 ? " ("+IntegerToString((int)(left/60))+" min me)" : " (abhi hui)");
      return true;
   }
   return false;
}
bool NewsBlock(string sym, string &why)
{
   string b = SymbolInfoString(sym, SYMBOL_CURRENCY_BASE), p = SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT);
   if(b=="" || p==""){ string n = Name6(sym); b = StringSubstr(n,0,3); p = StringSubstr(n,3,3); }
   return NewsBlockCur(b, p, why);
}

//+------------------------------------------------------------------+
//| EA ke pending hatao (news / expiry / din band)                   |
//+------------------------------------------------------------------+
void DeleteOne(ulong tk, string st, string msg)
{
   string cm = OrderGetString(ORDER_COMMENT), sym = OrderGetString(ORDER_SYMBOL);
   if(!trade.OrderDelete(tk)) { Print("SAMUSIGNAL AI AUTO: #", tk, " hata nahi paaye: ", trade.ResultRetcodeDescription()); return; }
   Print("SAMUSIGNAL AI AUTO: ", sym, " pending #", tk, " hataya - ", msg);
   if(StringFind(cm,"SSA")==0 && StringLen(cm)>3) SetSig(StringSubstr(cm,3), st, "#"+IntegerToString((long)tk)+" "+msg);
}
void DeleteOurPendings(string st, string msg)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      DeleteOne(tk, st, msg);
   }
}
void CheckExpiry()
{
   if(PendingMin<=0) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(TimeTradeServer() - setup < PendingMin*60) continue;
      DeleteOne(tk, "EXPIRED", IntegerToString(PendingMin)+" min me nahi bhara");
   }
}
void CheckNewsPending()
{
   if(!NewsOn) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string sym = OrderGetString(ORDER_SYMBOL), why;
      if(!NewsBlock(sym, why)) continue;
      DeleteOne(tk, "CANCELLED", "news: "+why);
      if(PushOn) SendNotification("SAMUSIGNAL AI AUTO: "+Name6(sym)+" pending cancel - news "+why);
   }
}

//+------------------------------------------------------------------+
//| Aaj ka hisaab (broker server ka din)                             |
//+------------------------------------------------------------------+
void DayStats()
{
   long ns = (long)TimeTradeServer();
   datetime now = (datetime)ns, d0 = (datetime)(ns - ns % 86400);
   g_Losses = 0; g_Net = 0;
   if(!HistorySelect(d0, now + 3600)) return;
   int n = HistoryDealsTotal();
   for(int i=0;i<n;i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d==0 || HistoryDealGetInteger(d, DEAL_MAGIC)!=Magic) continue;
      double pr = HistoryDealGetDouble(d, DEAL_PROFIT);
      g_Net += pr + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if((en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY) && pr < 0) g_Losses++;
   }
}
void CheckDay()
{
   DayStats();
   g_Stop = false; g_StopWhy = "";
   if(MaxLossesPerDay>0 && g_Losses >= MaxLossesPerDay){ g_Stop = true; g_StopWhy = IntegerToString(g_Losses)+" loss"; }
   else if(DailyTargetUsd>0 && g_Net >= DailyTargetUsd){ g_Stop = true; g_StopWhy = "target poora $"+DoubleToString(g_Net,2); }
   if(!g_Stop) return;
   DeleteOurPendings("CANCELLED", "aaj band: "+g_StopWhy);
   int dn = (int)((long)TimeTradeServer()/86400);
   if(g_StopDay != dn)
   {
      g_StopDay = dn;
      string m = "SAMUSIGNAL AI AUTO: aaj ki trading band ("+g_StopWhy+") | aaj net $"+DoubleToString(g_Net,2)+" | "+IntegerToString(g_Losses)+" loss";
      Print(m);
      if(PushOn) SendNotification(m);
   }
}

//+------------------------------------------------------------------+
//| Signal padho + LIMIT lagao                                       |
//+------------------------------------------------------------------+
void PollSigs()
{
   string resp; int code;
   if(!Http("GET", FbUrl("sig", "orderBy=%22%24key%22&limitToLast=30"), "", "", resp, code)) return;
   if(g_Real && !AllowReal) g_Status = "REAL account - AllowReal=false, trade NAHI";
   else if(StringFind(g_Status,"Firebase")==0 || StringFind(g_Status,"net error")==0 || StringFind(g_Status,"WebRequest")==0 || g_Status=="shuru...")
      g_Status = "chalu - signal ka intezaar";
   if(resp=="" || resp=="null") return;
   string keys[], objs[];
   int n = SplitRecords(resp, keys, objs);
   for(int i=0;i<n;i++)
   {
      if(IsDone(keys[i])) continue;
      if(StringFind(objs[i], "\"st\"")>=0){ MarkDone(keys[i]); continue; }   // pehle hi nipat chuka
      ProcessSig(keys[i], objs[i]);
   }
}

void ProcessSig(string key, string obj)
{
   MarkDone(key);
   string name = JsonStr(obj, "sym"); StringToUpper(name);
   string dir  = JsonStr(obj, "dir");
   double entry = JsonNum(obj, "entry");
   int    conf  = (int)JsonNum(obj, "conf");
   long   at    = (long)JsonNum(obj, "at");
   string tag   = "SSA"+key;
   g_LastSig = name+" "+dir+" @ "+DoubleToString(entry,5)+" (AI "+IntegerToString(conf)+"%)";

   if(AlreadyPlaced(tag)) return;
   if(g_Real && !AllowReal){ SetSig(key, "SKIP", "REAL account - AllowReal=false"); return; }
   if(name=="" || (dir!="BUY" && dir!="SELL") || entry<=0){ SetSig(key, "SKIP", "signal adhoora"); return; }
   if(IsExcluded(name)){ SetSig(key, "SKIP", name+" is EA me nahi (XAU / BTC)"); return; }
   if(conf < MinConf){ SetSig(key, "SKIP", "AI bharosa "+IntegerToString(conf)+"% < "+IntegerToString(MinConf)+"%"); return; }
   long age = (long)TimeGMT() - at;
   if(at<=0 || age > MaxSigAgeMin*60){ SetSig(key, "SKIP", "purana signal ("+IntegerToString((int)(age/60))+" min)"); return; }
   if(g_Stop){ SetSig(key, "SKIP", "aaj band: "+g_StopWhy); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)){ SetSig(key, "SKIP", "MT5 me Algo Trading band"); return; }

   string sym = Resolve(name);
   if(sym==""){ SetSig(key, "SKIP", name+" symbol is account me nahi mila"); return; }
   if(!WaitPrice(sym, 3000)){ SetSig(key, "SKIP", sym+" ka bhaav nahi aaya"); return; }
   if(CountOurOn(sym)>0){ SetSig(key, "SKIP", "1 pair 1 trade: "+sym+" pe pehle se trade / pending"); return; }
   string why;
   if(NewsBlock(sym, why)){ SetSig(key, "SKIP", "news: "+why); return; }

   double k = UsdPerPriceLot(sym);
   if(k<=0){ SetSig(key, "SKIP", sym+" ka tick value nahi mila"); return; }
   double tpD = TP_Usd / (k*0.01), slD = SL_Usd / (k*0.01);       // $ per 0.01 lot -> bhaav ki doori (lot ke saath $ badhta)
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   double spr = ask - bid;
   if(MaxSpreadPctOfTP>0 && spr > tpD*MaxSpreadPctOfTP/100.0)
   {
      SetSig(key, "SKIP", "spread "+DoubleToString(spr/pt,0)+" pts > TP ka "+DoubleToString(MaxSpreadPctOfTP,0)+"% ("+DoubleToString(tpD*MaxSpreadPctOfTP/100.0/pt,0)+" pts)");
      return;
   }
   if(tpD < minD || slD < minD){ SetSig(key, "SKIP", "TP / SL broker ki stop level se chhota"); return; }

   entry = NormalizeDouble(entry, dg);
   double sl, tp;
   if(dir=="BUY")
   {
      if(entry >= ask - minD){ SetSig(key, "SKIP", "bhaav entry tak aa chuka / neeche (ask "+DoubleToString(ask,dg)+") - LIMIT nahi lag sakta"); return; }
      sl = NormalizeDouble(entry - slD, dg); tp = NormalizeDouble(entry + tpD, dg);
   }
   else
   {
      if(entry <= bid + minD){ SetSig(key, "SKIP", "bhaav entry tak aa chuka / upar (bid "+DoubleToString(bid,dg)+") - LIMIT nahi lag sakta"); return; }
      sl = NormalizeDouble(entry + slD, dg); tp = NormalizeDouble(entry - tpD, dg);
   }

   double lot = Lot;
   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN), vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(vstep>0) lot = MathFloor(lot/vstep+1e-9)*vstep;
   if(lot < vmin) lot = vmin;

   bool ok = (dir=="BUY") ? trade.BuyLimit(lot, entry, sym, sl, tp, ORDER_TIME_GTC, 0, tag)
                          : trade.SellLimit(lot, entry, sym, sl, tp, ORDER_TIME_GTC, 0, tag);
   uint rc = trade.ResultRetcode();
   if(!ok || (rc!=TRADE_RETCODE_DONE && rc!=TRADE_RETCODE_PLACED))
   {
      SetSig(key, "ERROR", sym+" order nahi laga: "+IntegerToString((int)rc)+" "+trade.ResultRetcodeDescription());
      return;
   }
   string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+sym+" "+dir+" LIMIT "+DoubleToString(lot,2)+" @ "+DoubleToString(entry,dg)
              +" TP "+DoubleToString(tp,dg)+" SL "+DoubleToString(sl,dg)+" (AI "+IntegerToString(conf)+"%)";
   SetSig(key, "PLACED", m);
   if(PushOn) SendNotification("SAMUSIGNAL AI AUTO: "+m);
}

//+------------------------------------------------------------------+
//| Bhara / band hua -> push + din ka hisaab                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &tr, const MqlTradeRequest &rq, const MqlTradeResult &rs)
{
   if(tr.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(tr.deal)) return;
   if(HistoryDealGetInteger(tr.deal, DEAL_MAGIC) != Magic) return;
   long en = HistoryDealGetInteger(tr.deal, DEAL_ENTRY);
   string sym = HistoryDealGetString(tr.deal, DEAL_SYMBOL), m;
   if(en==DEAL_ENTRY_IN)
      m = "bhara: "+sym+" @ "+DoubleToString(HistoryDealGetDouble(tr.deal, DEAL_PRICE), (int)SymbolInfoInteger(sym, SYMBOL_DIGITS));
   else
   {
      double pl = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
      DayStats();
      m = (pl>=0 ? "TP " : "SL ")+sym+" "+(pl>=0?"+":"")+DoubleToString(pl,2)+"$ | aaj: "+DoubleToString(g_Net,2)+"$ | "+IntegerToString(g_Losses)+"/"+IntegerToString(MaxLossesPerDay)+" loss";
   }
   Print("SAMUSIGNAL AI AUTO: ", m);
   if(PushOn) SendNotification("SAMUSIGNAL AI AUTO: "+m);
   g_NeedCheck = true;
}

//+------------------------------------------------------------------+
//| Halat Firebase me (scanner padhta hai: kin pair par AI na poochhe)|
//+------------------------------------------------------------------+
string JArr(string &a[])
{
   string s = "[";
   for(int i=0;i<ArraySize(a);i++) s += (i?",":"")+"\""+a[i]+"\"";
   return s+"]";
}
void AddUniq(string &a[], string v)
{
   for(int i=0;i<ArraySize(a);i++) if(a[i]==v) return;
   int n = ArraySize(a); ArrayResize(a, n+1); a[n] = v;
}
void PublishState()
{
   string busy[], news[];
   int op = 0, pd = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      op++; AddUniq(busy, Name6(PositionGetString(POSITION_SYMBOL)));
   }
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong t = OrderGetTicket(i);
      if(t==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      pd++; AddUniq(busy, Name6(OrderGetString(ORDER_SYMBOL)));
   }
   for(int i=0;i<ArraySize(PAIRS28);i++)
   {
      string why;
      if(NewsBlockCur(StringSubstr(PAIRS28[i],0,3), StringSubstr(PAIRS28[i],3,3), why)) AddUniq(news, PAIRS28[i]);
   }
   bool off = (g_Real && !AllowReal);
   string body = "{\"t\":"+IntegerToString((long)TimeGMT())+",\"v\":\""+VER+"\",\"stop\":"+((g_Stop||off)?"true":"false")
      +",\"why\":\""+JsonSafe(off ? "REAL account - AllowReal=false" : g_StopWhy)+"\",\"losses\":"+IntegerToString(g_Losses)
      +",\"net\":"+DoubleToString(g_Net,2)+",\"maxLoss\":"+IntegerToString(MaxLossesPerDay)+",\"target\":"+DoubleToString(DailyTargetUsd,2)
      +",\"open\":"+IntegerToString(op)+",\"pend\":"+IntegerToString(pd)+",\"busy\":"+JArr(busy)+",\"news\":"+JArr(news)
      +",\"status\":\""+JsonSafe(g_Status)+"\"}";
   string resp; int code;
   Http("POST", FbUrl("state", ""), body, "X-HTTP-Method-Override: PUT\r\n", resp, code);
}
void ReadScan()
{
   string resp; int code;
   if(!Http("GET", FbUrl("scan", ""), "", "", resp, code) || resp=="null") { g_ScanTxt = "scanner ka data nahi"; return; }
   long t = (long)JsonNum(resp, "t");
   int ago = (int)(((long)TimeGMT() - t)/60);
   string why = JsonStr(resp, "why");
   g_ScanTxt = (t>0 ? IntegerToString(ago)+" min pehle" : "?") + " | achhe "+IntegerToString((int)JsonNum(resp,"cand"))
             + " | AI sahmat "+IntegerToString((int)JsonNum(resp,"agree"))+" | bheje "+IntegerToString((int)JsonNum(resp,"sent"))
             + (why!="" ? " | "+why : "") + (ago > 20 ? "  <<< SCANNER CHUP? (C:\\SamuScanner\\scanner.log)" : "");
}

void Panel()
{
   string s = "SAMUSIGNAL AI AUTO v"+VER+(g_Real?"   [REAL]":"   [DEMO]")+"\n"
      + "Halat: "+g_Status+"\n"
      + "Aaj: $"+DoubleToString(g_Net,2)+" / target $"+DoubleToString(DailyTargetUsd,2)+" | loss "+IntegerToString(g_Losses)+"/"+IntegerToString(MaxLossesPerDay)
      + (g_Stop ? "   >>> AAJ BAND ("+g_StopWhy+")" : "")+"\n"
      + "TP $"+DoubleToString(TP_Usd,2)+" SL $"+DoubleToString(SL_Usd,2)+" lot "+DoubleToString(Lot,2)+" | news "+IntegerToString(NewsBeforeMin)+"/"+IntegerToString(NewsAfterMin)+" min | spread <= TP ka "+DoubleToString(MaxSpreadPctOfTP,0)+"%\n"
      + "Aakhri signal: "+g_LastSig+"\n"
      + "Scanner: "+g_ScanTxt;
   Comment(s);
}
//+------------------------------------------------------------------+
