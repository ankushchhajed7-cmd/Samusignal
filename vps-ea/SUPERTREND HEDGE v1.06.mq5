//+------------------------------------------------------------------+
//|                                   SUPERTREND HEDGE v1.06.mq5     |
//|                 Ankush New Vision - Supertrend + 2x hedge cycle  |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.06 (28-Oct-2026) - Ankush: EA ki trade MANUAL band karo to     |
//|  bhi uska profit / loss din ke target, cycle P&L aur recent       |
//|  closes me gina jaaye. Pehle sirf EA ke Magic wali band deal      |
//|  gini jaati thi (manual band deal ka Magic 0 hota hai). Ab EA ki  |
//|  khuli position (IN deal is Magic se) ki har band deal gini jaati |
//|  hai. EA ke bina khuli manual trade nahi gini jaati               |
//| v1.05 (28-Oct-2026) - DASHBOARD PERSONAL FX jaisa (Ankush):       |
//|  amber terminal panel, 3 column: [1] CYCLE [2] ACCOUNT            |
//|  [3] RISK CONTROL [4] SETTINGS [5] RECENT CLOSES (IST) + status   |
//|  bar. Buttons: PAUSE / RESUME (naya cycle rok-ta, chalu trade     |
//|  nahi chhedta) aur CLOSE ALL. Trading niyam v1.04 jaise           |
//| v1.04 (28-Oct-2026) - Ankush ke live screenshot se:               |
//|  1. FIX: ek saath 2 hedge (0.02 + 0.02) khul gaye the. Server ne  |
//|     Buy Stop bhara aur usi pal EA ne market se bhi khola. Ab      |
//|     pending laga ho to market nahi; 5 sec me na bhare tab hi      |
//|     pending hata kar market                                       |
//|  2. ASLI 0-0 BE: hedge spread cover karke 0 ke upar gaya ->       |
//|     server par SL = entry price. Price wapas aaye to bilkul 0 par |
//|     band (pehle spread jitna minus me katta tha)                  |
//|  3. Jo hedge khulte hi ulta gaya (kabhi 0 tak nahi pahuncha) wo   |
//|     pehle jaisa spread jitne loss par hi katega                   |
//| v1.03 (28-Oct-2026) - FIX (Ankush): cycle band hote hi turant     |
//|  naya trade khul jaata tha. Ab cycle band hone ke baad M5 ki      |
//|  NAYI candle shuru hone par hi Supertrend check karke naya trade. |
//|  EA lagane / restart par bhi agli nayi candle ka intezaar         |
//| v1.02 (28-Oct-2026) - Ankush ke badlav:                           |
//|  1. Re-entry limit ab PARTIAL ki ginti se: hedge me $1 partial    |
//|     4 baar ho gaya -> is cycle me naya hedge nahi                 |
//|  2. 0-0 EXIT: 4 partial ke baad cycle ka kul >= 0 hote hi sab     |
//|     band, naya cycle (+$1 ka intezaar nahi)                       |
//|  3. Whipsaw limit 6: bina partial ke BE par band hue hedge alag   |
//|     gine. 6 ho gaye -> naya hedge nahi (spread ka kharcha ruke)   |
//|  4. Max DD default $10 (cycle -$10 -> sab band, aaj band)         |
//| v1.01 (28-Oct-2026) - Ankush ke 3 badlav:                         |
//|  1. Main TP ab CYCLE ke hisaab se: TP wahan jahan cycle ka kul    |
//|     +$1 bane (pehle ke partial / BE ka hisaab jod kar). Pehle BE  |
//|     ke spread loss se cycle minus me band ho sakta tha            |
//|  2. Re-entry max 3: pehla hedge + 3 baar dobara (kul 4). Uske    |
//|     baad is cycle me naya hedge nahi                              |
//|  3. News filter: USD HIGH impact news se 30 min pehle / 30 min   |
//|     baad naya cycle nahi (MT5 calendar; Strategy Tester me        |
//|     calendar nahi chalta). Chalu cycle chalta rahega. Panel par  |
//|     news ka time IST (India) me                                   |
//| v1.00 (28-Oct-2026) - POORA NAYA EA (Ankush ki strategy)          |
//|  1. Entry  : M5 Supertrend (ATR 10, x3, band candle) jis taraf,   |
//|              us taraf MAIN trade 0.01, TP $1 (server par)         |
//|  2. Hedge  : price $3 ulta (4000 -> 3997) -> ulti side 0.02       |
//|              (Sell Stop / Buy Stop pending, server par)           |
//|  3. Lock   : hedge $1 (0.01 ke hisaab, 0.02 par $2) profit me ->  |
//|              lock. Price wapas lock level par -> 0.01 partial     |
//|              close (+$1). Bacha 0.01 sirf hedge, profit nahi lega |
//|  4. BE     : hedge price entry se ulta gaya -> no profit no loss  |
//|              band (sirf spread). Price wapas level par -> dobara  |
//|              0.02. Ye jitni baar bhi ho                            |
//|  5. Basket : main + hedge khule, kul floating >= $1 -> sab band   |
//|  5b Cycle  : cycle shuru par balance note. Cycle ka kul (band     |
//|              partial / BE + khuli trades) >= $1 -> sab band       |
//|              (100 -> 101), naya cycle                             |
//|  6. Cycle  : main TP par band -> hedge band, naya Supertrend      |
//|              check, naya cycle                                    |
//|  7. Din    : $5 target -> naya cycle nahi (chalu cycle pura hoga) |
//|              Din = broker server time 00:00                       |
//|  Safety    : hedge par backup SL server par (EA band ho tab bhi), |
//|              Max DD (default OFF). Sirf HEDGING account           |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.06"
#property description "SUPERTREND HEDGE v1.06 - manual close bhi target me, PERSONAL FX jaisa dashboard, asli 0-0 BE (server SL), duplicate hedge fix, naya cycle sirf nayi M5 candle par, M5 Supertrend main trade (cycle +$1 TP), news filter, max 4 partial + 0-0 exit, whipsaw 6, max DD $10, 2x hedge, profit lock + partial close, breakeven re-entry, cycle +$1 close, daily target. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME   "SUPERTREND HEDGE"
#define EA_VER    "v1.06"
#define TAG_MAIN  "STH_MAIN"
#define TAG_HEDGE "STH_HEDGE"
#define GVP       "STH1_"
#define PNL       "STHP_"
#define BT_PAUSE  "BT_PAUSE"
#define BT_CALL   "BT_CALL"

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

