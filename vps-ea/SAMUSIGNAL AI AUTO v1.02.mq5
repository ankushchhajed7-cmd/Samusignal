//+------------------------------------------------------------------+
//|                                   SAMUSIGNAL AI AUTO v1.02.mq5   |
//|                                           Ankush New Vision      |
//+------------------------------------------------------------------+
//|  v1.02: DASHBOARD - user ka chuna design 4 (Twin Gauge): profit  |
//|         meter, loss meter, IST ghadi, agla scan, TP/SL, open /   |
//|         pending, scanner, spread, aaj ke signal ki patti, open   |
//|         trades, agli news, PAUSE + CANCEL PENDING button, mini.  |
//|         Trade ke niyam me koi badlav nahi.                       |
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
#property version   "1.02"
#property description "SAMUSIGNAL AI AUTO - VPS scanner ke AI sahmat signal par LIMIT (TP $0.25 / SL $1.50), news + din ki seema"

#include <Trade\Trade.mqh>
#include <Canvas\Canvas.mqh>
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

input group "========== DASHBOARD (v1.02) =========="
input bool   PanelOn           = true;      // Dashboard dikhao (false = purana text)
input double PanelScale        = 0.8;       // Dashboard ka size (0.5 chhota - 1.2 bada)
input int    PanelX            = 8;         // Chart ke baayen se (px)
input int    PanelY            = 24;        // Chart ke upar se (px)

#define VER "1.02"
string PAIRS28[] = {"EURUSD","GBPUSD","USDJPY","USDCHF","USDCAD","AUDUSD","NZDUSD","EURJPY","EURGBP","EURCHF","EURCAD","EURAUD","EURNZD",
                    "GBPJPY","GBPCHF","GBPCAD","GBPAUD","GBPNZD","AUDJPY","AUDCHF","AUDCAD","AUDNZD","NZDJPY","NZDCHF","NZDCAD","CADCHF","CADJPY","CHFJPY"};

string   g_Done[400];  int g_DoneN = 0;
string   g_Status = "shuru...", g_LastSig = "-", g_ScanTxt = "-", g_StopWhy = "";
bool     g_Stop = false, g_Real = false, g_UrlWarned = false, g_NeedCheck = true;
int      g_Losses = 0, g_StopDay = -1;
double   g_Net = 0;
datetime g_NewsT[]; string g_NewsCur[], g_NewsName[]; datetime g_NewsLoaded = 0;
// v1.02 dashboard
#define  CVNAME "SSA_DASH"
#define  DW 960
#define  DH 640
#define  DMINI 64
CCanvas  g_Cv;
bool     g_CvOk = false, g_Paused = false, g_FbOk = false, g_Mini = false;
datetime g_CancelArm = 0;
string   g_LastRes = "-";
double   g_LastSpr = -1, g_LastSprPct = -1;
int      g_Wins = 0;
long     g_ScT = 0;
int      g_ScPairs = 0, g_ScCand = 0, g_ScAi = 0, g_ScAgree = 0, g_ScSent = 0;
datetime g_NxT = 0, g_NxLoaded = 0; string g_NxCur = "", g_NxName = "";
double   g_Bx[3], g_By[3], g_Bw[3], g_Bh[3];
uint     cBG, cTile, cBrd, cLbl, cFg, cOrg, cGrn, cRed, cBlu, cAmb, cTrk, cRz, cNbg, cNbr, cGry, cGbg, cRbg, cDim;

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
   g_Paused = (GlobalVariableCheck(PauseName()) && GlobalVariableGet(PauseName()) > 0.5);
   DashInit();
   EventSetTimer(1);
   Print("SAMUSIGNAL AI AUTO v", VER, " shuru | TP $", DoubleToString(TP_Usd,2), " SL $", DoubleToString(SL_Usd,2),
         " lot ", DoubleToString(Lot,2), " | news ", NewsBeforeMin, "/", NewsAfterMin, " min | din: ", MaxLossesPerDay, " loss / $", DoubleToString(DailyTargetUsd,2));
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ EventKillTimer(); Comment(""); if(g_CvOk) g_Cv.Destroy(); ObjectDelete(0, CVNAME); }
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
   NextNewsLoad();
   Dash();
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
      g_FbOk = false;
      return false;
   }
   resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if(code<200 || code>=300){ g_Status = "Firebase HTTP "+IntegerToString(code)+(code==401?" (FirebaseAuth daalo)":""); g_FbOk = false; return false; }
   g_FbOk = true;
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
   g_Losses = 0; g_Net = 0; g_Wins = 0;
   if(!HistorySelect(d0, now + 3600)) return;
   int n = HistoryDealsTotal();
   for(int i=0;i<n;i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d==0 || HistoryDealGetInteger(d, DEAL_MAGIC)!=Magic) continue;
      double pr = HistoryDealGetDouble(d, DEAL_PROFIT);
      g_Net += pr + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY){ if(pr < 0) g_Losses++; else g_Wins++; }
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

