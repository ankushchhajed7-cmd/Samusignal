//+------------------------------------------------------------------+
//|                                        Tithi Gold v1.05.mq5      |
//|                     Ankush New Vision - Gold Basket Stop Grid    |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| NAAM: "Tithi Gold" (pehle "Basket Grid 3USD" naam se bana tha)   |
//| v1.05 (14-Oct-2026) - DABBA FILTER (rolling High-Low range)       |
//|  - Naya grid lagane se pehle pichhle 2 ghante (M5 x 24 candle,    |
//|    chalu candle samet) ka High - Low dekha jaata hai              |
//|  - Range 8.00 (gold price) ya kam = market dabbe me ghoom raha    |
//|    hai -> naya grid NAHI, wait. Har second check: dabba toota     |
//|    (range 8 se upar) to turant grid                               |
//|  - Chalte basket / lage pending par koi asar nahi                 |
//|  - Input: sirf "Dabba filter" true / false                        |
//| v1.04 (14-Oct-2026) - RESTART SAFETY + CURRENCY                   |
//|  - Band karna (close) chal raha ho aur MT5 / VPS restart ho jaye: |
//|    "close chal raha hai" + uska kaaran (profit book / daily loss /|
//|    manual / atka / news / weekend / max loss) save rehta hai.     |
//|    Restart ke baad EA SABSE PEHLE wahi close poora karta hai,     |
//|    naya grid / trailing baad me                                   |
//|  - Close By 5 baar me poora na ho to market close (atakna nahi)   |
//|  - Currency: saare target / loss / lock ACCOUNT CURRENCY me hain. |
//|    Panel aur msg me ab account ki currency dikhti hai (USD = $).  |
//|    USD nahi ho to start par chetavani; CENT account (USC) par     |
//|    alag se Alert (3.00 = sirf 3 cent)                             |
//|  - Gap / spread / trailing doori GOLD PRICE me hain ("price")     |
//| v1.03 (14-Oct-2026) - SLIPPAGE FIX (basket +$2.77 par band hua,   |
//|                       asli -$1.78 aaya: 4 buy + 11 sell, net      |
//|                       0.09 lot SELL khula tha, band hote hote     |
//|                       price $0.50 upar gaya)                      |
//|  - SMART CLOSE: pehle sirf EXTRA lot (net khula risk) band ->     |
//|    profit wahin lock. Phir bache buy-sell jode CLOSE BY se band   |
//|    (inpe price hilne ka asar nahi, spread bhi bachta hai)         |
//|  - Lock me slippage buffer: $3 + (net lot x $0.30 price)          |
//|    0.01 lot -> $3.30, 0.09 lot -> $5.70                           |
//|  - Basket band hone par ASLI profit history se padh ke log +      |
//|    mobile alert (andaza / asli / slippage)                        |
//|  - Panel: NET lot (khula risk) row                                |
//| v1.02 (13-Oct-2026) - GAP $1.50                                   |
//|  - Default gap $2.00 -> $1.50 (30 level = $45 range,              |
//|    0.03 lot $15 par, 0.09 lot $30 par)                            |
//|  - Galti se forex pair (EURUSD wagairah) par lagaya to EA band:  |
//|    gap / spread / trailing $ me gold ke hisaab se hain            |
//| v1.01 (13-Oct-2026) - TARGET / LOSS / NEWS / SPREAD / WEEKEND /   |
//|                       MOBILE ALERT / ATKA BASKET / LOT TRAILING   |
//|  - Daily profit target $ (0 = off). Aaj (IST raat 12 se) ka band  |
//|    profit target tak pahunche -> naya grid nahi, kal IST 12 baje  |
//|    se apne aap dobara shuru                                       |
//|  - News filter (MT5 calendar, HIGH impact, USD): news se 30 min   |
//|    pehle se 30 min baad tak naya grid nahi lagega. Sirf pending   |
//|    hon to hat jaate hain. Basket chal raha ho to: pending hatao,  |
//|    khule trades apne $3 trailing se band (setting se badal sakte) |
//|  - Daily loss limit $ (0 = off): aaj ka band + khula basket       |
//|    itna minus ho -> sab band, kal IST 12 baje tak trading band    |
//|  - Spread filter ab default ON ($0.50): spread zyada ho to naya   |
//|    grid nahi lagega (rollover / news spike se bachne ke liye)     |
//|  - Weekend stop (IST): Shukra 14:00 se Somvar 08:00 tak naya     |
//|    grid nahi, pending hatenge; chal raha basket trailing se band  |
//|    (chaho to weekend shuru hote hi sab band - setting)            |
//|  - Mobile alert (MT5 push): basket band, daily target / loss,     |
//|    max loss, news ruka, weekend stop                              |
//|  - ATKA BASKET: basket 4 ghante se khula ho YA 20+ trades khule  |
//|    hon -> target $3 se ghata ke $0 (breakeven). Net $0 aate hi    |
//|    sab band, bina loss ke bahar                                   |
//|  - TRAILING MODE (3 tarah):                                       |
//|    LOT  = doori lot ke hisaab se: gold price $0.50 x khula net    |
//|           lot (0.01 lot = $1 min, 0.50 lot = $25) - DEFAULT       |
//|    FIXED = hamesha $1 (v1.00 jaisa)                               |
//|    %    = peak ka 70% pakka (peak $20 -> lock $14)                |
//|  - Panel: AAJ profit / target, daily loss, spread, NEWS (IST)     |
//|  - Aaj ka profit + cycles ab IST din ke hisaab se                 |
//| v1.00 (13-Oct-2026) - pehla build                                 |
//|  - Investor account wale EA ki strategy par bana:                 |
//|    price ke upar 30 BUY STOP + neeche 30 SELL STOP                |
//|  - Gap $2.00 (input). Pehla buy = price + 1 gap,                 |
//|    pehla sell = price - 1 gap                                     |
//|  - Lot tiers: level 1-10 = 0.01, 11-20 = 0.03, 21-30 = 0.09       |
//|    (base lot x multiplier har 10 level par)                      |
//|  - BASKET TRAILING: saari khuli trades ka NET profit              |
//|    (buy + sell + swap + commission) $3 ho -> trailing shuru.      |
//|    Lock kam se kam $3. Peak se $1 girte hi SAB trades band        |
//|    + saare pending delete -> naye price par naya grid.            |
//|  - Optional safety: Max basket loss $ (0 = off)                  |
//|  - Neon panel: net P/L, peak, lock, trades, aaj ka profit,       |
//|    TRADING ON/OFF aur CLOSE ALL button                           |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.05"
#property description "Tithi Gold v1.05 - 30 buy stop + 30 sell stop gold grid, basket trailing, daily target / loss, news + spread filter. Paise wale inputs account currency me."

#include <Trade\Trade.mqh>

#define EA_NAME  "Tithi Gold"
#define EA_VER   "v1.05"
#define PFX      "TITHI105_"
#define GVP      "TITHIG_"      // global variables (version badalne par bhi same)
#define CMT_TAG  "TITHI"

//--- dabba filter (fixed values)
#define BOX_TF     PERIOD_M5      // M5 candles
#define BOX_BARS   24             // 24 x M5 = pichhle 2 ghante
#define BOX_MAX    8.0            // range itna ya kam (gold price) = dabba

//--- neon colours
#define CLR_BG     C'6,10,20'
#define CLR_BOX    C'11,17,31'
#define CLR_CELL   C'15,23,41'
#define CLR_LINE   C'30,44,74'
#define NEON_CY    C'0,229,255'
#define NEON_MG    C'255,61,240'
#define NEON_PU    C'150,110,255'
#define NEON_GR    C'57,255,136'
#define NEON_RD    C'255,77,109'
#define NEON_OR    C'255,170,0'
#define GOLD_C     C'255,196,46'
#define TXT_W      C'232,238,255'
#define TXT_DIM    C'125,140,175'

