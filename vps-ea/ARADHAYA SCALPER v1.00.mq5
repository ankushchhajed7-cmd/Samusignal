//+------------------------------------------------------------------+
//|                                   ARADHAYA SCALPER v1.00.mq5     |
//|                 Ankush New Vision - Safe Mode Gold Scalper       |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.00 (24-Oct-2026) - POORA NAYA EA (FXMIND SCALPANDO ka idea,   |
//|  lekin SAFE MODE). Default: Cent account 20000, XAUUSD M5.       |
//|  1. Entry  : M15 trend (EMA50 > EMA200 + close EMA50 ke upar =   |
//|              sirf BUY, ulta = sirf SELL) + M5 ki pichli candle   |
//|              trend ki taraf + RSI(14) 50-70 buy / 30-50 sell.     |
//|              Ek samay me sirf EK basket.                          |
//|  2. Filter : spread, ATR (bahut tez market me entry nahi),        |
//|              ASLI news filter (MT5 calendar, USD high impact     |
//|              30 min pehle/baad), IST 02:30-05:30 entry nahi,      |
//|              Shukra 23:00 IST -> Somvar 06:00 IST entry nahi,     |
//|              Shanivar 02:00 IST se pehle basket band.             |
//|  3. Grid   : max 6 level. Gap = ATR x 1.5 (kam se kam $3, max   |
//|              $10), har level par gap x 1.2. Lot: level 1-2 same,  |
//|              phir x1.3. Max lot 0.50. Ek M5 candle me ek hi add.  |
//|              AUTO lot: har 2000 balance par 0.01 (20000 = 0.10).  |
//|  4. Exit   : level 1-3 TP = average + $1.50; level 4+ = average  |
//|              + $0.30 (jaldi bahar). Profit lock: average se $1.0 |
//|              aage gaya to SL = average + $0.30.                   |
//|  5. Safety : BASKET SL = balance ka 10%, server par har trade ki |
//|              SL me laga hota hai (VPS band ho tab bhi). EA khud  |
//|              bhi check karta hai (backup).                        |
//|              Basket loss me band hua -> aaj ke liye EA band.      |
//|              Din ka loss limit 10%.                               |
//|  6. Target : DIN KA 1% (default ON). Aaj ka band P/L + khuli     |
//|              basket = 1% hote hi sab band, EA kal tak band.       |
//|              Restart ke baad bhi yaad rehta hai.                  |
//|  7. Panel  : status, trend, basket, avg/TP/SL, aaj ka P/L vs      |
//|              target, spread/ATR/gap, agli news. Button: CLOSE ALL,|
//|              PAUSE / RESUME. Push alert (phone).                  |
//|  Paise wale sab number ACCOUNT CURRENCY me (cent = USC).          |
//|  Price doori ($) wale input sidhe price me (gold: 1.0 = $1).      |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.00"
#property description "ARADHAYA SCALPER v1.00 - safe mode gold scalper: trend entry, max 6 level grid, server basket SL 10%, daily 1% target."

#include <Trade\Trade.mqh>

#define EA_NAME "ARADHAYA SCALPER v1.00"
#define PFX     "ARS_"

enum ENUM_ARS_LOTMODE
{
   ARS_LOT_FIXED = 0,   // FIXED - neeche wala lot
   ARS_LOT_AUTO  = 1    // AUTO - balance ke hisaab se
};

//--- 1. Account
input group "=== 1. Account ==="
input long   InpMagic          = 24102601;  // Magic number
input string InpComment        = "ARADHAYA"; // Trade comment

//--- 2. Lot
input group "=== 2. Lot ==="
input ENUM_ARS_LOTMODE InpLotMode = ARS_LOT_AUTO; // Lot mode
input double InpFixedLot       = 0.10;   // FIXED mode: pehla lot
input double InpAutoPerBalance = 2000;   // AUTO mode: har itne balance par 0.01 lot
input int    InpFlatLevels     = 2;      // Shuru ke itne level same lot
input double InpLotMult        = 1.3;    // Uske baad lot multiplier
input double InpMaxLot         = 0.50;   // Ek trade ka max lot

//--- 3. Grid
input group "=== 3. Grid ==="
input int    InpMaxLevels      = 6;      // Max level (trades) ek basket me
input double InpATRMult        = 1.5;    // Gap = ATR x ye
input double InpMinGap         = 3.0;    // Kam se kam gap ($ price)
input double InpMaxGap         = 10.0;   // Zyada se zyada pehla gap ($ price)
input double InpGapMult        = 1.2;    // Har level par gap x ye

