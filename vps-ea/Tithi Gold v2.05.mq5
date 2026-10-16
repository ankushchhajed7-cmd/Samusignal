//+------------------------------------------------------------------+
//|                                        Tithi Gold v2.05.mq5      |
//|                     Ankush New Vision - Gold Straddle Grid       |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v2.05 (16-Oct-2026) - REAL EA ki live setting jaisa:              |
//|  - DEFAULT lot 0.01 / 0.05 / 0.20 (30 level = 10 / 10 / 10)       |
//|  - DEFAULT cycle target 50, both sides always = false            |
//|  - FIX: side ab poore cycle ke liye lock nahi. Trend khatam ho to |
//|    chalu cycle me doosri side ke stop wapas lagte hain; trend     |
//|    ulta ho jaaye to side bhi palat jaati hai                      |
//| v2.04 (16-Oct-2026) - DEFAULT: din ka HARD loss cap 300 -> 3000   |
//|  Baaki saari settings v2.03 jaisi (Ankush ke screenshot jaisi).   |
//|  Trading niyam same                                               |
//| v2.03 (14-Oct-2026) - Pending lagane ka kram original jaisa:      |
//|  B1, S1, B2, S2 ... (beech se bahar). Pehle saare buy phir saare |
//|  sell nahi. Trading niyam same                                    |
//| v2.02 (14-Oct-2026) - "Both sides always = true" ab CHALU cycle   |
//|  par bhi turant lagta hai (pehle sirf naye cycle se). Trend wala |
//|  ek-side cycle chal raha ho to doosri side ke stop bhi lag jaate |
//|  hain. Algo Trading OFF ho to panel par "ALGO TRADING OFF" dikhe  |
//|  - DEFAULT ab us original account jaise jo hum dekh rahe hain:    |
//|    dono side hamesha, 30 level, lot 0.01 / 0.03 / 0.09 (10/10/10),|
//|    cycle target 3, din ka profit cap 250, loss cap 300            |
//| v2.01 (14-Oct-2026) - FIX: deposit / withdrawal ko din ka profit  |
//|  samajh liya tha (balance badhaya -> "DAY PROFIT CAP +280").      |
//|  Ab din ka P/L = equity - din ki shuruaat equity - (deposit /     |
//|  withdrawal / credit jo uske baad hue). Restart par agar profit  |
//|  cap galat laga tha (sahi hisaab cap se kam) to apne aap hat-ta  |
//| v2.00 (14-Oct-2026) - POORA NAYA EA (original EA ki input photo   |
//|                       ke hisaab se, sab default photo jaise)      |
//|  1. Account : Magic 26011001, log level 0                         |
//|  2. Grid    : har side 20 level, gap = 1.0 x (price / 3000)       |
//|               (4160 par 1.39), asli buy/sell stop chart par.      |
//|               Lot tier: near 0.01 / mid 0.05 / far 0.20           |
//|               (levels 3 hisso me: 20 = 7 / 7 / 6)                 |
//|               Band hua level price wapas aaye to dobara lagta hai |
//|  2b Lot mode: FIXED (ya AUTO: balance / 5000 x 0.01/0.05/0.15)    |
//|  3. Target  : CYCLE NET = is cycle ka BANK (band trades) +        |
//|               khuli trades ka P/L. Target 50 (AUTO: 0.1% balance) |
//|               pahunchte hi sab band, naya cycle                   |
//|  3b Din     : profit cap 250, HARD loss cap 3000 (ya % me 2/20)   |
//|               loss ke baad 1 din band, phir 1 din lot+target x2   |
//|  4. Trend   : 6 candle me 30 ka move = trend -> sirf us taraf     |
//|               ka grid. Floating -800 + trend = trend side lot x2  |
//|  5. Trailing: sirf PROFIT wali trade - 2 gap profit par trailing  |
//|               chalu, 1 gap peeche SL. Equity < balance ho to      |
//|               trailing nahi (photo default). Losers cycle target  |
//|               tak pakde rehte hain                                |
//|  7. Chart   : neon panel                                         |
//|  Tithi extras (photo me nahi, default OFF): news, weekend,       |
//|  spread, dabba filter. Smart close, restart safety, mobile alert |
//|  ON (ye trading ka niyam nahi badalte)                           |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "2.05"
#property description "Tithi Gold v2.05 - gold straddle grid: per-leg trailing bank, cycle net target, day caps, trend one-side. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME  "Tithi Gold"
#define EA_VER   "v2.05"
#define PFX      "TITHI205_"
#define GVP      "TG2_"
#define CMT_TAG  "TG2"

#define BOX_TF     PERIOD_M5
#define BOX_BARS   24
#define BOX_MAX    8.0

//--- neon colours
#define CLR_BG     C'6,10,20'
#define CLR_BOX    C'11,17,31'
#define CLR_CELL   C'15,23,41'
#define NEON_CY    C'0,229,255'
#define NEON_MG    C'255,61,240'
#define NEON_PU    C'150,110,255'
#define NEON_GR    C'57,255,136'
#define NEON_RD    C'255,77,109'
#define NEON_OR    C'255,170,0'
#define GOLD_C     C'255,196,46'
#define TXT_W      C'232,238,255'
#define TXT_DIM    C'125,140,175'

enum ENUM_LOT_MODE
{
   LOT_MODE_FIXED = 0,   // FIXED: near / mid / far lot jaisa likha
   LOT_MODE_AUTO  = 1    // AUTO: balance ke hisaab se badhe
};

//=== INPUTS (original photo jaise) =================================
input group "1. Account"
input long   InpMagic               = 26011001; // Magic number
input int    InpLogLevel            = 0;        // 0 = errors + cycle banks only, 1 = state events bhi

input group "2. Grid and Lots"
input int    InpLevels              = 30;       // Levels per side
input double InpGridStepUSD         = 1.0;      // Reference spacing (gold PRICE) at InpPriceScaleReference
input bool   InpScaleByPrice        = true;     // Scale spacing by current price
input double InpPriceScaleReference = 3000.0;   // Price where InpGridStepUSD applies
input bool   InpKeepStopsOnChart    = true;     // Keep buy/sell stops on chart (false = virtual levels)
input double InpNearLot             = 0.01;     // Near-tier lots
input double InpMidLot              = 0.05;     // Mid-tier lots
input double InpFarLot              = 0.20;     // Far-tier lots

input group "2b. Lot Mode"
input ENUM_LOT_MODE InpLotMode      = LOT_MODE_FIXED; // Exactly one mode: fixed tier lots or auto
input double InpAutoRefBalance      = 5000.0;   // Reference balance for auto lots
input double InpAutoNearLot         = 0.01;     // At base balance: near-tier lots
input double InpAutoMidLot          = 0.05;     // At base balance: mid-tier lots
input double InpAutoFarLot          = 0.15;     // At base balance: far-tier lots

input group "3. Profit Targets"
input double InpCycleTarget         = 50.0;     // Fixed-mode cycle net bank target (account currency)
input double InpWholeBookGreen      = 0.0;      // Whole-book green bank (khuli trades ka P/L itna = sab band, 0 = off)