//=== INPUTS ========================================================
input group "=== EA Identification ==="
input long   InpMagic          = 111555;  // Magic Number

input group "=== Grid ==="
input double InpGap            = 1.50;    // Gap (gold PRICE me, jaise 1.50) - do levels ke beech doori
input int    InpLevels         = 30;      // Har side kitne levels (30 buy stop + 30 sell stop)
input double InpBaseLot        = 0.01;    // Pehle tier ka lot
input double InpLotMultiplier  = 3.0;     // Har tier par lot x (0.01 -> 0.03 -> 0.09)
input int    InpLevelsPerTier  = 10;      // Kitne levels ke baad lot badhe

enum ENUM_TRAIL_MODE
{
   TRAIL_LOT     = 0,   // LOT ke hisaab se (gold price doori x khula lot)
   TRAIL_FIXED   = 1,   // FIXED doori (account currency me)
   TRAIL_PERCENT = 2    // PEAK ka % pakka
};

input group "=== Basket Trailing (sab trades ek saath) ==="
input double InpTrailStart     = 3.00;    // Trailing kab shuru: net basket profit (account currency)
input double InpMinLock        = 3.00;    // Kam se kam itna lock (account currency) - isse neeche aate hi band
input ENUM_TRAIL_MODE InpTrailMode = TRAIL_LOT; // Trailing doori kaise ho
input double InpTrailDist      = 1.00;    // FIXED doori (account currency) - LOT mode me ye kam se kam doori
input double InpTrailPriceDist = 0.50;    // LOT mode: gold PRICE kitna ulta chale (0.50 = 50 cent price)
input double InpTrailKeepPct   = 70;      // % mode: peak ka kitna % pakka (70 = peak 20 par lock 14)
input double InpSlipBuffer     = 0.30;    // Slippage buffer: lock me + (gold PRICE x net khula lot), jaise 0.30 price x 0.09 lot
input bool   InpUseCloseBy     = true;    // Buy-sell jodi CLOSE BY se band (broker allow kare to)
input bool   InpCountCommission= true;    // Net profit me commission bhi gino (entry x2)
input bool   InpDeletePendOnTrail = false;// Trailing shuru hote hi pending hata do

input group "=== Daily Target / Loss ==="
input double InpDailyTarget    = 50.00;   // Daily profit target (account currency, 0 = off) - pura hote hi aaj naya grid nahi
input double InpDailyLoss      = 100.00;  // Daily loss limit (account currency, 0 = off) - aaj band + khula itna minus = sab band

input group "=== Dabba Filter ==="
input bool   InpBoxFilter      = true;    // Dabba filter: pichhle 2 ghante ka range 8.00 ya kam ho to naya grid nahi

input group "=== Spread Filter ==="
input double InpMaxSpread      = 0.50;    // Max spread (gold PRICE, jaise 0.50) - isse zyada ho to naya grid nahi (0 = off)

enum ENUM_NEWS_ACT
{
   NEWS_KEEP      = 0,   // Basket chalne do, pending bhi rahein
   NEWS_DEL_PEND  = 1,   // Pending hatao, khule trades trailing se band
   NEWS_CLOSE_ALL = 2    // Sab turant band (loss ho to bhi)
};

input group "=== News Filter ==="
input bool          InpNewsFilter    = true;          // News filter ON/OFF
input int           InpNewsBefore    = 30;            // News se kitne minute PEHLE ruk jao
input int           InpNewsAfter     = 30;            // News ke kitne minute BAAD tak ruko
input string        InpNewsCurrencies= "USD";         // News currencies (comma se, jaise USD,EUR)
input bool          InpNewsMedium    = false;         // Medium impact news bhi gino
input ENUM_NEWS_ACT InpNewsBasket    = NEWS_DEL_PEND; // News aate waqt basket chal raha ho to

input group "=== Atka Basket (rescue) ==="
input bool   InpRescueOn       = true;    // Atka basket nikalna ON/OFF
input double InpRescueHours    = 4;       // Basket itne ghante se khula ho to atka maano (0 = off)
input int    InpRescueTrades   = 20;      // Itne ya zyada trades khule hon to atka maano (0 = off)
input double InpRescueTarget   = 0.00;    // Atke basket ka target (account currency; 0 = breakeven, -5 = 5 ka loss manzoor)

input group "=== Weekend Stop (IST time) ==="
input bool            InpWeekendStop    = true;     // Weekend stop ON/OFF
input ENUM_DAY_OF_WEEK InpWkStopDay     = FRIDAY;   // Kis din se band
input int             InpWkStopHour     = 14;       // Kitne baje se band (IST, 0-23)
input ENUM_DAY_OF_WEEK InpWkStartDay    = MONDAY;   // Kis din se chalu
input int             InpWkStartHour    = 8;        // Kitne baje se chalu (IST, 0-23)
input bool            InpWkCloseAll     = false;    // Weekend shuru hote hi chal raha basket bhi band karo

input group "=== Mobile Alert (MT5 push) ==="
input bool   InpPush           = true;    // Mobile alert ON/OFF (MT5 me MetaQuotes ID daalna zaroori)
input bool   InpPushBasket     = true;    // Har basket band hone par alert
input bool   InpPushTrail      = false;   // Trailing shuru hone par alert
input bool   InpPushRisk       = true;    // Daily target / loss, max loss, news, weekend alert

input group "=== Safety ==="
input double InpMaxBasketLoss  = 0;       // Basket loss (account currency) itna ho to sab band (0 = off)
input int    InpPauseAfterLossMin = 60;   // Loss band ke baad kitne minute ruke
input int    InpWaitAfterCloseSec = 0;    // Basket band hone ke baad naya grid kitne second baad
input bool   InpForceMinVolume = true;    // Lot kam ho to broker ka min lot lo
input int    InpSlippage       = 1000;    // Slippage (points)

input group "=== Panel ==="
input double InpPanelScale     = 1.40;    // Panel size (phone ke liye 1.3 - 1.6)
input int    InpPanelX         = 10;      // Panel X
input int    InpPanelY         = 25;      // Panel Y

//=== GLOBALS =======================================================
CTrade   trade;
double   gK = 1.0;
double   gScale = 1.0;

bool     gTradingOn   = true;
bool     gClosing     = false;     // CLOSE ALL chal raha hai
string   gCloseWhy    = "";
bool     gTrailOn     = false;
double   gPeak        = 0;         // trailing shuru hone ke baad ka sabse uncha net
double   gWorst       = 0;         // is basket ka sabse bura net
double   gWorstEver   = 0;         // EA chalu hone ke baad sabse bura basket
double   gCenter      = 0;         // grid ka beech ka price
int      gPlaced      = 0;         // is grid me kitne pending lage the
datetime gLastClose   = 0;
datetime gPauseUntil  = 0;
uint     gLastCloseSend = 0;
int      gCycles      = 0;         // aaj kitne basket band hue
double   gLastBasket  = 0;
string   gMsg         = "";
datetime gCloseStart  = 0;         // basket band karna kab shuru hua
double   gCloseEntryCom = 0;       // band hote basket ka entry commission
int      gClosePass   = 0;         // close ke kitne round ho chuke
bool     gBoxWait     = false;     // dabba ki wajah se grid ruka hai
double   gBoxRange    = -1;        // pichhle 2 ghante ka High - Low

// live counts
int      gBuys = 0, gSells = 0, gPendB = 0, gPendS = 0;
double   gLotB = 0, gLotS = 0, gNet = 0;
double   gToday = 0;
datetime gTodayCalc = 0;

