//+------------------------------------------------------------------+
//|                                   SAMU GOLD KILLER v1.01.mq5       |
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
//|  v1.01 (18-Nov-2026) "Gold Luxe" dashboard (kaala + sona): equity, |
//|   IST/server time, status banner, BUY/SELL/TODAY/CYCLES, $30 TP    |
//|   bars, drawdown bar, next grid + spread + news line, trade table, |
//|   PAUSE / CLOSE BUY / CLOSE SELL / CLOSE ALL buttons.              |
//|   News filter +-30 min (MT5 Economic Calendar, USD, High).         |
//|   Spread filter OFF hi (original jaisa).                           |
//|  v1.00 (18-Nov-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.01"

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
input bool   ShowPanel          = true;    // Gold Luxe dashboard
input int    PanelX             = 12;      // Dashboard left (px)
input int    PanelY             = 24;      // Dashboard top (px)

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
   LoadNews();
   EventSetTimer(1);
   if(ShowPanel) Panel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, "SGK_");
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
//| GOLD LUXE DASHBOARD                                               |
//+------------------------------------------------------------------+
#define C_BG      C'11,11,11'
#define C_LINE    C'58,50,38'
#define C_GOLD    C'212,175,55'
#define C_GOLD2   C'176,141,58'
#define C_CREAM   C'237,230,214'
#define C_MUTED   C'138,129,114'
#define C_GREEN   C'111,207,151'
#define C_RED     C'224,108,108'
#define C_AMBER   C'230,180,80'
#define C_TRACK   C'38,34,28'
#define C_BANNER  C'26,16,14'

#define PW 600

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
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, PanelX + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, PanelY + y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, MathMax(w, 0));
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, border);
}

void Lbl(string n, int x, int y, string txt, string font, int size, color clr, bool right = false)
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
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, right ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, PanelX + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, PanelY + y);
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
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, PanelX + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, PanelY + y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString(0, nm, OBJPROP_TEXT, txt);
   ObjectSetString(0, nm, OBJPROP_FONT, "Segoe UI Semibold");
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, txtc);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, border);
}