input group "3b. Daily Limits"
input bool   InpHardDailyStop       = true;     // Hard daily stop (false = loss cap band)
input bool   InpIndependentFloatStop= false;    // Independent EA floating-P/L stop (false = account equity se)
input bool   InpLimitsInPercent     = false;    // true = % of day-start equity, false = USD
input double InpDayProfitCapUSD     = 250.0;    // Day equity profit cap (account currency)
input double InpDayLossCapUSD       = 3000.0;   // HARD day equity loss cap (account currency)
input double InpAutoCycleTargetPct  = 0.1;      // Auto-mode cycle target as % of balance
input double InpDayProfitCapPct     = 2.0;      // Daily profit cap as % of day-start equity
input double InpDayLossCapPct       = 20.0;     // HARD daily loss cap as % of day-start equity
input bool   InpAfterLossDouble     = true;     // After loss: next trading day lots + cycle target x2
input int    InpPauseDaysAfterLoss  = 1;        // Do not trade for this many days after day loss cap

input group "4. Trend (detection + optional one-side)"
input bool   InpBothSidesAlways     = false;    // Both sides always (false = trend me sirf ek side)
input bool   InpAllowNewCycleFlat   = false;    // Allow new cycle when flat (target se pehle)
input int    InpTrendBars           = 6;        // Bars for trend move (chart timeframe)
input double InpTrendMoveUSD        = 30.0;     // Gold PRICE move to call it a trend
input bool   InpDeepDD2x            = true;     // 2x with-trend grid lots when deep DD + trend
input double InpDeepDDUSD           = 800.0;    // Deep DD: EA floating itna minus (account currency)

input group "5. Trailing (per-leg only; whole basket waits for cycle target)"
input bool   InpTrailProfitLegs     = true;     // Trail each IN-PROFIT leg only
input int    InpTrailArmGrids       = 2;        // Profit grids (price) to ARM trail
input int    InpTrailDistGrids      = 1;        // Trail distance after arm (grids)
input bool   InpTrailEvenIfRed      = false;    // Trail even if equity < balance
input double InpGreenGate           = 0.0;      // Equity-green gate (equity - balance >= iska)

input group "6. Engines"
input bool   InpHoldLosers          = true;     // Hold losers until cycle net target

input group "7. Chart"
input bool   InpChartUI             = true;     // Chart UI (panel)
input double InpPanelScale          = 1.40;     // Panel size (phone ke liye 1.3 - 1.6)
input int    InpPanelX              = 10;       // Panel X
input int    InpPanelY              = 25;       // Panel Y

input group "8. Tithi extras (photo me nahi - default OFF)"
input bool   InpNewsFilter          = false;    // News filter: news ke time naya cycle nahi
input int    InpNewsBefore          = 30;       // News se kitne minute pehle
input int    InpNewsAfter           = 30;       // News ke kitne minute baad
input string InpNewsCurrencies      = "USD";    // News currencies
input bool   InpWeekendStop         = false;    // Weekend stop: Shukra 14:00 - Somvar 08:00 IST naya cycle nahi
input double InpMaxSpread           = 0;        // Max spread (gold PRICE) naya cycle ke liye (0 = off)
input bool   InpBoxFilter           = false;    // Dabba filter: 2 ghante ka range 8.00 ya kam = naya cycle nahi
input bool   InpPush                = true;     // Mobile alert (MT5 push)
input bool   InpUseCloseBy          = true;     // Band karte waqt buy-sell jodi CLOSE BY se
input int    InpSlippage            = 1000;     // Slippage (points)

//=== GLOBALS =======================================================
CTrade   trade;
double   gK = 1.0, gScale = 1.0;

bool     gTradingOn = true;
// cycle
int      gCycleNo     = 0;
datetime gCycleStart  = 0;
double   gCenter      = 0;
double   gStep        = 0;
int      gSides       = 0;        // 0 = dono, 1 = sirf buy, -1 = sirf sell
bool     gCycleHadPos = false;
double   gCycleBank   = 0;        // is cycle ka band hua P/L (history se)
double   gLastCycle   = 0;
// close
bool     gClosing = false;
string   gCloseWhy = "";
datetime gCloseStart = 0;
uint     gLastCloseSend = 0;
int      gClosePass = 0;
double   gCloseEst = 0;
// day
datetime gDayStart    = 0;
double   gDayStartEq  = 0;
datetime gDseTime     = 0;        // day-start equity kab note hui (deposit iske baad wale hi ghatenge)
bool     gDayDone     = false;    // aaj ka profit / loss cap lag chuka
string   gDayDoneWhy  = "";
datetime gPauseUntil  = 0;        // loss ke baad kab tak band
bool     gDoublePending = false;  // agle trading din x2
double   gMultToday   = 1.0;
double   gDayPL       = 0;
// live
int      gBuys = 0, gSells = 0, gPendB = 0, gPendS = 0, gTrailing = 0;
double   gLotB = 0, gLotS = 0, gFloat = 0;
int      gTrendDir = 0;
double   gTrendMove = 0;
bool     gDeepDD = false;
double   gPrevBid = 0, gPrevAsk = 0;
string   gMsg = "";
// news
datetime gNewsT[];
string   gNewsN[];
datetime gNewsLoaded = 0;
string   gNewsNow = "", gNewsNext = "";
bool     gBankDirty = true;
// commission cache
ulong    gComTk[];
double   gComVal[];

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
bool IsTester() { return (MQLInfoInteger(MQL_TESTER) != 0); }
double TickSize() { double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE); return (ts > 0 ? ts : _Point); }
double NormP(double p) { double ts = TickSize(); return NormalizeDouble(MathRound(p / ts) * ts, _Digits); }

double NormLot(double l)
{
   double mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(st <= 0) st = 0.01;
   int dg = (int)MathMax(0.0, MathCeil(-MathLog10(st) - 1e-9));
   l = MathFloor(l / st + 1e-9) * st;
   if(l < mn) l = mn;
   if(mx > 0 && l > mx) l = mx;
   return NormalizeDouble(l, dg);
}

double StopsDist()
{
   double lv = MathMax((double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL),
                       (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL));
   return lv * _Point + TickSize() * 2;
}

ENUM_ORDER_TYPE_TIME OrderTimeType()
{
   int m = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   if((m & SYMBOL_EXPIRATION_GTC) != 0) return ORDER_TIME_GTC;
   if((m & SYMBOL_EXPIRATION_DAY) != 0) return ORDER_TIME_DAY;
   return ORDER_TIME_GTC;
}

bool MyPos() { return (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic); }
bool MyOrd() { return (OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic); }
double SpreadNow() { return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID); }

string AccCur() { return AccountInfoString(ACCOUNT_CURRENCY); }
string CurLabel() { string c = AccCur(); if(c == "USD" || c == "") return "$"; return c + " "; }
bool IsCentAccount() { string c = AccCur(); StringToUpper(c); return (c == "USC" || c == "EUC" || StringFind(c, "CENT") >= 0); }
string CurFix(string m) { string c = CurLabel(); if(c != "$") StringReplace(m, "$", c); return m; }
string Money(double v) { return (v >= 0 ? "+" : "") + DoubleToString(v, 2); }