// daily / news
datetime gDayStart    = 0;         // aaj IST raat 12 ka server time
bool     gTargetHit   = false;
bool     gLossHit     = false;     // aaj daily loss limit lag chuki
datetime gNewsT[];
string   gNewsN[];
datetime gNewsLoaded  = 0;
string   gNewsNow     = "";        // news window chal rahi ho to naam
string   gNewsNext    = "";        // agli news (panel ke liye)
bool     gNewsPrev    = false;
bool     gWeekend     = false;
bool     gWeekendPrev = false;
datetime gFirstOpen   = 0;         // basket ki pehli trade kab khuli
bool     gStuck       = false;
bool     gStuckPrev   = false;

// commission cache (position ticket -> entry commission)
ulong    gComTk[];
double   gComVal[];

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
double TickSize()
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return (ts > 0 ? ts : _Point);
}

double NormP(double p)
{
   double ts = TickSize();
   return NormalizeDouble(MathRound(p / ts) * ts, _Digits);
}

double NormLot(double l)
{
   double mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(st <= 0) st = 0.01;
   int dg = (int)MathMax(0.0, MathCeil(-MathLog10(st) - 1e-9));
   l = MathFloor(l / st + 1e-9) * st;
   if(l < mn) l = (InpForceMinVolume ? mn : 0);
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

bool MyPos()
{
   return (PositionGetString(POSITION_SYMBOL) == _Symbol &&
           PositionGetInteger(POSITION_MAGIC) == InpMagic);
}

bool MyOrd()
{
   return (OrderGetString(ORDER_SYMBOL) == _Symbol &&
           OrderGetInteger(ORDER_MAGIC) == InpMagic);
}

double LevelLot(int lvl)   // lvl = 1..InpLevels
{
   int per  = MathMax(1, InpLevelsPerTier);
   int tier = (lvl - 1) / per;
   return NormLot(InpBaseLot * MathPow(MathMax(1.0, InpLotMultiplier), tier));
}

double SpreadNow()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

//--- currency: saare paise wale number account ki currency me hote hain
string AccCur() { return AccountInfoString(ACCOUNT_CURRENCY); }
string CurLabel()
{
   string c = AccCur();
   if(c == "USD" || c == "") return "$";
   return c + " ";
}
bool IsCentAccount()
{
   string c = AccCur();
   StringToUpper(c);
   return (c == "USC" || c == "EUC" || StringFind(c, "CENT") >= 0);
}
// msg me "$" ko account currency se badlo (USD account par kuch nahi badalta)
string CurFix(string m)
{
   string c = CurLabel();
   if(c != "$") StringReplace(m, "$", c);
   return m;
}

void SetMsg(string m)
{
   m = CurFix(m);
   gMsg = m;
   Print(EA_NAME, " | ", m);
}

string Money(double v)
{
   return (v >= 0 ? "+" : "") + DoubleToString(v, 2);
}

//--- global variables (EA restart par state yaad rahe)
string GVName(string k)
{
   return GVP + IntegerToString(InpMagic) + "_" + _Symbol + "_" + k;
}
void GVSet(string k, double v) { GlobalVariableSet(GVName(k), v); }
double GVGet(string k, double def)
{
   string n = GVName(k);
   if(!GlobalVariableCheck(n)) return def;
   return GlobalVariableGet(n);
}

int WhyCode(string w)
{
   if(StringFind(w, "PROFIT BOOK") == 0)       return 1;
   if(StringFind(w, "ATKA") == 0)              return 2;
   if(StringFind(w, "DAILY LOSS") == 0)        return 3;
   if(StringFind(w, "MAX LOSS") == 0)          return 4;
   if(StringFind(w, "MANUAL") == 0)            return 5;
   if(StringFind(w, "NEWS") == 0)              return 6;
   if(StringFind(w, "WEEKEND") == 0)           return 7;
   return 9;
}
string WhyText(int c)
{
   switch(c)
   {
      case 1: return "PROFIT BOOK";
      case 2: return "ATKA BASKET NIKALA";
      case 3: return "DAILY LOSS";
      case 4: return "MAX LOSS";
      case 5: return "MANUAL CLOSE ALL";
      case 6: return "NEWS CLOSE";
      case 7: return "WEEKEND CLOSE";
   }
   return "CLOSE";
}

void SaveState()
{
   GVSet("closing",  gClosing ? 1 : 0);
   GVSet("closewhy", WhyCode(gCloseWhy));
   GVSet("closest",  (double)gCloseStart);
   GVSet("closeest", gLastBasket);
   GVSet("closecom", gCloseEntryCom);
   GVSet("trail",  gTrailOn ? 1 : 0);
   GVSet("peak",   gPeak);
   GVSet("worst",  gWorst);
   GVSet("center", gCenter);
   GVSet("placed", gPlaced);
   GVSet("on",     gTradingOn ? 1 : 0);
   GVSet("pause",  (double)gPauseUntil);
}

void LoadState()
{
   gTrailOn   = (GVGet("trail", 0) > 0.5);
   gPeak      = GVGet("peak", 0);
   gWorst     = GVGet("worst", 0);
   gCenter    = GVGet("center", 0);
   gPlaced    = (int)GVGet("placed", 0);
   gTradingOn = (GVGet("on", 1) > 0.5);
   gPauseUntil= (datetime)(long)GVGet("pause", 0);
   gClosing   = (GVGet("closing", 0) > 0.5);
   if(gClosing)
   {
      gCloseWhy      = WhyText((int)GVGet("closewhy", 9)) + " (restart ke baad)";
      gCloseStart    = (datetime)(long)GVGet("closest", 0);
      gLastBasket    = GVGet("closeest", 0);
      gCloseEntryCom = GVGet("closecom", 0);
      if(gCloseStart == 0) gCloseStart = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| TIME (IST)                                                       |
//+------------------------------------------------------------------+
bool IsTester() { return (MQLInfoInteger(MQL_TESTER) != 0); }

long ServerOffset()
{
   long off = (long)TimeTradeServer() - (long)TimeGMT();
   return (long)MathRound(off / 900.0) * 900;   // 15 min me round
}

datetime ServerToIst(datetime t) { return (datetime)((long)t - ServerOffset() + 19800); }

// aaj IST raat 12 baje ka server time
datetime IstDayStartServer()
{
   long ist    = (long)TimeTradeServer() - ServerOffset() + 19800;
   long istMid = ist - (ist % 86400);
   return (datetime)(istMid - 19800 + ServerOffset());
}

void UpdateDay()
{
   datetime ds = IstDayStartServer();
   if(ds == gDayStart) return;
   bool first = (gDayStart == 0);
   gDayStart  = ds;
   gTodayCalc = 0;
   if(first)
   {
      // EA restart: aaj loss limit lag chuki thi to yaad rakho
      gLossHit = (MathAbs(GVGet("lossday", 0) - (double)ds) < 1);
   }
   else
   {
      gCycles = 0;
      if(gTargetHit || gLossHit) SetMsg("Naya din (IST) - daily target / loss reset, trading dobara shuru");
      gTargetHit = false;
      gLossHit   = false;
      GVSet("lossday", 0);
   }
}

bool IsWeekendIst()
{
   if(!InpWeekendStop) return false;
   datetime ist = ServerToIst(TimeTradeServer());
   MqlDateTime d;
   TimeToStruct(ist, d);
   int now   = d.day_of_week * 1440 + d.hour * 60 + d.min;
   int stop  = (int)InpWkStopDay  * 1440 + MathMax(0, MathMin(23, InpWkStopHour))  * 60;
   int start = (int)InpWkStartDay * 1440 + MathMax(0, MathMin(23, InpWkStartHour)) * 60;
   if(stop == start) return false;
   if(stop < start) return (now >= stop && now < start);
   return (now >= stop || now < start);   // Shukra -> Somvar (hafta ghoom ke)
}

//+------------------------------------------------------------------+
//| MOBILE ALERT                                                     |
//+------------------------------------------------------------------+
void Notify(string m, bool allowed)
{
   if(!InpPush || !allowed || IsTester()) return;
   if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) return;
   string txt = EA_NAME + " " + _Symbol + ": " + CurFix(m);
   if(StringLen(txt) > 255) txt = StringSubstr(txt, 0, 255);
   if(!SendNotification(txt))
      Print(EA_NAME, " | push alert nahi gaya, error ", GetLastError());
}

//+------------------------------------------------------------------+
//| NEWS (MT5 economic calendar)                                     |
//+------------------------------------------------------------------+
void LoadNews()
{
   ArrayResize(gNewsT, 0);
   ArrayResize(gNewsN, 0);
   datetime now  = TimeTradeServer();
   datetime from = now - 6 * 3600;
   datetime to   = now + 36 * 3600;
   string cur[];
   int nc = StringSplit(InpNewsCurrencies, ',', cur);
   for(int c = 0; c < nc; c++)
   {
      string cc = cur[c];
      StringTrimLeft(cc);
      StringTrimRight(cc);
      StringToUpper(cc);
      if(cc == "") continue;
      MqlCalendarValue v[];
      int n = CalendarValueHistory(v, from, to, NULL, cc);
      for(int i = 0; i < n; i++)
      {
         MqlCalendarEvent ev;
         if(!CalendarEventById(v[i].event_id, ev)) continue;
         bool ok = (ev.importance == CALENDAR_IMPORTANCE_HIGH) ||
                   (InpNewsMedium && ev.importance == CALENDAR_IMPORTANCE_MODERATE);
         if(!ok) continue;
         int k = ArraySize(gNewsT);
         ArrayResize(gNewsT, k + 1);
         ArrayResize(gNewsN, k + 1);
         gNewsT[k] = v[i].time;
         gNewsN[k] = cc + " " + ev.name;
      }
   }
   gNewsLoaded = TimeLocal();
}

void UpdateNews()
{
   gNewsNow  = "";
   gNewsNext = "";
   if(!InpNewsFilter || IsTester()) return;
   if(gNewsLoaded == 0 || TimeLocal() - gNewsLoaded > 600) LoadNews();

   datetime now = TimeTradeServer();
   long bef = (long)MathMax(0, InpNewsBefore) * 60;
   long aft = (long)MathMax(0, InpNewsAfter)  * 60;
   datetime best = 0;
   for(int i = 0; i < ArraySize(gNewsT); i++)
   {
      long t = (long)gNewsT[i];
      if((long)now >= t - bef && (long)now <= t + aft && gNewsNow == "")
         gNewsNow = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES);
      if(t > (long)now && (best == 0 || gNewsT[i] < best))
      {
         best = gNewsT[i];
         gNewsNext = gNewsN[i] + " " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES);
      }
   }
}

