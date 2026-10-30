//+------------------------------------------------------------------+
//|                                       AMC GOLD MASTER v1.01.mq5  |
//|                 Ankush New Vision - M5 candle momentum gold EA   |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.01 (30-Oct-2026) - COCKPIT dashboard + JOURNAL                |
//|  - Comment ki jagah Cockpit panel (SUPERTREND GRID jaisa):       |
//|    IST ghadi + server + session | SIGNAL (agli candle ki disha  |
//|    + countdown) | MASTER CAUTION (SL laga = laal blink + chart   |
//|    ke beech flash + awaaz; jeet / 5 trade poore = hara)          |
//|    TRADE P&L | DAILY (x/5 trade) | LOCK | RISK                   |
//|    RISK GAUGE (khula loss vs 1 trade ka risk, 20 khane)          |
//|    Lights: TRADES / SPREAD / ALGO / TIME / LOCK / DAY             |
//|    Status + PAUSE / CLOSE ALL buttons, niche BAL/EQ/entry/SL/TP  |
//|  - JOURNAL: MQL5\Files\AMC_GM_journal_<account>.csv              |
//|    har candle ka faisla (ENTRY / SKIP + kaaran), har LOCK, har   |
//|    band trade (result, peak, worst, kitni der) - aage badlav ke   |
//|    liye. Experts log me bhi.                                      |
//|  - Push notification (InpPush) SL / jeet / din poora par          |
//|  - Strategy wahi v1.00 wali (koi badlav nahi)                     |
//| v1.00 (30-Oct-2026) - pehla build                                |
//|  GrowthMasters (purchased) ke 4 din / 20 trade ke observation se |
//|  - ENTRY: har M5 candle khulte hi (pehle 30 sec me), sirf jab     |
//|    apna koi trade khula na ho. Pichhli candle HARI = BUY,         |
//|    LAAL = SELL, doji (body < 0.10) = skip                         |
//|  - SL: pichhli candle ke low (BUY) / high (SELL) se 0.30 bahar,    |
//|    kam se kam 1.00, 10.00 se bada = trade skip                    |
//|  - TP: SL doori x 1.5 | LOT: balance ka 1% risk                   |
//|  - LOCK ($): profit $2 par SL = +$1, phir har +$1 par lock +$1     |
//|  - Din me max 5 trade (server din, 00:00 se)                      |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.01"
#property description "AMC GOLD MASTER v1.01 - M5 candle colour entry, 1% risk, $ lock trail, 5 trades/day, Cockpit panel"

#include <Trade\Trade.mqh>

#define EA_NAME  "AMC GOLD MASTER"
#define EA_VER   "v1.01"
#define PNL      "AMCGM_"
#define GVP      "AMCGM_"
#define BT_PAUSE "BT_PAUSE"
#define BT_CALL  "BT_CALL"

enum ENUM_AMC_LOT
{
   AMC_LOT_RISK  = 0,   // Balance ka % risk
   AMC_LOT_FIXED = 1    // Fixed lot
};

//=== INPUTS ========================================================
input group "=== Pehchaan ==="
input long            InpMagic          = 20261030;   // Magic Number
input string          InpComment        = "AMC GOLD MASTER"; // Trade comment

input group "=== Entry (M5 candle) ==="
input ENUM_TIMEFRAMES InpTF             = PERIOD_M5;  // Candle timeframe (GrowthMasters = M5)
input int             InpEntryWindowSec = 30;         // Candle khulne ke baad kitne second tak entry
input double          InpMinBody        = 0.10;       // Pichhli candle ki body kam se kam (price) - doji skip
input int             InpMaxTradesDay   = 5;          // Din me max trade (0 = no limit)
input int             InpStartHour      = 0;          // Trade shuru (server ghanta, 0-23)
input int             InpEndHour        = 24;         // Trade band (server ghanta, 24 = poora din)
input int             InpMaxSpreadPts   = 0;          // Max spread points (0 = off)

input group "=== SL / TP ==="
input double          InpSLBuffer       = 0.30;       // SL: pichhli candle high/low se bahar (price)
input double          InpMinSL          = 1.00;       // SL kam se kam doori (price)
input double          InpMaxSL          = 10.00;      // SL isse bada = trade skip (price)
input double          InpRR             = 1.5;        // TP = SL doori x ye

input group "=== Lot ==="
input ENUM_AMC_LOT    InpLotMode        = AMC_LOT_RISK; // Lot kaise
input double          InpRiskPct        = 1.0;        // Risk % (balance ka, har trade)
input double          InpFixedLot       = 0.01;       // Fixed lot (agar Fixed chuna)
input double          InpMaxLot         = 5.00;       // Max lot seema

input group "=== Profit lock / trailing ($) ==="
input bool            InpUseLock        = true;       // Lock ON/OFF
input double          InpLockTrigger    = 2.00;       // Profit $ itna ho to lock shuru
input double          InpLockKeep       = 1.00;       // Pehla lock: itna $ pakka
input double          InpLockStep       = 1.00;       // Har itne $ par lock aage
input bool            InpLockPerLot     = false;      // Lock lot ke saath badhe ($ values 0.01 lot ke liye)

