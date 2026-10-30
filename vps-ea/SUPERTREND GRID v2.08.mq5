//+------------------------------------------------------------------+
//|                                   SUPERTREND GRID v2.08.mq5      |
//|              Ankush New Vision - M1 Supertrend + $10 grid basket |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v2.08 (30-Oct-2026) - Ankush: lock wali trade par TP dikhna       |
//|  chahiye. Default InpDDMode ab LOCK+TP (har ulti trade TP $5,     |
//|  round 7 6 5 4 3). Pehle se khuli lock trade (bina TP) par bhi    |
//|  EA TP laga deta hai                                              |
//| v2.07 (29-Oct-2026) - COCKPIT DASHBOARD (Ankush ne 6 me se chuna)|
//|  Badi IST ghadi (second ke saath, server time, session), TREND,   |
//|  MASTER CAUTION (emergency par laal blink + chart ke beech bada   |
//|  flash + awaaz; click = OK), bade number (basket / daily / cycle /|
//|  reserve), 20 khane ka DD gauge, lights (news spread algo weekend |
//|  lock spike), status + PAUSE / CLOSE ALL, reserve USE box.        |
//|  Timer 0.5 sec (blink). Trading niyam v2.06 jaise                 |
//| v2.06 (29-Oct-2026) - 30% RESERVE (Ankush): har cycle ke profit   |
//|  ka 30% reserve me (pichhla loss pehle pura hota hai). AUTO lot / |
//|  din target sirf baaki balance par. Panel [6] RESERVE: kitna      |
//|  bacha, kitna use kiya; box me rakam likho -> USE = utna trading  |
//|  me. Use na karo to reserve pada rahe. Ye usi account me kagzi    |
//|  hisaab hai (MT5 EA alag account me paisa nahi bhej sakta)        |
//| v2.05 (29-Oct-2026) - Ankush ke saath tay:                        |
//|  1. Supertrend TF chuno: M1 / M5 / M15 / M30 (default M1). Upar   |
//|     wale TF ka filter (default M15) - OFF                         |
//|  2. AUTO lot: har $2000 balance par 0.01 ($10,000 = 0.05). Basket |
//|     shuru par tay, poore basket me wahi. Trailing $ (2 / 1 / 1)   |
//|     aur lock TP 0.01 ke hisaab, lot ke saath badhte               |
//|  3. Spread filter: spread > 0.50 -> naya basket / grid nahi       |
//|  4. Weekend: Shukra 3 PM IST ke baad se Somvar 7 AM IST tak naya  |
//|     basket nahi (chalu basket chalta rahe)                        |
//|  5. Push alert (MT5 mobile): Max DD lock / band, cycle profit,    |
//|     din ka target, spike trade                                    |
//|  6. SPIKE: 5 min me basket ke khilaf $30 -> basket ke kul lot     |
//|     jitni EK ulti trade, TP price $5. Khuli rahe tab grid /       |
//|     trailing ruke                                                 |
//|  7. News ke samay grid trade bhi nahi (InpNewsBlockGrid)          |
//| v2.04 (29-Oct-2026) - CYCLE PROFIT $50 (Ankush): basket shuru par |
//|  balance note. Cycle ka kul (band deal + khuli trade) >= +$50 ->  |
//|  sab band, cooldown, naya basket. Lock me atka ho tab bhi isi se  |
//|  bahar. Input InpCycleProfit                                      |
//| v2.03 (29-Oct-2026) - LOCK+TP ghatta hua (Ankush): pehle round me |
//|  basket jitni ulti trade (7), sab TP $5. Saari TP par band ->     |
//|  agle round me ek kam (6), phir 5, 4, 3 (InpLockMinTrades), phir  |
//|  wapas 7 se: 7 6 5 4 3, 7 6 5 4 3 ...                            |
//| v2.02 (29-Oct-2026) - DD par 3 vikalp (InpDDMode, Ankush):        |
//|   0 CLOSE   : sab band + aaj band                                 |
//|   1 LOCK    : (default) utni hi ulti trade, faisla haath se       |
//|   2 LOCK+TP : utni hi ulti trade, har ek ka TP $5 (InpLockTP).    |
//|               Saari ulti trade TP par band -> utni hi phir khulti |
//|               hain, aise hi chalta rahe. Rokna = CLOSE ALL        |
//| v2.01 (29-Oct-2026) - Ankush: Max DD $500, aur DD par band karne  |
//|  ki jagah LOCK: basket ki jitni trade (jaise 5 Buy x 0.01) utni   |
//|  hi ulti trade (5 Sell x 0.01). Lock ke baad EA grid / trailing   |
//|  nahi karta - faisla haath se (CLOSE ALL). Lock wali ulti trade   |
//|  haath se band karo to EA basket phir sambhalta hai              |
//| v2.00 (29-Oct-2026) - NAYI STRATEGY (SUPERTREND HEDGE ki jagah,  |
//|  Ankush): hedge poora hata, grid / averaging                      |
//|  1. Entry  : M1 Supertrend (ATR 10, x3, band candle) jis taraf,   |
//|              nayi M1 candle par 0.01                              |
//|  2. Grid   : pehli entry se har $10 ulta -> usi taraf ek aur 0.01 |
//|              (4000 Buy -> 3990, 3980 ... ), kul 7 trade tak       |
//|  3. Basket : sab trade ka kul profit +$2 -> $1 lock, phir sabse   |
//|              unche profit se $1 peeche lock chale (trailing).     |
//|              Fixed TP nahi. Lock server par SL bhi (sab trade par |
//|              ek hi price) - VPS band ho tab bhi                   |
//|  4. Max DD : basket -$40 -> sab band, aaj band (RESUME se hatao)  |
//|  5. Band hone ke baad 5 min cooldown, phir M1 Supertrend ki       |
//|     mojooda disha me naya basket                                  |
//|  6. Din    : target account balance ka 1% (din ki shuruaat ka)    |
//|  Pehle jaisa: news filter, manual close bhi ginti me, dashboard,  |
//|  PAUSE / RESUME, CLOSE ALL. Naya Magic (hedge EA se alag)         |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "2.08"
#property description "SUPERTREND GRID v2.08 - lock trade par TP $5 (default LOCK+TP), Cockpit dashboard (ghadi, master caution flash), 30% reserve (panel se use), TF chuno, AUTO lot $2000/0.01, spread / weekend / spike / push, cycle profit $50 par sab band, LOCK+TP round 7 6 5 4 3 dohrata, DD par CLOSE / LOCK / LOCK+TP vikalp, Max DD $500 par LOCK (utni hi ulti trade), M1 Supertrend entry, har $10 par 0.01 grid (7 tak), basket +$2 par $1 lock + $1 trailing, Max DD $40, 5 min cooldown, din target balance ka 1%. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME   "SUPERTREND GRID"
#define EA_VER    "v2.08"
#define TAG_TRADE "STG_GRID"
#define TAG_LOCK  "STG_LOCK"
#define TAG_SPIKE "STG_SPIKE"
#define GVP       "STG2_"
#define PNL       "STGP_"
#define BT_PAUSE  "BT_PAUSE"
#define BT_CALL   "BT_CALL"
#define BT_RUSE   "BT_RUSE"
#define ED_RAMT   "ED_RAMT"

//--- theme (PERSONAL FX jaisa)
#define QT_AMBER   C'255,176,0'
#define QT_AMBERD  C'170,125,30'
#define QT_DOTS    C'82,66,26'
#define QT_BG      C'8,8,8'
#define QT_BORDER  C'70,64,40'
#define QT_SECT    C'34,27,7'
#define QT_WHITE   C'230,230,222'
#define QT_GREEN   C'80,220,100'
#define QT_RED     C'255,90,80'
#define QT_DARKBTN C'12,12,10'
#define QFONT      "Consolas"

enum EDDMode
  {
   DD_CLOSE   = 0,   // 0 CLOSE - sab band + aaj band
   DD_LOCK    = 1,   // 1 LOCK - utni hi ulti trade, faisla haath se
   DD_LOCK_TP = 2    // 2 LOCK+TP - ulti trade TP $5, round 7 6 5 4 3 dohrata
  };

enum ESTTF
  {
   ST_M1  = 0,   // M1 (1 minute)
   ST_M5  = 1,   // M5 (5 minute)
   ST_M15 = 2,   // M15 (15 minute)
   ST_M30 = 3    // M30 (30 minute)
  };

input group "1. Account"
input long   InpMagic        = 26102901;   // Magic number (hedge EA se alag)
input int    InpSlippage     = 30;         // Slippage (points)

