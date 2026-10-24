//+------------------------------------------------------------------+
//|                                   ARADHAYA SCALPER v2.01.mq5     |
//|          Ankush New Vision - Multi-Engine Safe Gold Scalper      |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v2.01 (24-Oct-2026) - Ankush ki setting + 6 mahine ka re-test:   |
//|  - AUTO lot: har 3000 balance par 0.01 (20000 = 0.06,            |
//|    50000 = 0.16)                                                  |
//|  - Din ka target 1% -> 0.80%                                      |
//|  - Group SL 10% -> 8%, din ka loss limit 10% -> 8% (re-test me    |
//|    DD 15% -> 11-12%, profit lagbhag same)                         |
//|  - Group target ab pehle lot ke hisaab se: pehla lot x $4.0 move  |
//|    (20000 / 0.06 lot = 24 USC). Pehle balance ka 0.2% tha - chhote|
//|    lot par der lagti thi                                          |
//|  - Lot limit ab apne aap: kul = pehla lot x 15, net = pehla lot   |
//|    x 6 (20000 = 0.90 / 0.36, 50000 = 2.40 / 0.96). Balance badle  |
//|    to hath se kuch nahi badalna                                   |
//|  Trading niyam (engine, regime, grid, TP) v2.00 jaise hi          |
//| v2.00 (24-Oct-2026) - MULTI ENGINE + MANAGER (6 mahine ke M5     |
//|  backtest me sabse achha setup "L2" - usi ke niyam).             |
//|  ENGINES (har engine ka alag magic, alag basket):                 |
//|   E1 Trend   : sirf TREND regime. M15 EMA50/200 + M5 candle +     |
//|                RSI. MARKET order. Max 4 level, TP avg + 1.50      |
//|   E2 Range   : sirf RANGE regime. Bollinger(20,2) neeche BUY      |
//|                LIMIT, upar SELL LIMIT (OCO, 2 candle). Max 4,     |
//|                TP avg + 1.50                                      |
//|   E3 Breakout: (DEFAULT OFF - backtest me kamzor) 1 ghante ka     |
//|                High/Low + 0.2 ATR par BUY/SELL STOP (OCO)         |
//|   E4 Chop    : RANGE/MIXED regime. 1 ghante ka box (1-4 ATR):     |
//|                neeche BUY LIMIT, upar SELL LIMIT (OCO, 2 candle). |
//|                Max 3 level, TP avg + 0.75                         |
//|  GRID (sab engine): gap = ATR x1.5 (min $3, max $10), har level  |
//|   x1.2. Lot L1-L2 same, phir x1.3. Ek candle me ek hi add.        |
//|   Level 4+ = TP avg + 0.30 (jaldi bahar).                         |
//|  MANAGER:                                                         |
//|   Regime  : M15 ADX(14) >= 25 aur CHOP(14) < 50 = TREND,          |
//|             ADX < 20 aur CHOP > 55 = RANGE, baaki MIXED.          |
//|             Regime badla -> galat engine ke pending cancel.       |
//|   Group exit: is cycle ka BANK (band hue trades) + sab engine ki  |
//|             floating >= balance ka 0.2% -> SAB band (pending bhi).|
//|   Exposure: kul lot (khule + pending) max 1.50, BUY-SELL farq     |
//|             max 0.60.                                             |
//|   Group SL: sab ki floating = -10% balance -> sab band, aaj band. |
//|   Din     : 1% target -> sab band, kal tak band. Loss limit 10%.  |
//|   Server  : har trade / pending me EMERGENCY SL (basket ka 15%)   |
//|             - VPS band ho tab bhi bachav. Asli 10% EA dekhta hai. |
//|  FILTERS: spread 0.50, ATR 8 (E1/E2), MT5 news USD high +-30 min, |
//|   IST 02:30-05:30, Shukra 23:00 -> Somvar 06:00 IST entry nahi,   |
//|   Shanivar 02:00 IST sab band. News / time / pause par pending    |
//|   orders turant cancel.                                           |
//|  Default: Cent 20000, XAUUSD M5, AUTO lot (20000 = 0.10).         |
//|  Paise wale number ACCOUNT CURRENCY me (cent = USC).              |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "2.01"
#property description "ARADHAYA SCALPER v2.01 - multi engine (Trend / Range / Chop, Breakout optional) + manager: regime filter, group exit, exposure cap, group SL 10%, daily 1% target."

#include <Trade\Trade.mqh>

#define EA_NAME "ARADHAYA SCALPER v2.01"
#define PFX     "AR2_"
#define NE      4          // E1, E2, E3, E4

enum ENUM_AR2_LOTMODE
{
   AR2_LOT_FIXED = 0,   // FIXED - neeche wala lot
   AR2_LOT_AUTO  = 1    // AUTO - balance ke hisaab se
};

enum ENUM_AR2_REGIME { RG_MIXED = 0, RG_TREND = 1, RG_RANGE = 2 };

//--- 1. Account
input group "=== 1. Account ==="
input long   InpMagicBase      = 24102610;    // Magic base (E1=+1, E2=+2, E3=+3, E4=+4)
input string InpComment        = "AR2";       // Trade comment

//--- 2. Engines
input group "=== 2. Engines ==="
input bool   InpE1On           = true;   // E1 Trend chalu
input bool   InpE2On           = true;   // E2 Range chalu
input bool   InpE3On           = false;  // E3 Breakout chalu (backtest me kamzor - OFF)
input bool   InpE4On           = true;   // E4 Chop Scalper chalu
input double InpE1TP           = 1.50;   // E1 TP: average se ($ price)
input double InpE2TP           = 1.50;   // E2 TP: average se ($ price)
input double InpE3TP           = 1.50;   // E3 TP: average se ($ price)
input double InpE4TP           = 0.75;   // E4 TP: average se ($ price)
input int    InpE1MaxLv        = 4;      // E1 max level
input int    InpE2MaxLv        = 4;      // E2 max level
input int    InpE3MaxLv        = 4;      // E3 max level
input int    InpE4MaxLv        = 3;      // E4 max level
input int    InpBELevel        = 4;      // Is level se jaldi bahar
input double InpBEProfit       = 0.30;   // Jaldi bahar TP: average se ($ price)

