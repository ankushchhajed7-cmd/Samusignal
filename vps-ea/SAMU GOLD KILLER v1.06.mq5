//+------------------------------------------------------------------+
//|                                   SAMU GOLD KILLER v1.06.mq5       |
//|                                   Ankush New Vision                |
//|                                                                    |
//|  "GOLD KILLER V10" (MT4, InstaForex 72929366, magic 666888) ka     |
//|  MT5 clone. Rules = 16 din ki history (2267 trades) + 3 ghante ka  |
//|  Live Record (har tick + har order) se nikale, simulator se match: |
//|  lot 27/27, pending lagna 21/22, fill 23/27, basket $30 3/4.       |
//|                                                                    |
//|  KAAM (BUY side; SELL bilkul ulta, dono saath + alag chalte hain): |
//|   1) Market BUY nahi - BUY STOP lagta hai Ask + PendingDistance    |
//|      ($0.80) par.                                                  |
//|   2) Price neeche jaye to BUY STOP bhi neeche khiskta hai (hamesha |
//|      Ask + $0.80), kam se kam TrailStep ($0.05) ke step me.        |
//|   3) Price $0.80 wapas uthe -> stop lag jata hai (girte gold ko    |
//|      palat'te hi pakadna).                                         |
//|   4) Agla level: naye BUY STOP ki price pichhle (sabse neeche)     |
//|      BUY se kam se kam MinGridGap ($0.80) neeche ho tabhi lagta.   |
//|   5) Lot = StartLot x 1.3^(level-1), 2 decimal round:              |
//|      0.01 0.01 0.02 0.02 0.03 0.04 0.05 0.06 0.08 0.11 0.14 0.18   |
//|      0.23 0.30 0.39 0.51 0.67 0.87 ...                             |
//|   6) Side ka floating profit >= BasketTP_USD ($30) -> us side ke   |
//|      sab trade band + pending delete -> turant naya 0.01 BUY STOP. |
//|                                                                    |
//|  SAFETY (original me nahi tha, 22 level tak bina SL jata tha):     |
//|   MaxLevels, MaxLossUSD (side ka loss -> basket band), MaxSpread   |
//|   (default OFF - original me spread filter nahi tha).              |
//|  NEWS FILTER (v1.01): high-impact USD news se 30 min pehle + 30    |
//|   min baad naya pending nahi, purana pending delete. Khule trade   |
//|   ka $30 TP / MaxLoss chalta rehta hai.                            |
//|  OPTIONAL: H1 trailing SL (1-trade basket) - default OFF.          |
//|                                                                    |
//|  DHYAN: Account HEDGING hona chahiye (BUY + SELL saath).           |
//|  Distance $ me hain (InstaForex GOLD 80 points = $0.80), isliye    |
//|  XAUUSDm (3 digit) / XAUUSD (2 digit) dono par same chalega.       |
//|                                                                    |
//|  CHANGELOG                                                         |
//|  v1.06 (25-Nov-2026) TOKEN PASTE KI ZAROORAT NAHI:                 |
//|   - GitHubToken khaali chhodo. Dashboard par JODO CODE dikhta hai  |
//|     (jaise K7M-3QX-9PA). App > Settings > "EA jodo" me code likho. |
//|     App token ko is code se lock karke live/pair.json me bhejta    |
//|     hai; EA har 30 sec dekhta hai, khol ke VPS par save karta hai  |
//|     (MQL5\Files Common, SGK_tok_<magic>.txt) aur pair.json mitata. |
//|   - Token galat / expire (401) -> file mit ke naya code.           |
//|   - Token input me daala ho to wahi chalega (purana tareeka).      |
//|  v1.05 (25-Nov-2026) APP CONTROL (repo SAMU-GOLD-KILLER-COMMAND):  |
//|   - ControlMode APP: nayi basket sirf START ke baad. START app se  |
//|     (GitHub live branch control.json) ya chart ke START button se. |
//|     START = window (30/60/90 min) + max TP (default 2). Max TP ya   |
//|     window khatam -> nayi basket band. Window ke baad jo basket    |
//|     EndCloseUSD ($1) ya zyada profit me ho -> turant band.         |
//|     App commands: START / STOP / CLOSE_BUY / CLOSE_SELL / CLOSE_ALL|
//|     (10 min se purana command ignore). FIXED = v1.04 jaisa samay.  |
//|   - Shaant check: pichhle 30 min ka range $5 se zyada -> nayi      |
//|     basket nahi (Lab: 101 din me account saaf 0 baar).             |
//|   - Deep bounce: basket L8 -> naye chhote level band, 0.20 lot ke  |
//|     max 2 bounce STOP ($2 door, $2 gap), side $15 profit par band, |
//|     $4000 loss par band.                                           |
//|   - Har 30 sec status.json (equity, basket, 120 M1 bar, news,      |
//|     trades) app ko. MT5: Tools > Options > Expert Advisors >       |
//|     Allow WebRequest: https://api.github.com                       |
//|   - Tester me APP mode: Session1/Session2 shuru par khud START.    |
//|  v1.04 (18-Nov-2026) TRADE TIME + RAAT KI NEWS (18 Nov ko ~$35 ki  |
//|   giravat me BUY basket L16 tak gayi, equity DD 14.5%):            |
//|   - Nayi basket (pehla L1 pending) sirf IST 09:00-10:30 aur        |
//|     22:30-00:30 me. Bahar: nayi basket nahi, L1 pending hat jaata. |
//|     Khuli basket level jodti rehti hai + $30 TP chalu.             |
//|   - Raat 9 baje (IST) ke baad 3 baje tak koi HIGH USD news ya Fed  |
//|     (FOMC / Fed Chair / Powell / rate decision) ho to us din ki    |
//|     RAAT wali trading OFF, sirf subah. Dashboard par kaaran.       |
//|   - Purana +-30 min news filter waisa hi (har samay).              |
//|   - 2 mahine ke H1 data: 18:30-21:30 IST sabse tez ($22-26/ghanta),|
//|     09:30 ~$13, 22:30-00:30 ~$13-16.                               |
//|  v1.03 (18-Nov-2026) Dashboard door se padhne layak: bade + BOLD  |
//|   akshar (min 10pt, input TextScale), chamkile rang, hara highlight|
//|   (ALL CLEAR banner + profit), kam lines (info/drawdown line hata  |
//|   kar DETAILS me), table bold.                                     |
//|  v1.02 (18-Nov-2026) Dashboard ab FULL SCREEN: poora chart window, |
//|   candles chhupi (HideChart), har window size + Windows scaling   |
//|   (DPI) par khud fit - v1.01 me laptop par akshar chadh gaye the.  |
//|   Neeche: trade table (left) + DETAILS (next BUY/SELL, avg, grid,  |
//|   spread, news, max levels, max loss, magic). EA hatane par chart  |
//|   wapas normal.                                                    |
//|  v1.01 (18-Nov-2026) "Gold Luxe" dashboard (kaala + sona): equity, |
//|   IST/server time, status banner, BUY/SELL/TODAY/CYCLES, $30 TP    |
//|   bars, drawdown bar, next grid + spread + news line, trade table, |
//|   PAUSE / CLOSE BUY / CLOSE SELL / CLOSE ALL buttons.              |
//|   News filter +-30 min (MT5 Economic Calendar, USD, High).         |
//|   Spread filter OFF hi (original jaisa).                           |
//|  v1.00 (18-Nov-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.06"

#include <Trade\Trade.mqh>

//--- inputs
input group "=== Side ==="
input bool   EnableBuy          = true;    // BUY grid (BUY STOP)
input bool   EnableSell         = true;    // SELL grid (SELL STOP)

input group "=== Pending / Grid ($ distance) ==="
input double PendingDistance    = 0.80;    // Pending market se kitna door ($)
input double MinGridGap         = 0.80;    // Naya level pichhle trade se kam se kam ($)
input double TrailStep          = 0.05;    // Pending trail ka min step ($)

input group "=== Lot ==="
input double StartLot           = 0.01;    // Pehla lot
input double LotMultiplier      = 1.3;     // Martingale multiplier
input int    LotDigits          = 2;       // Lot rounding digits

input group "=== Exit ==="
input double BasketTP_USD       = 30.0;    // Side basket profit target ($)

input group "=== Safety (0 = off) ==="
input int    MaxLevels          = 22;      // Max trades per side (0 = unlimited)
input double MaxLossUSD         = 0.0;     // Side ka loss itna -> basket band ($)
input double MaxSpreadUSD       = 0.0;     // Spread isse zyada -> naya pending/trail nahi ($) (0 = off, original jaisa)

input group "=== News filter ==="
input bool   UseNewsFilter      = true;    // High-impact news ke aas-paas naya pending band
input int    NewsBeforeMin      = 30;      // News se kitne minute pehle
input int    NewsAfterMin       = 30;      // News ke kitne minute baad
input string NewsCurrencies     = "USD";   // Currency (comma se: USD,EUR)
input bool   NewsHighOnly       = true;    // true = sirf High, false = Medium + High

input group "=== Trade Time (IST) - v1.04 ==="
input bool   UseTradeTime       = true;            // Nayi basket sirf neeche ke samay me
input string Session1           = "09:00-10:30";   // Subah (IST)
input string Session2           = "22:30-00:30";   // Raat (IST, aadhi raat paar chal sakta hai)
input bool   NightNewsSkip      = true;            // Raat 9 ke baad badi news / Fed -> us din raat OFF
input string NightNewsFrom      = "21:00";         // Is samay (IST) se...
input string NightNewsTo        = "03:00";         // ...is samay (agle din, IST) tak ki news dekho
input string FedWords           = "FOMC,Fed Chair,Powell,Federal Funds,Interest Rate Decision"; // Fed ki khabar (koi bhi importance)

enum ENUM_SGK_CTRL
{
   CTRL_APP   = 0,   // APP: App / chart ke START button se (v1.05)
   CTRL_FIXED = 1    // FIXED: Session1/Session2 (v1.04 jaisa)
};

input group "=== App Control (v1.05) ==="
input ENUM_SGK_CTRL ControlMode = CTRL_APP;      // Nayi basket kab
input string GitHubToken        = "";            // KHAALI CHHODO - app ke "EA jodo" code se token khud aata hai
input string GitHubRepo         = "ankushchhajed7-cmd/SAMU-GOLD-KILLER-COMMAND"; // Repo
input string GitHubBranch       = "live";        // Live branch (control.json / status.json)
input int    PollSec            = 15;            // Kitne sec me command dekho
input int    StatusSec          = 30;            // Kitne sec me status bhejo
input int    CmdExpiryMin       = 10;            // Isse purana command ignore (min)
input int    DefaultWindowMin   = 60;            // Chart START button: window (min)
input int    DefaultMaxTP       = 2;             // Chart START button: max TP
input double EndCloseUSD        = 1.0;           // Window ke baad basket profit >= ye ($) -> band (-1 = off)

input group "=== Shaant check (v1.05) ==="
input double CalmRangeUSD       = 5.0;           // Pichhle CalmMinutes ka range isse kam -> tabhi nayi basket (0 = off)
input int    CalmMinutes        = 30;            // Kitne minute dekho