input group "2. Supertrend"
input ESTTF  InpSTTF         = ST_M1;      // Supertrend timeframe (entry)
input bool   InpSTFilter     = false;      // Upar wale TF ka filter (dono ek disha me ho tab hi basket)
input ESTTF  InpSTFilterTF   = ST_M15;     // Filter timeframe
input int    InpATRPeriod    = 10;         // ATR period
input double InpSTMult       = 3.0;        // Multiplier

input group "3. Grid"
input bool   InpLotAuto      = true;       // AUTO lot (balance ke hisaab se)
input double InpPerBalance   = 2000.0;     // AUTO: har itne balance par 0.01
input double InpLot          = 0.01;       // AUTO band ho to har trade ka lot
input double InpGridGap      = 10.0;       // Grid gap (price, pehli entry se har itna ulta)
input int    InpMaxTrades    = 7;          // Max trade (pehla + grid)
input int    InpCooldownMin  = 5;          // Basket band hone ke baad cooldown (minute)

input group "4. Basket profit (0.01 lot ke hisaab se, lot ke saath badhta)"
input double InpTrailStart   = 2.0;        // Basket itna $ profit -> lock chalu (0.01 par)
input double InpLockMin      = 1.0;        // Kam se kam itna $ lock (0.01 par)
input double InpTrailDist    = 1.0;        // Sabse unche profit se itna $ peeche lock (0.01 par)

input group "5. Din / Safety"
input double InpCycleProfit  = 50.0;       // Cycle profit ($): basket shuru se kul (band + khuli) itna -> sab band, naya cycle (0 = off)
input double InpDailyPct     = 1.0;        // Din ka target (din ki shuruaat ke balance ka %, 0 = off)
input double InpMaxDD        = 500.0;      // Max DD basket ($, 0 = off)
input EDDMode InpDDMode     = DD_LOCK_TP; // Max DD par kya kare
input double InpLockTP       = 5.0;        // LOCK+TP: har ulti trade ka TP ($ per 0.01 = price)
input int    InpLockMinTrades = 3;         // LOCK+TP: har round ek kam, itne tak, phir basket jitni se dobara
input double InpMaxSpread    = 0.50;       // Spread isse zyada (price) -> naya basket / grid nahi (0 = off)
input bool   InpWeekend      = true;       // Weekend: Shukra shaam se Somvar subah naya basket nahi
input int    InpFriStopIST   = 15;         // Shukra itne baje (IST) ke baad naya basket nahi
input int    InpMonStartIST  = 7;          // Somvar itne baje (IST) se phir shuru
input bool   InpPush         = true;       // MT5 mobile push alert
input bool   InpShowPanel    = true;       // Chart panel (dashboard)
input int    InpPanelX       = 10;         // Panel X
input int    InpPanelY       = 25;         // Panel Y
input int    InpPanelFont    = 10;         // Panel font (8-12)
input double InpPanelScale   = 0.0;        // Panel scale (0 = AUTO screen DPI)

input group "6. News filter"
input bool   InpNewsFilter   = true;       // News filter ON
input string InpNewsCcy      = "USD";      // Currency (comma se: USD,EUR)
input int    InpNewsBefore   = 30;         // News se pehle (minute) naya basket nahi
input int    InpNewsAfter    = 30;         // News ke baad (minute) naya basket nahi
input bool   InpNewsBlockGrid = true;      // News ke samay grid trade bhi nahi

input group "8. Reserve"
input bool   InpReserve      = true;       // Profit ka hissa reserve me (lot / target baaki balance par)
input double InpReservePct   = 30.0;       // Har cycle ke profit ka itna % reserve

input group "7. Spike"
input bool   InpSpike        = true;       // Spike: kam samay me basket ke khilaf badi chaal -> ek ulti trade
input double InpSpikeMove    = 30.0;       // Itni chaal (price)
input int    InpSpikeMin     = 5;          // Itne minute me
input double InpSpikeTP      = 5.0;        // Ulti trade ka TP (price)

struct SPos
  {
   ulong    ticket;
   int      dir;      // +1 buy, -1 sell
   double   vol;
   double   open;
   double   sl;
   double   tp;
   double   pl;       // profit + swap
   long     timeMsc;
  };

CTrade   trade;
int      g_stDir        = 0;
datetime g_stBar        = 0;
int      g_fDir         = 0;      // filter TF ka Supertrend
datetime g_fBar         = 0;
ENUM_TIMEFRAMES g_tf    = PERIOD_M1;
ENUM_TIMEFRAMES g_ftf   = PERIOD_M15;
datetime g_dayStart     = 0;
double   g_dayPL        = 0;
uint     g_lastPLms     = 0;
bool     g_plDirty      = true;
string   g_status       = "";
datetime g_newsTimes[];
string   g_newsNames[];
datetime g_newsLoaded   = 0;
datetime g_initTime     = 0;
double   g_S            = 1.0;    // panel scale (screen DPI / 96), chart me fit karne ke baad
double   g_SBase        = 1.0;
int      g_FS           = 10;
double   g_DpiS         = 1.0;
int      g_CW           = 400;
int      g_LabChars     = 16;
int      g_ValX         = 200;
int      g_LastChartW   = 0;
// cockpit panel + master caution
double g_U       = 1.0;     // design px -> chart px
int    g_PX      = 10;      // panel ka x
int    g_PY      = 25;      // panel ka y
bool   g_blink   = false;
int    g_tick    = 0;
int    g_alertLvl  = 0;     // 0 kuch nahi, 1 hara (info), 2 laal (emergency)
string g_alertMsg  = "";
datetime g_alertAt = 0;
datetime g_flashTill = 0;   // chart ke beech bada flash kab tak

//+------------------------------------------------------------------+
double Vpp()   // 1 lot par 1.0 price move = kitne $
  {
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0)
      return 0;
   return tv / ts;
  }
double MoneyToDist(double money, double lots)
  {
   double v = Vpp();
   if(v <= 0 || lots <= 0)
      return 0;
   return money / (lots * v);
  }
double NormLot(double lots)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0)
      step = 0.01;
   lots = MathRound(lots / step) * step;
   lots = MathMax(mn, MathMin(mx, lots));
   return NormalizeDouble(lots, 2);
  }
double NormPrice(double p)
  {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts > 0)
      p = MathRound(p / ts) * ts;
   return NormalizeDouble(p, _Digits);
  }
double MinDist()
  {
   long st = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long fz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(st, fz) * _Point + _Point;
  }

string GvKey(string s) { return GVP + IntegerToString(InpMagic) + "_" + s; }

//+------------------------------------------------------------------+
//| Supertrend (TradingView jaisa, ATR = RMA) - band candle (shift 1) |
//+------------------------------------------------------------------+
int SupertrendDirTF(ENUM_TIMEFRAMES tf, int &cDir, datetime &cBar)
  {
   datetime bt = iTime(_Symbol, tf, 1);
   if(bt == 0)
      return cDir;
   if(bt == cBar && cDir != 0)
      return cDir;

   int need = MathMax(400, InpATRPeriod * 30);
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int n = CopyRates(_Symbol, tf, 1, need, r);   // r[0] sabse purana
   if(n < InpATRPeriod + 3)
      return cDir;

   double atr = 0, sumTR = 0, pUp = 0, pDn = 0;
   int    trend = 1;
   for(int i = 1; i < n; i++)
     {
      double tr = MathMax(r[i].high - r[i].low,
                  MathMax(MathAbs(r[i].high - r[i - 1].close), MathAbs(r[i].low - r[i - 1].close)));
      if(i < InpATRPeriod)
        {
         sumTR += tr;
         continue;
        }
      if(i == InpATRPeriod)
        {
         sumTR += tr;
         atr = sumTR / InpATRPeriod;
        }
      else
         atr = (atr * (InpATRPeriod - 1) + tr) / InpATRPeriod;

      double hl2 = (r[i].high + r[i].low) / 2.0;
      double up  = hl2 - InpSTMult * atr;
      double dn  = hl2 + InpSTMult * atr;
      if(i == InpATRPeriod)
        {
         pUp = up;
         pDn = dn;
         continue;
        }
      if(r[i - 1].close > pUp)
         up = MathMax(up, pUp);
      if(r[i - 1].close < pDn)
         dn = MathMin(dn, pDn);

      if(trend == -1 && r[i].close > pDn)
         trend = 1;
      else
         if(trend == 1 && r[i].close < pUp)
            trend = -1;
      pUp = up;
      pDn = dn;
     }
   cDir = trend;
   cBar = bt;
   return cDir;
  }