//--- 4. Exit
input group "=== 4. Exit ==="
input double InpTP             = 1.50;   // TP: average se doori ($ price), level 1-3
input int    InpBELevel        = 4;      // Is level se jaldi bahar (BE mode)
input double InpBEProfit       = 0.30;   // BE mode TP: average se doori ($ price)
input bool   InpUseLock        = true;   // Profit lock chalu
input double InpLockStart      = 1.00;   // Lock: average se itna aage jaye ($ price)
input double InpLockProfit     = 0.30;   // Lock: SL = average + itna ($ price)

//--- 5. Safety
input group "=== 5. Safety ==="
input double InpBasketSLPct    = 10.0;   // Basket SL = balance ka % (loss)
input bool   InpServerSL       = true;   // Basket SL server par har trade me lagao
input double InpDailyTargetPct = 1.0;    // Din ka target % (0 = off)
input double InpDailyLossPct   = 10.0;   // Din ka max loss % (0 = off)
input bool   InpPauseAfterLoss = true;   // Basket loss me band ho to aaj ke liye band

//--- 6. Entry filters
input group "=== 6. Entry filters ==="
input ENUM_TIMEFRAMES InpTF      = PERIOD_M5;  // Entry timeframe
input ENUM_TIMEFRAMES InpTrendTF = PERIOD_M15; // Trend timeframe
input int    InpEmaFast        = 50;     // Trend EMA fast
input int    InpEmaSlow        = 200;    // Trend EMA slow
input int    InpRsiPeriod      = 14;     // RSI period (entry TF)
input double InpRsiBuyMin      = 50;     // BUY: RSI kam se kam
input double InpRsiBuyMax      = 70;     // BUY: RSI zyada se zyada
input double InpRsiSellMin     = 30;     // SELL: RSI kam se kam
input double InpRsiSellMax     = 50;     // SELL: RSI zyada se zyada
input int    InpAtrPeriod      = 14;     // ATR period (entry TF)
input double InpMaxATR         = 8.0;    // ATR isse zyada = entry nahi ($ price)
input double InpMaxSpread      = 0.50;   // Spread isse zyada = entry/add nahi ($ price)

//--- 7. News
input group "=== 7. News filter ==="
input bool   InpNewsFilter     = true;   // News filter (MT5 calendar, high impact)
input string InpNewsCurrencies = "USD";  // Currencies (comma se)
input int    InpNewsBefore     = 30;     // News se pehle (minute) entry nahi
input int    InpNewsAfter      = 30;     // News ke baad (minute) entry nahi

//--- 8. Time (IST)
input group "=== 8. Time filter (IST) ==="
input bool   InpTimeFilter     = true;   // Roz ka no-trade time chalu
input string InpNoTradeStart   = "02:30"; // No-trade shuru (IST)
input string InpNoTradeEnd     = "05:30"; // No-trade khatam (IST)
input bool   InpWeekendGuard   = true;   // Shukra 23:00 se Somvar 06:00 IST entry nahi + Shanivar 02:00 IST basket band

//--- 9. Panel / alert
input group "=== 9. Panel / Alert ==="
input bool   InpPanel          = true;   // Chart panel
input int    InpPanelX         = 10;     // Panel X
input int    InpPanelY         = 25;     // Panel Y
input int    InpFontSize       = 9;      // Font size
input bool   InpPush           = true;   // Phone push alert

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+
CTrade   trade;
int      hEF = INVALID_HANDLE, hES = INVALID_HANDLE, hRSI = INVALID_HANDLE, hATR = INVALID_HANDLE;

datetime gLastBar = 0, gLastAddBar = 0;

// basket
int      gCnt = 0;          // khuli trades
int      gDir = 0;          // 1 buy, -1 sell, 2 mixed
double   gLots = 0, gAvg = 0, gFloat = 0, gSwap = 0, gExtreme = 0;
datetime gBasketStart = 0;
bool     gHadBasket = false;
datetime gLastBasketStart = 0;
double   gSLPrice = 0, gTPPrice = 0;

// din
double   gClosedToday = 0, gDayBase = 0;
datetime gStatsTime = 0;
bool     gDirty = true;

// pause
datetime gPauseDay = 0;
string   gPauseReason = "";
bool     gManualPause = false;
bool     gSkipLossPause = false;

// news
datetime gNewsT[];
string   gNewsN[];
datetime gNewsLoaded = 0;
string   gNewsNow = "", gNewsNext = "";

// panel
string   gWhy = "";
int      gLines = 12;

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
bool IsTester() { return (MQLInfoInteger(MQL_TESTER) != 0); }

bool TradeAllowed()
{
   return (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED));
}

void Push(string txt)
{
   Print(EA_NAME, ": ", txt);
   if(!InpPush || IsTester()) return;
   if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) return;
   SendNotification(EA_NAME + " " + _Symbol + ": " + txt);
}

