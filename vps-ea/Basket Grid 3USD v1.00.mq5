//+------------------------------------------------------------------+
//|                                   Basket Grid 3USD v1.00.mq5     |
//|                     Ankush New Vision - Gold Basket Stop Grid    |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
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
#property version     "1.00"
#property description "Basket Grid 3USD v1.00 - 30 buy stop + 30 sell stop grid, $3 basket trailing"

#include <Trade\Trade.mqh>

#define EA_NAME  "Basket Grid 3USD"
#define EA_VER   "v1.00"
#define PFX      "BG3USD100_"
#define CMT_TAG  "BG3"

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
input double InpGap            = 2.00;    // Gap $ (do levels ke beech price doori)
input int    InpLevels         = 30;      // Har side kitne levels (30 buy stop + 30 sell stop)
input double InpBaseLot        = 0.01;    // Pehle tier ka lot
input double InpLotMultiplier  = 3.0;     // Har tier par lot x (0.01 -> 0.03 -> 0.09)
input int    InpLevelsPerTier  = 10;      // Kitne levels ke baad lot badhe

input group "=== Basket Trailing (sab trades ek saath) ==="
input double InpTrailStart     = 3.00;    // Trailing kab shuru: net basket profit $
input double InpMinLock        = 3.00;    // Kam se kam itna $ lock (isse neeche aate hi band)
input double InpTrailDist      = 1.00;    // Peak profit se kitna $ girne par band
input bool   InpCountCommission= true;    // Net profit me commission bhi gino (entry x2)
input bool   InpDeletePendOnTrail = false;// Trailing shuru hote hi pending hata do

input group "=== Safety ==="
input double InpMaxBasketLoss  = 0;       // Basket loss $ itna ho to sab band (0 = off)
input int    InpPauseAfterLossMin = 60;   // Loss band ke baad kitne minute ruke
input int    InpWaitAfterCloseSec = 0;    // Basket band hone ke baad naya grid kitne second baad
input double InpMaxSpread      = 0;       // Naya grid tabhi jab spread $ isse kam (0 = off)
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

// live counts
int      gBuys = 0, gSells = 0, gPendB = 0, gPendS = 0;
double   gLotB = 0, gLotS = 0, gNet = 0;
double   gToday = 0;
datetime gTodayCalc = 0;

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

void SetMsg(string m)
{
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
   return PFX + IntegerToString(InpMagic) + "_" + _Symbol + "_" + k;
}
void GVSet(string k, double v) { GlobalVariableSet(GVName(k), v); }
double GVGet(string k, double def)
{
   string n = GVName(k);
   if(!GlobalVariableCheck(n)) return def;
   return GlobalVariableGet(n);
}

void SaveState()
{
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

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
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
   if(TimeCurrent() - gTodayCalc < 5) return;
   gTodayCalc = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime from = StructToTime(dt);
   gToday = 0;
   if(!HistorySelect(from, TimeCurrent() + 60)) return;
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
   ClearComCache();
   SaveState();
   SetMsg(StringFormat("Naya grid @ %s | gap $%.2f | %d pending lage%s",
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
void SendCloseAll()
{
   if(GetTickCount() - gLastCloseSend < 1000 && gLastCloseSend != 0) return;
   gLastCloseSend = GetTickCount();

   trade.SetAsyncMode(true);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !MyPos()) continue;
      trade.PositionClose(t, (ulong)InpSlippage);
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !MyOrd()) continue;
      trade.OrderDelete(t);
   }
   trade.SetAsyncMode(false);
}

void StartClose(string why)
{
   if(gClosing) return;
   gClosing = true;
   gCloseWhy = why;
   gLastBasket = gNet;
   gLastCloseSend = 0;
   SetMsg(StringFormat("%s | net $%.2f | peak $%.2f | %d trades", why, gNet, gPeak, gBuys + gSells));
   SendCloseAll();
}