ENUM_TIMEFRAMES TFof(ESTTF t)
  {
   if(t == ST_M5)
      return PERIOD_M5;
   if(t == ST_M15)
      return PERIOD_M15;
   if(t == ST_M30)
      return PERIOD_M30;
   return PERIOD_M1;
  }

int SupertrendDir()  { return SupertrendDirTF(g_tf, g_stDir, g_stBar); }
int SupertrendFilt() { return SupertrendDirTF(g_ftf, g_fDir, g_fBar); }


//+------------------------------------------------------------------+
//| P/L : din ka (band deals, is magic + symbol, manual close bhi)   |
//+------------------------------------------------------------------+
#define HIST_BACK 604800   // 7 din peeche tak dekho

void OurPosIds(ulong &ours[])
  {
   ArrayResize(ours, 0);
   int n = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0 || HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;
      ArrayResize(ours, n + 1);
      ours[n++] = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);
     }
  }

bool IsOurDeal(ulong d, const ulong &ours[])
  {
   if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol)
      return false;
   if(HistoryDealGetInteger(d, DEAL_MAGIC) == InpMagic)
      return true;
   ulong pid = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);
   for(int i = ArraySize(ours) - 1; i >= 0; i--)
      if(ours[i] == pid)
         return true;
   return false;
  }

double ClosedPL(long fromMsc)
  {
   double pl = 0;
   if(!HistorySelect((datetime)(fromMsc / 1000) - HIST_BACK, TimeCurrent() + 86400))
      return 0;
   ulong ours[];
   OurPosIds(ours);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(!IsOurDeal(d, ours))
         continue;
      if(HistoryDealGetInteger(d, DEAL_TIME_MSC) < fromMsc)   // pichhle cycle ke deal nahi
         continue;
      pl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
            + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   return pl;
  }

//+------------------------------------------------------------------+
//| News filter (MT5 economic calendar, server time)                 |
//+------------------------------------------------------------------+
void LoadNews()
  {
   ArrayResize(g_newsTimes, 0);
   ArrayResize(g_newsNames, 0);
   datetime now = TimeTradeServer();
   string ccy[];
   int nc = StringSplit(InpNewsCcy, ',', ccy);
   for(int c = 0; c < nc; c++)
     {
      string cur = ccy[c];
      StringTrimLeft(cur);
      StringTrimRight(cur);
      if(cur == "")
         continue;
      MqlCalendarValue v[];
      if(CalendarValueHistory(v, now - 86400, now + 2 * 86400, NULL, cur) <= 0)
         continue;
      for(int i = 0; i < ArraySize(v); i++)
        {
         MqlCalendarEvent ev;
         if(!CalendarEventById(v[i].event_id, ev) || ev.importance != CALENDAR_IMPORTANCE_HIGH)
            continue;
         int k = ArraySize(g_newsTimes);
         ArrayResize(g_newsTimes, k + 1);
         ArrayResize(g_newsNames, k + 1);
         g_newsTimes[k] = v[i].time;
         g_newsNames[k] = cur + " " + ev.name;
        }
     }
   g_newsLoaded = now;
  }

bool NewsBlocked(string &info)
  {
   info = "";
   if(!InpNewsFilter || MQLInfoInteger(MQL_TESTER))
      return false;
   datetime now = TimeTradeServer();
   if(now - g_newsLoaded > 600)
      LoadNews();
   for(int i = 0; i < ArraySize(g_newsTimes); i++)
      if(now >= g_newsTimes[i] - InpNewsBefore * 60 && now <= g_newsTimes[i] + InpNewsAfter * 60)
        {
         // news ka time server time me aata hai -> dikhane ke liye IST (GMT+5:30)
         datetime ist = g_newsTimes[i] - (TimeTradeServer() - TimeGMT()) + 19800;
         info = g_newsNames[i] + " @ " + TimeToString(ist, TIME_MINUTES) + " IST";
         return true;
        }
   return false;
  }

// is EA ki aakhri band (OUT) deal ka time
datetime LastCloseTime()
  {
   datetime last = 0;
   if(!HistorySelect(g_dayStart - HIST_BACK, TimeCurrent() + 86400))
      return 0;
   ulong ours[];
   OurPosIds(ours);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(!IsOurDeal(d, ours))
         continue;
      long e = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(e != DEAL_ENTRY_OUT && e != DEAL_ENTRY_OUT_BY)
         continue;
      datetime t = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      if(t > last)
         last = t;
     }
   return last;
  }

void UpdateDay()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime ds = StructToTime(dt);
   if(ds != g_dayStart)
     {
      g_dayStart = ds;
      g_plDirty  = true;
     }
   uint now = GetTickCount();
   if(!g_plDirty && now - g_lastPLms < 1000)
      return;
   g_dayPL    = ClosedPL((long)g_dayStart * 1000);
   g_lastPLms = now;
   g_plDirty  = false;
  }

//+------------------------------------------------------------------+
//| Positions                                                        |
//+------------------------------------------------------------------+
int ScanPositions(SPos &ps[], double &floating, double &lots)
  {
   ArrayResize(ps, 0);
   int n = 0;
   floating = 0;
   lots     = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      SPos p;
      p.ticket  = tk;
      p.dir     = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      p.vol     = PositionGetDouble(POSITION_VOLUME);
      p.open    = PositionGetDouble(POSITION_PRICE_OPEN);
      p.sl      = PositionGetDouble(POSITION_SL);
      p.tp      = PositionGetDouble(POSITION_TP);
      p.pl      = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      p.timeMsc = PositionGetInteger(POSITION_TIME_MSC);
      floating += p.pl;
      lots     += p.vol;
      ArrayResize(ps, n + 1);
      ps[n++] = p;
     }
   return n;
  }

// basket ki pehli (sabse purani) trade
int FirstIdx(const SPos &ps[], int n)
  {
   int fi = -1;
   for(int i = 0; i < n; i++)
      if(fi < 0 || ps[i].timeMsc < ps[fi].timeMsc)
         fi = i;
   return fi;
  }

void ClosePos(ulong tk, string why)
  {
   if(!trade.PositionClose(tk))
      PrintFormat("%s close #%I64u fail (%s): %u %s", EA_NAME, tk, why, trade.ResultRetcode(), trade.ResultRetcodeDescription());
   else
      PrintFormat("%s close #%I64u : %s", EA_NAME, tk, why);
   g_plDirty = true;
  }

void CloseAll(string why)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      ClosePos(tk, why);
     }
   GlobalVariableDel(GvKey("PEAK"));
  }

//+------------------------------------------------------------------+
//| Din ka target (din ki shuruaat ke balance ka %), pause, Max DD   |
//+------------------------------------------------------------------+
bool IsPaused() { return GlobalVariableCheck(GvKey("PAUSE")) && GlobalVariableGet(GvKey("PAUSE")) > 0; }

bool DayStopped() { return GlobalVariableCheck(GvKey("STOP")) && (datetime)GlobalVariableGet(GvKey("STOP")) == g_dayStart; }

double DayTarget()
  {
   if(InpDailyPct <= 0)
      return 0;
   // din ki shuruaat ka balance = abhi ka balance - aaj is EA ka band P/L
   return (Tradable() - g_dayPL) * InpDailyPct / 100.0;
  }

bool DayBlocked()
  {
   if(DayStopped())
      return true;
   double t = DayTarget();
   return (t > 0 && g_dayPL >= t);
  }

//+------------------------------------------------------------------+
//| Reserve: har cycle ke profit ka 30% alag (usi account me hisaab) |
//+------------------------------------------------------------------+
double Reserve() { return (InpReserve && GlobalVariableCheck(GvKey("RES"))) ? GlobalVariableGet(GvKey("RES")) : 0; }

// trading ke liye balance = balance - reserve
double Tradable() { return MathMax(0.0, AccountInfoDouble(ACCOUNT_BALANCE) - Reserve()); }

// cycle band: profit ho to (pichhla loss pehle pura) uska 30% reserve me
void ReserveAccrue(double pl)
  {
   if(!InpReserve || InpReservePct <= 0)
      return;
   double carry = GlobalVariableCheck(GvKey("RCARRY")) ? GlobalVariableGet(GvKey("RCARRY")) : 0;
   double net   = pl - carry;
   if(net > 0)
     {
      double add = net * InpReservePct / 100.0;
      double res = Reserve() + add;
      GlobalVariableSet(GvKey("RES"), res);
      GlobalVariableSet(GvKey("RCARRY"), 0);
      Notify(StringFormat("Reserve +$%.2f (cycle %s) - kul reserve $%.2f", add, Money(pl), res));
     }
   else
      GlobalVariableSet(GvKey("RCARRY"), -net);
  }