long ServerOffset()
{
   long off = (long)TimeTradeServer() - (long)TimeGMT();
   return (long)MathRound(off / 900.0) * 900;
}
datetime ServerToIst(datetime t) { return (datetime)((long)t - ServerOffset() + 19800); }
datetime ServerDayStart() { long t = (long)TimeTradeServer(); return (datetime)(t - (t % 86400)); }

int IstWeekMinute()
{
   MqlDateTime d;
   TimeToStruct(ServerToIst(TimeTradeServer()), d);
   return d.day_of_week * 1440 + d.hour * 60 + d.min;
}

int HM(string s)
{
   string p[];
   if(StringSplit(s, ':', p) < 2) return -1;
   return (int)StringToInteger(p[0]) * 60 + (int)StringToInteger(p[1]);
}

double Buf(int h, int shift)
{
   double b[1];
   if(h == INVALID_HANDLE) return EMPTY_VALUE;
   if(CopyBuffer(h, 0, shift, 1, b) != 1) return EMPTY_VALUE;
   return b[0];
}

double TickSize()
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return (ts > 0 ? ts : _Point);
}

double NP(double p)
{
   double ts = TickSize();
   return NormalizeDouble(MathRound(p / ts) * ts, _Digits);
}

// 1 lot ka 1.0 price move = kitne paise (account currency)
double ValuePerPriceLot()
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tv <= 0) tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = TickSize();
   if(tv <= 0 || ts <= 0) return 0;
   return tv / ts;
}

double Spread()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

string Money(double v)
{
   return (v >= 0 ? "+" : "") + DoubleToString(v, 2);
}

//+------------------------------------------------------------------+
//| LOT                                                              |
//+------------------------------------------------------------------+
double NormLot(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   lot = MathRound(lot / step) * step;
   double cap = MathMin(vmax, InpMaxLot);
   if(lot > cap) lot = MathFloor(cap / step) * step;
   if(lot < vmin) lot = vmin;
   return NormalizeDouble(lot, 2);
}

double BaseLot()
{
   if(InpLotMode == ARS_LOT_FIXED) return InpFixedLot;
   double per = (InpAutoPerBalance > 0 ? InpAutoPerBalance : 2000);
   double steps = MathFloor(AccountInfoDouble(ACCOUNT_BALANCE) / per);
   return MathMax(0.01, steps * 0.01);
}

double LotForLevel(int level)
{
   double base = BaseLot();
   double m = 1.0;
   if(level > InpFlatLevels) m = MathPow(InpLotMult, level - InpFlatLevels);
   return NormLot(base * m);
}

//+------------------------------------------------------------------+
//| GAP                                                              |
//+------------------------------------------------------------------+
double BaseGap()
{
   double a = Buf(hATR, 1);
   double g = InpMinGap;
   if(a != EMPTY_VALUE && a > 0) g = a * InpATRMult;
   if(g < InpMinGap) g = InpMinGap;
   if(InpMaxGap > 0 && g > InpMaxGap) g = InpMaxGap;
   return g;
}

// level 'cnt' khula hai -> agla level kitni doori par
double NextGap(int cnt)
{
   int k = MathMax(0, cnt - 1);
   return BaseGap() * MathPow(InpGapMult, k);
}

//+------------------------------------------------------------------+
//| NEWS (MT5 calendar)                                              |
//+------------------------------------------------------------------+
void LoadNews()
{
   ArrayResize(gNewsT, 0); ArrayResize(gNewsN, 0);
   datetime now = TimeTradeServer();
   string cur[];
   int nc = StringSplit(InpNewsCurrencies, ',', cur);
   for(int c = 0; c < nc; c++)
   {
      string cc = cur[c]; StringTrimLeft(cc); StringTrimRight(cc); StringToUpper(cc);
      if(cc == "") continue;
      MqlCalendarValue v[];
      int n = CalendarValueHistory(v, now - 6 * 3600, now + 36 * 3600, NULL, cc);
      for(int i = 0; i < n; i++)
      {
         MqlCalendarEvent ev;
         if(!CalendarEventById(v[i].event_id, ev)) continue;
         if(ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;
         int k = ArraySize(gNewsT);
         ArrayResize(gNewsT, k + 1); ArrayResize(gNewsN, k + 1);
         gNewsT[k] = v[i].time; gNewsN[k] = cc + " " + ev.name;
      }
   }
   gNewsLoaded = TimeLocal();
}

void UpdateNews()
{
   gNewsNow = ""; gNewsNext = "";
   if(!InpNewsFilter || IsTester()) return;
   if(gNewsLoaded == 0 || TimeLocal() - gNewsLoaded > 600) LoadNews();
   long now = (long)TimeTradeServer();
   long bef = (long)MathMax(0, InpNewsBefore) * 60, aft = (long)MathMax(0, InpNewsAfter) * 60;
   datetime best = 0;
   for(int i = 0; i < ArraySize(gNewsT); i++)
   {
      long t = (long)gNewsT[i];
      if(now >= t - bef && now <= t + aft && gNewsNow == "")
         gNewsNow = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES) + " IST";
      if(t > now && (best == 0 || gNewsT[i] < best))
      { best = gNewsT[i]; gNewsNext = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES) + " IST"; }
   }
}