input group "=== Deep bounce (v1.05) ==="
input bool   UseDeepBounce      = true;          // Gehri basket ka alag niyam
input int    DeepFromLevel      = 8;             // Is level se deep mode
input double DeepLot            = 0.20;          // Bounce trade lot
input double DeepDistance       = 2.0;           // Bounce STOP market se ($)
input double DeepGap            = 2.0;           // Bounce trade pichhle trade se kam se kam ($)
input int    DeepMaxTrades      = 2;             // Max bounce trade
input double DeepTP_USD         = 15.0;          // Deep basket profit >= ye -> band ($)
input double DeepHardLossUSD    = 4000.0;        // Deep basket loss >= ye -> band ($, 0 = off)

input group "=== Optional: H1 trailing SL (1-trade basket) ==="
input bool   UseH1TrailSL       = false;   // Naye H1 candle par SL = pichhli H1 candle high/low (sirf profit lock ho to)

input group "=== General ==="
input long   MagicNumber        = 20261118;
input string OrderComment       = "SAMU GOLD KILLER";
input bool   ShowPanel          = true;    // Gold Luxe dashboard (full screen)
input bool   HideChart          = true;    // Candles chhupao - poora chart dashboard
input bool   BlinkAlerts        = true;    // Laal alert banner blink kare (v1.05)
input double TextScale          = 1.0;     // Akshar bade/chhote (1.2 = 20% bade)
input int    MinFontSize        = 10;      // Sabse chhota akshar (pt)

CTrade   trade;
datetime lastH1      = 0;
datetime lastErrTime = 0;
bool     paused      = false;
string   gvPause;

//--- news cache
datetime newsTime[];
string   newsName[];
datetime newsLoaded  = 0;
bool     newsBlock   = false;
string   newsText    = "Clear";

//--- v1.04 trade time + raat ki news
datetime nightTime[];
string   nightName[];
bool     inTime      = true;
bool     nightOff    = false;
string   nightWhy    = "";
string   timeText    = "Off";

//--- v1.05 app control
bool     armed       = false;
long     armT0       = 0, armEnd = 0;            // GMT epoch
int      armTP       = 0, armMaxTP = 0;
double   lastCmdId   = 0;
string   lastCmdName = "", lastCmdRes = "";
long     lastCmdT    = 0;
long     lastPoll    = 0, lastPush = 0, lastAutoArm = 0;
bool     pushNow     = true;
string   statusSha   = "";
bool     linkOk      = false;
string   linkText    = "Off (token nahi)";
long     linkAt      = 0;
bool     calmOk      = true;
double   calmRange   = 0;
string   gvArm;
//--- v1.06 jodo code
string   ghTok       = "";
bool     tokFromFile = false;
string   pairCode    = "", pairShow = "", pairId = "";
long     lastPair    = 0;

//--- today stats cache
double   todayPL     = 0;
int      todayCycles = 0;
datetime statsAt     = 0;
double   worstFloat  = 0;
int      worstDay    = -1;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.LogLevel(LOG_LEVEL_ERRORS);
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      Print("SAMU GOLD KILLER: WARNING - account HEDGING nahi hai, BUY+SELL saath nahi chal payenge");
   lastH1 = iTime(_Symbol, PERIOD_H1, 0);
   gvPause = "SGK_PAUSE_" + IntegerToString(MagicNumber) + "_" + _Symbol;
   paused = GlobalVariableCheck(gvPause) && GlobalVariableGet(gvPause) > 0.5;
   gvArm  = "SGK5_" + IntegerToString(MagicNumber) + "_" + _Symbol + "_";
   LoadArm();                                             // v1.05
   InitToken();                                           // v1.06
   if(RemoteOn()) linkText = "Jud raha hai...";
   Comment("");
   SetupChart();
   LoadNews();
   UpdateTime();                                          // v1.04
   EventSetTimer(1);
   if(ShowPanel) Panel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, "SGK_");
   RestoreChart();
   Comment("");
}

void OnTimer()
{
   if(TimeCurrent() - newsLoaded > 600) LoadNews();
   UpdateNews();
   UpdateTime();                                          // v1.04
   UpdateCalm();                                          // v1.05
   Remote();                                              // v1.05
   if(ShowPanel) Panel();
}

//+------------------------------------------------------------------+
double NormLot(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lot = NormalizeDouble(lot, LotDigits);
   if(step > 0) lot = MathRound(lot / step) * step;
   lot = MathMax(mn, MathMin(mx, lot));
   return NormalizeDouble(lot, 8);
}

double LevelLot(int level)                     // level 1,2,3...
{
   return NormLot(StartLot * MathPow(LotMultiplier, level - 1));
}

double NormPrice(double p)
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) ts = _Point;
   return NormalizeDouble(MathRound(p / ts) * ts, _Digits);
}

//--- side info: 0 = BUY, 1 = SELL
struct SideInfo
{
   int      count;
   double   lots;
   double   profit;
   double   extreme;     // BUY: sabse neeche open, SELL: sabse upar open
   double   avg;
   ulong    pendTicket;
   double   pendPrice;
   double   pendLot;
   int      pendCount;
};

void Collect(int side, SideInfo &s, bool fixDup = true)
{
   s.count = 0; s.lots = 0; s.profit = 0; s.extreme = 0; s.avg = 0;
   s.pendTicket = 0; s.pendPrice = 0; s.pendLot = 0; s.pendCount = 0;
   double pv = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if((side == 0 && type != POSITION_TYPE_BUY) || (side == 1 && type != POSITION_TYPE_SELL)) continue;
      double op = PositionGetDouble(POSITION_PRICE_OPEN), v = PositionGetDouble(POSITION_VOLUME);
      s.count++;
      s.lots   += v;
      pv       += op * v;
      s.profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(s.count == 1) s.extreme = op;
      else s.extreme = (side == 0) ? MathMin(s.extreme, op) : MathMax(s.extreme, op);
   }
   if(s.lots > 0) s.avg = pv / s.lots;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      long type = OrderGetInteger(ORDER_TYPE);
      if((side == 0 && type != ORDER_TYPE_BUY_STOP) || (side == 1 && type != ORDER_TYPE_SELL_STOP)) continue;
      s.pendCount++;
      if(s.pendTicket == 0)
      {
         s.pendTicket = t;
         s.pendPrice  = OrderGetDouble(ORDER_PRICE_OPEN);
         s.pendLot    = OrderGetDouble(ORDER_VOLUME_CURRENT);
      }
      else if(fixDup)
         trade.OrderDelete(t);                 // ek side ka sirf ek pending
   }
}

void DeletePending(int side)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      long type = OrderGetInteger(ORDER_TYPE);
      if((side == 0 && type == ORDER_TYPE_BUY_STOP) || (side == 1 && type == ORDER_TYPE_SELL_STOP))
         trade.OrderDelete(t);
   }
}

void CloseSide(int side, string why)
{
   DeletePending(side);                         // pehle pending hatao, phir positions
   for(int pass = 0; pass < 3; pass++)
   {
      int left = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         long type = PositionGetInteger(POSITION_TYPE);
         if((side == 0 && type != POSITION_TYPE_BUY) || (side == 1 && type != POSITION_TYPE_SELL)) continue;
         if(!trade.PositionClose(t)) left++;
      }
      if(left == 0) break;
      Sleep(300);
   }
   statsAt = 0;                                 // dashboard stats turant refresh
   pushNow = true;                              // v1.05: app ko turant khabar
   Print("SAMU GOLD KILLER: ", (side == 0 ? "BUY" : "SELL"), " basket band - ", why);
}

double SpreadUSD()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

bool SpreadOk()
{
   if(MaxSpreadUSD <= 0) return true;
   return SpreadUSD() <= MaxSpreadUSD + 1e-9;
}

double MinStopDist()
{
   long lvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long frz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(lvl, frz) * _Point + _Point;
}

//+------------------------------------------------------------------+
//| NEWS FILTER (MT5 Economic Calendar, time = trade server time)     |
//+------------------------------------------------------------------+
void LoadNews()
{
   newsLoaded = TimeCurrent();
   ArrayResize(newsTime, 0);
   ArrayResize(newsName, 0);
   LoadNightNews();                                      // v1.04
   if(!UseNewsFilter || MQLInfoInteger(MQL_TESTER)) return;
   datetime now = TimeTradeServer();
   string cur[];
   int nc = StringSplit(NewsCurrencies, ',', cur);
   for(int c = 0; c < nc; c++)
   {
      string ccy = cur[c];
      StringTrimLeft(ccy); StringTrimRight(ccy);
      if(ccy == "") continue;
      MqlCalendarValue vals[];
      ResetLastError();
      CalendarValueHistory(vals, now - 6 * 3600, now + 36 * 3600, NULL, ccy);
      int n = ArraySize(vals);
      for(int i = 0; i < n; i++)
      {
         MqlCalendarEvent ev;
         if(!CalendarEventById(vals[i].event_id, ev)) continue;
         bool imp = (ev.importance == CALENDAR_IMPORTANCE_HIGH) || (!NewsHighOnly && ev.importance == CALENDAR_IMPORTANCE_MODERATE);
         if(!imp) continue;
         int k = ArraySize(newsTime);
         ArrayResize(newsTime, k + 1);
         ArrayResize(newsName, k + 1);
         newsTime[k] = vals[i].time;
         newsName[k] = ccy + " " + ev.name;
      }
   }
}

string IstHM(datetime serverTime)
{
   // server time -> IST (offset = TimeTradeServer - TimeGMT)
   long off = (long)TimeTradeServer() - (long)TimeGMT();
   datetime ist = (datetime)((long)serverTime - off + 19800);
   return TimeToString(ist, TIME_MINUTES);
}

void UpdateNews()
{
   newsBlock = false;
   newsText  = UseNewsFilter ? "Clear" : "Off";
   if(!UseNewsFilter || MQLInfoInteger(MQL_TESTER)) { if(MQLInfoInteger(MQL_TESTER)) newsText = "Tester (off)"; return; }
   datetime now = TimeTradeServer();
   datetime nextT = 0; string nextN = "";
   for(int i = 0; i < ArraySize(newsTime); i++)
   {
      datetime t = newsTime[i];
      if(now >= t - NewsBeforeMin * 60 && now <= t + NewsAfterMin * 60)
      {
         newsBlock = true;
         newsText  = "BLOCK " + newsName[i] + " " + IstHM(t) + " IST (till " + IstHM(t + NewsAfterMin * 60) + ")";
         return;
      }
      if(t > now && (nextT == 0 || t < nextT)) { nextT = t; nextN = newsName[i]; }
   }
   if(nextT > 0)
   {
      int mins = (int)((nextT - now) / 60);
      if(mins < 360) newsText = "Next " + nextN + " " + IstHM(nextT) + " IST (" + IntegerToString(mins) + " min)";
   }
}