input group "=== Extra suraksha (0 = off) ==="
input double          InpDayLossPct     = 0;          // Din ka loss % poora = aaj aur trade nahi
input double          InpDayTargetPct   = 0;          // Din ka profit % poora = aaj aur trade nahi
input int             InpSlippage       = 50;         // Slippage (points)

input group "=== Dashboard / Journal ==="
input bool            InpShowPanel      = true;       // Cockpit panel dikhao
input int             InpPanelX         = 10;         // Panel X
input int             InpPanelY         = 25;         // Panel Y
input double          InpPanelScale     = 0;          // Panel size (0 = chart me apne aap fit)
input bool            InpJournal        = true;       // Journal file likho (MQL5\Files)
input bool            InpPush           = true;       // Mobile push (SL / jeet / din poora)

//=== GLOBALS =======================================================
CTrade   trade;
datetime gDoneBar   = 0;     // is candle pe faisla ho chuka
datetime gTryBar    = 0;
int      gTries     = 0;
string   gLastMsg   = "";
int      gDayTrades = 0;
double   gDayPL     = 0;
datetime gStatsAt   = 0;
string   gJournal   = "";

// khule trade ka peak / worst (journal ke liye)
ulong    gPkTicket  = 0;
double   gPeak      = 0;
double   gWorst     = 0;
double   gLockNow   = 0;

// panel
double   g_U        = 1.0;
double   g_DpiS     = 1.0;
int      g_PX       = 10;
int      g_PY       = 25;
int      g_LastChartW = 0;
bool     g_blink    = false;
int      g_tick     = 0;
int      g_alertLvl = 0;     // 0 kuch nahi, 1 hara, 2 laal
string   g_alertMsg = "";
datetime g_alertAt  = 0;
datetime g_flashTill = 0;

//+------------------------------------------------------------------+
//| helpers                                                          |
//+------------------------------------------------------------------+
double NormP(double p) { return NormalizeDouble(p, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)); }
string GvKey(string s) { return GVP + IntegerToString(InpMagic) + "_" + s; }
bool   IsPaused()      { return GlobalVariableCheck(GvKey("PAUSE")) && GlobalVariableGet(GvKey("PAUSE")) > 0; }
string Money(double v) { return (v >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(v), 2); }

double MinStopDist()
{
   long lv = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long fz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(lv, fz) * _Point;
}

// 1 lot par 1.0 price chalne se kitne $
double MoneyPerPricePerLot(bool loss)
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(_Symbol, loss ? SYMBOL_TRADE_TICK_VALUE_LOSS : SYMBOL_TRADE_TICK_VALUE_PROFIT);
   if(tv <= 0) tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0 || tv <= 0) return 0;
   return tv / ts;
}

datetime DayStart() { return StringToTime(TimeToString(TimeCurrent(), TIME_DATE)); }

string IstStr(datetime srv, int flags = TIME_DATE | TIME_SECONDS)
{
   return TimeToString(srv - (TimeTradeServer() - TimeGMT()) + 19800, flags);
}

// apna khula trade (EA ek waqt me ek hi rakhta hai)
bool GetMyPos(ulong &tk, bool &isBuy, double &op, double &sl, double &tp, double &vol, double &pl)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      tk    = t;
      isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      op    = PositionGetDouble(POSITION_PRICE_OPEN);
      sl    = PositionGetDouble(POSITION_SL);
      tp    = PositionGetDouble(POSITION_TP);
      vol   = PositionGetDouble(POSITION_VOLUME);
      pl    = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      return true;
   }
   return false;
}

int MyPositions()
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic) n++;
   }
   return n;
}

// aaj ke trade (entries) aur aaj ka band hua P/L (har 2 sec me ek baar)
void TodayStats(bool force = false)
{
   if(!force && TimeCurrent() - gStatsAt < 2) return;
   gStatsAt = TimeCurrent();
   gDayTrades = 0; gDayPL = 0;
   if(!HistorySelect(DayStart(), TimeCurrent() + 60)) return;
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_IN) gDayTrades++;
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_INOUT || en == DEAL_ENTRY_OUT_BY)
         gDayPL += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
   }
}

double RiskMoney()
{
   return AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPct / 100.0;
}

double CalcLot(double slDist)
{
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstp = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vstp <= 0) vstp = 0.01;
   double lot = InpFixedLot;
   if(InpLotMode == AMC_LOT_RISK)
   {
      double mpp = MoneyPerPricePerLot(true);
      if(mpp <= 0 || slDist <= 0) return 0;
      lot = RiskMoney() / (slDist * mpp);
   }
   lot = MathFloor(lot / vstp) * vstp;
   if(lot < vmin) lot = vmin;
   lot = MathMin(lot, MathMin(vmax, InpMaxLot));
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| JOURNAL                                                          |
//+------------------------------------------------------------------+
void Journal(string event, string side, double lot, double price, double sl, double tp, double money, string note)
{
   if(!InpJournal || MQLInfoInteger(MQL_TESTER)) return;
   bool isNew = !FileIsExist(gJournal);
   int h = FileOpen(gJournal, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ',');
   if(h == INVALID_HANDLE) return;
   if(isNew)
      FileWrite(h, "server_time", "ist_time", "event", "side", "lot", "price", "sl", "tp", "money", "day_trades", "day_pl", "balance", "note");
   FileSeek(h, 0, SEEK_END);
   int dg = _Digits;
   FileWrite(h, TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS), IstStr(TimeCurrent()), event, side,
             DoubleToString(lot, 2), DoubleToString(price, dg), DoubleToString(sl, dg), DoubleToString(tp, dg),
             DoubleToString(money, 2), gDayTrades, DoubleToString(gDayPL, 2),
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), note);
   FileClose(h);
}

