//+------------------------------------------------------------------+
//|                                   SUPERTREND HEDGE v1.01.mq5     |
//|                 Ankush New Vision - Supertrend + 2x hedge cycle  |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.01 (28-Oct-2026) - Ankush ke 3 badlav:                         |
//|  1. Main TP ab CYCLE ke hisaab se: TP wahan jahan cycle ka kul    |
//|     +$1 bane (pehle ke partial / BE ka hisaab jod kar). Pehle BE  |
//|     ke spread loss se cycle minus me band ho sakta tha            |
//|  2. Re-entry max 3: pehla hedge + 3 baar dobara (kul 4). Uske    |
//|     baad is cycle me naya hedge nahi                              |
//|  3. News filter: USD HIGH impact news se 30 min pehle / 30 min   |
//|     baad naya cycle nahi (MT5 calendar; Strategy Tester me        |
//|     calendar nahi chalta). Chalu cycle chalta rahega              |
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
#property version     "1.01"
#property description "SUPERTREND HEDGE v1.01 - M5 Supertrend main trade (cycle +$1 TP), news filter, max 3 re-entry, 2x hedge, profit lock + partial close, breakeven re-entry, cycle +$1 close, daily target. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME   "SUPERTREND HEDGE"
#define EA_VER    "v1.01"
#define TAG_MAIN  "STH_MAIN"
#define TAG_HEDGE "STH_HEDGE"
#define GVP       "STH1_"

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
input double InpBEBuffer     = 0.0;        // BE close buffer (price, 0 = turant)
input double InpBackupSL     = 0.50;       // Hedge backup SL server par (price, 0 = off)
input int    InpMaxReentry   = 3;          // Max re-entry per cycle (pehle hedge ke baad, -1 = no limit)

input group "4. Din / Safety"
input double InpDailyTarget  = 5.0;        // Din ka target ($, 0 = off)
input double InpMaxDD        = 0.0;        // Max DD cycle ($, 0 = off) -> sab band, aaj band
input bool   InpShowPanel    = true;       // Chart panel

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
int      g_hedgeIns     = 0;

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
double ClosedPL(long fromMsc)
  {
   double pl = 0;
   if(!HistorySelect((datetime)(fromMsc / 1000), TimeCurrent() + 86400))
      return 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(d, DEAL_TIME_MSC) < fromMsc)   // pichhle cycle ke deal nahi
         continue;
      pl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
            + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   return pl;
  }

// cycle ka band P/L + kitni baar hedge khula (main ke alawa IN deals)
double CycleStats(long fromMsc, ulong mainTicket, int &hedgeIns)
  {
   double pl = 0;
   hedgeIns = 0;
   if(!HistorySelect((datetime)(fromMsc / 1000), TimeCurrent() + 86400))
      return 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(d, DEAL_TIME_MSC) < fromMsc)
         continue;
      pl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
            + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
      if(HistoryDealGetInteger(d, DEAL_ENTRY) == DEAL_ENTRY_IN && (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID) != mainTicket)
         hedgeIns++;
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
         info = g_newsNames[i] + " @ " + TimeToString(g_newsTimes[i], TIME_MINUTES);
         return true;
        }
   return false;
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

   if(hdir * (o - level) >= 0)   // price level par / paar -> market se hedge
     {
      if(pend > 0)
         DeletePendings();
      bool ok = hdir > 0 ? trade.Buy(hLot, _Symbol, 0, 0, 0, TAG_HEDGE)
                         : trade.Sell(hLot, _Symbol, 0, 0, 0, TAG_HEDGE);
      if(ok)
         PrintFormat("%s HEDGE (market) %s %.2f @ %s", EA_NAME, hdir > 0 ? "BUY" : "SELL", hLot, DoubleToString(o, _Digits));
      else
         PrintFormat("%s hedge fail: %u %s", EA_NAME, trade.ResultRetcode(), trade.ResultRetcodeDescription());
      g_plDirty = true;
      return;
     }

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

   // 1. BE: price entry se ulta gaya -> no profit no loss (sirf spread)
   if(h.dir * (h.open - o) > InpBEBuffer + _Point * 0.5)
     {
      ClosePos(h.ticket, "hedge BE");
      return;
     }

   // 2. Lock + partial (sirf jab hedge main se bada ho, jaise 0.02 vs 0.01)
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double excess = h.vol - m.vol;
   if(excess >= step * 0.5 && lockDist > 0)
     {
      double prof   = h.dir * (c - h.open);
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
   if(InpBackupSL > 0 && h.sl == 0)
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
   double closedPL = CycleStats(m.timeMsc, m.ticket, g_hedgeIns);
   double cyclePL  = closedPL + floating;

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
      if(InpMaxReentry >= 0 && g_hedgeIns >= 1 + InpMaxReentry)
        {
         DeletePendings();
         g_status = StringFormat("RE-ENTRY LIMIT (%d) pura - main TP ka intezaar", InpMaxReentry);
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
void Panel()
  {
   if(!InpShowPanel)
      return;
   SPos   m;
   SPos   hed[];
   bool   hasMain  = false;
   double floating = 0;
   int    nh = ScanPositions(m, hasMain, hed, floating);
   string s = StringFormat("%s %s  |  Magic %I64d\n", EA_NAME, EA_VER, InpMagic);
   s += StringFormat("Supertrend %s : %s\n", EnumToString(InpSTTF), g_stDir > 0 ? "BUY" : (g_stDir < 0 ? "SELL" : "-"));
   s += "Status : " + g_status + "\n";
   if(hasMain)
     {
      int    ins = 0;
      double cyc = CycleStats(m.timeMsc, m.ticket, ins) + floating;
      double bal = GlobalVariableCheck(GvKey("BAL")) ? GlobalVariableGet(GvKey("BAL")) : 0;
      s += StringFormat("Main : %s %.2f @ %s  TP %s\n", m.dir > 0 ? "BUY" : "SELL", m.vol,
                        DoubleToString(m.open, _Digits), DoubleToString(m.tp, _Digits));
      s += StringFormat("Hedge level : %s  |  hedge khule %d  |  re-entry %d / %d\n",
                        DoubleToString(m.open - m.dir * InpHedgeGap, _Digits), nh, MathMax(ins - 1, 0), InpMaxReentry);
      s += StringFormat("Cycle start balance %.2f  |  cycle P/L %.2f (target +%.2f)\n", bal, cyc, InpTPMoney);
      s += StringFormat("Floating %.2f\n", floating);
     }
   s += StringFormat("Aaj ka P/L %.2f / target %.2f\n", g_dayPL, InpDailyTarget);
   string news;
   s += "News filter : " + (!InpNewsFilter ? "OFF" : (MQLInfoInteger(MQL_TESTER) ? "tester me nahi" : (NewsBlocked(news) ? "BLOCK - " + news : "clear")));
   Comment(s);
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
   EventSetTimer(1);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
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
