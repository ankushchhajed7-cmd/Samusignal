//+------------------------------------------------------------------+
//|                                  MEXA SCALP Trade EA v1.01.mq5   |
//|                                  Ankush New Vision               |
//+------------------------------------------------------------------+
//  CHANGELOG
//  v1.01 (2026-10-18)
//   - PROFIT LOCK: price $1 favour me -> SL = entry + $0.50 (lock), phir har $0.10 aage
//     badhne par lock bhi $0.10 aage (1.10->0.60, 1.20->0.70 ...). Lock kabhi peeche nahi jaata.
//   - TP $5 / SL $2.5 (app ke saath same) — lot ab bhi 1% risk se (SL $2.5 ke hisaab se)
//   - Push: pehli baar lock lagne par + "LOCK HIT" close
//  v1.00 (2026-10-18)
//   - MEXA SCALP signal par AUTO TRADE (XAUUSD M1 ke liye banaya)
//   - Signal: EMA 9/21 crossover + RSI 14 filter
//       BUY  = EMA 9 upar cross + RSI 50..70
//       SELL = EMA 9 niche cross + RSI 30..50
//   - Entry Mode: CLOSE (candle close par pakka signal, default) / LIVE (cross hote hi)
//   - Lot = balance ka 1% risk (SL $2 ke hisaab se apne aap)
//   - TP $3 / SL $2 (price move) — order ke saath hi lag jaate hain
//   - EXIT RULE: har candle close hone se 5 sec pehle — profit me ho to BOOK,
//     loss me ho to rukna, TP ya SL tak wait (agli candle par phir check)
//   - Max spread $0.30, rollover time (23:55-00:10 server) me nayi trade nahi
//   - Ek waqt me sirf 1 trade (sirf apna magic number dekhta hai)
//   - Daily stop: aaj ka MEXA loss balance ka 3% → aaj nayi trade band
//   - Phone push: trade open, BOOK / TP / SL close, daily stop
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property version     "1.01"
#property description "MEXA SCALP Trade EA — EMA 9/21 + RSI 14 auto scalper."
#property description "1% risk lot, TP $5 / SL $2.5, profit lock, candle close se 5 sec pehle book."

#include <Trade/Trade.mqh>

enum ENUM_MEXA_ENTRY
{
   ENTRY_CLOSE = 0,   // CLOSE — candle close par (pakka signal)
   ENTRY_LIVE  = 1    // LIVE — cross hote hi (jaldi, cancel ho sakta hai)
};

//--- inputs
input group "=== Signal ==="
input int             InpEmaFast      = 9;            // EMA Fast
input int             InpEmaSlow      = 21;           // EMA Slow
input int             InpRsiPeriod    = 14;           // RSI Period
input double          InpBuyRsiMin    = 50;           // BUY: RSI min
input double          InpBuyRsiMax    = 70;           // BUY: RSI max
input double          InpSellRsiMin   = 30;           // SELL: RSI min
input double          InpSellRsiMax   = 50;           // SELL: RSI max
input ENUM_MEXA_ENTRY InpEntryMode    = ENTRY_CLOSE;  // Entry Mode

input group "=== Risk / TP / SL ==="
input double          InpRiskPercent  = 1.0;          // Risk per trade (% balance) — lot isi se
input double          InpTpMove       = 5.0;          // TP price move ($)
input double          InpSlMove       = 2.5;          // SL price move ($)
input double          InpMaxSpread    = 0.30;         // Max spread ($) — isse zyada to trade nahi
input double          InpDailyLossPct = 3.0;          // Daily stop: aaj ka loss (% balance)

input group "=== Exit (profit book) ==="
input int             InpBookSecBefore = 5;           // Candle close se kitne sec pehle check
input double          InpMinBookProfit = 0.10;        // Itna net profit ($) ho tabhi book

input group "=== Profit Lock (price move $) ==="
input bool            InpUseLock      = true;         // Profit lock ON
input double          InpLockStart    = 1.0;          // Itna price favour me ho to lock shuru ($)
input double          InpLockKeep     = 0.5;          // Shuru me kitna lock ($)
input double          InpLockStep     = 0.1;          // Har kitne $ par lock aage ($)