//+------------------------------------------------------------------+
//| COMMISSION (position ki entry deal se)                           |
//+------------------------------------------------------------------+
double EntryCommission(ulong posTicket)
{
   int n = ArraySize(gComTk);
   for(int i = 0; i < n; i++)
      if(gComTk[i] == posTicket) return gComVal[i];

   double c = 0;
   bool found = false;
   if(HistorySelectByPosition(posTicket))
   {
      int d = HistoryDealsTotal();
      for(int j = 0; j < d; j++)
      {
         ulong dt = HistoryDealGetTicket(j);
         if(dt == 0) continue;
         if(HistoryDealGetInteger(dt, DEAL_ENTRY) == DEAL_ENTRY_IN)
         {
            c += HistoryDealGetDouble(dt, DEAL_COMMISSION) + HistoryDealGetDouble(dt, DEAL_FEE);
            found = true;
         }
      }
   }
   if(!found) return 0;   // deal abhi history me nahi aayi - agle tick par dobara
   ArrayResize(gComTk, n + 1);
   ArrayResize(gComVal, n + 1);
   gComTk[n]  = posTicket;
   gComVal[n] = c;
   return c;
}

void ClearComCache()
{
   ArrayResize(gComTk, 0);
   ArrayResize(gComVal, 0);
}

//+------------------------------------------------------------------+
//| STATE                                                            |
//+------------------------------------------------------------------+
void UpdateState()
{
   gBuys = 0; gSells = 0; gPendB = 0; gPendS = 0;
   gLotB = 0; gLotS = 0; gNet = 0;
   gFirstOpen = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
      datetime pt = (datetime)PositionGetInteger(POSITION_TIME);
      if(gFirstOpen == 0 || pt < gFirstOpen) gFirstOpen = pt;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { gBuys++; gLotB += v; }
      else                                                       { gSells++; gLotS += v; }
      gNet += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(InpCountCommission) gNet += EntryCommission(t) * 2.0;   // entry + exit (andaza)
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY_STOP)  gPendB++;
      if(ot == ORDER_TYPE_SELL_STOP) gPendS++;
   }
}

void CalcToday()
{
   if(gTodayCalc != 0 && TimeCurrent() - gTodayCalc < 5) return;
   gTodayCalc = TimeCurrent();
   datetime from = gDayStart;
   if(from == 0) from = IstDayStartServer();
   gToday = 0;
   if(!HistorySelect(from, TimeCurrent() + 3600)) return;
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      gToday += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
              + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
   }

   bool hit = (InpDailyTarget > 0 && gToday >= InpDailyTarget);
   if(hit && !gTargetHit)
   {
      SetMsg(StringFormat("DAILY TARGET poora: $%.2f / $%.2f - aaj naya grid nahi", gToday, InpDailyTarget));
      Notify(StringFormat("DAILY TARGET poora +$%.2f - aaj trading band", gToday), InpPushRisk);
   }
   gTargetHit = hit;

   if(InpDailyLoss > 0 && gToday <= -InpDailyLoss && !gLossHit) SetLossHit();
}

void SetLossHit()
{
   gLossHit = true;
   GVSet("lossday", (double)gDayStart);
   SetMsg(StringFormat("DAILY LOSS limit ($%.2f) - aaj trading band, kal IST 12 baje se", InpDailyLoss));
   Notify(StringFormat("DAILY LOSS limit $%.2f lagi - sab band, kal IST 12 baje se", InpDailyLoss), InpPushRisk);
}

//+------------------------------------------------------------------+
//| GRID                                                             |
//+------------------------------------------------------------------+
bool SendStop(bool isBuy, double lot, double price, string cmt)
{
   ENUM_ORDER_TYPE_TIME tt = OrderTimeType();
   for(int attempt = 0; attempt < 2; attempt++)
   {
      bool ok = isBuy ? trade.BuyStop(lot, price, _Symbol, 0, 0, tt, 0, cmt)
                      : trade.SellStop(lot, price, _Symbol, 0, 0, tt, 0, cmt);
      uint rc = trade.ResultRetcode();
      if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED)) return true;
      if(rc != TRADE_RETCODE_REQUOTE && rc != TRADE_RETCODE_PRICE_CHANGED &&
         rc != TRADE_RETCODE_TIMEOUT && rc != TRADE_RETCODE_CONNECTION) break;
      Sleep(200);
   }
   Print(EA_NAME, " | pending fail ", cmt, " @", DoubleToString(price, _Digits),
         " rc=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   return false;
}

