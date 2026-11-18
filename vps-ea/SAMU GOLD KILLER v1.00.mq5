//+------------------------------------------------------------------+
//|                                   SAMU GOLD KILLER v1.00.mq5       |
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
//|   MaxLevels, MaxLossUSD (side ka loss -> basket band), MaxSpread.  |
//|  OPTIONAL: H1 trailing SL (1-trade basket) - default OFF.          |
//|                                                                    |
//|  DHYAN: Account HEDGING hona chahiye (BUY + SELL saath).           |
//|  Distance $ me hain (InstaForex GOLD 80 points = $0.80), isliye    |
//|  XAUUSDm (3 digit) / XAUUSD (2 digit) dono par same chalega.       |
//|                                                                    |
//|  CHANGELOG                                                         |
//|  v1.00 (18-Nov-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"

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
input double MaxSpreadUSD       = 0.0;     // Spread isse zyada -> naya pending/trail nahi ($)

input group "=== Optional: H1 trailing SL (1-trade basket) ==="
input bool   UseH1TrailSL       = false;   // Naye H1 candle par SL = pichhli H1 candle high/low (sirf profit lock ho to)

input group "=== General ==="
input long   MagicNumber        = 20261118;
input string OrderComment       = "SAMU GOLD KILLER";
input bool   ShowPanel          = true;

CTrade   trade;
datetime lastH1      = 0;
datetime lastErrTime = 0;

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
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

void OnTimer() { if(ShowPanel) Panel(); }

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
   ulong    pendTicket;
   double   pendPrice;
   double   pendLot;
   int      pendCount;
};

void Collect(int side, SideInfo &s)
{
   s.count = 0; s.lots = 0; s.profit = 0; s.extreme = 0;
   s.pendTicket = 0; s.pendPrice = 0; s.pendLot = 0; s.pendCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if((side == 0 && type != POSITION_TYPE_BUY) || (side == 1 && type != POSITION_TYPE_SELL)) continue;
      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      s.count++;
      s.lots   += PositionGetDouble(POSITION_VOLUME);
      s.profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(s.count == 1) s.extreme = op;
      else s.extreme = (side == 0) ? MathMin(s.extreme, op) : MathMax(s.extreme, op);
   }
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
      else
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
   Print("SAMU GOLD KILLER: ", (side == 0 ? "BUY" : "SELL"), " basket band - ", why);
}

bool SpreadOk()
{
   if(MaxSpreadUSD <= 0) return true;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   return (ask - bid) <= MaxSpreadUSD + 1e-9;
}

double MinStopDist()
{
   long lvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long frz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(lvl, frz) * _Point + _Point;
}

//+------------------------------------------------------------------+
void HandleSide(int side)
{
   bool enabled = (side == 0) ? EnableBuy : EnableSell;
   SideInfo s;
   Collect(side, s);

   // 1) basket exit
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

   if(!enabled)
   {
      if(s.pendTicket != 0) DeletePending(side);
      return;
   }
   if(MaxLevels > 0 && s.count >= MaxLevels)
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

   // 2) pending trail (sirf market ki taraf, kabhi peeche nahi)
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

   // 3) naya pending
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
void Panel()
{
   string txt = "SAMU GOLD KILLER v1.00   " + _Symbol + "\n";
   for(int side = 0; side < 2; side++)
   {
      SideInfo s;
      Collect(side, s);
      txt += StringFormat("%s: %d trades  %.2f lot  P/L $%.2f / TP $%.0f  |  next L%d %.2f lot  |  pending %s\n",
                          side == 0 ? "BUY " : "SELL", s.count, s.lots, s.profit, BasketTP_USD,
                          s.count + 1, LevelLot(s.count + 1),
                          s.pendTicket ? DoubleToString(s.pendPrice, _Digits) : "-");
   }
   double sp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   txt += StringFormat("Spread $%.2f   Gap $%.2f   Pending $%.2f   MaxLevels %d   MaxLoss $%.0f", sp, MinGridGap, PendingDistance, MaxLevels, MaxLossUSD);
   Comment(txt);
}
//+------------------------------------------------------------------+