//+------------------------------------------------------------------+
//| TIME                                                             |
//+------------------------------------------------------------------+
bool InNoTradeTime()
{
   if(!InpTimeFilter) return false;
   int s = HM(InpNoTradeStart), e = HM(InpNoTradeEnd);
   if(s < 0 || e < 0 || s == e) return false;
   int m = IstWeekMinute() % 1440;
   if(s < e) return (m >= s && m < e);
   return (m >= s || m < e);
}

bool WeekendNoEntry()
{
   if(!InpWeekendGuard) return false;
   int m = IstWeekMinute();
   int friStop  = 5 * 1440 + 23 * 60;   // Shukra 23:00 IST
   int monStart = 1 * 1440 + 6 * 60;    // Somvar 06:00 IST
   return (m >= friStop || m < monStart);
}

bool WeekendCloseNow()
{
   if(!InpWeekendGuard) return false;
   int m = IstWeekMinute();
   return (m >= 6 * 1440 + 2 * 60);     // Shanivar 02:00 IST ke baad
}

//+------------------------------------------------------------------+
//| HISTORY / DAY                                                    |
//+------------------------------------------------------------------+
double DealsSince(datetime from)
{
   double r = 0;
   if(from <= 0) return 0;
   if(!HistorySelect(from - 1, TimeCurrent() + 3600)) return 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from - 1) continue;
      r += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
         + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
   }
   return r;
}

void DayStats(bool force)
{
   if(!force && !gDirty && TimeCurrent() - gStatsTime < 5) return;
   gClosedToday = DealsSince(ServerDayStart());
   gDayBase = AccountInfoDouble(ACCOUNT_BALANCE) - gClosedToday;
   gStatsTime = TimeCurrent();
   gDirty = false;
}

double DayTargetMoney() { return (InpDailyTargetPct > 0 ? gDayBase * InpDailyTargetPct / 100.0 : 0); }
double DayLossMoney()   { return (InpDailyLossPct   > 0 ? gDayBase * InpDailyLossPct   / 100.0 : 0); }
double SLMoney()        { return AccountInfoDouble(ACCOUNT_BALANCE) * InpBasketSLPct / 100.0; }

//+------------------------------------------------------------------+
//| PAUSE                                                            |
//+------------------------------------------------------------------+
string GvName()   { return PFX + IntegerToString(InpMagic) + "_" + _Symbol + "_pause"; }
string GvBasket() { return PFX + IntegerToString(InpMagic) + "_" + _Symbol + "_bstart"; }

void SetPause(string why)
{
   datetime today = ServerDayStart();
   if(gPauseDay == today) return;          // aaj pehle se band - pehli wajah hi rahegi
   gPauseDay = today;
   gPauseReason = why;
   if(!IsTester()) GlobalVariableSet(GvName(), (double)today);
   Push("AAJ KE LIYE BAND - " + why);
}

bool IsPaused()
{
   datetime today = ServerDayStart();
   if(gPauseDay != 0 && gPauseDay != today) { gPauseDay = 0; gPauseReason = ""; }
   return (gPauseDay == today);
}

//+------------------------------------------------------------------+
//| BASKET                                                           |
//+------------------------------------------------------------------+
void ScanBasket()
{
   gCnt = 0; gDir = 0; gLots = 0; gFloat = 0; gSwap = 0; gExtreme = 0; gBasketStart = 0;
   double pw = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      int d = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double v  = PositionGetDouble(POSITION_VOLUME);
      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      if(gDir == 0) gDir = d; else if(gDir != d) gDir = 2;
      gCnt++;
      gLots += v;
      pw += op * v;
      gFloat += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      gSwap  += PositionGetDouble(POSITION_SWAP);
      if(d == 1) { if(gExtreme == 0 || op < gExtreme) gExtreme = op; }
      else       { if(gExtreme == 0 || op > gExtreme) gExtreme = op; }
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(gBasketStart == 0 || t < gBasketStart) gBasketStart = t;
   }
   gAvg = (gLots > 0 ? pw / gLots : 0);
   if(gCnt == 0) { gSLPrice = 0; gTPPrice = 0; }
}