input group "=== Time filter (server time) ==="
input bool            InpUseRollover  = true;         // Rollover time me nayi trade band
input string          InpRollStart    = "23:55";      // Rollover start (HH:MM)
input string          InpRollEnd      = "00:10";      // Rollover end (HH:MM)

input group "=== Other ==="
input long            InpMagic        = 18102026;     // Magic number (dusre EA se alag)
input bool            InpPush         = true;         // Phone push notification
input int             InpSlippage     = 30;           // Max slippage (points)

//--- globals
CTrade   trade;
int      hFast = INVALID_HANDLE, hSlow = INVALID_HANDLE, hRsi = INVALID_HANDLE;
datetime lastBarTime   = 0;      // CLOSE mode: kis bar ka close signal check ho chuka
datetime liveDoneBar   = 0;      // LIVE mode: is bar me signal le liya
datetime bookCheckedBar = 0;     // is bar ka 5-sec check ho chuka
datetime spreadLogBar  = 0;
datetime curDay        = 0;
double   dayStartBal   = 0;
bool     dayStopped    = false;
string   lastAction    = "-";
ulong    lockPushedTk  = 0;      // is ticket ka lock push ho chuka

//+------------------------------------------------------------------+
string TfName() { return StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7); }

void Push(const string msg)
{
   Print(msg);
   if(InpPush && !MQLInfoInteger(MQL_TESTER) && TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      if(!SendNotification(msg)) Print("MEXA: push fail, error ", GetLastError());
}

int HHMM(const string s)
{
   string parts[];
   if(StringSplit(s, ':', parts) != 2) return(-1);
   return((int)StringToInteger(parts[0]) * 60 + (int)StringToInteger(parts[1]));
}

bool InRollover()
{
   if(!InpUseRollover) return(false);
   int a = HHMM(InpRollStart), b = HHMM(InpRollEnd);
   if(a < 0 || b < 0) return(false);
   MqlDateTime t; TimeToStruct(TimeTradeServer(), t);
   int m = t.hour * 60 + t.min;
   if(a <= b) return(m >= a && m < b);
   return(m >= a || m < b);                         // aadhi raat paar
}

double Spread() { return(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)); }

//+------------------------------------------------------------------+
ulong MyPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return(tk);
   }
   return(0);
}

//+------------------------------------------------------------------+
double CalcLot(const bool verbose = false)
{
   double bal      = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk     = bal * InpRiskPercent / 100.0;
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickVal <= 0) tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(tickVal <= 0 || tickSize <= 0 || step <= 0 || InpSlMove <= 0) return(0);

   double lossPerLot = InpSlMove / tickSize * tickVal;   // 1 lot par SL ka loss
   double lots = risk / lossPerLot;
   lots = MathFloor(lots / step) * step;
   if(lots < minLot)
   {
      if(verbose) Print("MEXA: 1% risk ke liye lot bahut chhota — min lot ", DoubleToString(minLot, 2), " lagega (risk thoda zyada)");
      lots = minLot;
   }
   if(lots > maxLot) lots = maxLot;

   //--- margin check
   double margin = 0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   while(lots >= minLot && OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, ask, margin) &&
         margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9)
      lots = NormalizeDouble(lots - step, 2);
   if(lots < minLot) return(0);
   return(NormalizeDouble(lots, 2));
}

//+------------------------------------------------------------------+
//| aaj ka sirf MEXA ka P/L (closed + open)                         |
//+------------------------------------------------------------------+
double TodayPnL()
{
   double pnl = 0;
   if(HistorySelect(curDay, TimeCurrent() + 60))
   {
      int n = HistoryDealsTotal();
      for(int i = 0; i < n; i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0) continue;
         if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
         if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
         pnl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_COMMISSION) +
                HistoryDealGetDouble(d, DEAL_SWAP);
      }
   }
   ulong tk = MyPosition();
   if(tk > 0 && PositionSelectByTicket(tk))
      pnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   return(pnl);
}