// SKIP bhi journal me (aage dekhna kitne mauke kyun chhoote)
void Skip(datetime bar0, string why)
{
   gDoneBar = bar0;
   gLastMsg = why;
   Journal("SKIP", "", 0, 0, 0, 0, 0, why);
}

//+------------------------------------------------------------------+
//| ALERT                                                            |
//+------------------------------------------------------------------+
void Notify(string msg, int level)
{
   Print(EA_NAME, " ", msg);
   if(level > 0 && (level >= g_alertLvl || TimeCurrent() - g_alertAt > 60))
   {
      g_alertLvl = level;
      g_alertMsg = msg;
      g_alertAt  = TimeCurrent();
      if(level == 2)
      {
         g_flashTill = TimeCurrent() + 15;
         if(!MQLInfoInteger(MQL_TESTER)) PlaySound("alert2.wav");
      }
   }
   if(InpPush && !MQLInfoInteger(MQL_TESTER))
      SendNotification(EA_NAME + ": " + msg);
}

//+------------------------------------------------------------------+
//| ENTRY - har nayi candle ke shuru me                              |
//+------------------------------------------------------------------+
void TryEntry()
{
   datetime bar0 = iTime(_Symbol, InpTF, 0);
   if(bar0 == 0 || bar0 == gDoneBar) return;

   if(TimeCurrent() - bar0 > InpEntryWindowSec) { gDoneBar = bar0; return; }   // beech me EA laga / der ho gayi
   if(MyPositions() > 0) { gDoneBar = bar0; gLastMsg = "trade khula hai - agli candle"; return; }
   if(IsPaused())        { Skip(bar0, "PAUSE (button)"); return; }

   MqlDateTime tm; TimeToStruct(bar0, tm);
   if(tm.hour < InpStartHour || tm.hour >= InpEndHour) { gDoneBar = bar0; gLastMsg = "time ke bahar"; return; }

   TodayStats(true);
   if(InpMaxTradesDay > 0 && gDayTrades >= InpMaxTradesDay) { gDoneBar = bar0; gLastMsg = "aaj ke " + IntegerToString(gDayTrades) + " trade poore"; return; }
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(InpDayLossPct > 0 && gDayPL <= -bal * InpDayLossPct / 100.0)  { Skip(bar0, "day loss poora"); return; }
   if(InpDayTargetPct > 0 && gDayPL >= bal * InpDayTargetPct / 100.0) { Skip(bar0, "day target poora"); return; }

   if(InpMaxSpreadPts > 0)
   {
      long spr = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spr > InpMaxSpreadPts)
      {
         gLastMsg = "spread zyada " + IntegerToString(spr);
         if(TimeCurrent() - bar0 >= InpEntryWindowSec - 1) Skip(bar0, gLastMsg);   // window khatam = skip likho
         return;
      }
   }

   double o1 = iOpen(_Symbol, InpTF, 1), c1 = iClose(_Symbol, InpTF, 1);
   double h1 = iHigh(_Symbol, InpTF, 1), l1 = iLow(_Symbol, InpTF, 1);
   if(o1 == 0 || c1 == 0) return;
   double body = c1 - o1;
   if(MathAbs(body) < InpMinBody) { Skip(bar0, "doji body " + DoubleToString(MathAbs(body), 2)); return; }

   bool   isBuy = (body > 0);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double px  = isBuy ? ask : bid;
   double sl  = isBuy ? l1 - InpSLBuffer : h1 + InpSLBuffer;
   double dist = isBuy ? px - sl : sl - px;
   double minD = MathMax(InpMinSL, MinStopDist() + 2 * _Point);
   if(dist < minD) { dist = minD; sl = isBuy ? px - dist : px + dist; }
   if(dist > InpMaxSL) { Skip(bar0, "SL " + DoubleToString(dist, 2) + " bahut bada"); Print(EA_NAME, " ", gLastMsg); return; }
   double tp = isBuy ? px + dist * InpRR : px - dist * InpRR;

   double lot = CalcLot(dist);
   if(lot <= 0) { Skip(bar0, "lot 0"); return; }

   if(gTryBar != bar0) { gTryBar = bar0; gTries = 0; }
   gTries++;
   bool ok = isBuy ? trade.Buy(lot, _Symbol, 0, NormP(sl), NormP(tp), InpComment)
                   : trade.Sell(lot, _Symbol, 0, NormP(sl), NormP(tp), InpComment);
   uint rc = trade.ResultRetcode();
   if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL))
   {
      gDoneBar = bar0;
      double risk = dist * lot * MoneyPerPricePerLot(true);
      double fill = trade.ResultPrice() > 0 ? trade.ResultPrice() : px;
      gLastMsg = (isBuy ? "BUY " : "SELL ") + DoubleToString(lot, 2) + " | SL " + DoubleToString(dist, 2) + " | risk $" + DoubleToString(risk, 2);
      gDayTrades++;
      Print(EA_NAME, " ", gLastMsg, " | pichhli candle O ", DoubleToString(o1, _Digits), " C ", DoubleToString(c1, _Digits),
            " | aaj ka trade #", gDayTrades);
      Journal("ENTRY", isBuy ? "BUY" : "SELL", lot, fill, sl, tp, -risk,
              StringFormat("candle O %s H %s L %s C %s body %.2f | SLdist %.2f | spread %d",
                           DoubleToString(o1, _Digits), DoubleToString(h1, _Digits), DoubleToString(l1, _Digits),
                           DoubleToString(c1, _Digits), body, dist, (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)));
      gPkTicket = 0;
   }
   else
   {
      gLastMsg = "order fail code " + IntegerToString((int)rc);
      Print(EA_NAME, " ", gLastMsg, " (koshish ", gTries, ")");
      if(gTries >= 3) Skip(bar0, gLastMsg);
   }
}