//+------------------------------------------------------------------+
//| Lot (AUTO: har $2000 par 0.01), $ scale, spread, weekend, push   |
//+------------------------------------------------------------------+
double CalcLot()
  {
   if(!InpLotAuto || InpPerBalance <= 0)
      return NormLot(InpLot);
   double steps = MathFloor(Tradable() / InpPerBalance);
   return NormLot(MathMax(1.0, steps) * 0.01);
  }

// is basket ka lot (basket shuru par tay)
double BasketLot() { return GlobalVariableCheck(GvKey("LOT")) ? GlobalVariableGet(GvKey("LOT")) : CalcLot(); }

// 0.01 ke hisaab wale $ ko lot ke hisaab se badhao ($10,000 -> 0.05 -> x5)
double Mult() { return MathMax(1.0, BasketLot() / 0.01); }

bool SpreadOk(const MqlTick &tk) { return InpMaxSpread <= 0 || (tk.ask - tk.bid) <= InpMaxSpread; }

bool WeekendBlocked()
  {
   if(!InpWeekend)
      return false;
   MqlDateTime d;
   TimeToStruct(TimeGMT() + 19800, d);   // IST = GMT + 5:30
   if(d.day_of_week == 6 || d.day_of_week == 0)
      return true;
   if(d.day_of_week == 5 && d.hour >= InpFriStopIST)
      return true;
   if(d.day_of_week == 1 && d.hour < InpMonStartIST)
      return true;
   return false;
  }

// level: 0 sirf push, 1 hara info (master caution), 2 laal emergency (blink + flash + awaaz)
void Notify(string msg, int level = 0)
  {
   PrintFormat("%s %s", EA_NAME, msg);
   if(level > 0 && (level >= g_alertLvl || TimeCurrent() - g_alertAt > 60))
     {
      g_alertLvl = level;
      g_alertMsg = msg;
      g_alertAt  = TimeCurrent();
      if(level == 2)
        {
         g_flashTill = TimeCurrent() + 15;
         if(!MQLInfoInteger(MQL_TESTER))
            PlaySound("alert2.wav");
        }
     }
   if(InpPush && !MQLInfoInteger(MQL_TESTER))
      SendNotification(EA_NAME + ": " + msg);
  }

//+------------------------------------------------------------------+
void OpenTrade(int dir, string why, string tag = TAG_TRADE, double tpDist = 0, double lot = 0)
  {
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk))
      return;
   lot          = NormLot(lot > 0 ? lot : BasketLot());
   double price = dir > 0 ? tk.ask : tk.bid;
   double tp    = tpDist > 0 ? NormPrice(price + dir * tpDist) : 0;
   bool ok = dir > 0 ? trade.Buy(lot, _Symbol, 0, 0, tp, tag)
                     : trade.Sell(lot, _Symbol, 0, 0, tp, tag);
   if(ok)
      PrintFormat("%s %s: %s %.2f @ %s", EA_NAME, why, dir > 0 ? "BUY" : "SELL", lot, DoubleToString(price, _Digits));
   else
      PrintFormat("%s %s fail: %u %s", EA_NAME, why, trade.ResultRetcode(), trade.ResultRetcodeDescription());
   g_plDirty = true;
  }

//+------------------------------------------------------------------+
//| Basket trailing: +$2 par $1 lock, phir peak se $1 peeche          |
//| Lock price = avg + lock / (lots x $ per 1.0) -> sab trade par SL  |
//+------------------------------------------------------------------+
void ManageBasket(const SPos &ps[], int n, double floating, double lots, const MqlTick &tk)
  {
   int    dir = ps[0].dir;
   double vpp = Vpp();
   if(vpp <= 0 || lots <= 0)
      return;
   double avg = 0;
   for(int i = 0; i < n; i++)
      avg += ps[i].open * ps[i].vol;
   avg /= lots;

   double peak = GlobalVariableCheck(GvKey("PEAK")) ? GlobalVariableGet(GvKey("PEAK")) : 0;
   if(floating > peak)
     {
      peak = floating;
      GlobalVariableSet(GvKey("PEAK"), peak);
     }
   double mu = Mult();
   if(peak < InpTrailStart * mu)
      return;   // abhi lock chalu nahi

   double lock = MathMax(InpLockMin * mu, peak - InpTrailDist * mu);
   // profit wapas lock tak aaya -> sab band (server SL bhi yahi hai)
   if(floating <= lock)
     {
      CloseAll(StringFormat("BASKET LOCK +%.2f (peak %.2f)", floating, peak));
      return;
     }
   // server par sab trade ka SL = lock price (EA / VPS band ho tab bhi)
   double slPx = NormPrice(avg + dir * lock / (lots * vpp));
   double c    = dir > 0 ? tk.bid : tk.ask;
   if(dir * (c - slPx) <= MinDist())
      return;
   for(int i = 0; i < n; i++)
      if(ps[i].sl == 0 || dir * (slPx - ps[i].sl) > _Point * 0.5)   // SL sirf aage khiske
         trade.PositionModify(ps[i].ticket, slPx, 0);
  }