input group "1. Account"
input long   InpMagic        = 26102801;   // Magic number
input int    InpSlippage     = 30;         // Slippage (points)

input group "2. Supertrend"
input ENUM_TIMEFRAMES InpSTTF = PERIOD_M5; // Supertrend timeframe
input int    InpATRPeriod    = 10;         // ATR period
input double InpSTMult       = 3.0;        // Multiplier

input group "3. Trade"
input double InpLot          = 0.01;       // Main trade lot
input double InpTPMoney      = 1.0;        // TP / lock / basket / cycle target ($)
input double InpHedgeGap     = 3.0;        // Hedge gap (price, 4000 -> 3997)
input double InpHedgeMult    = 2.0;        // Hedge lot = main lot x
input double InpReentryGap   = 0.0;        // Re-entry gap (price, 0 = usi level par)
input double InpBEBuffer     = 0.0;        // BE close buffer (price, 0 = turant) - jo hedge kabhi 0 tak nahi pahuncha
input double InpBEPlus       = 0.0;        // Asli BE SL entry se kitna plus (price, 0 = bilkul 0-0)
input double InpBackupSL     = 0.50;       // Hedge backup SL server par (price, 0 = off)
input int    InpMaxPartials  = 4;          // Max partial ($1) per cycle -> phir naya hedge nahi + 0-0 exit (-1 = no limit)
input int    InpMaxWhipsaw   = 6;          // Max whipsaw (bina partial BE) per cycle -> phir naya hedge nahi (-1 = no limit)

input group "4. Din / Safety"
input double InpDailyTarget  = 5.0;        // Din ka target ($, 0 = off)
input double InpMaxDD        = 10.0;       // Max DD cycle ($, 0 = off) -> sab band, aaj band
input bool   InpShowPanel    = true;       // Chart panel (dashboard)
input int    InpPanelX       = 10;         // Panel X
input int    InpPanelY       = 25;         // Panel Y
input int    InpPanelFont    = 10;         // Panel font (8-12)
input double InpPanelScale   = 0.0;        // Panel scale (0 = AUTO screen DPI)

input group "5. News filter"
input bool   InpNewsFilter   = true;       // News filter ON
input string InpNewsCcy      = "USD";      // Currency (comma se: USD,EUR)
input int    InpNewsBefore   = 30;         // News se pehle (minute) naya cycle nahi
input int    InpNewsAfter    = 30;         // News ke baad (minute) naya cycle nahi

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
bool     g_armed        = true;   // hedge level ke "peeche" price aa chuka hai
int      g_lastHedgeCnt = 0;
int      g_stDir        = 0;
datetime g_stBar        = 0;
datetime g_dayStart     = 0;
double   g_dayPL        = 0;
uint     g_lastPLms     = 0;
bool     g_plDirty      = true;
string   g_status       = "";
datetime g_newsTimes[];
string   g_newsNames[];
datetime g_newsLoaded   = 0;
datetime g_initTime     = 0;
datetime g_pendHitSince = 0;
double   g_S            = 1.0;    // panel scale (screen DPI / 96)
double   g_DpiS         = 1.0;
int      g_CW           = 400;
int      g_LabChars     = 16;
int      g_ValX         = 200;
int      g_LastChartW   = 0;
int      g_partials     = 0;
int      g_whipsaws     = 0;

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
int SupertrendDir()
  {
   datetime bt = iTime(_Symbol, InpSTTF, 1);
   if(bt == 0)
      return g_stDir;
   if(bt == g_stBar && g_stDir != 0)
      return g_stDir;

   int need = MathMax(400, InpATRPeriod * 30);
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int n = CopyRates(_Symbol, InpSTTF, 1, need, r);   // r[0] sabse purana
   if(n < InpATRPeriod + 3)
      return g_stDir;

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
   g_stDir = trend;
   g_stBar = bt;
   return g_stDir;
  }

//+------------------------------------------------------------------+
//| Positions / orders                                               |
//+------------------------------------------------------------------+
int ScanPositions(SPos &mainP, bool &hasMain, SPos &hed[], double &floating)
  {
   SPos all[];
   int  n = 0;
   floating = 0;
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
      ArrayResize(all, n + 1);
      all[n++] = p;
     }
   // main = jo ticket cycle shuru par yaad kiya (comment par bharosa nahi, broker badal deta hai).
   // Yaad na ho (pehli baar / manual) to sabse purani trade. Yaad wala band ho chuka -> main nahi.
   hasMain = false;
   int mi = -1;
   if(GlobalVariableCheck(GvKey("MAIN")))
     {
      ulong mt = (ulong)GlobalVariableGet(GvKey("MAIN"));
      for(int i = 0; i < n; i++)
         if(all[i].ticket == mt)
            mi = i;
     }
   else
      for(int i = 0; i < n; i++)
         if(mi < 0 || all[i].timeMsc < all[mi].timeMsc)
            mi = i;
   ArrayResize(hed, 0);
   int nh = 0;
   for(int i = 0; i < n; i++)
     {
      if(i == mi)
        {
         mainP   = all[i];
         hasMain = true;
         continue;
        }
      ArrayResize(hed, nh + 1);
      hed[nh++] = all[i];
     }
   return nh;
  }