void DayCheck()
{
   MqlDateTime t; TimeToStruct(TimeTradeServer(), t);
   t.hour = 0; t.min = 0; t.sec = 0;
   datetime today = StructToTime(t);
   if(today != curDay)
   {
      curDay      = today;
      dayStartBal = AccountInfoDouble(ACCOUNT_BALANCE);
      dayStopped  = false;
   }
   if(!dayStopped && dayStartBal > 0)
   {
      double limit = dayStartBal * InpDailyLossPct / 100.0;
      double pnl   = TodayPnL();
      if(pnl <= -limit)
      {
         dayStopped = true;
         Push("MEXA SCALP | DAILY STOP | aaj ka loss " + DoubleToString(pnl, 2) + "$ (limit -" +
              DoubleToString(limit, 2) + "$) — aaj nayi trade band");
      }
   }
}

//+------------------------------------------------------------------+
//| signal: k = 1 (closed bar) ya 0 (chalu bar)                      |
//+------------------------------------------------------------------+
int GetSignal(const int k, double &rsiOut)
{
   double f[], s[], r[];
   ArraySetAsSeries(f, true); ArraySetAsSeries(s, true); ArraySetAsSeries(r, true);
   if(CopyBuffer(hFast, 0, 0, 3, f) < 3) return(0);
   if(CopyBuffer(hSlow, 0, 0, 3, s) < 3) return(0);
   if(CopyBuffer(hRsi,  0, 0, 3, r) < 3) return(0);
   rsiOut = r[k];
   bool up = (f[k + 1] <= s[k + 1] && f[k] > s[k]);
   bool dn = (f[k + 1] >= s[k + 1] && f[k] < s[k]);
   if(up && r[k] >= InpBuyRsiMin && r[k] <= InpBuyRsiMax)   return(+1);
   if(dn && r[k] >= InpSellRsiMin && r[k] <= InpSellRsiMax) return(-1);
   return(0);
}