void PlaceGrid()
{
   if(InpGap <= 0 || InpLevels <= 0) { SetMsg("Gap / Levels galat hai"); return; }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) return;

   gCenter = NormP((bid + ask) / 2.0);
   gPlaced = 0;
   int skipped = 0;
   double sd = StopsDist();

   // beech se bahar ki taraf: B1,S1,B2,S2... taaki pass wale levels pehle lagein
   for(int lvl = 1; lvl <= InpLevels; lvl++)
   {
      double lot = LevelLot(lvl);
      if(lot <= 0) { skipped += 2; continue; }

      double bp = NormP(gCenter + InpGap * lvl);
      double sp = NormP(gCenter - InpGap * lvl);
      string lv = StringFormat("%02d", lvl);

      ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(bp > ask + sd) { if(SendStop(true,  lot, bp, CMT_TAG + " B" + lv)) gPlaced++; else skipped++; }
      else skipped++;
      if(sp < bid - sd) { if(SendStop(false, lot, sp, CMT_TAG + " S" + lv)) gPlaced++; else skipped++; }
      else skipped++;
   }

   gTrailOn = false;
   gPeak = 0;
   gWorst = 0;
   gBoxWait = false;
   ClearComCache();
   SaveState();
   SetMsg(StringFormat("Naya grid @ %s | gap %.2f price | %d pending lage%s",
          DoubleToString(gCenter, _Digits), InpGap, gPlaced,
          skipped > 0 ? " | " + IntegerToString(skipped) + " skip" : ""));
}

void DeletePendings()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      trade.OrderDelete(t);
   }
}

// positions pehle (profit lock), phir pendings. Async = sab ek saath jaate hain.
bool CloseByAllowed()
{
   if(!InpUseCloseBy) return false;
   long om = SymbolInfoInteger(_Symbol, SYMBOL_ORDER_MODE);
   return ((om & SYMBOL_ORDER_CLOSEBY) != 0);
}

// SMART CLOSE:
//  1) buy aur sell ke lot barabar nahi -> sirf EXTRA lot turant band.
//     Iske baad basket ka P/L price hilne se nahi badalta (lock).
//  2) lot barabar -> buy-sell jodi CLOSE BY se band (ya market se).
void SendCloseAll()
{
   if(gLastCloseSend != 0 && GetTickCount() - gLastCloseSend < 1000) return;
   gLastCloseSend = GetTickCount();
   gClosePass++;
   UpdateState();

   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   double half   = step * 0.5;
   bool   bigBuy = (gLotB > gLotS);
   double need   = MathAbs(gLotB - gLotS);

   trade.SetAsyncMode(true);

   if(need >= half)
   {
      //--- 1) extra lot band (bade side ki trades)
      for(int i = PositionsTotal() - 1; i >= 0 && need >= half; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !MyPos()) continue;
         bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
         if(isBuy != bigBuy) continue;
         double v = PositionGetDouble(POSITION_VOLUME);
         if(v <= need + half)
         {
            trade.PositionClose(t, (ulong)InpSlippage);
            need -= v;
         }
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
      //--- 2) buy = sell lot: jodi band
      ulong bT[]; ulong sT[];
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !MyPos()) continue;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         { int k = ArraySize(bT); ArrayResize(bT, k + 1); bT[k] = t; }
         else
         { int k = ArraySize(sT); ArrayResize(sT, k + 1); sT[k] = t; }
      }
      int nb = ArraySize(bT), ns = ArraySize(sT);
      if(CloseByAllowed() && nb > 0 && ns > 0 && gClosePass <= 5)
      {
         int np = MathMin(nb, ns);
         for(int j = 0; j < np; j++) trade.PositionCloseBy(bT[j], sT[j]);
         // bachi hui (jodi nahi mili) agle round me
      }
      // 5 round me Close By se poora na hua -> seedha market close
      else
      {
         for(int j = 0; j < nb; j++) trade.PositionClose(bT[j], (ulong)InpSlippage);
         for(int j = 0; j < ns; j++) trade.PositionClose(sT[j], (ulong)InpSlippage);
      }
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      trade.OrderDelete(t);
   }
   trade.SetAsyncMode(false);
}

// basket band hone ke baad history se asli profit
double RealizedSince(datetime from)
{
   double r = 0;
   if(!HistorySelect(from - 60, TimeCurrent() + 60)) return 0;
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from - 2) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_OUT_BY && en != DEAL_ENTRY_INOUT) continue;
      r += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP)
         + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
   }
   return r;
}

void StartClose(string why)
{
   if(gClosing) return;
   gClosing = true;
   gCloseWhy = why;
   gLastBasket = gNet;
   gLastCloseSend = 0;
   gCloseStart = TimeCurrent();
   gCloseEntryCom = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      gCloseEntryCom += EntryCommission(t);
   }
   gClosePass = 0;
   SaveState();
   GlobalVariablesFlush();   // turant disk par - restart ho to bhi yaad rahe
   SetMsg(StringFormat("%s | net $%.2f | peak $%.2f | %d trades | buy %.2f / sell %.2f lot",
          why, gNet, gPeak, gBuys + gSells, gLotB, gLotS));
   SendCloseAll();
}

//+------------------------------------------------------------------+
//| TRAILING doori                                                   |
//+------------------------------------------------------------------+
double MoneyPerPrice()   // 1 lot par gold price $1 chale to kitna $ (gold = ~100)
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0) return 100.0;
   return tv / ts;
}

double TrailDistMoney()
{
   if(InpTrailMode == TRAIL_FIXED) return MathMax(0.01, InpTrailDist);
   double netLot = MathAbs(gLotB - gLotS);
   double d = InpTrailPriceDist * netLot * MoneyPerPrice();
   return MathMax(MathMax(0.01, InpTrailDist), d);
}

double NetLot() { return MathAbs(gLotB - gLotS); }

// kam se kam lock + slippage buffer (jitna lot ek taraf khula, utna buffer)
double EffLock()
{
   return InpMinLock + MathMax(0.0, InpSlipBuffer) * NetLot() * MoneyPerPrice();
}

double TrailFloor()
{
   double lk = EffLock();
   if(InpTrailMode == TRAIL_PERCENT)
      return MathMax(lk, gPeak * MathMax(0.0, MathMin(100.0, InpTrailKeepPct)) / 100.0);
   return MathMax(lk, gPeak - TrailDistMoney());
}

//+------------------------------------------------------------------+
//| DABBA FILTER - pichhle BOX_BARS candles (chalu samet) ka range   |
//+------------------------------------------------------------------+
double BoxRange()
{
   double h[], l[];
   if(CopyHigh(_Symbol, BOX_TF, 0, BOX_BARS, h) < BOX_BARS) return -1;
   if(CopyLow (_Symbol, BOX_TF, 0, BOX_BARS, l) < BOX_BARS) return -1;
   double hh = h[ArrayMaximum(h)];
   double ll = l[ArrayMinimum(l)];
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid > hh) hh = bid;   // abhi ka price bhi gino
   if(bid > 0 && bid < ll) ll = bid;
   return hh - ll;
}