void CloseAll(string why)
{
   for(int pass = 0; pass < 3; pass++)
   {
      int left = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong tk = PositionGetTicket(i);
         if(tk == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
         if(!trade.PositionClose(tk)) left++;
      }
      if(left == 0) break;
      Sleep(300);
   }
   gDirty = true;
   Print(EA_NAME, ": CLOSE ALL - ", why);
}

// basket khatam hua? nateeja dekho
void CheckBasketDone()
{
   if(gCnt > 0)
   {
      gHadBasket = true;
      if(gLastBasketStart != gBasketStart)
      {
         gLastBasketStart = gBasketStart;
         if(!IsTester()) GlobalVariableSet(GvBasket(), (double)gBasketStart);
      }
      return;
   }
   if(!gHadBasket) return;
   gHadBasket = false;
   gDirty = true;
   if(!IsTester()) GlobalVariableDel(GvBasket());
   double res = DealsSince(gLastBasketStart);
   Push("Basket band: " + Money(res) + " " + AccountInfoString(ACCOUNT_CURRENCY));
   if(res < 0 && InpPauseAfterLoss && !gSkipLossPause)
      SetPause("Basket loss " + Money(res));
   gSkipLossPause = false;
}

//+------------------------------------------------------------------+
//| SERVER SL / TP                                                   |
//+------------------------------------------------------------------+
void ManageStops()
{
   if(gCnt <= 0 || (gDir != 1 && gDir != -1)) return;
   double vpl = ValuePerPriceLot();
   if(vpl <= 0 || gLots <= 0) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minDist = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   double tpDist = (gCnt >= InpBELevel ? InpBEProfit : InpTP);
   double tp = (gDir == 1 ? gAvg + tpDist : gAvg - tpDist);

   // basket SL: is price par poori basket ka loss = balance ka X%
   double sl = 0;
   if(InpServerSL && InpBasketSLPct > 0)
   {
      double room = SLMoney() + gSwap;
      if(room < 0) room = 0;
      double dist = room / (vpl * gLots);
      sl = (gDir == 1 ? gAvg - dist : gAvg + dist);
   }
   // profit lock
   if(InpUseLock && gCnt < InpBELevel)
   {
      if(gDir == 1 && bid >= gAvg + InpLockStart)
      { double l = gAvg + InpLockProfit; if(sl == 0 || l > sl) sl = l; }
      if(gDir == -1 && ask <= gAvg - InpLockStart)
      { double l = gAvg - InpLockProfit; if(sl == 0 || l < sl) sl = l; }
   }
   tp = NP(tp);
   if(sl != 0) sl = NP(sl);

   // price pehle hi paar kar gaya? turant band
   if(gDir == 1)
   {
      if(bid >= tp)            { gSkipLossPause = false; CloseAll("TP (average + doori)"); return; }
      if(sl != 0 && bid <= sl) { CloseAll("SL / lock"); return; }
   }
   else
   {
      if(ask <= tp)            { gSkipLossPause = false; CloseAll("TP (average - doori)"); return; }
      if(sl != 0 && ask >= sl) { CloseAll("SL / lock"); return; }
   }
   gTPPrice = tp; gSLPrice = sl;
   double shownSL = 0;

   double half = TickSize() / 2.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);
      double nSL = curSL, nTP = curTP;

      // SL kabhi peeche nahi (buy: sirf upar, sell: sirf neeche)
      if(sl != 0)
      {
         bool better = (curSL == 0) || (gDir == 1 ? sl > curSL + half : sl < curSL - half);
         bool valid  = (gDir == 1 ? sl < bid - minDist : sl > ask + minDist);
         if(better && valid) nSL = sl;
      }
      if(MathAbs(tp - curTP) > half)
      {
         bool valid = (gDir == 1 ? tp > bid + minDist : tp < ask - minDist);
         if(valid) nTP = tp;
      }
      if(MathAbs(nSL - curSL) > half || MathAbs(nTP - curTP) > half)
      {
         if(!trade.PositionModify(tk, nSL, nTP))
            Print(EA_NAME, ": modify fail #", tk, " ret=", trade.ResultRetcode());
      }
      if(nSL != 0) shownSL = nSL;
   }
   if(shownSL != 0) gSLPrice = shownSL;
}