//+------------------------------------------------------------------+
void Process()
  {
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk) || tk.bid <= 0)
      return;
   UpdateDay();

   SPos   ps[];
   double floating = 0, lots = 0;
   int    n = ScanPositions(ps, floating, lots);

   if(n == 0)
     {
      GlobalVariableDel(GvKey("PEAK"));
      GlobalVariableDel(GvKey("LOCK"));
      GlobalVariableDel(GvKey("LOCKK"));
      GlobalVariableDel(GvKey("LOT"));
      // cycle abhi band hua -> uska profit ka 30% reserve
      if(GlobalVariableCheck(GvKey("CSTART")))
        {
         ReserveAccrue(ClosedPL((long)GlobalVariableGet(GvKey("CSTART")) * 1000));
         GlobalVariableDel(GvKey("CSTART"));
        }
      if(IsPaused())
        {
         g_status = "PAUSE";
         return;
        }
      if(DayStopped())
        {
         g_status = "AAJ BAND (Max DD)";
         return;
        }
      if(DayBlocked())
        {
         g_status = "DIN KA TARGET PURA";
         if(!GlobalVariableCheck(GvKey("DTN")) || (datetime)GlobalVariableGet(GvKey("DTN")) != g_dayStart)
           {
            GlobalVariableSet(GvKey("DTN"), (double)g_dayStart);
            Notify(StringFormat("Din ka target pura %s", Money(g_dayPL)), 1);
           }
         return;
        }
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         g_status = "ALGO TRADING OFF";
         return;
        }
      string news;
      if(NewsBlocked(news))
        {
         g_status = "NEWS: " + news;
         return;
        }
      if(WeekendBlocked())
        {
         g_status = StringFormat("WEEKEND (Shukra %d:00 se Somvar %d:00 IST)", InpFriStopIST, InpMonStartIST);
         return;
        }
      if(!SpreadOk(tk))
        {
         g_status = StringFormat("SPREAD %.2f > %.2f", tk.ask - tk.bid, InpMaxSpread);
         return;
        }
      // basket band hone ke baad cooldown, phir nayi candle par (EA lagane ke baad bhi nayi candle)
      datetime lastClose = LastCloseTime();
      int      left      = (int)(lastClose + InpCooldownMin * 60 - TimeCurrent());
      if(lastClose > 0 && left > 0)
        {
         g_status = StringFormat("COOLDOWN %d:%02d", left / 60, left % 60);
         return;
        }
      datetime bar0 = iTime(_Symbol, g_tf, 0);
      if(bar0 == 0 || bar0 <= MathMax(lastClose, g_initTime))
        {
         g_status = "Nayi " + EnumToString(g_tf) + " candle ka intezaar";
         return;
        }
      int d = SupertrendDir();
      if(d == 0)
        {
         g_status = "Supertrend data ka intezaar";
         return;
        }
      if(InpSTFilter && SupertrendFilt() != d)
        {
         g_status = StringFormat("FILTER: %s ulta (%s %s)", EnumToString(g_ftf), EnumToString(g_tf), d > 0 ? "BUY" : "SELL");
         return;
        }
      GlobalVariableSet(GvKey("BAL"), AccountInfoDouble(ACCOUNT_BALANCE));
      GlobalVariableSet(GvKey("LOT"), CalcLot());
      GlobalVariableSet(GvKey("CSTART"), (double)TimeCurrent());
      OpenTrade(d, "NAYA BASKET");
      return;
     }

   // CYCLE PROFIT: basket shuru (pehli trade) se band deal + khuli trade >= +$50 -> sab band, naya cycle
   int    fiC      = FirstIdx(ps, n);
   double cycleNet = ClosedPL(ps[fiC].timeMsc) + floating;
   if(InpCycleProfit > 0 && cycleNet >= InpCycleProfit)
     {
      CloseAll(StringFormat("CYCLE PROFIT %s", Money(cycleNet)));
      Notify(StringFormat("Cycle profit %s - sab band, naya cycle", Money(cycleNet)), 1);
      return;
     }

   // DD LOCK: basket ki jitni trade, utni hi ulti (LOCK 1 = khul rahi, 2 = poori)
   int fi0 = FirstIdx(ps, n), baseDir = ps[fi0].dir, nBase = 0, nOpp = 0;
   for(int i = 0; i < n; i++)
      if(ps[i].dir == baseDir)
         nBase++;
      else
         nOpp++;
   int lockSt = GlobalVariableCheck(GvKey("LOCK")) ? (int)GlobalVariableGet(GvKey("LOCK")) : 0;
   double lockTP = (InpDDMode == DD_LOCK_TP) ? MoneyToDist(InpLockTP, 0.01) : 0;   // $ per 0.01 -> price
   // is round me kitni ulti trade (LOCK+TP me 7 6 5 4 3 ...; LOCK me basket jitni)
   int lockK = GlobalVariableCheck(GvKey("LOCKK")) ? (int)GlobalVariableGet(GvKey("LOCKK")) : nBase;
   if(InpDDMode != DD_LOCK_TP || lockK < 1)
      lockK = nBase;
   if(lockSt == 2 && nOpp == 0)
     {
      if(InpDDMode == DD_LOCK_TP)
        {
         // saari ulti trade TP par band -> agle round me ek kam; min se neeche -> basket jitni se dobara
         int next = lockK - 1;
         if(next < MathMax(1, InpLockMinTrades))
            next = nBase;
         PrintFormat("%s LOCK+TP: %d ulti trade TP par band -> agla round %d", EA_NAME, lockK, next);
         lockK = next;
         GlobalVariableSet(GvKey("LOCKK"), lockK);
         GlobalVariableSet(GvKey("LOCK"), 1);
         lockSt = 1;
        }
      else
        {
         // lock wali ulti trade haath se band ki -> basket phir EA sambhalega
         GlobalVariableDel(GvKey("LOCK"));
         lockSt = 0;
        }
     }
   if(lockSt == 1)
     {
      if(nOpp < lockK)
         OpenTrade(-baseDir, StringFormat("DD LOCK %d/%d", nOpp + 1, lockK), TAG_LOCK, lockTP);
      else
         GlobalVariableSet(GvKey("LOCK"), 2);
     }
   // LOCK+TP: kisi lock trade par TP nahi (purane version / mode badla) -> TP laga do
   if(lockSt > 0 && InpDDMode == DD_LOCK_TP && lockTP > 0)
      for(int i = 0; i < n; i++)
         if(ps[i].dir != baseDir && ps[i].tp == 0)
           {
            double tpx = NormPrice(ps[i].open + ps[i].dir * lockTP);
            double cpx = ps[i].dir > 0 ? tk.bid : tk.ask;
            if(ps[i].dir * (tpx - cpx) > MinDist())
               trade.PositionModify(ps[i].ticket, ps[i].sl, tpx);
            else
               ClosePos(ps[i].ticket, "lock TP pehle hi paar");   // price TP ke paar ja chuka
           }
   if(lockSt > 0)
     {
      g_status = StringFormat("DD %s: %d %s + %d %s (%s)%s", InpDDMode == DD_LOCK_TP ? StringFormat("LOCK+TP round %d", lockK) : "LOCK",
                              nBase, baseDir > 0 ? "BUY" : "SELL", nOpp, baseDir > 0 ? "SELL" : "BUY", Money(floating),
                              InpDDMode == DD_LOCK_TP ? " - rokna = CLOSE ALL" : " - faisla haath se");
      return;
     }

   // spike wali ulti trade khuli hai (lock nahi) -> basket pehle se lock, grid / trailing ruke
   bool spikeOpen = (nOpp > 0);

   // Max DD (spike khuli ho to basket pehle se lock hai)
   if(InpMaxDD > 0 && floating <= -InpMaxDD && !spikeOpen)
     {
      if(InpDDMode != DD_CLOSE)
        {
         Notify(StringFormat("MAX DD %s -> LOCK %d", Money(floating), nBase), 2);
         GlobalVariableSet(GvKey("LOCK"), 1);
         GlobalVariableSet(GvKey("LOCKK"), nBase);
         OpenTrade(-baseDir, StringFormat("DD LOCK 1/%d", nBase), TAG_LOCK, lockTP);
         return;
        }
      CloseAll(StringFormat("MAX DD %.2f", floating));
      GlobalVariableSet(GvKey("STOP"), (double)g_dayStart);
      Notify(StringFormat("MAX DD %s - sab band", Money(floating)), 2);
      return;
     }

   if(spikeOpen)
     {
      g_status = StringFormat("SPIKE HEDGE chalu (%d %s + %d %s) - TP ka intezaar", nBase, baseDir > 0 ? "BUY" : "SELL",
                              nOpp, baseDir > 0 ? "SELL" : "BUY");
      return;
     }

   // SPIKE: pichhle InpSpikeMin minute me basket ke khilaf InpSpikeMove -> basket ke kul lot jitni ek ulti trade
   if(InpSpike && InpSpikeMove > 0)
     {
      double move = 0;
      if(baseDir > 0)
        {
         int hi = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, MathMax(1, InpSpikeMin), 0);
         if(hi >= 0)
            move = iHigh(_Symbol, PERIOD_M1, hi) - tk.bid;
        }
      else
        {
         int lo = iLowest(_Symbol, PERIOD_M1, MODE_LOW, MathMax(1, InpSpikeMin), 0);
         if(lo >= 0)
            move = tk.bid - iLow(_Symbol, PERIOD_M1, lo);
        }
      datetime lastSpike = GlobalVariableCheck(GvKey("SPIKET")) ? (datetime)GlobalVariableGet(GvKey("SPIKET")) : 0;
      if(move >= InpSpikeMove && TimeCurrent() - lastSpike >= InpSpikeMin * 60)
        {
         GlobalVariableSet(GvKey("SPIKET"), (double)TimeCurrent());
         OpenTrade(-baseDir, StringFormat("SPIKE %.2f / %d min", move, InpSpikeMin), TAG_SPIKE, InpSpikeTP, NormLot(lots));
         Notify(StringFormat("SPIKE %.2f in %d min -> %s %.2f, TP %.2f", move, InpSpikeMin,
                             baseDir > 0 ? "SELL" : "BUY", NormLot(lots), InpSpikeTP), 2);
         return;
        }
     }

   ManageBasket(ps, n, floating, lots, tk);

   // grid: pehli entry se har InpGridGap ulta -> ek aur 0.01 (InpMaxTrades tak)
   int    fi  = FirstIdx(ps, n);
   int    dir = ps[fi].dir;
   double o   = dir > 0 ? tk.ask : tk.bid;
   double nextLvl = NormPrice(ps[fi].open - dir * InpGridGap * n);
   string gnews;
   bool   gridOk = SpreadOk(tk) && !(InpNewsBlockGrid && NewsBlocked(gnews));
   if(n < InpMaxTrades && dir * (nextLvl - o) >= 0 && gridOk)
     {
      // race guard: usi pal doosra add na ho
      double f2 = 0, l2 = 0;
      SPos   p2[];
      if(ScanPositions(p2, f2, l2) == n)
         OpenTrade(dir, StringFormat("GRID %d", n + 1));
     }

   double peak = GlobalVariableCheck(GvKey("PEAK")) ? GlobalVariableGet(GvKey("PEAK")) : 0;
   double mu   = Mult();
   if(peak >= InpTrailStart * mu)
      g_status = StringFormat("PROFIT LOCK +%.2f (peak %.2f)", MathMax(InpLockMin * mu, peak - InpTrailDist * mu), peak);
   else
      if(!gridOk && n < InpMaxTrades && dir * (nextLvl - o) >= 0)
         g_status = "GRID RUKA (spread / news)";
   else
      if(n >= InpMaxTrades)
         g_status = StringFormat("GRID PURA (%d) - basket profit ka intezaar", n);
      else
         g_status = StringFormat("BASKET %d trade - agla grid %s", n, DoubleToString(nextLvl, _Digits));
  }