// level 0 = hamesha (errors, cycle bank), level 1 = state events
void Log(int lvl, string m)
{
   m = CurFix(m);
   if(lvl == 0) gMsg = m;
   if(lvl <= InpLogLevel) Print(EA_NAME, " | ", m);
}

void Notify(string m)
{
   if(!InpPush || IsTester()) return;
   if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) return;
   string txt = EA_NAME + " " + _Symbol + ": " + CurFix(m);
   if(StringLen(txt) > 255) txt = StringSubstr(txt, 0, 255);
   SendNotification(txt);
}

//--- global variables (restart par yaad rahe)
string GVName(string k) { return GVP + IntegerToString(InpMagic) + "_" + _Symbol + "_" + k; }
void   GVSet(string k, double v) { GlobalVariableSet(GVName(k), v); }
double GVGet(string k, double def) { string n = GVName(k); if(!GlobalVariableCheck(n)) return def; return GlobalVariableGet(n); }

int WhyCode(string w)
{
   if(StringFind(w, "CYCLE") == 0)      return 1;
   if(StringFind(w, "GREEN") == 0)      return 2;
   if(StringFind(w, "DAY PROFIT") == 0) return 3;
   if(StringFind(w, "DAY LOSS") == 0)   return 4;
   if(StringFind(w, "MANUAL") == 0)     return 5;
   if(StringFind(w, "FLAT") == 0)       return 6;
   return 9;
}
string WhyText(int c)
{
   switch(c)
   {
      case 1: return "CYCLE BANK";
      case 2: return "GREEN BANK";
      case 3: return "DAY PROFIT CAP";
      case 4: return "DAY LOSS CAP";
      case 5: return "MANUAL CLOSE ALL";
      case 6: return "FLAT NEW CYCLE";
   }
   return "CLOSE";
}

void SaveState()
{
   GVSet("on",       gTradingOn ? 1 : 0);
   GVSet("cyc",      gCycleNo);
   GVSet("cst",      (double)gCycleStart);
   GVSet("ctr",      gCenter);
   GVSet("stp",      gStep);
   GVSet("sid",      gSides);
   GVSet("hadpos",   gCycleHadPos ? 1 : 0);
   GVSet("closing",  gClosing ? 1 : 0);
   GVSet("closewhy", WhyCode(gCloseWhy));
   GVSet("closest",  (double)gCloseStart);
   GVSet("closeest", gCloseEst);
   GVSet("day",      (double)gDayStart);
   GVSet("dse",      gDayStartEq);
   GVSet("dset",     (double)gDseTime);
   GVSet("daywhy",   gDayDoneWhy == "PROFIT CAP" ? 1 : (gDayDoneWhy == "LOSS CAP" ? 2 : 0));
   GVSet("daydone",  gDayDone ? 1 : 0);
   GVSet("pause",    (double)gPauseUntil);
   GVSet("dblpend",  gDoublePending ? 1 : 0);
   GVSet("mult",     gMultToday);
   GVSet("lastcyc",  gLastCycle);
}

void LoadState()
{
   gTradingOn    = (GVGet("on", 1) > 0.5);
   gCycleNo      = (int)GVGet("cyc", 0);
   gCycleStart   = (datetime)(long)GVGet("cst", 0);
   gCenter       = GVGet("ctr", 0);
   gStep         = GVGet("stp", 0);
   gSides        = (int)GVGet("sid", 0);
   gCycleHadPos  = (GVGet("hadpos", 0) > 0.5);
   gClosing      = (GVGet("closing", 0) > 0.5);
   if(gClosing)
   {
      gCloseWhy   = WhyText((int)GVGet("closewhy", 9)) + " (restart ke baad)";
      gCloseStart = (datetime)(long)GVGet("closest", 0);
      gCloseEst   = GVGet("closeest", 0);
      if(gCloseStart == 0) gCloseStart = TimeCurrent();
   }
   gDayStart      = (datetime)(long)GVGet("day", 0);
   gDayStartEq    = GVGet("dse", 0);
   gDayDone       = (GVGet("daydone", 0) > 0.5);
   gDseTime       = (datetime)(long)GVGet("dset", 0);
   int dw         = (int)GVGet("daywhy", 0);
   gDayDoneWhy    = (dw == 1 ? "PROFIT CAP" : dw == 2 ? "LOSS CAP" : "");
   gPauseUntil    = (datetime)(long)GVGet("pause", 0);
   gDoublePending = (GVGet("dblpend", 0) > 0.5);
   gMultToday     = GVGet("mult", 1.0);
   gLastCycle     = GVGet("lastcyc", 0);
}

//+------------------------------------------------------------------+
//| TIME / NEWS / WEEKEND                                            |
//+------------------------------------------------------------------+
long ServerOffset()
{
   long off = (long)TimeTradeServer() - (long)TimeGMT();
   return (long)MathRound(off / 900.0) * 900;
}
datetime ServerToIst(datetime t) { return (datetime)((long)t - ServerOffset() + 19800); }
datetime ServerDayStart() { long t = (long)TimeTradeServer(); return (datetime)(t - (t % 86400)); }

bool IsWeekendIst()
{
   if(!InpWeekendStop) return false;
   MqlDateTime d;
   TimeToStruct(ServerToIst(TimeTradeServer()), d);
   int now = d.day_of_week * 1440 + d.hour * 60 + d.min;
   int stop = 5 * 1440 + 14 * 60, start = 1 * 1440 + 8 * 60;   // Shukra 14:00 -> Somvar 08:00
   return (now >= stop || now < start);
}

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
         gNewsNow = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES);
      if(t > now && (best == 0 || gNewsT[i] < best))
      { best = gNewsT[i]; gNewsNext = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES); }
   }
}

double BoxRange()
{
   double h[], l[];
   if(CopyHigh(_Symbol, BOX_TF, 0, BOX_BARS, h) < BOX_BARS) return -1;
   if(CopyLow (_Symbol, BOX_TF, 0, BOX_BARS, l) < BOX_BARS) return -1;
   return h[ArrayMaximum(h)] - l[ArrayMinimum(l)];
}

//+------------------------------------------------------------------+
//| COMMISSION / HISTORY                                             |
//+------------------------------------------------------------------+
double EntryCommission(ulong posTicket)
{
   int n = ArraySize(gComTk);
   for(int i = 0; i < n; i++) if(gComTk[i] == posTicket) return gComVal[i];
   double c = 0; bool found = false;
   if(HistorySelectByPosition(posTicket))
      for(int j = 0; j < HistoryDealsTotal(); j++)
      {
         ulong dt = HistoryDealGetTicket(j);
         if(dt == 0) continue;
         if(HistoryDealGetInteger(dt, DEAL_ENTRY) == DEAL_ENTRY_IN)
         { c += HistoryDealGetDouble(dt, DEAL_COMMISSION) + HistoryDealGetDouble(dt, DEAL_FEE); found = true; }
      }
   if(!found) return 0;
   ArrayResize(gComTk, n + 1); ArrayResize(gComVal, n + 1);
   gComTk[n] = posTicket; gComVal[n] = c;
   return c;
}