//+------------------------------------------------------------------+
//| ORDERS                                                           |
//+------------------------------------------------------------------+
bool MarginOk(int dir, double lot)
{
   double price = (dir == 1 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   double m = 0;
   if(!OrderCalcMargin(dir == 1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, m)) return true;
   return (m < AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9);
}

bool OpenTrade(int dir, double lot, int level)
{
   if(!MarginOk(dir, lot)) { Print(EA_NAME, ": margin kam, level ", level, " nahi khola"); return false; }
   string cm = InpComment + " L" + IntegerToString(level);
   bool ok = (dir == 1 ? trade.Buy(lot, _Symbol, 0, 0, 0, cm) : trade.Sell(lot, _Symbol, 0, 0, 0, cm));
   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED && rc != TRADE_RETCODE_DONE_PARTIAL))
   {
      Print(EA_NAME, ": order fail ret=", rc, " ", trade.ResultRetcodeDescription());
      return false;
   }
   gDirty = true;
   return true;
}

//+------------------------------------------------------------------+
//| SIGNAL                                                           |
//+------------------------------------------------------------------+
int TrendDir()
{
   double ef = Buf(hEF, 1), es = Buf(hES, 1);
   double c  = iClose(_Symbol, InpTrendTF, 1);
   if(ef == EMPTY_VALUE || es == EMPTY_VALUE || c <= 0) return 0;
   if(ef > es && c > ef) return 1;
   if(ef < es && c < ef) return -1;
   return 0;
}

// "" = entry ki ijazat. Warna wajah.
string EntryBlock()
{
   if(!TradeAllowed())  return "ALGO TRADING OFF";
   if(IsPaused())       return "AAJ BAND: " + gPauseReason;
   if(gManualPause)     return "PAUSE (button)";
   if(WeekendNoEntry()) return "Weekend - entry nahi";
   if(InNoTradeTime())  return "No-trade time " + InpNoTradeStart + "-" + InpNoTradeEnd + " IST";
   if(gNewsNow != "")   return "NEWS: " + gNewsNow;
   if(InpMaxSpread > 0 && Spread() > InpMaxSpread) return "Spread zyada " + DoubleToString(Spread(), 2);
   double a = Buf(hATR, 1);
   if(InpMaxATR > 0 && a != EMPTY_VALUE && a > InpMaxATR) return "ATR zyada " + DoubleToString(a, 2);
   if(TrendDir() == 0)  return "Trend saaf nahi (M15)";
   return "";
}

int Signal()
{
   int t = TrendDir();
   if(t == 0) return 0;
   double o = iOpen(_Symbol, InpTF, 1), c = iClose(_Symbol, InpTF, 1);
   double r = Buf(hRSI, 1);
   if(o <= 0 || c <= 0 || r == EMPTY_VALUE) return 0;
   if(t == 1  && c > o && r >= InpRsiBuyMin  && r <= InpRsiBuyMax)  return 1;
   if(t == -1 && c < o && r >= InpRsiSellMin && r <= InpRsiSellMax) return -1;
   return 0;
}

void TryEntry()
{
   gWhy = EntryBlock();
   if(gWhy != "") return;
   int s = Signal();
   if(s == 0) { gWhy = "Signal ka intezaar"; return; }
   double lot = LotForLevel(1);
   if(OpenTrade(s, lot, 1))
   {
      gLastAddBar = iTime(_Symbol, InpTF, 0);
      Push((s == 1 ? "BUY" : "SELL") + string(" basket shuru, lot ") + DoubleToString(lot, 2));
      ScanBasket();
      ManageStops();
   }
}

void TryAdd()
{
   if(gCnt <= 0 || gCnt >= InpMaxLevels || (gDir != 1 && gDir != -1)) return;
   if(!TradeAllowed()) return;
   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt == gLastAddBar) return;                                      // ek candle me ek hi add
   if(InpMaxSpread > 0 && Spread() > InpMaxSpread) return;
   double gap = NextGap(gCnt);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool go = (gDir == 1 ? ask <= gExtreme - gap : bid >= gExtreme + gap);
   if(!go) return;
   int level = gCnt + 1;
   double lot = LotForLevel(level);
   if(OpenTrade(gDir, lot, level))
   {
      gLastAddBar = bt;
      Push("Level " + IntegerToString(level) + " add, lot " + DoubleToString(lot, 2));
      ScanBasket();
      ManageStops();
   }
}

//+------------------------------------------------------------------+
//| PANEL                                                            |
//+------------------------------------------------------------------+
void ObjLabel(string nm, int x, int y, string t, color c, int fs)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetString(0, nm, OBJPROP_FONT, "Consolas");
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
}

void ObjButton(string nm, int x, int y, int w, int h, string t, color bg)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetString(0, nm, OBJPROP_FONT, "Arial Black");
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
}