//+------------------------------------------------------------------+
//| COCKPIT PANEL (Ankush ne 6 design me se chuna)                   |
//|  Row1: IST ghadi (badi) | TREND | MASTER CAUTION (emergency)     |
//|  Row2: BASKET P&L | DAILY | CYCLE | RESERVE (bade number)         |
//|  Row3: DD GAUGE (20 khane)                                       |
//|  Row4: lights: NEWS SPREAD ALGO WEEKEND LOCK SPIKE               |
//|  Row5: status + PAUSE + CLOSE ALL                                |
//|  Row6: avg / agla grid / lock / balance + reserve USE box        |
//| Design 960 px chaudai par bana, chart ki chaudai me scale hota hai|
//+------------------------------------------------------------------+
#define CK_BG      C'27,30,34'
#define CK_TILE    C'14,16,18'
#define CK_EDGE    C'58,63,69'
#define CK_LABEL   C'154,163,173'
#define CK_TEXT    C'232,232,232'
#define CK_AMBER   C'255,176,0'
#define CK_GREEN   C'61,220,132'
#define CK_RED     C'255,77,77'
#define CK_REDBG   C'58,13,18'
#define CK_GRNBG   C'16,51,31'
#define CK_AMBBG   C'51,39,14'
#define CK_OFF     C'42,46,51'
#define CK_OFFEDGE C'74,80,88'
#define CK_NUM     "Consolas"
#define CK_SANS    "Arial"


int    P(double v)  { return (int)MathRound(v * g_U); }
// design px font -> MT5 point (screen DPI ke hisaab se)
int    FP(double px) { return (int)MathMax(6, MathRound(px * g_U * 0.75 / g_DpiS)); }

string Money(double v) { return (v >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(v), 2); }

string IstTime(datetime srv)
  {
   return TimeToString(srv - (TimeTradeServer() - TimeGMT()) + 19800, TIME_MINUTES);
  }

void Rect(string n, int x, int y, int w, int h, color bg, color edge = clrNONE)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_COLOR, edge == clrNONE ? bg : edge);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, edge == clrNONE ? 1 : MathMax(1, P(2)));
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_BACK, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void Lbl(string n, string t, int x, int y, color c, int f, string font = CK_SANS, ENUM_ANCHOR_POINT an = ANCHOR_LEFT_UPPER)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, f);
   ObjectSetString(0, n, OBJPROP_FONT, font);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, an);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void Btn(string n, string t, int x, int y, int w, int h, color bg, color fg, color edge, int f)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, edge);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, f);
   ObjectSetString(0, n, OBJPROP_FONT, CK_SANS);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void Edit(string n, string t, int x, int y, int w, int h, int f)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, CK_AMBER);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, CK_TILE);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, CK_EDGE);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, f);
   ObjectSetString(0, n, OBJPROP_FONT, CK_NUM);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void SetTxt(string n, string t, color c)
  {
   ObjectSetString(0, PNL + n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, PNL + n, OBJPROP_COLOR, c);
  }

// ek tile: kinara + label + bada number + chhoti line
void Tile(string id, double x, double y, double w, double h, string label, int bigPx)
  {
   Rect(PNL + id + "_BG", g_PX + P(x), g_PY + P(y), P(w), P(h), CK_TILE, CK_EDGE);
   Lbl(PNL + id + "_L", label, g_PX + P(x + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + id + "_V", "--", g_PX + P(x + 12), g_PY + P(y + 26), CK_TEXT, FP(bigPx), CK_NUM);
   Lbl(PNL + id + "_S", " ", g_PX + P(x + 12), g_PY + P(y + h - 24), CK_LABEL, FP(12));
  }

// annunciator light
void Light(string id, double x, double y, double w, double h)
  {
   Rect(PNL + id + "_BG", g_PX + P(x), g_PY + P(y), P(w), P(h), CK_OFF, CK_OFFEDGE);
   Lbl(PNL + id + "_T", "--", g_PX + P(x + w / 2), g_PY + P(y + h / 2), CK_LABEL, FP(13), CK_SANS, ANCHOR_CENTER);
  }

void SetLight(string id, string t, int state)   // 0 band, 1 hara, 2 amber, 3 laal
  {
   color bg = CK_OFF, ed = CK_OFFEDGE, fg = CK_LABEL;
   if(state == 1) { bg = CK_GRNBG; ed = CK_GREEN; fg = CK_GREEN; }
   if(state == 2) { bg = CK_AMBBG; ed = CK_AMBER; fg = CK_AMBER; }
   if(state == 3) { bg = CK_REDBG; ed = CK_RED;   fg = CK_RED;   }
   ObjectSetInteger(0, PNL + id + "_BG", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, PNL + id + "_BG", OBJPROP_COLOR, ed);
   SetTxt(id + "_T", t, fg);
  }

void BuildPanel()
  {
   if(!InpShowPanel)
      return;
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   g_PX = InpPanelX;
   g_PY = InpPanelY;
   // design 960 px chauda; chart me fit (InpPanelScale > 0 ho to wahi)
   double avail = MathMax(400.0, chartW - 2.0 * InpPanelX);
   g_U = (InpPanelScale > 0.0) ? InpPanelScale : MathMin(avail / 960.0, 1.6 * g_DpiS);
   g_U = MathMax(0.45, g_U);

   const double W = 960, PADX = 16, G = 12;
   double inner = W - 2 * PADX;
   double tw = (inner - 3 * G) / 4;   // 4 tile ki chaudai
   Rect(PNL + "BG", g_PX, g_PY, P(W), P(464), CK_BG, CK_EDGE);

   // ---- Row 1: ghadi (2 tile) | trend | master caution
   double y = 16;
   Rect(PNL + "CL_BG", g_PX + P(PADX), g_PY + P(y), P(2 * tw + G), P(96), CK_TILE, CK_EDGE);
   Lbl(PNL + "CL_L", "IST TIME", g_PX + P(PADX + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + "CL_N", EA_NAME + " " + EA_VER + " \x00B7 " + _Symbol, g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 9), CK_LABEL, FP(11), CK_SANS, ANCHOR_RIGHT_UPPER);
   Lbl(PNL + "CL_V", "--:--:--", g_PX + P(PADX + 12), g_PY + P(y + 26), CK_AMBER, FP(52), CK_NUM);
   Lbl(PNL + "CL_S1", "SERVER --:--", g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 46), CK_LABEL, FP(12), CK_SANS, ANCHOR_RIGHT_UPPER);
   Lbl(PNL + "CL_S2", "--", g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 66), CK_LABEL, FP(12), CK_SANS, ANCHOR_RIGHT_UPPER);
   double xt = PADX + 2 * tw + 2 * G;
   Tile("TR", xt, y, tw, 96, "TREND", 32);
   double xc = xt + tw + G;
   // master caution: button (click = OK) + labels upar
   Btn(PNL + "CA_BG", " ", g_PX + P(xc), g_PY + P(y), P(tw), P(96), CK_OFF, CK_LABEL, CK_OFFEDGE, FP(11));
   Lbl(PNL + "CA_L", "MASTER CAUTION", g_PX + P(xc + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + "CA_V", "ALL CLEAR", g_PX + P(xc + 12), g_PY + P(y + 34), CK_GREEN, FP(17));
   Lbl(PNL + "CA_S", " ", g_PX + P(xc + 12), g_PY + P(y + 66), CK_LABEL, FP(11));

   // ---- Row 2: bade number
   y = 124;
   Tile("BP", PADX, y, tw, 92, "BASKET P&L", 30);
   Tile("DY", PADX + (tw + G), y, tw, 92, "DAILY", 30);
   Tile("CY", PADX + 2 * (tw + G), y, tw, 92, "CYCLE", 30);
   Tile("RS", PADX + 3 * (tw + G), y, tw, 92, "RESERVE", 30);

   // ---- Row 3: DD gauge, 20 khane
   y = 228;
   Rect(PNL + "DD_BG", g_PX + P(PADX), g_PY + P(y), P(inner), P(60), CK_TILE, CK_EDGE);
   Lbl(PNL + "DD_L", "DD GAUGE", g_PX + P(PADX + 12), g_PY + P(y + 8), CK_LABEL, FP(11));
   double sw = (inner - 24 - 19 * 4) / 20.0;
   for(int i = 0; i < 20; i++)
      Rect(PNL + "DD_S" + IntegerToString(i), g_PX + P(PADX + 12 + i * (sw + 4)), g_PY + P(y + 30), P(sw), P(18), CK_OFF);

   // ---- Row 4: annunciator lights
   y = 300;
   double lw = (inner - 5 * 8) / 6.0;
   string ids[] = {"LN", "LS", "LA", "LW", "LL", "LK"};
   for(int i = 0; i < 6; i++)
      Light(ids[i], PADX + i * (lw + 8), y, lw, 40);

   // ---- Row 5: status + buttons
   y = 352;
   double bw = 120, sbw = inner - 2 * bw - 2 * G;
   Rect(PNL + "ST_BG", g_PX + P(PADX), g_PY + P(y), P(sbw), P(44), CK_TILE, CK_EDGE);
   Lbl(PNL + "ST_V", "--", g_PX + P(PADX + 12), g_PY + P(y + 22), CK_GREEN, FP(14), CK_NUM, ANCHOR_LEFT);
   Btn(PNL + BT_PAUSE, "PAUSE", g_PX + P(PADX + sbw + G), g_PY + P(y), P(bw), P(44), CK_OFF, CK_AMBER, CK_AMBER, FP(14));
   Btn(PNL + BT_CALL, "CLOSE ALL", g_PX + P(PADX + sbw + G + bw + G), g_PY + P(y), P(bw), P(44), CK_REDBG, CK_RED, CK_RED, FP(14));

   // ---- Row 6: details + reserve USE
   y = 408;
   double iw = 600;
   Rect(PNL + "IN_BG", g_PX + P(PADX), g_PY + P(y), P(iw), P(40), CK_TILE, CK_EDGE);
   Lbl(PNL + "IN_V", "--", g_PX + P(PADX + 12), g_PY + P(y + 20), CK_LABEL, FP(12), CK_NUM, ANCHOR_LEFT);
   double rx = PADX + iw + G;
   Lbl(PNL + "RU_L", "USE RESERVE $", g_PX + P(rx), g_PY + P(y + 20), CK_LABEL, FP(12), CK_SANS, ANCHOR_LEFT);
   Edit(PNL + ED_RAMT, "0", g_PX + P(rx + 120), g_PY + P(y + 4), P(100), P(32), FP(14));
   Btn(PNL + BT_RUSE, "USE", g_PX + P(rx + 228), g_PY + P(y + 4), P(W - PADX - rx - 228), P(32), CK_AMBBG, CK_AMBER, CK_AMBER, FP(13));
  }