ulong FindPending()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != InpMagic)
         continue;
      ENUM_ORDER_TYPE t = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(t == ORDER_TYPE_BUY_STOP || t == ORDER_TYPE_SELL_STOP)
         return tk;
     }
   return 0;
  }

void DeletePendings()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != InpMagic)
         continue;
      trade.OrderDelete(tk);
     }
  }

void ClosePos(ulong tk, string why)
  {
   if(!trade.PositionClose(tk))
      PrintFormat("%s close #%I64u fail (%s): %u %s", EA_NAME, tk, why, trade.ResultRetcode(), trade.ResultRetcodeDescription());
   else
      PrintFormat("%s close #%I64u : %s", EA_NAME, tk, why);
   GlobalVariableDel(GvKey("L" + (string)tk));
   GlobalVariableDel(GvKey("B" + (string)tk));
   g_plDirty = true;
  }

void CloseAll(string why)
  {
   DeletePendings();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      ClosePos(tk, why);
     }
  }

//+------------------------------------------------------------------+
//| P/L : din ka aur cycle ka (band deals, is magic + symbol)        |
//+------------------------------------------------------------------+
#define HIST_BACK 604800   // 7 din peeche tak dekho (raat ko khuli position bhi pakad me aaye)

// is EA ki positions ke ID: jinki IN deal is Magic se bani. HistorySelect pehle ho chuka ho
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

// EA ki deal ya EA ki position ki manual band deal (manual close ka Magic 0 hota hai)
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

// cycle ka band P/L + hedge ki ginti:
//  partial  = hedge jiska kuch hissa band hua (0.02 me se 0.01)
//  whipsaw  = hedge jo bina partial ke poora band hua (BE)
double CycleStats(long fromMsc, ulong mainTicket, int &partials, int &whipsaws)
  {
   double pl = 0;
   partials = 0;
   whipsaws = 0;
   if(!HistorySelect((datetime)(fromMsc / 1000) - HIST_BACK, TimeCurrent() + 86400))
      return 0;
   ulong ours[];
   OurPosIds(ours);
   ulong  ids[];
   double inV[], outV[];
   bool   part[];
   int    n = 0;
   double eps = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) * 0.5;
   int    total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(!IsOurDeal(d, ours))
         continue;
      if(HistoryDealGetInteger(d, DEAL_TIME_MSC) < fromMsc)
         continue;
      pl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
            + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
      ulong pid = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);
      if(pid == mainTicket)
         continue;
      long   entry = HistoryDealGetInteger(d, DEAL_ENTRY);
      double vol   = HistoryDealGetDouble(d, DEAL_VOLUME);
      int k = -1;
      for(int j = 0; j < n; j++)
         if(ids[j] == pid)
            k = j;
      if(entry == DEAL_ENTRY_IN)
        {
         if(k < 0)
           {
            ArrayResize(ids, n + 1);
            ArrayResize(inV, n + 1);
            ArrayResize(outV, n + 1);
            ArrayResize(part, n + 1);
            ids[n]  = pid;
            inV[n]  = vol;
            outV[n] = 0;
            part[n] = false;
            n++;
           }
        }
      else
         if(k >= 0)
           {
            if(vol < inV[k] - eps)
               part[k] = true;
            outV[k] += vol;
           }
     }
   for(int j = 0; j < n; j++)
     {
      if(part[j])
         partials++;
      else
         if(outV[j] >= inV[j] - eps)
            whipsaws++;
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

// is EA ki aakhri band (OUT) deal ka time - pichhle 2 din me
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

bool IsPaused() { return GlobalVariableCheck(GvKey("PAUSE")) && GlobalVariableGet(GvKey("PAUSE")) > 0; }

bool DayStopped() { return GlobalVariableCheck(GvKey("STOP")) && (datetime)GlobalVariableGet(GvKey("STOP")) == g_dayStart; }

bool DayBlocked()
  {
   if(DayStopped())
      return true;
   return (InpDailyTarget > 0 && g_dayPL >= InpDailyTarget);
  }

//+------------------------------------------------------------------+
void OpenMain(int dir)
  {
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk))
      return;
   double lot  = NormLot(InpLot);
   double dist = MoneyToDist(InpTPMoney, lot);
   if(dist <= 0)
      return;
   double price = dir > 0 ? tk.ask : tk.bid;
   double tp    = NormPrice(price + dir * dist);
   bool ok = dir > 0 ? trade.Buy(lot, _Symbol, 0, 0, tp, TAG_MAIN)
                     : trade.Sell(lot, _Symbol, 0, 0, tp, TAG_MAIN);
   if(!ok)
     {
      PrintFormat("%s main open fail: %u %s", EA_NAME, trade.ResultRetcode(), trade.ResultRetcodeDescription());
      return;
     }
   GlobalVariableSet(GvKey("MAIN"), (double)trade.ResultOrder());
   GlobalVariableSet(GvKey("BAL"), AccountInfoDouble(ACCOUNT_BALANCE));
   g_armed        = true;
   g_lastHedgeCnt = 0;
   g_plDirty      = true;
   PrintFormat("%s NAYA CYCLE: %s %.2f @ %s, TP %s, balance %.2f", EA_NAME, dir > 0 ? "BUY" : "SELL", lot,
               DoubleToString(price, _Digits), DoubleToString(tp, _Digits), AccountInfoDouble(ACCOUNT_BALANCE));
  }