//+------------------------------------------------------------------+
//| MAIN LOGIC                                                       |
//+------------------------------------------------------------------+
void Engine()
{
   UpdateDay();
   UpdateState();
   UpdateNews();
   CalcToday();
   int open = gBuys + gSells;
   int pend = gPendB + gPendS;
   bool news = (gNewsNow != "");
   gWeekend = IsWeekendIst();

   if(news && !gNewsPrev) Notify("NEWS - trading ruka: " + gNewsNow + " IST", InpPushRisk);
   gNewsPrev = news;
   if(gWeekend != gWeekendPrev)
   {
      SetMsg(gWeekend ? "Weekend stop shuru - naya grid nahi" : "Weekend khatam - trading chalu");
      Notify(gWeekend ? "Weekend stop shuru - naya grid nahi" : "Weekend khatam - trading chalu", InpPushRisk);
      gWeekendPrev = gWeekend;
   }

   //--- 1) band karna chal raha hai
   if(gClosing)
   {
      if(open == 0 && pend == 0)
      {
         gClosing = false;
         gLastClose = TimeCurrent();
         gCycles++;
         gTrailOn = false; gPeak = 0; gWorst = 0; gPlaced = 0;
         gStuck = false; gStuckPrev = false;
         ClearComCache();
         gTodayCalc = 0;
         CalcToday();
         SaveState();
         GlobalVariablesFlush();
         double est  = gLastBasket;
         double real = RealizedSince(gCloseStart) + gCloseEntryCom;
         gLastBasket = real;
         SetMsg(StringFormat("Basket band (%s) | andaza $%.2f | ASLI $%.2f | slippage $%.2f",
                gCloseWhy, est, real, real - est));
         bool risk = (gCloseWhy != "PROFIT BOOK");
         Notify(StringFormat("%s %s$%.2f (andaza %.2f) | aaj %s$%.2f", gCloseWhy, real >= 0 ? "+" : "-", MathAbs(real), est,
                gToday >= 0 ? "+" : "-", MathAbs(gToday)), risk ? (InpPushRisk || InpPushBasket) : InpPushBasket);
      }
      else SendCloseAll();
      return;
   }

   //--- 2) trades khule hain -> basket trailing
   if(open > 0)
   {
      // daily loss: aaj ka band + khula basket
      if(InpDailyLoss > 0 && gToday + gNet <= -InpDailyLoss)
      {
         if(!gLossHit) SetLossHit();
         StartClose("DAILY LOSS");
         return;
      }
      if(gLossHit)   // limit pehle lag chuki (jaise restart) -> band karo
      {
         StartClose("DAILY LOSS (pehle se)");
         return;
      }

      // news aa rahi hai
      if(news && InpNewsBasket == NEWS_CLOSE_ALL)
      {
         StartClose("NEWS CLOSE (" + gNewsNow + ")");
         return;
      }
      if(gWeekend && InpWkCloseAll)
      {
         StartClose("WEEKEND CLOSE");
         return;
      }
      if(gWeekend && pend > 0)
      {
         DeletePendings();
         SetMsg("Weekend: pending hataye, khula basket trailing se band hoga");
      }
      if(news && InpNewsBasket == NEWS_DEL_PEND && pend > 0)
      {
         DeletePendings();
         SetMsg("News: pending hataye, khule trades trailing se band honge (" + gNewsNow + ")");
      }

      if(gNet < gWorst) gWorst = gNet;
      if(gWorst < gWorstEver) gWorstEver = gWorst;

      // safety loss
      if(InpMaxBasketLoss > 0 && gNet <= -InpMaxBasketLoss)
      {
         gPauseUntil = (datetime)((long)TimeCurrent() + (long)MathMax(0, InpPauseAfterLossMin) * 60);
         StartClose("MAX LOSS");
         SaveState();
         return;
      }

      // atka basket
      gStuck = false;
      if(InpRescueOn && !gTrailOn)
      {
         bool byTime   = (InpRescueHours > 0 && gFirstOpen > 0 &&
                          (double)(TimeCurrent() - gFirstOpen) >= InpRescueHours * 3600.0);
         bool byTrades = (InpRescueTrades > 0 && open >= InpRescueTrades);
         gStuck = (byTime || byTrades);
         if(gStuck && !gStuckPrev)
         {
            string why = byTime ? DoubleToString(InpRescueHours, 1) + " ghante" : IntegerToString(open) + " trades";
            SetMsg("ATKA BASKET (" + why + ") - ab target $" + DoubleToString(InpRescueTarget, 2));
            Notify("ATKA BASKET (" + why + ") - target ab $" + DoubleToString(InpRescueTarget, 2) +
                   " | abhi net " + Money(gNet), InpPushRisk);
         }
         gStuckPrev = gStuck;
         if(gStuck && gNet >= InpRescueTarget)
         {
            StartClose("ATKA BASKET NIKALA");
            return;
         }
      }

      double startP = MathMax(InpTrailStart, EffLock());
      if(!gTrailOn && gNet >= startP)
      {
         gTrailOn = true;
         gPeak = gNet;
         SetMsg(StringFormat("Trailing shuru @ $%.2f", gNet));
         Notify(StringFormat("Trailing shuru @ +$%.2f", gNet), InpPushTrail);
         if(InpDeletePendOnTrail) DeletePendings();
         SaveState();
         return;
      }

      if(gTrailOn)
      {
         if(gNet > gPeak) { gPeak = gNet; GVSet("peak", gPeak); }
         double floorP = TrailFloor();
         if(gNet <= floorP)
         {
            StartClose("PROFIT BOOK");
            return;
         }
      }
      return;
   }

   //--- 3) koi trade khula nahi
   if(pend > 0)
   {
      // news / daily target: abhi tak koi trade fill nahi -> pending hata do
      if((news && InpNewsBasket != NEWS_KEEP) || gTargetHit || gLossHit || gWeekend)
      {
         DeletePendings();
         gPlaced = 0;
         SaveState();
         SetMsg(gLossHit ? "Daily loss limit - pending hataye" :
                gTargetHit ? "Daily target poora - pending hataye" :
                gWeekend ? "Weekend stop - pending hataye" : "News: pending hataye (" + gNewsNow + ")");
         return;
      }
      // grid ka koi level fill hua tha aur trade bahar band ho gaya (manual / SL) -> purana grid hatao
      if(gPlaced > 0 && pend < gPlaced)
      {
         SetMsg("Grid adhoora (trade bahar se band) - naya grid lagega");
         DeletePendings();
         gPlaced = 0;
         SaveState();
      }
      // trailing chal rahi thi par trades khatam -> reset
      if(gTrailOn) { gTrailOn = false; gPeak = 0; SaveState(); }
      return;
   }

   //--- 4) kuch nahi khula -> naya grid
   if(!gTradingOn) return;
   if(gLossHit) return;                        // aaj ka loss limit
   if(gTargetHit) return;                      // aaj ka target poora
   if(news) return;                            // news time - naya grid nahi
   if(gWeekend) return;                        // weekend stop
   if(TimeCurrent() < gPauseUntil) return;
   int waitS = MathMax(InpWaitAfterCloseSec, InpDailyTarget > 0 ? 2 : 0);   // history update hone do
   if(waitS > 0 && TimeCurrent() - gLastClose < waitS) return;
   if(InpMaxSpread > 0 && SpreadNow() > InpMaxSpread) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) return;

   // dabba filter: market chhote range me ghoom raha ho to naya grid nahi
   if(InpBoxFilter)
   {
      gBoxRange = BoxRange();
      bool box = (gBoxRange >= 0 && gBoxRange <= BOX_MAX);
      if(box)
      {
         if(!gBoxWait)
            SetMsg(StringFormat("DABBA: pichhle 2 ghante ka range %.2f (<= %.2f) - naya grid nahi, wait", gBoxRange, BOX_MAX));
         gBoxWait = true;
         return;
      }
      if(gBoxWait)
         SetMsg(StringFormat("Dabba toota: range %.2f - naya grid", gBoxRange));
      gBoxWait = false;
   }

   PlaceGrid();
}

//+------------------------------------------------------------------+
//| PANEL - UI helpers                                               |
//+------------------------------------------------------------------+
int PX(double v) { return (int)MathRound(v * gK); }
int FS(double v) { return (int)MathMax(6.0, MathRound(v * gScale)); }