//--- 3. Lot
input group "=== 3. Lot ==="
input ENUM_AR2_LOTMODE InpLotMode = AR2_LOT_AUTO; // Lot mode
input double InpFixedLot       = 0.10;   // FIXED mode: pehla lot
input double InpAutoPerBalance = 3000;   // AUTO mode: har itne balance par 0.01 lot
input int    InpFlatLevels     = 2;      // Shuru ke itne level same lot
input double InpLotMult        = 1.3;    // Uske baad lot multiplier
input double InpMaxLot         = 0.50;   // Ek trade ka max lot

//--- 4. Grid
input group "=== 4. Grid ==="
input double InpATRMult        = 1.5;    // Gap = ATR x ye
input double InpMinGap         = 3.0;    // Kam se kam gap ($ price)
input double InpMaxGap         = 10.0;   // Zyada se zyada pehla gap ($ price)
input double InpGapMult        = 1.2;    // Har level par gap x ye

//--- 5. Manager
input group "=== 5. Manager (regime / group) ==="
input bool   InpUseRegime      = true;   // Regime filter (har engine sirf apne regime me)
input ENUM_TIMEFRAMES InpRegimeTF = PERIOD_M15; // Regime timeframe
input int    InpAdxPeriod      = 14;     // ADX period
input int    InpChopPeriod     = 14;     // Choppiness period
input double InpTrendAdx       = 25;     // TREND: ADX kam se kam
input double InpTrendChopMax   = 50;     // TREND: CHOP isse kam
input double InpRangeAdx       = 20;     // RANGE: ADX isse kam
input double InpRangeChopMin   = 55;     // RANGE: CHOP isse zyada
input bool   InpGroupExit      = true;   // Group exit (bank + floating)
input double InpGroupTargetMove = 4.0;   // Group target: pehla lot x itna $ move (paise)
input double InpMaxTotalX      = 15;     // Kul lot max = pehla lot x ye (khule + pending)
input double InpMaxNetX        = 6;      // BUY - SELL farq max = pehla lot x ye

//--- 6. Safety
input group "=== 6. Safety ==="
input double InpGroupSLPct     = 8.0;    // Group SL: sab ki floating = balance ka -%
input double InpEmergencySLPct = 15.0;   // Server emergency SL: har basket ka % (VPS band ho tab)
input double InpDailyTargetPct = 0.8;    // Din ka target % (0 = off)
input double InpDailyLossPct   = 8.0;    // Din ka max loss % (0 = off)
input bool   InpPauseAfterSL   = true;   // Group SL ke baad aaj ke liye band

//--- 7. Entry
input group "=== 7. Entry ==="
input ENUM_TIMEFRAMES InpTF      = PERIOD_M5;  // Entry timeframe
input ENUM_TIMEFRAMES InpTrendTF = PERIOD_M15; // E1 trend timeframe
input int    InpEmaFast        = 50;     // E1 EMA fast
input int    InpEmaSlow        = 200;    // E1 EMA slow
input int    InpRsiPeriod      = 14;     // E1 RSI period
input double InpRsiBuyMin      = 50;     // E1 BUY: RSI kam se kam
input double InpRsiBuyMax      = 70;     // E1 BUY: RSI zyada se zyada
input double InpRsiSellMin     = 30;     // E1 SELL: RSI kam se kam
input double InpRsiSellMax     = 50;     // E1 SELL: RSI zyada se zyada
input int    InpBBPeriod       = 20;     // E2 Bollinger period
input double InpBBDev          = 2.0;    // E2 Bollinger deviation
input int    InpBoxBars        = 12;     // E3/E4 box candles (12 x M5 = 1 ghanta)
input double InpBoxMinATR      = 1.0;    // E4 box kam se kam (x ATR)
input double InpBoxMaxATR      = 4.0;    // E4 box zyada se zyada (x ATR)
input double InpE4Offset       = 0.10;   // E4 limit box ke andar (x ATR)
input double InpE3Buffer       = 0.20;   // E3 stop box ke bahar (x ATR)
input double InpE3AtrRise      = 1.10;   // E3: ATR > 20-candle average x ye
input int    InpPendBarsLimit  = 2;      // E2/E4 pending kitni candle
input int    InpPendBarsStop   = 12;     // E3 pending kitni candle
input int    InpAtrPeriod      = 14;     // ATR period
input double InpMaxATR         = 8.0;    // E1/E2: ATR isse zyada = entry nahi ($ price)
input double InpMaxSpread      = 0.50;   // Spread isse zyada = entry/add nahi ($ price)

//--- 8. News
input group "=== 8. News filter ==="
input bool   InpNewsFilter     = true;   // News filter (MT5 calendar, high impact)
input string InpNewsCurrencies = "USD";  // Currencies (comma se)
input int    InpNewsBefore     = 30;     // News se pehle (minute)
input int    InpNewsAfter      = 30;     // News ke baad (minute)

//--- 9. Time (IST)
input group "=== 9. Time filter (IST) ==="
input bool   InpTimeFilter     = true;   // Roz ka no-trade time
input string InpNoTradeStart   = "02:30"; // No-trade shuru (IST)
input string InpNoTradeEnd     = "05:30"; // No-trade khatam (IST)
input bool   InpWeekendGuard   = true;   // Shukra 23:00 -> Somvar 06:00 IST entry nahi + Shanivar 02:00 IST sab band

//--- 10. Panel / alert
input group "=== 10. Panel / Alert ==="
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
int      hBB = INVALID_HANDLE, hADX = INVALID_HANDLE;