void EnsureMainTP(const SPos &m, double dist)
  {
   double want = NormPrice(m.open + m.dir * dist);
   double ts   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(MathAbs(m.tp - want) <= ts * 0.5)
      return;
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk))
      return;
   double c = m.dir > 0 ? tk.bid : tk.ask;
   if(m.dir * (want - c) <= MinDist())
     {
      if(m.dir * (c - want) >= 0)
         ClosePos(m.ticket, "main TP (EA)");   // price TP ke paar ja chuka
      return;
     }
   trade.PositionModify(m.ticket, m.sl, want);
  }

//+------------------------------------------------------------------+
//| Hedge na ho: pending / market se hedge lagao                     |
//+------------------------------------------------------------------+
void ManageEntry(const SPos &m, double H, const MqlTick &tk)
  {
   int    hdir  = -m.dir;
   double o     = hdir > 0 ? tk.ask : tk.bid;            // hedge kis price par khulega
   double level = NormPrice(H + hdir * InpReentryGap);   // sell hedge: H - gap
   double hLot  = NormLot(m.vol * InpHedgeMult);
   ulong  pend  = FindPending();

   if(!g_armed && hdir * (H - o) > 0)
      g_armed = true;
   if(!g_armed)
     {
      if(pend > 0)
         DeletePendings();
      return;
     }

   if(hdir * (o - level) >= 0)   // price level par / paar
     {
      if(pend > 0)
        {
         // pending server par bhar raha hai -> market se doosra hedge NAHI (duplicate fix)
         if(g_pendHitSince == 0)
            g_pendHitSince = TimeCurrent();
         if(TimeCurrent() - g_pendHitSince < 5)
            return;
         DeletePendings();   // 5 sec me nahi bhara -> hatao, agle tick par market (agar tab tak bhara nahi)
         g_pendHitSince = 0;
         return;
        }
      g_pendHitSince = 0;
      bool ok = hdir > 0 ? trade.Buy(hLot, _Symbol, 0, 0, 0, TAG_HEDGE)
                         : trade.Sell(hLot, _Symbol, 0, 0, 0, TAG_HEDGE);
      if(ok)
         PrintFormat("%s HEDGE (market) %s %.2f @ %s", EA_NAME, hdir > 0 ? "BUY" : "SELL", hLot, DoubleToString(o, _Digits));
      else
         PrintFormat("%s hedge fail: %u %s", EA_NAME, trade.ResultRetcode(), trade.ResultRetcodeDescription());
      g_plDirty = true;
      return;
     }

   g_pendHitSince = 0;
   if(pend > 0)
     {
      if(OrderSelect(pend) && MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - level) <= _Point)
         return;
      DeletePendings();
     }
   if(hdir * (level - o) > MinDist())
     {
      bool ok = hdir > 0 ? trade.BuyStop(hLot, level, _Symbol, 0, 0, ORDER_TIME_GTC, 0, TAG_HEDGE)
                         : trade.SellStop(hLot, level, _Symbol, 0, 0, ORDER_TIME_GTC, 0, TAG_HEDGE);
      if(!ok)
         PrintFormat("%s pending fail: %u %s", EA_NAME, trade.ResultRetcode(), trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Hedge khula: BE / lock / partial / backup SL                     |
//+------------------------------------------------------------------+
void ManageHedge(const SPos &h, const SPos &m, double lockDist, const MqlTick &tk)
  {
   double o = h.dir > 0 ? tk.ask : tk.bid;   // isi side par dobara khulta
   double c = h.dir > 0 ? tk.bid : tk.ask;   // isi par band hota
   string gv = GvKey("L" + (string)h.ticket);
   string gb = GvKey("B" + (string)h.ticket);
   double prof   = h.dir * (c - h.open);           // asli profit (spread ke baad)
   double bePx   = NormPrice(h.open + h.dir * InpBEPlus);
   bool   beOn   = GlobalVariableCheck(gb);

   // 1a. Hedge spread cover karke 0 ke upar -> asli 0-0 BE chalu
   if(!beOn && prof > InpBEPlus + MinDist())
     {
      GlobalVariableSet(gb, 1);
      beOn = true;
     }
   if(beOn)
     {
      // price wapas entry par -> bilkul 0-0 band (server SL bhi yahi hai)
      if(prof <= InpBEPlus)
        {
         ClosePos(h.ticket, "hedge BE 0-0");
         return;
        }
      // server SL = entry (EA / VPS band ho tab bhi 0-0)
      if((h.sl == 0 || h.dir * (bePx - h.sl) > _Point * 0.5) && h.dir * (c - bePx) > MinDist())
         trade.PositionModify(h.ticket, bePx, 0);
     }
   // 1b. Kabhi 0 tak nahi pahuncha aur ulta gaya -> spread jitne loss par band
   else
      if(h.dir * (h.open - o) > InpBEBuffer + _Point * 0.5)
        {
         ClosePos(h.ticket, "hedge BE (spread)");
         return;
        }

   // 2. Lock + partial (sirf jab hedge main se bada ho, jaise 0.02 vs 0.01)
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double excess = h.vol - m.vol;
   if(excess >= step * 0.5 && lockDist > 0)
     {
      bool   locked = GlobalVariableCheck(gv);
      if(!locked && prof >= lockDist)
        {
         GlobalVariableSet(gv, 1);
         PrintFormat("%s LOCK #%I64u (%.2f profit)", EA_NAME, h.ticket, h.pl);
        }
      else
         if(locked && prof <= lockDist)
           {
            if(trade.PositionClosePartial(h.ticket, NormLot(excess)))
              {
               GlobalVariableDel(gv);
               PrintFormat("%s PARTIAL #%I64u %.2f band, %.2f hedge bacha", EA_NAME, h.ticket, NormLot(excess), m.vol);
              }
            else
               PrintFormat("%s partial fail: %u %s", EA_NAME, trade.ResultRetcode(), trade.ResultRetcodeDescription());
            g_plDirty = true;
            return;
           }
     }

   // 3. Backup SL server par (EA / VPS band ho tab bhi bada loss nahi)
   if(InpBackupSL > 0 && h.sl == 0 && !beOn)
     {
      double spr = tk.ask - tk.bid;
      double sl  = NormPrice(h.open - h.dir * (spr + InpBackupSL));
      if(h.dir * (c - sl) > MinDist())
         trade.PositionModify(h.ticket, sl, 0);
     }
  }

//+------------------------------------------------------------------+
void Process()
  {
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk) || tk.bid <= 0)
      return;
   UpdateDay();

   SPos   m;
   SPos   hed[];
   bool   hasMain  = false;
   double floating = 0;
   int    nh = ScanPositions(m, hasMain, hed, floating);

   if(!hasMain)
     {
      g_lastHedgeCnt = 0;
      if(nh > 0)
        {
         CloseAll("main band -> hedge bhi band");
         return;
        }
      DeletePendings();
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
      // cycle band (ya EA laga) us candle me naya trade nahi - agli nayi candle ka intezaar
      datetime bar0 = iTime(_Symbol, InpSTTF, 0);
      datetime wait = MathMax(LastCloseTime(), g_initTime);
      if(bar0 == 0 || bar0 <= wait)
        {
         g_status = "Nayi " + EnumToString(InpSTTF) + " candle ka intezaar";
         return;
        }
      int d = SupertrendDir();
      if(d == 0)
        {
         g_status = "Supertrend data ka intezaar";
         return;
        }
      OpenMain(d);
      return;
     }

   double lot1     = m.vol;
   double tpDist   = MoneyToDist(InpTPMoney, lot1);
   double H        = NormPrice(m.open - m.dir * InpHedgeGap);
   double closedPL = CycleStats(m.timeMsc, m.ticket, g_partials, g_whipsaws);
   double cyclePL  = closedPL + floating;
   bool   partLimit = (InpMaxPartials >= 0 && g_partials >= InpMaxPartials);
   bool   wsLimit   = (InpMaxWhipsaw >= 0 && g_whipsaws >= InpMaxWhipsaw);

   // Max DD
   if(InpMaxDD > 0 && cyclePL <= -InpMaxDD)
     {
      CloseAll("MAX DD");
      GlobalVariableSet(GvKey("STOP"), (double)g_dayStart);
      return;
     }
   // Cycle ka kul +$1 (balance 100 -> 101) ya main + hedge floating +$1 -> sab band
   if(cyclePL >= InpTPMoney && (nh > 0 || cyclePL > floating))
     {
      CloseAll(StringFormat("CYCLE +%.2f", cyclePL));
      return;
     }
   if(nh > 0 && floating >= InpTPMoney)
     {
      CloseAll(StringFormat("BASKET +%.2f", floating));
      return;
     }
   // 0-0 exit: partial limit pura ho chuka, cycle ka kul 0 ya plus -> sab band
   if(partLimit && cyclePL >= 0)
     {
      CloseAll(StringFormat("0-0 EXIT (%d partial) %+.2f", g_partials, cyclePL));
      return;
     }

   // Main TP cycle ke hisaab se: main ko utna kamana hai jitne se cycle ka kul +$1 bane
   double need   = InpTPMoney - closedPL;
   double mainTP = MoneyToDist(MathMax(need, 0.01), lot1);
   EnsureMainTP(m, MathMax(mainTP, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)));

   if(nh > 0)
     {
      DeletePendings();
      for(int i = 0; i < nh; i++)
         ManageHedge(hed[i], m, tpDist, tk);
      g_status = StringFormat("HEDGE chalu (%d)", nh);
     }
   else
     {
      if(g_lastHedgeCnt > 0)
         g_armed = false;   // hedge abhi band hua -> price level ke peeche jaaye tab dobara
      if(partLimit || wsLimit)
        {
         DeletePendings();
         g_status = partLimit ? StringFormat("PARTIAL LIMIT (%d) pura - 0-0 / main TP ka intezaar", g_partials)
                              : StringFormat("WHIPSAW LIMIT (%d) pura - main TP ka intezaar", g_whipsaws);
        }
      else
        {
         ManageEntry(m, H, tk);
         g_status = g_armed ? "Hedge level ka intezaar" : "BE ke baad, price wapas aane ka intezaar";
        }
     }
   g_lastHedgeCnt = nh;
  }

