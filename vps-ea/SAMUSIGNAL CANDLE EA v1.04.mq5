//+------------------------------------------------------------------+
//|                                  SAMUSIGNAL CANDLE EA v1.04.mq5  |
//|                                           Ankush New Vision      |
//+------------------------------------------------------------------+
//|  v1.04 (user Final): HAATH SE LIYA TRADE bhi isi niyam se -      |
//|         is account par magic 0 wala trade EA apna leta hai: SL $10,|
//|         TP = pichhli band candle ki body ka 50% ($0.10-$1.00),     |
//|         candle band par fayde me / dusri candle se +$0.05 = BOOK, |
//|         200 candle = TIME. EA ke 3 slot me NAHI gina; manual ka 1 |
//|         slot alag (zyada khole to push chetavni, band nahi karta).|
//|         Manual trade wale pair par EA naya trade nahi kholta.     |
//|  v1.03 (user): PAIR DIN BHAR BAND - kisi pair ka trade floating  |
//|         me -$2 (BlockPairLossUsd, 0.01 lot par) se neeche gaya to |
//|         wo trade apne niyam se chalta rahe (TP / book / TIME),    |
//|         par us din (server din, 05:30 IST tak) us pair par naya   |
//|         trade nahi. EA restart par bhi yaad (GlobalVariable).     |
//|         BADLE KA PAIR: us pair ki jagah app me ek naya pair apne  |
//|         aap ON (ReserveOrder me se pehla jiski koi currency chalu  |
//|         pair se na takraye) + phone push. Agle din wo badla pair  |
//|         app se apne aap OFF (Firebase /candle/cfg/auto).          |
//|  v1.02 (user): TRADE SAMAY (IST) 07:00-17:00 aur 20:00-22:00 -   |
//|         bahar naya trade nahi (chalu trade apne niyam se). NEWS:  |
//|         High news (MT5 calendar, pair ki currency; BTC = USD) se |
//|         30 min pehle se 30 min baad tak naya trade nahi. Input   |
//|         NewsCloseOpen = true ho to us beech chalu trade bhi band.|
//|         Dashboard me SAMAY + NEWS line.                          |
//|         DIN KA TARGET $2 (user): aaj +$2 = us din naya trade nahi |
//|         (chalu trade apne niyam se). Din = server din (05:30 IST).|
//|  v1.01: DASHBOARD 'Matrix Terminal' (user ka sample) + PAUSE /   |
//|         CLOSE ALL (2 baar dabao) button.                         |
//|         SIRF 1 MIN (user: 5 MIN hatao) - app ka 5 MIN button EA   |
//|         par asar nahi; 5 MIN wala hold input hataya.            |
//|         Panel ki lines ek dusre par nahi chadhti (screen DPI ke   |
//|         hisaab se doori), kaala dabba peeche, status 'OK'.      |
//|         Trade niyam me koi badlav nahi.                          |
//|  v1.00 (user 16 Nov 2026): app ke CANDLE page (Strategy 5) ka   |
//|  apna EA - naye $100 DEMO account par. VPS paper jaisa hi niyam: |
//|                                                                  |
//|  KAUNSE PAIR: sirf wahi jo app ke Candle page me ON hain         |
//|   (Firebase /candle/cfg pairs, har 20 sec). v1.01: sirf 1 MIN.  |
//|   app ka (cfg.tf). App me pair OFF kiya = naya trade nahi (chalu |
//|   trade apne niyam se band hota hai).                            |
//|                                                                  |
//|  SIGNAL (har band candle, MT5 ki apni candles, app jaisa hi):    |
//|   body >= pichhli 10 ki average body x 1.2 aur >= range ka 50%;  |
//|   BUY = hari + EMA9 > EMA21 + close > EMA9 + RSI14 50-70,        |
//|   SELL = laal + EMA9 < EMA21 + close < EMA9 + RSI14 30-50.       |
//|   Agli candle khulte hi MARKET order (1m: 20 sec, 5m: 60 sec ke  |
//|   andar, warna chhod do).                                        |
//|                                                                  |
//|  TRADE (0.01 lot par, lot ke saath badhta):                      |
//|   TP = signal candle body ka 50% ($0.10 - $1.00), SL $10.        |
//|   Pehli candle: TP / SL, ya candle band par fayde me = BOOK.     |
//|   Dusri candle se: +$0.05 dikhte hi BOOK, ya kisi candle ka band |
//|   fayde me = BOOK. 1m: 200 candle, 5m: 72 candle baad TIME band. |
//|   1 pair = 1 trade. EK SAATH ZYADA SE ZYADA 3 TRADE (MaxOpen).   |
//|                                                                  |
//|  SURAKSHA: REAL account par trade tabhi jab AllowReal = true     |
//|   (user: DEMO). Spread $ > MaxSpreadUsd = SKIP. Din ka target /  |
//|   ghata (0 = band) - pahunche to us din naya trade nahi.         |
//|                                                                  |
//|  APP KE LIYE: /candle/ea/state (har 30 sec) aur                 |
//|   /candle/ea/trades/<key> (key = VPS paper wala hi, tulna ke     |
//|   liye). Phone push: trade khula / band.                         |
//|                                                                  |
//|  MT5: Tools > Options > Expert Advisors > Allow WebRequest me    |
//|  Firebase URL. Algo Trading ON. EA kisi bhi EK chart par.        |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.04"
#property description "SAMUSIGNAL CANDLE EA - app ke Candle page (Strategy 5) ke ON pair par, VPS paper jaisa niyam, max 3 trade"

#include <Trade\Trade.mqh>
CTrade trade;

#define VER "1.04"
#define LBL "SSC_L"

input group "========== FIREBASE =========="
input string FirebaseURL      = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // FirebaseURL (mat badlo)
input string FirebaseAuth     = "";        // FirebaseAuth (AI AUTO / News Pusher wala hi)

input group "========== TRADE =========="
input double Lot              = 0.01;      // Lot
input int    MaxOpen          = 3;         // Ek saath zyada se zyada kitne trade
input double SL_Usd           = 10.0;      // SL $ (0.01 lot par)
input double TpBodyPct        = 50;        // TP = signal candle body ka itna %
input double TpMin_Usd        = 0.10;      // TP kam se kam $ (0.01 lot par)
input double TpMax_Usd        = 1.00;      // TP zyada se zyada $ (0.01 lot par)
input double Book_Usd         = 0.05;      // Dusri candle se itna profit dikhte hi BOOK $
input int    HoldMax1         = 200;       // 1 MIN: kitni candle baad TIME band
input double MaxSpreadUsd     = 0.50;      // Spread max $ (0.01 lot par), 0 = jaanch nahi
input string ExcludeCSV       = "";        // In pair par trade nahi (jaise XAUUSD), khaali = sirf app
input string SymbolSuffix     = "";        // Symbol suffix (khaali = apne aap)
input long   Magic            = 7320001;   // Magic number
input bool   AllowReal        = false;     // REAL account par trade? (false = sirf DEMO)

input group "========== SIGNAL (app jaisa - mat badlo) =========="
input double BodyMult         = 1.2;       // body >= pichhli 10 ki average x
input double BodyPctRange     = 50;        // body >= candle range ka %
input int    EmaFast          = 9;         // EMA tez
input int    EmaSlow          = 21;        // EMA dheemi
input int    RsiLen           = 14;        // RSI
input int    CalcBars         = 250;       // Hisaab kitni band candle par (app / VPS feed = 250)

input group "========== TRADE SAMAY - IST (v1.02) =========="
input string TradeWindows     = "07:00-17:00,20:00-22:00"; // Naya trade sirf in samay (IST); khaali = hamesha

input group "========== NEWS (v1.02) =========="
input bool   NewsOn           = true;      // News filter chalu
input int    NewsBeforeMin    = 30;        // High news se kitne min pehle naya trade nahi
input int    NewsAfterMin     = 30;        // High news ke kitne min baad tak naya trade nahi
input bool   NewsWithMedium   = false;     // Medium news bhi
input bool   NewsCloseOpen    = false;     // News ke us beech chalu trade bhi band kar do?

input group "========== HAATH KA TRADE (v1.04) =========="
input bool   ManageManual     = true;      // Haath se liya trade (magic 0) bhi isi niyam se sambhalo
input int    ManualSlots      = 1;         // Manual ka alag slot (EA ke MaxOpen me nahi gina)
input double ManualTpBodyPct  = 50;        // Manual TP = pichhli band candle ki body ka itna %