string   ENAME[NE] = {"E1 Trend", "E2 Range", "E3 Break", "E4 Chop"};

// engine state
bool     eOn[NE];
double   eTP[NE];
int      eMaxLv[NE];
int      eCnt[NE], eDir[NE], ePend[NE];
double   eLots[NE], eAvg[NE], eFloat[NE], eSwap[NE], eExt[NE], eTPPx[NE], eSLPx[NE];
datetime eLastAddBar[NE];
int      ePrevCnt[NE];

// totals
double   gFloat = 0, gBuyLots = 0, gSellLots = 0;
int      gOpen = 0, gPendAll = 0;

datetime gLastBar = 0;
int      gRegime = RG_MIXED;
double   gAdx = 0, gChop = 0;

// cycle / day
datetime gCycleStart = 0;
double   gBank = 0, gClosedToday = 0, gDayBase = 0;
datetime gStatsTime = 0;
bool     gDirty = true;

// pause
datetime gPauseDay = 0;
string   gPauseReason = "";
bool     gManualPause = false;

// news
datetime gNewsT[];
string   gNewsN[];
datetime gNewsLoaded = 0;
string   gNewsNow = "", gNewsNext = "";

int      gLines = 15;

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
bool IsTester() { return (MQLInfoInteger(MQL_TESTER) != 0); }
bool TradeAllowed() { return (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED)); }

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

double Buf(int h, int buffer, int shift)
{
   double b[1];
   if(h == INVALID_HANDLE) return EMPTY_VALUE;
   if(CopyBuffer(h, buffer, shift, 1, b) != 1) return EMPTY_VALUE;
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

double ValuePerPriceLot()
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tv <= 0) tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = TickSize();
   if(tv <= 0 || ts <= 0) return 0;
   return tv / ts;
}

double Spread() { return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID); }
string Money(double v) { return (v >= 0 ? "+" : "") + DoubleToString(v, 2); }
double Bal() { return AccountInfoDouble(ACCOUNT_BALANCE); }

long EMagic(int e) { return InpMagicBase + e + 1; }
int  EngOfMagic(long m)
{
   long k = m - InpMagicBase - 1;
   if(k < 0 || k >= NE) return -1;
   return (int)k;
}

//+------------------------------------------------------------------+
//| LOT / GAP                                                        |
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
   if(InpLotMode == AR2_LOT_FIXED) return InpFixedLot;
   double per = (InpAutoPerBalance > 0 ? InpAutoPerBalance : 2000);
   return MathMax(0.01, MathFloor(Bal() / per) * 0.01);
}

double LotForLevel(int level)
{
   double m = 1.0;
   if(level > InpFlatLevels) m = MathPow(InpLotMult, level - InpFlatLevels);
   return NormLot(BaseLot() * m);
}

double ATR1() { return Buf(hATR, 0, 1); }

double NextGap(int cnt)
{
   double a = ATR1();
   double g = InpMinGap;
   if(a != EMPTY_VALUE && a > 0) g = a * InpATRMult;
   if(g < InpMinGap) g = InpMinGap;
   if(InpMaxGap > 0 && g > InpMaxGap) g = InpMaxGap;
   return g * MathPow(InpGapMult, MathMax(0, cnt - 1));
}

//+------------------------------------------------------------------+
//| NEWS                                                             |
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
   return (m >= 5 * 1440 + 23 * 60 || m < 1 * 1440 + 6 * 60);
}

bool WeekendCloseNow()
{
   if(!InpWeekendGuard) return false;
   return (IstWeekMinute() >= 6 * 1440 + 2 * 60);
}

//+------------------------------------------------------------------+
//| HISTORY / DAY / CYCLE                                            |
//+------------------------------------------------------------------+
// sab engine ke deals ka P/L 'from' ke baad
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
      if(EngOfMagic(HistoryDealGetInteger(d, DEAL_MAGIC)) < 0) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from - 1) continue;
      r += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
         + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
   }
   return r;
}

string GvPause() { return PFX + IntegerToString(InpMagicBase) + "_" + _Symbol + "_pause"; }
string GvCycle() { return PFX + IntegerToString(InpMagicBase) + "_" + _Symbol + "_cycle"; }

void Stats(bool force)
{
   if(!force && !gDirty && TimeCurrent() - gStatsTime < 5) return;
   gClosedToday = DealsSince(ServerDayStart());
   gDayBase = Bal() - gClosedToday;
   gBank = (gCycleStart > 0 ? DealsSince(gCycleStart) : 0);
   gStatsTime = TimeCurrent();
   gDirty = false;
}

double DayTargetMoney() { return (InpDailyTargetPct > 0 ? gDayBase * InpDailyTargetPct / 100.0 : 0); }
double DayLossMoney()   { return (InpDailyLossPct   > 0 ? gDayBase * InpDailyLossPct   / 100.0 : 0); }
double GroupSLMoney()   { return Bal() * InpGroupSLPct / 100.0; }
double GroupTgtMoney()  { return LotForLevel(1) * ValuePerPriceLot() * InpGroupTargetMove; }
double MaxTotalLots()   { return LotForLevel(1) * InpMaxTotalX; }
double MaxNetLots()     { return LotForLevel(1) * InpMaxNetX; }

void SetPause(string why)
{
   datetime today = ServerDayStart();
   if(gPauseDay == today) return;
   gPauseDay = today; gPauseReason = why;
   if(!IsTester()) GlobalVariableSet(GvPause(), (double)today);
   Push("AAJ KE LIYE BAND - " + why);
}

bool IsPaused()
{
   datetime today = ServerDayStart();
   if(gPauseDay != 0 && gPauseDay != today) { gPauseDay = 0; gPauseReason = ""; }
   return (gPauseDay == today);
}