//+------------------------------------------------------------------+
//| LOCK - profit $ ke hisaab se SL aage                              |
//+------------------------------------------------------------------+
void ManageLock()
{
   double mpp = MoneyPerPricePerLot(false);
   if(mpp <= 0) return;
   double minD = MinStopDist();
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   gLockNow = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double op  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl  = PositionGetDouble(POSITION_SL);
      double tp  = PositionGetDouble(POSITION_TP);
      double vol = PositionGetDouble(POSITION_VOLUME);
      double px  = isBuy ? bid : ask;
      double profit = (isBuy ? px - op : op - px) * vol * mpp;

      // peak / worst (journal)
      if(gPkTicket != t) { gPkTicket = t; gPeak = profit; gWorst = profit; }
      gPeak  = MathMax(gPeak, profit);
      gWorst = MathMin(gWorst, profit);
      if(sl > 0 && ((isBuy && sl > op) || (!isBuy && sl < op)))
         gLockNow = MathAbs(sl - op) * vol * mpp;

      if(!InpUseLock || InpLockTrigger <= 0) continue;
      double k    = InpLockPerLot ? vol / 0.01 : 1.0;
      double trig = InpLockTrigger * k;
      double keep = InpLockKeep * k;
      double step = MathMax(0.01, InpLockStep * k);
      if(profit < trig) continue;

      double lockM = keep + MathFloor((profit - trig) / step) * step;
      double d     = lockM / (vol * mpp);
      double nsl   = isBuy ? op + d : op - d;
      if(isBuy  && nsl > bid - minD) nsl = bid - minD;
      if(!isBuy && nsl < ask + minD) nsl = ask + minD;
      nsl = NormP(nsl);

      bool better   = (sl == 0) || (isBuy ? nsl > sl + _Point / 2 : nsl < sl - _Point / 2);
      bool inProfit = isBuy ? nsl > op : nsl < op;
      if(!better || !inProfit) continue;

      if(trade.PositionModify(t, nsl, tp))
      {
         gLockNow = MathAbs(nsl - op) * vol * mpp;
         Print(EA_NAME, " LOCK #", t, " profit $", DoubleToString(profit, 2), " -> pakka $", DoubleToString(lockM, 2),
               " | SL ", DoubleToString(nsl, _Digits));
         Journal("LOCK", isBuy ? "BUY" : "SELL", vol, px, nsl, tp, lockM, StringFormat("profit $%.2f", profit));
      }
      else
         Print(EA_NAME, " lock fail #", t, " code ", trade.ResultRetcode());
   }
}

void CloseAll(string why)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         trade.PositionClose(t, InpSlippage);
   }
   Print(EA_NAME, " CLOSE ALL - ", why);
}

//+------------------------------------------------------------------+
//| COCKPIT PANEL                                                    |
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

int P(double v)   { return (int)MathRound(v * g_U); }
int FP(double px) { return (int)MathMax(6, MathRound(px * g_U * 0.75 / g_DpiS)); }

void Rect(string n, int x, int y, int w, int h, color bg, color edge = clrNONE)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
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
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
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
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
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

void SetTxt(string n, string t, color c)
{
   ObjectSetString(0, PNL + n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, PNL + n, OBJPROP_COLOR, c);
}