input group "========== PAIR DIN BHAR BAND (v1.03) =========="
input double BlockPairLossUsd = 2.0;       // Trade floating me itna $ ghate me gaya = us din wo pair band (0 = band)
input bool   AutoReplace      = true;      // Pair band hone par app me badle ka pair apne aap ON (sirf us din) + push
input string ReserveOrder     = "EURCHF,GBPCHF,NZDCHF,EURNZD,GBPNZD,NZDCAD,AUDNZD,AUDCHF,CADCHF,NZDJPY,CHFJPY,EURJPY,GBPJPY,EURCAD,GBPCAD,AUDCAD,CADJPY,EURAUD,GBPAUD,NZDUSD,USDCHF,EURUSD,GBPUSD,USDJPY,AUDUSD"; // Badle ke pair (pehle wala pehle)

input group "========== DIN KI SEEMA (0 = band) =========="
input double DayTargetUsd     = 2.0;       // v1.02: din ka profit $ itna = us din naya trade nahi (0 = band)
input double DayLossUsd       = 0;         // Din ka ghata $ itna = us din naya trade nahi

input group "========== DUSRA =========="
input int    CfgPollSec       = 20;        // App ki settings har kitne sec padhe
input bool   PushOn           = true;      // Phone par push (trade khula / band)
input bool   PanelOn          = true;      // Chart par haal
input int    FontPx           = 12;        // Panel akshar size

// ---- halat ----
string   g_CfgPairs[];      // app format "BTC/USD"
string   g_Names[];         // "BTCUSD"
string   g_Syms[];          // broker symbol ("" = nahi mila)
datetime g_LastBar[];       // har pair ki aakhri jaanchi band candle
int      g_Tf = 1;
bool     g_CfgOk = false, g_FbOk = false, g_Real = false, g_UrlWarned = false;
datetime g_CfgAt = 0;
string   g_Status = "shuru...", g_Last = "-", g_LastSkip = "-";
double   g_DayPl = 0; int g_DayW = 0, g_DayL = 0;
long     g_Off = 0;         // server - UTC (sec)
// EA ne khud band kiya to wajah (position id -> wajah)
ulong    g_WhyId[]; string g_WhyTx[];
// har trade ki aakhri dekhi candle (book / TIME ke liye)
ulong    g_MgId[];  datetime g_MgBar[];
ulong    g_ManId[];  datetime g_ManStart[];  int g_ManWarn = 0;   // v1.04: apnaye gaye manual trade + ginti kab se
// v1.02: samay + news
int      g_WinFrom[], g_WinTo[];
datetime g_NewsT[]; string g_NewsCur[], g_NewsName[]; datetime g_NewsLoaded = 0;
datetime g_NxT = 0, g_NxLoaded = 0; string g_NxCur = "", g_NxName = "";

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(50);
   g_Real = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   if(g_Real && !AllowReal)
   {
      g_Status = "REAL account - AllowReal=false, trade NAHI";
      Alert("SAMUSIGNAL CANDLE EA: ye REAL account hai. User ne DEMO kaha hai - is account par koi order nahi lagega (AllowReal=false).");
   }
   WinParse();
   EventSetMillisecondTimer(250);
   Print("SAMUSIGNAL CANDLE EA v", VER, " shuru | lot ", DoubleToString(Lot,2), " | max ", MaxOpen, " trade | SL $", DoubleToString(SL_Usd,2),
         " | TP body ", DoubleToString(TpBodyPct,0), "% ($", DoubleToString(TpMin_Usd,2), "-", DoubleToString(TpMax_Usd,2), ") | book $", DoubleToString(Book_Usd,2));
   LoadCfg();
   DayStats();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ EventKillTimer(); ObjectsDeleteAll(0, LBL); Comment(""); }
void OnTick(){}

void OnTimer()
{
   static datetime lastCfg = 0, lastState = 0, lastDay = 0, lastPanel = 0;
   datetime now = TimeLocal();
   if(now - lastCfg >= (CfgPollSec < 5 ? 5 : CfgPollSec)){ lastCfg = now; LoadCfg(); }
   if(now - lastDay >= 10){ lastDay = now; DayStats(); }
   Manage();          // chalu trade: book / TIME (har 250 ms)
   ScanPairs();       // nayi band candle par signal
   if(now - lastState >= 30){ lastState = now; PublishState(); }
   NextNewsLoad();
   { static datetime lastExp = 0; if(AutoReplace && now - lastExp >= 60){ lastExp = now; AutoExpire(); } }   // v1.03
   if(now != lastPanel){ lastPanel = now; Panel(); }
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
string FbUrl(string path)
{
   string u = FbBase()+"/candle/"+path+".json";
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
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
         if(!g_UrlWarned){ g_UrlWarned = true; Alert("SAMUSIGNAL CANDLE EA: Tools > Options > Expert Advisors > Allow WebRequest me ye URL daalo: ", FbBase()); }
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
// "pairs":["BTC/USD","GBP/USD"] -> out[]
int JsonStrArr(string obj, string key, string &out[])
{
   ArrayResize(out, 0);
   int p = StringFind(obj, "\""+key+"\"");
   if(p<0) return -1;
   int a = StringFind(obj, "[", p), b = (a<0 ? -1 : StringFind(obj, "]", a));
   if(a<0 || b<0) return -1;
   string s = StringSubstr(obj, a+1, b-a-1);
   int n = 0, i = 0, L = StringLen(s);
   while(i < L)
   {
      int q1 = StringFind(s, "\"", i);
      if(q1<0) break;
      int q2 = StringFind(s, "\"", q1+1);
      if(q2<0) break;
      ArrayResize(out, n+1); out[n] = StringSubstr(s, q1+1, q2-q1-1); n++;
      i = q2+1;
   }
   return n;
}
string B36(long v)
{
   string d = "0123456789abcdefghijklmnopqrstuvwxyz", s = "";
   if(v <= 0) return "0";
   while(v > 0){ int m = (int)(v % 36); s = StringSubstr(d, m, 1) + s; v /= 36; }
   return s;
}

//+------------------------------------------------------------------+
//| App ki settings: kaunse pair ON + 1 / 5 MIN                      |
//+------------------------------------------------------------------+
bool IsExcluded(string name)
{
   string parts[];
   int n = StringSplit(ExcludeCSV, ',', parts);
   for(int i=0;i<n;i++){ string p = parts[i]; StringTrimLeft(p); StringTrimRight(p); StringToUpper(p); if(p!="" && p==name) return true; }
   return false;
}
void LoadCfg()
{
   string resp; int code;
   if(!Http("GET", FbUrl("cfg"), "", "", resp, code)) return;
   string arr[];
   string t0 = resp; StringTrimLeft(t0); StringTrimRight(t0);
   if(t0 == "" || t0 == "null")
   {
      g_CfgOk = false; g_Status = "app settings (/candle/cfg) nahi - app me Candle page kholo";
      ArrayResize(g_CfgPairs, 0); ArrayResize(g_Names, 0); ArrayResize(g_Syms, 0); ArrayResize(g_LastBar, 0);
      return;
   }
   int n = JsonStrArr(resp, "pairs", arr);
   if(n < 0) n = 0;                                                  // app me saare pair OFF (Firebase khaali list nahi rakhta)
   int newTf = 1;                                                    // v1.01: sirf 1 MIN (user)
   // naya pair list (purane pair ki aakhri candle yaad rakho)
   string oldN[]; datetime oldB[];
   int on = ArraySize(g_Names);
   ArrayResize(oldN, on); ArrayResize(oldB, on);
   for(int i=0;i<on;i++){ oldN[i] = g_Names[i]; oldB[i] = g_LastBar[i]; }
   ArrayResize(g_CfgPairs, 0); ArrayResize(g_Names, 0); ArrayResize(g_Syms, 0); ArrayResize(g_LastBar, 0);
   int c = 0;
   for(int i=0;i<n;i++)
   {
      string nm = arr[i]; StringReplace(nm, "/", ""); StringToUpper(nm);
      if(nm=="" || IsExcluded(nm)) continue;
      ArrayResize(g_CfgPairs, c+1); ArrayResize(g_Names, c+1); ArrayResize(g_Syms, c+1); ArrayResize(g_LastBar, c+1);
      g_CfgPairs[c] = arr[i]; g_Names[c] = nm; g_Syms[c] = Resolve(nm); g_LastBar[c] = 0;
      for(int j=0;j<on;j++) if(oldN[j]==nm && newTf==g_Tf) g_LastBar[c] = oldB[j];
      c++;
   }
   g_Tf = newTf;
   g_CfgOk = true; g_CfgAt = TimeLocal();
   g_Status = "OK";
}

//+------------------------------------------------------------------+
//| Symbol                                                           |
//+------------------------------------------------------------------+
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
// 0.01 lot nahi - 1.0 lot par 1 price-unit chalne ka $ (account currency)
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
ENUM_TIMEFRAMES Per(int tf){ return (tf == 5 ? PERIOD_M5 : PERIOD_M1); }
int TfFromKey(string key){ return (StringSubstr(key, StringLen(key)-1, 1) == "5" ? 5 : 1); }
int CountOpen()
{
   int n = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      n++;
   }
   return n;
}
bool SelectOur(string sym)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      if(PositionGetString(POSITION_SYMBOL)==sym) return true;
   }
   return false;
}
bool HasOpen(string sym)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      if(mg != Magic && !(ManageManual && mg == 0)) continue;     // v1.04: manual wala pair bhi busy
      if(PositionGetString(POSITION_SYMBOL)==sym) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Signal - app (candlerules.js) jaisa hi                           |