// is EA ke saare deals (in + out) ka P/L, 'from' ke baad
double DealsSince(datetime from)
{
   double r = 0;
   if(from <= 0) return 0;
   if(!HistorySelect(from - 5, TimeCurrent() + 3600)) return 0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from) continue;
      r += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
         + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
   }
   return r;
}

//+------------------------------------------------------------------+
//| STATE                                                            |
//+------------------------------------------------------------------+
void UpdateState()
{
   gBuys = gSells = gPendB = gPendS = gTrailing = 0;
   gLotB = gLotS = gFloat = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { gBuys++; gLotB += v; } else { gSells++; gLotS += v; }
      if(PositionGetDouble(POSITION_SL) > 0) gTrailing++;
      gFloat += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + EntryCommission(t); // exit commission andaza
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY_STOP) gPendB++;
      if(ot == ORDER_TYPE_SELL_STOP) gPendS++;
   }
   if(gBuys + gSells > 0) gCycleHadPos = true;
}

void UpdateTrend()
{
   gTrendDir = 0; gTrendMove = 0;
   int n = MathMax(1, InpTrendBars);
   double c0 = iClose(_Symbol, PERIOD_CURRENT, 0);
   double cN = iClose(_Symbol, PERIOD_CURRENT, n);
   if(c0 <= 0 || cN <= 0) return;
   gTrendMove = c0 - cN;
   if(gTrendMove >=  InpTrendMoveUSD) gTrendDir =  1;
   if(gTrendMove <= -InpTrendMoveUSD) gTrendDir = -1;
}

double CycleTarget()
{
   double t = (InpLotMode == LOT_MODE_AUTO) ? AccountInfoDouble(ACCOUNT_BALANCE) * InpAutoCycleTargetPct / 100.0 : InpCycleTarget;
   return t * gMultToday;
}

//+------------------------------------------------------------------+
//| DAY: start equity, caps, pause, x2                               |
//+------------------------------------------------------------------+
void UpdateDay()
{
   datetime ds = ServerDayStart();
   if(ds == gDayStart) return;
   bool firstEver = (gDayStart == 0);
   gDayStart   = ds;
   gDayStartEq = AccountInfoDouble(ACCOUNT_EQUITY);
   gDseTime    = TimeCurrent();
   gDayDone    = false; gDayDoneWhy = "";
   gMultToday  = 1.0;
   if(TimeTradeServer() >= gPauseUntil && gDoublePending && InpAfterLossDouble)
   {
      gMultToday = 2.0;
      gDoublePending = false;
      Log(0, "Naya din: pichhle loss ke baad aaj LOT + CYCLE TARGET x2");
      Notify("Aaj lot + cycle target x2 (pichhle loss ke baad)");
   }
   else if(!firstEver) Log(1, "Naya din - day caps reset");
   SaveState();
}

double DayProfitCap() { return InpLimitsInPercent ? gDayStartEq * InpDayProfitCapPct / 100.0 : InpDayProfitCapUSD; }
double DayLossCap()   { return InpLimitsInPercent ? gDayStartEq * InpDayLossCapPct   / 100.0 : InpDayLossCapUSD; }

// day-start equity note hone ke baad ke deposit / withdrawal / credit (trading P/L nahi)
double BalanceOpsSince(datetime from)
{
   double r = 0;
   if(from <= 0) return 0;
   if(!HistorySelect(from, TimeCurrent() + 3600)) return 0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from) continue;
      long dt = HistoryDealGetInteger(d, DEAL_TYPE);
      if(dt == DEAL_TYPE_BALANCE || dt == DEAL_TYPE_CREDIT || dt == DEAL_TYPE_BONUS ||
         dt == DEAL_TYPE_CHARGE  || dt == DEAL_TYPE_CORRECTION)
         r += HistoryDealGetDouble(d, DEAL_PROFIT);
   }
   return r;
}

double CalcDayPL()
{
   if(InpIndependentFloatStop) return DealsSince(gDayStart) + gFloat;
   return AccountInfoDouble(ACCOUNT_EQUITY) - gDayStartEq - BalanceOpsSince(gDseTime);
}

//+------------------------------------------------------------------+
//| GRID                                                             |
//+------------------------------------------------------------------+
int NearCount() { return (int)MathCeil(InpLevels / 3.0); }
int MidCount()  { return (int)MathCeil((InpLevels - NearCount()) / 2.0); }

double TierBaseLot(int lvl)
{
   int tier = (lvl <= NearCount()) ? 0 : (lvl <= NearCount() + MidCount() ? 1 : 2);
   if(InpLotMode == LOT_MODE_AUTO)
   {
      double k = (InpAutoRefBalance > 0) ? AccountInfoDouble(ACCOUNT_BALANCE) / InpAutoRefBalance : 1.0;
      return (tier == 0 ? InpAutoNearLot : tier == 1 ? InpAutoMidLot : InpAutoFarLot) * k;
   }
   return (tier == 0 ? InpNearLot : tier == 1 ? InpMidLot : InpFarLot);
}

bool TrendSide(bool isBuy) { return (gTrendDir == 1 && isBuy) || (gTrendDir == -1 && !isBuy); }
bool UseX2(bool isBuy) { return (InpDeepDD2x && gDeepDD && TrendSide(isBuy)); }

double LevelLot(int lvl, bool isBuy)
{
   double l = TierBaseLot(lvl) * gMultToday;
   if(UseX2(isBuy)) l *= 2.0;
   return NormLot(l);
}

double LevelPrice(bool isBuy, int lvl) { return NormP(isBuy ? gCenter + gStep * lvl : gCenter - gStep * lvl); }
bool SideAllowed(bool isBuy) { return (InpBothSidesAlways || gSides == 0 || (gSides == 1 && isBuy) || (gSides == -1 && !isBuy)); }

// is level par khuli trade?
bool LevelHasPos(bool isBuy, double lp)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      bool b = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      if(b != isBuy) continue;
      if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - lp) < gStep * 0.5) return true;
   }
   return false;
}

// is level par pending? ticket aur comment wapas
ulong LevelPend(bool isBuy, double lp, string &cmt)
{
   cmt = "";
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(isBuy && ot != ORDER_TYPE_BUY_STOP) continue;
      if(!isBuy && ot != ORDER_TYPE_SELL_STOP) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - lp) < gStep * 0.25) { cmt = OrderGetString(ORDER_COMMENT); return t; }
   }
   return 0;
}

string LevelCmt(bool isBuy, int lvl, bool x2)
{
   return CMT_TAG + (isBuy ? " B" : " S") + StringFormat("%02d", lvl) + (x2 ? " X2" : "");
}

bool SendStop(bool isBuy, double lot, double price, string cmt)
{
   ENUM_ORDER_TYPE_TIME tt = OrderTimeType();
   bool ok = isBuy ? trade.BuyStop(lot, price, _Symbol, 0, 0, tt, 0, cmt)
                   : trade.SellStop(lot, price, _Symbol, 0, 0, tt, 0, cmt);
   uint rc = trade.ResultRetcode();
   if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED)) return true;
   Log(0, "pending fail " + cmt + " rc=" + IntegerToString(rc) + " " + trade.ResultRetcodeDescription());
   return false;
}

