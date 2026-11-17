//+------------------------------------------------------------------+
//|                                  SAMUSIGNAL CANDLE EA v1.10.mq5  |
//|                                           Ankush New Vision      |
//+------------------------------------------------------------------+
//|  v1.10 (user Final, 17 Nov raat) "6 PERFECT TRADES":            |
//|   - Sirf 17 achhe forex pair (XAU / BTC nahi; kam chalne wale  |
//|     / bade spread wale NZD-CHF-GBP cross hataye).               |
//|   - Lot 0.02, TP fix $0.50 (0.01 par $0.25), SL $6 ($3).        |
//|   - Pakki jaanch: 15m + 1h trend dono saath, spread <= TP 50%, |
//|     news, score >= 70, har minute 1 naya trade.                 |
//|   - ORDER haalat dekh kar: MARKET (bhaav EMA ke paas) / LIMIT  |
//|     (bhaav khincha ya badi candle: body 40% peechhe) / STOP     |
//|     (pichhle 20 candle ka high/low thik saamne: 1 kadam paar). |
//|     LIMIT / STOP 5 min me na bhare = cancel.                    |
//|   - Ek saath 6 tak (seedhi hataayi); $3 net tak trade, phir din |
//|     band + TARGET LOCK; din ka loss $12 = din band.             |
//|   - +$0.30 par LOCK (SL +$0.10), trail nahi; chhota BOOK band; |
//|     trade -$2 tak gaya to wapas $0 par band; TIME 300 wahi.     |
//|  v1.09 (user Final, 17 Nov):                                     |
//|   (1) AUTO PICK - app ke pair ki jagah EA khud PickList ke ~15   |
//|       pair har minute jaanchta hai: candle band hote hi sab par  |
//|       signal, phir score (candle ki taakat + TP/spread + 5m/15m  |
//|       trend) se sabse achhe pair par trade. TP < 2x spread =     |
//|       bahar. Ek currency ek disha me ek hi baar. AutoPick=false  |
//|       = purana tarika (app ke ON pair).                          |
//|   (2) SEEDHI SLOT - din ka band profit $0-1: 8 trade, $1-2: 6,  |
//|       $2-3: 4 (SlotSteps "8,6,4", StepUsd 1). Slot ghatne par    |
//|       chalu trade band NAHI, sirf naye ruk-te hain.              |
//|   (3) Din ka target $2 -> $3 + TARGET LOCK: target pura = din    |
//|       band; chalu trade: net + P/L >= target ho to turant band,  |
//|       kam ho to kul wapas target par aate hi band.               |
//|   (4) Kam se kam profit $0.05 -> $0.10: dusri candle se +$0.10   |
//|       BOOK, candle band par bhi fayda >= $0.10 ho tabhi BOOK.    |
//|   (5) TIME 200 -> 300 candle.                                    |
//|   (6) FloatStopUsd (0 = band): kul floating itna minus = naye    |
//|       trade ruk-te hain (sujhaav, user ne abhi chalu nahi kaha). |
//|  (17 Nov: VPS disk bhari thi - dobara bheja; "Label" fix)       |
//|  v1.08 (user Final): LOCK + TRAIL - fayda +$0.15 (LockAtUsd)     |
//|         hote hi SL +$0.10 (LockToUsd) par pakka, phir SL bhaav ke |
//|         peechhe $0.05 (TrailGapUsd) chalta hai. Fixed TP ki jagah  |
//|         door ka TP = body ka 100% ($0.15-$1.00). Lock ke baad      |
//|         +$0.05 / candle-close BOOK band; 200 candle TIME wahi.     |
//|         Lock se pehle sab pehle jaisa. Haath ke trade par bhi.     |
//|         TRADE SAMAY hataya (TradeWindows khaali = 24 ghante);    |
//|         sirf High news +-30 min ki rok rehti hai.                 |
//|  v1.07 (user): TP kam se kam $0.10 -> $0.15 (TpMin_Usd, 0.01 lot |
//|         par; EA + haath ka trade). Baaki sab v1.06 jaisa.         |
//|  v1.06 (user): 200 candle TIME WAPAS (HoldMax1 200, pehle jaisa). |
//|         TP thoda bada: candle body ka 50% -> 60% (TpBodyPct,      |
//|         ManualTpBodyPct). $0.10 kam se kam / $1.00 zyada wahi.    |
//|  v1.05 (user): 200 CANDLE wala TIME band HATAYA - trade sirf TP,  |
//|         BOOK (+$0.05 / candle close fayde me) ya SL $10 par band.  |
//|         HoldMax1 = 0 (0 = kabhi TIME nahi). Din ka target $2 wahi. |
//|         FIX: badle ka pair sirf tab jab band pair app me ON tha   |
//|         (16 Nov: OFF GBPUSD ke badle NZDCHF ON ho gaya tha).       |
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
#property version   "1.10"
#property description "SAMUSIGNAL CANDLE EA - Candle signal, 17 forex pair me se pakka trade, MARKET / LIMIT / STOP, TP $0.50 / SL $6 (0.02), din $3"

#include <Trade\Trade.mqh>
CTrade trade;

#define VER "1.10"
#define LBL "SSC_L"

input group "========== FIREBASE =========="
input string FirebaseURL      = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // FirebaseURL (mat badlo)
input string FirebaseAuth     = "";        // FirebaseAuth (AI AUTO / News Pusher wala hi)

input group "========== TRADE =========="
input double Lot              = 0.02;      // v1.10: Lot (pehle 0.01)
input int    MaxOpen          = 6;         // v1.10: Ek saath zyada se zyada kitne trade (pending bhi gine)
input double SL_Usd           = 3.0;       // v1.10: SL $ (0.01 lot par; 0.02 = $6; pehle 10)
input double TpBodyPct        = 60;        // v1.06: TP = signal candle body ka itna % (pehle 50)
input double TpMin_Usd        = 0.15;      // v1.07: TP kam se kam $ (0.01 lot par; pehle 0.10)
input double TpMax_Usd        = 1.00;      // TP zyada se zyada $ (0.01 lot par)
input double Book_Usd         = 0.10;      // v1.09: Dusri candle se itna profit dikhte hi BOOK $ (pehle 0.05)
input double BookCloseUsd     = 0.10;      // v1.09: Candle band par fayda kam se kam itna ho tabhi BOOK (pehle $0.004)
input int    HoldMax1         = 300;       // v1.09: kitni candle baad TIME band (0 = kabhi nahi; pehle 200)
input double MaxSpreadUsd     = 0.50;      // Spread max $ (0.01 lot par), 0 = jaanch nahi
input string ExcludeCSV       = "";        // In pair par trade nahi (jaise XAUUSD), khaali = sirf app
input string SymbolSuffix     = "";        // Symbol suffix (khaali = apne aap)
input long   Magic            = 7320001;   // Magic number
input bool   AllowReal        = false;     // REAL account par trade? (false = sirf DEMO)