void ObjBase(string nm, ENUM_OBJECT type)
{
   if(ObjectFind(0, nm) < 0) ObjectCreate(0, nm, type, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nm, OBJPROP_BACK, false);
}

void UiRect(string n, double x, double y, double w, double h, color bg, color br, int bw = 1)
{
   string nm = PFX + n;
   ObjBase(nm, OBJ_RECTANGLE_LABEL);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, MathMax(1, PX(w)));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, MathMax(1, PX(h)));
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, br);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH, bw);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 0);
}

void UiText(string n, double x, double y, string t, color c, double fs,
            string font = "Bahnschrift", ENUM_ANCHOR_POINT a = ANCHOR_LEFT)
{
   string nm = PFX + n;
   ObjBase(nm, OBJ_LABEL);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, a);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetString(0, nm, OBJPROP_FONT, font);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(fs));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 1);
}

void UiBtn(string n, double x, double y, double w, double h, string t,
           color fg, color bg, color br, double fs, string font = "Bahnschrift")
{
   string nm = PFX + n;
   ObjBase(nm, OBJ_BUTTON);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, PX(w));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, PX(h));
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetString(0, nm, OBJPROP_FONT, font);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(fs));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, br);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 10);
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

//--- rows: label (left) + value (right)
#define PW   330.0
#define RH   22.0

void Row(int i, double y0, string key, string label)
{
   double y = y0 + i * RH;
   UiRect("rw" + key, 8, y, PW - 16, RH - 3, (i % 2 == 0 ? CLR_CELL : CLR_BOX), CLR_BOX, 1);
   UiText("lb" + key, 16, y + (RH - 3) / 2.0, label, TXT_DIM, 8.5, "Bahnschrift", ANCHOR_LEFT);
   UiText("vl" + key, PW - 16, y + (RH - 3) / 2.0, "-", TXT_W, 9, "Consolas", ANCHOR_RIGHT);
}

#define Y_ROWS 74.0
#define N_ROWS 16

void BuildPanel()
{
   double H = Y_ROWS + N_ROWS * RH + 84;
   UiRect("bg", 0, 0, PW, H, CLR_BG, NEON_CY, 2);
   UiRect("logo", 8, 7, 26, 26, GOLD_C, GOLD_C, 1);
   UiText("logoB", 21, 20, "$3", C'12,12,12', 9, "Arial Black", ANCHOR_CENTER);
   UiText("title", 42, 13, EA_NAME, TXT_W, 11, "Arial Black", ANCHOR_LEFT);
   UiText("ver", 42, 29, EA_VER + "  |  " + _Symbol + "  |  magic " + IntegerToString(InpMagic) + "  |  " + AccCur(),
          TXT_DIM, 7.5, "Bahnschrift", ANCHOR_LEFT);

   // status strip
   UiRect("st", 8, 42, PW - 16, 26, CLR_BOX, NEON_PU, 1);
   UiText("stT", PW / 2.0, 55, "-", NEON_GR, 10, "Arial Black", ANCHOR_CENTER);

   string cu = " (" + (AccCur() == "" ? "?" : AccCur()) + ")";
   Row(0,  Y_ROWS, "net",   "BASKET NET" + cu);
   Row(1,  Y_ROWS, "trail", "TRAILING");
   Row(2,  Y_ROWS, "lock",  "LOCK (min book)" + cu);
   Row(3,  Y_ROWS, "buy",   "BUY khule / lot");
   Row(4,  Y_ROWS, "sell",  "SELL khule / lot");
   Row(5,  Y_ROWS, "pend",  "PENDING buy / sell");
   Row(6,  Y_ROWS, "grid",  "GRID beech / gap (price)");
   Row(7,  Y_ROWS, "worst", "Is basket ka worst" + cu);
   Row(8,  Y_ROWS, "today", "AAJ profit / target" + cu);
   Row(9,  Y_ROWS, "cyc",   "Aaj basket band");
   Row(10, Y_ROWS, "last",  "Pichhla basket" + cu);
   Row(11, Y_ROWS, "loss",  "DAILY LOSS limit" + cu);
   Row(12, Y_ROWS, "spr",   "SPREAD / max (price)");
   Row(13, Y_ROWS, "news",  "NEWS (IST)");
   Row(14, Y_ROWS, "stuck", "ATKA (time / trades)");
   Row(15, Y_ROWS, "netlot","NET lot (khula risk)");

   double by = Y_ROWS + N_ROWS * RH + 6;
   UiBtn("btnTrade", 8, by, (PW - 24) / 2.0, 30, "TRADING  ON", NEON_GR, C'8,46,30', NEON_GR, 9, "Arial Black");
   UiBtn("btnClose", 16 + (PW - 24) / 2.0, by, (PW - 24) / 2.0, 30, "CLOSE ALL", NEON_RD, C'50,12,22', NEON_RD, 9, "Arial Black");
   UiText("msg", 12, by + 46, "-", TXT_DIM, 7.5, "Bahnschrift", ANCHOR_LEFT);
   PaintTradeBtn();
   ChartRedraw();
}