//+------------------------------------------------------------------+
//| PANEL - PERSONAL FX jaisa (amber terminal, 3 column, DPI-aware)  |
//|  [1] CYCLE          | [2] ACCOUNT        | [4] SETTINGS          |
//|                     | [3] RISK CONTROL   | [5] RECENT CLOSES     |
//+------------------------------------------------------------------+
int    SC(int v) { return (int)MathRound(v * g_S); }

string DotPad(string label, int n)
  {
   string r = label + " ";
   while(StringLen(r) < n)
      r += ".";
   return r;
  }

string Money(double v) { return (v >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(v), 2); }

string IstTime(datetime srv)
  {
   return TimeToString(srv - (TimeTradeServer() - TimeGMT()) + 19800, TIME_MINUTES);
  }

void Rect(string n, int x, int y, int w, int h, color c)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, c);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_BACK, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void Lbl(string n, string t, int x, int y, color c, int f)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, f);
   ObjectSetString(0, n, OBJPROP_FONT, QFONT);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void LblR(string n, string t, int x, int y, color c, int f)
  {
   Lbl(n, t, x, y, c, f);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
  }

void Btn(string n, string t, int x, int y, int w, int h, color bg, color fg, int f)
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
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, f);
   ObjectSetString(0, n, OBJPROP_FONT, QFONT);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