//+------------------------------------------------------------------+
//| v1.04 TRADE TIME (IST) + RAAT KI NEWS                             |
//+------------------------------------------------------------------+
bool HasWord(string name, string words)
{
   string low = name; StringToLower(low);
   string w[]; int n = StringSplit(words, ',', w);
   for(int i = 0; i < n; i++)
   {
      string x = w[i]; StringTrimLeft(x); StringTrimRight(x); StringToLower(x);
      if(x != "" && StringFind(low, x) >= 0) return true;
   }
   return false;
}

void LoadNightNews()
{
   ArrayResize(nightTime, 0);
   ArrayResize(nightName, 0);
   if(!UseTradeTime || !NightNewsSkip || MQLInfoInteger(MQL_TESTER)) return;
   datetime now = TimeTradeServer();
   string cur[];
   int nc = StringSplit(NewsCurrencies, ',', cur);
   for(int c = 0; c < nc; c++)
   {
      string ccy = cur[c];
      StringTrimLeft(ccy); StringTrimRight(ccy);
      if(ccy == "") continue;
      MqlCalendarValue vals[];
      CalendarValueHistory(vals, now - 14 * 3600, now + 40 * 3600, NULL, ccy);
      for(int i = 0; i < ArraySize(vals); i++)
      {
         MqlCalendarEvent ev;
         if(!CalendarEventById(vals[i].event_id, ev)) continue;
         bool big = (ev.importance == CALENDAR_IMPORTANCE_HIGH) || (ccy == "USD" && HasWord(ev.name, FedWords));
         if(!big) continue;
         int k = ArraySize(nightTime);
         ArrayResize(nightTime, k + 1);
         ArrayResize(nightName, k + 1);
         nightTime[k] = vals[i].time;
         nightName[k] = ccy + " " + ev.name;
      }
   }
}

int HM(string t)                                          // "HH:MM" -> minute (galat ho to -1)
{
   StringTrimLeft(t); StringTrimRight(t);
   string p[];
   if(StringSplit(t, ':', p) != 2) return -1;
   int h = (int)StringToInteger(p[0]), m = (int)StringToInteger(p[1]);
   if(h < 0 || h > 24 || m < 0 || m > 59) return -1;
   return (h * 60 + m) % 1440;
}

bool ParseSess(string sess, int &a, int &b)
{
   string p[];
   a = -1; b = -1;
   if(StringSplit(sess, '-', p) != 2) return false;
   a = HM(p[0]); b = HM(p[1]);
   return (a >= 0 && b >= 0 && a != b);
}

bool InSess(int m, int a, int b)
{
   if(a < 0 || b < 0) return false;
   if(a < b) return (m >= a && m < b);
   return (m >= a || m < b);                              // aadhi raat paar
}

string HMs(int m) { return StringFormat("%02d:%02d", (m / 60) % 24, m % 60); }

void UpdateTime()
{
   if(ControlMode == CTRL_APP)                            // v1.05: START se window
   {
      long now = (long)TimeGMT();
      if(MQLInfoInteger(MQL_TESTER) && !armed)            // tester: har session ke shuru me khud START
      {
         long ist = now + 19800; int m = (int)((ist % 86400) / 60);
         int a1, b1, a2, b2;
         bool s1 = ParseSess(Session1, a1, b1) && m == a1, s2 = ParseSess(Session2, a2, b2) && m == a2;
         if((s1 || s2) && now / 60 != lastAutoArm) { lastAutoArm = now / 60; Arm(DefaultWindowMin, DefaultMaxTP); lastCmdName = "START (tester)"; }
      }
      if(armed && now >= armEnd) Disarm("window khatam");
      nightOff = false; nightWhy = "";
      inTime = armed && armTP < armMaxTP;
      if(armed) timeText = StringFormat("START · %s tak · TP %d/%d", GmtHM(armEnd), armTP, armMaxTP);
      else      timeText = "STANDBY · App se START";
      return;
   }
   if(!UseTradeTime) { inTime = true; nightOff = false; nightWhy = ""; timeText = "Off (24 ghante)"; return; }
   long ist = (long)TimeGMT() + 19800;
   int  m   = (int)((ist % 86400) / 60);
   long day0 = ist - ist % 86400;                         // aaj IST 00:00
   int a1, b1, a2, b2;
   bool ok1 = ParseSess(Session1, a1, b1);
   bool ok2 = ParseSess(Session2, a2, b2);
   bool in1 = ok1 && InSess(m, a1, b1);
   bool in2 = ok2 && InSess(m, a2, b2);

   // kaunsi raat: aadhi raat ke baad wala hissa kal ki raat ka hai
   nightOff = false; nightWhy = "";
   if(ok2 && NightNewsSkip && !MQLInfoInteger(MQL_TESTER))
   {
      long nightDay = day0;
      if(a2 > b2 && m < b2) nightDay -= 86400;
      int f = HM(NightNewsFrom), t = HM(NightNewsTo);
      if(f < 0) f = 21 * 60;
      if(t < 0) t = 3 * 60;
      long fromIst = nightDay + f * 60;
      long toIst   = nightDay + t * 60 + (t <= f ? 86400 : 0);
      long off = (long)TimeTradeServer() - (long)TimeGMT();
      long fromSrv = fromIst - 19800 + off, toSrv = toIst - 19800 + off;
      for(int i = 0; i < ArraySize(nightTime); i++)
      {
         long nt = (long)nightTime[i];
         if(nt >= fromSrv && nt <= toSrv)
         {
            nightOff = true;
            nightWhy = nightName[i] + " " + IstHM(nightTime[i]) + " IST";
            break;
         }
      }
   }
   inTime = in1 || (in2 && !nightOff);

   if(inTime)
   {
      int end = in1 ? b1 : b2;
      timeText = "ON  ·  " + HMs(end) + " tak";
      return;
   }
   // agla samay
   int best = 100000; string nm = "";
   if(ok1) { int d = (a1 - m + 1440) % 1440; if(d < best) { best = d; nm = HMs(a1); } }
   if(ok2)
   {
      int d = (a2 - m + 1440) % 1440;
      bool tonightOff = nightOff && !(a2 > b2 && m < b2) && d < 1440;   // aaj ki raat hi band hai
      if(!tonightOff && d < best) { best = d; nm = HMs(a2); }
   }
   timeText = "OFF  ·  agla " + nm + " IST";
}

//+------------------------------------------------------------------+
void HandleSide(int side)
{
   bool enabled = (side == 0) ? EnableBuy : EnableSell;
   SideInfo s;
   Collect(side, s);
   bool deep = UseDeepBounce && DeepFromLevel > 0 && s.count >= DeepFromLevel;   // v1.05

   // 1) basket exit (pause / news me bhi chalta hai)
   if(s.count > 0 && !deep && s.profit >= BasketTP_USD)
   {
      CloseSide(side, StringFormat("TP $%.2f (%d trades)", s.profit, s.count));
      if(ControlMode == CTRL_APP && armed) { armTP++; SaveArm(); }   // v1.05: is START ka TP
      return;
   }
   if(deep && s.profit >= DeepTP_USD)                    // v1.05 deep bounce
   {
      CloseSide(side, StringFormat("DEEP TP $%.2f (%d trades)", s.profit, s.count));
      return;
   }
   if(deep && DeepHardLossUSD > 0 && s.profit <= -DeepHardLossUSD)
   {
      CloseSide(side, StringFormat("DEEP HARD $%.2f (%d trades)", s.profit, s.count));
      return;
   }
   if(s.count > 0 && MaxLossUSD > 0 && s.profit <= -MaxLossUSD)
   {
      CloseSide(side, StringFormat("MaxLoss $%.2f (%d trades)", s.profit, s.count));
      return;
   }
   // v1.05: window ke baad (ya STOP ke baad) basket thoda bhi profit me -> band
   if(ControlMode == CTRL_APP && EndCloseUSD >= 0 && s.count > 0 && !WindowOpen() && s.profit >= EndCloseUSD)
   {
      CloseSide(side, StringFormat("Window ke baad profit $%.2f (%d trades)", s.profit, s.count));
      return;
   }

   // 2) naya pending band: side off / PAUSE / news / max levels / samay / shaant check
   bool calmBlock = (s.count == 0 && CalmRangeUSD > 0 && !calmOk);                  // v1.05
   if(!enabled || paused || newsBlock || (MaxLevels > 0 && s.count >= MaxLevels) || (s.count == 0 && !inTime) || calmBlock)
   {
      if(s.pendTicket != 0) DeletePending(side);
      return;
   }
   if(TimeCurrent() - lastErrTime < 3) return;            // error ke baad thoda ruko
   if(!SpreadOk()) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist, gap, lot; string cmt;
   if(deep)
   {
      int nb = DeepCount(side);
      if(nb >= DeepMaxTrades) { if(s.pendTicket != 0) DeletePending(side); return; }
      dist = MathMax(DeepDistance, MinStopDist());
      gap  = DeepGap;
      lot  = NormLot(DeepLot);
      cmt  = OrderComment + " D" + IntegerToString(nb + 1);
   }
   else
   {
      dist = MathMax(PendingDistance, MinStopDist());
      gap  = MinGridGap;
      lot  = LevelLot(s.count + 1);
      cmt  = OrderComment + " L" + IntegerToString(s.count + 1);
   }
   double want = NormPrice(side == 0 ? ask + dist : bid - dist);

   // 3) pending trail (sirf market ki taraf, kabhi peeche nahi)
   if(s.pendTicket != 0)
   {
      bool better = (side == 0) ? (want <= s.pendPrice - TrailStep + 1e-9) : (want >= s.pendPrice + TrailStep - 1e-9);
      if(MathAbs(s.pendLot - lot) > 1e-9)               // level badal gaya (jaise manual close / deep mode) -> sahi lot se dubara
      {
         trade.OrderDelete(s.pendTicket);
         return;
      }
      if(better)
      {
         if(s.count > 0)
         {
            bool gapOk = (side == 0) ? (want <= s.extreme - gap + 1e-9) : (want >= s.extreme + gap - 1e-9);
            if(!gapOk) return;
         }
         if(!trade.OrderModify(s.pendTicket, want, 0, 0, ORDER_TIME_GTC, 0))
            lastErrTime = TimeCurrent();
      }
      return;
   }

   // 4) naya pending
   if(s.count > 0)
   {
      bool gapOk = (side == 0) ? (want <= s.extreme - gap + 1e-9) : (want >= s.extreme + gap - 1e-9);
      if(!gapOk) return;
   }
   bool ok = (side == 0) ? trade.BuyStop(lot, want, _Symbol, 0, 0, ORDER_TIME_GTC, 0, cmt)
                         : trade.SellStop(lot, want, _Symbol, 0, 0, ORDER_TIME_GTC, 0, cmt);
   if(!ok) lastErrTime = TimeCurrent();
}

int DeepCount(int side)                                   // v1.05: bounce trades (comment " D")
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if((side == 0 && type != POSITION_TYPE_BUY) || (side == 1 && type != POSITION_TYPE_SELL)) continue;
      string c = PositionGetString(POSITION_COMMENT);
      if(StringFind(c, " D") >= 0 || MathAbs(PositionGetDouble(POSITION_VOLUME) - NormLot(DeepLot)) < 1e-9) n++;
   }
   return n;
}