// v1.02: SKIP + ginti (pl / sp / nw / pr / ot) + dashboard ki aakhri line
void Skip(string key, string cat, string msg)
{
   CntAdd(cat);
   g_LastRes = "SKIP: "+msg;
   SetSig(key, "SKIP", msg);
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
   CntAdd("in");
   if(g_Real && !AllowReal){ Skip(key, "ot", "REAL account - AllowReal=false"); return; }
   if(name=="" || (dir!="BUY" && dir!="SELL") || entry<=0){ Skip(key, "ot", "signal adhoora"); return; }
   if(IsExcluded(name)){ Skip(key, "ot", name+" is EA me nahi (XAU / BTC)"); return; }
   if(conf < MinConf){ Skip(key, "ot", "AI bharosa "+IntegerToString(conf)+"% < "+IntegerToString(MinConf)+"%"); return; }
   long age = (long)TimeGMT() - at;
   if(at<=0 || age > MaxSigAgeMin*60){ Skip(key, "ot", "purana signal ("+IntegerToString((int)(age/60))+" min)"); return; }
   if(g_Stop){ Skip(key, "ot", "aaj band: "+g_StopWhy); return; }
   if(g_Paused){ Skip(key, "ot", "PAUSE (panel se)"); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)){ Skip(key, "ot", "MT5 me Algo Trading band"); return; }

   string sym = Resolve(name);
   if(sym==""){ Skip(key, "ot", name+" symbol is account me nahi mila"); return; }
   if(!WaitPrice(sym, 3000)){ Skip(key, "ot", sym+" ka bhaav nahi aaya"); return; }
   if(CountOurOn(sym)>0){ Skip(key, "pr", "1 pair 1 trade: "+sym+" pe pehle se trade / pending"); return; }
   string why;
   if(NewsBlock(sym, why)){ Skip(key, "nw", "news: "+why); return; }

   double k = UsdPerPriceLot(sym);
   if(k<=0){ Skip(key, "ot", sym+" ka tick value nahi mila"); return; }
   double tpD = TP_Usd / (k*0.01), slD = SL_Usd / (k*0.01);       // $ per 0.01 lot -> bhaav ki doori (lot ke saath $ badhta)
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   double spr = ask - bid;
   g_LastSpr = (pt > 0 ? spr/pt : 0); g_LastSprPct = (tpD > 0 ? spr/tpD*100.0 : 0);
   if(MaxSpreadPctOfTP>0 && spr > tpD*MaxSpreadPctOfTP/100.0)
   {
      Skip(key, "sp", "spread "+DoubleToString(spr/pt,0)+" pts > TP ka "+DoubleToString(MaxSpreadPctOfTP,0)+"% ("+DoubleToString(tpD*MaxSpreadPctOfTP/100.0/pt,0)+" pts)");
      return;
   }
   if(tpD < minD || slD < minD){ Skip(key, "ot", "TP / SL broker ki stop level se chhota"); return; }

   entry = NormalizeDouble(entry, dg);
   double sl, tp;
   if(dir=="BUY")
   {
      if(entry >= ask - minD){ Skip(key, "ot", "bhaav entry tak aa chuka / neeche (ask "+DoubleToString(ask,dg)+") - LIMIT nahi lag sakta"); return; }
      sl = NormalizeDouble(entry - slD, dg); tp = NormalizeDouble(entry + tpD, dg);
   }
   else
   {
      if(entry <= bid + minD){ Skip(key, "ot", "bhaav entry tak aa chuka / upar (bid "+DoubleToString(bid,dg)+") - LIMIT nahi lag sakta"); return; }
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
      CntAdd("ot"); g_LastRes = "ERROR "+IntegerToString((int)rc);
      SetSig(key, "ERROR", sym+" order nahi laga: "+IntegerToString((int)rc)+" "+trade.ResultRetcodeDescription());
      return;
   }
   string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+sym+" "+dir+" LIMIT "+DoubleToString(lot,2)+" @ "+DoubleToString(entry,dg)
              +" TP "+DoubleToString(tp,dg)+" SL "+DoubleToString(sl,dg)+" (AI "+IntegerToString(conf)+"%)";
   CntAdd("pl"); g_LastRes = "PLACED";
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
   string body = "{\"t\":"+IntegerToString((long)TimeGMT())+",\"v\":\""+VER+"\",\"stop\":"+((g_Stop||off||g_Paused)?"true":"false")
      +",\"why\":\""+JsonSafe(off ? "REAL account - AllowReal=false" : (g_Paused ? "PAUSE (panel se)" : g_StopWhy))+"\",\"paused\":"+(g_Paused?"true":"false")+",\"losses\":"+IntegerToString(g_Losses)
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
   g_ScT = t; g_ScPairs = (int)JsonNum(resp,"pairs"); g_ScCand = (int)JsonNum(resp,"cand"); g_ScAi = (int)JsonNum(resp,"ai");
   g_ScAgree = (int)JsonNum(resp,"agree"); g_ScSent = (int)JsonNum(resp,"sent");
   int ago = (int)(((long)TimeGMT() - t)/60);
   string why = JsonStr(resp, "why");
   g_ScanTxt = (t>0 ? IntegerToString(ago)+" min pehle" : "?") + " | achhe "+IntegerToString((int)JsonNum(resp,"cand"))
             + " | AI sahmat "+IntegerToString((int)JsonNum(resp,"agree"))+" | bheje "+IntegerToString((int)JsonNum(resp,"sent"))
             + (why!="" ? " | "+why : "") + (ago > 20 ? "  <<< SCANNER CHUP? (C:\\SamuScanner\\scanner.log)" : "");
}