// khali level (asli stop mode) par pending lagao / X2 badlo
void ArmLevels()
{
   if(!InpKeepStopsOnChart || gCenter <= 0 || gStep <= 0) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return;   // Algo Trading OFF
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sd = StopsDist();
   // beech se bahar: B1, S1, B2, S2 ... (original jaisa kram)
   for(int lvl = 1; lvl <= InpLevels; lvl++)
   {
      for(int s = 0; s < 2; s++)
      {
         bool isBuy = (s == 0);
         if(!SideAllowed(isBuy)) continue;
         double lp = LevelPrice(isBuy, lvl);
         string cmt;
         ulong pt = LevelPend(isBuy, lp, cmt);
         bool x2 = UseX2(isBuy);
         if(pt > 0)
         {
            // deep DD + trend: is side ke pending x2 lot se badlo
            bool hasX2 = (StringFind(cmt, "X2") >= 0);
            if(x2 && !hasX2) trade.OrderDelete(pt);
            continue;
         }
         if(LevelHasPos(isBuy, lp)) continue;
         // price sahi taraf ho tabhi stop lag sakta hai
         if(isBuy  && lp <= ask + sd) continue;
         if(!isBuy && lp >= bid - sd) continue;
         SendStop(isBuy, LevelLot(lvl, isBuy), lp, LevelCmt(isBuy, lvl, x2));
      }
   }
}

// virtual mode: price level paar kare to market order
void VirtualTriggers()
{
   if(InpKeepStopsOnChart || gCenter <= 0 || gStep <= 0) return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(gPrevAsk <= 0) { gPrevAsk = ask; gPrevBid = bid; return; }
   for(int lvl = 1; lvl <= InpLevels; lvl++)
   {
      if(SideAllowed(true))
      {
         double lp = LevelPrice(true, lvl);
         if(gPrevAsk < lp && ask >= lp && !LevelHasPos(true, lp))
            trade.Buy(LevelLot(lvl, true), _Symbol, 0, 0, 0, LevelCmt(true, lvl, UseX2(true)));
      }
      if(SideAllowed(false))
      {
         double lp = LevelPrice(false, lvl);
         if(gPrevBid > lp && bid <= lp && !LevelHasPos(false, lp))
            trade.Sell(LevelLot(lvl, false), _Symbol, 0, 0, 0, LevelCmt(false, lvl, UseX2(false)));
      }
   }
   gPrevAsk = ask; gPrevBid = bid;
}

void NewCycle()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) return;
   double mid = (bid + ask) / 2.0;
   gStep = InpGridStepUSD;
   if(InpScaleByPrice && InpPriceScaleReference > 0) gStep = InpGridStepUSD * mid / InpPriceScaleReference;
   gStep = NormP(gStep);
   if(gStep <= 0) { Log(0, "Gap 0 hai - input check karo"); return; }
   gCenter = NormP(mid);
   UpdateTrend();
   gSides = (InpBothSidesAlways || gTrendDir == 0) ? 0 : gTrendDir;
   gCycleNo++;
   gCycleStart = TimeCurrent();
   gCycleHadPos = false;
   gCycleBank = 0;
   gPrevAsk = ask; gPrevBid = bid;
   ArrayResize(gComTk, 0); ArrayResize(gComVal, 0);
   SaveState();
   ArmLevels();
   Log(1, StringFormat("CYCLE #%d @ %s | gap %.2f | %s | target $%.2f", gCycleNo, DoubleToString(gCenter, _Digits), gStep,
       gSides == 0 ? "dono side" : (gSides == 1 ? "sirf BUY (trend)" : "sirf SELL (trend)"), CycleTarget()));
}

//+------------------------------------------------------------------+
//| PER-LEG TRAILING                                                 |
//+------------------------------------------------------------------+
void TrailLegs()
{
   if(!InpTrailProfitLegs || gStep <= 0) return;
   bool gate = InpTrailEvenIfRed ||
               (AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE) >= InpGreenGate);
   if(!gate) return;   // equity laal - trailing nahi (lage hue SL waise hi rahenge)
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sd = StopsDist(), ts = TickSize();
   double arm = gStep * MathMax(1, InpTrailArmGrids), dist = gStep * MathMax(1, InpTrailDistGrids);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double op = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL), tp = PositionGetDouble(POSITION_TP);
      if(isBuy)
      {
         if(bid - op < arm) continue;
         double nsl = NormP(bid - dist);
         if(nsl > bid - sd) continue;
         if(sl > 0 && nsl <= sl + ts) continue;
         if(trade.PositionModify(t, nsl, tp)) Log(1, StringFormat("Trail BUY %.2f -> SL %s", op, DoubleToString(nsl, _Digits)));
      }
      else
      {
         if(op - ask < arm) continue;
         double nsl = NormP(ask + dist);
         if(nsl < ask + sd) continue;
         if(sl > 0 && nsl >= sl - ts) continue;
         if(trade.PositionModify(t, nsl, tp)) Log(1, StringFormat("Trail SELL %.2f -> SL %s", op, DoubleToString(nsl, _Digits)));
      }
   }
}

// "hold losers" OFF ho to: bank se sabse bada loser kaato
void CutLoserFromBank()
{
   if(InpHoldLosers || gCycleBank <= 0) return;
   ulong worst = 0; double wpl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(pl < wpl) { wpl = pl; worst = t; }
   }
   if(worst > 0 && gCycleBank + wpl >= 0)
   {
      trade.PositionClose(worst, (ulong)InpSlippage);
      gBankDirty = true;
      Log(1, StringFormat("Loser bank se kaata: %.2f (bank %.2f)", wpl, gCycleBank));
   }
}

//+------------------------------------------------------------------+
//| CLOSE (smart: extra lot pehle, phir Close By)                    |
//+------------------------------------------------------------------+
bool CloseByAllowed()
{
   if(!InpUseCloseBy) return false;
   return ((SymbolInfoInteger(_Symbol, SYMBOL_ORDER_MODE) & SYMBOL_ORDER_CLOSEBY) != 0);
}

void SendCloseAll()
{
   if(gLastCloseSend != 0 && GetTickCount() - gLastCloseSend < 1000) return;
   gLastCloseSend = GetTickCount();
   gClosePass++;
   UpdateState();
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   double half = step * 0.5;
   bool bigBuy = (gLotB > gLotS);
   double need = MathAbs(gLotB - gLotS);

   trade.SetAsyncMode(true);
   for(int i = OrdersTotal() - 1; i >= 0; i--)   // pehle pending hatao (naye fill na hon)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      trade.OrderDelete(t);
   }
   if(need >= half)
   {
      for(int i = PositionsTotal() - 1; i >= 0 && need >= half; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !MyPos()) continue;
         bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
         if(isBuy != bigBuy) continue;
         double v = PositionGetDouble(POSITION_VOLUME);
         if(v <= need + half) { trade.PositionClose(t, (ulong)InpSlippage); need -= v; }
         else
         {
            double part = NormalizeDouble(MathRound(need / step) * step, 2);
            if(part >= step) trade.PositionClosePartial(t, part, (ulong)InpSlippage);
            need = 0;
         }
      }
   }
   else
   {
      ulong bT[]; ulong sT[];
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !MyPos()) continue;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { int k = ArraySize(bT); ArrayResize(bT, k + 1); bT[k] = t; }
         else { int k = ArraySize(sT); ArrayResize(sT, k + 1); sT[k] = t; }
      }
      int nb = ArraySize(bT), ns = ArraySize(sT);
      if(CloseByAllowed() && nb > 0 && ns > 0 && gClosePass <= 5)
      {
         int np = MathMin(nb, ns);
         for(int j = 0; j < np; j++) trade.PositionCloseBy(bT[j], sT[j]);
      }
      else
      {
         for(int j = 0; j < nb; j++) trade.PositionClose(bT[j], (ulong)InpSlippage);
         for(int j = 0; j < ns; j++) trade.PositionClose(sT[j], (ulong)InpSlippage);
      }
   }
   trade.SetAsyncMode(false);
}

