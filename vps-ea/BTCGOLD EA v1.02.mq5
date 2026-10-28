//+------------------------------------------------------------------+
//|                                          BTCGOLD EA v1.02.mq5    |
//|                     Ankush New Vision - Gold Smart Algo EA       |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.02 (28-Oct-2026) - BTC EA v1.18 ki FINAL Buster trailing,     |
//|   GOLD ke hisaab se (M30 ATR: BTC ~230, Gold ~7.5 => /30)        |
//|  - SL MAX $5 (Buster BTC 150 price => gold ~5)                   |
//|  - Trailing ON default; shuru $1.80, doori $1.60                 |
//|    (Buster BTC 55 / 50 price => gold 1.80 / 1.60)                |
//|  - Breakeven $1.80 par, SL = entry + $0.20                       |
//|  - Profit Lock default OFF (Buster me nahi hai)                  |
//|  - TP MAX $20, DAY LOSS $10, same-disha doori 3.0,               |
//|    ATR threshold 0.0008 (Buster jaisa 'dead market' filter)      |
//|  - Sab $ values 0.01 lot ke hisaab se: lot badhao to inhe bhi     |
//|    utne guna karo (0.10 lot = x10)                               |
//|  - Strategy code same (ZigZag swing scan, 72 ghante, stop orders) |
//| v1.01 (13-Oct-2026) - pending gayab hone ki jaanch / fix         |
//|  - Expiry 72 ghante hi hai; ab broker ki expiry date pehle padhi  |
//|    jaati hai, comment se aayi galat / kati date ignore            |
//|  - Restart pe sirf v1.11/v1.12 wale (bina '|') pending hat-te hain |
//|  - Har hataye gaye pending ka KAARAN Experts log me likha jaata   |
//|    hai (expiry / news park / day loss / mode OFF / restart)       |
//| v1.00 (13-Oct-2026) - GOLD (XAUUSD) ke liye, BTC EA v1.16 se bana |
//|  - Wahi swing scan strategy + neon dashboard                      |
//|  - Gold defaults (0.01 lot): SL $7, TP MIN $3, TP MAX $25,        |
//|    LOCK STEP $2, DAY LOSS $15, Breakeven $2.50 (+$0.30),          |
//|    Trailing doori $4                                              |
//|  - Entry buffer ab $ me (0.50) - XM / Exness dono pe same         |
//|  - Min same-disha doori 2, ATR threshold 0.0005, Magic 111334     |
//|  - Alag settings file, alag panel objects (BTC EA ke saath chale) |
//| Purani history: BTC EA v1.11 - v1.16                             |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property link        "https://github.com/ankushchhajed7-cmd"
#property version     "1.02"
#property description "BTCGOLD EA v1.02 - XAUUSD ZigZag swing EA with neon dashboard"

#include <Trade\Trade.mqh>

#define EA_NAME  "BTCGOLD EA"
#define EA_VER   "v1.02"
#define PFX      "BTCGOLD100_"

//--- neon colours
#define CLR_BG     C'6,10,20'
#define CLR_BOX    C'11,17,31'
#define CLR_CELL   C'15,23,41'
#define CLR_EDIT   C'20,16,44'
#define CLR_LINE   C'30,44,74'
#define NEON_CY    C'0,229,255'
#define NEON_MG    C'255,61,240'
#define NEON_PU    C'150,110,255'
#define NEON_GR    C'57,255,136'
#define NEON_RD    C'255,77,109'
#define NEON_OR    C'255,170,0'
#define BTC_OR     C'255,196,46'
#define TXT_W      C'232,238,255'
#define TXT_DIM    C'125,140,175'

//=== INPUTS ========================================================
input group "=== EA Identification ==="
input long            InpMagic          = 111334;          // Magic Number
input ENUM_TIMEFRAMES InpTF             = PERIOD_CURRENT;  // Signal timeframe (M30 chart pe lagao)

input group "=== Panel defaults (panel se bhi badal sakte ho) ==="
input double InpLot            = 0.01;   // LOT
input double InpTPMin          = 1.80;   // TP MIN $ (yahan se trailing shuru) - Buster jaisa, 0.01 lot
input double InpTPMax          = 20.00;   // TP MAX $ (hard take profit)
input double InpSLMax          = 5.00;   // SL MAX $ (har trade ka max loss)
input double InpLockStep       = 1.60;   // LOCK STEP $ (har itne $ par lock upar)
input double InpKeepPct        = 60;     // KEEP % (profit ka kitna % pakka)
input int    InpNewsMin        = 30;     // NEWS MIN (news ke pehle / baad minute)
input double InpDayLoss        = 10.00;   // DAY LOSS $ (0 = off)
input bool   InpBreakeven      = true;   // Breakeven ON/OFF
input bool   InpProfitLock     = false;  // Profit lock ON/OFF (Buster me nahi; ON karoge to jaldi band hoga)
input bool   InpTrailing       = true;   // Trailing ON/OFF (Buster jaisa ON)
input bool   InpNewsFilter     = true;   // News filter ON/OFF
input bool   InpTrendMode      = true;   // TREND mode ON/OFF
input bool   InpRangeMode      = false;  // RANGE mode ON/OFF
input bool   InpUseMarket      = false;  // MARKET entry ON/OFF
input bool   InpUseLimit       = true;   // LIMIT entry ON/OFF (RANGE mode)
input bool   InpUseStop        = true;   // STOP entry ON/OFF (TREND mode)

input group "=== Breakeven / Trailing detail ==="
input double InpBETrigger      = 1.80;   // Breakeven kab: profit $ itna ho (0.01 lot)
input double InpBEPlus         = 0.20;   // Breakeven par entry se upar $ (0.01 lot)
input double InpTrailDist      = 1.60;   // Trailing doori $ (price se, 0.01 lot) - Buster ~50 BTC => 1.60 gold

input group "=== Strategy (ZigZag swing) ==="
input int    InpSwingDepth     = 5;      // Swing depth (bars har taraf)
input int    InpSwingLookback  = 300;    // Kitne bars me swing dhoondhe
input int    InpMaxSwingAgeHours = 72;   // Kitne ghante purane swing tak order (Buster = 72)
input double InpEntryBuffer    = 0.50;   // Swing level se entry buffer ($ price doori)
input bool   InpUseEMADir      = false;  // TREND: EMA ki disha me hi trade
input int    InpEMAPeriod      = 50;     // EMA period
input int    InpADXPeriod      = 14;     // ADX period
input double InpADXThreshold   = 20.0;   // ADX >= isse = TREND, kam = RANGE
input double InpATRThreshold   = 0.0008;  // ATR/Price isse kam = market dead, no trade

input group "=== Position Management ==="
input int    InpMaxOpenTrades  = 0;      // Ek saath max KHULE trades (0 = off, sirf naye pending rokta hai)
input int    InpMinGapMinutes  = 0;      // Pichhle trade ke baad kitne minute ruko (0 = off)
input int    InpMaxPositions   = 4;      // Max trades (khule + pending)
input int    InpMaxPendingSide = 2;      // Max pending har side (buy / sell)
input int    InpMinCandleGap   = 1;      // Market entries ke beech min candles
input double InpMinDistSameDir = 3.0;    // Same disha entries ke beech min price doori
input int    InpPendingExpiryHours = 72; // Pending kitne ghante baad hate (Buster = 72)
input bool   InpForceMinVolume = true;   // Lot kam ho to broker ka min lot lo
input double InpMinBalance     = 1.0;    // Is balance se kam = trade band
input int    InpSlippage       = 1000;   // Slippage (points)

input group "=== Day loss / News / Weekend ==="
input bool   InpCloseAllOnDayLoss   = true;   // Day loss poora = sab trades band
input bool   InpDeletePendingOnNews = true;   // News time pe pending hatao
input string InpNewsCurrencies      = "USD";  // News currencies (comma se)
input bool   InpDisableWeekend      = false;  // Weekend trade band

input group "=== Panel ==="
input double InpPanelScale     = 1.40;   // Panel size (phone ke liye 1.3 - 1.6)
input int    InpPanelX         = 10;     // Panel X
input int    InpPanelY         = 25;     // Panel Y
input bool   InpResetSaved     = false;  // true = saved panel settings bhool jao

//=== SETTINGS / TOGGLES ============================================
#define ST_COUNT   8
#define ST_LOT     0
#define ST_TPMIN   1
#define ST_TPMAX   2
#define ST_SLMAX   3
#define ST_STEP    4
#define ST_KEEP    5
#define ST_NEWS    6
#define ST_DAYLOSS 7
string ST_NAME[ST_COUNT] = {"LOT","TP MIN $","TP MAX $","SL MAX $","LOCK STEP $","KEEP %","NEWS MIN","DAY LOSS $"};
double ST_MINV[ST_COUNT] = {0.01, 0.05, 0.10, 0.10, 0.05, 10, 0,   0};
double ST_MAXV[ST_COUNT] = {100,  1000, 10000,10000,1000, 95, 240, 100000};
int    ST_DIG[ST_COUNT]  = {2,    2,    2,    2,    2,    0,  0,   2};
double S[ST_COUNT];