//+------------------------------------------------------------------+
//| SCAN                                                             |
//+------------------------------------------------------------------+
void Scan()
{
   double pw[NE];
   datetime first = 0;
   for(int e = 0; e < NE; e++)
   {
      eCnt[e] = 0; eDir[e] = 0; ePend[e] = 0; eLots[e] = 0; eAvg[e] = 0; eFloat[e] = 0; eSwap[e] = 0; eExt[e] = 0; pw[e] = 0;
   }
   gFloat = 0; gBuyLots = 0; gSellLots = 0; gOpen = 0; gPendAll = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      int e = EngOfMagic(PositionGetInteger(POSITION_MAGIC));
      if(e < 0) continue;
      int d = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double v = PositionGetDouble(POSITION_VOLUME), op = PositionGetDouble(POSITION_PRICE_OPEN);
      if(eDir[e] == 0) eDir[e] = d; else if(eDir[e] != d) eDir[e] = 2;
      eCnt[e]++; eLots[e] += v; pw[e] += op * v;
      double f = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      eFloat[e] += f; eSwap[e] += PositionGetDouble(POSITION_SWAP); gFloat += f;
      if(d == 1) { gBuyLots += v; if(eExt[e] == 0 || op < eExt[e]) eExt[e] = op; }
      else       { gSellLots += v; if(eExt[e] == 0 || op > eExt[e]) eExt[e] = op; }
      gOpen++;
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(first == 0 || t < first) first = t;
   }
   for(int e = 0; e < NE; e++)
   {
      eAvg[e] = (eLots[e] > 0 ? pw[e] / eLots[e] : 0);
      if(eCnt[e] == 0) { eTPPx[e] = 0; eSLPx[e] = 0; }
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      int e = EngOfMagic(OrderGetInteger(ORDER_MAGIC));
      if(e < 0) continue;
      long ty = OrderGetInteger(ORDER_TYPE);
      double v = OrderGetDouble(ORDER_VOLUME_CURRENT);
      if(ty == ORDER_TYPE_BUY_LIMIT || ty == ORDER_TYPE_BUY_STOP) gBuyLots += v;
      else if(ty == ORDER_TYPE_SELL_LIMIT || ty == ORDER_TYPE_SELL_STOP) gSellLots += v;
      ePend[e]++; gPendAll++;
   }

   // cycle: pehli khuli trade se shuru, sab band = cycle khatam
   if(gOpen > 0)
   {
      if(gCycleStart == 0 || first < gCycleStart)
      {
         gCycleStart = first; gDirty = true;
         if(!IsTester()) GlobalVariableSet(GvCycle(), (double)gCycleStart);
      }
   }
   else if(gCycleStart != 0)
   {
      gCycleStart = 0; gBank = 0;
      if(!IsTester()) GlobalVariableDel(GvCycle());
   }
}

bool CanAdd(int dir, double lot)
{
   double b = gBuyLots + (dir == 1 ? lot : 0);
   double s = gSellLots + (dir == -1 ? lot : 0);
   if(InpMaxTotalX > 0 && b + s > MaxTotalLots() + 1e-9) return false;
   if(InpMaxNetX > 0 && MathAbs(b - s) > MaxNetLots() + 1e-9) return false;
   return true;
}

//+------------------------------------------------------------------+
//| CLOSE / CANCEL                                                   |
//+------------------------------------------------------------------+
void CancelPend(int eng)   // eng = -1 -> sab
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      int e = EngOfMagic(OrderGetInteger(ORDER_MAGIC));
      if(e < 0 || (eng >= 0 && e != eng)) continue;
      trade.OrderDelete(tk);
   }
}

void CloseEngine(int eng, string why)   // eng = -1 -> sab
{
   for(int pass = 0; pass < 3; pass++)
   {
      int left = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong tk = PositionGetTicket(i);
         if(tk == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         int e = EngOfMagic(PositionGetInteger(POSITION_MAGIC));
         if(e < 0 || (eng >= 0 && e != eng)) continue;
         if(!trade.PositionClose(tk)) left++;
      }
      if(left == 0) break;
      Sleep(300);
   }
   gDirty = true;
   Print(EA_NAME, ": CLOSE ", (eng < 0 ? "ALL" : ENAME[eng]), " - ", why);
}

void CloseEverything(string why)
{
   CancelPend(-1);
   CloseEngine(-1, why);
   Push("SAB BAND - " + why);
}

//+------------------------------------------------------------------+
//| REGIME                                                           |
//+------------------------------------------------------------------+
double Chop()
{
   int n = MathMax(2, InpChopPeriod);
   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true); ArraySetAsSeries(lo, true); ArraySetAsSeries(cl, true);
   if(CopyHigh(_Symbol, InpRegimeTF, 1, n, hi) < n) return 50;
   if(CopyLow(_Symbol, InpRegimeTF, 1, n, lo) < n) return 50;
   if(CopyClose(_Symbol, InpRegimeTF, 1, n + 1, cl) < n + 1) return 50;
   double sum = 0;
   for(int k = 0; k < n; k++)
   {
      double tr = MathMax(hi[k] - lo[k], MathMax(MathAbs(hi[k] - cl[k + 1]), MathAbs(lo[k] - cl[k + 1])));
      sum += tr;
   }
   double hh = hi[ArrayMaximum(hi)], ll = lo[ArrayMinimum(lo)];
   if(hh - ll <= 0 || sum <= 0) return 50;
   return 100.0 * MathLog10(sum / (hh - ll)) / MathLog10((double)n);
}

void UpdateRegime()
{
   double a = Buf(hADX, 0, 1);
   gAdx = (a == EMPTY_VALUE ? 0 : a);
   gChop = Chop();
   if(gAdx >= InpTrendAdx && gChop < InpTrendChopMax) gRegime = RG_TREND;
   else if(gAdx < InpRangeAdx && gChop > InpRangeChopMin) gRegime = RG_RANGE;
   else gRegime = RG_MIXED;
}

string RegimeName(int r) { return (r == RG_TREND ? "TREND" : r == RG_RANGE ? "RANGE" : "MIXED"); }

