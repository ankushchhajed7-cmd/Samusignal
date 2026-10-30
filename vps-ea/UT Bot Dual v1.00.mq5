//+------------------------------------------------------------------+
//|                                        UT Bot Dual v1.00.mq5     |
//|                                        Ankush New Vision         |
//+------------------------------------------------------------------+
//  CHANGELOG
//  v1.00 (2026-10-30)
//   - First build. Idea from Trade4Wealth video "UT Bot Indicator"
//   - UT Bot Alerts (QuantNomad) logic, 2 copies:
//       BUY  copy : Key Value 4 , ATR Period 300  -> only BUY signals
//       SELL copy : Key Value 6 , ATR Period 1    -> only SELL signals
//   - Multi-pair: one chart runs all pairs in the list (auto suffix)
//   - Exit = fixed SL/TP only (Money $ mode or Pips mode)
//   - Optional filters (default OFF): EMA trend, ADX, session time
//   - Safety: max total trades, max spread, daily max loss
//   - Signals only on CLOSED candle (no repaint)
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "UT Bot Dual - Buy copy (4/300) + Sell copy (6/1), multi-pair, fixed SL/TP"

#include <Trade/Trade.mqh>

enum ENUM_SLTP_MODE
  {
   SLTP_MONEY = 0, // Money ($ per trade)
   SLTP_PIPS  = 1  // Pips
  };

//==================== INPUTS ====================
input group "=== Pairs ==="
input string          InpSymbols  = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,USDCHF,NZDUSD,EURJPY,GBPJPY,XAUUSD"; // Pairs (comma separated, without suffix)
input string          InpSuffix   = "auto";     // Suffix: auto = from chart symbol | blank = none | e.g. m
input ENUM_TIMEFRAMES InpTF       = PERIOD_M5;  // Signal timeframe

input group "=== UT Bot BUY copy ==="
input bool   InpTradeBuy = true;   // Take BUY trades
input double InpBuyKey   = 4.0;    // BUY Key Value (sensitivity)
input int    InpBuyATR   = 300;    // BUY ATR Period

input group "=== UT Bot SELL copy ==="
input bool   InpTradeSell = true;  // Take SELL trades
input double InpSellKey   = 6.0;   // SELL Key Value (sensitivity)
input int    InpSellATR   = 1;     // SELL ATR Period

input group "=== UT Bot common ==="
input bool   InpHeikin    = false; // Signals from Heikin Ashi candles
input int    InpCalcBars  = 2000;  // Bars used for calculation

input group "=== Trade / SL TP ==="
input double         InpLot          = 0.01;       // Lot size
input ENUM_SLTP_MODE InpSLTPMode     = SLTP_MONEY; // SL/TP mode
input double         InpSLMoney      = 2.0;        // SL in $ (Money mode)
input double         InpTPMoney      = 3.0;        // TP in $ (Money mode)
input double         InpSLPips       = 20;         // SL in pips (Pips mode)
input double         InpTPPips       = 30;         // TP in pips (Pips mode)
input bool           InpOnePerSymbol = true;       // Only 1 open trade per pair (false = 1 per direction)
input int            InpMaxTotal     = 10;         // Max total open trades (all pairs)
input int            InpMaxSpreadPts = 0;          // Max spread in points (0 = off)
input long           InpMagic        = 2610301;    // Magic number
input int            InpSlippage     = 30;         // Slippage (points)

input group "=== Filters (default OFF) ==="
input bool   InpUseEMA     = false; // EMA trend filter (BUY above EMA, SELL below)
input int    InpEMAPeriod  = 200;   // EMA period
input bool   InpUseADX     = false; // ADX filter (trade only if ADX >= min)
input int    InpADXPeriod  = 14;    // ADX period
input double InpADXMin     = 20;    // ADX minimum
input bool   InpUseSession = false; // Session filter (server time)
input int    InpStartHour  = 8;     // Session start hour
input int    InpEndHour    = 20;    // Session end hour