#define TG_COUNT 9
#define TG_BE    0
#define TG_LOCK  1
#define TG_TRAIL 2
#define TG_NEWS  3
#define TG_TREND 4
#define TG_RANGE 5
#define TG_MKT   6
#define TG_LIM   7
#define TG_STP   8
string TG_NAME[TG_COUNT] = {"BREAKEVEN","PROFIT LOCK","TRAILING","NEWS FILTER","TREND","RANGE","MARKET","LIMIT","STOP"};
bool   TG[TG_COUNT];

bool   gTradingOn = true;
bool   gMin       = false;
bool   gSetOpen   = true;

//=== GLOBALS =======================================================
CTrade   trade;
int      hADX = INVALID_HANDLE, hATR = INVALID_HANDLE, hEMA = INVALID_HANDLE;
double   gK = 1.0;
double   gScale = 1.0;
string   gCfgFile = "";
datetime gLastBar = 0;
datetime gLastMktEntry = 0;
bool     gForceCheck = true;

int      gState = 0;           // 0 ACTIVE, 1 BAND, 2 NEWS
string   gReason = "";
bool     gDayLossHit = false;
double   gTodayPL = 0, gTodayClosed = 0, gFloating = 0, gLocked = 0;
int      gWins = 0, gLosses = 0, gBuys = 0, gSells = 0, gPendStop = 0, gPendLimit = 0;
double   gADX = 0, gATR = 0, gEMA = 0;
bool     gDead = false, gIsTrend = false;
string   gRegime = "-";
string   gMsg = "";
datetime gMsgTime = 0;
uint     gLastHist = 0;
datetime gLastEntry = 0;      // aakhri trade kab khula
bool     gEntryBlock = false; // abhi naya trade nahi (trade khula / gap)
string   gUsedPiv[];          // jin swings pe order lag chuka (H<time> / L<time>)
string   gScanNote = "";
datetime gScanPrinted = 0;
string   gParkPiv[];
int      gParkType[];
double   gParkPrice[];
datetime gParkExp[];
string   gParkTag[];

datetime gNewsT[];
string   gNewsN[];
datetime gNewsLoaded = 0;
string   gNewsNow = "";

//+------------------------------------------------------------------+
//| Small helpers                                                    |
//+------------------------------------------------------------------+
bool IsTester() { return (MQLInfoInteger(MQL_TESTER) != 0); }
bool IsReal()   { return (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL); }

void SetMsg(string m)
{
   gMsg = m;
   gMsgTime = TimeLocal();
   Print(EA_NAME, " ", EA_VER, " | ", m);
}

string SignMoney(double v)
{
   return (v >= 0 ? "+" : "-") + DoubleToString(MathAbs(v), 2);
}

string Fmt(int i) { return DoubleToString(S[i], ST_DIG[i]); }

double Buf(int h, int buffer, int shift)
{
   double b[];
   if(h == INVALID_HANDLE) return 0;
   if(CopyBuffer(h, buffer, shift, 1, b) != 1) return 0;
   return b[0];
}

double TickSize()
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) ts = _Point;
   return ts;
}

double NormP(double p)
{
   double ts = TickSize();
   return NormalizeDouble(MathRound(p / ts) * ts, _Digits);
}

// $ ko price doori me badlo (diye gaye lot par)
double MoneyToDist(double money, double lot)
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = TickSize();
   if(tv <= 0 || lot <= 0) return 0;
   return money / (lot * tv / ts);
}

// price doori ko $ me badlo
double DistToMoney(double dist, double lot)
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = TickSize();
   if(tv <= 0) return 0;
   return dist / ts * tv * lot;
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

//+------------------------------------------------------------------+
//| IST time helpers                                                 |
//+------------------------------------------------------------------+
datetime IstNow() { return (datetime)((long)TimeGMT() + 19800); }

long ServerOffset() { return (long)TimeTradeServer() - (long)TimeGMT(); }

// aaj IST raat 12 baje ka server time
datetime ServerIstMidnight()
{
   long ist    = (long)IstNow();
   long istMid = ist - (ist % 86400);
   return (datetime)(istMid - 19800 + ServerOffset());
}

datetime ServerToIst(datetime t) { return (datetime)((long)t - ServerOffset() + 19800); }

string IstDate(datetime t)
{
   MqlDateTime d;
   TimeToStruct(t, d);
   string m[12] = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
   return StringFormat("%02d %s %04d  IST", d.day, m[d.mon - 1], d.year);
}

//+------------------------------------------------------------------+
//| Settings: defaults, fingerprint, save / load                     |
//+------------------------------------------------------------------+
void LoadDefaults()
{
   S[ST_LOT]     = InpLot;
   S[ST_TPMIN]   = InpTPMin;
   S[ST_TPMAX]   = InpTPMax;
   S[ST_SLMAX]   = InpSLMax;
   S[ST_STEP]    = InpLockStep;
   S[ST_KEEP]    = InpKeepPct;
   S[ST_NEWS]    = InpNewsMin;
   S[ST_DAYLOSS] = InpDayLoss;
   TG[TG_BE]     = InpBreakeven;
   TG[TG_LOCK]   = InpProfitLock;
   TG[TG_TRAIL]  = InpTrailing;
   TG[TG_NEWS]   = InpNewsFilter;
   TG[TG_TREND]  = InpTrendMode;
   TG[TG_RANGE]  = InpRangeMode;
   TG[TG_MKT]    = InpUseMarket;
   TG[TG_LIM]    = InpUseLimit;
   TG[TG_STP]    = InpUseStop;
}

// inputs ka "thumb print" - agar aap inputs badlo to panel inputs hi lega
string Fingerprint()
{
   string s = DoubleToString(InpLot, 2) + "|" + DoubleToString(InpTPMin, 2) + "|" +
              DoubleToString(InpTPMax, 2) + "|" + DoubleToString(InpSLMax, 2) + "|" +
              DoubleToString(InpLockStep, 2) + "|" + DoubleToString(InpKeepPct, 1) + "|" +
              IntegerToString(InpNewsMin) + "|" + DoubleToString(InpDayLoss, 2) + "|";
   s += (InpBreakeven ? "1" : "0");
   s += (InpProfitLock ? "1" : "0");
   s += (InpTrailing ? "1" : "0");
   s += (InpNewsFilter ? "1" : "0");
   s += (InpTrendMode ? "1" : "0");
   s += (InpRangeMode ? "1" : "0");
   s += (InpUseMarket ? "1" : "0");
   s += (InpUseLimit ? "1" : "0");
   s += (InpUseStop ? "1" : "0");
   return s;
}