void StartClose(string why)
{
   if(gClosing) return;
   gClosing = true;
   gCloseWhy = why;
   gCloseStart = TimeCurrent();
   gCloseEst = gCycleBank + gFloat;
   gLastCloseSend = 0;
   gClosePass = 0;
   SaveState();
   GlobalVariablesFlush();
   Log(1, StringFormat("%s | cycle bank $%.2f + khula $%.2f = $%.2f | %d trades", why, gCycleBank, gFloat, gCloseEst, gBuys + gSells));
   SendCloseAll();
}

// v2.05: chalu cycle me side dobara dekho (pehle cycle bhar lock rehti thi)
// trend khatam -> dono side; trend ulta -> side palto. Dono side se ek side
// beech cycle me nahi jaate (real EA me dono side ke stop rehte hain)
void RecheckSides()
{
   if(InpBothSidesAlways || gClosing || gCycleStart <= 0 || gSides == 0) return;
   int ns = gSides;
   if(gTrendDir == 0)            ns = 0;
   else if(gTrendDir == -gSides) ns = gTrendDir;
   if(ns == gSides) return;
   gSides = ns;
   SaveState();
   Log(0, StringFormat("Trend badla (%s): ab %s", Money(gTrendMove),
       gSides == 0 ? "dono side" : (gSides == 1 ? "sirf BUY" : "sirf SELL")));
}

//+------------------------------------------------------------------+
//| MAIN                                                             |
//+------------------------------------------------------------------+
void Engine()
{
   UpdateDay();
   UpdateState();
   UpdateTrend();
   RecheckSides();
   UpdateNews();
   gCycleBank = (gCycleStart > 0) ? DealsSince(gCycleStart) : 0;   // is cycle ka bank (history se)
   gBankDirty = false;
   gDayPL = CalcDayPL();
   gDeepDD = (gFloat <= -MathAbs(InpDeepDDUSD));
   int open = gBuys + gSells, pend = gPendB + gPendS;

   //--- 1) band karna chal raha hai
   if(gClosing)
   {
      if(open == 0 && pend == 0)
      {
         double real = (gCycleStart > 0) ? DealsSince(gCycleStart) : 0;
         gClosing = false;
         gLastCycle = real;
         string w = gCloseWhy;
         Log(0, StringFormat("CYCLE #%d BAND (%s) | BANK $%.2f | target $%.2f", gCycleNo, w, real, CycleTarget()));
         Notify(StringFormat("Cycle #%d band (%s) %s$%.2f", gCycleNo, w, real >= 0 ? "+" : "-", MathAbs(real)));
         gCycleStart = 0; gCenter = 0; gCycleHadPos = false; gCycleBank = 0;
         SaveState();
         GlobalVariablesFlush();
      }
      else SendCloseAll();
      return;
   }

   //--- 2) din ke caps
   if(!gDayDone)
   {
      if(gDayPL >= DayProfitCap())
      {
         gDayDone = true; gDayDoneWhy = "PROFIT CAP";
         Log(0, StringFormat("DAY PROFIT CAP: aaj %s$%.2f / $%.2f - aaj aur trade nahi", gDayPL >= 0 ? "+" : "", gDayPL, DayProfitCap()));
         Notify(StringFormat("Day profit cap poora +$%.2f - aaj band", gDayPL));
         SaveState();
         if(open + pend > 0) { StartClose("DAY PROFIT CAP"); return; }
      }
      else if(InpHardDailyStop && gDayPL <= -DayLossCap())
      {
         gDayDone = true; gDayDoneWhy = "LOSS CAP";
         gPauseUntil = (datetime)((long)gDayStart + (long)(MathMax(0, InpPauseDaysAfterLoss) + 1) * 86400);
         gDoublePending = InpAfterLossDouble;
         Log(0, StringFormat("DAY LOSS CAP: aaj $%.2f / -$%.2f - band, %s tak ruko", gDayPL, DayLossCap(), TimeToString(gPauseUntil, TIME_DATE)));
         Notify(StringFormat("DAY LOSS CAP $%.2f - sab band, %s tak trading nahi", gDayPL, TimeToString(gPauseUntil, TIME_DATE)));
         SaveState();
         GlobalVariablesFlush();
         if(open + pend > 0) { StartClose("DAY LOSS CAP"); return; }
      }
   }
   else if(open + pend > 0 && (gDayDoneWhy != ""))
   {
      StartClose(gDayDoneWhy == "LOSS CAP" ? "DAY LOSS CAP" : "DAY PROFIT CAP");
      return;
   }

   //--- 3) cycle chal raha hai (target tak isi cycle me)
   if(gCycleStart > 0)
   {
      double net = gCycleBank + gFloat;
      if(net >= CycleTarget()) { StartClose("CYCLE BANK"); return; }
      if(InpWholeBookGreen > 0 && open > 0 && gFloat >= InpWholeBookGreen) { StartClose("GREEN BANK"); return; }
      if(InpAllowNewCycleFlat && open == 0 && gCycleHadPos) { StartClose("FLAT NEW CYCLE"); return; }
      // ek bhi trade nahi khula aur price grid se door chala gaya (one-side trend grid) -> naya cycle
      if(!gCycleHadPos && open == 0 && gCenter > 0 && gStep > 0)
      {
         double mid = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
         if(MathAbs(mid - gCenter) > 3.0 * gStep) { StartClose("FLAT NEW CYCLE"); return; }
      }

      TrailLegs();
      CutLoserFromBank();
      if(!gDayDone) VirtualTriggers();
      return;
   }

   //--- 4) koi cycle nahi -> naya cycle?
   if(open > 0 || pend > 0)
   {
      // EA restart / state kho gaya: purane trades ko cycle maan lo
      // state kho gayi: sabse purani khuli trade ke time se cycle maano, naye pending nahi (grid beech pata nahi)
      datetime first = TimeCurrent();
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !MyPos()) continue;
         datetime pt = (datetime)PositionGetInteger(POSITION_TIME);
         if(pt < first) first = pt;
      }
      gCycleStart = first;
      gCenter = 0;
      if(gStep <= 0) gStep = NormP(InpGridStepUSD * SymbolInfoDouble(_Symbol, SYMBOL_BID) / MathMax(1.0, InpPriceScaleReference));
      gCycleNo++;
      SaveState();
      Log(0, "Purane trades mile - unhe chalu cycle maan ke manage kar rahe hain (target / trailing)");
      return;
   }
   if(!gTradingOn || gDayDone) return;
   if(TimeTradeServer() < gPauseUntil) return;
   if(InpNewsFilter && gNewsNow != "") return;
   if(IsWeekendIst()) return;
   if(InpMaxSpread > 0 && SpreadNow() > InpMaxSpread) return;
   if(InpBoxFilter) { double r = BoxRange(); if(r >= 0 && r <= BOX_MAX) return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) return;
   NewCycle();
}