void Tile(string id, double x, double y, double w, double h, string label, int bigPx)
{
   Rect(PNL + id + "_BG", g_PX + P(x), g_PY + P(y), P(w), P(h), CK_TILE, CK_EDGE);
   Lbl(PNL + id + "_L", label, g_PX + P(x + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + id + "_V", "--", g_PX + P(x + 12), g_PY + P(y + 26), CK_TEXT, FP(bigPx), CK_NUM);
   Lbl(PNL + id + "_S", " ", g_PX + P(x + 12), g_PY + P(y + h - 24), CK_LABEL, FP(12));
}

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
   if(!InpShowPanel) return;
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   g_PX = InpPanelX;
   g_PY = InpPanelY;
   double avail = MathMax(400.0, chartW - 2.0 * InpPanelX);
   g_U = (InpPanelScale > 0.0) ? InpPanelScale : MathMin(avail / 960.0, 1.6 * g_DpiS);
   g_U = MathMax(0.45, g_U);

   const double W = 960, PADX = 16, G = 12;
   double inner = W - 2 * PADX;
   double tw = (inner - 3 * G) / 4;
   Rect(PNL + "BG", g_PX, g_PY, P(W), P(464), CK_BG, CK_EDGE);

   // Row 1: ghadi | signal | master caution
   double y = 16;
   Rect(PNL + "CL_BG", g_PX + P(PADX), g_PY + P(y), P(2 * tw + G), P(96), CK_TILE, CK_EDGE);
   Lbl(PNL + "CL_L", "IST TIME", g_PX + P(PADX + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + "CL_N", EA_NAME + " " + EA_VER + " \x00B7 " + _Symbol, g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 9), CK_LABEL, FP(11), CK_SANS, ANCHOR_RIGHT_UPPER);
   Lbl(PNL + "CL_V", "--:--:--", g_PX + P(PADX + 12), g_PY + P(y + 26), CK_AMBER, FP(52), CK_NUM);
   Lbl(PNL + "CL_S1", "SERVER --:--", g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 46), CK_LABEL, FP(12), CK_SANS, ANCHOR_RIGHT_UPPER);
   Lbl(PNL + "CL_S2", "--", g_PX + P(PADX + 2 * tw + G - 12), g_PY + P(y + 66), CK_LABEL, FP(12), CK_SANS, ANCHOR_RIGHT_UPPER);
   double xt = PADX + 2 * tw + 2 * G;
   Tile("TR", xt, y, tw, 96, "SIGNAL", 32);
   double xc = xt + tw + G;
   Btn(PNL + "CA_BG", " ", g_PX + P(xc), g_PY + P(y), P(tw), P(96), CK_OFF, CK_LABEL, CK_OFFEDGE, FP(11));
   Lbl(PNL + "CA_L", "MASTER CAUTION", g_PX + P(xc + 12), g_PY + P(y + 9), CK_LABEL, FP(11));
   Lbl(PNL + "CA_V", "ALL CLEAR", g_PX + P(xc + 12), g_PY + P(y + 34), CK_GREEN, FP(17));
   Lbl(PNL + "CA_S", " ", g_PX + P(xc + 12), g_PY + P(y + 66), CK_LABEL, FP(11));

   // Row 2: bade number
   y = 124;
   Tile("BP", PADX, y, tw, 92, "TRADE P&L", 30);
   Tile("DY", PADX + (tw + G), y, tw, 92, "DAILY", 30);
   Tile("LK", PADX + 2 * (tw + G), y, tw, 92, "LOCK", 30);
   Tile("RK", PADX + 3 * (tw + G), y, tw, 92, "RISK / TRADE", 30);

   // Row 3: risk gauge
   y = 228;
   Rect(PNL + "DD_BG", g_PX + P(PADX), g_PY + P(y), P(inner), P(60), CK_TILE, CK_EDGE);
   Lbl(PNL + "DD_L", "RISK GAUGE", g_PX + P(PADX + 12), g_PY + P(y + 8), CK_LABEL, FP(11));
   double sw = (inner - 24 - 19 * 4) / 20.0;
   for(int i = 0; i < 20; i++)
      Rect(PNL + "DD_S" + IntegerToString(i), g_PX + P(PADX + 12 + i * (sw + 4)), g_PY + P(y + 30), P(sw), P(18), CK_OFF);

   // Row 4: lights
   y = 300;
   double lw = (inner - 5 * 8) / 6.0;
   string ids[] = {"LT", "LS", "LA", "LH", "LL", "LD"};
   for(int i = 0; i < 6; i++)
      Light(ids[i], PADX + i * (lw + 8), y, lw, 40);

   // Row 5: status + buttons
   y = 352;
   double bw = 120, sbw = inner - 2 * bw - 2 * G;
   Rect(PNL + "ST_BG", g_PX + P(PADX), g_PY + P(y), P(sbw), P(44), CK_TILE, CK_EDGE);
   Lbl(PNL + "ST_V", "--", g_PX + P(PADX + 12), g_PY + P(y + 22), CK_GREEN, FP(14), CK_NUM, ANCHOR_LEFT);
   Btn(PNL + BT_PAUSE, "PAUSE", g_PX + P(PADX + sbw + G), g_PY + P(y), P(bw), P(44), CK_OFF, CK_AMBER, CK_AMBER, FP(14));
   Btn(PNL + BT_CALL, "CLOSE ALL", g_PX + P(PADX + sbw + G + bw + G), g_PY + P(y), P(bw), P(44), CK_REDBG, CK_RED, CK_RED, FP(14));

   // Row 6: details
   y = 408;
   Rect(PNL + "IN_BG", g_PX + P(PADX), g_PY + P(y), P(inner), P(40), CK_TILE, CK_EDGE);
   Lbl(PNL + "IN_V", "--", g_PX + P(PADX + 12), g_PY + P(y + 20), CK_LABEL, FP(12), CK_NUM, ANCHOR_LEFT);
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
   if(g.hour < 7)  return "ASIA SESSION";
   if(g.hour < 12) return "LONDON SESSION";
   if(g.hour < 16) return "LONDON + NY";
   if(g.hour < 21) return "NEW YORK SESSION";
   return "QUIET HOURS";
}

