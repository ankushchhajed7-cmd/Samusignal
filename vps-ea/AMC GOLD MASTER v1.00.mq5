//+------------------------------------------------------------------+
//|                                       AMC GOLD MASTER v1.00.mq5  |
//|                 Ankush New Vision - M5 candle momentum gold EA   |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.00 (30-Oct-2026) - pehla build                                |
//|  GrowthMasters (purchased) ke 4 din / 20 trade ke observation se |
//|  - ENTRY: har M5 candle khulte hi (pehle 30 sec me), sirf jab     |
//|    apna koi trade khula na ho. Pichhli candle HARI = BUY,         |
//|    LAAL = SELL, doji (body < 0.10) = skip                         |
//|  - SL: pichhli candle ke low (BUY) / high (SELL) se 0.30 bahar,    |
//|    kam se kam 1.00, 10.00 se bada = trade skip                    |
//|  - TP: SL doori x 1.5                                             |
//|  - LOT: balance ka 1% risk (SL lage to ~1% jaata hai)             |
//|  - LOCK ($): profit $2 hote hi SL = +$1, phir har +$1 par lock     |
//|    bhi +$1 (profit se $1 peeche). Default GrowthMasters jaisa      |
//|    fixed $ (lot kitna bhi ho). 'Lock lot ke saath' ON = $ values   |
//|    0.01 lot ke liye, lot badhne par utne guna                     |
//|  - Din me max 5 trade (server din, 00:00 se)                      |
//|  - Extra suraksha (default OFF): day loss %, day target %,        |
//|    max spread                                                     |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.00"
#property description "AMC GOLD MASTER v1.00 - M5 candle colour entry, 1% risk, $ lock trail, 5 trades/day"

#include <Trade\Trade.mqh>

#define EA_NAME  "AMC GOLD MASTER"
#define EA_VER   "v1.00"

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

//=== GLOBALS =======================================================
CTrade   trade;
datetime gDoneBar   = 0;     // is candle pe faisla ho chuka
datetime gTryBar    = 0;
int      gTries     = 0;
string   gLastMsg   = "";

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
   // jis candle pe EA laga, uspe beech me entry nahi - agli candle se
   gDoneBar = iTime(_Symbol, InpTF, 0);
   Print(EA_NAME, " ", EA_VER, " shuru | ", _Symbol, " ", EnumToString(InpTF),
         " | magic ", InpMagic, " | ", (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL ? "REAL" : "DEMO"));
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

void OnTimer() { Work(); }
void OnTick()  { Work(); }

//+------------------------------------------------------------------+
void Work()
{
   ManageLock();
   TryEntry();
   ShowInfo();
}

//+------------------------------------------------------------------+
//| helpers                                                          |
//+------------------------------------------------------------------+
double NormP(double p) { return NormalizeDouble(p, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)); }

double MinStopDist()
{
   long lv = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long fz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(lv, fz) * _Point;
}

// 1 lot par 1.0 price chalne se kitne $ (profit / loss)
double MoneyPerPricePerLot(bool loss)
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(_Symbol, loss ? SYMBOL_TRADE_TICK_VALUE_LOSS : SYMBOL_TRADE_TICK_VALUE_PROFIT);
   if(tv <= 0) tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0 || tv <= 0) return 0;
   return tv / ts;
}