//--- optional: naye H1 bar par 1-trade basket ka SL pichhli H1 candle ke high/low par (sirf profit lock ho to)
void H1Trail()
{
   datetime h1 = iTime(_Symbol, PERIOD_H1, 0);
   if(h1 == 0 || h1 == lastH1) return;
   lastH1 = h1;
   double hi = iHigh(_Symbol, PERIOD_H1, 1), lo = iLow(_Symbol, PERIOD_H1, 1);
   if(hi <= 0 || lo <= 0) return;
   for(int side = 0; side < 2; side++)
   {
      SideInfo s;
      Collect(side, s);
      if(s.count != 1) continue;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         long type = PositionGetInteger(POSITION_TYPE);
         double op = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(side == 0 && type == POSITION_TYPE_BUY)
         {
            double nsl = NormPrice(lo);
            if(nsl > op && (sl == 0 || nsl > sl) && nsl < bid - MinStopDist())
               trade.PositionModify(t, nsl, PositionGetDouble(POSITION_TP));
         }
         if(side == 1 && type == POSITION_TYPE_SELL)
         {
            double nsl = NormPrice(hi);
            if(nsl < op && (sl == 0 || nsl < sl) && nsl > ask + MinStopDist())
               trade.PositionModify(t, nsl, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   UpdateCalm();                                          // v1.05
   HandleSide(0);
   HandleSide(1);
   if(UseH1TrailSL) H1Trail();
}

//+------------------------------------------------------------------+
//| BUTTONS                                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE) { if(ShowPanel) Panel(); return; }
   if(id != CHARTEVENT_OBJECT_CLICK || StringFind(sparam, "SGK_BTN_") != 0) return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   if(sparam == "SGK_BTN_PAUSE" && ControlMode == CTRL_APP)    // v1.05: chart se START / STOP
   {
      if(armed) { Disarm("chart STOP"); lastCmdName = "STOP (chart)"; lastCmdRes = "OK · nayi basket band"; }
      else if(MessageBox(StringFormat("START karein?\nWindow %d min · Max %d TP\nShaant check: 30 min range $%.1f / $%.1f", DefaultWindowMin, DefaultMaxTP, calmRange, CalmRangeUSD),
                         "SAMU GOLD KILLER", MB_YESNO | MB_ICONQUESTION) == IDYES)
      { Arm(DefaultWindowMin, DefaultMaxTP); paused = false; GlobalVariableSet(gvPause, 0.0); lastCmdName = "START (chart)"; lastCmdRes = StringFormat("OK · %d min · %d TP", DefaultWindowMin, DefaultMaxTP); }
      lastCmdT = (long)TimeGMT(); pushNow = true;
      UpdateTime();
   }
   else if(sparam == "SGK_BTN_PAUSE")
   {
      paused = !paused;
      GlobalVariableSet(gvPause, paused ? 1.0 : 0.0);
      if(paused) { DeletePending(0); DeletePending(1); }
      Print("SAMU GOLD KILLER: ", paused ? "PAUSE (naya pending band, TP chalu)" : "RESUME");
   }
   else if(sparam == "SGK_BTN_CBUY")
   {
      if(MessageBox("BUY ke sab trade band karein?", "SAMU GOLD KILLER", MB_YESNO | MB_ICONQUESTION) == IDYES) CloseSide(0, "button");
   }
   else if(sparam == "SGK_BTN_CSELL")
   {
      if(MessageBox("SELL ke sab trade band karein?", "SAMU GOLD KILLER", MB_YESNO | MB_ICONQUESTION) == IDYES) CloseSide(1, "button");
   }
   else if(sparam == "SGK_BTN_CALL")
   {
      if(MessageBox("BUY + SELL sab trade band karein?\n(Naya cycle chalega - rokna ho to pehle PAUSE)", "SAMU GOLD KILLER", MB_YESNO | MB_ICONWARNING) == IDYES)
      { CloseSide(0, "button ALL"); CloseSide(1, "button ALL"); }
   }
   if(ShowPanel) Panel();
}

//+------------------------------------------------------------------+
//| GOLD LUXE DASHBOARD — FULL SCREEN (poora chart window)            |
//| Har size / har Windows scaling (DPI) par khud fit: coordinates    |
//| chart ke pixel se, font size DPI ke hisaab se.                    |
//+------------------------------------------------------------------+
#define C_BG      C'11,11,11'
#define C_PANEL   C'17,16,14'
#define C_LINE    C'70,60,44'
#define C_GOLD    C'240,196,64'
#define C_GOLD2   C'190,150,60'
#define C_CREAM   C'250,246,236'
#define C_MUTED   C'185,175,155'
#define C_GREEN   C'0,230,118'
#define C_RED     C'255,90,90'
#define C_AMBER   C'255,190,60'
#define C_TRACK   C'38,34,28'
#define C_GBG     C'10,52,30'
#define C_GBORD   C'0,150,80'
#define C_ABG     C'56,40,8'
#define C_RBG     C'64,16,16'
#define F_B       "Segoe UI Semibold"
#define F_BLK     "Segoe UI Black"
#define F_SERIF   "Georgia"

int    gW = 0, gH = 0;          // chart size px
double gU = 10;                 // layout unit px
double gDpi = 96;

string Spaced(string s)
{
   string o = "";
   for(int i = 0; i < StringLen(s); i++)
   {
      string ch = StringSubstr(s, i, 1);
      o += (ch == " ") ? "  " : ch;
      if(i < StringLen(s) - 1) o += " ";
   }
   return o;
}

string Money(double v, bool sign = false)
{
   string s = DoubleToString(MathAbs(v), 2);
   int dot = StringFind(s, ".");
   string ip = StringSubstr(s, 0, dot), fp = StringSubstr(s, dot);
   string r = "";
   int cnt = 0;
   for(int i = StringLen(ip) - 1; i >= 0; i--)
   {
      r = StringSubstr(ip, i, 1) + r;
      cnt++;
      if(cnt % 3 == 0 && i > 0) r = "," + r;
   }
   string pre = (v < 0) ? "-$" : (sign ? "+$" : "$");
   return pre + r + fp;
}

int PX(double units) { return (int)MathRound(units * gU); }                    // unit -> px
int FS(double units)                                                          // unit (text height) -> font points
{
   return (int)MathMax(MinFontSize, MathRound(units * TextScale * gU * 72.0 / gDpi));
}

void Rect(string n, int x, int y, int w, int h, color bg, color border)
{
   string nm = "SGK_" + n;
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nm, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, MathMax(w, 1));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, MathMax(h, 1));
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, border);
}

void Lbl(string n, int x, int y, string txt, string font, int size, color clr, int align = 0)   // 0 left, 1 right, 2 center
{
   string nm = "SGK_" + n;
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nm, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, align == 1 ? ANCHOR_RIGHT_UPPER : (align == 2 ? ANCHOR_UPPER : ANCHOR_LEFT_UPPER));
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, nm, OBJPROP_TEXT, txt == "" ? " " : txt);
   ObjectSetString(0, nm, OBJPROP_FONT, font);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
}

void Btn(string n, int x, int y, int w, int h, string txt, color txtc, color bg, color border)
{
   string nm = "SGK_BTN_" + n;
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nm, OBJPROP_ZORDER, 10);
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString(0, nm, OBJPROP_TEXT, txt);
   ObjectSetString(0, nm, OBJPROP_FONT, F_B);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FS(1.6));
   ObjectSetInteger(0, nm, OBJPROP_COLOR, txtc);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, border);
}

void Bar(string n, int x, int y, int w, int h, double frac, color fill)
{
   frac = MathMax(0.0, MathMin(1.0, frac));
   Rect(n + "_t", x, y, w, h, C_TRACK, C_TRACK);
   int fw = (int)MathRound(w * frac);
   Rect(n + "_f", x, y, MathMax(fw, 1), h, fw < 1 ? C_TRACK : fill, fw < 1 ? C_TRACK : fill);
}

void TodayStats()
{
   if(TimeCurrent() - statsAt < 10) return;
   statsAt = TimeCurrent();
   MqlDateTime d; TimeToStruct(TimeCurrent(), d);
   d.hour = 0; d.min = 0; d.sec = 0;
   datetime day0 = StructToTime(d);
   todayPL = 0; todayCycles = 0;
   if(!HistorySelect(day0, TimeCurrent() + 3600)) return;
   int n = HistoryDealsTotal();
   datetime lastT = 0; long lastType = -1;
   for(int i = 0; i < n; i++)
   {
      ulong t = HistoryDealGetTicket(i);
      if(t == 0) continue;
      if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != MagicNumber) continue;
      long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
      todayPL += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
      datetime tm = (datetime)HistoryDealGetInteger(t, DEAL_TIME);
      long ty = HistoryDealGetInteger(t, DEAL_TYPE);
      if(ty != lastType || tm - lastT > 5) todayCycles++;   // ek saath band hue = ek basket
      lastT = tm; lastType = ty;
   }
}

void SetupChart()
{
   if(!ShowPanel) return;
   ChartSetInteger(0, CHART_FOREGROUND, false);              // objects candles ke upar
   if(HideChart) ChartSetInteger(0, CHART_SHOW, false);       // poora chart = dashboard
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, C_BG);
}

void RestoreChart()
{
   ChartSetInteger(0, CHART_SHOW, true);
}