void SaveCfg()
{
   if(IsTester()) return;
   int h = FileOpen(gCfgFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
   {
      Print(EA_NAME, " settings save fail, error ", GetLastError());
      return;
   }
   FileWriteString(h, "FP=" + Fingerprint() + "\r\n");
   for(int i = 0; i < ST_COUNT; i++)
      FileWriteString(h, "S" + IntegerToString(i) + "=" + DoubleToString(S[i], 4) + "\r\n");
   for(int i = 0; i < TG_COUNT; i++)
      FileWriteString(h, "T" + IntegerToString(i) + "=" + (TG[i] ? "1" : "0") + "\r\n");
   FileWriteString(h, "TRADING=" + (gTradingOn ? "1" : "0") + "\r\n");
   FileWriteString(h, "MIN=" + (gMin ? "1" : "0") + "\r\n");
   FileWriteString(h, "SET=" + (gSetOpen ? "1" : "0") + "\r\n");
   FileClose(h);
}

void LoadCfg()
{
   if(IsTester()) return;
   if(InpResetSaved || !FileIsExist(gCfgFile)) { SaveCfg(); return; }
   int h = FileOpen(gCfgFile, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return;

   double tS[ST_COUNT];
   bool   tT[TG_COUNT];
   ArrayCopy(tS, S);
   ArrayCopy(tT, TG);
   bool   tTr = gTradingOn, tMn = gMin, tSt = gSetOpen;
   string fp = "";

   while(!FileIsEnding(h))
   {
      string line = FileReadString(h);
      int p = StringFind(line, "=");
      if(p < 1) continue;
      string k = StringSubstr(line, 0, p);
      string v = StringSubstr(line, p + 1);
      StringTrimRight(v);
      if(k == "FP")           fp  = v;
      else if(k == "TRADING") tTr = (v == "1");
      else if(k == "MIN")     tMn = (v == "1");
      else if(k == "SET")     tSt = (v == "1");
      else if(StringLen(k) == 2 && StringSubstr(k, 0, 1) == "S")
      {
         int i = (int)StringToInteger(StringSubstr(k, 1));
         if(i >= 0 && i < ST_COUNT) tS[i] = StringToDouble(v);
      }
      else if(StringLen(k) == 2 && StringSubstr(k, 0, 1) == "T")
      {
         int i = (int)StringToInteger(StringSubstr(k, 1));
         if(i >= 0 && i < TG_COUNT) tT[i] = (v == "1");
      }
   }
   FileClose(h);

   gTradingOn = tTr;
   gMin       = tMn;
   gSetOpen   = tSt;
   if(fp == Fingerprint())
   {
      ArrayCopy(S, tS);
      ArrayCopy(TG, tT);
      Print(EA_NAME, " panel ki saved settings load hui");
   }
   else
   {
      Print(EA_NAME, " inputs badle gaye - panel settings inputs se li gayi");
      SaveCfg();
   }
}

bool Confirm(string what)
{
   if(!IsReal() || IsTester()) return true;
   string msg = what + "\n\nREAL account hai. Pakka badalna hai?";
   return (MessageBox(msg, EA_NAME + " " + EA_VER + " - Confirm", MB_YESNO | MB_ICONQUESTION) == IDYES);
}

//+------------------------------------------------------------------+
//| News filter                                                      |
//+------------------------------------------------------------------+
void LoadNews()
{
   ArrayResize(gNewsT, 0);
   ArrayResize(gNewsN, 0);
   datetime now  = TimeTradeServer();
   datetime from = now - 6 * 3600;
   datetime to   = now + 24 * 3600;
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
         if(ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;
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
   gNewsNow = "";
   if(!TG[TG_NEWS] || S[ST_NEWS] <= 0 || IsTester()) return;
   if(gNewsLoaded == 0 || TimeLocal() - gNewsLoaded > 600) LoadNews();
   datetime now = TimeTradeServer();
   int w = (int)S[ST_NEWS] * 60;
   for(int i = 0; i < ArraySize(gNewsT); i++)
   {
      if(now >= gNewsT[i] - w && now <= gNewsT[i] + w)
      {
         gNewsNow = gNewsN[i] + " @ " + TimeToString(ServerToIst(gNewsT[i]), TIME_MINUTES) + " IST";
         break;
      }
   }
}

//+------------------------------------------------------------------+
//| State: counts, today P/L, status                                 |
//+------------------------------------------------------------------+
void CalcToday()
{
   gTodayClosed = 0;
   gWins = 0;
   gLosses = 0;
   datetime mid = ServerIstMidnight();
   datetime lastIn = 0;
   if(HistorySelect(mid - 3 * 86400, TimeCurrent() + 3600))
   {
      int n = HistoryDealsTotal();
      for(int i = 0; i < n; i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0) continue;
         if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
         if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
         long     entry = HistoryDealGetInteger(d, DEAL_ENTRY);
         datetime dtm   = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
         if(entry == DEAL_ENTRY_IN && dtm > lastIn) lastIn = dtm;
         if(dtm < mid) continue;
         double p = HistoryDealGetDouble(d, DEAL_PROFIT) +
                    HistoryDealGetDouble(d, DEAL_SWAP) +
                    HistoryDealGetDouble(d, DEAL_COMMISSION);
         gTodayClosed += p;
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT || entry == DEAL_ENTRY_OUT_BY)
         {
            if(p > 0) gWins++;
            else if(p < 0) gLosses++;
         }
      }
   }
   if(lastIn > gLastEntry) gLastEntry = lastIn;
}

void CalcRegime()
{
   gADX = Buf(hADX, 0, 1);
   gATR = Buf(hATR, 0, 1);
   gEMA = Buf(hEMA, 0, 1);
   double c1 = iClose(_Symbol, InpTF, 1);
   gDead    = (c1 > 0 && gATR > 0 && gATR / c1 < InpATRThreshold);
   gIsTrend = (gADX >= InpADXThreshold);
   if(gADX <= 0)  { gRegime = "data load ho raha..."; return; }
   string a = "  ADX " + DoubleToString(gADX, 1);
   if(gDead)          gRegime = "DEAD (ATR kam)" + a;
   else if(gIsTrend)  gRegime = "TREND" + a + (TG[TG_TREND] ? "" : " (OFF)");
   else               gRegime = "RANGE" + a + (TG[TG_RANGE] ? "" : " (OFF)");
}

void UpdateState()
{
   gBuys = 0; gSells = 0; gFloating = 0; gLocked = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      double op  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl  = PositionGetDouble(POSITION_SL);
      double vol = PositionGetDouble(POSITION_VOLUME);
      gFloating += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      datetime pt = (datetime)PositionGetInteger(POSITION_TIME);
      if(pt > gLastEntry) gLastEntry = pt;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         gBuys++;
         if(sl > op) gLocked += DistToMoney(sl - op, vol);
      }
      else
      {
         gSells++;
         if(sl > 0 && sl < op) gLocked += DistToMoney(op - sl, vol);
      }
   }

   gPendStop = 0; gPendLimit = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_SELL_STOP) gPendStop++;
      else if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_SELL_LIMIT) gPendLimit++;
   }

   if(GetTickCount() - gLastHist >= 1000 || gLastHist == 0)
   {
      CalcToday();
      gLastHist = GetTickCount();
   }
   gTodayPL    = gTodayClosed + gFloating;
   gDayLossHit = (S[ST_DAYLOSS] > 0 && gTodayPL <= -S[ST_DAYLOSS]);

   UpdateNews();
   CalcRegime();

   int prev = gState;
   gState  = 0;
   gReason = "Sab theek - EA trade dhoondh raha hai";
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(!gTradingOn)
      { gState = 1; gReason = "Trading OFF (panel se) - khule trades manage ho rahe hain"; }
   else if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == 0 || MQLInfoInteger(MQL_TRADE_ALLOWED) == 0)
      { gState = 1; gReason = "MT5 me Algo Trading band hai"; }
   else if(gDayLossHit)
      { gState = 1; gReason = "Day loss seema poori - kal (IST) se phir chalu"; }
   else if(AccountInfoDouble(ACCOUNT_BALANCE) < InpMinBalance)
      { gState = 1; gReason = "Balance seema se kam hai"; }
   else if(InpDisableWeekend && (dt.day_of_week == 0 || dt.day_of_week == 6))
      { gState = 1; gReason = "Weekend - trade band"; }
   else if(gNewsNow != "")
      { gState = 2; gReason = "News: " + gNewsNow; }

   // ek saath 1 trade + trades ke beech gap
   bool prevBlock = gEntryBlock;
   gEntryBlock = false;
   int openNow = gBuys + gSells;
   long gapLeft = 0;
   if(InpMinGapMinutes > 0 && gLastEntry > 0)
      gapLeft = (long)gLastEntry + (long)InpMinGapMinutes * 60 - (long)TimeCurrent();
   if(InpMaxOpenTrades > 0 && openNow >= InpMaxOpenTrades)
   {
      gEntryBlock = true;
      if(gState == 0) gReason = "Max khule trades poore - naye pending nahi, purane chalu";
   }
   else if(gapLeft > 0)
   {
      gEntryBlock = true;
      if(gState == 0)
         gReason = StringFormat("Gap chal raha hai - agla trade %dh %02dm baad (%s IST se)",
                                (int)(gapLeft / 3600), (int)((gapLeft % 3600) / 60),
                                TimeToString(ServerToIst((datetime)((long)gLastEntry + (long)InpMinGapMinutes * 60)), TIME_MINUTES));
   }

   if(gState == 0 && !gEntryBlock && gScanNote != "")
      gReason = (ParkCount() > 0 ? IntegerToString(ParkCount()) + " park | " : "") + gScanNote;

   if(prev != gState || prevBlock != gEntryBlock) gForceCheck = true;
}

//+------------------------------------------------------------------+
//| Orders helpers                                                   |
//+------------------------------------------------------------------+
void CountLive(int &pos, int &pBuy, int &pSell)
{
   pos = 0; pBuy = 0; pSell = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      pos++;
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_BUY_LIMIT) pBuy++;
      else if(ot == ORDER_TYPE_SELL_STOP || ot == ORDER_TYPE_SELL_LIMIT) pSell++;
   }
}

bool Slot(bool isBuy, bool pending)
{
   int pos, pb, ps;
   CountLive(pos, pb, ps);
   if(pos + pb + ps >= InpMaxPositions) return false;
   if(pending)
   {
      if(isBuy && pb >= InpMaxPendingSide) return false;
      if(!isBuy && ps >= InpMaxPendingSide) return false;
   }
   return true;
}

// is level ke paas same disha ka trade / order pehle se hai?
bool NearExisting(bool isBuy, double price, double tol)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      bool pb = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      if(pb != isBuy) continue;
      if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - price) < tol) return true;
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      bool ob = (ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_BUY_LIMIT);
      bool os = (ot == ORDER_TYPE_SELL_STOP || ot == ORDER_TYPE_SELL_LIMIT);
      if(!ob && !os) continue;
      if(ob != isBuy) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - price) < tol) return true;
   }
   return false;
}

// pending hatao + Experts log me kaaran likho
bool DelOrder(ulong t, string why)
{
   string ty = EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
   double pr = OrderGetDouble(ORDER_PRICE_OPEN);
   bool ok = trade.OrderDelete(t);
   Print(EA_NAME, " ", EA_VER, " | pending hataya #", t, " ", ty, " @", DoubleToString(pr, _Digits),
         " - kaaran: ", why, (ok ? "" : "  (FAIL code " + IntegerToString((int)trade.ResultRetcode()) + ")"));
   return ok;
}

void DeleteOrders(bool stops, bool limits, bool buys, bool sells, string why)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      bool isStop = (ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_SELL_STOP);
      bool isLim  = (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_SELL_LIMIT);
      bool isB    = (ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_BUY_LIMIT);
      if(!((isStop && stops) || (isLim && limits))) continue;
      if(!((isB && buys) || (!isB && sells))) continue;
      DelOrder(t, why);
   }
}

