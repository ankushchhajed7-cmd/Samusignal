//+------------------------------------------------------------------+
//|                                   SUPERTREND GRID v2.00.mq5      |
//|              Ankush New Vision - M1 Supertrend + $10 grid basket |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
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
#property version     "2.00"
#property description "SUPERTREND GRID v2.00 - M1 Supertrend entry, har $10 par 0.01 grid (7 tak), basket +$2 par $1 lock + $1 trailing, Max DD $40, 5 min cooldown, din target balance ka 1%. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME   "SUPERTREND GRID"
#define EA_VER    "v2.00"
#define TAG_TRADE "STG_GRID"
#define GVP       "STG2_"
#define PNL       "STGP_"
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
input long   InpMagic        = 26102901;   // Magic number (hedge EA se alag)
input int    InpSlippage     = 30;         // Slippage (points)

input group "2. Supertrend"
input ENUM_TIMEFRAMES InpSTTF = PERIOD_M1; // Supertrend timeframe
input int    InpATRPeriod    = 10;         // ATR period
input double InpSTMult       = 3.0;        // Multiplier

input group "3. Grid"
input double InpLot          = 0.01;       // Har trade ka lot
input double InpGridGap      = 10.0;       // Grid gap (price, pehli entry se har itna ulta)
input int    InpMaxTrades    = 7;          // Max trade (pehla + grid)
input int    InpCooldownMin  = 5;          // Basket band hone ke baad cooldown (minute)

input group "4. Basket profit"
input double InpTrailStart   = 2.0;        // Basket itna $ profit -> lock chalu
input double InpLockMin      = 1.0;        // Kam se kam itna $ lock
input double InpTrailDist    = 1.0;        // Sabse unche profit se itna $ peeche lock

input group "5. Din / Safety"
input double InpDailyPct     = 1.0;        // Din ka target (din ki shuruaat ke balance ka %, 0 = off)
input double InpMaxDD        = 40.0;       // Max DD basket ($, 0 = off) -> sab band, aaj band
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
   return (AccountInfoDouble(ACCOUNT_BALANCE) - g_dayPL) * InpDailyPct / 100.0;
  }

bool DayBlocked()
  {
   if(DayStopped())
      return true;
   double t = DayTarget();
   return (t > 0 && g_dayPL >= t);
  }

//+------------------------------------------------------------------+
void OpenTrade(int dir, string why)
  {
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk))
      return;
   double lot   = NormLot(InpLot);
   double price = dir > 0 ? tk.ask : tk.bid;
   bool ok = dir > 0 ? trade.Buy(lot, _Symbol, 0, 0, 0, TAG_TRADE)
                     : trade.Sell(lot, _Symbol, 0, 0, 0, TAG_TRADE);
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
   if(peak < InpTrailStart)
      return;   // abhi lock chalu nahi

   double lock = MathMax(InpLockMin, peak - InpTrailDist);
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
      // basket band hone ke baad cooldown, phir nayi candle par (EA lagane ke baad bhi nayi candle)
      datetime lastClose = LastCloseTime();
      int      left      = (int)(lastClose + InpCooldownMin * 60 - TimeCurrent());
      if(lastClose > 0 && left > 0)
        {
         g_status = StringFormat("COOLDOWN %d:%02d", left / 60, left % 60);
         return;
        }
      datetime bar0 = iTime(_Symbol, InpSTTF, 0);
      if(bar0 == 0 || bar0 <= MathMax(lastClose, g_initTime))
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
      GlobalVariableSet(GvKey("BAL"), AccountInfoDouble(ACCOUNT_BALANCE));
      OpenTrade(d, "NAYA BASKET");
      return;
     }

   // Max DD
   if(InpMaxDD > 0 && floating <= -InpMaxDD)
     {
      CloseAll(StringFormat("MAX DD %.2f", floating));
      GlobalVariableSet(GvKey("STOP"), (double)g_dayStart);
      return;
     }

   ManageBasket(ps, n, floating, lots, tk);

   // grid: pehli entry se har InpGridGap ulta -> ek aur 0.01 (InpMaxTrades tak)
   int    fi  = FirstIdx(ps, n);
   int    dir = ps[fi].dir;
   double o   = dir > 0 ? tk.ask : tk.bid;
   double nextLvl = NormPrice(ps[fi].open - dir * InpGridGap * n);
   if(n < InpMaxTrades && dir * (nextLvl - o) >= 0)
     {
      // race guard: usi pal doosra add na ho
      double f2 = 0, l2 = 0;
      SPos   p2[];
      if(ScanPositions(p2, f2, l2) == n)
         OpenTrade(dir, StringFormat("GRID %d", n + 1));
     }

   double peak = GlobalVariableCheck(GvKey("PEAK")) ? GlobalVariableGet(GvKey("PEAK")) : 0;
   if(peak >= InpTrailStart)
      g_status = StringFormat("PROFIT LOCK +%.2f (peak %.2f)", MathMax(InpLockMin, peak - InpTrailDist), peak);
   else
      if(n >= InpMaxTrades)
         g_status = StringFormat("GRID PURA (%d) - basket profit ka intezaar", n);
      else
         g_status = StringFormat("BASKET %d trade - agla grid %s", n, DoubleToString(nextLvl, _Digits));
  }