datetime DayStart()
{
   return StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
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

// aaj ke trade (entries) aur aaj ka band hua P/L
void TodayStats(int &trades, double &pl)
{
   trades = 0; pl = 0;
   if(!HistorySelect(DayStart(), TimeCurrent() + 60)) return;
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_IN) trades++;
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_INOUT || en == DEAL_ENTRY_OUT_BY)
         pl += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
   }
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
      double mpp  = MoneyPerPricePerLot(true);
      double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPct / 100.0;
      if(mpp <= 0 || slDist <= 0) return 0;
      lot = risk / (slDist * mpp);
   }
   lot = MathFloor(lot / vstp) * vstp;
   if(lot < vmin) lot = vmin;
   lot = MathMin(lot, MathMin(vmax, InpMaxLot));
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| ENTRY - har nayi candle ke shuru me                              |
//+------------------------------------------------------------------+
void TryEntry()
{
   datetime bar0 = iTime(_Symbol, InpTF, 0);
   if(bar0 == 0 || bar0 == gDoneBar) return;

   // sirf candle ke pehle X second me (GrowthMasters jaisa)
   if(TimeCurrent() - bar0 > InpEntryWindowSec) { gDoneBar = bar0; return; }

   if(MyPositions() > 0) { gDoneBar = bar0; gLastMsg = "trade khula hai - agli candle"; return; }

   MqlDateTime tm; TimeToStruct(bar0, tm);
   if(tm.hour < InpStartHour || tm.hour >= InpEndHour) { gDoneBar = bar0; gLastMsg = "time ke bahar"; return; }

   int trades; double pl;
   TodayStats(trades, pl);
   if(InpMaxTradesDay > 0 && trades >= InpMaxTradesDay) { gDoneBar = bar0; gLastMsg = "aaj ke " + IntegerToString(trades) + " trade poore"; return; }
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(InpDayLossPct > 0 && pl <= -bal * InpDayLossPct / 100.0)  { gDoneBar = bar0; gLastMsg = "day loss poora"; return; }
   if(InpDayTargetPct > 0 && pl >= bal * InpDayTargetPct / 100.0) { gDoneBar = bar0; gLastMsg = "day target poora"; return; }

   if(InpMaxSpreadPts > 0)
   {
      long spr = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spr > InpMaxSpreadPts) { gLastMsg = "spread zyada " + IntegerToString(spr); return; } // window me dobara dekhega
   }

   double o1 = iOpen(_Symbol, InpTF, 1), c1 = iClose(_Symbol, InpTF, 1);
   double h1 = iHigh(_Symbol, InpTF, 1), l1 = iLow(_Symbol, InpTF, 1);
   if(o1 == 0 || c1 == 0) return;
   double body = c1 - o1;
   if(MathAbs(body) < InpMinBody) { gDoneBar = bar0; gLastMsg = "pichhli candle doji - skip"; return; }

   bool   isBuy = (body > 0);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double px  = isBuy ? ask : bid;
   double sl  = isBuy ? l1 - InpSLBuffer : h1 + InpSLBuffer;
   double dist = isBuy ? px - sl : sl - px;
   double minD = MathMax(InpMinSL, MinStopDist() + 2 * _Point);
   if(dist < minD) { dist = minD; sl = isBuy ? px - dist : px + dist; }
   if(dist > InpMaxSL) { gDoneBar = bar0; gLastMsg = "SL " + DoubleToString(dist, 2) + " bahut bada - skip"; Print(EA_NAME, " ", gLastMsg); return; }
   double tp = isBuy ? px + dist * InpRR : px - dist * InpRR;

   double lot = CalcLot(dist);
   if(lot <= 0) { gDoneBar = bar0; gLastMsg = "lot 0 - skip"; return; }

   if(gTryBar != bar0) { gTryBar = bar0; gTries = 0; }
   gTries++;
   bool ok = isBuy ? trade.Buy(lot, _Symbol, 0, NormP(sl), NormP(tp), InpComment)
                   : trade.Sell(lot, _Symbol, 0, NormP(sl), NormP(tp), InpComment);
   uint rc = trade.ResultRetcode();
   if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL))
   {
      gDoneBar = bar0;
      double risk = dist * lot * MoneyPerPricePerLot(true);
      gLastMsg = (isBuy ? "BUY " : "SELL ") + DoubleToString(lot, 2) + " | SL " + DoubleToString(dist, 2) + " | risk $" + DoubleToString(risk, 2);
      Print(EA_NAME, " ", gLastMsg, " | pichhli candle O ", DoubleToString(o1, _Digits), " C ", DoubleToString(c1, _Digits),
            " | aaj ka trade #", trades + 1);
   }
   else
   {
      gLastMsg = "order fail code " + IntegerToString((int)rc);
      Print(EA_NAME, " ", gLastMsg, " (koshish ", gTries, ")");
      if(gTries >= 3) gDoneBar = bar0;
   }
}

//+------------------------------------------------------------------+
//| LOCK - profit $ ke hisaab se SL aage                              |
//+------------------------------------------------------------------+
void ManageLock()
{
   if(!InpUseLock || InpLockTrigger <= 0) return;
   double mpp  = MoneyPerPricePerLot(false);
   if(mpp <= 0) return;
   double minD = MinStopDist();
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

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

      double k    = InpLockPerLot ? vol / 0.01 : 1.0;
      double trig = InpLockTrigger * k;
      double keep = InpLockKeep * k;
      double step = MathMax(0.01, InpLockStep * k);
      if(profit < trig) continue;

      double lockM = keep + MathFloor((profit - trig) / step) * step;
      double d     = lockM / (vol * mpp);               // $ -> price doori
      double nsl   = isBuy ? op + d : op - d;

      // broker ki min doori
      if(isBuy  && nsl > bid - minD) nsl = bid - minD;
      if(!isBuy && nsl < ask + minD) nsl = ask + minD;
      nsl = NormP(nsl);

      bool better = (sl == 0) || (isBuy ? nsl > sl + _Point / 2 : nsl < sl - _Point / 2);
      bool inProfit = isBuy ? nsl > op : nsl < op;
      if(!better || !inProfit) continue;

      if(trade.PositionModify(t, nsl, tp))
         Print(EA_NAME, " LOCK #", t, " profit $", DoubleToString(profit, 2), " -> pakka $", DoubleToString(lockM, 2),
               " | SL ", DoubleToString(nsl, _Digits));
      else
         Print(EA_NAME, " lock fail #", t, " code ", trade.ResultRetcode());
   }
}

//+------------------------------------------------------------------+
void ShowInfo()
{
   int trades; double pl;
   TodayStats(trades, pl);
   datetime bar0 = iTime(_Symbol, InpTF, 0);
   int left = (int)(bar0 + PeriodSeconds(InpTF) - TimeCurrent());
   string s = EA_NAME + " " + EA_VER + "  |  " + _Symbol + " " + EnumToString(InpTF) + "\n";
   s += "Aaj trade: " + IntegerToString(trades) + (InpMaxTradesDay > 0 ? " / " + IntegerToString(InpMaxTradesDay) : "") +
        "   |   Aaj P/L: $" + DoubleToString(pl, 2) + "\n";
   s += "Lot: " + (InpLotMode == AMC_LOT_RISK ? DoubleToString(InpRiskPct, 1) + "% risk" : DoubleToString(InpFixedLot, 2) + " fixed") +
        "   |   Lock: $" + DoubleToString(InpLockTrigger, 2) + " par $" + DoubleToString(InpLockKeep, 2) +
        (InpLockPerLot ? " (0.01 lot ke hisaab)" : "") + "\n";
   s += "Agli candle: " + IntegerToString(MathMax(left, 0)) + " sec   |   Khule trade: " + IntegerToString(MyPositions()) + "\n";
   s += "Last: " + gLastMsg;
   Comment(s);
}
//+------------------------------------------------------------------+