//+------------------------------------------------------------------+
double EmaLast(const double &c[], int n, int len)
{
   if(n < len) return EMPTY_VALUE;
   double k = 2.0/(len+1), e = 0;
   for(int i=0;i<len;i++) e += c[i];
   e /= len;
   for(int i=len;i<n;i++) e = c[i]*k + e*(1.0-k);
   return e;
}
double RsiLast(const double &c[], int n, int len)
{
   if(n < len+1) return EMPTY_VALUE;
   double g = 0, l = 0;
   for(int i=1;i<=len;i++){ double d = c[i]-c[i-1]; if(d>0) g += d; else l -= d; }
   g /= len; l /= len;
   for(int i=len+1;i<n;i++)
   {
      double d = c[i]-c[i-1];
      g = (g*(len-1) + MathMax(d,0.0))/len;
      l = (l*(len-1) + MathMax(-d,0.0))/len;
   }
   if(l == 0) return (g == 0 ? 50 : 100);
   return 100.0 - 100.0/(1.0 + g/l);
}
// dir: 1 BUY, -1 SELL, 0 NO
int Signal(string sym, ENUM_TIMEFRAMES per, double &body, string &why)
{
   body = 0; why = "";
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int got = CopyRates(sym, per, 1, CalcBars, r);   // sirf band candles, purani pehle
   int need = (int)MathMax(MathMax(EmaSlow+2, RsiLen+2), 12);
   if(got < need){ why = "kam candles ("+IntegerToString(got)+")"; return 0; }
   double c[];
   ArrayResize(c, got);
   for(int i=0;i<got;i++) c[i] = r[i].close;
   double e9 = EmaLast(c, got, EmaFast), e21 = EmaLast(c, got, EmaSlow), rs = RsiLast(c, got, RsiLen);
   double avg = 0;
   for(int i=got-11;i<=got-2;i++) avg += MathAbs(r[i].close - r[i].open);
   avg /= 10.0;
   MqlRates last = r[got-1];
   body = MathAbs(last.close - last.open);
   double range = last.high - last.low;
   bool green = last.close > last.open, red = last.close < last.open;
   if(!green && !red){ why = "doji"; return 0; }
   if(!(range > 0) || body < BodyPctRange/100.0*range){ why = "lambi poonch"; return 0; }
   if(!(avg > 0) || body < BodyMult*avg){ why = "candle mazboot nahi"; return 0; }
   if(e9 == EMPTY_VALUE || e21 == EMPTY_VALUE || rs == EMPTY_VALUE){ why = "hisaab adhoora"; return 0; }
   if(green)
   {
      if(!(e9 > e21)){ why = "EMA 9 < 21"; return 0; }
      if(!(last.close > e9)){ why = "close EMA 9 ke neeche"; return 0; }
      if(!(rs >= 50 && rs < 70)){ why = "RSI "+DoubleToString(rs,0); return 0; }
      why = "hari candle + EMA 9 > 21 + RSI "+DoubleToString(rs,0);
      return 1;
   }
   if(!(e9 < e21)){ why = "EMA 9 > 21"; return 0; }
   if(!(last.close < e9)){ why = "close EMA 9 ke upar"; return 0; }
   if(!(rs <= 50 && rs > 30)){ why = "RSI "+DoubleToString(rs,0); return 0; }
   why = "laal candle + EMA 9 < 21 + RSI "+DoubleToString(rs,0);
   return -1;
}

//+------------------------------------------------------------------+
//| Nayi band candle -> signal -> order                              |
//+------------------------------------------------------------------+
void ScanPairs()
{
   if(!g_CfgOk) return;
   g_Off = (long)MathRound(((double)TimeTradeServer() - (double)TimeGMT())/900.0)*900;
   ENUM_TIMEFRAMES per = Per(g_Tf);
   int winSec = (g_Tf == 5 ? 60 : 20);
   for(int i=0;i<ArraySize(g_Names);i++)
   {
      if(g_Syms[i]=="") continue;                                  // symbol nahi mila (har 20 sec phir dhoondhte hain)
      string sym = g_Syms[i];
      datetime b0 = iTime(sym, per, 0), b1 = iTime(sym, per, 1);
      if(b0 <= 0 || b1 <= 0) continue;
      if(g_LastBar[i] == 0){ g_LastBar[i] = b1; continue; }       // pehli baar: purana signal nahi
      if(b1 <= g_LastBar[i]) continue;
      g_LastBar[i] = b1;
      if((long)TimeTradeServer() - (long)b0 > winSec) continue;   // der ho gayi
      if(!InWindow()) continue;                                    // v1.02: trade samay ke bahar
      double body; string why;
      int dir = Signal(sym, per, body, why);
      if(dir == 0) continue;
      long nextMs = ((long)b0 - g_Off) * 1000;
      string key = "c" + B36(nextMs) + g_Names[i] + IntegerToString(g_Tf);
      Open(i, sym, dir, body, key, why);
   }
}
void SkipMsg(string nm, string dir, string msg)
{
   g_LastSkip = nm+" "+dir+": "+msg;
   AddLog("SKIP "+g_LastSkip);
   Print("SAMUSIGNAL CANDLE EA: SKIP ", g_LastSkip);
}
void Open(int idx, string sym, int dir, double body, string key, string why)
{
   string nm = g_Names[idx], ds = (dir > 0 ? "BUY" : "SELL");
   if(g_Real && !AllowReal){ SkipMsg(nm, ds, "REAL account - AllowReal=false"); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)){ SkipMsg(nm, ds, "MT5 me Algo Trading band"); return; }
   if(DayTargetUsd > 0 && g_DayPl >= DayTargetUsd){ SkipMsg(nm, ds, "aaj ka target poora ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd){ SkipMsg(nm, ds, "aaj ki ghata seema ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(IsPaused()){ SkipMsg(nm, ds, "PAUSE (panel se)"); return; }
   if(!InWindow()){ SkipMsg(nm, ds, "trading samay ke bahar (agla "+NextWindowTxt()+" IST)"); return; }
   { string nw; if(NewsBlock(sym, nw)){ SkipMsg(nm, ds, "news: "+nw); return; } }
   if(PairBlocked(sym)){ SkipMsg(nm, ds, "aaj band - is pair ka trade -$"+DoubleToString(BlockPairLossUsd,2)+" se neeche gaya tha"); return; }   // v1.03
   if(HasOpen(sym)){ SkipMsg(nm, ds, "1 pair 1 trade - pehle wala chalu"); return; }
   int op = CountOpen();
   if(op >= MaxOpen){ SkipMsg(nm, ds, "pehle se "+IntegerToString(op)+" / "+IntegerToString(MaxOpen)+" trade chalu"); return; }

   double k = UsdPerPriceLot(sym) * Lot;                 // is lot par 1 price-unit = $k
   if(k <= 0){ SkipMsg(nm, ds, "tick value nahi mila"); return; }
   double sc = Lot/0.01;
   double tp01 = MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * (k/sc) * TpBodyPct/100.0));
   tp01 = MathRound(tp01*100.0)/100.0;
   double tpUsd = tp01*sc, slUsd = SL_Usd*sc;
   double tpD = tpUsd/k, slD = slUsd/k;
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(ask <= 0 || bid <= 0){ SkipMsg(nm, ds, "bhaav nahi"); return; }
   double sprUsd = (ask-bid) * k / sc;
   if(MaxSpreadUsd > 0 && sprUsd > MaxSpreadUsd + 1e-9){ SkipMsg(nm, ds, "spread $"+DoubleToString(sprUsd,2)+" > $"+DoubleToString(MaxSpreadUsd,2)); return; }
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   double tpUse = MathMax(tpD, minD + pt), slUse = MathMax(slD, minD + pt);
   double px = (dir > 0 ? ask : bid);
   double tp = NormalizeDouble(dir > 0 ? px + tpUse : px - tpUse, dg);
   double sl = NormalizeDouble(dir > 0 ? px - slUse : px + slUse, dg);
   trade.SetTypeFillingBySymbol(sym);
   bool ok = (dir > 0 ? trade.Buy(Lot, sym, 0, sl, tp, key) : trade.Sell(Lot, sym, 0, sl, tp, key));
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
   {
      string m = "order nahi laga: "+IntegerToString((int)trade.ResultRetcode())+" "+trade.ResultRetcodeDescription();
      SkipMsg(nm, ds, m);
      if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" - "+m);
      return;
   }
   // asli bhaav se TP / SL dobara (paper jaisa: entry se TP ki doori)
   double fill = trade.ResultPrice();
   ulong posId = 0;
   if(SelectOur(sym))
   {
      posId = (ulong)PositionGetInteger(POSITION_TICKET);
      fill = PositionGetDouble(POSITION_PRICE_OPEN);
      double tp2 = NormalizeDouble(dir > 0 ? fill + tpUse : fill - tpUse, dg);
      double sl2 = NormalizeDouble(dir > 0 ? fill - slUse : fill + slUse, dg);
      if(MathAbs(tp2-tp) > pt/2 || MathAbs(sl2-sl) > pt/2) trade.PositionModify(posId, sl2, tp2);
   }
   int n = CountOpen();
   g_Last = nm+" "+ds+" khula @ "+DoubleToString(fill, dg)+" | TP $"+DoubleToString(tpUsd,2);
   Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", why);
   AddLog(g_Last); SetAlert(g_Last+"  ("+IntegerToString(n)+"/"+IntegerToString(MaxOpen)+")");
   if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" khula | TP $"+DoubleToString(tpUsd,2)+" | "+IntegerToString(n)+"/"+IntegerToString(MaxOpen)+" chalu");
   long nextMs = 0;
   { long b0 = (long)iTime(sym, Per(g_Tf), 0); nextMs = (b0 - g_Off)*1000; }
   string js = "{\"id\":\""+key+"\",\"sym\":\""+JsonSafe(g_CfgPairs[idx])+"\",\"n\":\""+nm+"\",\"dir\":\""+ds+"\",\"tf\":"+IntegerToString(g_Tf)
      +",\"next\":"+IntegerToString(nextMs)+",\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"entry\":"+DoubleToString(fill, dg)
      +",\"tp\":"+DoubleToString(tpUsd,2)+",\"sl\":"+DoubleToString(slUsd,2)+",\"spread\":"+DoubleToString(sprUsd,2)
      +",\"lot\":"+DoubleToString(Lot,2)+",\"done\":false}";
   string resp; int code;
   Http("POST", FbUrl("ea/trades/"+key), js, "X-HTTP-Method-Override: PUT\r\n", resp, code);
}