input group "=== Safety ==="
input double InpDailyMaxLoss = 0;   // Daily max loss $ (0 = off) - stops NEW trades for the day

//==================== GLOBALS ====================
CTrade   g_trade;
string   g_sym[];
datetime g_lastBar[];
int      g_adxHandle[];
string   g_lastSig[];
int      g_n = 0;

//+------------------------------------------------------------------+
string Trim(string s)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
  }

//+------------------------------------------------------------------+
bool TryResolve(const string cand, string &out)
  {
   if(cand == "")
      return false;
   bool isCustom = false;
   if(!SymbolExist(cand, isCustom))
      return false;
   if(!SymbolSelect(cand, true))
      return false;
   out = cand;
   return true;
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpBuyATR < 1 || InpSellATR < 1)
     {
      Print("ATR Period must be >= 1");
      return INIT_PARAMETERS_INCORRECT;
     }

   string suf = InpSuffix;
   if(suf == "auto")
      suf = (StringLen(_Symbol) > 6) ? StringSubstr(_Symbol, 6) : "";

   string parts[];
   int cnt = StringSplit(InpSymbols, ',', parts);
   ArrayResize(g_sym, 0);
   g_n = 0;

   for(int i = 0; i < cnt; i++)
     {
      string base = Trim(parts[i]);
      if(base == "")
         continue;
      string found = "";
      if(!TryResolve(base + suf, found))
         if(!TryResolve(base, found))
            if(!TryResolve(base + "m", found))
              {
               Print("Pair not found on this broker, skipped: ", base);
               continue;
              }
      // avoid duplicates
      bool dup = false;
      for(int k = 0; k < g_n; k++)
         if(g_sym[k] == found)
            dup = true;
      if(dup)
         continue;

      ArrayResize(g_sym, g_n + 1);
      g_sym[g_n] = found;
      g_n++;
     }

   if(g_n == 0)
     {
      Print("No valid pairs. Check InpSymbols / InpSuffix.");
      return INIT_FAILED;
     }

   ArrayResize(g_lastBar, g_n);
   ArrayResize(g_adxHandle, g_n);
   ArrayResize(g_lastSig, g_n);
   for(int s = 0; s < g_n; s++)
     {
      g_lastBar[s]   = 0;
      g_lastSig[s]   = "-";
      g_adxHandle[s] = INVALID_HANDLE;
      if(InpUseADX)
        {
         g_adxHandle[s] = iADX(g_sym[s], InpTF, InpADXPeriod);
         if(g_adxHandle[s] == INVALID_HANDLE)
            Print("ADX handle failed for ", g_sym[s]);
        }
     }

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippage);

   string list = "";
   for(int s = 0; s < g_n; s++)
      list += g_sym[s] + " ";
   Print("UT Bot Dual v1.00 started. Pairs (", g_n, "): ", list);

   EventSetTimer(1);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   for(int s = 0; s < g_n; s++)
      if(g_adxHandle[s] != INVALID_HANDLE)
         IndicatorRelease(g_adxHandle[s]);
   Comment("");
  }

void OnTick()  { ProcessAll(); }
void OnTimer() { ProcessAll(); }