// purana text panel (PanelOn=false ya canvas na bane)
void PanelText()
{
   string s = "SAMUSIGNAL AI AUTO v"+VER+(g_Real?"   [REAL]":"   [DEMO]")+"\n"
      + "Halat: "+g_Status+"\n"
      + "Aaj: $"+DoubleToString(g_Net,2)+" / target $"+DoubleToString(DailyTargetUsd,2)+" | loss "+IntegerToString(g_Losses)+"/"+IntegerToString(MaxLossesPerDay)
      + (g_Stop ? "   >>> AAJ BAND ("+g_StopWhy+")" : "")+"\n"
      + "TP $"+DoubleToString(TP_Usd,2)+" SL $"+DoubleToString(SL_Usd,2)+" lot "+DoubleToString(Lot,2)+" | news "+IntegerToString(NewsBeforeMin)+"/"+IntegerToString(NewsAfterMin)+" min | spread <= TP ka "+DoubleToString(MaxSpreadPctOfTP,0)+"%\n"
      + "Aakhri signal: "+g_LastSig+"\n"
      + "Scanner: "+g_ScanTxt+(g_Paused ? "\n>>> PAUSE (panel se)" : "");
   Comment(s);
}

//+------------------------------------------------------------------+
//| v1.02: DASHBOARD (user ka chuna design 4 - "Twin Gauge")         |
//|  Bayen: aaj profit meter ($0 -> target), Daayen: loss meter        |
//|  (0 -> 4, aakhri khaana laal), beech: IST ghadi + server + session |
//|  + halat + mode + agla scan. Neeche: TP/SL jeet, open/pending,     |
//|  scanner, spread, aaj ke signal ki patti (lage / spread / news /   |
//|  1-pair / baaki), open trades, agli High news + niyam, ALGO /      |
//|  FIREBASE / REAL LOCK, aakhri signal, PAUSE + CANCEL PENDING.      |
//|  "-" button: chhoti patti (mini). PanelScale se chhota / bada.     |
//+------------------------------------------------------------------+
void DashInit()
{
   if(!PanelOn) return;
   cBG=Rgb(23,24,26); cTile=Rgb(31,32,35); cBrd=Rgb(52,54,59); cLbl=Rgb(167,169,174); cFg=Rgb(242,242,240);
   cOrg=Rgb(255,138,61); cGrn=Rgb(52,211,153); cRed=Rgb(248,113,113); cBlu=Rgb(96,165,250); cAmb=Rgb(251,191,36);
   cTrk=Rgb(44,46,50); cRz=Rgb(90,35,40); cNbg=Rgb(42,33,22); cNbr=Rgb(122,90,38); cGry=Rgb(123,126,133);
   cGbg=Rgb(17,48,31); cRbg=Rgb(46,26,28); cDim=Rgb(74,77,82);
   ObjectDelete(0, CVNAME);
   g_CvOk = g_Cv.CreateBitmapLabel(CVNAME, PanelX, PanelY, Z(DW), Z(g_Mini ? DMINI : DH), COLOR_FORMAT_ARGB_NORMALIZE);
   if(g_CvOk)
   {
      ObjectSetInteger(0, CVNAME, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, CVNAME, OBJPROP_BACK, false);
   }
   else Print("SAMUSIGNAL AI AUTO: dashboard canvas nahi bana - purana text panel chalega");
}
double S(){ return (PanelScale < 0.3 ? 0.3 : (PanelScale > 2.0 ? 2.0 : PanelScale)); }
int    Z(double v){ return (int)MathRound(v*S()); }
uint   Rgb(int r, int g, int b){ return ColorToARGB((color)((b<<16)|(g<<8)|r), 255); }
void   PolarXY(double cx, double cy, double r, double a, double &x, double &y){ double t=(a-90.0)*M_PI/180.0; x=cx+r*MathCos(t); y=cy+r*MathSin(t); }
void   SetFont(string font, int px, bool bold){ int sz=Z(px); if(sz<7) sz=7; g_Cv.FontSet(font, sz, bold ? FW_BOLD : FW_NORMAL); }
void   DBox(double x, double y, double w, double h, uint fill, uint brd)
{
   int x1=Z(x), y1=Z(y), x2=Z(x+w)-1, y2=Z(y+h)-1;
   g_Cv.FillRectangle(x1, y1, x2, y2, fill);
   if(brd!=0) g_Cv.Rectangle(x1, y1, x2, y2, brd);
}
void   DTxt(double x, double y, string s, uint c, int px, bool bold, uint al, string font="Segoe UI"){ SetFont(font, px, bold); g_Cv.TextOut(Z(x), Z(y), s, c, al); }
double DRun(double x, double y, string s, uint c, int px, bool bold, string font="Consolas")
{
   SetFont(font, px, bold); g_Cv.TextOut(Z(x), Z(y), s, c, TA_LEFT|TA_TOP);
   return x + g_Cv.TextWidth(s)/S();
}
string Fit(string s, double maxW, int px, bool bold, string font="Consolas")
{
   SetFont(font, px, bold);
   while(StringLen(s) > 4 && g_Cv.TextWidth(s) > Z(maxW)) s = StringSubstr(s, 0, StringLen(s)-2);
   return s;
}
void   DLine(double x1, double y1, double x2, double y2, uint c, double w)
{ int lw=Z(w); if(lw<1) lw=1; g_Cv.LineThick(Z(x1), Z(y1), Z(x2), Z(y2), c, lw, STYLE_SOLID, LINE_END_ROUND); }
void   DArc(double cx, double cy, double r, double a0, double a1, uint c, double w)
{
   if(a1 <= a0) return;
   int lw=Z(w); if(lw<1) lw=1;
   double px, py, qx, qy; PolarXY(cx, cy, r, a0, px, py);
   for(double a=a0; a < a1-0.0001; a+=3.0)
   {
      double b = MathMin(a+3.0, a1); PolarXY(cx, cy, r, b, qx, qy);
      g_Cv.LineThick(Z(px), Z(py), Z(qx), Z(qy), c, lw, STYLE_SOLID, LINE_END_ROUND);
      px=qx; py=qy;
   }
}
void   DPill(double x, double y, double w, double h, string s, uint c, uint bg)
{ DBox(x, y, w, h, bg, c); DTxt(x+w/2, y+h/2, s, c, 12, true, TA_CENTER|TA_VCENTER); }
// meter: -120 se +120 degree
void   DGauge(double cx, double cy, double v, double mx, int ticks, int dec, uint col, bool redLast, string big, uint bigC)
{
   double r=96, a0=-120, a1=120;
   if(mx <= 0) mx = 1;
   DArc(cx, cy, r, a0, a1, cTrk, 16);
   if(redLast) DArc(cx, cy, r, a0+(a1-a0)*(ticks-1)/ticks, a1, cRz, 16);
   double vv = MathMax(0.0, MathMin(v, mx));
   if(vv > 0) DArc(cx, cy, r, a0, a0+(a1-a0)*vv/mx, col, 16);
   for(int i=0;i<=ticks;i++)
   {
      double a=a0+(a1-a0)*i/ticks, x1, y1, x2, y2, lx, ly;
      PolarXY(cx, cy, r-7, a, x1, y1); PolarXY(cx, cy, r+7, a, x2, y2); DLine(x1, y1, x2, y2, cFg, 2.5);
      PolarXY(cx, cy, r-28, a, lx, ly);
      DTxt(lx, ly, DoubleToString(mx*i/ticks, dec), (redLast && i==ticks) ? cRed : cLbl, 14, true, TA_CENTER|TA_VCENTER, "Consolas");
   }
   double nx, ny; PolarXY(cx, cy, r-12, a0+(a1-a0)*vv/mx, nx, ny);
   DLine(cx, cy, nx, ny, cFg, 4);
   g_Cv.FillCircle(Z(cx), Z(cy), Z(10), cBG); g_Cv.Circle(Z(cx), Z(cy), Z(10), cFg); g_Cv.Circle(Z(cx), Z(cy), Z(9), cFg);
   DTxt(cx, cy+30, big, bigC, 26, true, TA_CENTER|TA_TOP, "Consolas");
}
void   BtnSet(int i, double x, double y, double w, double h){ g_Bx[i]=x; g_By[i]=y; g_Bw[i]=w; g_Bh[i]=h; }