void UpdatePanel()
{
   CalcToday();
   string st; color sc;
   if(gClosing)                         { st = "BAND HO RAHA HAI...";  sc = NEON_OR; }
   else if(TimeCurrent() < gPauseUntil) { st = "PAUSE (max loss)";     sc = NEON_RD; }
   else if(gBuys + gSells > 0 && gStuck){ st = "ATKA - " + CurLabel() + DoubleToString(InpRescueTarget, 0) + " PAR NIKLEGA"; sc = NEON_OR; }
   else if(gBuys + gSells > 0)          { st = gTrailOn ? "PROFIT TRAILING" : "BASKET CHAL RAHA"; sc = gTrailOn ? NEON_GR : NEON_CY; }
   else if(gLossHit)                    { st = "DAILY LOSS - KAL TAK BAND"; sc = NEON_RD; }
   else if(gTargetHit)                  { st = "DAILY TARGET POORA";   sc = NEON_GR; }
   else if(gWeekend)                    { st = "WEEKEND STOP";         sc = NEON_PU; }
   else if(gNewsNow != "")              { st = "NEWS - TRADING RUKA";  sc = NEON_OR; }
   else if(gPendB + gPendS > 0)         { st = "GRID LAGA - FILL KA WAIT"; sc = NEON_PU; }
   else if(!gTradingOn)                 { st = "TRADING OFF";          sc = NEON_RD; }
   else if(InpMaxSpread > 0 && SpreadNow() > InpMaxSpread) { st = "SPREAD ZYADA - WAIT"; sc = NEON_OR; }
   else if(gBoxWait)                    { st = "DABBA " + DoubleToString(gBoxRange, 2) + " - WAIT"; sc = NEON_OR; }
   else                                 { st = "NAYA GRID LAG RAHA";   sc = NEON_OR; }
   SetT("stT", st, sc);

   SetT("vlnet", Money(gNet), gNet >= 0 ? NEON_GR : NEON_RD);
   string md = (InpTrailMode == TRAIL_LOT ? "LOT" : InpTrailMode == TRAIL_FIXED ? "FIX" : "%");
   if(gTrailOn)
      SetT("vltrail", md + " ON  peak " + DoubleToString(gPeak, 2), NEON_GR);
   else
      SetT("vltrail", md + " OFF (start " + CurLabel() + DoubleToString(MathMax(InpTrailStart, EffLock()), 2) + ")", TXT_DIM);
   double floorP = gTrailOn ? TrailFloor() : EffLock();
   SetT("vllock", DoubleToString(floorP, 2), gTrailOn ? NEON_GR : TXT_W);
   SetT("vlbuy",  IntegerToString(gBuys)  + "  /  " + DoubleToString(gLotB, 2), gBuys  > 0 ? NEON_CY : TXT_W);
   SetT("vlsell", IntegerToString(gSells) + "  /  " + DoubleToString(gLotS, 2), gSells > 0 ? NEON_MG : TXT_W);
   SetT("vlpend", IntegerToString(gPendB) + "  /  " + IntegerToString(gPendS), TXT_W);
   SetT("vlgrid", (gCenter > 0 ? DoubleToString(gCenter, _Digits) : "-") + "  /  " + DoubleToString(InpGap, 2), TXT_W);
   SetT("vlworst", Money(gWorst), gWorst < 0 ? NEON_RD : TXT_W);
   SetT("vltoday", Money(gToday) + (InpDailyTarget > 0 ? "  /  " + DoubleToString(InpDailyTarget, 2) : "  /  OFF"),
        gTargetHit ? NEON_GR : (gToday >= 0 ? TXT_W : NEON_RD));
   if(InpDailyLoss > 0)
   {
      double left = InpDailyLoss + gToday + gNet;   // aur kitna loss jhel sakte
      SetT("vlloss", DoubleToString(InpDailyLoss, 2) + "  (bacha " + DoubleToString(MathMax(0, left), 2) + ")",
           gLossHit ? NEON_RD : (left < InpDailyLoss * 0.3 ? NEON_OR : TXT_W));
   }
   else SetT("vlloss", "OFF", TXT_DIM);

   double spr = SpreadNow();
   bool sprBad = (InpMaxSpread > 0 && spr > InpMaxSpread);
   SetT("vlspr", DoubleToString(spr, 2) + "  /  " + (InpMaxSpread > 0 ? DoubleToString(InpMaxSpread, 2) : "OFF"),
        sprBad ? NEON_RD : TXT_W);

   double nl = NetLot();
   SetT("vlnetlot", nl < 0.005 ? "0.00 (barabar)" :
        DoubleToString(nl, 2) + (gLotB > gLotS ? "  BUY" : "  SELL") + "  (1.00 price = " + DoubleToString(nl * MoneyPerPrice(), 2) + ")",
        nl >= 0.10 ? NEON_OR : TXT_W);

   if(!InpRescueOn) SetT("vlstuck", "OFF", TXT_DIM);
   else
   {
      int mins = (gFirstOpen > 0 && gBuys + gSells > 0) ? (int)((TimeCurrent() - gFirstOpen) / 60) : 0;
      string tx = StringFormat("%dh%02dm/%.0fh  %d/%d", mins / 60, mins % 60, InpRescueHours,
                               gBuys + gSells, InpRescueTrades);
      SetT("vlstuck", gStuck ? "ATKA - " + CurLabel() + DoubleToString(InpRescueTarget, 2) + " par" : tx,
           gStuck ? NEON_OR : TXT_W);
   }

   string nw;
   color  nc = TXT_DIM;
   if(!InpNewsFilter)       nw = "OFF";
   else if(IsTester())      nw = "tester me off";
   else if(gNewsNow != "")  { nw = "RUKA: " + gNewsNow; nc = NEON_OR; }
   else if(gNewsNext != "") nw = "Agli: " + gNewsNext;
   else                     nw = "aaj koi nahi";
   if(StringLen(nw) > 28) nw = StringSubstr(nw, 0, 26) + "..";
   SetT("vlnews", nw, nc);
   SetT("vlcyc",  IntegerToString(gCycles), TXT_W);
   SetT("vllast", Money(gLastBasket), gLastBasket >= 0 ? NEON_GR : NEON_RD);
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
      gTradingOn = !gTradingOn;
      SaveState();
      SetMsg(gTradingOn ? "Trading ON" : "Trading OFF - chal raha basket poora hoga, naya grid nahi");
      PaintTradeBtn();
      UpdatePanel();
      return;
   }
   if(sparam == PFX + "btnClose")
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      UpdateState();
      if(gBuys + gSells + gPendB + gPendS == 0) { SetMsg("Band karne ko kuch nahi"); UpdatePanel(); return; }
      StartClose("MANUAL CLOSE ALL");
      UpdatePanel();
      return;
   }
}

int OnInit()
{
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Alert(EA_NAME, ": ye EA sirf HEDGING account par chalega (buy + sell ek saath)");
      return INIT_FAILED;
   }
   double px = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(px > 0 && InpGap > px * 0.01)
   {
      Alert(EA_NAME, ": gap ", DoubleToString(InpGap, 2), " is symbol (", _Symbol,
            ") ke liye bahut bada hai - ye EA GOLD (XAUUSD) ke liye bana hai");
      return INIT_FAILED;
   }
   if(InpMinLock > InpTrailStart)
      Print(EA_NAME, " | Dhyan: Min Lock trailing start se bada hai - trailing start = ", InpMinLock, " maana jaayega");

   int lim = (int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   if(lim > 0 && lim < InpLevels * 2)
      Print(EA_NAME, " | Dhyan: broker max ", lim, " pending deta hai, grid ko ", InpLevels * 2, " chahiye");

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   gScale = MathMax(0.6, MathMin(2.5, InpPanelScale));
   gK = gScale * (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

   LoadState();
   UpdateState();
   ClearComCache();

   Comment("");
   ChartSetInteger(0, CHART_FOREGROUND, false);
   BuildPanel();
   UpdatePanel();
   EventSetTimer(1);

   UpdateDay();
   CalcToday();
   gWeekendPrev = IsWeekendIst();

   // currency chetavani
   if(AccCur() != "USD")
   {
      string w = "Account currency " + AccCur() + " hai (USD nahi) - saare target / loss / lock " + AccCur() + " me gine jaayenge";
      if(IsCentAccount())
      {
         w += ". CENT account: 3.00 = sirf 3 cent! Target / loss / lock inputs 100 guna karo";
         Alert(EA_NAME, ": ", w);
      }
      Print(EA_NAME, " | DHYAN: ", w);
      gMsg = w;
   }

   // restart se pehle close chal raha tha -> pehle wahi poora
   if(gClosing)
   {
      gLastCloseSend = 0;
      gClosePass = 0;
      string rm = "RESTART: pichla close (" + gCloseWhy + ") adhoora tha - pehle wahi poora kar rahe hain";
      SetMsg(rm);
      Notify(rm, true);
   }
   if(InpPush && !IsTester() && !TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      Print(EA_NAME, " | Mobile alert ke liye: MT5 Tools > Options > Notifications me MetaQuotes ID daalo aur Enable karo");
   Notify(EA_VER + " chalu | gap " + DoubleToString(InpGap, 2) + " price | target $" + DoubleToString(InpDailyTarget, 2), InpPushRisk);
   string cl = CurLabel();
   Print(EA_NAME, " ", EA_VER, " start | ", _Symbol, " | currency ", AccCur(), " | gap ", DoubleToString(InpGap, 2), " price",
         " | daily target ", cl, DoubleToString(InpDailyTarget, 2), " | daily loss ", cl, DoubleToString(InpDailyLoss, 2),
         " | max spread ", DoubleToString(InpMaxSpread, 2), " price | news ", (InpNewsFilter ? "ON" : "OFF"),
         " | levels ", InpLevels, " | trail start ", cl, DoubleToString(InpTrailStart, 2),
         " | min lock ", cl, DoubleToString(InpMinLock, 2), " | trail dist ", cl, DoubleToString(InpTrailDist, 2));
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

void OnTimer()
{
   Engine();
   UpdatePanel();
}
//+------------------------------------------------------------------+