//+------------------------------------------------------------------+
//| UT Bot (QuantNomad) on closed bars. r[] oldest -> newest          |
//| Returns buy / sell for the LAST closed bar                        |
//+------------------------------------------------------------------+
void UTSignal(const MqlRates &r[], const double &src[], const int cnt,
              const double key, const int len, bool &buy, bool &sell)
  {
   buy = false;
   sell = false;
   if(cnt < len + 3)
      return;

   double ts[];
   ArrayResize(ts, cnt);
   ArrayInitialize(ts, 0.0);

   double sum = 0.0, rma = 0.0;
   for(int i = 0; i < cnt; i++)
     {
      // True Range
      double tr;
      if(i == 0)
         tr = r[i].high - r[i].low;
      else
         tr = MathMax(r[i].high - r[i].low,
                      MathMax(MathAbs(r[i].high - r[i - 1].close),
                              MathAbs(r[i].low  - r[i - 1].close)));

      // ATR = RMA(TR, len) like Pine
      if(i < len)
        {
         sum += tr;
         if(i < len - 1)
           {
            ts[i] = 0.0;
            continue;
           }
         rma = sum / len;
        }
      else
         rma = (rma * (len - 1) + tr) / len;

      double nLoss = key * rma;
      double prev  = (i > 0) ? ts[i - 1] : 0.0;
      double s     = src[i];
      double sp    = (i > 0) ? src[i - 1] : 0.0;

      if(s > prev && sp > prev)
         ts[i] = MathMax(prev, s - nLoss);
      else if(s < prev && sp < prev)
         ts[i] = MathMin(prev, s + nLoss);
      else if(s > prev)
         ts[i] = s - nLoss;
      else
         ts[i] = s + nLoss;
     }

   int k = cnt - 1;
   // crossover(src, ts)  -> BUY
   buy  = (src[k] > ts[k]) && (src[k - 1] <= ts[k - 1]);
   // crossover(ts, src)  -> SELL
   sell = (src[k] < ts[k]) && (ts[k - 1] <= src[k - 1]);
  }

//+------------------------------------------------------------------+
double EMAlast(const MqlRates &r[], const int cnt, const int period)
  {
   if(cnt <= 0)
      return 0.0;
   double a = 2.0 / (period + 1.0);
   double e = r[0].close;
   for(int i = 1; i < cnt; i++)
      e = a * r[i].close + (1.0 - a) * e;
   return e;
  }

//+------------------------------------------------------------------+
//| returns false if data not ready                                   |
//+------------------------------------------------------------------+
bool GetSignals(const int s, bool &buy, bool &sell, double &lastClose, double &ema)
  {
   buy = false;
   sell = false;
   int maxLen = MathMax(InpBuyATR, InpSellATR);
   int need   = maxLen + 50;
   int want   = MathMax(InpCalcBars, need + 10);
   if(InpUseEMA)
      want = MathMax(want, InpEMAPeriod * 3);

   MqlRates r[];
   int cnt = CopyRates(g_sym[s], InpTF, 1, want, r);   // from shift 1 = closed bars only
   if(cnt < need)
      return false;

   double src[];
   ArrayResize(src, cnt);
   for(int i = 0; i < cnt; i++)
      src[i] = InpHeikin ? (r[i].open + r[i].high + r[i].low + r[i].close) / 4.0 : r[i].close;

   bool b1, s1, b2, s2;
   UTSignal(r, src, cnt, InpBuyKey,  InpBuyATR,  b1, s1);
   UTSignal(r, src, cnt, InpSellKey, InpSellATR, b2, s2);

   buy  = b1;   // BUY copy -> only BUY
   sell = s2;   // SELL copy -> only SELL

   lastClose = r[cnt - 1].close;
   ema = InpUseEMA ? EMAlast(r, cnt, InpEMAPeriod) : 0.0;
   return true;
  }

//+------------------------------------------------------------------+
int CountPos(const string sym, const int dir)  // sym "" = all, dir 0 = any, 1 buy, -1 sell
  {
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(sym != "" && PositionGetString(POSITION_SYMBOL) != sym)
         continue;
      if(dir != 0)
        {
         long type = PositionGetInteger(POSITION_TYPE);
         if(dir == 1 && type != POSITION_TYPE_BUY)
            continue;
         if(dir == -1 && type != POSITION_TYPE_SELL)
            continue;
        }
      c++;
     }
   return c;
  }

//+------------------------------------------------------------------+
double TodayPL()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   datetime dayStart = StructToTime(dt);

   double pl = 0.0;
   if(HistorySelect(dayStart, TimeCurrent() + 60))
     {
      int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0)
            continue;
         if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic)
            continue;
         pl += HistoryDealGetDouble(d, DEAL_PROFIT)
             + HistoryDealGetDouble(d, DEAL_SWAP)
             + HistoryDealGetDouble(d, DEAL_COMMISSION);
        }
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      pl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }
   return pl;
  }