//+------------------------------------------------------------------+
//| Chalu trade: BOOK / TIME (paper jaisa)                           |
//+------------------------------------------------------------------+
void SetWhy(ulong id, string w)
{
   int n = ArraySize(g_WhyId);
   for(int i=0;i<n;i++) if(g_WhyId[i]==id){ g_WhyTx[i] = w; return; }
   if(n >= 50){ for(int i=1;i<n;i++){ g_WhyId[i-1] = g_WhyId[i]; g_WhyTx[i-1] = g_WhyTx[i]; } n--; }
   ArrayResize(g_WhyId, n+1); ArrayResize(g_WhyTx, n+1);
   g_WhyId[n] = id; g_WhyTx[n] = w;
}
string GetWhy(ulong id)
{
   for(int i=0;i<ArraySize(g_WhyId);i++) if(g_WhyId[i]==id) return g_WhyTx[i];
   return "";
}
int MgIdx(ulong id)
{
   for(int i=0;i<ArraySize(g_MgId);i++) if(g_MgId[i]==id) return i;
   int n = ArraySize(g_MgId);
   ArrayResize(g_MgId, n+1); ArrayResize(g_MgBar, n+1);
   g_MgId[n] = id; g_MgBar[n] = 0;
   return n;
}
void MgClean()
{
   for(int i=ArraySize(g_MgId)-1;i>=0;i--)
   {
      if(PositionSelectByTicket(g_MgId[i])) continue;
      int n = ArraySize(g_MgId);
      for(int j=i+1;j<n;j++){ g_MgId[j-1] = g_MgId[j]; g_MgBar[j-1] = g_MgBar[j]; }
      ArrayResize(g_MgId, n-1); ArrayResize(g_MgBar, n-1);
   }
}
void Manage()
{
   static datetime lastClean = 0;
   int manN = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      bool man = (ManageManual && mg == 0);                          // v1.04: haath ka trade
      if(mg != Magic && !man) continue;
      if(man){ manN++; AdoptManual(t); if(!PositionSelectByTicket(t)) continue; }
      string sym = PositionGetString(POSITION_SYMBOL), key = PositionGetString(POSITION_COMMENT);
      int tf = (man ? 1 : TfFromKey(key)), perSec = tf*60;          // v1.04: manual hamesha 1 MIN
      ENUM_TIMEFRAMES per = Per(tf);
      datetime openT = (datetime)PositionGetInteger(POSITION_TIME);
      datetime entryBar = (datetime)((long)openT - (long)openT % perSec);
      if(man){ datetime ms = ManStart(t); if(ms > 0) entryBar = ms; }    // purana manual: ginti apnane se
      datetime b0 = iTime(sym, per, 0);
      if(b0 <= 0) continue;
      int idx = (int)(((long)b0 - (long)entryBar)/perSec);   // abhi kaunsi candle (0 = entry wali)
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double sc = PositionGetDouble(POSITION_VOLUME)/0.01;
      if(NewsCloseOpen){ string nw; if(NewsBlock(sym, nw)){ CloseIt(t, "NEWS: "+nw); continue; } }   // v1.02
      if(!man && BlockPairLossUsd > 0 && pl <= -BlockPairLossUsd*sc) BlockPair(sym, pl);   // v1.03 (manual alag)
      int m = MgIdx(t);
      bool newBar = (g_MgBar[m] != 0 && b0 > g_MgBar[m]);
      if(g_MgBar[m] == 0) g_MgBar[m] = (idx > 0 ? b0 : entryBar);
      if(newBar)
      {
         g_MgBar[m] = b0;
         int holdMax = HoldMax1;
         if(pl > 0.004*sc){ CloseIt(t, "PROFIT BOOK"); continue; }        // candle band hui fayde me
         if(idx >= holdMax){ CloseIt(t, "TIME"); continue; }               // itni candle ho gayi
      }
      if(idx >= 1 && pl >= Book_Usd*sc){ CloseIt(t, "PROFIT BOOK"); continue; }   // dusri candle se +$0.05
   }
   if(ManageManual && manN > ManualSlots && manN != g_ManWarn)
   {
      g_ManWarn = manN;
      string w = "Manual slot "+IntegerToString(ManualSlots)+" hai, abhi "+IntegerToString(manN)+" haath ke trade chalu (sab isi niyam se sambhal raha hoon)";
      AddLog(w); if(PushOn) SendNotification("CANDLE EA: "+w);
   }
   if(manN <= ManualSlots) g_ManWarn = 0;
   if(TimeLocal() - lastClean >= 60){ lastClean = TimeLocal(); MgClean(); }
}
void CloseIt(ulong t, string why)
{
   SetWhy(t, why);
   bool man = (PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == 0);
   if(man) trade.SetExpertMagicNumber(0);                             // v1.04: manual band ka deal EA ke din ke hisaab me na jaaye
   bool ok = trade.PositionClose(t);
   if(man) trade.SetExpertMagicNumber(Magic);
   if(!ok)
      Print("SAMUSIGNAL CANDLE EA: band nahi hua (", why, "): ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| Trade band -> Firebase + push                                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &tr, const MqlTradeRequest &rq, const MqlTradeResult &rs)
{
   if(tr.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(tr.deal)) return;
   long dmg = HistoryDealGetInteger(tr.deal, DEAL_MAGIC);
   long en = HistoryDealGetInteger(tr.deal, DEAL_ENTRY);
   if(dmg != Magic)
   {
      // v1.04: apnaya hua haath ka trade band (EA ne band kiya to deal par EA ka magic hota hai; broker TP / SL par 0)
      ulong pid0 = (ulong)HistoryDealGetInteger(tr.deal, DEAL_POSITION_ID);
      if(ManageManual && IsAdopted(pid0) && (en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY))
      {
         double pl0 = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
         long r0 = HistoryDealGetInteger(tr.deal, DEAL_REASON);
         string why0 = GetWhy(pid0);
         if(r0 == DEAL_REASON_TP) why0 = "TP"; else if(r0 == DEAL_REASON_SL) why0 = "SL"; else if(why0 == "") why0 = "haath se band";
         string m0 = "Haath ka trade "+Name6(HistoryDealGetString(tr.deal, DEAL_SYMBOL))+" "+why0+" "+(pl0>=0?"+":"")+DoubleToString(pl0,2)+"$";
         AddLog(m0); SetAlert(m0);
         if(PushOn) SendNotification("CANDLE EA: "+m0);
      }
      return;
   }
   if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_OUT_BY) return;
   {
      ulong pidm = (ulong)HistoryDealGetInteger(tr.deal, DEAL_POSITION_ID);
      if(IsAdopted(pidm))                                               // v1.04: EA ne manual trade band kiya
      {
         double plm = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
         string mm = "Haath ka trade "+Name6(HistoryDealGetString(tr.deal, DEAL_SYMBOL))+" "+GetWhy(pidm)+" "+(plm>=0?"+":"")+DoubleToString(plm,2)+"$";
         AddLog(mm); SetAlert(mm);
         if(PushOn) SendNotification("CANDLE EA: "+mm);
         return;
      }
   }
   double pl = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
   string sym = HistoryDealGetString(tr.deal, DEAL_SYMBOL);
   ulong  pid = (ulong)HistoryDealGetInteger(tr.deal, DEAL_POSITION_ID);
   long   rsn = HistoryDealGetInteger(tr.deal, DEAL_REASON);
   datetime outT = (datetime)HistoryDealGetInteger(tr.deal, DEAL_TIME);
   double   outP = HistoryDealGetDouble(tr.deal, DEAL_PRICE);
   string res = GetWhy(pid);
   if(rsn == DEAL_REASON_TP) res = "TP";
   else if(rsn == DEAL_REASON_SL) res = "SL";
   else if(res == "") res = "BAND (haath / dusra)";
   // entry wala deal: key (comment), dir, samay
   string key = "", ds = "";
   datetime inT = 0;
   if(HistorySelectByPosition(pid))
   {
      for(int i=0;i<HistoryDealsTotal();i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d==0 || HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
         key = HistoryDealGetString(d, DEAL_COMMENT);
         ds  = (HistoryDealGetInteger(d, DEAL_TYPE) == DEAL_TYPE_BUY ? "BUY" : "SELL");
         inT = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      }
   }
   int tf = TfFromKey(key), perSec = tf*60;
   int nC = (inT > 0 ? (int)(((long)outT - ((long)inT - (long)inT % perSec))/perSec) + 1 : 0);
   DayStats();
   string nm = Name6(sym);
   g_Last = nm+" "+ds+" "+res+" "+(pl>=0?"+":"")+DoubleToString(pl,2)+"$";
   Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", nC, " candle | aaj ", DoubleToString(g_DayPl,2), "$");
   AddLog(g_Last+" | "+IntegerToString(nC)+" candle"); SetAlert(g_Last+"   aaj "+(g_DayPl>=0?"+":"")+DoubleToString(g_DayPl,2));
   if(PushOn) SendNotification("CANDLE EA: "+g_Last+" | "+IntegerToString(nC)+" candle | aaj "+(g_DayPl>=0?"+":"")+DoubleToString(g_DayPl,2)+"$ ("+IntegerToString(g_DayW)+"/"+IntegerToString(g_DayL)+")");
   if(key != "" && StringGetCharacter(key, 0) == 'c')
   {
      string body = "{\"done\":true,\"res\":\""+JsonSafe(res)+"\",\"pl\":"+DoubleToString(pl,2)+",\"exitT\":"+IntegerToString(((long)outT - g_Off)*1000)
         +",\"cn\":"+IntegerToString(nC)+",\"exit\":"+DoubleToString(outP, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS))+"}";
      string resp; int code;
      Http("POST", FbUrl("ea/trades/"+key), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code);
   }
   PublishState();
}
string Name6(string sym){ string u = sym; StringToUpper(u); return StringSubstr(u, 0, 6); }