// har 0.5 sec: ghadi, countdown, master caution blink, flash
void PanelFast()
{
   if(!InpShowPanel || ObjectFind(0, PNL + "BG") < 0) return;
   datetime ist = TimeGMT() + 19800;
   MqlDateTime d;
   TimeToStruct(ist, d);
   string days[] = {"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"};
   string mons[] = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
   SetTxt("CL_L", StringFormat("IST TIME \x00B7 %s %02d %s", days[d.day_of_week], d.day, mons[d.mon - 1]), CK_LABEL);
   SetTxt("CL_V", TimeToString(ist, TIME_SECONDS), CK_AMBER);
   SetTxt("CL_S1", "SERVER " + TimeToString(TimeTradeServer(), TIME_MINUTES), CK_LABEL);
   SetTxt("CL_S2", SessionName(), CK_LABEL);

   // signal: agli candle ki disha (abhi tak ki chalti candle) + countdown
   datetime bar0 = iTime(_Symbol, InpTF, 0);
   int left = (int)MathMax(0, bar0 + PeriodSeconds(InpTF) - TimeTradeServer());
   double o0 = iOpen(_Symbol, InpTF, 0), c0 = iClose(_Symbol, InpTF, 0);
   double b0 = c0 - o0;
   string tf = StringSubstr(EnumToString(InpTF), 7);
   SetTxt("TR_L", "SIGNAL \x00B7 " + tf, CK_LABEL);
   if(MathAbs(b0) < InpMinBody) SetTxt("TR_V", "DOJI", CK_LABEL);
   else SetTxt("TR_V", b0 > 0 ? "BUY \x25B2" : "SELL \x25BC", b0 > 0 ? CK_GREEN : CK_RED);
   SetTxt("TR_S", StringFormat("agli candle %d:%02d", left / 60, left % 60), CK_LABEL);

   if(g_alertLvl == 1 && TimeCurrent() - g_alertAt > 60) g_alertLvl = 0;
   color cbg = CK_OFF, ced = CK_OFFEDGE, cfg = CK_GREEN;
   string cv = "ALL CLEAR", cs = " ";
   if(g_alertLvl == 2)
   {
      cbg = g_blink ? CK_RED : CK_REDBG; ced = CK_RED;
      cfg = g_blink ? CK_TILE : CK_RED;
      cv  = g_alertMsg;
      cs  = IstStr(g_alertAt, TIME_MINUTES) + " IST \x00B7 click = OK";
   }
   if(g_alertLvl == 1)
   {
      cbg = CK_GRNBG; ced = CK_GREEN; cfg = CK_GREEN;
      cv  = g_alertMsg;
      cs  = IstStr(g_alertAt, TIME_MINUTES) + " IST";
   }
   ObjectSetInteger(0, PNL + "CA_BG", OBJPROP_BGCOLOR, cbg);
   ObjectSetInteger(0, PNL + "CA_BG", OBJPROP_BORDER_COLOR, ced);
   SetTxt("CA_L", "MASTER CAUTION", g_alertLvl == 2 ? cfg : CK_LABEL);
   SetTxt("CA_V", StringLen(cv) > 22 ? StringSubstr(cv, 0, 22) : cv, cfg);
   SetTxt("CA_S", cs, g_alertLvl == 2 ? cfg : CK_LABEL);

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
   if(!InpShowPanel) return;
   if(ObjectFind(0, PNL + "BG") < 0) BuildPanel();
   TodayStats();

   ulong tk = 0; bool isBuy = false; double op = 0, sl = 0, tp = 0, vol = 0, pl = 0;
   bool has = GetMyPos(tk, isBuy, op, sl, tp, vol, pl);
   double riskM = (InpLotMode == AMC_LOT_RISK) ? RiskMoney() : 0;
   double mppL  = MoneyPerPricePerLot(true);
   if(InpLotMode == AMC_LOT_FIXED) riskM = InpMaxSL * InpFixedLot * mppL;

   // Row 2
   if(has)
   {
      SetTxt("BP_V", StringFormat("%+.2f", pl), pl >= 0 ? CK_GREEN : CK_RED);
      SetTxt("BP_S", StringFormat("%s \x00B7 %.2f lot \x00B7 peak %s", isBuy ? "BUY" : "SELL", vol, Money(gPeak)), CK_LABEL);
      double k = InpLockPerLot ? vol / 0.01 : 1.0;
      if(gLockNow > 0)
      {
         SetTxt("LK_V", StringFormat("+%.2f", gLockNow), CK_GREEN);
         SetTxt("LK_S", "pakka profit (SL)", CK_LABEL);
      }
      else
      {
         SetTxt("LK_V", "--", CK_LABEL);
         SetTxt("LK_S", InpUseLock ? StringFormat("lock +$%.2f par", InpLockTrigger * k) : "lock OFF", CK_LABEL);
      }
   }
   else
   {
      SetTxt("BP_V", "--", CK_LABEL);
      SetTxt("BP_S", "koi trade khula nahi", CK_LABEL);
      SetTxt("LK_V", "--", CK_LABEL);
      SetTxt("LK_S", InpUseLock ? StringFormat("$%.0f par $%.0f pakka", InpLockTrigger, InpLockKeep) : "lock OFF", CK_LABEL);
   }
   SetTxt("DY_V", StringFormat("%+.2f", gDayPL), gDayPL >= 0 ? CK_GREEN : CK_RED);
   SetTxt("DY_S", InpMaxTradesDay > 0 ? StringFormat("%d / %d trade aaj", gDayTrades, InpMaxTradesDay) : StringFormat("%d trade aaj", gDayTrades), CK_LABEL);
   SetTxt("RK_V", DoubleToString(riskM, 2), CK_AMBER);
   SetTxt("RK_S", InpLotMode == AMC_LOT_RISK ? StringFormat("%.1f%% \x00B7 TP = SL x %.1f", InpRiskPct, InpRR)
                                             : StringFormat("fixed %.2f \x00B7 max SL", InpFixedLot), CK_LABEL);

   // Row 3: risk gauge (khula loss / 1 trade ka risk)
   double frac = (has && pl < 0 && riskM > 0) ? MathMin(1.0, -pl / riskM) : 0;
   int fill = (int)MathCeil(frac * 20 - 1e-9);
   SetTxt("DD_L", StringFormat("RISK GAUGE \x00B7 %s OF -$%.0f", Money(has ? MathMin(pl, 0) : 0), riskM), CK_LABEL);
   for(int i = 0; i < 20; i++)
   {
      color on  = i < 14 ? CK_GREEN : (i < 17 ? CK_AMBER : CK_RED);
      color off = i < 14 ? CK_OFF : (i < 17 ? CK_AMBBG : CK_REDBG);
      ObjectSetInteger(0, PNL + "DD_S" + IntegerToString(i), OBJPROP_BGCOLOR, i < fill ? on : off);
      ObjectSetInteger(0, PNL + "DD_S" + IntegerToString(i), OBJPROP_COLOR, i < fill ? on : off);
   }

   // Row 4: lights
   bool full = InpMaxTradesDay > 0 && gDayTrades >= InpMaxTradesDay;
   SetLight("LT", StringFormat("TRADES %d/%d", gDayTrades, InpMaxTradesDay), full ? 2 : 1);
   double spr = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool sprOk = InpMaxSpreadPts <= 0 || SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= InpMaxSpreadPts;
   SetLight("LS", StringFormat("SPREAD %.2f", spr), sprOk ? 1 : 3);
   bool algo = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED);
   SetLight("LA", algo ? "ALGO ON" : "ALGO OFF", algo ? 1 : 3);
   MqlDateTime sv; TimeToStruct(TimeTradeServer(), sv);
   bool inTime = sv.hour >= InpStartHour && sv.hour < InpEndHour;
   SetLight("LH", InpEndHour >= 24 && InpStartHour <= 0 ? "TIME ALL DAY" : StringFormat("TIME %02d-%02d", InpStartHour, InpEndHour), inTime ? 1 : 2);
   SetLight("LL", !InpUseLock ? "LOCK OFF" : (gLockNow > 0 ? "LOCK ON" : "LOCK READY"), !InpUseLock ? 0 : (gLockNow > 0 ? 1 : 0));
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   bool dLoss = InpDayLossPct > 0 && gDayPL <= -bal * InpDayLossPct / 100.0;
   bool dTgt  = InpDayTargetPct > 0 && gDayPL >= bal * InpDayTargetPct / 100.0;
   SetLight("LD", dLoss ? "DAY LOSS STOP" : (dTgt ? "DAY TARGET" : (full ? "AAJ PURA" : "DAY OK")), dLoss ? 3 : (dTgt || full ? 2 : 1));

   // Row 5
   bool paused = IsPaused();
   SetTxt("ST_V", "\x25B8 " + (paused ? "PAUSE (naya trade nahi)" : (gLastMsg == "" ? "agli candle ka intezaar" : gLastMsg)), paused ? CK_AMBER : CK_GREEN);
   ObjectSetString(0, PNL + BT_PAUSE, OBJPROP_TEXT, paused ? "RESUME" : "PAUSE");
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_COLOR, paused ? CK_GREEN : CK_AMBER);
   ObjectSetInteger(0, PNL + BT_PAUSE, OBJPROP_BORDER_COLOR, paused ? CK_GREEN : CK_AMBER);

   // Row 6
   string info;
   if(has)
      info = StringFormat("ENTRY %s \x00B7 SL %s \x00B7 TP %s \x00B7 EQ $%.2f", DoubleToString(op, _Digits),
                          DoubleToString(sl, _Digits), DoubleToString(tp, _Digits), AccountInfoDouble(ACCOUNT_EQUITY));
   else
      info = StringFormat("BAL $%.2f \x00B7 EQ $%.2f \x00B7 MAGIC %I64d \x00B7 JOURNAL %s", bal, AccountInfoDouble(ACCOUNT_EQUITY),
                          InpMagic, InpJournal ? "ON" : "OFF");
   SetTxt("IN_V", info, CK_LABEL);
   PanelFast();
}