void RebuildPanel()
  {
   ObjectsDeleteAll(0, PNL);
   BuildPanel();
   Panel();
  }

string SessionName()
  {
   MqlDateTime g;
   TimeToStruct(TimeGMT(), g);
   if(g.hour < 7)
      return "ASIA SESSION";
   if(g.hour < 12)
      return "LONDON SESSION";
   if(g.hour < 16)
      return "LONDON + NY";
   if(g.hour < 21)
      return "NEW YORK SESSION";
   return "QUIET HOURS";
  }

// har 0.5 sec: ghadi, master caution blink, beech ka flash
void PanelFast()
  {
   if(!InpShowPanel || ObjectFind(0, PNL + "BG") < 0)
      return;
   datetime ist = TimeGMT() + 19800;
   MqlDateTime d;
   TimeToStruct(ist, d);
   string days[] = {"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"};
   string mons[] = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
   SetTxt("CL_L", StringFormat("IST TIME \x00B7 %s %02d %s", days[d.day_of_week], d.day, mons[d.mon - 1]), CK_LABEL);
   SetTxt("CL_V", TimeToString(ist, TIME_SECONDS), CK_AMBER);
   SetTxt("CL_S1", "SERVER " + TimeToString(TimeTradeServer(), TIME_MINUTES), CK_LABEL);
   SetTxt("CL_S2", SessionName(), CK_LABEL);

   // green info 60 sec baad khud hat jaata hai; laal OK dabane tak
   if(g_alertLvl == 1 && TimeCurrent() - g_alertAt > 60)
      g_alertLvl = 0;
   color cbg = CK_OFF, ced = CK_OFFEDGE, cfg = CK_GREEN;
   string cv = "ALL CLEAR", cs = " ";
   if(g_alertLvl == 2)
     {
      cbg = g_blink ? CK_RED : CK_REDBG;
      ced = CK_RED;
      cfg = g_blink ? CK_TILE : CK_RED;
      cv  = g_alertMsg;
      cs  = IstTime(g_alertAt) + " IST \x00B7 click = OK";
     }
   if(g_alertLvl == 1)
     {
      cbg = CK_GRNBG;
      ced = CK_GREEN;
      cfg = CK_GREEN;
      cv  = g_alertMsg;
      cs  = IstTime(g_alertAt) + " IST";
     }
   ObjectSetInteger(0, PNL + "CA_BG", OBJPROP_BGCOLOR, cbg);
   ObjectSetInteger(0, PNL + "CA_BG", OBJPROP_BORDER_COLOR, ced);
   SetTxt("CA_L", "MASTER CAUTION", g_alertLvl == 2 ? cfg : CK_LABEL);
   SetTxt("CA_V", StringLen(cv) > 22 ? StringSubstr(cv, 0, 22) : cv, cfg);
   SetTxt("CA_S", cs, g_alertLvl == 2 ? cfg : CK_LABEL);

   // chart ke beech bada flash (sirf laal emergency, kuch second)
   if(g_alertLvl == 2 && TimeCurrent() < g_flashTill)
     {
      int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS), ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      int fw = MathMin(cw - 20, P(720)), fh = P(130);
      Btn(PNL + "FLASH", "\x26A0  " + g_alertMsg + "  \x26A0", (cw - fw) / 2, MathMax(g_PY + P(470), (ch - fh) / 2), fw, fh,
          g_blink ? CK_RED : CK_TILE, g_blink ? CK_TILE : CK_RED, CK_RED, FP(24));
     }
   else
      ObjectDelete(0, PNL + "FLASH");
   ChartRedraw(0);
  }