void DeleteAllPending(string why) { DeleteOrders(true, true, true, true, why); }

// pending kab expire ho: 1) broker ki expiry date  2) comment "BTCEA T|1760342400"
// 3) setup + InpPendingExpiryHours. Galat / kati hui date (1 ghante se kam ya
//    30 din se zyada) ignore hoti hai.
datetime ExpiryOf(string cmt, datetime setup, datetime brokerExp)
{
   long lo = (long)setup + 3600, hi = (long)setup + 30 * 86400;
   if((long)brokerExp >= lo && (long)brokerExp <= hi) return brokerExp;
   int p = StringFind(cmt, "|");
   if(p > 0)
   {
      long e = StringToInteger(StringSubstr(cmt, p + 1));
      if(e >= lo && e <= hi) return (datetime)e;
   }
   return (datetime)((long)setup + (long)MathMax(1, InpPendingExpiryHours) * 3600);
}

string TagOf(string cmt)
{
   string t = cmt;
   int p = StringFind(t, "|");
   if(p > 0) t = StringSubstr(t, 0, p);
   StringReplace(t, "BTCEA ", "");
   return t;
}

// comment "BTCEA T|exp|L1760000000" se swing ki pehchaan
string PivOf(string cmt)
{
   int p1 = StringFind(cmt, "|");
   if(p1 < 0) return "";
   int p2 = StringFind(cmt, "|", p1 + 1);
   if(p2 < 0) return "";
   return StringSubstr(cmt, p2 + 1);
}

bool IsUsed(string key)
{
   if(key == "") return false;
   for(int i = 0; i < ArraySize(gUsedPiv); i++)
      if(gUsedPiv[i] == key) return true;
   return false;
}

void MarkUsed(string key)
{
   if(key == "" || IsUsed(key)) return;
   int n = ArraySize(gUsedPiv);
   if(n >= 500) { ArrayRemove(gUsedPiv, 0, 100); n = ArraySize(gUsedPiv); }
   ArrayResize(gUsedPiv, n + 1);
   gUsedPiv[n] = key;
}

// restart ke baad yaad karo kaunse swing pe order lag chuka
void RebuildUsed()
{
   ArrayResize(gUsedPiv, 0);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      MarkUsed(PivOf(OrderGetString(ORDER_COMMENT)));
   }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      MarkUsed(PivOf(PositionGetString(POSITION_COMMENT)));
   }
   if(HistorySelect(TimeCurrent() - 10 * 86400, TimeCurrent() + 3600))
   {
      int n = HistoryOrdersTotal();
      for(int i = 0; i < n; i++)
      {
         ulong o = HistoryOrderGetTicket(i);
         if(o == 0) continue;
         if(HistoryOrderGetString(o, ORDER_SYMBOL) != _Symbol) continue;
         if(HistoryOrderGetInteger(o, ORDER_MAGIC) != InpMagic) continue;
         MarkUsed(PivOf(HistoryOrderGetString(o, ORDER_COMMENT)));
      }
   }
}

// sirf bahut purane (v1.11 / v1.12, comment me '|' nahi) pending hatao.
// Baaki sab (broker ne comment kaata ho tab bhi) apni 72 ghante expiry tak rehte hain.
void DeleteOldFormat()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      string cmt = OrderGetString(ORDER_COMMENT);
      if(StringFind(cmt, "BTCEA") != 0) continue;
      if(StringFind(cmt, "|") >= 0) continue;
      DelOrder(t, "restart - bahut purane version ka pending");
   }
}

void DeleteExpired()
{
   if(InpPendingExpiryHours <= 0) return;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      datetime ex    = ExpiryOf(OrderGetString(ORDER_COMMENT), setup, (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION));
      if(TimeCurrent() >= ex)
         DelOrder(t, "expiry (" + IntegerToString((int)(((long)ex - (long)setup) / 3600)) + " ghante poore)");
   }
}

int  ParkCount() { return ArraySize(gParkPrice); }

void ClearPark()
{
   ArrayResize(gParkType, 0);
   ArrayResize(gParkPrice, 0);
   ArrayResize(gParkExp, 0);
   ArrayResize(gParkTag, 0);
   ArrayResize(gParkPiv, 0);
}

// pending hata ke yaad rakho - baad me wapas lagenge
void ParkPending(string why = "park")
{
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      if(ot != ORDER_TYPE_BUY_STOP && ot != ORDER_TYPE_SELL_STOP &&
         ot != ORDER_TYPE_BUY_LIMIT && ot != ORDER_TYPE_SELL_LIMIT) continue;
      double   pr  = OrderGetDouble(ORDER_PRICE_OPEN);
      string   cmt = OrderGetString(ORDER_COMMENT);
      datetime ex  = ExpiryOf(cmt, (datetime)OrderGetInteger(ORDER_TIME_SETUP), (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION));
      if(!DelOrder(t, why + " (baad me wapas lagega)")) continue;
      bool dup = false;
      for(int j = 0; j < ParkCount(); j++)
         if(gParkType[j] == (int)ot && MathAbs(gParkPrice[j] - pr) < TickSize()) { dup = true; break; }
      if(dup) continue;
      int k = ParkCount();
      ArrayResize(gParkType, k + 1);
      ArrayResize(gParkPrice, k + 1);
      ArrayResize(gParkExp, k + 1);
      ArrayResize(gParkTag, k + 1);
      ArrayResize(gParkPiv, k + 1);
      gParkPiv[k]   = PivOf(cmt);
      gParkType[k]  = (int)ot;
      gParkPrice[k] = pr;
      gParkExp[k]   = ex;
      gParkTag[k]   = TagOf(cmt);
      n++;
   }
   if(n > 0) SetMsg(IntegerToString(n) + " pending park kiye - mauka aane par wapas lagenge");
}

void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      trade.PositionClose(t);
   }
   DeleteAllPending("day loss seema poori");
   ClearPark();
   SetMsg("Day loss seema poori - sab trades band kiye");
}

bool MarginOK(bool isBuy, double lot, double price)
{
   double m = 0;
   if(!OrderCalcMargin(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, m)) return true;
   if(m > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.95)
   {
      SetMsg("Margin kam hai - naya order nahi lagaya");
      return false;
   }
   return true;
}

bool SendPending(ENUM_ORDER_TYPE type, double lot, double price, double sl, double tp,
                 ENUM_ORDER_TYPE_TIME tt, datetime ex, string cmt)
{
   bool ok = false;
   if(type == ORDER_TYPE_BUY_STOP)   ok = trade.BuyStop(lot, price, _Symbol, sl, tp, tt, ex, cmt);
   if(type == ORDER_TYPE_SELL_STOP)  ok = trade.SellStop(lot, price, _Symbol, sl, tp, tt, ex, cmt);
   if(type == ORDER_TYPE_BUY_LIMIT)  ok = trade.BuyLimit(lot, price, _Symbol, sl, tp, tt, ex, cmt);
   if(type == ORDER_TYPE_SELL_LIMIT) ok = trade.SellLimit(lot, price, _Symbol, sl, tp, tt, ex, cmt);
   return (ok && (trade.ResultRetcode() == TRADE_RETCODE_DONE || trade.ResultRetcode() == TRADE_RETCODE_PLACED));
}