// is engine ko is regime me nayi entry ki ijazat?
bool RegimeOk(int e)
{
   if(!InpUseRegime) return true;
   if(e == 0) return (gRegime == RG_TREND);
   if(e == 1) return (gRegime == RG_RANGE);
   if(e == 2) return (gRegime == RG_TREND || gRegime == RG_MIXED);
   if(e == 3) return (gRegime == RG_RANGE || gRegime == RG_MIXED);
   return false;
}

//+------------------------------------------------------------------+
//| STOPS (per engine)                                               |
//+------------------------------------------------------------------+
double EmergencyDist(double lots)
{
   double vpl = ValuePerPriceLot();
   if(vpl <= 0 || lots <= 0 || InpEmergencySLPct <= 0) return 0;
   return Bal() * InpEmergencySLPct / 100.0 / (vpl * lots);
}

void ManageEngine(int e)
{
   if(eCnt[e] <= 0 || (eDir[e] != 1 && eDir[e] != -1)) return;
   int d = eDir[e];
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minDist = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   double tpDist = (eCnt[e] >= InpBELevel ? InpBEProfit : eTP[e]);
   double tp = NP(d == 1 ? eAvg[e] + tpDist : eAvg[e] - tpDist);
   double sl = 0;
   double dist = EmergencyDist(eLots[e]);
   if(dist > 0)
   {
      double room = dist + (eSwap[e] / (ValuePerPriceLot() * eLots[e]));
      if(room < 0) room = 0;
      sl = NP(d == 1 ? eAvg[e] - room : eAvg[e] + room);
   }

   if(d == 1 ? bid >= tp : ask <= tp) { CloseEngine(e, "TP"); return; }
   if(sl != 0 && (d == 1 ? bid <= sl : ask >= sl)) { CloseEngine(e, "Emergency SL"); return; }
   eTPPx[e] = tp; eSLPx[e] = sl;

   double half = TickSize() / 2.0;
   trade.SetExpertMagicNumber(EMagic(e));
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != EMagic(e)) continue;
      double curSL = PositionGetDouble(POSITION_SL), curTP = PositionGetDouble(POSITION_TP);
      double nSL = curSL, nTP = curTP;
      if(sl != 0 && MathAbs(sl - curSL) > half)
      {
         bool valid = (d == 1 ? sl < bid - minDist : sl > ask + minDist);
         if(valid) nSL = sl;
      }
      if(MathAbs(tp - curTP) > half)
      {
         bool valid = (d == 1 ? tp > bid + minDist : tp < ask - minDist);
         if(valid) nTP = tp;
      }
      if(MathAbs(nSL - curSL) > half || MathAbs(nTP - curTP) > half)
         if(!trade.PositionModify(tk, nSL, nTP))
            Print(EA_NAME, ": ", ENAME[e], " modify fail #", tk, " ret=", trade.ResultRetcode());
   }
}

//+------------------------------------------------------------------+
//| ORDERS                                                           |
//+------------------------------------------------------------------+
bool MarginOk(int dir, double lot, double price)
{
   double m = 0;
   if(!OrderCalcMargin(dir == 1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, m)) return true;
   return (m < AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9);
}

bool OkRet()
{
   uint rc = trade.ResultRetcode();
   return (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL);
}