void Panel()
{
   gW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   gH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   if(gW < 200 || gH < 150) return;
   gDpi = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(gDpi < 72) gDpi = 96;
   gU = MathMin(gW / 100.0, gH / 62.0);                      // 100 unit chauda, 62 unit uncha
   int m = PX(2.2);
   int W = gW, H = gH;
   int CW = W - 2 * m;

   TodayStats();
   SideInfo b, s;
   Collect(0, b, false);
   Collect(1, s, false);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE), eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double flt = b.profit + s.profit;
   MqlDateTime td; TimeToStruct(TimeCurrent(), td);
   if(td.day_of_year != worstDay) { worstDay = td.day_of_year; worstFloat = 0; }
   worstFloat = MathMin(worstFloat, flt);
   double sp = SpreadUSD();

   // ---------- background + frame ----------
   Rect("bg", 0, 0, W, H, C_BG, C_BG);
   Rect("frame", PX(0.8), PX(0.8), W - 2 * PX(0.8), H - 2 * PX(0.8), C_BG, C_LINE);

   // ---------- header ----------
   int y = PX(2.0);
   Lbl("t1", m, y, Spaced("SAMU GOLD KILLER") + "   ·   " + Spaced(_Symbol), F_B, FS(1.6), C_GOLD);
   Lbl("eq", m - PX(0.2), y + PX(2.2), Money(eq), F_SERIF, FS(5.0), C_GOLD);
   Lbl("t2", m, y + PX(8.6), "Balance " + Money(bal) + "   ·   Floating " + Money(flt, true), F_B, FS(1.7), flt >= 0 ? C_GREEN : C_MUTED);
   datetime ist = TimeGMT() + 19800;
   MqlDateTime it; TimeToStruct(ist, it);
   string days[7] = {"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"};
   string mons[12] = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
   int rx = W - m;
   Lbl("clk", rx, y + PX(0.6), StringFormat("%02d:%02d", it.hour, it.min), F_SERIF, FS(4.4), C_CREAM, 1);
   Lbl("day", rx, y + PX(6.4), Spaced("IST · " + days[it.day_of_week] + " " + IntegerToString(it.day) + " " + mons[it.mon - 1]), F_B, FS(1.5), C_GOLD, 1);
   Lbl("srv", rx, y + PX(8.6), "Server " + TimeToString(TimeTradeServer(), TIME_MINUTES) + "  ·  v1.06", F_B, FS(1.5), C_MUTED, 1);
   y += PX(11.6);
   Rect("hr1", m, y, CW, 1, C_LINE, C_LINE);
   y += PX(1.0);

   // ---------- status banner (hara = sab theek) ----------
   string bTitle, bMsg; int bk;
   Banner(b, s, bTitle, bMsg, bk);
   color bClr = bk == 0 ? C_GREEN : (bk == 2 ? C_RED : C_AMBER);
   color bBg  = bk == 0 ? C_GBG : (bk == 2 ? C_RBG : C_ABG);
   color bBorder = bk == 0 ? C_GBORD : bClr;
   if(bk == 2 && BlinkAlerts && (GetTickCount() / 600) % 2 == 0) bClr = C_CREAM;   // v1.05: laal alert blink
   double ddLimit = MaxLossUSD > 0 ? MaxLossUSD : 0;
   double worstSide = MathMin(b.profit, s.profit);
   Rect("ban", m, y, CW, PX(4.6), bBg, bBorder);
   Lbl("banT", m + PX(1.4), y + PX(0.7), bTitle, F_BLK, FS(2.2), bClr);
   Lbl("banM", m + PX(17), y + PX(1.0), bMsg, F_B, FS(1.9), C_CREAM);
   y += PX(5.8);

   // ---------- 4 stat columns ----------
   int cw = CW / 4;
   string cl[4] = {"BUY GRID", "SELL GRID", "TODAY", "CYCLES"};
   for(int i = 0; i < 4; i++)
   {
      Lbl("cl" + IntegerToString(i), m + i * cw + (i ? PX(1.6) : 0), y, Spaced(cl[i]), F_B, FS(1.6), C_GOLD);
      if(i > 0) Rect("cv" + IntegerToString(i), m + i * cw, y, 1, PX(8.4), C_LINE, C_LINE);
   }
   int vy = y + PX(2.0), sy = y + PX(6.6);
   int c0 = m, c1 = m + cw + PX(1.6), c2 = m + 2 * cw + PX(1.6), c3 = m + 3 * cw + PX(1.6);
   Lbl("c0", c0, vy, Money(b.profit, true), F_SERIF, FS(3.4), b.profit >= 0 ? C_GREEN : C_RED);
   Lbl("c0b", c0, sy, StringFormat("%d trades · %.2f lot", b.count, b.lots), F_B, FS(1.5), C_MUTED);
   Lbl("c1", c1, vy, Money(s.profit, true), F_SERIF, FS(3.4), s.profit >= 0 ? C_GREEN : C_RED);
   Lbl("c1b", c1, sy, StringFormat("%d trades · %.2f lot", s.count, s.lots), F_B, FS(1.5), C_MUTED);
   Lbl("c2", c2, vy, Money(todayPL, true), F_SERIF, FS(3.4), todayPL >= 0 ? C_GREEN : C_RED);
   Lbl("c2b", c2, sy, "aaj band P/L", F_B, FS(1.5), C_MUTED);
   Lbl("c3", c3, vy, IntegerToString(todayCycles) + " / $" + DoubleToString(BasketTP_USD, 0), F_SERIF, FS(3.4), C_CREAM);
   Lbl("c3b", c3, sy, "aaj band baskets", F_B, FS(1.5), C_MUTED);
   y += PX(9.4);

   // ---------- bars: BUY | SELL ----------
   double bf = b.count > 0 ? MathMax(0, b.profit) / BasketTP_USD : 0;
   double sf = s.count > 0 ? MathMax(0, s.profit) / BasketTP_USD : 0;
   int bh = MathMax(PX(0.7), 4);
   int hw = CW / 2 - PX(1.5), sx = m + CW / 2 + PX(1.5);
   Lbl("b1l", m, y, StringFormat("BUY  %s / $%.0f", Money(b.profit, true), BasketTP_USD), F_B, FS(1.7), C_CREAM);
   Lbl("b1r", m + hw, y, StringFormat("%.0f%%", bf * 100), F_B, FS(1.7), C_MUTED, 1);
   Bar("b1", m, y + PX(2.6), hw, bh, bf, C_GOLD);
   Lbl("b2l", sx, y, StringFormat("SELL  %s / $%.0f", Money(s.profit, true), BasketTP_USD), F_B, FS(1.7), C_CREAM);
   Lbl("b2r", sx + hw, y, StringFormat("%.0f%%", sf * 100), F_B, FS(1.7), C_MUTED, 1);
   Bar("b2", sx, y + PX(2.6), hw, bh, sf, C_GOLD);
   y += PX(4.2);
   Rect("hr2", m, y, CW, 1, C_LINE, C_LINE);
   y += PX(0.9);

   // ---------- lower: trade table (left) + details (right) ----------
   int btnH = PX(4.2);
   int yBtn = H - m - btnH;
   int lowTop = y, lowBot = yBtn - PX(1.0);
   int tblW = (int)(CW * 0.60);
   int rpX = m + tblW + PX(1.8), rpW = W - m - rpX;
   Rect("tbl", m, lowTop, tblW, lowBot - lowTop, C_PANEL, C_LINE);
   Rect("rp", rpX, lowTop, rpW, lowBot - lowTop, C_PANEL, C_LINE);

   int tx = m + PX(1.2), tw = tblW - PX(2.4);
   int cx0 = tx, cx1 = tx + (int)(tw * 0.09), cx2 = tx + (int)(tw * 0.27), cx3 = tx + (int)(tw * 0.42), cx4 = tx + (int)(tw * 0.66), cxR = tx + tw;
   int ty0 = lowTop + PX(0.8);
   Lbl("th0", cx0, ty0, "#", F_B, FS(1.5), C_GOLD);
   Lbl("th1", cx1, ty0, Spaced("TYPE"), F_B, FS(1.5), C_GOLD);
   Lbl("th2", cx2, ty0, Spaced("LOT"), F_B, FS(1.5), C_GOLD);
   Lbl("th3", cx3, ty0, Spaced("PRICE"), F_B, FS(1.5), C_GOLD);
   Lbl("th4", cx4, ty0, Spaced("TIME"), F_B, FS(1.5), C_GOLD);
   Lbl("th5", cxR, ty0, Spaced("P&L"), F_B, FS(1.5), C_GOLD, 1);
   double rowH = 2.75;
   int maxRows = (int)MathMax(1, MathFloor((lowBot - (ty0 + PX(2.9)) - PX(0.3)) / (rowH * gU)));
   maxRows = MathMin(maxRows, 30);

   int rows = 0;
   int ty[]; double lt[], pr[], pl[]; datetime ot[];
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      ArrayResize(ty, rows + 1); ArrayResize(lt, rows + 1); ArrayResize(pr, rows + 1); ArrayResize(pl, rows + 1); ArrayResize(ot, rows + 1);
      ty[rows] = (int)PositionGetInteger(POSITION_TYPE); lt[rows] = PositionGetDouble(POSITION_VOLUME);
      pr[rows] = PositionGetDouble(POSITION_PRICE_OPEN); pl[rows] = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      ot[rows] = (datetime)PositionGetInteger(POSITION_TIME);
      rows++;
   }
   for(int i = 0; i < rows; i++)                              // naye upar
      for(int j = i + 1; j < rows; j++)
         if(ot[j] > ot[i])
         {
            int c = ty[i]; ty[i] = ty[j]; ty[j] = c;
            double x = lt[i]; lt[i] = lt[j]; lt[j] = x;
            x = pr[i]; pr[i] = pr[j]; pr[j] = x;
            x = pl[i]; pl[i] = pl[j]; pl[j] = x;
            datetime q = ot[i]; ot[i] = ot[j]; ot[j] = q;
         }
   bool more = rows > maxRows;
   int shown = more ? maxRows - 1 : rows;
   for(int r = 0; r < 30; r++)
   {
      string rn = "r" + IntegerToString(r) + "_";
      int ry = ty0 + PX(2.9) + (int)(r * rowH * gU);
      if(r < shown)
      {
         Lbl(rn + "0", cx0, ry, IntegerToString(rows - r), F_B, FS(1.85), C_MUTED);
         Lbl(rn + "1", cx1, ry, ty[r] == POSITION_TYPE_BUY ? "BUY" : "SELL", F_B, FS(1.85), ty[r] == POSITION_TYPE_BUY ? C_GREEN : C_RED);
         Lbl(rn + "2", cx2, ry, DoubleToString(lt[r], 2), F_B, FS(1.85), C_CREAM);
         Lbl(rn + "3", cx3, ry, DoubleToString(pr[r], _Digits), F_B, FS(1.85), C_CREAM);
         Lbl(rn + "4", cx4, ry, IstHM(ot[r]), F_B, FS(1.85), C_MUTED);
         Lbl(rn + "5", cxR - PX(0.5), ry, Money(pl[r], true), F_B, FS(1.85), pl[r] >= 0 ? C_GREEN : C_RED, 1);
      }
      else
         for(int c = 0; c < 6; c++) ObjectDelete(0, "SGK_" + rn + IntegerToString(c));
   }
   if(rows == 0) Lbl("tnone", cx0, ty0 + PX(2.9), "Koi khula trade nahi  ·  pending lage hain", F_B, FS(1.7), C_MUTED);
   else ObjectDelete(0, "SGK_tnone");
   if(more) Lbl("tmore", cx0, ty0 + PX(2.9) + (int)(shown * rowH * gU), "+ " + IntegerToString(rows - shown) + " purane trades aur", F_B, FS(1.6), C_GOLD);
   else ObjectDelete(0, "SGK_tmore");

   // right DETAILS (sabse zaroori upar)
   string nb = (b.pendTicket ? DoubleToString(b.pendPrice, _Digits) : "-");
   string ns = (s.pendTicket ? DoubleToString(s.pendPrice, _Digits) : "-");
   int px0 = rpX + PX(1.2), px1 = rpX + rpW - PX(1.2);
   int ry0 = lowTop + PX(0.8);
   Lbl("rpT", px0, ry0, Spaced("DETAILS"), F_B, FS(1.5), C_GOLD);
   string kL[9], kV[9]; color kC[9];
   kL[0] = "Next BUY";   kV[0] = StringFormat("L%d %.2f @ %s", b.count + 1, LevelLot(b.count + 1), nb); kC[0] = C_GREEN;
   kL[1] = "Next SELL";  kV[1] = StringFormat("L%d %.2f @ %s", s.count + 1, LevelLot(s.count + 1), ns); kC[1] = C_RED;
   kL[2] = "News";       kV[2] = newsBlock ? "BLOCK" : (UseNewsFilter ? "Clear" : "Off"); kC[2] = newsBlock ? C_AMBER : C_GREEN;
   kL[3] = "Spread";     kV[3] = StringFormat("%.2f%s", sp, MaxSpreadUSD > 0 ? StringFormat(" (max %.2f)", MaxSpreadUSD) : " (off)"); kC[3] = C_CREAM;
   kL[4] = "Drawdown";   kV[4] = Money(MathMin(0, worstSide)) + (ddLimit > 0 ? " / $" + DoubleToString(ddLimit, 0) : " · max OFF"); kC[4] = worstSide < 0 ? C_RED : C_CREAM;
   kL[5] = ControlMode == CTRL_APP ? "START" : "Trade time";
   kV[5] = (nightOff && UseTradeTime && ControlMode == CTRL_FIXED) ? timeText + " · raat OFF" : timeText; kC[5] = inTime ? C_GREEN : C_AMBER;   // v1.04/1.05
   kL[6] = "Shaant check"; kV[6] = CalmRangeUSD > 0 ? StringFormat("%d min $%.1f / $%.1f %s", CalmMinutes, calmRange, CalmRangeUSD, calmOk ? "OK" : "RUKA") : "Off"; kC[6] = calmOk ? C_GREEN : C_AMBER;
   kL[7] = "App link";   kV[7] = linkText; kC[7] = RemoteOn() ? (linkOk ? C_GREEN : C_RED) : (ghTok == "" ? C_AMBER : C_MUTED);
   kL[8] = "Agli news";  kV[8] = newsText; kC[8] = C_MUTED;
   double kh = 2.75;
   int kRows = (int)MathFloor((lowBot - (ry0 + PX(2.9)) - PX(0.3)) / (kh * gU));
   for(int i = 0; i < 9; i++)
   {
      string kn = "k" + IntegerToString(i);
      int ky = ry0 + PX(2.9) + (int)(i * kh * gU);
      if(i < kRows)
      {
         if(i == 8) { Lbl(kn + "l", px0, ky, newsText, F_B, FS(1.4), C_MUTED); ObjectDelete(0, "SGK_" + kn + "v"); }
         else
         {
            Lbl(kn + "l", px0, ky, kL[i], F_B, FS(1.75), C_MUTED);
            Lbl(kn + "v", px1, ky, kV[i], F_B, FS(1.75), kC[i], 1);
         }
      }
      else { ObjectDelete(0, "SGK_" + kn + "l"); ObjectDelete(0, "SGK_" + kn + "v"); }
   }

   // ---------- buttons ----------
   int bw = PX(15);
   Btn("PAUSE", m, yBtn, bw, btnH, ControlMode == CTRL_APP ? (armed ? "STOP" : "START") : (paused ? "RESUME" : "PAUSE"), (ControlMode == CTRL_APP ? !armed : paused) ? C_GREEN : C_GOLD, C_BG, (ControlMode == CTRL_APP ? !armed : paused) ? C_GREEN : C_GOLD);
   Btn("CALL", W - m - bw, yBtn, bw, btnH, "CLOSE ALL", C_CREAM, C'140,36,30', C_RED);
   Btn("CSELL", W - m - 2 * bw - PX(1.2), yBtn, bw, btnH, "CLOSE SELL", C_CREAM, C'30,26,20', C_GOLD);
   Btn("CBUY", W - m - 3 * bw - PX(2.4), yBtn, bw, btnH, "CLOSE BUY", C_CREAM, C'30,26,20', C_GOLD);
   // purane v1.02 objects jo ab nahi chahiye
   string old[] = {"vline", "t2x", "b3l", "b3r", "b3_t", "b3_f", "info", "info2", "thl", "rpl", "k9l", "k9v"};
   for(int i = 0; i < ArraySize(old); i++) ObjectDelete(0, "SGK_" + old[i]);
   ChartRedraw(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| v1.05 BANNER (dashboard + app dono ke liye)  k: 0 hara 1 peela 2 laal |
//+------------------------------------------------------------------+
void Banner(SideInfo &b, SideInfo &s, string &t, string &m, int &k)
{
   bool hedging = ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   double ddLimit = MaxLossUSD > 0 ? MaxLossUSD : 0;
   double worstSide = MathMin(b.profit, s.profit);
   double sp = SpreadUSD();
   int open = b.count + s.count;
   t = "ALL CLEAR"; m = "BUY + SELL grid chalu  ·  TP $" + DoubleToString(BasketTP_USD, 0) + " per side"; k = 0;
   if(!hedging)                    { t = "EMERGENCY"; m = "Account HEDGING nahi - BUY + SELL saath nahi chalenge"; k = 2; }
   else if(ddLimit > 0 && worstSide <= -0.8 * ddLimit)
                                   { t = "EMERGENCY"; m = StringFormat("Drawdown %s of $%.0f  ·  MaxLoss par basket band", Money(worstSide), ddLimit); k = 2; }
   else if(MaxLevels > 0 && (b.count >= MaxLevels || s.count >= MaxLevels))
                                   { t = "EMERGENCY"; m = StringFormat("Max levels full  ·  BUY %d / SELL %d of %d", b.count, s.count, MaxLevels); k = 2; }
   else if(UseDeepBounce && DeepFromLevel > 0 && (b.count >= DeepFromLevel || s.count >= DeepFromLevel))
                                   { t = "DEEP"; m = StringFormat("Basket gehri  ·  BUY L%d / SELL L%d  ·  bounce %.2f lot  ·  $%.0f profit par band", b.count, s.count, DeepLot, DeepTP_USD); k = 2; }
   else if(ghTok == "" && !MQLInfoInteger(MQL_TESTER))
                                   { t = "JODO CODE"; m = pairShow + "   ·   App > Settings > EA jodo me ye code likho"; k = 1; }
   else if(RemoteOn() && !linkOk && lastPoll > 0)
                                   { t = "APP LINK"; m = linkText; k = 1; }
   else if(paused)                 { t = "PAUSED"; m = "Naya pending band  ·  $" + DoubleToString(BasketTP_USD, 0) + " TP chalu  ·  RESUME dabao"; k = 1; }
   else if(newsBlock)              { t = "NEWS"; m = newsText; k = 1; }
   else if(ControlMode == CTRL_APP)
   {
      if(armed)
      {
         if(armTP >= armMaxTP)                               { t = "TP POORE"; m = StringFormat("%d/%d TP  ·  nayi basket band  ·  window %s IST tak", armTP, armMaxTP, GmtHM(armEnd)); k = 0; }
         else if(CalmRangeUSD > 0 && !calmOk && open == 0)   { t = "RUKA"; m = StringFormat("START chalu, market tez: %d min range $%.1f > $%.1f", CalmMinutes, calmRange, CalmRangeUSD); k = 1; }
         else                                                { t = "START ON"; m = StringFormat("Window %s IST tak  ·  TP %d/%d  ·  basket TP $%.0f", GmtHM(armEnd), armTP, armMaxTP, BasketTP_USD); k = 0; }
      }
      else if(open > 0)            { t = "STANDBY"; m = StringFormat("Nayi basket band  ·  khuli basket $%.0f+ profit par band", MathMax(0.0, EndCloseUSD)); k = 1; }
      else                         { t = "STANDBY"; m = "App ya chart se START dabao"; k = 1; }
   }
   else if(!inTime && nightOff && open == 0 && UseTradeTime)
                                   { t = "RAAT OFF"; m = "Aaj raat news: " + nightWhy + "  ·  " + timeText; k = 1; }
   else if(!inTime)                { t = "OFF TIME"; m = "Nayi basket band  ·  " + timeText + "  ·  khuli basket ka TP chalu"; k = 1; }
   else if(CalmRangeUSD > 0 && !calmOk && open == 0)
                                   { t = "RUKA"; m = StringFormat("Market tez: %d min range $%.1f > $%.1f", CalmMinutes, calmRange, CalmRangeUSD); k = 1; }
   else if(!SpreadOk())            { t = "SPREAD"; m = StringFormat("Spread $%.2f > $%.2f  ·  naya pending ruka", sp, MaxSpreadUSD); k = 1; }
}

//+------------------------------------------------------------------+
//| v1.05 START / STOP state (restart ke baad bhi yaad)               |
//+------------------------------------------------------------------+
bool RemoteOn() { return StringLen(ghTok) > 10 && !MQLInfoInteger(MQL_TESTER); }

bool WindowOpen()
{
   if(ControlMode != CTRL_APP) return inTime;
   return armed && (long)TimeGMT() < armEnd;
}

string GmtHM(long gmt) { return TimeToString((datetime)(gmt + 19800), TIME_MINUTES); }

void SaveArm()
{
   if(MQLInfoInteger(MQL_TESTER)) return;
   GlobalVariableSet(gvArm + "A", armed ? 1.0 : 0.0);
   GlobalVariableSet(gvArm + "E", (double)armEnd);
   GlobalVariableSet(gvArm + "S", (double)armT0);
   GlobalVariableSet(gvArm + "T", (double)armTP);
   GlobalVariableSet(gvArm + "M", (double)armMaxTP);
   GlobalVariableSet(gvArm + "C", lastCmdId);
}

void LoadArm()
{
   if(MQLInfoInteger(MQL_TESTER) || !GlobalVariableCheck(gvArm + "A")) return;
   armed    = GlobalVariableGet(gvArm + "A") > 0.5;
   armEnd   = (long)GlobalVariableGet(gvArm + "E");
   armT0    = (long)GlobalVariableGet(gvArm + "S");
   armTP    = (int)GlobalVariableGet(gvArm + "T");
   armMaxTP = (int)GlobalVariableGet(gvArm + "M");
   if(GlobalVariableCheck(gvArm + "C")) lastCmdId = GlobalVariableGet(gvArm + "C");
   if(armed && (long)TimeGMT() >= armEnd) armed = false;
}

void Arm(int winMin, int maxTP)
{
   winMin = MathMax(5, MathMin(480, winMin));
   maxTP  = MathMax(1, MathMin(20, maxTP));
   armed = true; armT0 = (long)TimeGMT(); armEnd = armT0 + winMin * 60; armTP = 0; armMaxTP = maxTP;
   SaveArm(); pushNow = true;
   Print("SAMU GOLD KILLER: START - window ", winMin, " min (", GmtHM(armEnd), " IST tak), max ", maxTP, " TP");
}

void Disarm(string why)
{
   if(!armed) return;
   armed = false; SaveArm(); pushNow = true;
   Print("SAMU GOLD KILLER: START band - ", why);
}

//+------------------------------------------------------------------+
//| v1.05 SHAANT CHECK: pichhle CalmMinutes band M1 candle ka range    |
//+------------------------------------------------------------------+
void UpdateCalm()
{
   if(CalmRangeUSD <= 0 || CalmMinutes <= 0) { calmOk = true; calmRange = 0; return; }
   double hi = -1e18, lo = 1e18;
   for(int i = 1; i <= CalmMinutes; i++)
   {
      double h = iHigh(_Symbol, PERIOD_M1, i), l = iLow(_Symbol, PERIOD_M1, i);
      if(h <= 0 || l <= 0) continue;
      hi = MathMax(hi, h); lo = MathMin(lo, l);
   }
   if(hi < lo) { calmOk = true; calmRange = 0; return; }
   calmRange = hi - lo;
   calmOk = calmRange < CalmRangeUSD;
}

//+------------------------------------------------------------------+
//| v1.05 APP LINK (GitHub contents API, live branch)                 |
//+------------------------------------------------------------------+
string GhUrl(string path, bool withRef)
{
   string u = "https://api.github.com/repos/" + GitHubRepo + "/contents/" + path;
   if(withRef) u += "?ref=" + GitHubBranch + "&t=" + IntegerToString(GetTickCount());
   return u;
}

int GhReq(string method, string url, string accept, string body, string &resp)
{
   string hd = (ghTok != "" ? "Authorization: Bearer " + ghTok + "\r\n" : "") + "Accept: " + accept + "\r\nUser-Agent: SAMU-GOLD-KILLER-EA\r\nX-GitHub-Api-Version: 2022-11-28\r\n";
   if(body != "") hd += "Content-Type: application/json\r\n";
   char data[], res[]; string rh;
   if(body != "") { int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8); ArrayResize(data, MathMax(0, n - 1)); }
   ResetLastError();
   int code = WebRequest(method, url, hd, 5000, data, res, rh);
   if(code == -1)
   {
      int e = GetLastError();
      linkOk = false;
      linkText = (e == 4014) ? "WebRequest me https://api.github.com jodo" : "Internet / WebRequest error " + IntegerToString(e);
      resp = "";
      return -1;
   }
   resp = CharArrayToString(res, 0, WHOLE_ARRAY, CP_UTF8);
   return code;
}