bool PlacePending(ENUM_ORDER_TYPE type, double price, string tag, string piv, datetime expiry)
{
   double lot = NormLot(S[ST_LOT]);
   if(lot <= 0) return false;
   if(expiry == 0) expiry = (datetime)((long)TimeCurrent() + (long)MathMax(1, InpPendingExpiryHours) * 3600);
   if((long)expiry - (long)TimeCurrent() < 300) return false;
   price = NormP(price);
   bool isBuy = (type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_LIMIT);
   double sld = MoneyToDist(S[ST_SLMAX], lot);
   double tpd = MoneyToDist(S[ST_TPMAX], lot);
   if(sld <= 0) return false;
   double sl = NormP(isBuy ? price - sld : price + sld);
   double tp = (tpd > 0 ? NormP(isBuy ? price + tpd : price - tpd) : 0);
   if(!MarginOK(isBuy, lot, price)) return false;

   string cmt = "BTCEA " + tag + "|" + IntegerToString((long)expiry);
   if(piv != "") cmt += "|" + piv;
   int    em  = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   ENUM_ORDER_TYPE_TIME tt = OrderTimeType();
   datetime ex = 0;
   if((em & SYMBOL_EXPIRATION_SPECIFIED) != 0) { tt = ORDER_TIME_SPECIFIED; ex = expiry; }

   bool ok = SendPending(type, lot, price, sl, tp, tt, ex, cmt);
   if(!ok && tt == ORDER_TIME_SPECIFIED)
   {
      Print(EA_NAME, " expiry ke saath fail (code ", trade.ResultRetcode(), ") - GTC se dobara");
      ok = SendPending(type, lot, price, sl, tp, OrderTimeType(), 0, cmt);
   }
   if(!ok)
   {
      Print(EA_NAME, " pending fail ", EnumToString(type), " @", DoubleToString(price, _Digits),
            " code ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      SetMsg("Order fail: " + trade.ResultRetcodeDescription());
      return false;
   }
   MarkUsed(piv);
   SetMsg(EnumToString(type) + " @ " + DoubleToString(price, _Digits) + " lagaya (expiry " +
          TimeToString(ServerToIst(expiry), TIME_DATE | TIME_MINUTES) + " IST)");
   return true;
}

bool OpenMarket(bool isBuy, string tag)
{
   double lot = NormLot(S[ST_LOT]);
   if(lot <= 0) return false;
   double px  = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(!MarginOK(isBuy, lot, px)) return false;
   double sld = MoneyToDist(S[ST_SLMAX], lot);
   double tpd = MoneyToDist(S[ST_TPMAX], lot);
   if(sld <= 0) return false;
   double sl = NormP(isBuy ? px - sld : px + sld);
   double tp = (tpd > 0 ? NormP(isBuy ? px + tpd : px - tpd) : 0);
   string cmt = "BTCEA " + tag;
   bool ok = isBuy ? trade.Buy(lot, _Symbol, 0, sl, tp, cmt) : trade.Sell(lot, _Symbol, 0, sl, tp, cmt);
   if(!ok || trade.ResultRetcode() != TRADE_RETCODE_DONE)
   {
      Print(EA_NAME, " market fail code ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return false;
   }
   gLastMktEntry = TimeCurrent();
   SetMsg((isBuy ? "BUY" : "SELL") + string(" market khula @ ") + DoubleToString(px, _Digits));
   return true;
}

bool GapOK()
{
   if(gLastMktEntry == 0) return true;
   int sh = iBarShift(_Symbol, InpTF, gLastMktEntry, false);
   return (sh < 0 || sh >= InpMinCandleGap);
}

//+------------------------------------------------------------------+
//| ZigZag style swing levels                                        |
//| highs=true: un-toote swing high (ref se upar), paas wala pehle   |
//| start: kis bar se dekhna shuru (0 = abhi, 2 = market signal)     |
//+------------------------------------------------------------------+
int FindSwingsT(bool highs, int start, int maxN, double ref, double tol, int maxAgeSec,
                double &lv[], datetime &tm[])
{
   ArrayResize(lv, 0);
   ArrayResize(tm, 0);
   int D = MathMax(1, InpSwingDepth);
   int need = InpSwingLookback + D + start + 2;
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int got = CopyRates(_Symbol, InpTF, 0, need, r);
   if(got < start + 2 * D + 3) return 0;
   datetime oldest = (maxAgeSec > 0 ? (datetime)((long)TimeCurrent() - maxAgeSec) : 0);

   double ext = highs ? r[start].high : r[start].low;
   for(int i = start + 1; i < got - D; i++)
   {
      if(oldest > 0 && r[i].time < oldest) break;
      if(i - start >= D)
      {
         bool piv = true;
         for(int k = 1; k <= D && piv; k++)
         {
            if(highs) { if(!(r[i].high > r[i - k].high && r[i].high >= r[i + k].high)) piv = false; }
            else      { if(!(r[i].low  < r[i - k].low  && r[i].low  <= r[i + k].low))  piv = false; }
         }
         if(piv)
         {
            double L = highs ? r[i].high : r[i].low;
            bool unbroken = highs ? (L > ext) : (L < ext);
            bool side     = highs ? (L > ref) : (L < ref);
            if(unbroken && side)
            {
               bool dup = false;
               for(int j = 0; j < ArraySize(lv); j++)
                  if(MathAbs(lv[j] - L) < tol) { dup = true; break; }
               if(!dup)
               {
                  int s = ArraySize(lv);
                  ArrayResize(lv, s + 1);
                  ArrayResize(tm, s + 1);
                  lv[s] = L;
                  tm[s] = r[i].time;
                  if(s + 1 >= maxN) break;
               }
            }
         }
      }
      if(highs) ext = MathMax(ext, r[i].high);
      else      ext = MathMin(ext, r[i].low);
   }
   return ArraySize(lv);
}

int FindSwings(bool highs, int start, int maxN, double ref, double tol, double &lv[])
{
   datetime tm[];
   return FindSwingsT(highs, start, maxN, ref, tol, 0, lv, tm);
}

//+------------------------------------------------------------------+
//| Entries                                                          |
//+------------------------------------------------------------------+
// park kiye pending wapas lagao (agar level abhi bhi sahi hai)
void RestoreParked(double tol)
{
   int n = ParkCount();
   if(n == 0) return;
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sDst = StopsDist();
   int keep = 0;
   for(int i = 0; i < n; i++)
   {
      int    ty = gParkType[i];
      double p  = gParkPrice[i];
      bool isStop = (ty == ORDER_TYPE_BUY_STOP || ty == ORDER_TYPE_SELL_STOP);
      bool isBuy  = (ty == ORDER_TYPE_BUY_STOP || ty == ORDER_TYPE_BUY_LIMIT);
      bool drop = false;
      if((long)gParkExp[i] - (long)TimeCurrent() < 300) drop = true;
      // price level paar kar gaya = woh mauka nikal gaya
      else if(ty == ORDER_TYPE_BUY_STOP   && p <= ask + sDst) drop = true;
      else if(ty == ORDER_TYPE_SELL_STOP  && p >= bid - sDst) drop = true;
      else if(ty == ORDER_TYPE_BUY_LIMIT  && p >= ask - sDst) drop = true;
      else if(ty == ORDER_TYPE_SELL_LIMIT && p <= bid + sDst) drop = true;
      else if(isStop  && !(TG[TG_TREND] && TG[TG_STP])) drop = true;
      else if(!isStop && !(TG[TG_RANGE] && TG[TG_LIM])) drop = true;
      else if(NearExisting(isBuy, p, tol)) drop = true;
      else if(Slot(isBuy, true) && PlacePending((ENUM_ORDER_TYPE)ty, p, gParkTag[i], gParkPiv[i], gParkExp[i])) drop = true;

      if(!drop)
      {
         gParkType[keep]  = gParkType[i];
         gParkPrice[keep] = gParkPrice[i];
         gParkExp[keep]   = gParkExp[i];
         gParkTag[keep]   = gParkTag[i];
         gParkPiv[keep]   = gParkPiv[i];
         keep++;
      }
   }
   ArrayResize(gParkType, keep);
   ArrayResize(gParkPrice, keep);
   ArrayResize(gParkExp, keep);
   ArrayResize(gParkTag, keep);
   ArrayResize(gParkPiv, keep);
}

void ManageEntries()
{
   DeleteExpired();

   if(gState == 1)                 // trading off / day loss / balance / weekend
   {
      DeleteAllPending(gReason);
      ClearPark();
      return;
   }
   if(gState == 2)                 // news
   {
      if(InpDeletePendingOnNews) ParkPending("news: " + gNewsNow);
      return;
   }
   // jo mode aapne OFF kiya uske pending hatao
   if(!(TG[TG_TREND] && TG[TG_STP])) DeleteOrders(true, false, true, true, "TREND / STOP OFF");
   if(!(TG[TG_RANGE] && TG[TG_LIM])) DeleteOrders(false, true, true, true, "RANGE / LIMIT OFF");

   CalcRegime();
   double c1 = iClose(_Symbol, InpTF, 1);
   double c2 = iClose(_Symbol, InpTF, 2);
   double h1 = iHigh(_Symbol, InpTF, 1);
   double l1 = iLow(_Symbol, InpTF, 1);
   if(c1 <= 0 || gATR <= 0 || gADX <= 0) { gScanNote = "Chart data load ho raha hai..."; return; }

   double tol = MathMax(InpMinDistSameDir, gATR * 0.25);
   RestoreParked(tol);
   if(gEntryBlock) return;         // max khule trades / gap: sirf naye pending ruke

   bool trendOK = (TG[TG_TREND] && gIsTrend && !gDead);
   bool rangeOK = (TG[TG_RANGE] && !gIsTrend && !gDead);
   if(NormLot(S[ST_LOT]) <= 0) return;

   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sDst = StopsDist();
   double buf  = InpEntryBuffer;
   bool allowBuy = true, allowSell = true;
   if(InpUseEMADir && gEMA > 0) { allowBuy = (c1 > gEMA); allowSell = (c1 < gEMA); }

   //--- SWING SCAN (Buster "ZZ scan" jaisa)
   //    har candle pe pichhle InpMaxSwingAgeHours ke un-toote swings dekho;
   //    jis swing pe abhi tak order nahi laga uspe 1 pending (ek candle me max 1)
   int age = MathMax(1, InpMaxSwingAgeHours) * 3600;
   double hs[], ls[];
   datetime ht[], lt[];
   int nh = FindSwingsT(true,  0, 10, ask, tol, age, hs, ht);
   int nl = FindSwingsT(false, 0, 10, bid, tol, age, ls, lt);
   string lvTxt = "H " + (nh > 0 ? DoubleToString(hs[0], 0) : "-") + "  L " + (nl > 0 ? DoubleToString(ls[0], 0) : "-");
   string mode  = "ADX " + DoubleToString(gADX, 1);
   string note  = "";

   if(!trendOK && !rangeOK)
   {
      if(gDead)          note = "ATR bahut kam (market dead) - ruka";
      else if(gIsTrend)  note = mode + " TREND hai, par TREND mode OFF";
      else               note = mode + " < " + DoubleToString(InpADXThreshold, 0) + " sideways - ruka" +
                                (TG[TG_RANGE] ? "" : " (RANGE OFF)");
   }
   else
   {
      int      bType = -1;
      double   bPrice = 0;
      datetime bTime = 0;
      string   bKey = "", bTag = "";
      bool     full = false;
      int      freeSw = 0;

      for(int i = 0; i < nh; i++)
      {
         string key = "H" + IntegerToString((long)ht[i]);
         if(IsUsed(key)) continue;
         int ty = -1; double p = 0; bool buy = true; string tg = "";
         if(trendOK && TG[TG_STP] && allowBuy)  { ty = ORDER_TYPE_BUY_STOP;   p = hs[i] + buf; buy = true;  tg = "T"; if(p <= ask + sDst) continue; }
         else if(rangeOK && TG[TG_LIM])         { ty = ORDER_TYPE_SELL_LIMIT; p = hs[i] - buf; buy = false; tg = "R"; if(p <= bid + sDst) continue; }
         if(ty < 0) continue;
         if(NearExisting(buy, p, tol)) continue;
         freeSw++;
         if(!Slot(buy, true)) { full = true; continue; }
         if(ht[i] > bTime) { bType = ty; bPrice = p; bTime = ht[i]; bKey = key; bTag = tg; }
      }
      for(int i = 0; i < nl; i++)
      {
         string key = "L" + IntegerToString((long)lt[i]);
         if(IsUsed(key)) continue;
         int ty = -1; double p = 0; bool buy = false; string tg = "";
         if(trendOK && TG[TG_STP] && allowSell) { ty = ORDER_TYPE_SELL_STOP;  p = ls[i] - buf; buy = false; tg = "T"; if(p >= bid - sDst) continue; }
         else if(rangeOK && TG[TG_LIM])         { ty = ORDER_TYPE_BUY_LIMIT;  p = ls[i] + buf; buy = true;  tg = "R"; if(p >= ask - sDst) continue; }
         if(ty < 0) continue;
         if(NearExisting(buy, p, tol)) continue;
         freeSw++;
         if(!Slot(buy, true)) { full = true; continue; }
         if(lt[i] > bTime) { bType = ty; bPrice = p; bTime = lt[i]; bKey = key; bTag = tg; }
      }

      string md = (trendOK ? "TREND " : "RANGE ") + mode;
      if(bType >= 0)
      {
         if(PlacePending((ENUM_ORDER_TYPE)bType, bPrice, bTag, bKey, 0))
            note = md + " - naya pending laga";
         else
            note = md + " - order fail, Experts log dekho";
      }
      else if(full)        note = md + " - max pending poore";
      else if(freeSw == 0) note = md + " - naye swing ka intezaar";
   }
   gScanNote = note + "  |  " + lvTxt;
   datetime bt0 = iTime(_Symbol, InpTF, 0);
   if(bt0 != gScanPrinted)
   {
      gScanPrinted = bt0;
      Print(EA_NAME, " ", EA_VER, " scan: ", gScanNote);
   }

   //--- MARKET entries (breakout / rejection)
   if(TG[TG_MKT] && GapOK())
   {
      double h2[], l2[];
      if(trendOK)
      {
         if(allowBuy && FindSwings(true, 2, 1, 0, tol, h2) > 0 &&
            c1 > h2[0] && c2 <= h2[0] && Slot(true, false) && !NearExisting(true, ask, tol))
            OpenMarket(true, "TM");
         else if(allowSell && FindSwings(false, 2, 1, 1e12, tol, l2) > 0 &&
            c1 < l2[0] && c2 >= l2[0] && Slot(false, false) && !NearExisting(false, bid, tol))
            OpenMarket(false, "TM");
      }
      else if(rangeOK)
      {
         if(FindSwings(true, 2, 1, 0, tol, h2) > 0 &&
            h1 > h2[0] && c1 < h2[0] && Slot(false, false) && !NearExisting(false, bid, tol))
            OpenMarket(false, "RM");
         else if(FindSwings(false, 2, 1, 1e12, tol, l2) > 0 &&
            l1 < l2[0] && c1 > l2[0] && Slot(true, false) && !NearExisting(true, ask, tol))
            OpenMarket(true, "RM");
      }
   }
}

//+------------------------------------------------------------------+
//| Khule trades: Breakeven, Profit Lock, Trailing                   |
//+------------------------------------------------------------------+
double Better(bool isBuy, double cur, double c)
{
   if(cur == 0) return c;
   return isBuy ? MathMax(cur, c) : MathMin(cur, c);
}

void ManagePositions()
{
   double ts   = TickSize();
   double sDst = StopsDist();
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double op  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl  = PositionGetDouble(POSITION_SL);
      double tp  = PositionGetDouble(POSITION_TP);
      double vol = PositionGetDouble(POSITION_VOLUME);

      // safety: bina SL ke trade ko SL max lagao
      if(sl == 0)
      {
         double d = MoneyToDist(S[ST_SLMAX], vol);
         if(d <= 0) continue;
         double nsl = NormP(isBuy ? op - d : op + d);
         if(isBuy  && nsl >= bid - sDst) nsl = NormP(bid - sDst);
         if(!isBuy && nsl <= ask + sDst) nsl = NormP(ask + sDst);
         trade.PositionModify(t, nsl, tp);
         continue;
      }

      double px   = isBuy ? bid : ask;
      double prof = DistToMoney(isBuy ? px - op : op - px, vol);
      double best = sl;

      if(TG[TG_BE] && prof >= InpBETrigger)
      {
         double d = MoneyToDist(InpBEPlus, vol);
         best = Better(isBuy, best, isBuy ? op + d : op - d);
      }
      if(TG[TG_LOCK] && S[ST_TPMIN] > 0 && prof >= S[ST_TPMIN])
      {
         double step = MathMax(0.01, S[ST_STEP]);
         double lvl  = S[ST_TPMIN] + MathFloor((prof - S[ST_TPMIN]) / step) * step;
         double keep = lvl * S[ST_KEEP] / 100.0;
         double d    = MoneyToDist(keep, vol);
         best = Better(isBuy, best, isBuy ? op + d : op - d);
      }
      if(TG[TG_TRAIL] && prof >= S[ST_TPMIN])
      {
         double d = MoneyToDist(InpTrailDist, vol);
         double c = isBuy ? px - d : px + d;
         if((isBuy && c > op) || (!isBuy && c < op)) best = Better(isBuy, best, c);
      }

      // broker ki min doori ka dhyan
      if(isBuy  && best > bid - sDst) best = bid - sDst;
      if(!isBuy && best < ask + sDst) best = ask + sDst;
      best = NormP(best);

      double minMove = MathMax(ts, MoneyToDist(0.02, vol));
      bool improve = isBuy ? (best - sl >= minMove) : (sl - best >= minMove);
      if(improve)
      {
         if(!trade.PositionModify(t, best, tp))
            Print(EA_NAME, " SL modify fail #", t, " code ", trade.ResultRetcode());
      }
   }
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

void UiEdit(string n, double x, double y, double w, double h, string t, double fs)
{
   string nm = PFX + n;
   ObjBase(nm, OBJ_EDIT);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, InpPanelX + PX(x));
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, InpPanelY + PX(y));
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, PX(w));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, PX(h));
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetString(0, nm, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(fs));
   ObjectSetInteger(0, nm, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, nm, OBJPROP_READONLY, false);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, TXT_W);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, CLR_EDIT);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, NEON_PU);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 10);
}

