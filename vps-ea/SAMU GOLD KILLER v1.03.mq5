//+------------------------------------------------------------------+
//|                                   SAMU GOLD KILLER v1.03.mq5       |
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
#property version   "1.03"

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

input group "=== Optional: H1 trailing SL (1-trade basket) ==="
input bool   UseH1TrailSL       = false;   // Naye H1 candle par SL = pichhli H1 candle high/low (sirf profit lock ho to)

input group "=== General ==="
input long   MagicNumber        = 20261118;
input string OrderComment       = "SAMU GOLD KILLER";
input bool   ShowPanel          = true;    // Gold Luxe dashboard (full screen)
input bool   HideChart          = true;    // Candles chhupao - poora chart dashboard
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
   Comment("");
   SetupChart();
   LoadNews();
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
void HandleSide(int side)
{
   bool enabled = (side == 0) ? EnableBuy : EnableSell;
   SideInfo s;
   Collect(side, s);

   // 1) basket exit (pause / news me bhi chalta hai)
   if(s.count > 0 && s.profit >= BasketTP_USD)
   {
      CloseSide(side, StringFormat("TP $%.2f (%d trades)", s.profit, s.count));
      return;
   }
   if(s.count > 0 && MaxLossUSD > 0 && s.profit <= -MaxLossUSD)
   {
      CloseSide(side, StringFormat("MaxLoss $%.2f (%d trades)", s.profit, s.count));
      return;
   }

   // 2) naya pending band: side off / PAUSE / news / max levels
   if(!enabled || paused || newsBlock || (MaxLevels > 0 && s.count >= MaxLevels))
   {
      if(s.pendTicket != 0) DeletePending(side);
      return;
   }
   if(TimeCurrent() - lastErrTime < 3) return;            // error ke baad thoda ruko
   if(!SpreadOk()) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist = MathMax(PendingDistance, MinStopDist());
   double want = NormPrice(side == 0 ? ask + dist : bid - dist);
   int    level = s.count + 1;
   double lot   = LevelLot(level);

   // 3) pending trail (sirf market ki taraf, kabhi peeche nahi)
   if(s.pendTicket != 0)
   {
      bool better = (side == 0) ? (want <= s.pendPrice - TrailStep + 1e-9) : (want >= s.pendPrice + TrailStep - 1e-9);
      if(MathAbs(s.pendLot - lot) > 1e-9)               // level badal gaya (jaise manual close) -> sahi lot se dubara
      {
         trade.OrderDelete(s.pendTicket);
         return;
      }
      if(better)
      {
         if(s.count > 0)
         {
            bool gapOk = (side == 0) ? (want <= s.extreme - MinGridGap + 1e-9) : (want >= s.extreme + MinGridGap - 1e-9);
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
      bool gapOk = (side == 0) ? (want <= s.extreme - MinGridGap + 1e-9) : (want >= s.extreme + MinGridGap - 1e-9);
      if(!gapOk) return;
   }
   bool ok = (side == 0) ? trade.BuyStop(lot, want, _Symbol, 0, 0, ORDER_TIME_GTC, 0, OrderComment + " L" + IntegerToString(level))
                         : trade.SellStop(lot, want, _Symbol, 0, 0, ORDER_TIME_GTC, 0, OrderComment + " L" + IntegerToString(level));
   if(!ok) lastErrTime = TimeCurrent();
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
   if(sparam == "SGK_BTN_PAUSE")
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
   bool hedging = ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);

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
   Lbl("srv", rx, y + PX(8.6), "Server " + TimeToString(TimeTradeServer(), TIME_MINUTES) + "  ·  v1.03", F_B, FS(1.5), C_MUTED, 1);
   y += PX(11.6);
   Rect("hr1", m, y, CW, 1, C_LINE, C_LINE);
   y += PX(1.0);

   // ---------- status banner (hara = sab theek) ----------
   string bTitle = "ALL CLEAR", bMsg = "BUY + SELL grid chalu  ·  TP $" + DoubleToString(BasketTP_USD, 0) + " per side";
   color  bClr = C_GREEN, bBg = C_GBG, bBorder = C_GBORD;
   double ddLimit = MaxLossUSD > 0 ? MaxLossUSD : 0;
   double worstSide = MathMin(b.profit, s.profit);
   if(!hedging)                    { bTitle = "EMERGENCY"; bMsg = "Account HEDGING nahi - BUY + SELL saath nahi chalenge"; bClr = C_RED; bBg = C_RBG; bBorder = C_RED; }
   else if(ddLimit > 0 && worstSide <= -0.8 * ddLimit)
                                   { bTitle = "EMERGENCY"; bMsg = StringFormat("Drawdown %s of $%.0f  ·  MaxLoss par basket band", Money(worstSide), ddLimit); bClr = C_RED; bBg = C_RBG; bBorder = C_RED; }
   else if(MaxLevels > 0 && (b.count >= MaxLevels || s.count >= MaxLevels))
                                   { bTitle = "EMERGENCY"; bMsg = StringFormat("Max levels full  ·  BUY %d / SELL %d of %d", b.count, s.count, MaxLevels); bClr = C_RED; bBg = C_RBG; bBorder = C_RED; }
   else if(paused)                 { bTitle = "PAUSED"; bMsg = "Naya pending band  ·  $" + DoubleToString(BasketTP_USD, 0) + " TP chalu  ·  RESUME dabao"; bClr = C_AMBER; bBg = C_ABG; bBorder = C_AMBER; }
   else if(newsBlock)              { bTitle = "NEWS"; bMsg = newsText; bClr = C_AMBER; bBg = C_ABG; bBorder = C_AMBER; }
   else if(!SpreadOk())            { bTitle = "SPREAD"; bMsg = StringFormat("Spread $%.2f > $%.2f  ·  naya pending ruka", sp, MaxSpreadUSD); bClr = C_AMBER; bBg = C_ABG; bBorder = C_AMBER; }
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
   string kL[8], kV[8]; color kC[8];
   kL[0] = "Next BUY";   kV[0] = StringFormat("L%d %.2f @ %s", b.count + 1, LevelLot(b.count + 1), nb); kC[0] = C_GREEN;
   kL[1] = "Next SELL";  kV[1] = StringFormat("L%d %.2f @ %s", s.count + 1, LevelLot(s.count + 1), ns); kC[1] = C_RED;
   kL[2] = "News";       kV[2] = newsBlock ? "BLOCK" : (UseNewsFilter ? "Clear" : "Off"); kC[2] = newsBlock ? C_AMBER : C_GREEN;
   kL[3] = "Spread";     kV[3] = StringFormat("%.2f%s", sp, MaxSpreadUSD > 0 ? StringFormat(" (max %.2f)", MaxSpreadUSD) : " (off)"); kC[3] = C_CREAM;
   kL[4] = "Drawdown";   kV[4] = Money(MathMin(0, worstSide)) + (ddLimit > 0 ? " / $" + DoubleToString(ddLimit, 0) : " · max OFF"); kC[4] = worstSide < 0 ? C_RED : C_CREAM;
   kL[5] = "Levels";     kV[5] = StringFormat("%d / %d", MathMax(b.count, s.count), MaxLevels); kC[5] = C_CREAM;
   kL[6] = "Aaj sabse bura"; kV[6] = Money(worstFloat); kC[6] = worstFloat < 0 ? C_RED : C_CREAM;
   kL[7] = "Agli news";  kV[7] = newsText; kC[7] = C_MUTED;
   double kh = 2.75;
   int kRows = (int)MathFloor((lowBot - (ry0 + PX(2.9)) - PX(0.3)) / (kh * gU));
   for(int i = 0; i < 8; i++)
   {
      string kn = "k" + IntegerToString(i);
      int ky = ry0 + PX(2.9) + (int)(i * kh * gU);
      if(i < kRows)
      {
         if(i == 7) { Lbl(kn + "l", px0, ky, newsText, F_B, FS(1.4), C_MUTED); ObjectDelete(0, "SGK_" + kn + "v"); }
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
   Btn("PAUSE", m, yBtn, bw, btnH, paused ? "RESUME" : "PAUSE", paused ? C_GREEN : C_GOLD, C_BG, paused ? C_GREEN : C_GOLD);
   Btn("CALL", W - m - bw, yBtn, bw, btnH, "CLOSE ALL", C_CREAM, C'140,36,30', C_RED);
   Btn("CSELL", W - m - 2 * bw - PX(1.2), yBtn, bw, btnH, "CLOSE SELL", C_CREAM, C'30,26,20', C_GOLD);
   Btn("CBUY", W - m - 3 * bw - PX(2.4), yBtn, bw, btnH, "CLOSE BUY", C_CREAM, C'30,26,20', C_GOLD);
   // purane v1.02 objects jo ab nahi chahiye
   string old[] = {"vline", "t2x", "b3l", "b3r", "b3_t", "b3_f", "info", "info2", "thl", "rpl", "k8l", "k8v", "k9l", "k9v"};
   for(int i = 0; i < ArraySize(old); i++) ObjectDelete(0, "SGK_" + old[i]);
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