//+------------------------------------------------------------------+
//| EVENTS                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   if(InpRR <= 0 || InpMinSL <= 0)
   {
      Print(EA_NAME, " galat input: RR / MinSL 0 se bada hona chahiye");
      return(INIT_PARAMETERS_INCORRECT);
   }
   gJournal = "AMC_GM_journal_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + ".csv";
   gDoneBar = iTime(_Symbol, InpTF, 0);   // beech candle me entry nahi - agli se
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi <= 0) dpi = 96;
   g_DpiS = dpi / 96.0;
   Comment("");
   TodayStats(true);
   if(InpShowPanel) RebuildPanel();
   Print(EA_NAME, " ", EA_VER, " shuru | ", _Symbol, " ", EnumToString(InpTF),
         " | magic ", InpMagic, " | ", (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL ? "REAL" : "DEMO"),
         " | journal MQL5\\Files\\", gJournal);
   Journal("START", "", 0, 0, 0, 0, 0, EA_VER + StringFormat(" risk %.1f%% RR %.1f lock %.2f/%.2f/%.2f max %d/din buffer %.2f",
           InpRiskPct, InpRR, InpLockTrigger, InpLockKeep, InpLockStep, InpMaxTradesDay, InpSLBuffer));
   EventSetMillisecondTimer(500);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
   ObjectsDeleteAll(0, PNL);
}