void OutBtn(string inner, string txt, int x, int y, int w, int h, color border, color fg, int fsz)
  {
   int b = MathMax(2, SC(2));
   Rect(PNL + "BR_" + inner, x, y, w, h, border);
   Btn(PNL + inner, txt, x + b, y + b, w - 2 * b, h - 2 * b, QT_DARKBTN, fg, fsz);
  }

void Sect(string n, string txt, int colx, int y)
  {
   Rect(PNL + "S_" + n, colx, y, g_CW, SC(24), QT_SECT);
   Lbl(PNL + "SL_" + n, txt, colx + SC(8), y + SC(4), QT_AMBER, InpPanelFont);
  }

void MakeRow(string id, string label, int colx, int y)
  {
   Lbl(PNL + id + "_L", DotPad(label, g_LabChars), colx + SC(10), y, QT_AMBERD, InpPanelFont);
   Lbl(PNL + id + "_V", "--", colx + g_ValX, y, QT_WHITE, InpPanelFont);
  }

void SetV(string id, string txt, color c)
  {
   ObjectSetString(0, PNL + id + "_V", OBJPROP_TEXT, txt);
   ObjectSetInteger(0, PNL + id + "_V", OBJPROP_COLOR, c);
  }

void BuildPanel()
  {
   if(!InpShowPanel)
      return;
   int x = InpPanelX, y = InpPanelY, fs = InpPanelFont;
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   int PW  = MathMax(SC(760), chartW - 2 * InpPanelX);
   int gap = SC(8);
   int cw  = (PW - 2 * SC(8) - 2 * gap) / 3;
   g_CW = cw;
   int c1 = x + SC(8), c2 = c1 + cw + gap, c3 = c2 + cw + gap;
   int RH = SC(fs * 2 + 4), SH = SC(24);

   int charW = (int)MathRound(fs * 96.0 / 72.0 * g_DpiS * 0.55);
   if(charW < 6)
      charW = 6;
   int avail = (cw - SC(20)) / charW;
   g_LabChars = MathMax(14, MathMin(20, avail - 18));
   g_ValX     = SC(10) + (g_LabChars + 1) * charW;

   Rect(PNL + "BG", x, y, PW, 100, QT_BG);
   Rect(PNL + "B1", x, y, PW, 2, QT_BORDER);
   Rect(PNL + "TBG", x, y, PW, SC(32), QT_AMBER);
   Lbl(PNL + "TITLE", StringFormat("%s %s  |  M5 SUPERTREND + %.0fx HEDGE  |  $%.2f TP  |  CYCLE +$%.2f",
                                   EA_NAME, EA_VER, InpHedgeMult, InpTPMoney, InpTPMoney),
       x + SC(12), y + SC(7), C'0,0,0', fs + 1);
   LblR(PNL + "TITLE_R", "MAGIC " + IntegerToString(InpMagic), x + PW - SC(12), y + SC(8), C'0,0,0', fs);

   // status bar (poori chaudai)
   int ys = y + SC(36);
   Rect(PNL + "STB", x + SC(8), ys, PW - SC(16), SC(26), QT_DARKBTN);
   Lbl(PNL + "STL", "STATUS >", x + SC(16), ys + SC(5), QT_AMBERD, fs);
   Lbl(PNL + "STV", "--", x + SC(16) + 9 * charW, ys + SC(5), QT_GREEN, fs);
   int y0 = ys + SC(34);

   // ---- column 1 ----
   int yy = y0;
   Sect("CY", "[1] CYCLE", c1, yy);
   yy += SH + SC(4);
   MakeRow("ST",  "SUPERTREND M5", c1, yy); yy += RH;
   MakeRow("MN",  "MAIN TRADE",    c1, yy); yy += RH;
   MakeRow("MT",  "MAIN TP",       c1, yy); yy += RH;
   MakeRow("HL",  "HEDGE LEVEL",   c1, yy); yy += RH;
   MakeRow("HG",  "HEDGE",         c1, yy); yy += RH;
   MakeRow("PC",  "PARTIAL",       c1, yy); yy += RH;
   MakeRow("WS",  "WHIPSAW",       c1, yy); yy += RH;
   MakeRow("SB",  "START BALANCE", c1, yy); yy += RH;
   MakeRow("CP",  "CYCLE P&L",     c1, yy); yy += RH;
   int bottom1 = yy;

   // ---- column 2 ----
   yy = y0;
   Sect("AC", "[2] ACCOUNT", c2, yy);
   yy += SH + SC(4);
   MakeRow("BAL", "BALANCE",   c2, yy); yy += RH;
   MakeRow("EQ",  "EQUITY",    c2, yy); yy += RH;
   MakeRow("DPL", "DAILY P&L", c2, yy); yy += RH;
   MakeRow("FPL", "FLOAT P&L", c2, yy); yy += RH + SC(8);
   Sect("RC", "[3] RISK CONTROL", c2, yy);
   yy += SH + SC(4);
   MakeRow("DT",  "DAILY TARGET", c2, yy); yy += RH;
   MakeRow("DD",  "MAX DD",       c2, yy); yy += RH;
   MakeRow("NW",  "NEWS FILTER",  c2, yy); yy += RH;
   MakeRow("AL",  "ALGO TRADING", c2, yy); yy += RH;
   int bottom2 = yy;

   // ---- column 3 ----
   yy = y0;
   Sect("SE", "[4] SETTINGS", c3, yy);
   yy += SH + SC(4);
   MakeRow("LT",  "LOT / TP",    c3, yy); yy += RH;
   MakeRow("HS",  "HEDGE",       c3, yy); yy += RH;
   MakeRow("BE",  "BREAKEVEN",   c3, yy); yy += RH + SC(8);
   Sect("LG", "[5] RECENT CLOSES (IST)", c3, yy);
   yy += SH + SC(4);
   for(int i = 0; i < 5; i++)
     {
      string k = IntegerToString(i);
      Lbl(PNL + "LGT" + k, "--", c3 + SC(10), yy, QT_DOTS, fs - 1);
      Lbl(PNL + "LGX" + k, " ", c3 + SC(10) + 7 * charW, yy, QT_WHITE, fs - 1);
      Lbl(PNL + "LGP" + k, " ", c3 + SC(10) + 25 * charW, yy, QT_DOTS, fs - 1);
      yy += RH - SC(4);
     }
   yy += SC(6);
   int bw = (cw - SC(30)) / 2;
   OutBtn(BT_PAUSE, "PAUSE", c3 + SC(10), yy, bw, SC(32), QT_AMBER, QT_AMBER, fs);
   OutBtn(BT_CALL, "CLOSE ALL", c3 + SC(20) + bw, yy, bw, SC(32), QT_RED, QT_RED, fs);
   yy += SC(32) + SC(4);
   int bottom3 = yy;

   int bottom = MathMax(bottom1, MathMax(bottom2, bottom3));
   int PH = bottom - y + SC(10);
   Rect(PNL + "BG", x, y, PW, PH, QT_BG);
   Rect(PNL + "B2", x, y + PH - 2, PW, 2, QT_BORDER);
   Rect(PNL + "B3", x, y, 2, PH, QT_BORDER);
   Rect(PNL + "B4", x + PW - 2, y, 2, PH, QT_BORDER);
  }