void DrawPanel()
{
   if(!InpPanel) return;
   int fs = MathMax(6, InpFontSize);
   int lh = fs * 2 + 2;
   int w  = fs * 44;
   int h  = lh * gLines + 14 + lh + 8;
   string bg = PFX + "bg";
   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   }
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, InpPanelX);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, InpPanelY);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'16,20,32');
   ObjectSetInteger(0, bg, OBJPROP_COLOR, C'60,180,255');

   string cur = AccountInfoString(ACCOUNT_CURRENCY);
   string L[]; color LC[];
   ArrayResize(L, gLines); ArrayResize(LC, gLines);
   for(int i = 0; i < gLines; i++) { L[i] = ""; LC[i] = clrSilver; }

   L[0] = EA_NAME + "  " + _Symbol; LC[0] = C'60,180,255';

   // status
   string st; color sc;
   if(gCnt > 0 && gDir == 2)      { st = "MIXED basket - khud dekho"; sc = clrOrange; }
   else if(gCnt > 0)              { st = "BASKET CHALU"; sc = clrLime; }
   else
   {
      string b = EntryBlock();
      if(b == "") { st = "TRADING - " + (gWhy == "" ? "Signal ka intezaar" : gWhy); sc = clrLime; }
      else        { st = b; sc = (IsPaused() || gManualPause || !TradeAllowed()) ? clrTomato : clrGold; }
   }
   L[1] = "Status : " + st; LC[1] = sc;

   int t = TrendDir();
   double r = Buf(hRSI, 1);
   L[2] = "Trend  : " + (t == 1 ? "UP (sirf BUY)" : t == -1 ? "DOWN (sirf SELL)" : "FLAT")
        + "   RSI " + (r == EMPTY_VALUE ? "-" : DoubleToString(r, 1));
   LC[2] = (t == 1 ? clrLime : t == -1 ? clrTomato : clrSilver);

   if(gCnt > 0)
   {
      L[3] = "Basket : " + (gDir == 1 ? "BUY" : gDir == -1 ? "SELL" : "MIX") + "  L" + IntegerToString(gCnt)
           + "/" + IntegerToString(InpMaxLevels) + "  Lot " + DoubleToString(gLots, 2)
           + (gCnt >= InpBELevel ? "  (BE mode)" : "");
      LC[3] = clrWhite;
      L[4] = "Avg " + DoubleToString(gAvg, _Digits) + "  TP " + (gTPPrice > 0 ? DoubleToString(gTPPrice, _Digits) : "-")
           + "  SL " + (gSLPrice > 0 ? DoubleToString(gSLPrice, _Digits) : "-");
      LC[4] = clrWhite;
      L[5] = "Floating: " + Money(gFloat) + " " + cur; LC[5] = (gFloat >= 0 ? clrLime : clrTomato);
   }
   else
   {
      L[3] = "Basket : koi nahi"; L[4] = "Avg - TP - SL -"; L[5] = "Floating: 0.00 " + cur;
   }

   double dayPL = gClosedToday + gFloat;
   double tg = DayTargetMoney();
   L[6] = "Aaj P/L: " + Money(dayPL) + " / Target " + (tg > 0 ? "+" + DoubleToString(tg, 2) : "OFF")
        + (gDayBase > 0 ? "  (" + DoubleToString(dayPL / gDayBase * 100.0, 2) + "%)" : "");
   LC[6] = (dayPL >= 0 ? clrLime : clrTomato);

   L[7] = "Basket SL -" + DoubleToString(SLMoney(), 2) + "  Din loss limit "
        + (DayLossMoney() > 0 ? "-" + DoubleToString(DayLossMoney(), 2) : "OFF");
   LC[7] = clrOrange;

   double a = Buf(hATR, 1);
   L[8] = "Spread " + DoubleToString(Spread(), 2) + "  ATR " + (a == EMPTY_VALUE ? "-" : DoubleToString(a, 2))
        + "  Agla gap " + DoubleToString(NextGap(MathMax(1, gCnt)), 2);
   L[9] = "Lot    : pehla " + DoubleToString(LotForLevel(1), 2)
        + (gCnt > 0 && gCnt < InpMaxLevels ? "  agla " + DoubleToString(LotForLevel(gCnt + 1), 2) : "");
   L[10] = "News   : " + (!InpNewsFilter ? "OFF" : IsTester() ? "tester me nahi" :
           gNewsNow != "" ? "ABHI " + gNewsNow : gNewsNext != "" ? "agli " + gNewsNext : "koi high impact nahi");
   LC[10] = (gNewsNow != "" ? clrGold : clrSilver);
   L[11] = "Balance " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "  Equity "
         + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + " " + cur;

   for(int i = 0; i < gLines; i++)
      ObjLabel(PFX + "L" + IntegerToString(i), InpPanelX + 8, InpPanelY + 7 + i * lh, L[i], LC[i], fs);

   int by = InpPanelY + 7 + gLines * lh + 2;
   int bw = (w - 24) / 2;
   ObjButton(PFX + "btnClose", InpPanelX + 8, by, bw, lh + 4, "CLOSE ALL", C'170,30,30');
   ObjButton(PFX + "btnPause", InpPanelX + 16 + bw, by, bw, lh + 4,
             gManualPause ? "RESUME" : "PAUSE", gManualPause ? C'20,120,40' : C'90,90,40');
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| EVENTS                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFillingBySymbol(_Symbol);

   hEF  = iMA(_Symbol, InpTrendTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   hES  = iMA(_Symbol, InpTrendTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(_Symbol, InpTF, InpRsiPeriod, PRICE_CLOSE);
   hATR = iATR(_Symbol, InpTF, InpAtrPeriod);
   if(hEF == INVALID_HANDLE || hES == INVALID_HANDLE || hRSI == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print(EA_NAME, ": indicator handle nahi bana");
      return INIT_FAILED;
   }
   if(InpMaxLevels < 1 || InpTP <= 0 || InpBasketSLPct <= 0)
   {
      Print(EA_NAME, ": galat input (MaxLevels / TP / BasketSL)");
      return INIT_PARAMETERS_INCORRECT;
   }

   // restart ke baad "aaj band" yaad rakho
   if(!IsTester() && GlobalVariableCheck(GvName()))
   {
      datetime d = (datetime)GlobalVariableGet(GvName());
      if(d == ServerDayStart()) { gPauseDay = d; gPauseReason = "restart se pehle band hua tha"; }
   }

   gLastBar = iTime(_Symbol, InpTF, 0);
   ScanBasket();
   if(gCnt > 0)
   {
      gHadBasket = true; gLastBasketStart = gBasketStart; gLastAddBar = gLastBar;
      if(!IsTester()) GlobalVariableSet(GvBasket(), (double)gBasketStart);
   }
   else if(!IsTester() && GlobalVariableCheck(GvBasket()))
   {
      // EA band tha aur basket server SL/TP se band ho gayi - nateeja ab dekho
      gHadBasket = true;
      gLastBasketStart = (datetime)GlobalVariableGet(GvBasket());
   }
   DayStats(true);
   UpdateNews();
   EventSetTimer(1);
   DrawPanel();
   if(InpPush && !IsTester() && !TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      Print(EA_NAME, ": push alert ke liye Tools > Options > Notifications me MetaQuotes ID daalo");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, PFX);
   if(hEF  != INVALID_HANDLE) IndicatorRelease(hEF);
   if(hES  != INVALID_HANDLE) IndicatorRelease(hES);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   Comment("");
}

void OnTick()
{
   bool newBar = false;
   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt != 0 && bt != gLastBar) { gLastBar = bt; newBar = true; }

   ScanBasket();
   DayStats(false);
   CheckBasketDone();

   if(!TradeAllowed()) return;

   // --- din ka target / loss (band P/L + khuli basket)
   double dayPL = gClosedToday + gFloat;
   double tg = DayTargetMoney(), dl = DayLossMoney();
   if(tg > 0 && gDayBase > 0 && dayPL >= tg)
   {
      if(gCnt > 0) { gSkipLossPause = true; CloseAll("Din ka target"); }
      SetPause("DIN KA TARGET " + Money(dayPL));
      return;
   }
   if(dl > 0 && gDayBase > 0 && dayPL <= -dl)
   {
      if(gCnt > 0) CloseAll("Din ka loss limit");
      SetPause("DIN KA LOSS LIMIT " + Money(dayPL));
      return;
   }

   if(gCnt > 0)
   {
      // backup basket SL (server SL ke alawa)
      if(InpBasketSLPct > 0 && gFloat <= -SLMoney()) { CloseAll("BASKET SL (backup)"); return; }
      // weekend se pehle band
      if(WeekendCloseNow()) { gSkipLossPause = true; CloseAll("Weekend se pehle band"); return; }
      ManageStops();
      ScanBasket();
      if(gCnt > 0) TryAdd();
      return;
   }

   if(newBar) TryEntry();
}

void OnTimer()
{
   if(!IsTester()) UpdateNews();
   if(!IsTester()) { ScanBasket(); DayStats(false); }
   if(IsTester() && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   DrawPanel();
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) gDirty = true;
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == PFX + "btnClose")
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ScanBasket();
      if(gCnt > 0) gSkipLossPause = true;
      CloseAll("CLOSE ALL button");
      Push("CLOSE ALL button dabaya");
   }
   else if(sparam == PFX + "btnPause")
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      gManualPause = !gManualPause;
      Push(gManualPause ? "PAUSE: nayi entry band (khuli basket chalti rahegi)" : "RESUME: nayi entry chalu");
   }
   ScanBasket();
   DrawPanel();
}
//+------------------------------------------------------------------+