void Panel()
  {
   if(!InpShowPanel)
      return;
   if(ObjectFind(0, PNL + "BG") < 0)
      BuildPanel();
   SPos   ps[];
   double floating = 0, lots = 0;
   int    n = ScanPositions(ps, floating, lots);
   MqlTick tk;
   SymbolInfoTick(_Symbol, tk);

   // Row 1: trend
   SetTxt("TR_L", "TREND \x00B7 " + StringSubstr(EnumToString(g_tf), 7) + (InpSTFilter ? " + " + StringSubstr(EnumToString(g_ftf), 7) : ""), CK_LABEL);
   SetTxt("TR_V", g_stDir > 0 ? "BUY \x25B2" : (g_stDir < 0 ? "SELL \x25BC" : "--"), g_stDir > 0 ? CK_GREEN : (g_stDir < 0 ? CK_RED : CK_LABEL));
   SetTxt("TR_S", " ", CK_LABEL);

   // Row 2
   double cyc = 0, avg = 0, peak = 0, nextLvl = 0;
   int    dir = 0;
   if(n > 0)
     {
      int fi = FirstIdx(ps, n);
      dir = ps[fi].dir;
      for(int i = 0; i < n; i++)
         avg += ps[i].open * ps[i].vol;
      avg /= lots;
      cyc  = ClosedPL(ps[fi].timeMsc) + floating;
      peak = GlobalVariableCheck(GvKey("PEAK")) ? GlobalVariableGet(GvKey("PEAK")) : 0;
      nextLvl = ps[fi].open - dir * InpGridGap * n;
      SetTxt("BP_V", StringFormat("%+.2f", floating), floating >= 0 ? CK_GREEN : CK_RED);
      SetTxt("BP_S", StringFormat("%s \x00B7 %d / %d trade \x00B7 %.2f lot", dir > 0 ? "BUY" : "SELL", n, InpMaxTrades, lots), CK_LABEL);
      SetTxt("CY_V", StringFormat("%+.2f", cyc), cyc >= 0 ? CK_TEXT : CK_RED);
     }
   else
     {
      SetTxt("BP_V", "--", CK_LABEL);
      SetTxt("BP_S", "koi basket nahi", CK_LABEL);
      SetTxt("CY_V", "--", CK_LABEL);
     }
   SetTxt("CY_S", InpCycleProfit > 0 ? StringFormat("exit at +$%.0f", InpCycleProfit) : "cycle exit OFF", CK_LABEL);
   double dt = DayTarget();
   SetTxt("DY_V", StringFormat("%+.2f", g_dayPL), g_dayPL >= 0 ? CK_GREEN : CK_RED);
   SetTxt("DY_S", dt > 0 ? StringFormat("target $%.0f (%.1f%%)%s", dt, InpDailyPct, g_dayPL >= dt ? " PURA" : "") : "target OFF", g_dayPL >= dt && dt > 0 ? CK_AMBER : CK_LABEL);
   double used = GlobalVariableCheck(GvKey("RUSED")) ? GlobalVariableGet(GvKey("RUSED")) : 0;
   SetTxt("RS_V", InpReserve ? DoubleToString(Reserve(), 2) : "OFF", InpReserve ? CK_AMBER : CK_LABEL);
   SetTxt("RS_S", StringFormat("%.0f%% \x00B7 used $%.0f", InpReservePct, used), CK_LABEL);

   // Row 3: DD gauge
   double frac = (InpMaxDD > 0 && floating < 0) ? MathMin(1.0, -floating / InpMaxDD) : 0;
   int    fill = (int)MathCeil(frac * 20 - 1e-9);
   SetTxt("DD_L", InpMaxDD > 0 ? StringFormat("DD GAUGE \x00B7 %s OF -$%.0f", Money(MathMin(floating, 0)), InpMaxDD) : "DD GAUGE \x00B7 OFF", CK_LABEL);
   for(int i = 0; i < 20; i++)
     {
      color on  = i < 14 ? CK_GREEN : (i < 17 ? CK_AMBER : CK_RED);
      color off = i < 14 ? CK_OFF : (i < 17 ? CK_AMBBG : CK_REDBG);
      ObjectSetInteger(0, PNL + "DD_S" + IntegerToString(i), OBJPROP_BGCOLOR, i < fill ? on : off);
      ObjectSetInteger(0, PNL + "DD_S" + IntegerToString(i), OBJPROP_COLOR, i < fill ? on : off);
     }

   // Row 4: lights
   string news;
   bool   nb = NewsBlocked(news);
   SetLight("LN", !InpNewsFilter ? "NEWS OFF" : (nb ? "NEWS BLOCK" : "NEWS OK"), !InpNewsFilter ? 0 : (nb ? 3 : 1));
   double spr = tk.ask - tk.bid;
   SetLight("LS", StringFormat("SPREAD %.2f", spr), SpreadOk(tk) ? 1 : 3);
   bool algo = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED);
   SetLight("LA", algo ? "ALGO ON" : "ALGO OFF", algo ? 1 : 3);
   bool wk = WeekendBlocked();
   SetLight("LW", wk ? "WEEKEND STOP" : StringFormat("WEEKEND %d:00", InpFriStopIST), wk ? 2 : 1);
   int lockSt = GlobalVariableCheck(GvKey("LOCK")) ? (int)GlobalVariableGet(GvKey("LOCK")) : 0;
   bool dayStop = DayStopped();
   SetLight("LL", lockSt > 0 ? "DD LOCK ON" : (dayStop ? "AAJ BAND" : "LOCK OFF"), lockSt > 0 || dayStop ? 3 : 0);
   int nOpp = 0;
   for(int i = 0; i < n; i++)
      if(ps[i].dir != dir)
         nOpp++;
   bool spikeOpen = (lockSt == 0 && nOpp > 0);
   SetLight("LK", !InpSpike ? "SPIKE OFF" : (spikeOpen ? "SPIKE HEDGE" : "SPIKE READY"), !InpSpike ? 0 : (spikeOpen ? 3 : 1));

   // Row 5: status + buttons
   bool paused = IsPaused();
   SetTxt("ST_V", "\x25B8 " + (paused ? "PAUSE (naya basket nahi)" : g_status), paused ? CK_AMBER : CK_GREEN);
   bool hold = paused || dayStop;
   ObjectSetString(0, PNL + BT_PAUSE, OBJPROP_TEXT, hold ? "RESUME" : "PAUSE");
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_COLOR, hold ? CK_GREEN : CK_AMBER);
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_BORDER_COLOR, hold ? CK_GREEN : CK_AMBER);

   // Row 6: details
   string info;
   if(n > 0)
     {
      double mu = Mult();
      string lk = peak >= InpTrailStart * mu ? StringFormat("LOCK %s", Money(MathMax(InpLockMin * mu, peak - InpTrailDist * mu)))
                                             : StringFormat("LOCK +$%.0f par", InpTrailStart * mu);
      info = StringFormat("AVG %s \x00B7 AGLA GRID %s \x00B7 %s \x00B7 EQ $%.2f", DoubleToString(avg, _Digits),
                          n >= InpMaxTrades ? "PURA" : DoubleToString(nextLvl, _Digits), lk, AccountInfoDouble(ACCOUNT_EQUITY));
     }
   else
      info = StringFormat("BAL $%.2f \x00B7 EQ $%.2f \x00B7 LOT %.2f%s \x00B7 TRADING BAL $%.2f", AccountInfoDouble(ACCOUNT_BALANCE),
                          AccountInfoDouble(ACCOUNT_EQUITY), CalcLot(), InpLotAuto ? " AUTO" : "", Tradable());
   SetTxt("IN_V", info, CK_LABEL);
   PanelFast();
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Alert(EA_NAME, ": sirf HEDGING account par chalta hai (Buy + Sell saath).");
      return INIT_FAILED;
     }
   g_tf  = TFof(InpSTTF);
   g_ftf = TFof(InpSTFilterTF);
   if(InpGridGap <= 0 || InpMaxTrades < 1 || InpLot <= 0 || InpTrailStart < InpLockMin)
     {
      Alert(EA_NAME, ": inputs galat (gap > 0, max trade >= 1, lot > 0, trail start >= lock).");
      return INIT_PARAMETERS_INCORRECT;
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);
   g_initTime     = TimeCurrent();
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi <= 0)
      dpi = 96;
   g_DpiS = dpi / 96.0;
   g_SBase = (InpPanelScale > 0.0) ? InpPanelScale : g_DpiS;
   g_SBase = MathMax(0.75, MathMin(3.0, g_SBase));
   g_S     = g_SBase;
   g_FS    = InpPanelFont;
   Comment("");
   if(InpShowPanel)
      RebuildPanel();
   EventSetMillisecondTimer(500);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
   ObjectsDeleteAll(0, PNL);
  }

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(InpShowPanel && MathAbs(w - g_LastChartW) > 4)
         RebuildPanel();
      return;
     }
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   // master caution ya beech wala flash dabaya = OK (alert hatao)
   if(StringFind(sp, PNL + "CA_") == 0 || sp == PNL + "FLASH")
     {
      g_alertLvl  = 0;
      g_flashTill = 0;
      ObjectDelete(0, PNL + "FLASH");
     }
   if(sp == PNL + BT_PAUSE)
     {
      if(DayStopped())
        {
         // Max DD ka aaj ka stop haath se hatao (RESUME)
         GlobalVariableDel(GvKey("STOP"));
         GlobalVariableSet(GvKey("PAUSE"), 0);
         PrintFormat("%s RESUME - Max DD ka aaj ka stop hataya", EA_NAME);
        }
      else
        {
         GlobalVariableSet(GvKey("PAUSE"), IsPaused() ? 0 : 1);
         PrintFormat("%s %s", EA_NAME, IsPaused() ? "PAUSE - naya cycle nahi" : "RESUME");
        }
     }
   if(sp == PNL + BT_CALL)
      CloseAll("CLOSE ALL button");
   if(sp == PNL + BT_RUSE)
     {
      // box me likhi rakam reserve se trading me (reserve se zyada nahi)
      double amt = StringToDouble(ObjectGetString(0, PNL + ED_RAMT, OBJPROP_TEXT));
      amt = MathMin(MathMax(0.0, amt), Reserve());
      if(amt > 0)
        {
         double left = Reserve() - amt;
         GlobalVariableSet(GvKey("RES"), left);
         double used = (GlobalVariableCheck(GvKey("RUSED")) ? GlobalVariableGet(GvKey("RUSED")) : 0) + amt;
         GlobalVariableSet(GvKey("RUSED"), used);
         Notify(StringFormat("Reserve se $%.2f use kiya - bacha $%.2f", amt, left));
        }
      ObjectSetString(0, PNL + ED_RAMT, OBJPROP_TEXT, "0");
     }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   Panel();
  }

void OnTick()
  {
   Process();
  }

void OnTimer()
  {
   g_blink = !g_blink;
   g_tick++;
   if(g_tick % 2 == 0)
      Panel();       // har 1 sec poora panel
   else
      PanelFast();   // har 0.5 sec ghadi + blink
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
      g_plDirty = true;
  }
//+------------------------------------------------------------------+