//+------------------------------------------------------------------+
//| Din ka hisaab (server din)                                       |
//+------------------------------------------------------------------+
void DayStats()
{
   long ns = (long)TimeTradeServer();
   datetime now = (datetime)ns, d0 = (datetime)(ns - ns % 86400);
   g_DayPl = 0; g_DayW = 0; g_DayL = 0;
   if(!HistorySelect(d0, now + 3600)) return;
   int n = HistoryDealsTotal();
   for(int i=0;i<n;i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d==0 || HistoryDealGetInteger(d, DEAL_MAGIC)!=Magic) continue;
      double pr = HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
      g_DayPl += pr;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY){ if(pr < 0) g_DayL++; else g_DayW++; }
   }
}

//+------------------------------------------------------------------+
//| App ke liye halat                                                |
//+------------------------------------------------------------------+
string StopWhy()
{
   if(g_Real && !AllowReal) return "REAL account - AllowReal=false";
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return "MT5 me Algo Trading band";
   if(DayTargetUsd > 0 && g_DayPl >= DayTargetUsd) return "aaj ka target poora";
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd) return "aaj ki ghata seema";
   if(!g_CfgOk) return "app settings nahi mili";
   if(IsPaused()) return "PAUSE (panel se)";
   if(!InWindow()) return "trading samay ke bahar (agla "+NextWindowTxt()+" IST)";
   return "";
}
void PublishState()
{
   string open = "[";
   int op = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      open += (op ? "," : "") + "{\"n\":\""+Name6(sym)+"\",\"dir\":\""+(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "BUY" : "SELL")+"\",\"pl\":"+DoubleToString(pl,2)
            +",\"key\":\""+JsonSafe(PositionGetString(POSITION_COMMENT))+"\"}";
      op++;
   }
   open += "]";
   string pairs = "[";
   for(int i=0;i<ArraySize(g_Names);i++) pairs += (i ? "," : "") + "\""+g_Names[i]+(g_Syms[i]=="" ? "?" : "")+"\"";
   pairs += "]";
   string sw = StopWhy();
   string body = "{\"t\":"+IntegerToString((long)TimeGMT())+",\"v\":\""+VER+"\",\"tf\":"+IntegerToString(g_Tf)+",\"pairs\":"+pairs
      +",\"open\":"+IntegerToString(op)+",\"max\":"+IntegerToString(MaxOpen)+",\"list\":"+open
      +",\"dayPl\":"+DoubleToString(g_DayPl,2)+",\"dayW\":"+IntegerToString(g_DayW)+",\"dayL\":"+IntegerToString(g_DayL)
      +",\"bal\":"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+",\"eq\":"+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)
      +",\"demo\":"+(g_Real ? "false" : "true")+",\"stop\":\""+JsonSafe(sw)+"\",\"last\":\""+JsonSafe(g_Last)+"\",\"skip\":\""+JsonSafe(g_LastSkip)+"\",\"blk\":\""+JsonSafe(BlockedTxt())+"\"}";
   string resp; int code;
   Http("POST", FbUrl("ea/state"), body, "X-HTTP-Method-Override: PUT\r\n", resp, code);
}

//+------------------------------------------------------------------+
//| v1.04: HAATH KA TRADE apnao (SL $10 + TP pichhli candle body 50%) |
//+------------------------------------------------------------------+
bool IsAdopted(ulong t){ for(int i=0;i<ArraySize(g_ManId);i++) if(g_ManId[i]==t) return true; return false; }
datetime ManStart(ulong t){ for(int i=0;i<ArraySize(g_ManId);i++) if(g_ManId[i]==t) return g_ManStart[i]; return 0; }
void AdoptManual(ulong t)
{
   if(IsAdopted(t)) return;
   if(!PositionSelectByTicket(t)) return;
   string sym = PositionGetString(POSITION_SYMBOL);
   bool buy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   double vol = PositionGetDouble(POSITION_VOLUME), op = PositionGetDouble(POSITION_PRICE_OPEN);
   datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
   int sh = iBarShift(sym, PERIOD_M1, ot, false);
   if(sh < 0) return;
   double o = iOpen(sym, PERIOD_M1, sh + 1), c = iClose(sym, PERIOD_M1, sh + 1);   // pichhli band candle
   double k = UsdPerPriceLot(sym) * vol;
   if(k <= 0 || o <= 0) return;
   double sc = vol / 0.01;
   double body = MathAbs(c - o);
   double tp01 = MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * (k/sc) * ManualTpBodyPct/100.0));
   tp01 = MathRound(tp01*100.0)/100.0;
   double tpUsd = tp01*sc, slUsd = SL_Usd*sc;
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT), minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   double tpD = MathMax(tpUsd/k, minD + pt), slD = MathMax(slUsd/k, minD + pt);
   double tp = NormalizeDouble(buy ? op + tpD : op - tpD, dg), sl = NormalizeDouble(buy ? op - slD : op + slD, dg);
   int n = ArraySize(g_ManId); ArrayResize(g_ManId, n+1); ArrayResize(g_ManStart, n+1); g_ManId[n] = t;
   datetime b0 = iTime(sym, PERIOD_M1, 0);
   g_ManStart[n] = (TimeTradeServer() - ot < 300 || b0 <= 0) ? (datetime)((long)ot - (long)ot % 60) : b0;   // 5 min se purana = abhi se ginti
   bool ok = trade.PositionModify(t, sl, tp);
   string m = "Haath ka trade "+Name6(sym)+" "+(buy ? "BUY" : "SELL")+" "+DoubleToString(vol,2)+" apnaya: TP $"+DoubleToString(tpUsd,2)+" (pichhli candle body "+DoubleToString(ManualTpBodyPct,0)+"%), SL $"+DoubleToString(slUsd,2)+(ok ? "" : " - TP/SL lagana NAHI hua: "+trade.ResultRetcodeDescription());
   Print("SAMUSIGNAL CANDLE EA: ", m);
   AddLog(m);
   if(PushOn) SendNotification("CANDLE EA: "+m);
}
int CountManual()
{
   int n = 0;
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t = PositionGetTicket(i); if(t>0 && PositionGetInteger(POSITION_MAGIC)==0) n++; }
   return n;
}