//+------------------------------------------------------------------+
//| PANEL - PERSONAL FX jaisa (amber terminal, 3 column, DPI-aware)  |
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
   Lbl(PNL + "SL_" + n, txt, colx + SC(8), y + SC(4), QT_AMBER, g_FS);
  }

void MakeRow(string id, string label, int colx, int y)
  {
   Lbl(PNL + id + "_L", DotPad(label, g_LabChars), colx + SC(10), y, QT_AMBERD, g_FS);
   Lbl(PNL + id + "_V", "--", colx + g_ValX, y, QT_WHITE, g_FS);
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
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   // chart chhota ho to scale + font chhota karo taaki panel kate nahi
   g_S  = g_SBase;
   g_FS = InpPanelFont;
   double fit = (chartW - 2.0 * InpPanelX) / (760.0 * g_SBase);
   if(fit < 1.0)
     {
      fit  = MathMax(0.55, fit);
      g_S  = g_SBase * fit;
      g_FS = (int)MathMax(7, MathRound(InpPanelFont * fit));
     }
   int x = InpPanelX, y = InpPanelY, fs = g_FS;
   int PW  = MathMax(SC(760), chartW - 2 * InpPanelX);
   int gap = SC(8);
   int cw  = (PW - 2 * SC(8) - 2 * gap) / 3;
   g_CW = cw;
   int c1 = x + SC(8), c2 = c1 + cw + gap, c3 = c2 + cw + gap;
   int RH = SC(fs * 2 + 4), SH = SC(24);

   int charW = (int)MathRound(fs * 96.0 / 72.0 * g_DpiS * 0.55);   // font pt -> px (screen DPI)
   if(charW < 6)
      charW = 6;
   int avail = (cw - SC(20)) / charW;
   g_LabChars = MathMax(14, MathMin(20, avail - 18));
   g_ValX     = SC(10) + (g_LabChars + 1) * charW;

   Rect(PNL + "BG", x, y, PW, 100, QT_BG);
   Rect(PNL + "B1", x, y, PW, 2, QT_BORDER);
   Rect(PNL + "TBG", x, y, PW, SC(32), QT_AMBER);
   Lbl(PNL + "TITLE", StringFormat("%s %s  |  M1 SUPERTREND + $%.0f GRID x%d  |  LOCK $%.0f @ +$%.0f, TRAIL $%.0f",
                                   EA_NAME, EA_VER, InpGridGap, InpMaxTrades, InpLockMin, InpTrailStart, InpTrailDist),
       x + SC(12), y + SC(7), C'0,0,0', fs + 1);
   LblR(PNL + "TITLE_R", "MAGIC " + IntegerToString(InpMagic), x + PW - SC(12), y + SC(8), C'0,0,0', fs);

   // status bar (poori chaudai)
   int ys = y + SC(36);
   Rect(PNL + "STB", x + SC(8), ys, PW - SC(16), SC(34), QT_DARKBTN);
   Lbl(PNL + "STL", "STATUS >", x + SC(16), ys + SC(9), QT_AMBERD, fs);
   Lbl(PNL + "STV", "--", x + SC(16) + 9 * charW, ys + SC(9), QT_GREEN, fs);
   // buttons status patti me daayein - chhote chart par bhi hamesha dikhen
   int bw = 12 * charW;
   OutBtn(BT_CALL,  "CLOSE ALL", x + PW - SC(12) - bw,          ys + SC(2), bw, SC(30), QT_RED,   QT_RED,   fs);
   OutBtn(BT_PAUSE, "PAUSE",     x + PW - SC(12) - 2 * bw - SC(8), ys + SC(2), bw, SC(30), QT_AMBER, QT_AMBER, fs);
   int y0 = ys + SC(42);

   // ---- column 1 ----
   int yy = y0;
   Sect("CY", "[1] BASKET", c1, yy);
   yy += SH + SC(4);
   MakeRow("ST",  "SUPERTREND",    c1, yy); yy += RH;
   MakeRow("BD",  "DISHA",         c1, yy); yy += RH;
   MakeRow("TR",  "TRADE",         c1, yy); yy += RH;
   MakeRow("AV",  "AVG PRICE",     c1, yy); yy += RH;
   MakeRow("NG",  "AGLA GRID",     c1, yy); yy += RH;
   MakeRow("PK",  "PEAK / LOCK",   c1, yy); yy += RH;
   MakeRow("BP",  "BASKET P&L",    c1, yy); yy += RH;
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
   MakeRow("LT",  "LOT / GAP",   c3, yy); yy += RH;
   MakeRow("MX",  "MAX TRADE",   c3, yy); yy += RH;
   MakeRow("CD",  "COOLDOWN",    c3, yy); yy += RH + SC(8);
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
   SPos   ps[];
   double floating = 0, lots = 0;
   int    n = ScanPositions(ps, floating, lots);

   bool paused = IsPaused();
   ObjectSetString(0, PNL + "STV", OBJPROP_TEXT, paused ? "PAUSE (naya basket nahi)" : g_status);
   ObjectSetInteger(0, PNL + "STV", OBJPROP_COLOR, paused ? QT_AMBER : QT_GREEN);

   SetV("ST", EnumToString(InpSTTF) + (g_stDir > 0 ? "  BUY \x25B2" : (g_stDir < 0 ? "  SELL \x25BC" : "  --")),
        g_stDir > 0 ? QT_GREEN : (g_stDir < 0 ? QT_RED : QT_DOTS));
   if(n > 0)
     {
      int    fi  = FirstIdx(ps, n);
      int    dir = ps[fi].dir;
      double avg = 0;
      for(int i = 0; i < n; i++)
         avg += ps[i].open * ps[i].vol;
      avg /= lots;
      double peak = GlobalVariableCheck(GvKey("PEAK")) ? GlobalVariableGet(GvKey("PEAK")) : 0;
      SetV("BD", dir > 0 ? "BUY" : "SELL", dir > 0 ? QT_GREEN : QT_RED);
      SetV("TR", StringFormat("%d / %d  (%.2f lot)", n, InpMaxTrades, lots), n >= InpMaxTrades ? QT_AMBER : QT_WHITE);
      SetV("AV", DoubleToString(avg, _Digits), QT_WHITE);
      SetV("NG", n >= InpMaxTrades ? "GRID PURA" : DoubleToString(ps[fi].open - dir * InpGridGap * n, _Digits),
           n >= InpMaxTrades ? QT_AMBER : QT_WHITE);
      SetV("PK", peak >= InpTrailStart ? StringFormat("%s / lock %s", Money(peak), Money(MathMax(InpLockMin, peak - InpTrailDist)))
                                       : StringFormat("lock +$%.2f par chalu", InpTrailStart),
           peak >= InpTrailStart ? QT_GREEN : QT_AMBERD);
      SetV("BP", Money(floating), floating >= 0 ? QT_GREEN : QT_RED);
     }
   else
     {
      string ids[] = {"BD", "TR", "AV", "NG", "PK", "BP"};
      for(int i = 0; i < ArraySize(ids); i++)
         SetV(ids[i], "--", QT_DOTS);
     }

   SetV("BAL", "$" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), QT_WHITE);
   SetV("EQ",  "$" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), QT_WHITE);
   SetV("DPL", Money(g_dayPL), g_dayPL >= 0 ? QT_GREEN : QT_RED);
   SetV("FPL", Money(floating), floating >= 0 ? QT_GREEN : QT_RED);
   double dt = DayTarget();
   if(dt > 0)
      SetV("DT", Money(MathMax(g_dayPL, 0)) + " / +$" + DoubleToString(dt, 2) + StringFormat(" (%.1f%%)", InpDailyPct)
           + (g_dayPL >= dt ? "  PURA" : ""), g_dayPL >= dt ? QT_AMBER : QT_GREEN);
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

   SetV("LT", StringFormat("%.2f  /  $%.2f", InpLot, InpGridGap), QT_WHITE);
   SetV("MX", IntegerToString(InpMaxTrades), QT_WHITE);
   SetV("CD", IntegerToString(InpCooldownMin) + " min", QT_WHITE);

   // recent closes: is EA ki aaj ki aakhri 5 band deals (manual close bhi)
   int   shown = 0;
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

   bool hold = paused || DayStopped();
   ObjectSetString(0, PNL + BT_PAUSE, OBJPROP_TEXT, hold ? "RESUME" : "PAUSE");
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_COLOR, hold ? QT_GREEN : QT_AMBER);
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