void RebuildPanel()
  {
   ObjectsDeleteAll(0, PNL);
   BuildPanel();
   Panel();
  }

void Panel()
  {
   if(!InpShowPanel)
      return;
   if(ObjectFind(0, PNL + "BG") < 0)
      BuildPanel();
   SPos   m;
   SPos   hed[];
   bool   hasMain  = false;
   double floating = 0;
   int    nh = ScanPositions(m, hasMain, hed, floating);

   bool paused = IsPaused();
   ObjectSetString(0, PNL + "STV", OBJPROP_TEXT, paused ? "PAUSE (naya cycle nahi)" : g_status);
   ObjectSetInteger(0, PNL + "STV", OBJPROP_COLOR, paused ? QT_AMBER : QT_GREEN);

   SetV("ST", g_stDir > 0 ? "BUY  \x25B2" : (g_stDir < 0 ? "SELL \x25BC" : "--"),
        g_stDir > 0 ? QT_GREEN : (g_stDir < 0 ? QT_RED : QT_DOTS));
   if(hasMain)
     {
      int    pc = 0, ws = 0;
      double cyc = CycleStats(m.timeMsc, m.ticket, pc, ws) + floating;
      double bal = GlobalVariableCheck(GvKey("BAL")) ? GlobalVariableGet(GvKey("BAL")) : 0;
      SetV("MN", StringFormat("%s %.2f @ %s", m.dir > 0 ? "BUY" : "SELL", m.vol, DoubleToString(m.open, _Digits)),
           m.dir > 0 ? QT_GREEN : QT_RED);
      SetV("MT", m.tp > 0 ? DoubleToString(m.tp, _Digits) : "--", QT_WHITE);
      SetV("HL", DoubleToString(m.open - m.dir * InpHedgeGap, _Digits), QT_WHITE);
      if(nh > 0)
         SetV("HG", StringFormat("%s %.2f @ %s %s", hed[0].dir > 0 ? "BUY" : "SELL", hed[0].vol,
                                 DoubleToString(hed[0].open, _Digits), Money(hed[0].pl)),
              hed[0].pl >= 0 ? QT_GREEN : QT_RED);
      else
         SetV("HG", FindPending() > 0 ? "PENDING LAGA" : "--", FindPending() > 0 ? QT_AMBER : QT_DOTS);
      SetV("PC", StringFormat("%d / %d", pc, InpMaxPartials), pc >= InpMaxPartials && InpMaxPartials >= 0 ? QT_AMBER : QT_WHITE);
      SetV("WS", StringFormat("%d / %d", ws, InpMaxWhipsaw), ws >= InpMaxWhipsaw && InpMaxWhipsaw >= 0 ? QT_AMBER : QT_WHITE);
      SetV("SB", "$" + DoubleToString(bal, 2), QT_WHITE);
      SetV("CP", Money(cyc) + " / +$" + DoubleToString(InpTPMoney, 2), cyc >= 0 ? QT_GREEN : QT_RED);
     }
   else
     {
      string ids[] = {"MN", "MT", "HL", "HG", "PC", "WS", "SB", "CP"};
      for(int i = 0; i < ArraySize(ids); i++)
         SetV(ids[i], "--", QT_DOTS);
     }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   SetV("BAL", "$" + DoubleToString(balance, 2), QT_WHITE);
   SetV("EQ",  "$" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), QT_WHITE);
   SetV("DPL", Money(g_dayPL), g_dayPL >= 0 ? QT_GREEN : QT_RED);
   SetV("FPL", Money(floating), floating >= 0 ? QT_GREEN : QT_RED);
   if(InpDailyTarget > 0)
      SetV("DT", Money(MathMax(g_dayPL, 0)) + " / +$" + DoubleToString(InpDailyTarget, 2) + (g_dayPL >= InpDailyTarget ? "  PURA" : ""),
           g_dayPL >= InpDailyTarget ? QT_AMBER : QT_GREEN);
   else
      SetV("DT", "OFF", QT_AMBERD);
   SetV("DD", InpMaxDD > 0 ? "-$" + DoubleToString(InpMaxDD, 2) + (DayStopped() ? "  LAGA (aaj band)" : "") : "OFF",
        DayStopped() ? QT_RED : (InpMaxDD > 0 ? QT_WHITE : QT_AMBERD));
   string news;
   if(!InpNewsFilter)
      SetV("NW", "OFF", QT_AMBERD);
   else
      if(MQLInfoInteger(MQL_TESTER))
         SetV("NW", "TESTER ME NAHI", QT_AMBERD);
      else
         if(NewsBlocked(news))
            SetV("NW", "BLOCK " + news, QT_RED);
         else
            SetV("NW", StringFormat("CLEAR (%s +-%d/%d min)", InpNewsCcy, InpNewsBefore, InpNewsAfter), QT_GREEN);
   bool algo = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED);
   SetV("AL", algo ? "ON" : "OFF", algo ? QT_GREEN : QT_RED);

   SetV("LT", StringFormat("%.2f  /  $%.2f", InpLot, InpTPMoney), QT_WHITE);
   SetV("HS", StringFormat("%.2f @ $%.2f gap", NormLot(InpLot * InpHedgeMult), InpHedgeGap), QT_WHITE);
   SetV("BE", "ASLI 0-0 (server SL)", QT_GREEN);

   // recent closes: is EA ki aaj ki aakhri 5 band deals
   int shown = 0;
   ulong ours[];
   if(HistorySelect(g_dayStart - HIST_BACK, TimeCurrent() + 86400))
     {
      OurPosIds(ours);
      for(int i = HistoryDealsTotal() - 1; i >= 0 && shown < 5; i--)
        {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0 || !IsOurDeal(d, ours) || (datetime)HistoryDealGetInteger(d, DEAL_TIME) < g_dayStart)
            continue;
         long e = HistoryDealGetInteger(d, DEAL_ENTRY);
         if(e != DEAL_ENTRY_OUT && e != DEAL_ENTRY_OUT_BY)
            continue;
         double pl = HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
                     + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
         // band hone wali deal ulti side ki hoti hai (buy position = sell deal)
         string side = HistoryDealGetInteger(d, DEAL_TYPE) == DEAL_TYPE_SELL ? "BUY " : "SELL";
         string k = IntegerToString(shown);
         ObjectSetString(0, PNL + "LGT" + k, OBJPROP_TEXT, IstTime((datetime)HistoryDealGetInteger(d, DEAL_TIME)));
         ObjectSetString(0, PNL + "LGX" + k, OBJPROP_TEXT, side + " " + DoubleToString(HistoryDealGetDouble(d, DEAL_VOLUME), 2));
         ObjectSetString(0, PNL + "LGP" + k, OBJPROP_TEXT, Money(pl));
         ObjectSetInteger(0, PNL + "LGP" + k, OBJPROP_COLOR, pl >= 0 ? QT_GREEN : QT_RED);
         shown++;
        }
     }
   for(int i = shown; i < 5; i++)
     {
      string k = IntegerToString(i);
      ObjectSetString(0, PNL + "LGT" + k, OBJPROP_TEXT, "--");
      ObjectSetString(0, PNL + "LGX" + k, OBJPROP_TEXT, " ");
      ObjectSetString(0, PNL + "LGP" + k, OBJPROP_TEXT, " ");
     }

   ObjectSetString(0, PNL + BT_PAUSE, OBJPROP_TEXT, paused ? "RESUME" : "PAUSE");
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_COLOR, paused ? QT_GREEN : QT_AMBER);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Alert(EA_NAME, ": sirf HEDGING account par chalta hai (Buy + Sell saath).");
      return INIT_FAILED;
     }
   if(InpHedgeMult < 1.0 || InpHedgeGap <= 0 || InpTPMoney <= 0)
     {
      Alert(EA_NAME, ": inputs galat (hedge mult >= 1, gap > 0, TP > 0).");
      return INIT_PARAMETERS_INCORRECT;
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);
   g_armed        = true;
   g_lastHedgeCnt = 0;
   g_initTime     = TimeCurrent();
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi <= 0)
      dpi = 96;
   g_DpiS = dpi / 96.0;
   g_S    = (InpPanelScale > 0.0) ? InpPanelScale : g_DpiS;
   g_S    = MathMax(0.75, MathMin(3.0, g_S));
   Comment("");
   if(InpShowPanel)
      RebuildPanel();
   EventSetTimer(1);
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
   if(sp == PNL + BT_PAUSE)
     {
      GlobalVariableSet(GvKey("PAUSE"), IsPaused() ? 0 : 1);
      PrintFormat("%s %s", EA_NAME, IsPaused() ? "PAUSE - naya cycle nahi" : "RESUME");
     }
   if(sp == PNL + BT_CALL)
      CloseAll("CLOSE ALL button");
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   Panel();
  }

void OnTick()
  {
   Process();
  }

void OnTimer()
  {
   Panel();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
      g_plDirty = true;
  }
//+------------------------------------------------------------------+