string LinkErr(int code)
{
   if(code == 401) return "Token galat ya expire";
   if(code == 403) return "Token ki ijazat nahi / GitHub limit";
   if(code == 404) return "Repo / branch nahi mila";
   if(code == 409 || code == 422) return "Status file takrav - dobara bhejenge";
   return "GitHub " + IntegerToString(code);
}

string JStr(string js, string key)                       // simple JSON value (pehla match)
{
   int p = StringFind(js, "\"" + key + "\"");
   if(p < 0) return "";
   p = StringFind(js, ":", p + StringLen(key) + 2);
   if(p < 0) return "";
   p++;
   int n = StringLen(js);
   while(p < n && (StringGetCharacter(js, p) == ' ' || StringGetCharacter(js, p) == '\n' || StringGetCharacter(js, p) == '\r' || StringGetCharacter(js, p) == '\t')) p++;
   if(p >= n) return "";
   if(StringGetCharacter(js, p) == '"')
   {
      string o = "";
      for(int i = p + 1; i < n; i++)
      {
         ushort c = StringGetCharacter(js, i);
         if(c == '\\' && i + 1 < n) { o += ShortToString(StringGetCharacter(js, i + 1)); i++; continue; }
         if(c == '"') break;
         o += ShortToString(c);
      }
      return o;
   }
   int q = p;
   while(q < n) { ushort c = StringGetCharacter(js, q); if(c == ',' || c == '}' || c == ']' || c == ' ' || c == '\n' || c == '\r') break; q++; }
   return StringSubstr(js, p, q - p);
}