// ---- din ke signal ginti (terminal global variables, restart me bhi bachi) ----
string CntName(string cat){ return "SSA"+IntegerToString(Magic)+"_"+IntegerToString((long)TimeTradeServer()/86400)+"_"+cat; }
void   CntAdd(string cat){ string n=CntName(cat); GlobalVariableSet(n, GlobalVariableGet(n)+1); }
int    CntGet(string cat){ string n=CntName(cat); return GlobalVariableCheck(n) ? (int)GlobalVariableGet(n) : 0; }
string PauseName(){ return "SSA"+IntegerToString(Magic)+"_pause"; }

// ---- agli High news (36 ghante tak), har 10 min ----
void NextNewsLoad()
{
   if(g_NxLoaded>0 && TimeLocal()-g_NxLoaded < 600) return;
   g_NxLoaded = TimeLocal(); g_NxT = 0; g_NxCur = ""; g_NxName = "";
   datetime now = TimeTradeServer();
   MqlCalendarValue v[];
   int n = CalendarValueHistory(v, now - NewsAfterMin*60, now + 36*3600);
   for(int i=0;i<n;i++)
   {
      if(v[i].time + NewsAfterMin*60 < now) continue;
      MqlCalendarEvent e;
      if(!CalendarEventById(v[i].event_id, e)) continue;
      if(!(e.importance==CALENDAR_IMPORTANCE_HIGH || (NewsWithMedium && e.importance==CALENDAR_IMPORTANCE_MODERATE))) continue;
      if(e.type==CALENDAR_TYPE_HOLIDAY) continue;
      MqlCalendarCountry c;
      if(!CalendarCountryById(e.country_id, c)) continue;
      if(StringFind("|USD|EUR|GBP|JPY|CHF|CAD|AUD|NZD|", "|"+c.currency+"|") < 0) continue;
      if(g_NxT==0 || v[i].time < g_NxT){ g_NxT = v[i].time; g_NxCur = c.currency; g_NxName = e.name; }
   }
}
string IstHM(datetime srv, bool withDate)
{
   long ist = (long)srv - (long)(TimeTradeServer() - TimeGMT()) + 19800;
   string s = TimeToString((datetime)ist, TIME_DATE|TIME_MINUTES);   // yyyy.mm.dd hh:mi
   return withDate ? StringSubstr(s,8,2)+"."+StringSubstr(s,5,2)+" "+StringSubstr(s,11,5) : StringSubstr(s,11,5);
}
string SessionName()
{
   MqlDateTime g; TimeToStruct(TimeGMT(), g);
   int h = g.hour;
   if(h>=13 && h<17) return "LONDON + NEW YORK";
   if(h>=8  && h<13) return "LONDON";
   if(h>=17 && h<22) return "NEW YORK";
   if(h>=0  && h<8)  return "TOKYO";
   return "SHANT (ROLLOVER)";
}