//+------------------------------------------------------------------+
//| v1.03: PAIR DIN BHAR BAND (floating -$2)                          |
//+------------------------------------------------------------------+
long   DayStart(){ long ns = (long)TimeTradeServer(); return ns - ns % 86400; }
string BlkName(string sym){ return "SSC_BLK_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" + Name6(sym); }
bool   PairBlocked(string sym)
{
   string g = BlkName(sym);
   return GlobalVariableCheck(g) && (long)GlobalVariableGet(g) == DayStart();
}
void   BlockPair(string sym, double pl)
{
   if(PairBlocked(sym)) return;
   GlobalVariableSet(BlkName(sym), (double)DayStart());
   string m = Name6(sym)+" aaj ke liye band: trade "+DoubleToString(pl,2)+"$ tak gaya (seema -$"+DoubleToString(BlockPairLossUsd,2)+"). Chalu trade apne niyam se chalega.";
   Print("SAMUSIGNAL CANDLE EA: ", m);
   AddLog(m); SetAlert(Name6(sym)+" AAJ BAND (-$"+DoubleToString(BlockPairLossUsd,2)+")");
   if(PushOn) SendNotification("CANDLE EA: "+m);
   AutoReplacePair(sym);
}
// ---- v1.03: badle ka pair (app me ON / agle din OFF) ----
string Slash(string n6){ return StringSubstr(n6, 0, 3) + "/" + StringSubstr(n6, 3, 3); }
bool   UsesCur(string used, string n6){ return StringFind(used, ","+StringSubstr(n6, 0, 3)+",") >= 0 || StringFind(used, ","+StringSubstr(n6, 3, 3)+",") >= 0; }
string PairsJson(string &arr[], int n, string skip6, string add)
{
   string js = "[";
   int c = 0;
   for(int i=0;i<n;i++)
   {
      string nm = arr[i]; StringReplace(nm, "/", ""); StringToUpper(nm);
      if(skip6 != "" && nm == skip6) continue;
      js += (c ? "," : "") + "\""+JsonSafe(arr[i])+"\""; c++;
   }
   if(add != "") js += (c ? "," : "") + "\""+add+"\"";
   return js + "]";
}
void AutoReplacePair(string blockedSym)
{
   if(!AutoReplace) return;
   string bn = Name6(blockedSym);
   string gk = "SSC_REP_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" + bn;
   if(GlobalVariableCheck(gk) && (long)GlobalVariableGet(gk) == DayStart()) return;    // aaj is pair ka badla ho chuka
   string resp; int code;
   if(!Http("GET", FbUrl("cfg"), "", "", resp, code)) return;
   string arr[];
   int n = JsonStrArr(resp, "pairs", arr);
   if(n < 0) n = 0;
   string used = ",", have = ",";
   for(int i=0;i<n;i++)
   {
      string nm = arr[i]; StringReplace(nm, "/", ""); StringToUpper(nm);
      have += nm + ",";
      if(nm == bn || StringLen(nm) < 6) continue;
      string s2 = Resolve(nm);
      if(s2 != "" && PairBlocked(s2)) continue;                    // band pair ki currency khaali maani
      used += StringSubstr(nm, 0, 3) + "," + StringSubstr(nm, 3, 3) + ",";
   }
   string cand[];
   int m = StringSplit(ReserveOrder, ',', cand);
   string pick = "";
   for(int j=0;j<m;j++)
   {
      string c = cand[j]; StringTrimLeft(c); StringTrimRight(c); StringToUpper(c);
      if(StringLen(c) != 6 || StringFind(have, ","+c+",") >= 0 || UsesCur(used, c) || IsExcluded(c)) continue;
      string cs = Resolve(c);
      if(cs == "" || PairBlocked(cs)) continue;
      pick = c; break;
   }
   GlobalVariableSet(gk, (double)DayStart());
   if(pick == "")
   {
      string m0 = bn+" ki jagah koi badla pair nahi mila (sab currency pehle se chalu)";
      AddLog(m0); if(PushOn) SendNotification("CANDLE EA: "+m0);
      return;
   }
   if(!Http("POST", FbUrl("cfg"), "{\"pairs\":"+PairsJson(arr, n, "", Slash(pick))+"}", "X-HTTP-Method-Override: PATCH\r\n", resp, code)) return;
   Http("POST", FbUrl("cfg/auto/"+pick), "{\"d\":"+IntegerToString(DayStart())+",\"for\":\""+bn+"\",\"t\":"+IntegerToString((long)TimeGMT())+"}", "X-HTTP-Method-Override: PUT\r\n", resp, code);
   string msg = bn+" aaj band -> app me "+pick+" ON (sirf aaj, kal apne aap OFF)";
   Print("SAMUSIGNAL CANDLE EA: ", msg);
   AddLog(msg); SetAlert(pick+" ON ("+bn+" ki jagah)");
   if(PushOn) SendNotification("CANDLE EA: "+msg);
   LoadCfg();
}
// har 60 sec: pichhle din ke badle pair app se OFF
void AutoExpire()
{
   string resp; int code;
   if(!Http("GET", FbUrl("cfg/auto"), "", "", resp, code)) return;
   string t0 = resp; StringTrimLeft(t0); StringTrimRight(t0);
   if(t0 == "" || t0 == "null") return;
   long today = DayStart();
   int p = 0, L = StringLen(resp);
   while(p < L)
   {
      int q = StringFind(resp, "\":{", p);
      if(q < 0) break;
      int k = q - 1;
      while(k > 0 && StringGetCharacter(resp, k) != '"') k--;
      string name = StringSubstr(resp, k + 1, q - k - 1);
      int e = StringFind(resp, "}", q);
      if(e < 0) break;
      string obj = StringSubstr(resp, q + 2, e - q - 1);
      p = e + 1;
      long d = (long)JsonNum(obj, "d");
      if(StringLen(name) != 6 || d >= today) continue;
      string r2; int c2;
      if(!Http("GET", FbUrl("cfg"), "", "", r2, c2)) return;
      string arr[];
      int n = JsonStrArr(r2, "pairs", arr);
      if(n < 0) n = 0;
      Http("POST", FbUrl("cfg"), "{\"pairs\":"+PairsJson(arr, n, name, "")+"}", "X-HTTP-Method-Override: PATCH\r\n", r2, c2);
      Http("POST", FbUrl("cfg/auto/"+name), "", "X-HTTP-Method-Override: DELETE\r\n", r2, c2);
      string msg = name+" app se OFF (naya din) - "+JsonStrSimple(obj, "for")+" phir chalu";
      Print("SAMUSIGNAL CANDLE EA: ", msg);
      AddLog(msg);
      if(PushOn) SendNotification("CANDLE EA: "+msg);
      LoadCfg();
   }
}
string JsonStrSimple(string obj, string key)
{
   int a = StringFind(obj, "\""+key+"\"");
   if(a < 0) return "";
   a = StringFind(obj, "\"", StringFind(obj, ":", a) + 1);
   if(a < 0) return "";
   int b = StringFind(obj, "\"", a + 1);
   return (b > a ? StringSubstr(obj, a + 1, b - a - 1) : "");
}
string BlockedTxt()
{
   string t = "";
   for(int i=0;i<ArraySize(g_Syms);i++) if(g_Syms[i]!="" && PairBlocked(g_Syms[i])) t += (t=="" ? "" : ", ")+g_Names[i];
   return t;
}