void Work()
{
   ManageLock();
   TryEntry();
}

void OnTick() { Work(); }

void OnTimer()
{
   Work();
   g_blink = !g_blink;
   g_tick++;
   if(g_tick % 2 == 0) Panel();
   else                PanelFast();
}

// trade band hua -> journal + alert
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || trans.deal == 0) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagic) return;
   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol) return;
   long en = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_INOUT && en != DEAL_ENTRY_OUT_BY) return;

   double pr  = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   double px  = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
   double vol = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
   long   rsn = HistoryDealGetInteger(trans.deal, DEAL_REASON);
   long   pid = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   string why = rsn == DEAL_REASON_SL ? "SL" : (rsn == DEAL_REASON_TP ? "TP" : (rsn == DEAL_REASON_EXPERT ? "EA" : "HAATH"));
   // kitni der chala
   string dur = "";
   if(HistorySelectByPosition(pid) && HistoryDealsTotal() > 0)
   {
      ulong d0 = HistoryDealGetTicket(0);
      long sec = (long)(HistoryDealGetInteger(trans.deal, DEAL_TIME) - HistoryDealGetInteger(d0, DEAL_TIME));
      dur = StringFormat("%dm %02ds", (int)(sec / 60), (int)(sec % 60));
   }
   // side = jo trade band hua (close deal ulta hota hai)
   string side = HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_SELL ? "BUY" : "SELL";
   TodayStats(true);
   Journal("CLOSE", side, vol, px, 0, 0, pr, StringFormat("%s | peak %s | worst %s | %s", why, Money(gPeak), Money(gWorst), dur));

   bool lockExit = (why == "SL" && pr > 0);
   if(pr < 0 && why == "SL")
      Notify(StringFormat("SL LAGA %s", Money(pr)), 2);
   else
      Notify(StringFormat("%s %s (%s)", pr >= 0 ? "JEET" : "BAND", Money(pr), lockExit ? "LOCK" : why), 1);
   if(InpMaxTradesDay > 0 && gDayTrades >= InpMaxTradesDay && MyPositions() == 0)
      Notify(StringFormat("AAJ PURA %d trade %s", gDayTrades, Money(gDayPL)), 1);
   gPkTicket = 0;
   gLockNow  = 0;
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(InpShowPanel && MathAbs(w - g_LastChartW) > 4) RebuildPanel();
      return;
   }
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(StringFind(sp, PNL + "CA_") == 0 || sp == PNL + "FLASH")
   {
      g_alertLvl = 0; g_flashTill = 0;
      ObjectDelete(0, PNL + "FLASH");
   }
   if(sp == PNL + BT_PAUSE)
   {
      GlobalVariableSet(GvKey("PAUSE"), IsPaused() ? 0 : 1);
      Print(EA_NAME, " ", IsPaused() ? "PAUSE - naya trade nahi" : "RESUME");
      Journal(IsPaused() ? "PAUSE" : "RESUME", "", 0, 0, 0, 0, 0, "button");
   }
   if(sp == PNL + BT_CALL)
   {
      bool real = AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL;
      if(!real || MessageBox("Saare AMC GOLD MASTER trade band karein?", EA_NAME, MB_YESNO | MB_ICONWARNING) == IDYES)
         CloseAll("CLOSE ALL button");
   }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   Panel();
}
//+------------------------------------------------------------------+