void Dash()
{
   if(!PanelOn){ PanelText(); return; }
   if(!g_CvOk) { PanelText(); return; }
   int wantH = Z(g_Mini ? DMINI : DH);
   if(g_Cv.Height() != wantH || g_Cv.Width() != Z(DW)) g_Cv.Resize(Z(DW), wantH);
   g_Cv.Erase(cBG);
   for(int i=0;i<3;i++) BtnSet(i, -1, -1, 0, 0);

   // --- halat ---
   bool off = (g_Real && !AllowReal);
   bool algo = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED));
   string stT = "CHALU"; uint stC = cGrn, stB = cGbg;
   if(off){ stT="BAND (REAL)"; stC=cRed; stB=cRbg; }
   else if(!algo){ stT="ALGO BAND"; stC=cRed; stB=cRbg; }
   else if(g_Paused){ stT="PAUSE"; stC=cAmb; stB=cNbg; }
   else if(g_Stop){ stT="AAJ BAND"; stC=cAmb; stB=cNbg; }
   else if(!g_FbOk){ stT="NET ERROR"; stC=cRed; stB=cRbg; }
   string ist = StringSubstr(TimeToString(TimeGMT()+19800, TIME_SECONDS), 11);
   string srv = StringSubstr(TimeToString(TimeTradeServer(), TIME_MINUTES), 11);
   long gs = (long)TimeGMT();
   long el = gs % 900;
   long nx = (el < 25 ? 25-el : 900-el+25);
   string cd = StringFormat("%02d:%02d", (int)(nx/60), (int)(nx%60));
   string netS = (g_Net>=0 ? "+$" : "-$")+DoubleToString(MathAbs(g_Net),2);
   double mxP = (DailyTargetUsd > 0 ? DailyTargetUsd : 5.0);
   int    mxL = (MaxLossesPerDay > 0 ? MaxLossesPerDay : 4);

   if(g_Mini)
   {
      DBox(0, 0, DW, DMINI, cTile, cBrd);
      DTxt(16, 10, "SAMUSIGNAL AI AUTO v"+VER, cOrg, 15, true, TA_LEFT|TA_TOP);
      DTxt(16, 32, ist+" IST", cFg, 20, true, TA_LEFT|TA_TOP, "Consolas");
      DPill(250, 18, 130, 28, stT, stC, stB);
      double x = DRun(400, 20, netS, g_Net>=0 ? cGrn : cRed, 20, true);
      x = DRun(x, 24, " / $"+DoubleToString(mxP,0), cLbl, 14, false);
      x = DRun(x+24, 20, IntegerToString(g_Losses)+"/"+IntegerToString(mxL), cRed, 20, true);
      x = DRun(x, 24, " loss", cLbl, 14, false);
      DTxt(700, 14, "AGLA SCAN", cLbl, 11, false, TA_LEFT|TA_TOP);
      DTxt(700, 30, cd, cOrg, 20, true, TA_LEFT|TA_TOP, "Consolas");
      DBox(916, 18, 28, 28, cTile, cLbl); DTxt(930, 32, "+", cFg, 18, true, TA_CENTER|TA_VCENTER); BtnSet(2, 916, 18, 28, 28);
      g_Cv.Update();
      return;
   }

   // --- upar: do meter + beech ka khaana ---
   DBox(16, 16, 310, 236, cTile, cBrd);
   int dP = (mxP == MathRound(mxP) && mxP <= 10 ? 0 : 1);
   int tP = (dP==0 ? (int)mxP : 5);
   DGauge(171, 150, g_Net, mxP, tP, dP, cGrn, false, netS, g_Net>=0 ? cGrn : cRed);
   DTxt(171, 228, "AAJ PROFIT | TARGET $"+DoubleToString(mxP, dP), cLbl, 12, false, TA_CENTER|TA_TOP);

   DBox(634, 16, 310, 236, cTile, cBrd);
   DGauge(789, 150, g_Losses, mxL, mxL, 0, cRed, true, IntegerToString(g_Losses)+" / "+IntegerToString(mxL), cRed);
   DTxt(789, 228, "AAJ LOSS | "+IntegerToString(mxL)+" = AAJ BAND", cLbl, 12, false, TA_CENTER|TA_TOP);

   DBox(336, 16, 288, 236, cTile, cBrd);
   DTxt(480, 28, "SAMUSIGNAL AI AUTO", cOrg, 18, true, TA_CENTER|TA_TOP);
   DBox(600, 22, 18, 18, cTile, cLbl); DTxt(609, 31, "-", cFg, 16, true, TA_CENTER|TA_VCENTER); BtnSet(2, 596, 18, 26, 26);
   DTxt(480, 58, ist, cFg, 44, true, TA_CENTER|TA_TOP, "Consolas");
   DTxt(480, 112, "IST | SERVER "+srv+" | "+SessionName(), cLbl, 12, false, TA_CENTER|TA_TOP);
   DPill(352, 144, 124, 28, stT, stC, stB);
   DPill(484, 144, 124, 28, (g_Real ? "REAL" : "DEMO")+" v"+VER, cBlu, cTile);
   if(g_Stop && !off) DTxt(480, 176, Fit(g_StopWhy, 256, 11, false, "Segoe UI"), cAmb, 11, false, TA_CENTER|TA_TOP);
   DBox(352, 196, 256, 44, cBG, cOrg);
   DTxt(364, 218, "AGLA SCAN", cLbl, 12, false, TA_LEFT|TA_VCENTER);
   DTxt(596, 218, cd, cOrg, 24, true, TA_RIGHT|TA_VCENTER, "Consolas");

   // --- 4 khaane ---
   double tx[4] = {16, 250, 484, 718};
   for(int i=0;i<4;i++) DBox(tx[i], 262, 226, 66, cTile, cBrd);
   int fin = g_Wins + g_Losses;
   DTxt(28, 270, "TP / SL | JEET", cLbl, 11, false, TA_LEFT|TA_TOP);
   double x2 = DRun(28, 290, IntegerToString(g_Wins), cGrn, 22, true);
   x2 = DRun(x2, 290, " / ", cFg, 22, true);
   x2 = DRun(x2, 290, IntegerToString(g_Losses), cRed, 22, true);
   DRun(x2+10, 296, fin>0 ? IntegerToString((int)MathRound(100.0*g_Wins/fin))+"%" : "-", cLbl, 15, true);

   int op=0, pd=0; double flo=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t=PositionGetTicket(i); if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue; op++; flo += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP); }
   for(int i=OrdersTotal()-1;i>=0;i--){ ulong t=OrderGetTicket(i); if(t==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue; pd++; }
   DTxt(262, 270, "OPEN / PEND", cLbl, 11, false, TA_LEFT|TA_TOP);
   x2 = DRun(262, 290, IntegerToString(op), cGrn, 22, true);
   x2 = DRun(x2, 290, " / ", cFg, 22, true);
   x2 = DRun(x2, 290, IntegerToString(pd), cBlu, 22, true);
   if(op>0) DRun(x2+10, 296, (flo>=0?"+":"-")+DoubleToString(MathAbs(flo),2), flo>=0 ? cGrn : cRed, 15, true);

   int ago = (g_ScT>0 ? (int)(((long)TimeGMT()-g_ScT)/60) : -1);
   DTxt(496, 270, ago<0 ? "SCANNER | DATA NAHI" : "SCAN | "+IntegerToString(ago)+" MIN PEHLE", ago>20 || ago<0 ? cRed : cLbl, 11, false, TA_LEFT|TA_TOP);
   if(ago>20) DTxt(496, 300, "SCANNER CHUP? (scanner.log)", cRed, 13, true, TA_LEFT|TA_TOP);
   else
   {
      x2 = DRun(496, 296, IntegerToString(g_ScPairs)+" | "+IntegerToString(g_ScCand)+" | AI "+IntegerToString(g_ScAi)+" | ", cFg, 15, true);
      DRun(x2, 296, IntegerToString(g_ScAgree)+" ok", cGrn, 15, true);
   }

   DTxt(730, 270, "SPREAD | MAX "+DoubleToString(MaxSpreadPctOfTP,0)+"% TP", cLbl, 11, false, TA_LEFT|TA_TOP);
   if(g_LastSpr >= 0)
   {
      bool sok = (MaxSpreadPctOfTP<=0 || g_LastSprPct <= MaxSpreadPctOfTP);
      x2 = DRun(730, 290, DoubleToString(g_LastSpr,0)+"p", sok ? cGrn : cRed, 22, true);
      DRun(x2+10, 296, DoubleToString(g_LastSprPct,0)+"% (aakhri)", cLbl, 13, false);
   }
   else DRun(730, 294, "- (abhi signal nahi)", cLbl, 13, false);

   // --- aaj ke signal ki patti ---
   int cpl=CntGet("pl"), csp=CntGet("sp"), cnw=CntGet("nw"), cpr=CntGet("pr"), cot=CntGet("ot");
   int tot = cpl+csp+cnw+cpr+cot;
   DBox(16, 338, 928, 54, cTile, cBrd);
   DTxt(28, 344, "AAJ "+IntegerToString(tot)+" SIGNAL AAYE", cLbl, 11, false, TA_LEFT|TA_TOP);
   if(tot<=0){ DBox(28, 362, 904, 22, cTrk, 0); DTxt(480, 373, "abhi koi signal nahi", cLbl, 12, false, TA_CENTER|TA_VCENTER); }
   else
   {
      int cnt[5]; cnt[0]=cpl; cnt[1]=csp; cnt[2]=cnw; cnt[3]=cpr; cnt[4]=cot;
      uint col[5]; col[0]=cGrn; col[1]=cOrg; col[2]=cAmb; col[3]=cGry; col[4]=cDim;
      string nm[5] = {"LAGE ", "SPREAD ", "NEWS ", "1-PAIR ", "BAAKI "};
      string sh[5] = {"L", "S", "N", "P", "B"};
      double bx = 28;
      for(int i=0;i<5;i++)
      {
         if(cnt[i]<=0) continue;
         double w = 904.0*cnt[i]/tot;
         DBox(bx, 362, w, 22, col[i], 0);
         string lab = nm[i]+IntegerToString(cnt[i]);
         SetFont("Segoe UI", 12, true);
         if(g_Cv.TextWidth(lab) > Z(w-8)) lab = sh[i]+IntegerToString(cnt[i]);
         if(g_Cv.TextWidth(lab) <= Z(w-4)) DTxt(bx+w/2, 373, lab, cBG, 12, true, TA_CENTER|TA_VCENTER);
         bx += w;
      }
   }

   // --- open trades ---
   DBox(16, 402, 459, 172, cTile, cBrd);
   DTxt(28, 410, "OPEN TRADES", cLbl, 11, false, TA_LEFT|TA_TOP);
   double cx5[5] = {28, 116, 196, 300, 390};
   string hd[5] = {"PAIR", "DIR", "ENTRY", "P/L", "TIME"};
   for(int i=0;i<5;i++) DTxt(cx5[i], 428, hd[i], cLbl, 10, false, TA_LEFT|TA_TOP);
   int row = 0; double ry;
   for(int i=PositionsTotal()-1;i>=0 && row<5;i--)
   {
      ulong t=PositionGetTicket(i); if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      string sy=PositionGetString(POSITION_SYMBOL); int dg=(int)SymbolInfoInteger(sy, SYMBOL_DIGITS);
      bool buy=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double pl=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      int mins=(int)((TimeCurrent()-(datetime)PositionGetInteger(POSITION_TIME))/60);
      ry = 446 + row*24;
      DTxt(cx5[0], ry, Name6(sy), cFg, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[1], ry, buy ? "BUY" : "SELL", buy ? cGrn : cRed, 13, true, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[2], ry, DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), dg), cFg, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[3], ry, (pl>=0?"+":"-")+DoubleToString(MathAbs(pl),2), pl>=0 ? cGrn : cRed, 13, true, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[4], ry, IntegerToString(mins)+"m", cLbl, 13, false, TA_LEFT|TA_TOP, "Consolas");
      row++;
   }
   for(int i=OrdersTotal()-1;i>=0 && row<5;i--)
   {
      ulong t=OrderGetTicket(i); if(t==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string sy=OrderGetString(ORDER_SYMBOL); int dg=(int)SymbolInfoInteger(sy, SYMBOL_DIGITS);
      long ty=OrderGetInteger(ORDER_TYPE);
      int left = PendingMin - (int)((TimeTradeServer()-(datetime)OrderGetInteger(ORDER_TIME_SETUP))/60);
      ry = 446 + row*24;
      DTxt(cx5[0], ry, Name6(sy), cFg, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[1], ry, ty==ORDER_TYPE_BUY_LIMIT ? "B.LIM" : (ty==ORDER_TYPE_SELL_LIMIT ? "S.LIM" : "PEND"), cBlu, 13, true, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[2], ry, DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN), dg), cFg, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[3], ry, "pend", cLbl, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(cx5[4], ry, IntegerToString(left<0?0:left)+"m", cAmb, 13, false, TA_LEFT|TA_TOP, "Consolas");
      row++;
   }
   if(row==0) DTxt(28, 452, "abhi koi trade / pending nahi", cLbl, 13, false, TA_LEFT|TA_TOP);
   else if(op+pd > row) DTxt(28, 446+row*24, "+"+IntegerToString(op+pd-row)+" aur", cLbl, 12, false, TA_LEFT|TA_TOP);

   // --- news + niyam ---
   string nwhy = "", nowBlk = "";
   for(int i=0;i<ArraySize(PAIRS28);i++){ if(NewsBlockCur(StringSubstr(PAIRS28[i],0,3), StringSubstr(PAIRS28[i],3,3), nwhy)){ nowBlk = nwhy; break; } }
   DBox(485, 402, 459, 172, cNbg, cNbr);
   if(nowBlk != "")
   {
      DTxt(497, 410, "NEWS ROK ABHI CHALU", cRed, 11, true, TA_LEFT|TA_TOP);
      DTxt(497, 428, Fit(nowBlk, 436, 14, true, "Segoe UI"), cFg, 14, true, TA_LEFT|TA_TOP);
      DTxt(497, 452, "is currency ke pair: naya order nahi, pending cancel", cLbl, 12, false, TA_LEFT|TA_TOP);
   }
   else if(g_NxT > 0)
   {
      int np = 0; for(int i=0;i<ArraySize(PAIRS28);i++) if(StringFind(PAIRS28[i], g_NxCur) >= 0) np++;
      DTxt(497, 410, "AGLI HIGH NEWS", cAmb, 11, true, TA_LEFT|TA_TOP);
      DTxt(497, 428, Fit(g_NxCur+" "+g_NxName, 436, 14, true, "Segoe UI"), cFg, 14, true, TA_LEFT|TA_TOP);
      DTxt(497, 452, IstHM(g_NxT, true)+" IST | rok "+IstHM(g_NxT-NewsBeforeMin*60, false)+"-"+IstHM(g_NxT+NewsAfterMin*60, false), cAmb, 13, false, TA_LEFT|TA_TOP, "Consolas");
      DTxt(497, 474, IntegerToString(np)+" pair | pending cancel | chalu trade SL ke saath", cLbl, 12, false, TA_LEFT|TA_TOP);
   }
   else
   {
      DTxt(497, 410, "NEWS", cAmb, 11, true, TA_LEFT|TA_TOP);
      DTxt(497, 430, NewsOn ? "agle 36 ghante koi High news nahi" : "news filter BAND (NewsOn=false)", cFg, 14, true, TA_LEFT|TA_TOP);
   }
   DTxt(497, 512, "TP $"+DoubleToString(TP_Usd,2)+" | SL $"+DoubleToString(SL_Usd,2)+" | "+DoubleToString(Lot,2)+" lot | AI >= "+IntegerToString(MinConf)+"% | LIMIT "+IntegerToString(PendingMin)+"m", cLbl, 12, false, TA_LEFT|TA_TOP);
   DTxt(497, 532, "news "+IntegerToString(NewsBeforeMin)+"/"+IntegerToString(NewsAfterMin)+" min | "+ExcludeCSV+" nahi | din reset "+IstHM((datetime)(((long)TimeTradeServer()/86400+1)*86400), false)+" IST", cLbl, 12, false, TA_LEFT|TA_TOP);

   // --- neeche: halat + aakhri signal + buttons ---
   DPill(16, 584, 92, 40, algo ? "ALGO ON" : "ALGO OFF", algo ? cGrn : cRed, algo ? cGbg : cRbg);
   DPill(114, 584, 116, 40, g_FbOk ? "FIREBASE OK" : "FIREBASE ERR", g_FbOk ? cGrn : cRed, g_FbOk ? cGbg : cRbg);
   DPill(236, 584, 100, 40, AllowReal ? "REAL ON" : "REAL LOCK", AllowReal ? cAmb : cBlu, cTile);
   DBox(342, 584, 338, 40, cTile, cBrd);
   DTxt(352, 604, Fit("> "+g_LastSig+" | "+g_LastRes, 320, 12, false), cOrg, 12, false, TA_LEFT|TA_VCENTER, "Consolas");
   if(g_Paused){ DBox(690, 584, 104, 40, cGbg, cGrn); DTxt(742, 604, "RESUME", cGrn, 12, true, TA_CENTER|TA_VCENTER); }
   else        { DBox(690, 584, 104, 40, cTile, cAmb); DTxt(742, 604, "PAUSE", cAmb, 12, true, TA_CENTER|TA_VCENTER); }
   BtnSet(0, 690, 584, 104, 40);
   bool armed = (g_CancelArm > 0 && TimeLocal() - g_CancelArm <= 4);
   if(armed){ DBox(804, 584, 140, 40, cRed, cRed); DTxt(874, 604, "PAKKA? DUBARA", cBG, 12, true, TA_CENTER|TA_VCENTER); }
   else     { DBox(804, 584, 140, 40, cRbg, cRed); DTxt(874, 604, "CANCEL PENDING", cRed, 12, true, TA_CENTER|TA_VCENTER); }
   BtnSet(1, 804, 584, 140, 40);
   g_Cv.Update();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != CVNAME) return;
   double lx = ((double)lparam - PanelX)/S(), ly = (dparam - PanelY)/S();
   int hit = -1;
   for(int i=0;i<3;i++) if(g_Bw[i] > 0 && lx >= g_Bx[i] && lx <= g_Bx[i]+g_Bw[i] && ly >= g_By[i] && ly <= g_By[i]+g_Bh[i]) hit = i;
   if(hit == 0)
   {
      g_Paused = !g_Paused;
      GlobalVariableSet(PauseName(), g_Paused ? 1 : 0);
      string m = g_Paused ? "PAUSE - ab naya order nahi (chalu trade / pending wahi)" : "RESUME - naye signal phir se";
      Print("SAMUSIGNAL AI AUTO: ", m);
      if(PushOn) SendNotification("SAMUSIGNAL AI AUTO: "+m);
      PublishState();
   }
   else if(hit == 1)
   {
      if(g_CancelArm > 0 && TimeLocal() - g_CancelArm <= 4)
      {
         g_CancelArm = 0;
         DeleteOurPendings("CANCELLED", "haath se cancel (panel)");
         Print("SAMUSIGNAL AI AUTO: saare pending haath se cancel (panel)");
      }
      else g_CancelArm = TimeLocal();
   }
   else if(hit == 2) g_Mini = !g_Mini;
   if(hit >= 0){ ObjectSetInteger(0, CVNAME, OBJPROP_SELECTED, false); Dash(); }
}

//+------------------------------------------------------------------+