//+------------------------------------------------------------------+
bool TryOpen(const int dir, const double rsi)
{
   string side = (dir > 0 ? "BUY" : "SELL");
   if(MyPosition() > 0) { Print("MEXA: ", side, " signal — trade pehle se khuli, skip"); return(false); }
   if(dayStopped)       { Print("MEXA: ", side, " signal — daily stop laga hai, skip"); return(false); }
   if(InRollover())
   {
      datetime rb = iTime(_Symbol, _Period, 0);
      if(spreadLogBar != rb) { spreadLogBar = rb; Print("MEXA: ", side, " signal — rollover time, skip"); }
      return(false);
   }
   double sp = Spread();
   if(sp > InpMaxSpread)
   {
      datetime b0 = iTime(_Symbol, _Period, 0);
      if(spreadLogBar != b0) { spreadLogBar = b0; Print("MEXA: ", side, " signal — spread ", DoubleToString(sp, 2), "$ > ", DoubleToString(InpMaxSpread, 2), "$, skip"); }
      return(false);
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print("MEXA: Algo Trading OFF hai — trade nahi khul sakti");
      return(false);
   }

   double lot = CalcLot(true);
   if(lot <= 0) { Print("MEXA: lot 0 — margin/balance kam"); return(false); }

   double price = (dir > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   double sl = NormalizeDouble(price - dir * InpSlMove, _Digits);
   double tp = NormalizeDouble(price + dir * InpTpMove, _Digits);

   double minDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(minDist > 0 && (InpSlMove < minDist || InpTpMove < minDist))
      Print("MEXA: warning — broker stop level ", DoubleToString(minDist, _Digits), " se TP/SL chhota hai");

   bool ok = (dir > 0 ? trade.Buy(lot, _Symbol, 0, sl, tp, "MEXA SCALP")
                      : trade.Sell(lot, _Symbol, 0, sl, tp, "MEXA SCALP"));
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
   {
      Print("MEXA: ", side, " order fail — ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return(false);
   }
   double fill = trade.ResultPrice() > 0 ? trade.ResultPrice() : price;
   lastAction = side + " " + DoubleToString(lot, 2) + " @ " + DoubleToString(fill, _Digits);
   Push("MEXA SCALP | " + _Symbol + " " + TfName() + " | " + side + " " + DoubleToString(lot, 2) + " lot @ " +
        DoubleToString(fill, _Digits) + " | SL " + DoubleToString(sl, _Digits) + " TP " + DoubleToString(tp, _Digits) +
        " | RSI " + DoubleToString(rsi, 0) + " | spread " + DoubleToString(sp, 2));
   return(true);
}

//+------------------------------------------------------------------+
//| profit lock: SL ko profit ki taraf khiskao (kabhi peeche nahi)  |
//+------------------------------------------------------------------+
void LockCheck()
{
   if(!InpUseLock || InpLockStep <= 0) return;
   ulong tk = MyPosition();
   if(tk == 0 || !PositionSelectByTicket(tk)) return;
   long   type  = PositionGetInteger(POSITION_TYPE);
   double open  = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSL = PositionGetDouble(POSITION_SL);
   double curTP = PositionGetDouble(POSITION_TP);
   double vol   = PositionGetDouble(POSITION_VOLUME);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double move = (type == POSITION_TYPE_BUY ? bid - open : open - ask);
   if(move < InpLockStart - 1e-9) return;
   double lm = InpLockKeep + MathFloor((move - InpLockStart) / InpLockStep + 1e-9) * InpLockStep;
   double minDist = (double)MathMax(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL),
                                    SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL)) * _Point;
   double newSL;
   if(type == POSITION_TYPE_BUY)
   {
      newSL = NormalizeDouble(open + lm, _Digits);
      if(curSL > 0 && newSL <= curSL + _Point / 2) return;          // sirf aage
      if(newSL > bid - minDist) return;                              // broker stop level
   }
   else
   {
      newSL = NormalizeDouble(open - lm, _Digits);
      if(curSL > 0 && newSL >= curSL - _Point / 2) return;
      if(newSL < ask + minDist) return;
   }
   if(trade.PositionModify(tk, newSL, curTP))
   {
      double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double lockMoney = (tickSize > 0 ? lm / tickSize * tickVal * vol : 0);
      lastAction = "LOCK +" + DoubleToString(lockMoney, 2) + "$ (SL " + DoubleToString(newSL, _Digits) + ")";
      if(lockPushedTk != tk)
      {
         lockPushedTk = tk;
         Push("MEXA SCALP | " + _Symbol + " | PROFIT LOCK | SL " + DoubleToString(newSL, _Digits) +
              " | kam se kam +" + DoubleToString(lockMoney, 2) + "$");
      }
      else Print("MEXA: lock aage — SL ", DoubleToString(newSL, _Digits), " (+", DoubleToString(lockMoney, 2), "$)");
   }
   else
      Print("MEXA: lock modify fail — ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| candle close se X sec pehle: profit me ho to book               |
//+------------------------------------------------------------------+
void BookCheck()
{
   ulong tk = MyPosition();
   if(tk == 0) return;
   datetime b0 = iTime(_Symbol, _Period, 0);
   if(b0 == 0 || bookCheckedBar == b0) return;
   long remain = (long)(b0 + PeriodSeconds()) - (long)TimeTradeServer();
   if(remain > InpBookSecBefore || remain < 0) return;
   bookCheckedBar = b0;

   if(!PositionSelectByTicket(tk)) return;
   double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   if(profit > InpMinBookProfit)
   {
      if(trade.PositionClose(tk, InpSlippage))
         lastAction = "BOOK " + DoubleToString(profit, 2) + "$";
      else
         Print("MEXA: book close fail — ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   }
   else
      Print("MEXA: candle end check — P/L ", DoubleToString(profit, 2), "$, TP/SL tak wait");
}

//+------------------------------------------------------------------+
void ShowComment()
{
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   string pos = "koi nahi";
   ulong tk = MyPosition();
   if(tk > 0 && PositionSelectByTicket(tk))
      pos = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY " : "SELL ") +
            DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + "  P/L " +
            DoubleToString(PositionGetDouble(POSITION_PROFIT), 2) + "$";
   datetime b0 = iTime(_Symbol, _Period, 0);
   long remain = (long)(b0 + PeriodSeconds()) - (long)TimeTradeServer();
   Comment("MEXA SCALP Trade EA v1.01  |  ", _Symbol, " ", TfName(),
           "  |  EMA ", InpEmaFast, "/", InpEmaSlow, " RSI ", InpRsiPeriod,
           "  |  Entry: ", (InpEntryMode == ENTRY_CLOSE ? "CLOSE" : "LIVE"),
           "\nRisk ", DoubleToString(InpRiskPercent, 1), "%  →  agla lot ", DoubleToString(CalcLot(), 2),
           "   |   TP $", DoubleToString(InpTpMove, 2), "  SL $", DoubleToString(InpSlMove, 2),
           (InpUseLock ? "   |   Lock: $" + DoubleToString(InpLockStart, 2) + " ke baad" : ""),
           "\nSpread ", DoubleToString(Spread(), 2), "$ (max ", DoubleToString(InpMaxSpread, 2), ")",
           "   |   Candle khatam: ", (remain >= 0 ? IntegerToString(remain) + "s" : "-"),
           "\nTrade: ", pos,
           "\nAaj MEXA P/L: ", DoubleToString(TodayPnL(), 2), "$   ",
           (dayStopped ? "[DAILY STOP]" : ""), (InRollover() ? " [ROLLOVER]" : ""),
           "\nLast: ", lastAction);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpEmaFast < 1 || InpEmaSlow <= InpEmaFast || InpRsiPeriod < 2 || InpSlMove <= 0 || InpTpMove <= 0)
   {
      Print("MEXA: galat inputs");
      return(INIT_PARAMETERS_INCORRECT);
   }
   hFast = iMA(_Symbol, _Period, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, _Period, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
   hRsi  = iRSI(_Symbol, _Period, InpRsiPeriod, PRICE_CLOSE);
   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE || hRsi == INVALID_HANDLE)
   {
      Print("MEXA: indicator handle error ", GetLastError());
      return(INIT_FAILED);
   }
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);

   lastBarTime = iTime(_Symbol, _Period, 0);   // purane signal par trade nahi
   liveDoneBar = 0;
   bookCheckedBar = 0;
   curDay = 0;
   DayCheck();

   if(_Period != PERIOD_M1)
      Print("MEXA: note — EA M1 ke hisaab se banaya hai, abhi chart ", TfName(), " hai");

   EventSetTimer(1);
   ShowComment();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hRsi  != INVALID_HANDLE) IndicatorRelease(hRsi);
   Comment("");
}

//+------------------------------------------------------------------+
void OnTimer()
{
   DayCheck();
   BookCheck();
   ShowComment();
}

//+------------------------------------------------------------------+
void OnTick()
{
   DayCheck();
   LockCheck();
   BookCheck();

   datetime b0 = iTime(_Symbol, _Period, 0);
   if(b0 == 0) return;
   double rsi = 0;

   if(InpEntryMode == ENTRY_CLOSE)
   {
      if(b0 != lastBarTime)
      {
         lastBarTime = b0;
         int dir = GetSignal(1, rsi);
         if(dir != 0) TryOpen(dir, rsi);
      }
   }
   else // LIVE
   {
      if(liveDoneBar != b0)
      {
         int dir = GetSignal(0, rsi);
         if(dir != 0)
         {
            if(MyPosition() > 0 || dayStopped) liveDoneBar = b0;      // is candle me dobara mat dekho
            else if(TryOpen(dir, rsi)) liveDoneBar = b0;             // is candle me ek hi trade
            // spread / rollover se ruka to agle tick par phir try
         }
      }
   }
}

//+------------------------------------------------------------------+
//| trade band hone par push (BOOK / TP / SL / manual)              |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || trans.deal == 0) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagic) return;
   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;

   double p = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION) +
              HistoryDealGetDouble(trans.deal, DEAL_SWAP);
   long reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
   string why = (reason == DEAL_REASON_TP ? "TP HIT" : reason == DEAL_REASON_SL ? (p > 0 ? "LOCK HIT" : "SL HIT") :
                 reason == DEAL_REASON_EXPERT ? "BOOK (candle end)" : "CLOSE");
   lastAction = why + " " + DoubleToString(p, 2) + "$";
   Push("MEXA SCALP | " + _Symbol + " | " + why + " | " + (p >= 0 ? "+" : "") + DoubleToString(p, 2) + "$ | aaj " +
        DoubleToString(TodayPnL(), 2) + "$");
}
//+------------------------------------------------------------------+