input group "========== AUTO PICK (v1.09) =========="
input bool   AutoPick         = true;      // EA khud pair chune (false = app ke ON pair)
input string PickList         = "EURUSD,GBPUSD,USDJPY,USDCHF,USDCAD,AUDUSD,NZDUSD,EURJPY,GBPJPY,AUDJPY,CADJPY,CHFJPY,NZDJPY,EURAUD,EURCAD,EURCHF,AUDCAD"; // v1.10: 17 forex (XAU / BTC nahi)
input double PickMinScore     = 70;        // v1.10: Score (0-100) kam se kam itna (pehle 40)
input bool   PickOneCurDir    = true;      // Ek currency ek disha me ek hi trade (USD BUY do baar nahi)

input group "========== PERFECT ENTRY (v1.10) =========="
input double TpFixedUsd       = 0.25;      // TP fix $ (0.01 lot par; 0.02 = $0.50). 0 = candle body se
input bool   PickNeedHtf      = true;      // 15m + 1h trend dono saath zaroori
input double PickSpreadPct    = 50;        // Spread <= TP ka itna %
input int    PickPerMin       = 1;         // Har minute zyada se zyada naye trade
input double LimitStretchAtr  = 1.0;       // Bhaav EMA21 se itne ATR door = LIMIT
input double LimitBigBody     = 2.0;       // Candle body average ka itna guna = LIMIT
input double LimitPullPct     = 40;        // LIMIT: signal candle body ka itna % peechhe
input double StopNearAtr      = 0.3;       // Pichhle 20 candle ka high/low itne ATR paas = STOP
input int    PendMin          = 5;         // LIMIT / STOP itne min me na bhare = cancel
input bool   BookOn           = false;     // Purane chhote BOOK niyam (candle close / +$0.10)
input bool   TrailAfterLock   = false;     // Lock ke baad SL bhaav ke peechhe chale?
input double RecoverDipUsd    = 1.0;       // Trade itna minus (0.01 lot; 0.02 = $2) gaya to wapas $0 par band (0 = band)

input group "========== SEEDHI SLOT + TARGET LOCK (v1.09) =========="
input string SlotSteps        = "";        // v1.10: khaali = MaxOpen (6). Pehle "8,6,4"
input double StepUsd          = 1.0;       // Har seedhi kitne $ ki
input bool   TargetLock       = true;      // Target pura -> chalu trade band (net + P/L >= target par)
input double FloatStopUsd     = 0;         // Kul floating itna minus = naya trade nahi (0 = band)

input group "========== SIGNAL (app jaisa - mat badlo) =========="
input double BodyMult         = 1.2;       // body >= pichhli 10 ki average x
input double BodyPctRange     = 50;        // body >= candle range ka %
input int    EmaFast          = 9;         // EMA tez
input int    EmaSlow          = 21;        // EMA dheemi
input int    RsiLen           = 14;        // RSI
input int    CalcBars         = 250;       // Hisaab kitni band candle par (app / VPS feed = 250)

input group "========== TRADE SAMAY - IST (v1.02) =========="
input string TradeWindows     = "";        // v1.08 (user): khaali = hamesha (demo par poora check); pehle "07:00-17:00,20:00-22:00"

input group "========== NEWS (v1.02) =========="
input bool   NewsOn           = true;      // News filter chalu
input int    NewsBeforeMin    = 30;        // High news se kitne min pehle naya trade nahi
input int    NewsAfterMin     = 30;        // High news ke kitne min baad tak naya trade nahi
input bool   NewsWithMedium   = false;     // Medium news bhi
input bool   NewsCloseOpen    = false;     // News ke us beech chalu trade bhi band kar do?

input group "========== LOCK + TRAIL (v1.08) =========="
input bool   TrailOn          = true;      // Fayda LockAt par -> SL LockTo par pakka, phir trail
input double LockAtUsd        = 0.15;      // Itna fayda (0.01 lot par) hote hi lock
input double LockToUsd        = 0.05;      // v1.10: Lock: SL itne fayde par (0.01 lot; 0.02 = $0.10)
input double TrailGapUsd      = 0.05;      // Lock ke baad SL bhaav se itna peechhe chalega
input double TrailTpBodyPct   = 100;       // Trail chalu ho to door ka TP = body ka itna % (TpMin-TpMax ke andar)

input group "========== HAATH KA TRADE (v1.04) =========="
input bool   ManageManual     = true;      // Haath se liya trade (magic 0) bhi isi niyam se sambhalo
input int    ManualSlots      = 1;         // Manual ka alag slot (EA ke MaxOpen me nahi gina)
input double ManualTpBodyPct  = 60;        // v1.06: Manual TP = pichhli band candle ki body ka itna % (pehle 50)

input group "========== PAIR DIN BHAR BAND (v1.03) =========="
input double BlockPairLossUsd = 2.0;       // Trade floating me itna $ ghate me gaya = us din wo pair band (0 = band)
input bool   AutoReplace      = true;      // Pair band hone par app me badle ka pair apne aap ON (sirf us din) + push
input string ReserveOrder     = "EURCHF,GBPCHF,NZDCHF,EURNZD,GBPNZD,NZDCAD,AUDNZD,AUDCHF,CADCHF,NZDJPY,CHFJPY,EURJPY,GBPJPY,EURCAD,GBPCAD,AUDCAD,CADJPY,EURAUD,GBPAUD,NZDUSD,USDCHF,EURUSD,GBPUSD,USDJPY,AUDUSD"; // Badle ke pair (pehle wala pehle)

input group "========== DIN KI SEEMA (0 = band) =========="
input double DayTargetUsd     = 3.0;       // v1.09: din ka profit $ itna = us din band (pehle 2; 0 = band)
input double DayLossUsd       = 12;        // v1.10: Din ka ghata $ itna = us din naya trade nahi (2 SL)

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
// v1.09 AUTO PICK + target lock
string   g_PkNames[], g_PkSyms[];
datetime g_PkDone = 0;      // aakhri jaanchi minute (band candle ka samay)
string   g_PickTxt = "-";
int      g_TgtDay = -1;     double g_TgtNet = 0;   string g_LockTxt = "";
string   g_PdKey[], g_PdJs[];   // v1.10: LIMIT / STOP bharne par Firebase record
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
   Print("SAMUSIGNAL CANDLE EA v", VER, " shuru | lot ", DoubleToString(Lot,2), " | AUTO PICK ", (AutoPick ? "ON" : "off"), " | seedhi ", SlotSteps, " | target $", DoubleToString(DayTargetUsd,2), " | SL $", DoubleToString(SL_Usd,2),
         " | TP body ", DoubleToString(TpBodyPct,0), "% ($", DoubleToString(TpMin_Usd,2), "-", DoubleToString(TpMax_Usd,2), ") | book $", DoubleToString(Book_Usd,2));
   LoadCfg();
   PickLoad();
   DayStats();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ EventKillTimer(); ObjectsDeleteAll(0, LBL); Comment(""); }