//+------------------------------------------------------------------+
//| PANEL                                                            |
//+------------------------------------------------------------------+
int PX(double v) { return (int)MathRound(v * gK); }
int FS(double v) { return (int)MathMax(6.0, MathRound(v * gScale)); }

void ObjBase(string nm, ENUM_OBJECT type)
{
   if(ObjectFind(0, nm) < 0) ObjectCreate(0, nm, type, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nm, OBJPROP_BACK, false);
}
void UiRect(string n, double x, double y, double w, double h, color bg, color br, int bw = 1)
{
   string nm = PFX + n; ObjBase(nm, OBJ_RECTANGLE_LABEL);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, MathMax(1, PX(w)));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, MathMax(1, PX(h)));
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, br);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH, bw);
}
void UiText(string n, double x, double y, string t, color c, double fs, string font = "Bahnschrift", ENUM_ANCHOR_POINT a = ANCHOR_LEFT)
{
   string nm = PFX + n; ObjBase(nm, OBJ_LABEL);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, a);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetString(0, nm, OBJPROP_FONT, font);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(fs));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
}
void UiBtn(string n, double x, double y, double w, double h, string t, color fg, color bg, color br, double fs)
{
   string nm = PFX + n; ObjBase(nm, OBJ_BUTTON);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, PX(w));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, PX(h));
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetString(0, nm, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(fs));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, br);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
}
void SetT(string n, string t, color c)
{
   string nm = PFX + n;
   if(ObjectFind(0, nm) < 0) return;
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
}
void PaintTradeBtn()
{
   string nm = PFX + "btnTrade";
   if(ObjectFind(0, nm) < 0) return;
   ObjectSetString(0, nm, OBJPROP_TEXT, gTradingOn ? "TRADING  ON" : "TRADING  OFF");
   ObjectSetInteger(0, nm, OBJPROP_COLOR, gTradingOn ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, gTradingOn ? C'8,46,30' : C'50,12,22');
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, gTradingOn ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
}

#define PW     340.0
#define RH     22.0
#define Y_ROWS 74.0
#define N_ROWS 14

void Row(int i, string key, string label)
{
   double y = Y_ROWS + i * RH;
   UiRect("rw" + key, 8, y, PW - 16, RH - 3, (i % 2 == 0 ? CLR_CELL : CLR_BOX), CLR_BOX, 1);
   UiText("lb" + key, 16, y + (RH - 3) / 2.0, label, TXT_DIM, 8.5);
   UiText("vl" + key, PW - 16, y + (RH - 3) / 2.0, "-", TXT_W, 9, "Consolas", ANCHOR_RIGHT);
}

void BuildPanel()
{
   if(!InpChartUI) return;
   string cu = " (" + AccCur() + ")";
   double H = Y_ROWS + N_ROWS * RH + 84;
   UiRect("bg", 0, 0, PW, H, CLR_BG, NEON_CY, 2);
   UiRect("logo", 8, 7, 26, 26, GOLD_C, GOLD_C, 1);
   UiText("logoB", 21, 20, "TG", C'12,12,12', 9, "Arial Black", ANCHOR_CENTER);
   UiText("title", 42, 13, EA_NAME, TXT_W, 11, "Arial Black");
   UiText("ver", 42, 29, EA_VER + "  |  " + _Symbol + "  |  magic " + IntegerToString(InpMagic) + "  |  " + AccCur(), TXT_DIM, 7.5);
   UiRect("st", 8, 42, PW - 16, 26, CLR_BOX, NEON_PU, 1);
   UiText("stT", PW / 2.0, 55, "-", NEON_GR, 10, "Arial Black", ANCHOR_CENTER);
   Row(0,  "cyc",   "CYCLE # / side");
   Row(1,  "bank",  "Cycle BANK" + cu);
   Row(2,  "flt",   "Khula P/L" + cu);
   Row(3,  "net",   "CYCLE NET / target" + cu);
   Row(4,  "buy",   "BUY khule / lot");
   Row(5,  "sell",  "SELL khule / lot");
   Row(6,  "pend",  "PENDING buy / sell");
   Row(7,  "trail", "Trailing legs / gate");
   Row(8,  "grid",  "GRID beech / gap (price)");
   Row(9,  "trend", "TREND (" + IntegerToString(InpTrendBars) + " candle move)");
   Row(10, "day",   "AAJ P/L" + cu);
   Row(11, "caps",  "Caps profit / loss" + cu);
   Row(12, "mult",  "Lot mode / x");
   Row(13, "last",  "Pichhla cycle" + cu);
   double by = Y_ROWS + N_ROWS * RH + 6;
   UiBtn("btnTrade", 8, by, (PW - 24) / 2.0, 30, "TRADING  ON", NEON_GR, C'8,46,30', NEON_GR, 9);
   UiBtn("btnClose", 16 + (PW - 24) / 2.0, by, (PW - 24) / 2.0, 30, "CLOSE ALL", NEON_RD, C'50,12,22', NEON_RD, 9);
   UiText("msg", 12, by + 46, "-", TXT_DIM, 7.5);
   PaintTradeBtn();
   ChartRedraw();
}