//+------------------------------------------------------------------+
//| v1.02: TRADE SAMAY (IST) + NEWS (AI AUTO jaisa, MT5 calendar)     |
//+------------------------------------------------------------------+
int IstMin(){ long t = (long)TimeGMT() + 19800; return (int)((t % 86400) / 60); }
int HhmmToMin(string s)
{
   StringTrimLeft(s); StringTrimRight(s);
   string hm[];
   if(StringSplit(s, ':', hm) != 2) return -1;
   int h = (int)StringToInteger(hm[0]), m = (int)StringToInteger(hm[1]);
   if(h < 0 || h > 24 || m < 0 || m > 59) return -1;
   return h*60 + m;
}
void WinParse()
{
   ArrayResize(g_WinFrom, 0); ArrayResize(g_WinTo, 0);
   string parts[];
   int n = StringSplit(TradeWindows, ',', parts);
   for(int i=0;i<n;i++)
   {
      string ab[];
      if(StringSplit(parts[i], '-', ab) != 2) continue;
      int a = HhmmToMin(ab[0]), b = HhmmToMin(ab[1]);
      if(a < 0 || b < 0){ Print("SAMUSIGNAL CANDLE EA: TradeWindows me galat samay: ", parts[i]); continue; }
      int k = ArraySize(g_WinFrom);
      ArrayResize(g_WinFrom, k+1); ArrayResize(g_WinTo, k+1);
      g_WinFrom[k] = a; g_WinTo[k] = b;
   }
}
bool InWin(int i, int m){ int a = g_WinFrom[i], b = g_WinTo[i]; return (a <= b ? (m >= a && m < b) : (m >= a || m < b)); }
bool InWindow()
{
   int n = ArraySize(g_WinFrom);
   if(n == 0) return true;
   int m = IstMin();
   for(int i=0;i<n;i++) if(InWin(i, m)) return true;
   return false;
}
string NextWindowTxt()
{
   int n = ArraySize(g_WinFrom);
   if(n == 0) return "";
   int m = IstMin(), best = 0, bd = 100000;
   for(int i=0;i<n;i++){ int d = (g_WinFrom[i] - m + 1440) % 1440; if(d < bd){ bd = d; best = i; } }
   return StringFormat("%02d:%02d", g_WinFrom[best]/60, g_WinFrom[best]%60);
}
string WindowEndTxt()
{
   int n = ArraySize(g_WinFrom), m = IstMin();
   for(int i=0;i<n;i++) if(InWin(i, m)) return StringFormat("%02d:%02d", (g_WinTo[i]/60)%24, g_WinTo[i]%60);
   return "";
}
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
string NewsIst(datetime srv)
{
   long ist = (long)srv - (long)(TimeTradeServer() - TimeGMT()) + 19800;
   return StringSubstr(TimeToString((datetime)ist, TIME_DATE|TIME_MINUTES), 11);
}
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
      why = g_NewsCur[i]+" "+g_NewsName[i]+" "+NewsIst(g_NewsT[i])+" IST"
            + (left>0 ? " ("+IntegerToString((int)(left/60))+" min me)" : " (abhi hui)");
      return true;
   }
   return false;
}
// BTCUSD: base BTC (koi news nahi) + USD -> USD news par rukta hai
bool NewsBlock(string sym, string &why)
{
   string b = SymbolInfoString(sym, SYMBOL_CURRENCY_BASE), p = SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT);
   if(b=="" || p==""){ string n = Name6(sym); b = StringSubstr(n,0,3); p = StringSubstr(n,3,3); }
   return NewsBlockCur(b, p, why);
}
bool NewsNowAny()
{
   for(int i=0;i<ArraySize(g_Syms);i++){ string w; if(g_Syms[i]!="" && NewsBlock(g_Syms[i], w)) return true; }
   return false;
}
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
string NewsTxt()
{
   if(!NewsOn) return "filter band (NewsOn=false)";
   string blk = "";
   for(int i=0;i<ArraySize(g_Syms);i++){ string w; if(g_Syms[i]!="" && NewsBlock(g_Syms[i], w)) blk += (blk=="" ? "" : ", ")+g_Names[i]; }
   if(blk != "") return "RUKE: "+blk+" (news "+IntegerToString(NewsBeforeMin)+" min pehle / "+IntegerToString(NewsAfterMin)+" min baad)";
   if(g_NxT == 0) return "agle 36 ghante koi High news nahi";
   long left = (long)(g_NxT - TimeTradeServer());
   return "agli: "+g_NxCur+" "+g_NxName+" "+NewsIst(g_NxT)+" IST ("+(left > 0 ? IntegerToString((int)(left/60))+" min me" : "abhi")+")";
}

//+------------------------------------------------------------------+
//| v1.01 DASHBOARD - "Matrix Terminal" (user ka sample): kaala      |
//| background, hare monospace akshar, upar alert patti (ulta rang,  |
//| blink), STATUS / PAIRS / TRADE / DAILY / SLOTS, BALANCE patti,   |
//| LOG, [ PAUSE ] [ CLOSE ALL ]. Poori chart par.                   |
//+------------------------------------------------------------------+
#define MX_BG    C'0,0,0'
#define MX_GRN   C'124,252,124'
#define MX_DIM   C'60,140,70'
#define MX_RED   C'255,99,99'
#define MX_AMB   C'255,190,70'
#define MX_FONT  "Consolas"
#define BT_PAUSE "SSC_LBT_PAUSE"
#define BT_CALL  "SSC_LBT_CALL"

string   g_Log[6];  int g_LogN = 0;
string   g_Alert = ""; datetime g_AlertT = 0;
datetime g_CallArm = 0;