string JEsc(string s)
{
   string o = "";
   for(int i = 0; i < StringLen(s); i++)
   {
      ushort c = StringGetCharacter(s, i);
      if(c == '"') o += "\\\"";
      else if(c == '\\') o += "\\\\";
      else if(c < 32) o += " ";
      else o += ShortToString(c);
   }
   return o;
}

string Base64(string s)
{
   uchar src[], dst[], key[];
   int n = StringToCharArray(s, src, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(src, MathMax(0, n - 1));
   if(CryptEncode(CRYPT_BASE64, src, key, dst) <= 0) return "";
   return CharArrayToString(dst);
}

void Remote()
{
   if(MQLInfoInteger(MQL_TESTER)) { linkOk = false; linkText = "Tester (off)"; return; }
   long now = (long)TimeGMT();
   if(ghTok == "")                                       // v1.06: app se jodne ka intezaar
   {
      linkOk = false; linkText = "Jodo code " + pairShow;
      if(now - lastPair >= 30) { lastPair = now; PollPair(); }
      return;
   }
   if(now - lastPoll >= MathMax(5, PollSec)) { lastPoll = now; PollControl(); }
   if(pushNow || now - lastPush >= MathMax(10, StatusSec)) { lastPush = now; pushNow = false; PushStatus(); }
}

void PollControl()
{
   string r;
   int c = GhReq("GET", GhUrl("control.json", true), "application/vnd.github.raw+json", "", r);
   if(c == -1) return;
   if(c == 404) { linkOk = true; linkAt = (long)TimeGMT(); linkText = "OK · abhi koi command nahi"; return; }
   if(c == 401 && tokFromFile) { ResetToken("token galat / expire"); return; }   // v1.06
   if(c != 200) { linkOk = false; linkText = LinkErr(c); return; }
   linkOk = true; linkAt = (long)TimeGMT(); linkText = "OK · " + TimeToString((datetime)(linkAt + 19800), TIME_SECONDS);
   HandleCmd(r);
}

void HandleCmd(string js)
{
   double id = StringToDouble(JStr(js, "id"));
   if(id <= 0 || id <= lastCmdId) return;
   string cmd = JStr(js, "cmd");
   long ts = (long)StringToInteger(JStr(js, "ts"));
   long now = (long)TimeGMT();
   lastCmdId = id; lastCmdName = cmd; lastCmdT = now;
   long age = now - ts;
   string res;
   if(ts <= 0 || age > CmdExpiryMin * 60)
      res = StringFormat("Purana command (%d min) - ignore", (int)(age / 60));
   else if(cmd == "START")
   {
      if(ControlMode != CTRL_APP) res = "Ignored: EA FIXED mode me hai";
      else
      {
         int win = (int)StringToInteger(JStr(js, "win"));  if(win <= 0) win = DefaultWindowMin;
         int mtp = (int)StringToInteger(JStr(js, "maxTP")); if(mtp <= 0) mtp = DefaultMaxTP;
         Arm(win, mtp);
         if(paused) { paused = false; GlobalVariableSet(gvPause, 0.0); }
         res = StringFormat("OK · %d min · %d TP", MathMax(5, MathMin(480, win)), MathMax(1, MathMin(20, mtp)));
         if(CalmRangeUSD > 0 && !calmOk) res += StringFormat(" · market tez ($%.1f), shaant hone par basket", calmRange);
         if(newsBlock) res += " · news ke baad basket";
      }
   }
   else if(cmd == "STOP")       { Disarm("App STOP"); res = "OK · nayi basket band"; }
   else if(cmd == "CLOSE_BUY")  { CloseSide(0, "App CLOSE BUY"); res = "OK · BUY band"; }
   else if(cmd == "CLOSE_SELL") { CloseSide(1, "App CLOSE SELL"); res = "OK · SELL band"; }
   else if(cmd == "CLOSE_ALL")  { Disarm("App CLOSE ALL"); CloseSide(0, "App CLOSE ALL"); CloseSide(1, "App CLOSE ALL"); res = "OK · sab band, START band"; }
   else res = "Ignored: anjaan command " + cmd;
   lastCmdRes = res;
   SaveArm();
   pushNow = true;
   UpdateTime();
   Print("SAMU GOLD KILLER: App command ", cmd, " -> ", res);
}

void PushStatus()
{
   string r;
   if(statusSha == "")
   {
      int g = GhReq("GET", GhUrl("status.json", true), "application/vnd.github+json", "", r);
      if(g == 200) statusSha = JStr(r, "sha");
      else if(g != 404) { if(g != -1) { linkOk = false; linkText = LinkErr(g); } return; }
   }
   string b64 = Base64(BuildStatus());
   if(b64 == "") return;
   string body = "{\"message\":\"ea status\",\"branch\":\"" + GitHubBranch + "\",\"content\":\"" + b64 + "\"" + (statusSha != "" ? ",\"sha\":\"" + statusSha + "\"" : "") + "}";
   int c = GhReq("PUT", GhUrl("status.json", false), "application/vnd.github+json", body, r);
   if(c == 200 || c == 201) { statusSha = JStr(r, "sha"); linkOk = true; linkAt = (long)TimeGMT(); }
   else if(c == 401 && tokFromFile) ResetToken("token galat / expire");   // v1.06
   else { statusSha = ""; if(c != -1) { linkOk = false; linkText = LinkErr(c); } if(c == 409 || c == 422) pushNow = true; }
}

string JD(double v, int d = 2) { return DoubleToString(v, d); }

string SideJson(SideInfo &x, int side)
{
   double nxt = x.pendTicket ? x.pendPrice : 0;
   return "{\"n\":" + IntegerToString(x.count) + ",\"lots\":" + JD(x.lots) + ",\"pl\":" + JD(x.profit) + ",\"avg\":" + JD(x.avg, _Digits) + ",\"next\":" + JD(nxt, _Digits) + "}";
}

string BuildStatus()
{
   SideInfo b, s;
   Collect(0, b, false);
   Collect(1, s, false);
   TodayStats();
   long now = (long)TimeGMT();
   long off = (long)(MathRound(((double)TimeTradeServer() - (double)TimeGMT()) / 900.0) * 900.0);
   string bt, bm; int bk;
   Banner(b, s, bt, bm, bk);
   string login = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string acc = "..." + StringSubstr(login, MathMax(0, StringLen(login) - 4));
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double flt = b.profit + s.profit;

   string j = "{\"v\":1,\"ea\":\"1.06\",\"t\":" + IntegerToString(now);
   j += ",\"acc\":\"" + acc + "\",\"srv\":\"" + JEsc(AccountInfoString(ACCOUNT_SERVER)) + "\",\"sym\":\"" + _Symbol + "\"";
   j += ",\"bid\":" + JD(bid, _Digits) + ",\"ask\":" + JD(ask, _Digits) + ",\"sp\":" + JD(ask - bid);
   j += ",\"bal\":" + JD(AccountInfoDouble(ACCOUNT_BALANCE)) + ",\"eq\":" + JD(AccountInfoDouble(ACCOUNT_EQUITY)) + ",\"fl\":" + JD(flt) + ",\"tp\":" + JD(BasketTP_USD);
   j += ",\"mode\":\"" + (ControlMode == CTRL_APP ? "APP" : "FIXED") + "\",\"armed\":" + (armed ? "true" : "false");
   j += ",\"armT0\":" + IntegerToString(armT0) + ",\"armEnd\":" + IntegerToString(armEnd) + ",\"tpDone\":" + IntegerToString(armTP) + ",\"maxTP\":" + IntegerToString(armMaxTP);
   j += ",\"endClose\":" + JD(EndCloseUSD) + ",\"paused\":" + (paused ? "true" : "false") + ",\"inTime\":" + (inTime ? "true" : "false");
   j += ",\"calm\":{\"r30\":" + JD(calmRange) + ",\"lim\":" + JD(CalmRangeUSD, 1) + ",\"min\":" + IntegerToString(CalmMinutes) + ",\"ok\":" + (calmOk ? "true" : "false") + "}";
   // news (GMT)
   j += ",\"news\":{\"block\":" + (newsBlock ? "true" : "false") + ",\"text\":\"" + JEsc(newsText) + "\",\"list\":[";
   int nn = 0;
   for(int i = 0; i < ArraySize(newsTime) && nn < 20; i++)
   {
      long g = (long)newsTime[i] - off;
      if(g < now - 1800) continue;
      j += (nn ? "," : "") + "[" + IntegerToString(g) + ",\"" + JEsc(newsName[i]) + "\"]";
      nn++;
   }
   j += "]}";
   j += ",\"buy\":" + SideJson(b, 0) + ",\"sell\":" + SideJson(s, 1);
   j += ",\"deep\":{\"buy\":" + ((UseDeepBounce && DeepFromLevel > 0 && b.count >= DeepFromLevel) ? "true" : "false") + ",\"sell\":" + ((UseDeepBounce && DeepFromLevel > 0 && s.count >= DeepFromLevel) ? "true" : "false") + "}";
   j += ",\"today\":{\"pl\":" + JD(todayPL) + ",\"cyc\":" + IntegerToString(todayCycles) + ",\"worst\":" + JD(MathMin(worstFloat, flt)) + "}";
   j += ",\"lastCmd\":{\"id\":" + DoubleToString(lastCmdId, 0) + ",\"cmd\":\"" + JEsc(lastCmdName) + "\",\"res\":\"" + JEsc(lastCmdRes) + "\",\"t\":" + IntegerToString(lastCmdT) + "}";
   j += ",\"banner\":{\"t\":\"" + JEsc(bt) + "\",\"m\":\"" + JEsc(bm) + "\",\"k\":\"" + (bk == 0 ? "g" : (bk == 2 ? "r" : "a")) + "\"}";
   // trades (naye pehle, max 25)
   j += ",\"trades\":[";
   int tn = 0;
   ulong tk[]; datetime tt[]; int cnt = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      ArrayResize(tk, cnt + 1); ArrayResize(tt, cnt + 1);
      tk[cnt] = t; tt[cnt] = (datetime)PositionGetInteger(POSITION_TIME); cnt++;
   }
   for(int a = 0; a < cnt; a++)
      for(int c2 = a + 1; c2 < cnt; c2++)
         if(tt[c2] > tt[a]) { ulong x = tk[a]; tk[a] = tk[c2]; tk[c2] = x; datetime y = tt[a]; tt[a] = tt[c2]; tt[c2] = y; }
   for(int a = 0; a < cnt && tn < 25; a++)
   {
      if(!PositionSelectByTicket(tk[a])) continue;
      bool isB = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      j += (tn ? "," : "") + "[\"" + (isB ? "B" : "S") + "\"," + JD(PositionGetDouble(POSITION_VOLUME)) + "," + JD(PositionGetDouble(POSITION_PRICE_OPEN), _Digits) + ",\"" + IstHM((datetime)PositionGetInteger(POSITION_TIME)) + "\"," + JD(PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP)) + "]";
      tn++;
   }
   j += "]";
   // 120 band M1 candle (GMT)
   j += ",\"bars\":[";
   MqlRates rt[];
   int nb = CopyRates(_Symbol, PERIOD_M1, 1, 120, rt);
   for(int i = 0; i < nb; i++)
      j += (i ? "," : "") + "[" + IntegerToString((long)rt[i].time - off) + "," + JD(rt[i].open) + "," + JD(rt[i].high) + "," + JD(rt[i].low) + "," + JD(rt[i].close) + "]";
   j += "]}";
   return j;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| v1.06 JODO CODE: token bina paste kiye app se                     |