void SetT(string n, string t, color c)
{
   string nm = PFX + n;
   if(ObjectFind(0, nm) < 0) return;
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
}

void PaintToggle(int i)
{
   string nm = PFX + "tg" + IntegerToString(i);
   if(ObjectFind(0, nm) < 0) return;
   ObjectSetString(0, nm, OBJPROP_TEXT, TG_NAME[i] + (TG[i] ? "   ON" : "   OFF"));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, TG[i] ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, TG[i] ? C'8,46,30' : C'50,12,22');
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, TG[i] ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
}

void PaintTradeBtn()
{
   string nm = PFX + "btnTrade";
   if(ObjectFind(0, nm) < 0) return;
   ObjectSetString(0, nm, OBJPROP_TEXT, gTradingOn ? "ON" : "OFF");
   ObjectSetInteger(0, nm, OBJPROP_COLOR, gTradingOn ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, gTradingOn ? C'8,46,30' : C'50,12,22');
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, gTradingOn ? NEON_GR : NEON_RD);
   ObjectSetInteger(0, nm, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| PANEL - build                                                    |
//+------------------------------------------------------------------+
void BuildMini()
{
   double W = 440, H = 36;
   UiRect("bg", 0, 0, W, H, CLR_BG, NEON_CY, 2);
   UiRect("logo", 6, 5, 26, 26, BTC_OR, BTC_OR, 1);
   UiText("logoB", 19, 18, "G", C'12,12,12', 12, "Arial Black", ANCHOR_CENTER);
   UiText("mt", 40, 18, EA_NAME + " " + EA_VER, TXT_W, 10, "Arial Black", ANCHOR_LEFT);
   UiText("mst", 215, 18, "-", NEON_GR, 10, "Bahnschrift", ANCHOR_LEFT);
   UiText("mpl", W - 62, 18, "-", TXT_W, 10, "Consolas", ANCHOR_RIGHT);
   UiBtn("btnMax", W - 52, 6, 44, 24, "[ ]", NEON_CY, CLR_BOX, NEON_CY, 9);
}

void BuildPanel()
{
   ObjectsDeleteAll(0, PFX);
   if(gMin)
   {
      BuildMini();
      UpdatePanel();
      return;
   }

   double W  = 740;
   double yS = gSetOpen ? 290 : 120;   // summary row ka y
   double H  = yS + 154 + 30;
   double bw = (W - 24) / 2.0;         // har aadha box
   double xl = 8, xr = 8 + bw + 8;

   //--- frame
   UiRect("bg", 0, 0, W, H, CLR_BG, NEON_CY, 2);
   UiRect("acc1", 2, 2, W * 0.55, 3, NEON_MG, NEON_MG, 1);
   UiRect("acc2", W * 0.55 + 2, 2, W * 0.45 - 4, 3, NEON_CY, NEON_CY, 1);

   //--- header
   double y = 9;
   UiRect("hdr", 8, y, W - 16, 46, CLR_BOX, CLR_LINE, 1);
   UiRect("logo", 16, y + 6, 34, 34, BTC_OR, BTC_OR, 1);
   UiText("logoB", 33, y + 23, "G", C'12,12,12', 15, "Arial Black", ANCHOR_CENTER);
   UiText("title", 60, y + 18, EA_NAME + " " + EA_VER, TXT_W, 15, "Arial Black", ANCHOR_LEFT);
   UiText("deco", 312, y + 18, "//////", NEON_CY, 12, "Arial Black", ANCHOR_LEFT);
   UiText("sub", 60, y + 37, "ANKUSH NEW VISION  |  GOLD SMART ALGO", TXT_DIM, 7, "Bahnschrift", ANCHOR_LEFT);
   UiText("clock", W - 142, y + 17, "--:--:--", NEON_CY, 13, "Consolas", ANCHOR_RIGHT);
   UiText("date", W - 142, y + 36, "-", NEON_MG, 8, "Bahnschrift", ANCHOR_RIGHT);
   UiBtn("btnSet", W - 132, y + 10, 58, 26, "SET",
         gSetOpen ? C'12,12,12' : NEON_PU, gSetOpen ? NEON_PU : CLR_BOX, NEON_PU, 10, "Arial Black");
   UiBtn("btnMin", W - 66, y + 10, 46, 26, "-", TXT_W, CLR_BOX, NEON_CY, 12, "Arial Black");

   //--- info strip
   y = 63;
   double cw = (W - 16) / 4.0;
   string cap[4] = {"ACCOUNT", "MAGIC", "STATUS", "TRADING"};
   color  cc[4]  = {NEON_CY, NEON_MG, NEON_GR, NEON_OR};
   for(int i = 0; i < 4; i++)
   {
      double cx = 8 + i * cw;
      string si = IntegerToString(i);
      UiRect("ic" + si, cx, y, cw - 6, 50, CLR_CELL, CLR_LINE, 1);
      UiRect("id" + si, cx + 9, y + 19, 12, 12, CLR_CELL, cc[i], 2);
      UiText("icap" + si, cx + 30, y + 14, cap[i], TXT_DIM, 7, "Bahnschrift", ANCHOR_LEFT);
      if(i < 3) UiText("iv" + si, cx + 30, y + 34, "-", TXT_W, 11, "Arial Black", ANCHOR_LEFT);
   }
   UiBtn("btnTrade", 8 + 3 * cw + 30, y + 23, cw - 46, 22, "ON", NEON_GR, C'8,46,30', NEON_GR, 10, "Arial Black");
   PaintTradeBtn();

   //--- settings + functions
   if(gSetOpen)
   {
      y = 121;
      UiRect("sbox", xl, y, bw, 162, CLR_BOX, NEON_PU, 1);
      UiText("sh", xl + 10, y + 14, "// SETTINGS - value likho, ENTER dabao", NEON_PU, 8, "Bahnschrift", ANCHOR_LEFT);
      UiBtn("btnDef", xl + bw - 86, y + 4, 78, 20, "DEFAULTS", NEON_OR, C'42,26,0', NEON_OR, 8, "Arial Black");
      color dc[ST_COUNT] = {NEON_CY, NEON_GR, NEON_GR, NEON_RD, NEON_PU, NEON_PU, NEON_OR, NEON_RD};
      double colW = (bw - 10) / 2.0;
      for(int i = 0; i < ST_COUNT; i++)
      {
         int col = i / 4, row = i % 4;
         double cx = xl + 10 + col * colW;
         double cy = y + 30 + row * 32;
         string si = IntegerToString(i);
         UiRect("sd" + si, cx, cy + 10, 7, 7, dc[i], dc[i], 1);
         UiText("sl" + si, cx + 12, cy + 14, ST_NAME[i], TXT_W, 8, "Bahnschrift", ANCHOR_LEFT);
         UiEdit("ed" + si, cx + 92, cy + 2, 72, 24, Fmt(i), 10);
      }

      UiRect("fbox", xr, y, bw, 162, CLR_BOX, NEON_CY, 1);
      UiText("fh", xr + 10, y + 14, "// FUNCTIONS - dabao = ON / OFF", NEON_CY, 8, "Bahnschrift", ANCHOR_LEFT);
      double tw = (bw - 22) / 3.0;
      for(int i = 0; i < TG_COUNT; i++)
      {
         int c = i % 3, r = i / 3;
         UiBtn("tg" + IntegerToString(i), xr + 5 + c * (tw + 6), y + 30 + r * 42, tw, 34, "",
               NEON_GR, CLR_BOX, NEON_GR, 8, "Bahnschrift");
         PaintToggle(i);
      }
   }

   //--- summary (left)
   y = yS;
   UiRect("sumbox", xl, y, bw, 154, CLR_BOX, NEON_MG, 1);
   UiText("sumh", xl + 10, y + 14, "// SUMMARY", NEON_MG, 8, "Bahnschrift", ANCHOR_LEFT);
   string sn[6] = {"Khule trades", "Pending orders", "Aaj ka P/L", "Aaj jeet / haar", "Pakka profit (locked)", "Market abhi"};
   for(int i = 0; i < 6; i++)
   {
      double ly = y + 34 + i * 20;
      string si = IntegerToString(i);
      UiText("sk" + si, xl + 14, ly, sn[i], TXT_DIM, 9, "Bahnschrift", ANCHOR_LEFT);
      UiText("sv" + si, xl + bw - 12, ly, "-", TXT_W, 9, "Consolas", ANCHOR_RIGHT);
      if(i < 5) UiRect("ss" + si, xl + 10, ly + 10, bw - 20, 1, CLR_LINE, CLR_LINE, 1);
   }

   //--- tiles (right, 2 x 2)
   string tc[4]   = {"AAJ P/L $", "OPEN TRADES", "WIN %", "DAY LOSS SEEMA $"};
   color  tcol[4] = {NEON_GR, NEON_CY, NEON_PU, NEON_OR};
   double tw2 = (bw - 6) / 2.0;
   for(int i = 0; i < 4; i++)
   {
      int c = i % 2, r = i / 2;
      double tx = xr + c * (tw2 + 6);
      double ty = y + r * 80;
      string si = IntegerToString(i);
      UiRect("tile" + si, tx, ty, tw2, 74, CLR_BOX, tcol[i], 1);
      UiRect("tbar" + si, tx, ty, 4, 74, tcol[i], tcol[i], 1);
      UiText("tcap" + si, tx + 14, ty + 17, tc[i], TXT_DIM, 8, "Bahnschrift", ANCHOR_LEFT);
      UiText("tval" + si, tx + 14, ty + 48, "-", TXT_W, 14, "Arial Black", ANCHOR_LEFT);
   }

   //--- footer
   UiText("foot", 14, yS + 154 + 15, "-", TXT_DIM, 8, "Bahnschrift", ANCHOR_LEFT);

   UpdatePanel();
}

//+------------------------------------------------------------------+
//| PANEL - live values                                              |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   string pl  = SignMoney(gTodayPL);
   color  plc = (gTodayPL >= 0 ? NEON_GR : NEON_RD);
   string st  = (gState == 0 ? "ACTIVE" : (gState == 1 ? "BAND" : "NEWS"));
   color  stc = (gState == 0 ? NEON_GR : (gState == 1 ? NEON_RD : NEON_OR));

   if(gMin)
   {
      SetT("mst", st, stc);
      SetT("mpl", "P/L " + pl, plc);
      ChartRedraw();
      return;
   }

   datetime ist = IstNow();
   SetT("clock", TimeToString(ist, TIME_SECONDS), NEON_CY);
   SetT("date", IstDate(ist), NEON_MG);

   SetT("iv0", IsReal() ? "REAL" : "DEMO", IsReal() ? NEON_RD : NEON_GR);
   SetT("iv1", IntegerToString(InpMagic), NEON_MG);
   SetT("iv2", st, stc);
   PaintTradeBtn();

   SetT("sv0", StringFormat("%d   (B %d / S %d)", gBuys + gSells, gBuys, gSells), TXT_W);
   SetT("sv1", StringFormat("%d  (Stop %d / Lim %d / Park %d)", gPendStop + gPendLimit, gPendStop, gPendLimit, ParkCount()), TXT_W);
   SetT("sv2", pl + " $", plc);
   SetT("sv3", StringFormat("%d / %d", gWins, gLosses), TXT_W);
   SetT("sv4", SignMoney(gLocked) + " $", gLocked > 0 ? NEON_GR : TXT_W);
   SetT("sv5", gRegime, NEON_CY);

   SetT("tval0", pl, plc);
   SetT("tval1", IntegerToString(gBuys + gSells), NEON_CY);
   int tot = gWins + gLosses;
   SetT("tval2", tot > 0 ? IntegerToString((int)MathRound(100.0 * gWins / tot)) + "%" : "--", NEON_PU);
   if(S[ST_DAYLOSS] > 0)
   {
      double left = MathMax(0.0, S[ST_DAYLOSS] + MathMin(0.0, gTodayPL));
      double frac = left / S[ST_DAYLOSS];
      color  lc   = (frac > 0.5 ? NEON_GR : (frac > 0.2 ? NEON_OR : NEON_RD));
      SetT("tval3", DoubleToString(left, 2) + "/" + DoubleToString(S[ST_DAYLOSS], 2), lc);
   }
   else SetT("tval3", "OFF", TXT_DIM);

   bool showMsg = (gMsg != "" && TimeLocal() - gMsgTime < 20);
   SetT("foot", showMsg ? gMsg : gReason, showMsg ? NEON_CY : (gState == 0 ? TXT_DIM : stc));

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| PANEL - events                                                   |
//+------------------------------------------------------------------+
void OnEditDone(int i, string objName)
{
   string txt = ObjectGetString(0, objName, OBJPROP_TEXT);
   StringReplace(txt, ",", ".");
   StringTrimLeft(txt);
   StringTrimRight(txt);
   double v = StringToDouble(txt);
   if(i == ST_LOT && v > 0) v = NormLot(v);
   if(ST_DIG[i] == 0) v = MathRound(v);

   string err = "";
   if(StringLen(txt) == 0 || v < ST_MINV[i] || v > ST_MAXV[i])
      err = ST_NAME[i] + " galat - range " + DoubleToString(ST_MINV[i], ST_DIG[i]) +
            " se " + DoubleToString(ST_MAXV[i], ST_DIG[i]);
   else if(i == ST_TPMIN && v >= S[ST_TPMAX]) err = "TP MIN, TP MAX se chhota hona chahiye";
   else if(i == ST_TPMAX && v <= S[ST_TPMIN]) err = "TP MAX, TP MIN se bada hona chahiye";

   if(err != "")
   {
      ObjectSetString(0, objName, OBJPROP_TEXT, Fmt(i));
      SetMsg(err);
      UpdatePanel();
      return;
   }
   if(MathAbs(v - S[i]) < 1e-9)
   {
      ObjectSetString(0, objName, OBJPROP_TEXT, Fmt(i));
      return;
   }

   string nv = DoubleToString(v, ST_DIG[i]);
   if(!Confirm(ST_NAME[i] + " :  " + Fmt(i) + "  ->  " + nv))
   {
      ObjectSetString(0, objName, OBJPROP_TEXT, Fmt(i));
      SetMsg(ST_NAME[i] + " badlav cancel");
      UpdatePanel();
      return;
   }

   S[i] = v;
   SaveCfg();
   ObjectSetString(0, objName, OBJPROP_TEXT, Fmt(i));
   if(i == ST_LOT || i == ST_SLMAX || i == ST_TPMAX)
   {
      ParkPending(ST_NAME[i] + " badla");
      SetMsg(ST_NAME[i] + " = " + nv + " saved - pending orders nayi value se dobara lagenge");
   }
   else SetMsg(ST_NAME[i] + " = " + nv + " saved");
   gForceCheck = true;
   UpdateState();
   UpdatePanel();
}

void OnToggle(int i)
{
   bool nv = !TG[i];
   if(!Confirm(TG_NAME[i] + " :  " + (TG[i] ? "ON" : "OFF") + "  ->  " + (nv ? "ON" : "OFF")))
   {
      PaintToggle(i);
      SetMsg(TG_NAME[i] + " badlav cancel");
      UpdatePanel();
      return;
   }
   TG[i] = nv;
   SaveCfg();
   PaintToggle(i);
   string m = TG_NAME[i] + (nv ? " ON" : " OFF") + " saved";
   if(!TG[TG_TREND] && !TG[TG_RANGE])
      m += "  |  TREND / RANGE dono OFF - naye trade nahi khulenge";
   else if(!TG[TG_MKT] && !TG[TG_LIM] && !TG[TG_STP])
      m += "  |  MARKET / LIMIT / STOP sab OFF - naye trade nahi khulenge";
   SetMsg(m);
   gForceCheck = true;
   UpdateState();
   UpdatePanel();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(StringFind(sparam, PFX) != 0) return;
   string n = StringSubstr(sparam, StringLen(PFX));

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_BUTTON)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

      if(n == "btnMin")      { gMin = true;  SaveCfg(); BuildPanel(); }
      else if(n == "btnMax") { gMin = false; SaveCfg(); BuildPanel(); }
      else if(n == "btnSet") { gSetOpen = !gSetOpen; SaveCfg(); BuildPanel(); }
      else if(n == "btnTrade")
      {
         bool nv = !gTradingOn;
         if(Confirm(string("Trading ") + (gTradingOn ? "ON" : "OFF") + "  ->  " + (nv ? "ON" : "OFF")))
         {
            gTradingOn = nv;
            SaveCfg();
            SetMsg(nv ? "Trading ON - EA naye trade lega"
                      : "Trading OFF - pending hatenge, khule trades manage hote rahenge");
            gForceCheck = true;
         }
         UpdateState();
         UpdatePanel();
      }
      else if(n == "btnDef")
      {
         if(Confirm("Saari panel settings DEFAULT (EA inputs) par wapas?"))
         {
            LoadDefaults();
            SaveCfg();
            ParkPending("DEFAULTS dabaya");
            gForceCheck = true;
            SetMsg("DEFAULTS laga diye (EA inputs wali values)");
            BuildPanel();
         }
      }
      else if(StringSubstr(n, 0, 2) == "tg")
      {
         int i = (int)StringToInteger(StringSubstr(n, 2));
         if(i >= 0 && i < TG_COUNT) OnToggle(i);
      }
      ChartRedraw();
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(StringSubstr(n, 0, 2) == "ed")
      {
         int i = (int)StringToInteger(StringSubstr(n, 2));
         if(i >= 0 && i < ST_COUNT) OnEditDone(i, sparam);
      }
   }
}