string IstNow(){ return TimeToString(TimeGMT() + 19800, TIME_SECONDS); }
void AddLog(string m)
{
   for(int i=5;i>0;i--) g_Log[i] = g_Log[i-1];
   g_Log[0] = TimeToString(TimeGMT() + 19800, TIME_SECONDS) + "  " + m;
   if(g_LogN < 6) g_LogN++;
}
void SetAlert(string m){ g_Alert = m; g_AlertT = TimeLocal(); }
string PauseName(){ return "SSC_PAUSE_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)); }
bool IsPaused(){ return GlobalVariableCheck(PauseName()) && GlobalVariableGet(PauseName()) > 0.5; }
string Bar(double v, double mx, int n)
{
   int k = (mx > 0 ? (int)MathRound(MathMax(0.0, MathMin(1.0, v/mx)) * n) : 0);
   string s = "[";
   for(int i=0;i<n;i++) s += (i < k ? "#" : ".");
   return s + "]";
}
string Usd(double v){ return (v >= 0 ? "+" : "-") + DoubleToString(MathAbs(v), 2); }

void MxRect(string n, int x, int y, int w, int h, color bg, color edge)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_COLOR, edge);
   ObjectSetInteger(0, n, OBJPROP_BACK, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
}
void MxTxt(string n, string t, int x, int y, color c, ENUM_ANCHOR_POINT an = ANCHOR_LEFT_UPPER)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, an);
   ObjectSetString(0, n, OBJPROP_FONT, MX_FONT);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPx);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
}
void MxBtn(string n, string t, int x, int y, int w, int h, color fg, color bg)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetString(0, n, OBJPROP_FONT, MX_FONT);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPx);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_STATE, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
}
// ek line: baayein label (jaise STATUS), daayein "> value"
void Row(int &y, int rh, int x0, int xv, string id, string key, string val, color vc)
{
   MxTxt(LBL+"K"+id, key, x0, y, MX_GRN);
   MxTxt(LBL+"V"+id, (key == "" ? "" : "\x25B8 ") + val, xv, y, vc);
   y += rh;
}
void Sep(int &y, int rh, int x0, int w, string id)
{
   MxRect(LBL+"S"+id, x0, y + rh/3, w, 1, MX_DIM, MX_DIM);
   y += rh;
}
void Panel()
{
   if(!PanelOn) return;
   int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS), ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   uint tw0 = 0, th0 = 0;                                  // TextGetSize uint maangta hai (int = compile error)
   TextSetFont(MX_FONT, -FontPx*10);                      // asli pixel (screen DPI ke saath)
   TextGetSize("DRAWDOWN__", tw0, th0);
   int tw = (int)tw0, th = (int)th0;
   if(tw <= 0) tw = FontPx*10;
   if(th <= 0) th = FontPx*2;
   int rh = (int)MathMax(14.0, th*1.45), x0 = (int)MathMax(10.0, (double)th), xv = x0 + tw, lineW = (int)MathMax(100.0, (double)(cw - 2*x0));
   MxRect(LBL+"BG", 0, 0, cw, ch, MX_BG, MX_BG);          // poori chart kaali

   int y = (int)(rh*0.6);
   string pl = "";
   for(int i=0;i<ArraySize(g_Names);i++) pl += (i ? "," : "") + g_Names[i] + (g_Syms[i]=="" ? "?" : "");
   MxTxt(LBL+"H1", "root@candle-ea:~$ ./run --pairs "+(pl=="" ? "-" : pl)+" --tf M1", x0, y, MX_GRN);
   MxTxt(LBL+"H2", "["+IstNow()+" IST]", cw - x0, y, MX_GRN, ANCHOR_RIGHT_UPPER);
   y += rh;
   Sep(y, rh, x0, lineW, "1");

   // alert patti: naya trade / band (90 sec), ulta rang + blink
   bool on = (g_Alert != "" && TimeLocal() - g_AlertT < 90);
   bool blink = (on && ((long)TimeLocal() % 2) == 0);
   MxRect(LBL+"AL", x0, y - 2, lineW, rh, on ? (blink ? MX_GRN : MX_BG) : MX_BG, on ? MX_GRN : MX_DIM);
   MxTxt(LBL+"AT", on ? "!!! "+g_Alert+" !!!" : "--- agle signal ka intezaar ---", x0 + 8, y, on ? (blink ? MX_BG : MX_GRN) : MX_DIM);
   y += (int)(rh*1.4);

   string sw = StopWhy();
   if(sw == "" && IsPaused()) sw = "PAUSE (naya trade nahi)";
   int op = CountOpen();
   Row(y, rh, x0, xv, "1", "STATUS", (sw == "" ? "CHALU - " : "RUKA: "+sw+" - ")+IntegerToString(op)+" / "+IntegerToString(MaxOpen)+" trade khule", sw == "" ? MX_GRN : MX_AMB);
   Row(y, rh, x0, xv, "2", "PAIRS", (pl == "" ? "app me koi pair ON nahi" : pl)+"    M1    "+(g_Real ? "REAL" : "DEMO"), MX_GRN);
   Sep(y, rh, x0, lineW, "2");

   int shown = 0;
   for(int i=PositionsTotal()-1;i>=0 && shown < 4;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      long pmg = PositionGetInteger(POSITION_MAGIC);
      if(pmg != Magic && !(ManageManual && pmg == 0)) continue;     // v1.04: haath ka bhi
      string sym = PositionGetString(POSITION_SYMBOL);
      datetime openT = (datetime)PositionGetInteger(POSITION_TIME);
      datetime b0 = iTime(sym, PERIOD_M1, 0);
      int idx = (b0 > 0 ? (int)(((long)b0 - ((long)openT - (long)openT % 60))/60) + 1 : 0);
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double tpP = PositionGetDouble(POSITION_TP), opP = PositionGetDouble(POSITION_PRICE_OPEN);
      double kk = UsdPerPriceLot(sym) * PositionGetDouble(POSITION_VOLUME);
      string tpTxt = (kk > 0 && tpP > 0 ? "   TP "+DoubleToString(MathAbs(tpP - opP)*kk, 2) : "");
      Row(y, rh, x0, xv, "T"+IntegerToString(shown), shown == 0 ? "TRADE" : "",
          (pmg == 0 ? "[HAATH] " : "")+Name6(sym)+" "+(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "BUY " : "SELL")+"  lot "+DoubleToString(PositionGetDouble(POSITION_VOLUME),2)
          +"   P&L "+Usd(p)+"   candle "+IntegerToString(idx)+"/"+IntegerToString(HoldMax1)+tpTxt, p >= 0 ? MX_GRN : MX_RED);
      shown++;
   }
   if(shown == 0){ Row(y, rh, x0, xv, "T0", "TRADE", "koi trade khula nahi", MX_DIM); shown = 1; }
   for(int k=shown;k<4;k++){ ObjectDelete(0, LBL+"KT"+IntegerToString(k)); ObjectDelete(0, LBL+"VT"+IntegerToString(k)); }

   string tgt = (DayTargetUsd > 0 ? DoubleToString(DayTargetUsd,2) : "-");
   Row(y, rh, x0, xv, "3", "DAILY", Bar(g_DayPl, DayTargetUsd > 0 ? DayTargetUsd : 2.0, 20)+"  "+Usd(g_DayPl)+" / "+tgt+"   jeet "+IntegerToString(g_DayW)+"  haar "+IntegerToString(g_DayL), g_DayPl >= 0 ? MX_GRN : MX_RED);
   Row(y, rh, x0, xv, "4", "SLOTS", Bar(op, MaxOpen, 20)+"  EA "+IntegerToString(op)+" / "+IntegerToString(MaxOpen)+"   +   HAATH "+IntegerToString(CountManual())+" / "+IntegerToString(ManualSlots)+(ManageManual ? "" : " (sambhalna band)"), CountManual() > ManualSlots ? MX_AMB : MX_GRN);
   string ws = (TradeWindows == "" ? "hamesha" : TradeWindows);
   Row(y, rh, x0, xv, "6", "SAMAY", ws+" IST   "+(InWindow() ? "abhi ANDAR (band "+WindowEndTxt()+")" : "abhi BAHAR (agla "+NextWindowTxt()+")"), InWindow() ? MX_GRN : MX_AMB);
   Row(y, rh, x0, xv, "7", "NEWS", NewsTxt(), NewsNowAny() ? MX_AMB : MX_GRN);
   string bt = BlockedTxt();
   Row(y, rh, x0, xv, "8", "AAJ BAND", bt == "" ? "koi pair band nahi (seema -$"+DoubleToString(BlockPairLossUsd,2)+" floating)" : bt+"  (floating -$"+DoubleToString(BlockPairLossUsd,2)+" se neeche gaye the)", bt == "" ? MX_GRN : MX_AMB);
   Row(y, rh, x0, xv, "5", "RULES", "TP body "+DoubleToString(TpBodyPct,0)+"% ("+DoubleToString(TpMin_Usd,2)+"-"+DoubleToString(TpMax_Usd,2)+")   SL "+DoubleToString(SL_Usd,2)
        +"   BOOK +"+DoubleToString(Book_Usd,2)+"   TIME "+IntegerToString(HoldMax1)+" candle", MX_GRN);
   Sep(y, rh, x0, lineW, "3");

   bool algo = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED));
   MxTxt(LBL+"B1", "BALANCE "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+"    EQUITY "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)
         +"    FIREBASE "+(g_FbOk ? "ok" : "NAHI")+"    APP "+(g_CfgOk ? IntegerToString((int)(TimeLocal()-g_CfgAt))+"s" : "NAHI")+"    ALGO "+(algo ? "on" : "OFF"), x0, y, (g_FbOk && algo) ? MX_GRN : MX_AMB);
   y += rh;
   Sep(y, rh, x0, lineW, "4");

   for(int i=0;i<6;i++)
   {
      if(i < g_LogN) MxTxt(LBL+"LG"+IntegerToString(i), "LOG   "+g_Log[i], x0, y, i == 0 ? MX_GRN : MX_DIM);
      else ObjectDelete(0, LBL+"LG"+IntegerToString(i));
      y += rh;
   }
   if(g_LogN == 0) MxTxt(LBL+"LG0", "LOG   "+IstNow()+"  shuru - "+g_Status, x0, y - 6*rh, MX_DIM);

   int bh = (int)(rh*1.5), bw = (int)(tw*1.3), by = (int)MathMax((double)(y + rh/2), (double)(ch - bh - x0));
   bool armed = (g_CallArm > 0 && TimeLocal() - g_CallArm < 5);
   MxBtn(BT_PAUSE, IsPaused() ? "[ RESUME ]" : "[ PAUSE ]", x0, by, bw, bh, IsPaused() ? MX_AMB : MX_GRN, MX_BG);
   MxBtn(BT_CALL, armed ? "[ PAKKA? ]" : "[ CLOSE ALL ]", x0 + bw + x0, by, bw, bh, MX_RED, armed ? C'70,10,10' : MX_BG);
   ChartRedraw();
}
void CloseAll()
{
   int n = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      CloseIt(t, "CLOSE ALL (haath se)"); n++;
   }
   AddLog("CLOSE ALL - "+IntegerToString(n)+" trade band");
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == BT_PAUSE)
   {
      GlobalVariableSet(PauseName(), IsPaused() ? 0 : 1);
      AddLog(IsPaused() ? "PAUSE - naya trade nahi (chalu trade apne niyam se)" : "RESUME - phir se chalu");
      ObjectSetInteger(0, BT_PAUSE, OBJPROP_STATE, false);
      PublishState();
   }
   else if(sparam == BT_CALL)
   {
      if(g_CallArm > 0 && TimeLocal() - g_CallArm < 5){ g_CallArm = 0; CloseAll(); }
      else g_CallArm = TimeLocal();
      ObjectSetInteger(0, BT_CALL, OBJPROP_STATE, false);
   }
   Panel();
}
//+------------------------------------------------------------------+