//+------------------------------------------------------------------+
bool InSession()
  {
   if(!InpUseSession)
      return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(InpStartHour <= InpEndHour)
      return (h >= InpStartHour && h < InpEndHour);
   return (h >= InpStartHour || h < InpEndHour);   // overnight session
  }

//+------------------------------------------------------------------+
double NormLot(const string sym, double lot)
  {
   double mn = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(st <= 0)
      st = 0.01;
   lot = MathFloor(lot / st + 1e-9) * st;
   if(lot < mn)
      lot = mn;
   if(lot > mx)
      lot = mx;
   return NormalizeDouble(lot, 2);
  }

//+------------------------------------------------------------------+
double PipSize(const string sym)
  {
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    dig = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   if(StringFind(sym, "XAU") >= 0)
      return 0.1;                        // gold: 1 pip = 0.10
   if(dig == 3 || dig == 5)
      return pt * 10.0;
   return pt;
  }

//+------------------------------------------------------------------+
//| SL / TP distance in price                                         |
//+------------------------------------------------------------------+
bool CalcDist(const string sym, const double lots, double &slD, double &tpD)
  {
   if(InpSLTPMode == SLTP_PIPS)
     {
      double pip = PipSize(sym);
      slD = InpSLPips * pip;
      tpD = InpTPPips * pip;
     }
   else
     {
      double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(tv <= 0)
         tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
      double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
      if(tv <= 0 || ts <= 0 || lots <= 0)
         return false;
      double moneyPerPrice = tv / ts * lots;   // $ per 1.0 price move
      slD = InpSLMoney / moneyPerPrice;
      tpD = InpTPMoney / moneyPerPrice;
     }

   // respect broker minimum stop distance
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   long   stops  = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   long   spread = SymbolInfoInteger(sym, SYMBOL_SPREAD);
   double minD   = (stops + spread + 2) * pt;
   if(slD > 0 && slD < minD)
     {
      Print(sym, ": SL too close, widened to broker minimum");
      slD = minD;
     }
   if(tpD > 0 && tpD < minD)
     {
      Print(sym, ": TP too close, widened to broker minimum");
      tpD = minD;
     }
   return true;
  }

//+------------------------------------------------------------------+
void OpenTrade(const int s, const int dir)
  {
   string sym = g_sym[s];

   if(InpMaxSpreadPts > 0)
     {
      long sp = SymbolInfoInteger(sym, SYMBOL_SPREAD);
      if(sp > InpMaxSpreadPts)
        {
         Print(sym, ": spread ", sp, " > max ", InpMaxSpreadPts, ", skipped");
         return;
        }
     }

   double lots = NormLot(sym, InpLot);
   double slD = 0, tpD = 0;
   if(!CalcDist(sym, lots, slD, tpD))
     {
      Print(sym, ": cannot calculate SL/TP, skipped");
      return;
     }

   int    dig = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(ask <= 0 || bid <= 0)
      return;

   g_trade.SetTypeFillingBySymbol(sym);
   bool ok;
   if(dir == 1)
     {
      double sl = (slD > 0) ? NormalizeDouble(ask - slD, dig) : 0.0;
      double tp = (tpD > 0) ? NormalizeDouble(ask + tpD, dig) : 0.0;
      ok = g_trade.Buy(lots, sym, ask, sl, tp, "UTBotDual BUY");
     }
   else
     {
      double sl = (slD > 0) ? NormalizeDouble(bid + slD, dig) : 0.0;
      double tp = (tpD > 0) ? NormalizeDouble(bid - tpD, dig) : 0.0;
      ok = g_trade.Sell(lots, sym, bid, sl, tp, "UTBotDual SELL");
     }

   uint rc = g_trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED))
      Print(sym, ": order failed, code ", rc, " ", g_trade.ResultRetcodeDescription());
   else
      Print(sym, ": ", (dir == 1 ? "BUY" : "SELL"), " opened ", DoubleToString(lots, 2), " lot");
  }