void Bar(string n, int x, int y, int w, double frac, color fill)
{
   frac = MathMax(0.0, MathMin(1.0, frac));
   Rect(n + "_t", x, y, w, 4, C_TRACK, C_TRACK);
   int fw = (int)MathRound(w * frac);
   Rect(n + "_f", x, y, fw < 1 ? 1 : fw, 4, fw < 1 ? C_TRACK : fill, fw < 1 ? C_TRACK : fill);
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

void Panel()
{
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

   // positions table rows
   int rows = 0;
   ulong tk[]; int ty[]; double lt[], pr[], pl[]; datetime ot[];
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      ArrayResize(tk, rows + 1); ArrayResize(ty, rows + 1); ArrayResize(lt, rows + 1);
      ArrayResize(pr, rows + 1); ArrayResize(pl, rows + 1); ArrayResize(ot, rows + 1);
      tk[rows] = t; ty[rows] = (int)PositionGetInteger(POSITION_TYPE); lt[rows] = PositionGetDouble(POSITION_VOLUME);
      pr[rows] = PositionGetDouble(POSITION_PRICE_OPEN); pl[rows] = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      ot[rows] = (datetime)PositionGetInteger(POSITION_TIME);
      rows++;
   }
   int maxRows = 10;
   int shown = MathMin(rows, maxRows);
   int tableH = 22 + MathMax(shown, 1) * 16 + (rows > maxRows ? 16 : 0);
   int yTable = 300;
   int yBtn = yTable + tableH + 14;
   int H = yBtn + 40;

   Rect("bg", 0, 0, PW, H, C_BG, C_LINE);

   // header
   Lbl("t1", 22, 16, Spaced("SAMU GOLD KILLER") + "   ·   " + Spaced(_Symbol), "Segoe UI", 8, C_GOLD);
   Lbl("eq", 20, 32, Money(eq), "Georgia", 24, C_GOLD);
   Lbl("t2", 22, 74, "Equity  ·  Balance " + Money(bal) + "  ·  Floating " + Money(flt, true) + "  ·  v1.01", "Segoe UI", 8, C_MUTED);
   datetime ist = TimeGMT() + 19800;
   MqlDateTime it; TimeToStruct(ist, it);
   string days[7] = {"SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"};
   string mons[12] = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
   Rect("vline", PW - 200, 18, 1, 66, C_LINE, C_LINE);
   Lbl("clk", PW - 22, 26, StringFormat("%02d:%02d", it.hour, it.min), "Georgia", 20, C_CREAM, true);
   Lbl("day", PW - 22, 58, Spaced("IST · " + days[it.day_of_week] + " " + IntegerToString(it.day) + " " + mons[it.mon - 1]), "Segoe UI", 7, C_GOLD, true);
   Lbl("srv", PW - 22, 72, "Server " + TimeToString(TimeTradeServer(), TIME_MINUTES), "Segoe UI", 7, C_MUTED, true);
   Rect("hr1", 20, 96, PW - 40, 1, C_LINE, C_LINE);

   // status banner
   string bTitle = "Status", bMsg = "All clear  ·  BUY + SELL grid chalu  ·  TP $" + DoubleToString(BasketTP_USD, 0) + " per side";
   color  bClr = C_GREEN, bBorder = C'40,70,52';
   double ddLimit = MaxLossUSD > 0 ? MaxLossUSD : 0;
   double worstSide = MathMin(b.profit, s.profit);
   if(!hedging)                    { bTitle = "Emergency"; bMsg = "Account HEDGING nahi hai - BUY + SELL saath nahi chalenge"; bClr = C_RED; bBorder = C_GOLD2; }
   else if(ddLimit > 0 && worstSide <= -0.8 * ddLimit)
                                   { bTitle = "Emergency"; bMsg = StringFormat("Drawdown %s of $%.0f  ·  MaxLoss par basket band hoga", Money(worstSide), ddLimit); bClr = C_RED; bBorder = C_GOLD2; }
   else if(MaxLevels > 0 && (b.count >= MaxLevels || s.count >= MaxLevels))
                                   { bTitle = "Emergency"; bMsg = StringFormat("Max levels full  ·  BUY %d / SELL %d of %d  ·  naya trade band", b.count, s.count, MaxLevels); bClr = C_RED; bBorder = C_GOLD2; }
   else if(paused)                 { bTitle = "Paused"; bMsg = "Naya pending band  ·  khule trade ka $" + DoubleToString(BasketTP_USD, 0) + " TP chalu  ·  RESUME dabao"; bClr = C_AMBER; bBorder = C_GOLD2; }
   else if(newsBlock)              { bTitle = "News"; bMsg = newsText; bClr = C_AMBER; bBorder = C_GOLD2; }
   else if(!SpreadOk())            { bTitle = "Spread"; bMsg = StringFormat("Spread $%.2f > $%.2f  ·  naya pending ruka", sp, MaxSpreadUSD); bClr = C_AMBER; bBorder = C_GOLD2; }
   Rect("ban", 20, 108, PW - 40, 30, C_BANNER, bBorder);
   Lbl("banT", 32, 113, bTitle, "Georgia", 12, bClr);
   Lbl("banM", 132, 117, bMsg, "Segoe UI", 8, C_CREAM);

   // 4 stat columns
   int cw = (PW - 40) / 4;
   string cl[4] = {"BUY GRID", "SELL GRID", "TODAY", "CYCLES"};
   for(int i = 0; i < 4; i++)
   {
      Lbl("cl" + IntegerToString(i), 22 + i * cw, 152, Spaced(cl[i]), "Segoe UI", 7, C_GOLD);
      if(i > 0) Rect("cv" + IntegerToString(i), 20 + i * cw - 8, 150, 1, 44, C_LINE, C_LINE);
   }
   Lbl("c0", 22, 166, Money(b.profit, true), "Georgia", 14, b.profit >= 0 ? C_GREEN : C_RED);
   Lbl("c0b", 22 + 0, 188, StringFormat("%d trades · %.2f lot", b.count, b.lots), "Segoe UI", 7, C_MUTED);
   Lbl("c1", 22 + cw, 166, Money(s.profit, true), "Georgia", 14, s.profit >= 0 ? C_GREEN : C_RED);
   Lbl("c1b", 22 + cw, 188, StringFormat("%d trades · %.2f lot", s.count, s.lots), "Segoe UI", 7, C_MUTED);
   Lbl("c2", 22 + 2 * cw, 166, Money(todayPL, true), "Georgia", 14, todayPL >= 0 ? C_GREEN : C_RED);
   Lbl("c2b", 22 + 2 * cw, 188, "band trades ka P/L", "Segoe UI", 7, C_MUTED);
   Lbl("c3", 22 + 3 * cw, 166, IntegerToString(todayCycles) + " / $" + DoubleToString(BasketTP_USD, 0), "Georgia", 14, C_CREAM);
   Lbl("c3b", 22 + 3 * cw, 188, "aaj band baskets", "Segoe UI", 7, C_MUTED);

   // bars
   int bw = PW - 40;
   double bf = b.count > 0 ? MathMax(0, b.profit) / BasketTP_USD : 0;
   double sf = s.count > 0 ? MathMax(0, s.profit) / BasketTP_USD : 0;
   Lbl("b1l", 22, 208, StringFormat("BUY basket  %s of $%.0f", Money(b.profit, true), BasketTP_USD), "Segoe UI", 8, C_CREAM);
   Lbl("b1r", PW - 22, 208, StringFormat("%.0f%%", bf * 100), "Segoe UI", 8, C_MUTED, true);
   Bar("b1", 20, 224, bw, bf, C_GOLD);
   Lbl("b2l", 22, 232, StringFormat("SELL basket  %s of $%.0f", Money(s.profit, true), BasketTP_USD), "Segoe UI", 8, C_CREAM);
   Lbl("b2r", PW - 22, 232, StringFormat("%.0f%%", sf * 100), "Segoe UI", 8, C_MUTED, true);
   Bar("b2", 20, 248, bw, sf, C_GOLD);
   double ddBase = ddLimit > 0 ? ddLimit : MathMax(1.0, bal * 0.10);
   double df = MathMax(0, -worstSide) / ddBase;
   Lbl("b3l", 22, 256, ddLimit > 0 ? StringFormat("Drawdown of $%.0f (MaxLoss)  ·  aaj sabse bura %s", ddLimit, Money(worstFloat))
                                   : StringFormat("Drawdown of $%.0f (10%% balance, MaxLoss OFF)  ·  aaj sabse bura %s", ddBase, Money(worstFloat)), "Segoe UI", 8, C_CREAM);
   Lbl("b3r", PW - 22, 256, StringFormat("%.0f%%", df * 100), "Segoe UI", 8, C_MUTED, true);
   Bar("b3", 20, 272, bw, df, C_RED);

   // info line
   string nb = (b.pendTicket ? DoubleToString(b.pendPrice, _Digits) : "-");
   string ns = (s.pendTicket ? DoubleToString(s.pendPrice, _Digits) : "-");
   Lbl("info", 22, 282, StringFormat("Next BUY L%d %.2f @ %s  ·  Next SELL L%d %.2f @ %s  ·  Spread %.2f  ·  News: %s",
                                     b.count + 1, LevelLot(b.count + 1), nb, s.count + 1, LevelLot(s.count + 1), ns, sp, newsText), "Segoe UI", 7, C_MUTED);

   // trade table
   Rect("hr2", 20, yTable - 2, PW - 40, 1, C_LINE, C_LINE);
   int cx[6] = {22, 70, 140, 210, 330, 0};
   Lbl("th0", cx[0], yTable + 4, "#", "Segoe UI", 7, C_GOLD);
   Lbl("th1", cx[1], yTable + 4, Spaced("TYPE"), "Segoe UI", 7, C_GOLD);
   Lbl("th2", cx[2], yTable + 4, Spaced("LOT"), "Segoe UI", 7, C_GOLD);
   Lbl("th3", cx[3], yTable + 4, Spaced("PRICE"), "Segoe UI", 7, C_GOLD);
   Lbl("th4", cx[4], yTable + 4, Spaced("OPEN"), "Segoe UI", 7, C_GOLD);
   Lbl("th5", PW - 22, yTable + 4, Spaced("P&L"), "Segoe UI", 7, C_GOLD, true);
   // sort by open time
   for(int i = 0; i < rows; i++)
      for(int j = i + 1; j < rows; j++)
         if(ot[j] < ot[i])
         {
            ulong a = tk[i]; tk[i] = tk[j]; tk[j] = a;
            int c = ty[i]; ty[i] = ty[j]; ty[j] = c;
            double x = lt[i]; lt[i] = lt[j]; lt[j] = x;
            x = pr[i]; pr[i] = pr[j]; pr[j] = x;
            x = pl[i]; pl[i] = pl[j]; pl[j] = x;
            datetime q = ot[i]; ot[i] = ot[j]; ot[j] = q;
         }
   for(int r = 0; r < maxRows; r++)
   {
      string rn = "r" + IntegerToString(r) + "_";
      int y = yTable + 22 + r * 16;
      if(r < shown)
      {
         Lbl(rn + "0", cx[0], y, "#" + IntegerToString(r + 1), "Consolas", 8, C_MUTED);
         Lbl(rn + "1", cx[1], y, ty[r] == POSITION_TYPE_BUY ? "BUY" : "SELL", "Consolas", 8, ty[r] == POSITION_TYPE_BUY ? C_GREEN : C_RED);
         Lbl(rn + "2", cx[2], y, DoubleToString(lt[r], 2), "Consolas", 8, C_CREAM);
         Lbl(rn + "3", cx[3], y, DoubleToString(pr[r], _Digits), "Consolas", 8, C_CREAM);
         Lbl(rn + "4", cx[4], y, IstHM(ot[r]) + " IST", "Consolas", 8, C_MUTED);
         Lbl(rn + "5", PW - 22, y, Money(pl[r], true), "Consolas", 8, pl[r] >= 0 ? C_GREEN : C_RED, true);
      }
      else
         for(int c = 0; c < 6; c++) ObjectDelete(0, "SGK_" + rn + IntegerToString(c));
   }
   if(rows == 0) Lbl("tnone", cx[0], yTable + 22, "Koi khula trade nahi  ·  pending lage hain, price palatne ka intezaar", "Segoe UI", 8, C_MUTED);
   else ObjectDelete(0, "SGK_tnone");
   if(rows > maxRows) Lbl("tmore", cx[0], yTable + 22 + maxRows * 16, "+ " + IntegerToString(rows - maxRows) + " aur trades", "Segoe UI", 7, C_MUTED);
   else ObjectDelete(0, "SGK_tmore");

   // buttons
   Rect("hr3", 20, yBtn - 8, PW - 40, 1, C_LINE, C_LINE);
   Btn("PAUSE", 20, yBtn, 110, 26, paused ? "RESUME" : "PAUSE", C_GOLD, C_BG, C_GOLD);
   Btn("CBUY", PW - 20 - 110 * 3 - 16, yBtn, 110, 26, "CLOSE BUY", C_CREAM, C'30,26,20', C_GOLD2);
   Btn("CSELL", PW - 20 - 110 * 2 - 8, yBtn, 110, 26, "CLOSE SELL", C_CREAM, C'30,26,20', C_GOLD2);
   Btn("CALL", PW - 20 - 110, yBtn, 110, 26, "CLOSE ALL", C_CREAM, C'122,40,32', C'122,40,32');
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