void UpdatePanel()
{
   if(!InpChartUI) return;
   string st; color sc;
   int open = gBuys + gSells;
   bool algoOff = (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED));
   if(algoOff)                                  { st = "ALGO TRADING OFF - ON KARO"; sc = NEON_RD; }
   else if(gClosing)                            { st = "BAND HO RAHA HAI...";      sc = NEON_OR; }
   else if(TimeTradeServer() < gPauseUntil && open == 0) { st = "LOSS PAUSE - " + TimeToString(gPauseUntil, TIME_DATE); sc = NEON_RD; }
   else if(gDayDone && open == 0)               { st = "DAY " + gDayDoneWhy + " - AAJ BAND"; sc = gDayDoneWhy == "PROFIT CAP" ? NEON_GR : NEON_RD; }
   else if(gCycleStart > 0 && open > 0)         { st = gDeepDD ? "CYCLE - DEEP DD" : "CYCLE CHAL RAHA"; sc = gDeepDD ? NEON_RD : NEON_CY; }
   else if(gCycleStart > 0)                     { st = "GRID LAGA - FILL KA WAIT";  sc = NEON_PU; }
   else if(!gTradingOn)                         { st = "TRADING OFF";              sc = NEON_RD; }
   else if(InpNewsFilter && gNewsNow != "")     { st = "NEWS - WAIT";              sc = NEON_OR; }
   else                                         { st = "NAYA CYCLE LAG RAHA";      sc = NEON_OR; }
   SetT("stT", st, sc);

   string side = (gSides == 0 ? "DONO" : gSides == 1 ? "SIRF BUY" : "SIRF SELL");
   SetT("vlcyc", "#" + IntegerToString(gCycleNo) + "  /  " + side, gSides == 0 ? TXT_W : NEON_OR);
   SetT("vlbank", Money(gCycleBank), gCycleBank >= 0 ? NEON_GR : NEON_RD);
   SetT("vlflt", Money(gFloat), gFloat >= 0 ? NEON_GR : NEON_RD);
   double net = gCycleBank + gFloat;
   SetT("vlnet", Money(net) + "  /  " + DoubleToString(CycleTarget(), 2), net >= 0 ? NEON_GR : NEON_RD);
   SetT("vlbuy",  IntegerToString(gBuys)  + "  /  " + DoubleToString(gLotB, 2), gBuys  > 0 ? NEON_CY : TXT_W);
   SetT("vlsell", IntegerToString(gSells) + "  /  " + DoubleToString(gLotS, 2), gSells > 0 ? NEON_MG : TXT_W);
   SetT("vlpend", IntegerToString(gPendB) + "  /  " + IntegerToString(gPendS), TXT_W);
   bool gate = InpTrailEvenIfRed || (AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE) >= InpGreenGate);
   SetT("vltrail", IntegerToString(gTrailing) + "  /  " + (gate ? "GREEN (chalu)" : "RED (ruka)"), gate ? NEON_GR : NEON_OR);
   SetT("vlgrid", (gCenter > 0 ? DoubleToString(gCenter, _Digits) : "-") + "  /  " + DoubleToString(gStep, 2), TXT_W);
   SetT("vltrend", (gTrendDir == 1 ? "UP  " : gTrendDir == -1 ? "DOWN  " : "NONE  ") + Money(gTrendMove), gTrendDir == 0 ? TXT_DIM : NEON_OR);
   SetT("vlday", Money(gDayPL) + (InpIndependentFloatStop ? "  (EA)" : "  (equity)"), gDayPL >= 0 ? NEON_GR : NEON_RD);
   SetT("vlcaps", DoubleToString(DayProfitCap(), 0) + "  /  " + (InpHardDailyStop ? DoubleToString(DayLossCap(), 0) : "OFF"), TXT_W);
   SetT("vlmult", (InpLotMode == LOT_MODE_AUTO ? "AUTO" : "FIXED") + "  /  x" + DoubleToString(gMultToday, 0) + (gDeepDD ? "  DD-x2" : ""),
        gMultToday > 1 ? NEON_OR : TXT_W);
   SetT("vllast", Money(gLastCycle), gLastCycle >= 0 ? NEON_GR : NEON_RD);
   SetT("msg", gMsg, TXT_DIM);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| EVENTS                                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == PFX + "btnTrade")
   {
      gTradingOn = !gTradingOn; SaveState();
      Log(0, gTradingOn ? "Trading ON" : "Trading OFF - chal raha cycle poora hoga, naya nahi");
      PaintTradeBtn(); UpdatePanel(); return;
   }
   if(sparam == PFX + "btnClose")
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      UpdateState();
      if(gBuys + gSells + gPendB + gPendS == 0) { Log(0, "Band karne ko kuch nahi"); UpdatePanel(); return; }
      StartClose("MANUAL CLOSE ALL");
      UpdatePanel();
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) gBankDirty = true;
}

int OnInit()
{
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Alert(EA_NAME, ": ye EA sirf HEDGING account par chalega");
      return INIT_FAILED;
   }
   double px = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(px > 0 && px < 500)
   {
      Alert(EA_NAME, ": ye EA GOLD (XAUUSD) ke liye bana hai - ", _Symbol, " par nahi chalega");
      return INIT_FAILED;
   }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   gScale = MathMax(0.6, MathMin(2.5, InpPanelScale));
   gK = gScale * (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

   LoadState();
   if(InpBothSidesAlways && gSides != 0)
   {
      gSides = 0;
      Log(0, "Both sides always = true: chalu cycle me ab dono side ke stop lagenge");
   }
   if(gDayStart != ServerDayStart())
   {
      gDayStart = 0;      // UpdateDay naya din set karega
   }
   if(gDayStartEq <= 0 || gDseTime == 0)
   {
      gDayStartEq = AccountInfoDouble(ACCOUNT_EQUITY);   // purane version se aaye: yahin se ginti
      gDseTime    = TimeCurrent();
   }
   UpdateDay();
   UpdateState();
   // profit cap galat laga tha (jaise deposit ko profit samjha) -> sahi hisaab se dobara dekho
   if(gDayDone && gDayDoneWhy != "LOSS CAP")
   {
      double pl = CalcDayPL();
      if(pl < DayProfitCap())
      {
         gDayDone = false; gDayDoneWhy = "";
         Log(0, StringFormat("Day profit cap hataya - sahi aaj ka P/L %.2f (cap %.2f se kam)", pl, DayProfitCap()));
      }
   }
   SaveState();

   if(AccCur() != "USD")
   {
      string w = "Account currency " + AccCur() + " hai - target / caps " + AccCur() + " me gine jaayenge";
      if(IsCentAccount()) { w += ". CENT account: inputs 100 guna karo"; Alert(EA_NAME, ": ", w); }
      Print(EA_NAME, " | DHYAN: ", w);
   }
   if(gClosing)
   {
      string rm = "RESTART: pichla close (" + gCloseWhy + ") adhoora tha - pehle wahi poora";
      Log(0, rm); Notify(rm);
   }
   if(InpPush && !IsTester() && !TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      Print(EA_NAME, " | Mobile alert ke liye: Tools > Options > Notifications me MetaQuotes ID daalo");

   Comment("");
   BuildPanel();
   UpdatePanel();
   EventSetTimer(1);
   Print(EA_NAME, " ", EA_VER, " start | ", _Symbol, " | levels ", InpLevels, " | gap ", DoubleToString(InpGridStepUSD, 2),
         " @ ", DoubleToString(InpPriceScaleReference, 0), " | lots ", DoubleToString(InpNearLot, 2), "/", DoubleToString(InpMidLot, 2), "/",
         DoubleToString(InpFarLot, 2), " (tier ", NearCount(), "/", MidCount(), "/", InpLevels - NearCount() - MidCount(), ")",
         " | cycle target ", CurLabel(), DoubleToString(CycleTarget(), 2), " | day cap +", DoubleToString(DayProfitCap(), 0),
         " / -", DoubleToString(DayLossCap(), 0), " | trail arm ", InpTrailArmGrids, " dist ", InpTrailDistGrids);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   SaveState();
   ObjectsDeleteAll(0, PFX);
   Comment("");
   ChartRedraw();
}

void OnTick()
{
   Engine();
}

uint gLastArm = 0;
void OnTimer()
{
   Engine();
   // har second: khali levels par pending (cycle chal raha ho, band na ho raha ho)
   if(!gClosing && gCycleStart > 0 && !gDayDone && GetTickCount() - gLastArm >= 1000)
   {
      gLastArm = GetTickCount();
      UpdateTrend();
      ArmLevels();
   }
   UpdatePanel();
}
//+------------------------------------------------------------------+