bool MarketOpen(int e, int dir, double lot, int level)
{
   double px = (dir == 1 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   if(!MarginOk(dir, lot, px)) { Print(EA_NAME, ": margin kam - ", ENAME[e]); return false; }
   trade.SetExpertMagicNumber(EMagic(e));
   string cm = InpComment + " E" + IntegerToString(e + 1) + " L" + IntegerToString(level);
   bool ok = (dir == 1 ? trade.Buy(lot, _Symbol, 0, 0, 0, cm) : trade.Sell(lot, _Symbol, 0, 0, 0, cm));
   if(!ok || !OkRet()) { Print(EA_NAME, ": ", ENAME[e], " order fail ret=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription()); return false; }
   gDirty = true;
   if(dir == 1) gBuyLots += lot; else gSellLots += lot;
   return true;
}

// kind: 0 = limit, 1 = stop
bool PlacePending(int e, int dir, int kind, double price, int bars)
{
   double lot = LotForLevel(1);
   if(!CanAdd(dir, lot)) return false;
   price = NP(price);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist = MathMax((double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point, TickSize());
   // price sahi taraf hai?
   if(kind == 0 && dir == 1  && price > ask - minDist) return false;
   if(kind == 0 && dir == -1 && price < bid + minDist) return false;
   if(kind == 1 && dir == 1  && price < ask + minDist) return false;
   if(kind == 1 && dir == -1 && price > bid - minDist) return false;
   if(!MarginOk(dir, lot, price)) return false;

   double tp = NP(dir == 1 ? price + eTP[e] : price - eTP[e]);
   double dist = EmergencyDist(lot);
   double sl = (dist > 0 ? NP(dir == 1 ? price - dist : price + dist) : 0);

   ENUM_ORDER_TYPE_TIME tt = ORDER_TIME_GTC;
   datetime exp = 0;
   long em = SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   if((em & SYMBOL_EXPIRATION_SPECIFIED) != 0)
   {
      tt = ORDER_TIME_SPECIFIED;
      exp = iTime(_Symbol, InpTF, 0) + bars * PeriodSeconds(InpTF);
      if(exp < TimeTradeServer() + 120) exp = TimeTradeServer() + 120;
   }
   trade.SetExpertMagicNumber(EMagic(e));
   string cm = InpComment + " E" + IntegerToString(e + 1) + " L1";
   bool ok;
   if(kind == 0) ok = (dir == 1 ? trade.BuyLimit(lot, price, _Symbol, sl, tp, tt, exp, cm) : trade.SellLimit(lot, price, _Symbol, sl, tp, tt, exp, cm));
   else          ok = (dir == 1 ? trade.BuyStop(lot, price, _Symbol, sl, tp, tt, exp, cm)  : trade.SellStop(lot, price, _Symbol, sl, tp, tt, exp, cm));
   if(!ok || !OkRet())
   {
      Print(EA_NAME, ": ", ENAME[e], " pending fail ret=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return false;
   }
   if(dir == 1) gBuyLots += lot; else gSellLots += lot;
   ePend[e]++; gPendAll++;
   return true;
}

// purane pending (bars se zyada) aur galat regime wale pending hatao
void CleanPendings()
{
   datetime t0 = iTime(_Symbol, InpTF, 0);
   int P = PeriodSeconds(InpTF);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      int e = EngOfMagic(OrderGetInteger(ORDER_MAGIC));
      if(e < 0) continue;
      int bars = (e == 2 ? InpPendBarsStop : InpPendBarsLimit);
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      bool old = (setup < t0 - (bars - 1) * P);
      bool wrong = !RegimeOk(e) || !eOn[e];
      if(old || wrong) trade.OrderDelete(tk);
   }
}

//+------------------------------------------------------------------+
//| ENTRIES                                                          |
//+------------------------------------------------------------------+
int TrendDir()
{
   double ef = Buf(hEF, 0, 1), es = Buf(hES, 0, 1);
   double c = iClose(_Symbol, InpTrendTF, 1);
   if(ef == EMPTY_VALUE || es == EMPTY_VALUE || c <= 0) return 0;
   if(ef > es && c > ef) return 1;
   if(ef < es && c < ef) return -1;
   return 0;
}

// sakht rok: in par pending bhi cancel
string HardBlock()
{
   if(!TradeAllowed())  return "ALGO TRADING OFF";
   if(IsPaused())       return "AAJ BAND: " + gPauseReason;
   if(gManualPause)     return "PAUSE (button)";
   if(WeekendNoEntry()) return "Weekend - entry nahi";
   if(InNoTradeTime())  return "No-trade time " + InpNoTradeStart + "-" + InpNoTradeEnd + " IST";
   if(gNewsNow != "")   return "NEWS: " + gNewsNow;
   return "";
}

void BoxHL(double &hh, double &ll)
{
   double h[], l[];
   hh = 0; ll = 0;
   if(CopyHigh(_Symbol, InpTF, 1, InpBoxBars, h) < InpBoxBars) return;
   if(CopyLow(_Symbol, InpTF, 1, InpBoxBars, l) < InpBoxBars) return;
   hh = h[ArrayMaximum(h)]; ll = l[ArrayMinimum(l)];
}

double AtrAvg(int n)
{
   double b[];
   if(CopyBuffer(hATR, 0, 1, n, b) < n) return 0;
   double s = 0;
   for(int i = 0; i < n; i++) s += b[i];
   return s / n;
}

void TryEntries()
{
   if(InpMaxSpread > 0 && Spread() > InpMaxSpread) return;
   double a = ATR1();
   if(a == EMPTY_VALUE || a <= 0) return;
   bool atrOk = (InpMaxATR <= 0 || a <= InpMaxATR);
   double hh, ll; BoxHL(hh, ll);

   // E1 Trend - market
   if(eOn[0] && eCnt[0] == 0 && atrOk && RegimeOk(0))
   {
      int t = TrendDir(), d = 0;
      double o = iOpen(_Symbol, InpTF, 1), c = iClose(_Symbol, InpTF, 1), r = Buf(hRSI, 0, 1);
      if(r != EMPTY_VALUE)
      {
         if(t == 1  && c > o && r >= InpRsiBuyMin  && r <= InpRsiBuyMax)  d = 1;
         if(t == -1 && c < o && r >= InpRsiSellMin && r <= InpRsiSellMax) d = -1;
      }
      double lot = LotForLevel(1);
      if(d != 0 && CanAdd(d, lot) && MarketOpen(0, d, lot, 1))
      {
         eLastAddBar[0] = iTime(_Symbol, InpTF, 0);
         Push("E1 Trend " + (d == 1 ? "BUY" : "SELL") + " shuru, lot " + DoubleToString(lot, 2));
      }
   }
   // E2 Range - Bollinger limits
   if(eOn[1] && eCnt[1] == 0 && ePend[1] == 0 && atrOk && RegimeOk(1))
   {
      double up = Buf(hBB, 1, 1), lo = Buf(hBB, 2, 1);
      if(up != EMPTY_VALUE && lo != EMPTY_VALUE && up > lo)
      {
         PlacePending(1, 1, 0, lo, InpPendBarsLimit);
         PlacePending(1, -1, 0, up, InpPendBarsLimit);
      }
   }
   // E3 Breakout - stops
   if(eOn[2] && eCnt[2] == 0 && ePend[2] == 0 && RegimeOk(2) && hh > ll)
   {
      double avg = AtrAvg(20);
      if(avg > 0 && a > avg * InpE3AtrRise)
      {
         PlacePending(2, 1, 1, hh + InpE3Buffer * a, InpPendBarsStop);
         PlacePending(2, -1, 1, ll - InpE3Buffer * a, InpPendBarsStop);
      }
   }
   // E4 Chop - box limits
   if(eOn[3] && eCnt[3] == 0 && ePend[3] == 0 && RegimeOk(3) && hh > ll)
   {
      double box = hh - ll;
      if(box >= InpBoxMinATR * a && box <= InpBoxMaxATR * a)
      {
         PlacePending(3, 1, 0, ll + InpE4Offset * a, InpPendBarsLimit);
         PlacePending(3, -1, 0, hh - InpE4Offset * a, InpPendBarsLimit);
      }
   }
}

void TryAdd(int e)
{
   if(eCnt[e] <= 0 || eCnt[e] >= eMaxLv[e] || (eDir[e] != 1 && eDir[e] != -1)) return;
   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt == eLastAddBar[e]) return;
   if(InpMaxSpread > 0 && Spread() > InpMaxSpread) return;
   int d = eDir[e];
   double gap = NextGap(eCnt[e]);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(!(d == 1 ? ask <= eExt[e] - gap : bid >= eExt[e] + gap)) return;
   int level = eCnt[e] + 1;
   double lot = LotForLevel(level);
   if(!CanAdd(d, lot)) return;
   if(MarketOpen(e, d, lot, level))
   {
      eLastAddBar[e] = bt;
      Push(ENAME[e] + " level " + IntegerToString(level) + " add, lot " + DoubleToString(lot, 2));
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

string EngLine(int e)
{
   string s = StringFormat("%-9s: ", ENAME[e]);
   if(!eOn[e]) return s + "OFF";
   if(eCnt[e] > 0)
   {
      s += (eDir[e] == 1 ? "BUY " : eDir[e] == -1 ? "SELL" : "MIX ") + " L" + IntegerToString(eCnt[e]) + "/" + IntegerToString(eMaxLv[e])
         + " lot " + DoubleToString(eLots[e], 2) + "  " + Money(eFloat[e]);
      if(eTPPx[e] > 0) s += "  TP " + DoubleToString(eTPPx[e], _Digits);
      return s;
   }
   if(ePend[e] > 0) return s + "pending " + IntegerToString(ePend[e]) + " (intezaar)";
   return s + (RegimeOk(e) ? "khali - signal ka intezaar" : "khali - regime nahi");
}

void DrawPanel()
{
   if(!InpPanel) return;
   int fs = MathMax(6, InpFontSize);
   int lh = fs * 2 + 2;
   int w  = fs * 50;
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
   string hb = HardBlock();
   if(hb != "")        { L[1] = "Status : " + hb; LC[1] = (IsPaused() || gManualPause || !TradeAllowed()) ? clrTomato : clrGold; }
   else if(gOpen > 0)  { L[1] = "Status : CYCLE CHALU (" + IntegerToString(gOpen) + " trade)"; LC[1] = clrLime; }
   else                { L[1] = "Status : TRADING - intezaar"; LC[1] = clrLime; }

   L[2] = "Regime : " + RegimeName(gRegime) + "   ADX " + DoubleToString(gAdx, 1) + "  CHOP " + DoubleToString(gChop, 1)
        + (InpUseRegime ? "" : "  (filter OFF)");
   LC[2] = (gRegime == RG_TREND ? clrDeepSkyBlue : gRegime == RG_RANGE ? clrViolet : clrSilver);

   for(int e = 0; e < NE; e++)
   {
      L[3 + e] = EngLine(e);
      LC[3 + e] = (!eOn[e] ? clrDimGray : eCnt[e] > 0 ? (eFloat[e] >= 0 ? clrLime : clrTomato) : clrSilver);
   }

   double net = gBank + gFloat;
   L[7] = "Group  : bank " + Money(gBank) + "  float " + Money(gFloat) + "  NET " + Money(net)
        + (InpGroupExit ? " / +" + DoubleToString(GroupTgtMoney(), 2) : " (exit OFF)");
   LC[7] = (net >= 0 ? clrLime : clrTomato);
   L[8] = "Lot    : BUY " + DoubleToString(gBuyLots, 2) + "  SELL " + DoubleToString(gSellLots, 2)
        + "  kul " + DoubleToString(gBuyLots + gSellLots, 2) + "/" + DoubleToString(MaxTotalLots(), 2)
        + "  net " + DoubleToString(MathAbs(gBuyLots - gSellLots), 2) + "/" + DoubleToString(MaxNetLots(), 2);

   double dayPL = gClosedToday + gFloat, tg = DayTargetMoney();
   L[9] = "Aaj P/L: " + Money(dayPL) + " / Target " + (tg > 0 ? "+" + DoubleToString(tg, 2) : "OFF")
        + (gDayBase > 0 ? "  (" + DoubleToString(dayPL / gDayBase * 100.0, 2) + "%)" : "");
   LC[9] = (dayPL >= 0 ? clrLime : clrTomato);
   L[10] = "Group SL -" + DoubleToString(GroupSLMoney(), 2) + "  Din loss "
         + (DayLossMoney() > 0 ? "-" + DoubleToString(DayLossMoney(), 2) : "OFF") + "  Emerg " + DoubleToString(InpEmergencySLPct, 0) + "%";
   LC[10] = clrOrange;
   double a = ATR1();
   L[11] = "Spread " + DoubleToString(Spread(), 2) + "  ATR " + (a == EMPTY_VALUE ? "-" : DoubleToString(a, 2))
         + "  Gap " + DoubleToString(NextGap(1), 2) + "  Lot L1 " + DoubleToString(LotForLevel(1), 2);
   L[12] = "News   : " + (!InpNewsFilter ? "OFF" : IsTester() ? "tester me nahi" :
           gNewsNow != "" ? "ABHI " + gNewsNow : gNewsNext != "" ? "agli " + gNewsNext : "koi high impact nahi");
   LC[12] = (gNewsNow != "" ? clrGold : clrSilver);
   L[13] = "Balance " + DoubleToString(Bal(), 2) + "  Equity " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + " " + cur;
   L[14] = "Magic  : " + IntegerToString(InpMagicBase + 1) + ".." + IntegerToString(InpMagicBase + 4);
   LC[14] = clrDimGray;

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
   trade.SetDeviationInPoints(50);
   trade.SetTypeFillingBySymbol(_Symbol);

   eOn[0] = InpE1On; eOn[1] = InpE2On; eOn[2] = InpE3On; eOn[3] = InpE4On;
   eTP[0] = InpE1TP; eTP[1] = InpE2TP; eTP[2] = InpE3TP; eTP[3] = InpE4TP;
   eMaxLv[0] = InpE1MaxLv; eMaxLv[1] = InpE2MaxLv; eMaxLv[2] = InpE3MaxLv; eMaxLv[3] = InpE4MaxLv;
   for(int e = 0; e < NE; e++)
   {
      eLastAddBar[e] = 0;
      if(eTP[e] <= 0 || eMaxLv[e] < 1) { Print(EA_NAME, ": galat input ", ENAME[e]); return INIT_PARAMETERS_INCORRECT; }
   }
   if(InpGroupSLPct <= 0) { Print(EA_NAME, ": Group SL 0 nahi ho sakta"); return INIT_PARAMETERS_INCORRECT; }

   hEF  = iMA(_Symbol, InpTrendTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   hES  = iMA(_Symbol, InpTrendTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(_Symbol, InpTF, InpRsiPeriod, PRICE_CLOSE);
   hATR = iATR(_Symbol, InpTF, InpAtrPeriod);
   hBB  = iBands(_Symbol, InpTF, InpBBPeriod, 0, InpBBDev, PRICE_CLOSE);
   hADX = iADXWilder(_Symbol, InpRegimeTF, InpAdxPeriod);
   if(hEF == INVALID_HANDLE || hES == INVALID_HANDLE || hRSI == INVALID_HANDLE || hATR == INVALID_HANDLE
      || hBB == INVALID_HANDLE || hADX == INVALID_HANDLE)
   {
      Print(EA_NAME, ": indicator handle nahi bana");
      return INIT_FAILED;
   }

   if(!IsTester())
   {
      if(GlobalVariableCheck(GvPause()))
      {
         datetime d = (datetime)GlobalVariableGet(GvPause());
         if(d == ServerDayStart()) { gPauseDay = d; gPauseReason = "restart se pehle band hua tha"; }
      }
      if(GlobalVariableCheck(GvCycle())) gCycleStart = (datetime)GlobalVariableGet(GvCycle());
   }

   gLastBar = iTime(_Symbol, InpTF, 0);
   for(int e = 0; e < NE; e++) eLastAddBar[e] = gLastBar;
   Scan();
   for(int e = 0; e < NE; e++) ePrevCnt[e] = eCnt[e];
   UpdateRegime();
   Stats(true);
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
   int hs[6]; hs[0] = hEF; hs[1] = hES; hs[2] = hRSI; hs[3] = hATR; hs[4] = hBB; hs[5] = hADX;
   for(int i = 0; i < 6; i++) if(hs[i] != INVALID_HANDLE) IndicatorRelease(hs[i]);
   Comment("");
}

void OnTick()
{
   bool newBar = false;
   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt != 0 && bt != gLastBar) { gLastBar = bt; newBar = true; }

   Scan();
   Stats(false);
   if(!TradeAllowed()) return;

   // --- 1. din ka target / loss
   double dayPL = gClosedToday + gFloat;
   double tg = DayTargetMoney(), dl = DayLossMoney();
   if(tg > 0 && gDayBase > 0 && dayPL >= tg)
   {
      if(gOpen > 0 || gPendAll > 0) CloseEverything("Din ka target " + Money(dayPL));
      SetPause("DIN KA TARGET " + Money(dayPL));
      return;
   }
   if(dl > 0 && gDayBase > 0 && dayPL <= -dl)
   {
      if(gOpen > 0 || gPendAll > 0) CloseEverything("Din ka loss limit " + Money(dayPL));
      SetPause("DIN KA LOSS LIMIT " + Money(dayPL));
      return;
   }

   // --- 2. group exit / group SL / weekend
   if(gOpen > 0)
   {
      double net = gBank + gFloat;
      if(InpGroupExit && net > 0 && net >= GroupTgtMoney())
      {
         CloseEverything("GROUP TARGET " + Money(net));
         return;
      }
      if(gFloat <= -GroupSLMoney())
      {
         CloseEverything("GROUP SL " + Money(gFloat));
         if(InpPauseAfterSL) SetPause("Group SL " + Money(gFloat));
         return;
      }
      if(WeekendCloseNow()) { CloseEverything("Weekend se pehle band"); return; }
   }

   // --- 3. sakht rok par pending cancel
   string hb = HardBlock();
   if(hb != "" && gPendAll > 0) { CancelPend(-1); Scan(); }

   // --- 4. har engine: OCO, TP/SL, grid add
   for(int e = 0; e < NE; e++)
   {
      if(ePrevCnt[e] == 0 && eCnt[e] > 0) eLastAddBar[e] = bt;   // pending abhi bhara: is candle me add nahi
      if(eCnt[e] <= 0) continue;
      if(ePend[e] > 0) { CancelPend(e); Scan(); }        // OCO: basket khul gayi, doosra pending hatao
      ManageEngine(e);
   }
   Scan();
   for(int e = 0; e < NE; e++)
      if(eCnt[e] > 0) { TryAdd(e); }
   Scan();
   for(int e = 0; e < NE; e++) if(eCnt[e] > 0) ManageEngine(e);

   // --- 5. nayi candle: regime, purane pending hatao, nayi entry
   if(newBar)
   {
      UpdateRegime();
      CleanPendings();
      Scan();
      if(hb == "") { TryEntries(); Scan(); for(int e = 0; e < NE; e++) if(eCnt[e] > 0) ManageEngine(e); }
   }
   Scan();
   for(int e = 0; e < NE; e++) ePrevCnt[e] = eCnt[e];
}

void OnTimer()
{
   if(!IsTester()) { UpdateNews(); Scan(); Stats(false); }
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
      CloseEverything("CLOSE ALL button");
   }
   else if(sparam == PFX + "btnPause")
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      gManualPause = !gManualPause;
      if(gManualPause) CancelPend(-1);
      Push(gManualPause ? "PAUSE: nayi entry band, pending hataye (khuli basket chalti rahegi)" : "RESUME: nayi entry chalu");
   }
   Scan();
   DrawPanel();
}
//+------------------------------------------------------------------+