//| KDF (app ke saath same): k = SHA256(code + ":" + nonce),          |
//| phir 5000 baar k = SHA256(k). Block i = SHA256(k + i (4 byte BE)).|
//| c = "SGK1:" + token XOR blocks.  id = SHA256("SGKID:" + code)[0..8]|
//+------------------------------------------------------------------+
#define SGK_ALPHA "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

void Ascii(string s, uchar &a[])
{
   int n = StringToCharArray(s, a, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(a, MathMax(0, n - 1));
}

bool Sha(const uchar &src[], uchar &dst[])
{
   uchar key[];
   return CryptEncode(CRYPT_HASH_SHA256, src, key, dst) == 32;
}

string HexOf(const uchar &a[], int n)
{
   string s = "";
   for(int i = 0; i < n && i < ArraySize(a); i++) s += StringFormat("%02x", a[i]);
   return s;
}

int HexVal(ushort c)
{
   if(c >= '0' && c <= '9') return c - '0';
   if(c >= 'a' && c <= 'f') return c - 'a' + 10;
   if(c >= 'A' && c <= 'F') return c - 'A' + 10;
   return 0;
}

int Unhex(string h, uchar &out[])
{
   int n = StringLen(h) / 2;
   ArrayResize(out, n);
   for(int i = 0; i < n; i++) out[i] = (uchar)((HexVal(StringGetCharacter(h, 2 * i)) << 4) | HexVal(StringGetCharacter(h, 2 * i + 1)));
   return n;
}

string FileRead1(string name)
{
   int h = FileOpen(name, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE) return "";
   string s = FileReadString(h);
   FileClose(h);
   StringTrimLeft(s); StringTrimRight(s);
   return s;
}

void FileWrite1(string name, string v)
{
   int h = FileOpen(name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE) { Print("SAMU GOLD KILLER: file nahi likh paye ", name); return; }
   FileWriteString(h, v);
   FileClose(h);
}

string TokFile()  { return "SGK_tok_"  + IntegerToString(MagicNumber) + ".txt"; }
string PairFile() { return "SGK_pair_" + IntegerToString(MagicNumber) + ".txt"; }

void MakePairCode(bool fresh)
{
   pairCode = fresh ? "" : FileRead1(PairFile());
   if(StringLen(pairCode) != 9)
   {
      MathSrand((uint)(GetMicrosecondCount() ^ (ulong)TimeLocal()));
      uchar seed[], h[];
      Ascii(IntegerToString((long)GetMicrosecondCount()) + ":" + IntegerToString((long)TimeLocal()) + ":" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + ":" + IntegerToString(MathRand()) + ":" + IntegerToString(MathRand()) + ":" + TerminalInfoString(TERMINAL_PATH), seed);
      Sha(seed, h);
      string al = SGK_ALPHA; int L = StringLen(al);
      pairCode = "";
      for(int i = 0; i < 9; i++) pairCode += StringSubstr(al, h[i] % L, 1);
      FileWrite1(PairFile(), pairCode);
   }
   pairShow = StringSubstr(pairCode, 0, 3) + "-" + StringSubstr(pairCode, 3, 3) + "-" + StringSubstr(pairCode, 6, 3);
   uchar a[], d[];
   Ascii("SGKID:" + pairCode, a);
   Sha(a, d);
   pairId = HexOf(d, 8);
}

void InitToken()
{
   ghTok = GitHubToken; StringTrimLeft(ghTok); StringTrimRight(ghTok);
   tokFromFile = false;
   if(StringLen(ghTok) <= 10)
   {
      ghTok = MQLInfoInteger(MQL_TESTER) ? "" : FileRead1(TokFile());
      tokFromFile = StringLen(ghTok) > 10;
      if(!tokFromFile) ghTok = "";
   }
   if(ghTok == "" && !MQLInfoInteger(MQL_TESTER)) MakePairCode(false);
}

void ResetToken(string why)
{
   Print("SAMU GOLD KILLER: token hataya - ", why, ". Naya jodo code.");
   FileDelete(TokFile(), FILE_COMMON);
   ghTok = ""; tokFromFile = false; statusSha = ""; linkOk = false;
   MakePairCode(true);
   lastPair = 0;
}

bool PairDecrypt(string code, string nonce, string chex, string &tok)
{
   uchar t[], k[];
   Ascii(code + ":" + nonce, t);
   if(!Sha(t, k)) return false;
   for(int i = 0; i < 5000; i++)
   {
      uchar x[];
      ArrayCopy(x, k);
      if(!Sha(x, k)) return false;
   }
   uchar c[];
   int n = Unhex(chex, c);
   if(n < 10) return false;
   uchar p[], blk[];
   ArrayResize(p, n);
   int bi = -1;
   for(int j = 0; j < n; j++)
   {
      int b = j / 32;
      if(b != bi)
      {
         uchar ib[];
         ArrayResize(ib, 36);
         ArrayCopy(ib, k, 0, 0, 32);
         ib[32] = (uchar)((b >> 24) & 255); ib[33] = (uchar)((b >> 16) & 255); ib[34] = (uchar)((b >> 8) & 255); ib[35] = (uchar)(b & 255);
         if(!Sha(ib, blk)) return false;
         bi = b;
      }
      p[j] = (uchar)(c[j] ^ blk[j % 32]);
   }
   string s = CharArrayToString(p, 0, n);
   if(StringSubstr(s, 0, 5) != "SGK1:") return false;
   tok = StringSubstr(s, 5);
   StringTrimLeft(tok); StringTrimRight(tok);
   return StringLen(tok) > 10;
}

void PollPair()
{
   if(pairCode == "") MakePairCode(false);
   string r;
   int c = GhReq("GET", GhUrl("pair.json", true), "application/vnd.github.raw+json", "", r);   // bina token (public repo)
   if(c == 404 || c == -1) return;
   if(c != 200) { linkText = "Jodo code " + pairShow + " · " + LinkErr(c); return; }
   if(JStr(r, "id") != pairId) return;                    // kisi aur code ka
   string tok;
   if(!PairDecrypt(pairCode, JStr(r, "n"), JStr(r, "c"), tok)) { linkText = "Code mila par khula nahi - app me dobara EA jodo"; return; }
   ghTok = tok; tokFromFile = true;
   FileWrite1(TokFile(), ghTok);
   FileDelete(PairFile(), FILE_COMMON);
   Print("SAMU GOLD KILLER: app se jud gaya (token VPS par save)");
   // pair.json mitao
   string m;
   if(GhReq("GET", GhUrl("pair.json", true), "application/vnd.github+json", "", m) == 200)
   {
      string sha = JStr(m, "sha");
      if(sha != "") GhReq("DELETE", GhUrl("pair.json", false), "application/vnd.github+json", "{\"message\":\"EA juda\",\"branch\":\"" + GitHubBranch + "\",\"sha\":\"" + sha + "\"}", m);
   }
   lastPoll = 0; pushNow = true; linkText = "Jud gaya";
}
//+------------------------------------------------------------------+