//+------------------------------------------------------------------+
void TryTrade(const int s, const int dir, const double lastClose, const double ema, const bool dailyBlocked)
  {
   string sym = g_sym[s];

   if(dailyBlocked)
      return;
   if(dir == 1 && !InpTradeBuy)
      return;
   if(dir == -1 && !InpTradeSell)
      return;
   if(!InSession())
      return;

   if(InpUseEMA)
     {
      if(dir == 1 && !(lastClose > ema))
         return;
      if(dir == -1 && !(lastClose < ema))
         return;
     }

   if(InpUseADX)
     {
      if(g_adxHandle[s] == INVALID_HANDLE)
         return;
      double adx[];
      if(CopyBuffer(g_adxHandle[s], 0, 1, 1, adx) != 1)
        {
         Print(sym, ": ADX not ready, skipped");
         return;
        }
      if(adx[0] < InpADXMin)
         return;
     }

   if(CountPos("", 0) >= InpMaxTotal)
      return;
   if(InpOnePerSymbol)
     {
      if(CountPos(sym, 0) > 0)
         return;
     }
   else
     {
      if(CountPos(sym, dir) > 0)
         return;
     }

   OpenTrade(s, dir);
  }

//+------------------------------------------------------------------+
void ProcessAll()
  {
   static bool busy = false;
   if(busy)
      return;
   busy = true;

   double pl = (InpDailyMaxLoss > 0) ? TodayPL() : 0.0;
   bool dailyBlocked = (InpDailyMaxLoss > 0 && pl <= -InpDailyMaxLoss);

   for(int s = 0; s < g_n; s++)
     {
      datetime t0 = iTime(g_sym[s], InpTF, 0);
      if(t0 == 0 || t0 == g_lastBar[s])
         continue;

      bool buy, sell;
      double lastClose, ema;
      if(!GetSignals(s, buy, sell, lastClose, ema))
         continue;                       // data not ready, retry next second

      bool first = (g_lastBar[s] == 0);
      g_lastBar[s] = t0;
      if(first)
         continue;                       // never trade an old signal on start

      if(buy && sell)
        {
         g_lastSig[s] = "CONFLICT " + TimeToString(t0, TIME_MINUTES);
         continue;                       // both copies fired same bar -> skip
        }
      if(buy)
        {
         g_lastSig[s] = "BUY " + TimeToString(t0, TIME_MINUTES);
         TryTrade(s, 1, lastClose, ema, dailyBlocked);
        }
      else if(sell)
        {
         g_lastSig[s] = "SELL " + TimeToString(t0, TIME_MINUTES);
         TryTrade(s, -1, lastClose, ema, dailyBlocked);
        }
     }

   // Dashboard
   string txt = "UT Bot Dual v1.00  |  TF " + EnumToString(InpTF) + "\n";
   txt += "BUY copy " + DoubleToString(InpBuyKey, 1) + "/" + IntegerToString(InpBuyATR)
        + "   SELL copy " + DoubleToString(InpSellKey, 1) + "/" + IntegerToString(InpSellATR) + "\n";
   txt += "Open trades: " + IntegerToString(CountPos("", 0)) + " / " + IntegerToString(InpMaxTotal);
   if(InpDailyMaxLoss > 0)
      txt += "   Today P/L: $" + DoubleToString(pl, 2) + (dailyBlocked ? "  [DAILY LOSS HIT - no new trades]" : "");
   txt += "\n------------------------------\n";
   for(int s = 0; s < g_n; s++)
      txt += g_sym[s] + "   last: " + g_lastSig[s] + "   open: " + IntegerToString(CountPos(g_sym[s], 0)) + "\n";
   Comment(txt);

   busy = false;
  }
//+------------------------------------------------------------------+