//+------------------------------------------------------------------+
//| MAIN LOGIC                                                       |
//+------------------------------------------------------------------+
void Engine()
{
   UpdateState();
   int open = gBuys + gSells;
   int pend = gPendB + gPendS;

   //--- 1) band karna chal raha hai
   if(gClosing)
   {
      if(open == 0 && pend == 0)
      {
         gClosing = false;
         gLastClose = TimeCurrent();
         gCycles++;
         gTrailOn = false; gPeak = 0; gWorst = 0; gPlaced = 0;
         ClearComCache();
         gTodayCalc = 0;
         SaveState();
         SetMsg(StringFormat("Basket band (%s) - andaza $%.2f", gCloseWhy, gLastBasket));
      }
      else SendCloseAll();
      return;
   }

   //--- 2) trades khule hain -> basket trailing
   if(open > 0)
   {
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

      double startP = MathMax(InpTrailStart, InpMinLock);
      if(!gTrailOn && gNet >= startP)
      {
         gTrailOn = true;
         gPeak = gNet;
         SetMsg(StringFormat("Trailing shuru @ $%.2f", gNet));
         if(InpDeletePendOnTrail) DeletePendings();
         SaveState();
         return;
      }

      if(gTrailOn)
      {
         if(gNet > gPeak) { gPeak = gNet; GVSet("peak", gPeak); }
         double floorP = MathMax(InpMinLock, gPeak - InpTrailDist);
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
   if(TimeCurrent() < gPauseUntil) return;
   if(InpWaitAfterCloseSec > 0 && TimeCurrent() - gLastClose < InpWaitAfterCloseSec) return;
   if(InpMaxSpread > 0 && SpreadNow() > InpMaxSpread) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) return;

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
#define PW   300.0
#define RH   22.0

void Row(int i, double y0, string key, string label)
{
   double y = y0 + i * RH;
   UiRect("rw" + key, 8, y, PW - 16, RH - 3, (i % 2 == 0 ? CLR_CELL : CLR_BOX), CLR_BOX, 1);
   UiText("lb" + key, 16, y + (RH - 3) / 2.0, label, TXT_DIM, 8.5, "Bahnschrift", ANCHOR_LEFT);
   UiText("vl" + key, PW - 16, y + (RH - 3) / 2.0, "-", TXT_W, 9, "Consolas", ANCHOR_RIGHT);
}

#define Y_ROWS 74.0
#define N_ROWS 11

void BuildPanel()
{
   double H = Y_ROWS + N_ROWS * RH + 84;
   UiRect("bg", 0, 0, PW, H, CLR_BG, NEON_CY, 2);
   UiRect("logo", 8, 7, 26, 26, GOLD_C, GOLD_C, 1);
   UiText("logoB", 21, 20, "$3", C'12,12,12', 9, "Arial Black", ANCHOR_CENTER);
   UiText("title", 42, 13, EA_NAME, TXT_W, 11, "Arial Black", ANCHOR_LEFT);
   UiText("ver", 42, 29, EA_VER + "  |  " + _Symbol + "  |  magic " + IntegerToString(InpMagic),
          TXT_DIM, 7.5, "Bahnschrift", ANCHOR_LEFT);

   // status strip
   UiRect("st", 8, 42, PW - 16, 26, CLR_BOX, NEON_PU, 1);
   UiText("stT", PW / 2.0, 55, "-", NEON_GR, 10, "Arial Black", ANCHOR_CENTER);

   Row(0,  Y_ROWS, "net",   "BASKET NET $");
   Row(1,  Y_ROWS, "trail", "TRAILING");
   Row(2,  Y_ROWS, "lock",  "LOCK (min book) $");
   Row(3,  Y_ROWS, "buy",   "BUY khule / lot");
   Row(4,  Y_ROWS, "sell",  "SELL khule / lot");
   Row(5,  Y_ROWS, "pend",  "PENDING buy / sell");
   Row(6,  Y_ROWS, "grid",  "GRID beech / gap");
   Row(7,  Y_ROWS, "worst", "Is basket ka worst $");
   Row(8,  Y_ROWS, "today", "AAJ ka profit $");
   Row(9,  Y_ROWS, "cyc",   "Aaj basket band");
   Row(10, Y_ROWS, "last",  "Pichhla basket $");

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
   else if(gBuys + gSells > 0)          { st = gTrailOn ? "PROFIT TRAILING" : "BASKET CHAL RAHA"; sc = gTrailOn ? NEON_GR : NEON_CY; }
   else if(gPendB + gPendS > 0)         { st = "GRID LAGA - FILL KA WAIT"; sc = NEON_PU; }
   else if(!gTradingOn)                 { st = "TRADING OFF";          sc = NEON_RD; }
   else                                 { st = "NAYA GRID LAG RAHA";   sc = NEON_OR; }
   SetT("stT", st, sc);

   SetT("vlnet", Money(gNet), gNet >= 0 ? NEON_GR : NEON_RD);
   if(gTrailOn)
      SetT("vltrail", "ON  peak " + DoubleToString(gPeak, 2), NEON_GR);
   else
      SetT("vltrail", "OFF  (start $" + DoubleToString(MathMax(InpTrailStart, InpMinLock), 2) + ")", TXT_DIM);
   double floorP = gTrailOn ? MathMax(InpMinLock, gPeak - InpTrailDist) : InpMinLock;
   SetT("vllock", DoubleToString(floorP, 2), gTrailOn ? NEON_GR : TXT_W);
   SetT("vlbuy",  IntegerToString(gBuys)  + "  /  " + DoubleToString(gLotB, 2), gBuys  > 0 ? NEON_CY : TXT_W);
   SetT("vlsell", IntegerToString(gSells) + "  /  " + DoubleToString(gLotS, 2), gSells > 0 ? NEON_MG : TXT_W);
   SetT("vlpend", IntegerToString(gPendB) + "  /  " + IntegerToString(gPendS), TXT_W);
   SetT("vlgrid", (gCenter > 0 ? DoubleToString(gCenter, _Digits) : "-") + "  /  $" + DoubleToString(InpGap, 2), TXT_W);
   SetT("vlworst", Money(gWorst), gWorst < 0 ? NEON_RD : TXT_W);
   SetT("vltoday", Money(gToday), gToday >= 0 ? NEON_GR : NEON_RD);
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

   Print(EA_NAME, " ", EA_VER, " start | ", _Symbol, " | gap $", DoubleToString(InpGap, 2),
         " | levels ", InpLevels, " | trail start $", DoubleToString(InpTrailStart, 2),
         " | min lock $", DoubleToString(InpMinLock, 2), " | trail dist $", DoubleToString(InpTrailDist, 2));
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