void OnTick(){}

void OnTimer()
{
   static datetime lastCfg = 0, lastState = 0, lastDay = 0, lastPanel = 0;
   datetime now = TimeLocal();
   if(now - lastCfg >= (CfgPollSec < 5 ? 5 : CfgPollSec)){ lastCfg = now; LoadCfg(); PickLoad(); }
   if(now - lastDay >= 10){ lastDay = now; DayStats(); }
   Manage();          // chalu trade: book / TIME (har 250 ms)
   DoTargetLock();    // v1.09
   { static datetime lastPd = 0; if(now != lastPd){ lastPd = now; CheckPend(); } }   // v1.10
   if(AutoPick) PickScan(); else ScanPairs();   // v1.09: AUTO PICK ya app ke pair
   if(now - lastState >= 30){ lastState = now; PublishState(); }
   NextNewsLoad();
   { static datetime lastExp = 0; if(AutoReplace && !AutoPick && now - lastExp >= 60){ lastExp = now; AutoExpire(); } }   // v1.03 (AUTO PICK me nahi)
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
double g_SigStr = 0;   // v1.09: body / avg10 (aakhri Signal ka)
int Signal(string sym, ENUM_TIMEFRAMES per, double &body, string &why)
{
   body = 0; why = ""; g_SigStr = 0;
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
   g_SigStr = body/avg;
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
      Open(g_Names[i], g_CfgPairs[i], sym, dir, body, key, why);
   }
}
void SkipMsg(string nm, string dir, string msg)
{
   g_LastSkip = nm+" "+dir+": "+msg;
   AddLog("SKIP "+g_LastSkip);
   Print("SAMUSIGNAL CANDLE EA: SKIP ", g_LastSkip);
}
void Open(string nm, string appPair, string sym, int dir, double body, string key, string why, int ot = 0, double opx = 0)   // ot: 0 MARKET, 1 LIMIT, 2 STOP
{
   string ds = (dir > 0 ? "BUY" : "SELL");
   if(g_Real && !AllowReal){ SkipMsg(nm, ds, "REAL account - AllowReal=false"); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)){ SkipMsg(nm, ds, "MT5 me Algo Trading band"); return; }
   if(TgtHit() || (DayTargetUsd > 0 && g_DayPl >= DayTargetUsd)){ SkipMsg(nm, ds, "aaj ka target poora ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(FloatStopUsd > 0 && FloatPl() <= -FloatStopUsd){ SkipMsg(nm, ds, "kul floating $"+DoubleToString(FloatPl(),2)+" (seema -$"+DoubleToString(FloatStopUsd,2)+")"); return; }   // v1.09
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd){ SkipMsg(nm, ds, "aaj ki ghata seema ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(IsPaused()){ SkipMsg(nm, ds, "PAUSE (panel se)"); return; }
   if(!InWindow()){ SkipMsg(nm, ds, "trading samay ke bahar (agla "+NextWindowTxt()+" IST)"); return; }
   { string nw; if(NewsBlock(sym, nw)){ SkipMsg(nm, ds, "news: "+nw); return; } }
   if(PairBlocked(sym)){ SkipMsg(nm, ds, "aaj band - is pair ka trade -$"+DoubleToString(BlockPairLossUsd,2)+" se neeche gaya tha"); return; }   // v1.03
   if(HasOpen(sym)){ SkipMsg(nm, ds, "1 pair 1 trade - pehle wala chalu"); return; }
   int op = CountOpen() + CountPend(), mx = CurMax();                // v1.09 / v1.10: pending bhi gine
   if(op >= mx){ SkipMsg(nm, ds, "pehle se "+IntegerToString(op)+" / "+IntegerToString(mx)+" trade chalu"); return; }

   double k = UsdPerPriceLot(sym) * Lot;                 // is lot par 1 price-unit = $k
   if(k <= 0){ SkipMsg(nm, ds, "tick value nahi mila"); return; }
   double sc = Lot/0.01;
   double tpPct = (TrailOn ? TrailTpBodyPct : TpBodyPct);           // v1.08: trail me door ka TP
   double tp01 = (TpFixedUsd > 0 ? TpFixedUsd : MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * (k/sc) * tpPct/100.0)));   // v1.10
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
   bool pend = false; string otTx = "MARKET";                        // v1.10: LIMIT / STOP
   if(ot != 0)
   {
      opx = NormalizeDouble(opx, dg);
      bool okPx = (ot == 1 ? (dir > 0 ? opx < ask - minD - pt : opx > bid + minD + pt)
                           : (dir > 0 ? opx > ask + minD + pt : opx < bid - minD - pt));
      if(okPx){ pend = true; otTx = (ot == 1 ? "LIMIT" : "STOP"); }
      else otTx = "MARKET";                                          // bhaav pehle hi wahan pahunch gaya
   }
   double px = (pend ? opx : (dir > 0 ? ask : bid));
   double tp = NormalizeDouble(dir > 0 ? px + tpUse : px - tpUse, dg);
   double sl = NormalizeDouble(dir > 0 ? px - slUse : px + slUse, dg);
   long nextMs = 0;
   { long b0 = (long)iTime(sym, Per(g_Tf), 0); nextMs = (b0 - g_Off)*1000; }
   string jsMid = ",\"sym\":\""+JsonSafe(appPair)+"\",\"why\":\""+JsonSafe(why)+"\",\"n\":\""+nm+"\",\"dir\":\""+ds+"\",\"tf\":"+IntegerToString(g_Tf)
      +",\"next\":"+IntegerToString(nextMs)+",\"tp\":"+DoubleToString(tpUsd,2)+",\"sl\":"+DoubleToString(slUsd,2)+",\"spread\":"+DoubleToString(sprUsd,2)
      +",\"lot\":"+DoubleToString(Lot,2)+",\"ord\":\""+otTx+"\"";
   trade.SetTypeFillingBySymbol(sym);
   bool ok;
   if(pend)
   {
      if(ot == 1) ok = (dir > 0 ? trade.BuyLimit(Lot, px, sym, sl, tp, ORDER_TIME_GTC, 0, key) : trade.SellLimit(Lot, px, sym, sl, tp, ORDER_TIME_GTC, 0, key));
      else        ok = (dir > 0 ? trade.BuyStop(Lot, px, sym, sl, tp, ORDER_TIME_GTC, 0, key)  : trade.SellStop(Lot, px, sym, sl, tp, ORDER_TIME_GTC, 0, key));
   }
   else ok = (dir > 0 ? trade.Buy(Lot, sym, 0, sl, tp, key) : trade.Sell(Lot, sym, 0, sl, tp, key));
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
   {
      string m = "order nahi laga: "+IntegerToString((int)trade.ResultRetcode())+" "+trade.ResultRetcodeDescription();
      SkipMsg(nm, ds, m);
      if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" - "+m);
      return;
   }
   if(pend)                                                          // v1.10: bharne par record (OnTradeTransaction)
   {
      PdAdd(key, jsMid);
      g_Last = nm+" "+ds+" "+otTx+" @ "+DoubleToString(px, dg)+" | TP $"+DoubleToString(tpUsd,2)+" | "+IntegerToString(PendMin)+" min";
      Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", why);
      AddLog(g_Last); SetAlert(g_Last);
      if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" "+otTx+" lagaya | TP $"+DoubleToString(tpUsd,2)+" SL $"+DoubleToString(slUsd,2)+" | "+why);
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
   g_Last = nm+" "+ds+" MARKET khula @ "+DoubleToString(fill, dg)+" | TP $"+DoubleToString(tpUsd,2);
   Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", why);
   AddLog(g_Last); SetAlert(g_Last+"  ("+IntegerToString(n)+"/"+IntegerToString(CurMax())+")");
   if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" khula | TP $"+DoubleToString(tpUsd,2)+" | "+IntegerToString(n)+"/"+IntegerToString(CurMax())+" chalu"+(AutoPick ? " | "+why : ""));
   string js = "{\"id\":\""+key+"\""+jsMid+",\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"entry\":"+DoubleToString(fill, dg)+",\"done\":false}";
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
      GlobalVariableDel("SSC_DIP_" + IntegerToString((long)g_MgId[i]));   // v1.10
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
      if(RecoverDipUsd > 0)                                              // v1.10: gehra gaya -> wapas $0 par band
      {
         string gv = "SSC_DIP_" + IntegerToString((long)t);
         if(pl <= -RecoverDipUsd*sc && !GlobalVariableCheck(gv))
         {
            GlobalVariableSet(gv, 1);
            AddLog(Name6(sym)+" "+DoubleToString(pl,2)+"$ tak gaya - ab wapas $0 par band karenge");
         }
         if(GlobalVariableCheck(gv) && pl >= 0){ CloseIt(t, "WAPSI $0"); continue; }
      }
      int m = MgIdx(t);
      bool newBar = (g_MgBar[m] != 0 && b0 > g_MgBar[m]);
      if(g_MgBar[m] == 0) g_MgBar[m] = (idx > 0 ? b0 : entryBar);
      bool locked = (TrailOn && LockTrail(t, sym, pl, sc));           // v1.08: lock + trail
      if(locked)
      {
         if(newBar){ g_MgBar[m] = b0; if(HoldMax1 > 0 && idx >= HoldMax1){ CloseIt(t, "TIME"); continue; } }
         continue;                                                     // lock ke baad book niyam band
      }
      if(newBar)
      {
         g_MgBar[m] = b0;
         int holdMax = HoldMax1;
         if(BookOn && pl >= BookCloseUsd*sc){ CloseIt(t, "PROFIT BOOK"); continue; }   // v1.09: candle band, fayda >= $0.10 (v1.10: BookOn)
         if(holdMax > 0 && idx >= holdMax){ CloseIt(t, "TIME"); continue; }   // v1.05: 0 = TIME nahi
      }
      if(BookOn && idx >= 1 && pl >= Book_Usd*sc){ CloseIt(t, "PROFIT BOOK"); continue; }   // dusri candle se +$0.10 (v1.09; v1.10: BookOn)
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
// v1.08: true = is trade par lock laga hai (SL fayde ki taraf). Lock na ho aur fayda LockAt tak = lock lagao. Lock ho = trail.
bool LockTrail(ulong t, string sym, double pl, double sc)
{
   if(!PositionSelectByTicket(t)) return false;
   bool buy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   double op = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL), tp = PositionGetDouble(POSITION_TP);
   double k = UsdPerPriceLot(sym) * PositionGetDouble(POSITION_VOLUME);
   if(k <= 0) return false;
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   double lockD = LockToUsd*sc/k, gapD = TrailGapUsd*sc/k;
   double lockPx = (buy ? op + lockD : op - lockD);
   bool isLocked = (sl > 0 && (buy ? sl >= lockPx - pt : sl <= lockPx + pt));
   double bid = SymbolInfoDouble(sym, SYMBOL_BID), ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   if(!isLocked)
   {
      if(pl < LockAtUsd*sc) return false;
      double nsl = NormalizeDouble(lockPx, dg);
      if(buy ? (bid - nsl < minD) : (nsl - ask < minD)) return false;   // broker ki doori
      if(trade.PositionModify(t, nsl, tp))
      {
         string m = Name6(sym)+" LOCK: SL +$"+DoubleToString(LockToUsd*sc,2)+" pakka (fayda "+DoubleToString(pl,2)+"$)"+(TrailAfterLock ? ", ab trail" : ", TP ka intezaar");
         AddLog(m); Print("SAMUSIGNAL CANDLE EA: ", m);
         return true;
      }
      return false;
   }
   if(!TrailAfterLock) return true;                                   // v1.10: lock ke baad trail nahi, TP ka intezaar
   double want = NormalizeDouble(buy ? bid - gapD : ask + gapD, dg);  // bhaav se gap peechhe
   double stepMin = MathMax(pt, 0.01*sc/k);                           // kam se kam $0.01 sudhar par hi badlo
   if(buy ? (want > sl + stepMin && bid - want >= minD) : (want < sl - stepMin && want - ask >= minD))
      trade.PositionModify(t, want, tp);
   return true;
}
// ================= v1.09: SEEDHI SLOT / TARGET LOCK / AUTO PICK =================
int CurMax()
{
   if(SlotSteps == "") return MaxOpen;
   string p[]; int n = StringSplit(SlotSteps, ',', p);
   if(n <= 0) return MaxOpen;
   int st = (StepUsd > 0 && g_DayPl > 0 ? (int)MathFloor(g_DayPl / StepUsd + 1e-9) : 0);
   if(st >= n) st = n - 1;
   int v = (int)StringToInteger(p[st]);
   return (v > 0 ? v : MaxOpen);
}
double FloatPl()
{
   double f = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      f += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return f;
}
int  TodayN(){ return (int)((long)TimeTradeServer()/86400); }
bool TgtHit()
{
   if(DayTargetUsd <= 0) return false;
   int dn = TodayN();
   if(g_TgtDay != dn && g_DayPl >= DayTargetUsd)
   {
      g_TgtDay = dn; g_TgtNet = g_DayPl;
      string m = "aaj ka target poora $"+DoubleToString(g_DayPl,2)+" - din band (naya trade nahi)";
      Print("SAMUSIGNAL CANDLE EA: ", m); AddLog(m); SetAlert("TARGET POORA $"+DoubleToString(g_DayPl,2));
      if(PushOn) SendNotification("CANDLE EA: "+m);
   }
   return (g_TgtDay == dn);
}
void DoTargetLock()
{
   if(!TgtHit()){ g_LockTxt = ""; return; }
   if(!TargetLock) return;
   static int waitDay = -1;
   int n = 0; double fl = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      fl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP); n++;
   }
   if(n == 0){ if(StringFind(g_LockTxt, "intezaar") >= 0) g_LockTxt = ""; return; }
   if(g_DayPl + fl < DayTargetUsd)
   {
      g_LockTxt = "LOCK intezaar: "+IntegerToString(n)+" trade, kul $"+DoubleToString(g_DayPl+fl,2);
      if(waitDay != TodayN())
      {
         waitDay = TodayN();
         string m = "TARGET LOCK - "+IntegerToString(n)+" chalu trade P/L $"+DoubleToString(fl,2)+" (kul $"+DoubleToString(g_DayPl+fl,2)+"). Kul $"+DoubleToString(DayTargetUsd,2)+" par aate hi band, warna apna TP / SL";
         Print("SAMUSIGNAL CANDLE EA: ", m); AddLog(m); if(PushOn) SendNotification("CANDLE EA: "+m);
      }
      return;
   }
   DayStats();                                         // taaza band net se dobara
   if(g_DayPl + FloatPl() < DayTargetUsd) return;
   double before = g_DayPl + FloatPl(); int c = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      CloseIt(t, "TARGET LOCK"); c++;
   }
   g_LockTxt = "LOCK: "+IntegerToString(c)+" trade band";
   string m = "TARGET LOCK - "+IntegerToString(c)+" trade band | aaj net ~$"+DoubleToString(before,2)+" - din band";
   Print("SAMUSIGNAL CANDLE EA: ", m); AddLog(m); SetAlert(m);
   if(PushOn) SendNotification("CANDLE EA: "+m);
}
void PickLoad()
{
   string p[]; int n = StringSplit(PickList, ',', p);
   if(n < 0) n = 0;
   string oN[], oS[]; int on = ArraySize(g_PkNames);
   ArrayResize(oN, on); ArrayResize(oS, on);
   for(int i=0;i<on;i++){ oN[i] = g_PkNames[i]; oS[i] = g_PkSyms[i]; }
   ArrayResize(g_PkNames, 0); ArrayResize(g_PkSyms, 0);
   int c = 0;
   for(int i=0;i<n;i++)
   {
      string nm = p[i]; StringTrimLeft(nm); StringTrimRight(nm); StringReplace(nm, "/", ""); StringToUpper(nm);
      if(nm == "" || IsExcluded(nm)) continue;
      string sy = "";
      for(int j=0;j<on;j++) if(oN[j] == nm) sy = oS[j];
      if(sy == "") sy = Resolve(nm);                                 // nahi mila to har 20 sec phir
      ArrayResize(g_PkNames, c+1); ArrayResize(g_PkSyms, c+1);
      g_PkNames[c] = nm; g_PkSyms[c] = sy; c++;
   }
}
// bada trend: per par EMA9 vs EMA21 -> 1 upar, -1 neeche, 0 pata nahi
int HtfDir(string sym, ENUM_TIMEFRAMES per)
{
   double c[]; ArraySetAsSeries(c, false);
   int got = CopyClose(sym, per, 1, 120, c);
   if(got < EmaSlow + 5) return 0;
   double a = EmaLast(c, got, EmaFast), b = EmaLast(c, got, EmaSlow);
   if(a == EMPTY_VALUE || b == EMPTY_VALUE) return 0;
   return (a > b ? 1 : (a < b ? -1 : 0));
}
// currency +1 / -1 / 0 (pair ki disha se): BUY EURUSD = EUR +1, USD -1
int CurSign(string n6, int dir, string cur)
{
   if(StringSubstr(n6, 0, 3) == cur) return dir;
   if(StringSubstr(n6, 3, 3) == cur) return -dir;
   return 0;
}
// chalu (EA + haath) trade ki currency-disha, jaise ",EUR+,USD-,"
string Exposure()
{
   string e = ",";
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      if(mg != Magic && !(ManageManual && mg == 0)) continue;
      string n6 = Name6(PositionGetString(POSITION_SYMBOL));
      int dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 1 : -1);
      e += StringSubstr(n6, 0, 3) + (dir > 0 ? "+" : "-") + "," + StringSubstr(n6, 3, 3) + (dir > 0 ? "-" : "+") + ",";
   }
   for(int i=OrdersTotal()-1;i>=0;i--)                                 // v1.10: pending bhi
   {
      ulong o = OrderGetTicket(i);
      if(o==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string n6 = Name6(OrderGetString(ORDER_SYMBOL));
      long ty = OrderGetInteger(ORDER_TYPE);
      int dir = ((ty == ORDER_TYPE_BUY_LIMIT || ty == ORDER_TYPE_BUY_STOP) ? 1 : -1);
      e += StringSubstr(n6, 0, 3) + (dir > 0 ? "+" : "-") + "," + StringSubstr(n6, 3, 3) + (dir > 0 ? "-" : "+") + ",";
   }
   return e;
}
bool ExpClash(string exp, string n6, int dir)
{
   string a = StringSubstr(n6, 0, 3) + (dir > 0 ? "+" : "-"), b = StringSubstr(n6, 3, 3) + (dir > 0 ? "-" : "+");
   return (StringFind(exp, ","+a+",") >= 0 || StringFind(exp, ","+b+",") >= 0);
}
// ---- v1.10: pending (LIMIT / STOP) ----
int CountPend()
{
   int n = 0;
   for(int i=OrdersTotal()-1;i>=0;i--){ ulong o = OrderGetTicket(i); if(o!=0 && OrderGetInteger(ORDER_MAGIC)==Magic) n++; }
   return n;
}
bool HasPend(string sym)
{
   for(int i=OrdersTotal()-1;i>=0;i--){ ulong o = OrderGetTicket(i); if(o!=0 && OrderGetInteger(ORDER_MAGIC)==Magic && OrderGetString(ORDER_SYMBOL)==sym) return true; }
   return false;
}
void PdAdd(string key, string js)
{
   int n = ArraySize(g_PdKey);
   if(n >= 40){ for(int i=1;i<n;i++){ g_PdKey[i-1] = g_PdKey[i]; g_PdJs[i-1] = g_PdJs[i]; } n--; }
   ArrayResize(g_PdKey, n+1); ArrayResize(g_PdJs, n+1);
   g_PdKey[n] = key; g_PdJs[n] = js;
}
void PdFilled(ulong deal)
{
   ulong pid = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   string key = HistoryDealGetString(deal, DEAL_COMMENT);
   if(PositionSelectByTicket(pid)) key = PositionGetString(POSITION_COMMENT);
   for(int i=0;i<ArraySize(g_PdKey);i++)
   {
      if(g_PdKey[i] != key) continue;
      string sym = HistoryDealGetString(deal, DEAL_SYMBOL);
      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double px = HistoryDealGetDouble(deal, DEAL_PRICE);
      long t = (long)HistoryDealGetInteger(deal, DEAL_TIME);
      string js = "{\"id\":\""+key+"\""+g_PdJs[i]+",\"at\":"+IntegerToString((t - g_Off)*1000)+",\"entry\":"+DoubleToString(px, dg)+",\"done\":false}";
      string resp; int code;
      Http("POST", FbUrl("ea/trades/"+key), js, "X-HTTP-Method-Override: PUT\r\n", resp, code);
      g_Last = Name6(sym)+" "+(HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_BUY ? "BUY" : "SELL")+" pending BHARA @ "+DoubleToString(px, dg);
      AddLog(g_Last); SetAlert(g_Last+"  ("+IntegerToString(CountOpen())+"/"+IntegerToString(CurMax())+")");
      if(PushOn) SendNotification("CANDLE EA: "+g_Last+" | "+IntegerToString(CountOpen())+" chalu");
      int n = ArraySize(g_PdKey);
      for(int j=i+1;j<n;j++){ g_PdKey[j-1] = g_PdKey[j]; g_PdJs[j-1] = g_PdJs[j]; }
      ArrayResize(g_PdKey, n-1); ArrayResize(g_PdJs, n-1);
      return;
   }
}
void DeletePend(string why)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong o = OrderGetTicket(i);
      if(o==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(trade.OrderDelete(o)){ string m = Name6(sym)+" pending hataya - "+why; AddLog(m); Print("SAMUSIGNAL CANDLE EA: ", m); }
   }
}
void CheckPend()
{
   if(CountPend() == 0) return;
   if(TgtHit()){ DeletePend("aaj ka target poora"); return; }
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd){ DeletePend("din ki ghata seema"); return; }
   if(IsPaused()){ DeletePend("PAUSE"); return; }
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong o = OrderGetTicket(i);
      if(o==0 || OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string sym = OrderGetString(ORDER_SYMBOL), nw;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      string why = "";
      if(PendMin > 0 && TimeTradeServer() - setup >= PendMin*60) why = IntegerToString(PendMin)+" min me nahi bhara";
      else if(NewsBlock(sym, nw)) why = "news: "+nw;
      if(why == "") continue;
      if(trade.OrderDelete(o)){ string m = Name6(sym)+" pending hataya - "+why; AddLog(m); Print("SAMUSIGNAL CANDLE EA: ", m); }
   }
}
// signal candle ka haal: close, EMA21, ATR14, pichhle 20 (signal candle se pehle) ka high / low, body, avg10
bool SigCtx(string sym, double &C, double &e21, double &atr, double &hi20, double &lo20, double &bo, double &avg)
{
   MqlRates r[]; ArraySetAsSeries(r, false);
   int got = CopyRates(sym, PERIOD_M1, 1, 80, r);
   if(got < 40) return false;
   double c[]; ArrayResize(c, got);
   for(int i=0;i<got;i++) c[i] = r[i].close;
   e21 = EmaLast(c, got, EmaSlow);
   if(e21 == EMPTY_VALUE) return false;
   MqlRates L = r[got-1];
   C = L.close; bo = MathAbs(L.close - L.open);
   avg = 0; for(int i=got-11;i<=got-2;i++) avg += MathAbs(r[i].close - r[i].open); avg /= 10.0;
   atr = 0;
   for(int i=got-14;i<got;i++){ double tr = MathMax(r[i].high, r[i-1].close) - MathMin(r[i].low, r[i-1].close); atr += tr; }
   atr /= 14.0;
   hi20 = r[got-21].high; lo20 = r[got-21].low;
   for(int i=got-21;i<=got-2;i++){ hi20 = MathMax(hi20, r[i].high); lo20 = MathMin(lo20, r[i].low); }
   return (atr > 0);
}
void PickScan()
{
   g_Off = (long)MathRound(((double)TimeTradeServer() - (double)TimeGMT())/900.0)*900;
   long now = (long)TimeTradeServer();
   datetime cur0 = (datetime)(now - now % 60);                       // abhi wali minute
   long into = now - (long)cur0;
   if(cur0 <= g_PkDone || into < 2 || into > 20) return;            // har minute ek baar, khulne ke 2-20 sec me
   g_PkDone = cur0;
   if(!InWindow()) return;
   int nP = ArraySize(g_PkNames);
   string cN[], cS[], cW[]; int cD[], cO[]; double cB[], cSc[], cP[];
   int nc = 0, nSig = 0, nOut = 0;
   string outTx = "";
   for(int i=0;i<nP;i++)
   {
      string sym = g_PkSyms[i], nm = g_PkNames[i];
      if(sym == "") continue;
      datetime b0 = iTime(sym, PERIOD_M1, 0), b1 = iTime(sym, PERIOD_M1, 1);
      if(b0 != cur0 || b1 <= 0) continue;                           // taaza bhaav nahi (market band / der)
      double body; string why;
      int dir = Signal(sym, PERIOD_M1, body, why);
      if(dir == 0) continue;
      nSig++;
      double str = g_SigStr;
      { string nw; if(HasOpen(sym) || HasPend(sym) || PairBlocked(sym) || NewsBlock(sym, nw)){ nOut++; outTx += " "+nm+":rok"; continue; } }
      double k = UsdPerPriceLot(sym) * 0.01;                         // 0.01 lot par
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
      if(k <= 0 || ask <= 0 || bid <= 0) continue;
      double spr = (ask - bid) * k;
      double tpPct = (TrailOn ? TrailTpBodyPct : TpBodyPct);
      double tp01 = (TpFixedUsd > 0 ? TpFixedUsd : MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * k * tpPct/100.0)));
      if(spr > tp01 * PickSpreadPct/100.0){ nOut++; outTx += " "+nm+":spread"; continue; }
      int h5 = HtfDir(sym, PERIOD_M5), h15 = HtfDir(sym, PERIOD_M15), h1 = HtfDir(sym, PERIOD_H1);
      if(PickNeedHtf && (h15 != dir || h1 != dir)){ nOut++; outTx += " "+nm+":trend"; continue; }
      double C, e21, atr, hi20, lo20, bo, avg;
      if(!SigCtx(sym, C, e21, atr, hi20, lo20, bo, avg)) continue;
      double stretch = MathAbs(C - e21) / atr;
      // order ka tarika
      int ot = 0; double opx = 0; string otx = "MARKET";
      double lvl = (dir > 0 ? hi20 : lo20), gap = (dir > 0 ? lvl - C : C - lvl);
      if(gap > 0 && gap <= StopNearAtr*atr)
      {
         double buf = MathMax(ask - bid, 0.1*atr);
         ot = 2; opx = (dir > 0 ? lvl + buf : lvl - buf); otx = "STOP";
      }
      else if(stretch > LimitStretchAtr || str > LimitBigBody)
      {
         ot = 1; opx = (dir > 0 ? C - LimitPullPct/100.0*bo : C + LimitPullPct/100.0*bo); otx = "LIMIT";
      }
      double ratio = (spr > 0 ? tp01 / spr : 10);
      double sc = MathMin(str, 3.0)/3.0*35.0                         // candle ki taakat (35)
                + MathMin(ratio, 8.0)/8.0*25.0                       // TP / spread (25)
                + (h5 == dir ? 20.0 : 0)                             // 5m bhi saath (20)
                + (stretch <= 1.0 ? 20.0 : (stretch <= 2.0 ? 10.0 : 0));   // bhaav zyada khincha nahi (20)
      if(sc < PickMinScore){ nOut++; outTx += " "+nm+":"+DoubleToString(sc,0); continue; }
      ArrayResize(cN, nc+1); ArrayResize(cS, nc+1); ArrayResize(cW, nc+1); ArrayResize(cD, nc+1); ArrayResize(cO, nc+1);
      ArrayResize(cB, nc+1); ArrayResize(cSc, nc+1); ArrayResize(cP, nc+1);
      cN[nc] = nm; cS[nc] = sym; cD[nc] = dir; cB[nc] = body; cSc[nc] = sc; cO[nc] = ot; cP[nc] = opx;
      cW[nc] = "AUTO "+DoubleToString(sc,0)+" "+otx+" (taakat "+DoubleToString(str,1)+"x, TP/spread "+DoubleToString(ratio,1)+"x, 5m "+(h5 == dir ? "haan" : "nahi")
             +", kheench "+DoubleToString(stretch,1)+" ATR, 15m+1h saath) | "+why;
      nc++;
   }
   for(int a=0;a<nc;a++) for(int b=a+1;b<nc;b++) if(cSc[b] > cSc[a])
   {
      string t1 = cN[a]; cN[a] = cN[b]; cN[b] = t1;  t1 = cS[a]; cS[a] = cS[b]; cS[b] = t1;  t1 = cW[a]; cW[a] = cW[b]; cW[b] = t1;
      int t2 = cD[a]; cD[a] = cD[b]; cD[b] = t2;  t2 = cO[a]; cO[a] = cO[b]; cO[b] = t2;
      double t3 = cB[a]; cB[a] = cB[b]; cB[b] = t3;  t3 = cSc[a]; cSc[a] = cSc[b]; cSc[b] = t3;  t3 = cP[a]; cP[a] = cP[b]; cP[b] = t3;
   }
   string ist = TimeToString(TimeGMT() + 19800, TIME_MINUTES);
   if(nc == 0)
   {
      g_PickTxt = ist+" "+IntegerToString(nSig)+" signal"+(nOut > 0 ? ", sab bahar:"+outTx : ", koi nahi");
      return;
   }
   string list = "";
   for(int a=0;a<nc && a<4;a++) list += (a ? ", " : "")+cN[a]+(cD[a] > 0 ? " B " : " S ")+DoubleToString(cSc[a],0)+(cO[a] == 1 ? "L" : (cO[a] == 2 ? "S" : "M"));
   g_PickTxt = ist+" "+list;
   if(StopWhy() != "") return;                                       // target / loss / pause / algo band: sirf dikhao
   string exp = Exposure();
   int placed = 0;
   for(int a=0;a<nc;a++)
   {
      if(placed >= PickPerMin) break;
      if(CountOpen() + CountPend() >= CurMax()) break;
      if(PickOneCurDir && ExpClash(exp, cN[a], cD[a])){ SkipMsg(cN[a], cD[a] > 0 ? "BUY" : "SELL", "currency pehle se usi disha me (AUTO)"); continue; }
      long nextMs = ((long)cur0 - g_Off) * 1000;
      string key = "c" + B36(nextMs) + cN[a] + "1";
      int before = CountOpen() + CountPend();
      Open(cN[a], Slash(cN[a]), cS[a], cD[a], cB[a], key, cW[a], cO[a], cP[a]);
      if(CountOpen() + CountPend() > before)
      {
         placed++;
         exp += StringSubstr(cN[a], 0, 3) + (cD[a] > 0 ? "+" : "-") + "," + StringSubstr(cN[a], 3, 3) + (cD[a] > 0 ? "-" : "+") + ",";
      }
   }
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
   if(dmg == Magic && en == DEAL_ENTRY_IN){ PdFilled(tr.deal); return; }   // v1.10: LIMIT / STOP bhara
   if(dmg != Magic)
   {
      // v1.04: apnaya hua haath ka trade band (EA ne band kiya to deal par EA ka magic hota hai; broker TP / SL par 0)
      ulong pid0 = (ulong)HistoryDealGetInteger(tr.deal, DEAL_POSITION_ID);
      if(ManageManual && IsAdopted(pid0) && (en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY))
      {
         double pl0 = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
         long r0 = HistoryDealGetInteger(tr.deal, DEAL_REASON);
         string why0 = GetWhy(pid0);
         if(r0 == DEAL_REASON_TP) why0 = "TP"; else if(r0 == DEAL_REASON_SL) why0 = (pl0 > 0 ? "LOCK/TRAIL" : "SL"); else if(why0 == "") why0 = "haath se band";
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
   else if(rsn == DEAL_REASON_SL) res = (pl > 0 ? "LOCK/TRAIL" : "SL");   // v1.08
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
   if(TgtHit()) return "aaj ka target poora $"+DoubleToString(g_TgtNet,2)+(g_LockTxt != "" ? " | "+g_LockTxt : "");
   if(DayTargetUsd > 0 && g_DayPl >= DayTargetUsd) return "aaj ka target poora";
   if(FloatStopUsd > 0 && FloatPl() <= -FloatStopUsd) return "kul floating -$"+DoubleToString(FloatStopUsd,2)+" se neeche";
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd) return "aaj ki ghata seema";
   if(!g_CfgOk && !AutoPick) return "app settings nahi mili";
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
   if(AutoPick) for(int i=0;i<ArraySize(g_PkNames);i++) pairs += (i ? "," : "") + "\""+g_PkNames[i]+(g_PkSyms[i]=="" ? "?" : "")+"\"";
   else for(int i=0;i<ArraySize(g_Names);i++) pairs += (i ? "," : "") + "\""+g_Names[i]+(g_Syms[i]=="" ? "?" : "")+"\"";
   pairs += "]";
   string sw = StopWhy();
   string body = "{\"t\":"+IntegerToString((long)TimeGMT())+",\"v\":\""+VER+"\",\"tf\":"+IntegerToString(g_Tf)+",\"pairs\":"+pairs
      +",\"open\":"+IntegerToString(op)+",\"max\":"+IntegerToString(CurMax())+",\"list\":"+open
      +",\"pend\":"+IntegerToString(CountPend())+",\"auto\":"+(AutoPick ? "true" : "false")+",\"pick\":\""+JsonSafe(g_PickTxt)+"\",\"target\":"+DoubleToString(DayTargetUsd,2)+",\"steps\":\""+JsonSafe(SlotSteps)+"\""
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
   double tp01 = (TpFixedUsd > 0 ? TpFixedUsd : MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * (k/sc) * (TrailOn ? TrailTpBodyPct : ManualTpBodyPct)/100.0)));   // v1.10
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
   if(!AutoPick) AutoReplacePair(sym);   // v1.09: AUTO PICK me badla nahi chahiye
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
   if(StringFind(have, ","+bn+",") < 0)                            // v1.05: app me ON hi nahi tha -> badla nahi
   {
      AddLog(bn+" app me ON nahi tha - uski jagah koi pair ON nahi kiya");
      return;
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
   if(AutoPick){ for(int i=0;i<ArraySize(g_PkSyms);i++) if(g_PkSyms[i]!="" && PairBlocked(g_PkSyms[i])) t += (t=="" ? "" : ", ")+g_PkNames[i]; return t; }
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
   MxTxt(LBL+"K"+id, (key == "" ? " " : key), x0, y, MX_GRN);   // khaali = MT5 "Label" likh deta hai
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
   if(AutoPick) pl = "AUTO("+IntegerToString(ArraySize(g_PkNames))+")";
   else for(int i=0;i<ArraySize(g_Names);i++) pl += (i ? "," : "") + g_Names[i] + (g_Syms[i]=="" ? "?" : "");
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
   Row(y, rh, x0, xv, "1", "STATUS", (sw == "" ? "CHALU - " : "RUKA: "+sw+" - ")+IntegerToString(op)+" / "+IntegerToString(CurMax())+" trade khule", sw == "" ? MX_GRN : MX_AMB);
   if(AutoPick) Row(y, rh, x0, xv, "2", "AUTO PICK", g_PickTxt+"    M1    "+(g_Real ? "REAL" : "DEMO"), MX_GRN);
   else Row(y, rh, x0, xv, "2", "PAIRS", (pl == "" ? "app me koi pair ON nahi" : pl)+"    M1    "+(g_Real ? "REAL" : "DEMO"), MX_GRN);
   Sep(y, rh, x0, lineW, "2");

   int shown = 0;
   for(int i=PositionsTotal()-1;i>=0 && shown < 8;i--)
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
          +"   P&L "+Usd(p)+"   candle "+IntegerToString(idx)+(HoldMax1 > 0 ? "/"+IntegerToString(HoldMax1) : "")+tpTxt, p >= 0 ? MX_GRN : MX_RED);
      shown++;
   }
   if(shown == 0){ Row(y, rh, x0, xv, "T0", "TRADE", "koi trade khula nahi", MX_DIM); shown = 1; }
   for(int k=shown;k<8;k++){ ObjectDelete(0, LBL+"KT"+IntegerToString(k)); ObjectDelete(0, LBL+"VT"+IntegerToString(k)); }

   string tgt = (DayTargetUsd > 0 ? DoubleToString(DayTargetUsd,2) : "-")+(FloatStopUsd > 0 ? "   floating "+Usd(FloatPl()) : "");
   Row(y, rh, x0, xv, "3", "DAILY", Bar(g_DayPl, DayTargetUsd > 0 ? DayTargetUsd : 2.0, 20)+"  "+Usd(g_DayPl)+" / "+tgt+"   jeet "+IntegerToString(g_DayW)+"  haar "+IntegerToString(g_DayL), g_DayPl >= 0 ? MX_GRN : MX_RED);
   Row(y, rh, x0, xv, "4", "SLOTS", Bar(op, CurMax(), 20)+"  EA "+IntegerToString(op)+" / "+IntegerToString(CurMax())+(SlotSteps != "" ? " (seedhi "+SlotSteps+")" : "")+"   +   HAATH "+IntegerToString(CountManual())+" / "+IntegerToString(ManualSlots)+(ManageManual ? "" : " (sambhalna band)"), CountManual() > ManualSlots ? MX_AMB : MX_GRN);
   string ws = (TradeWindows == "" ? "hamesha" : TradeWindows);
   Row(y, rh, x0, xv, "6", "SAMAY", ws+" IST   "+(InWindow() ? "abhi ANDAR (band "+WindowEndTxt()+")" : "abhi BAHAR (agla "+NextWindowTxt()+")"), InWindow() ? MX_GRN : MX_AMB);
   Row(y, rh, x0, xv, "7", "NEWS", NewsTxt(), NewsNowAny() ? MX_AMB : MX_GRN);
   string bt = BlockedTxt();
   Row(y, rh, x0, xv, "8", "AAJ BAND", bt == "" ? "koi pair band nahi (seema -$"+DoubleToString(BlockPairLossUsd,2)+" floating)" : bt+"  (floating -$"+DoubleToString(BlockPairLossUsd,2)+" se neeche gaye the)", bt == "" ? MX_GRN : MX_AMB);
   Row(y, rh, x0, xv, "5", "RULES", "lot "+DoubleToString(Lot,2)+"  TP $"+DoubleToString((TpFixedUsd > 0 ? TpFixedUsd : TpMin_Usd)*Lot/0.01,2)+"  SL $"+DoubleToString(SL_Usd*Lot/0.01,2)
        +"  LOCK +"+DoubleToString(LockAtUsd*Lot/0.01,2)+" -> +"+DoubleToString(LockToUsd*Lot/0.01,2)+(RecoverDipUsd > 0 ? "  WAPSI -"+DoubleToString(RecoverDipUsd*Lot/0.01,2) : "")
        +"  "+(HoldMax1 > 0 ? "TIME "+IntegerToString(HoldMax1) : "TIME nahi")+"  din +$"+DoubleToString(DayTargetUsd,2)+" / -$"+DoubleToString(DayLossUsd,2)+"  pending "+IntegerToString(CountPend()), MX_GRN);
   Sep(y, rh, x0, lineW, "3");

   bool algo = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED));
   MxTxt(LBL+"B1", "BALANCE "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+"    EQUITY "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)
         +"    FIREBASE "+(g_FbOk ? "ok" : "NAHI")+"    APP "+(g_CfgOk ? IntegerToString((int)(TimeLocal()-g_CfgAt))+"s" : "NAHI")+"    ALGO "+(algo ? "on" : "OFF"), x0, y, (g_FbOk && algo) ? MX_GRN : MX_AMB);
   y += rh;
   Sep(y, rh, x0, lineW, "4");

   int nLog = (shown > 4 ? 6 - (shown - 4) : 6);                     // v1.09: 8 trade dikhe to log chhota
   for(int i=0;i<6;i++)
   {
      if(i < g_LogN && i < nLog) MxTxt(LBL+"LG"+IntegerToString(i), "LOG   "+g_Log[i], x0, y, i == 0 ? MX_GRN : MX_DIM);
      else ObjectDelete(0, LBL+"LG"+IntegerToString(i));
      if(i < nLog) y += rh;
   }
   if(g_LogN == 0) MxTxt(LBL+"LG0", "LOG   "+IstNow()+"  shuru - "+g_Status, x0, y - nLog*rh, MX_DIM);

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
   DeletePend("CLOSE ALL");                                           // v1.10
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