//+------------------------------------------------------------------+
//| Init / Deinit / Tick / Timer                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints((ulong)InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   hADX = iADX(_Symbol, InpTF, InpADXPeriod);
   hATR = iATR(_Symbol, InpTF, 14);
   hEMA = iMA(_Symbol, InpTF, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(hADX == INVALID_HANDLE || hATR == INVALID_HANDLE || hEMA == INVALID_HANDLE)
   {
      Print(EA_NAME, " indicator handle nahi bana");
      return INIT_FAILED;
   }

   gScale = MathMax(0.6, MathMin(2.5, InpPanelScale));
   gK = gScale * (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

   string sym = _Symbol;
   StringReplace(sym, "#", "_");
   StringReplace(sym, "/", "_");
   gCfgFile = "BTCGOLD_EA_" + IntegerToString(InpMagic) + "_" + sym + ".cfg";

   LoadDefaults();
   LoadCfg();
   DeleteOldFormat();
   RebuildUsed();

   // pichla market entry time (MinCandleGap ke liye)
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      datetime pt = (datetime)PositionGetInteger(POSITION_TIME);
      if(pt > gLastMktEntry) gLastMktEntry = pt;
   }

   Comment("");
   ChartSetInteger(0, CHART_FOREGROUND, false);
   gLastBar = 0;
   gForceCheck = true;
   UpdateState();
   BuildPanel();
   EventSetTimer(1);

   Print(EA_NAME, " ", EA_VER, " start | ", _Symbol, " ", EnumToString(InpTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpTF),
         " | ", (IsReal() ? "REAL" : "DEMO"), " | settings file: MQL5\\Files\\", gCfgFile);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, PFX);
   Comment("");
   if(hADX != INVALID_HANDLE) IndicatorRelease(hADX);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hEMA != INVALID_HANDLE) IndicatorRelease(hEMA);
   ChartRedraw();
}

void OnTick()
{
   UpdateState();
   if(gDayLossHit && InpCloseAllOnDayLoss && (gBuys + gSells) > 0)
   {
      CloseAll();
      UpdateState();
   }

   ManagePositions();

   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt != gLastBar) { gLastBar = bt; gForceCheck = true; }
   if(gForceCheck)
   {
      gForceCheck = false;
      ManageEntries();
   }
}

void OnTimer()
{
   UpdateState();
   UpdatePanel();
}
//+------------------------------------------------------------------+
