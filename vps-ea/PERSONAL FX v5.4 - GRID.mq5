//+------------------------------------------------------------------+
//|                                    PERSONAL FX v5.4 - GRID.mq5    |
//|     PERSONAL FX v5.4 — MANUAL ENTRY + MARTINGALE GRID SYSTEM     |
//|  Manual trade -> auto $TP -> loss gap -> same-side grid add ->  |
//|  basket average-price TP. Clean build: dashboard + daily limits  |
//|  + grid engine only (breakeven/trailing/autopilot/recovery/news  |
//|  session filters removed as requested).                          |
//+------------------------------------------------------------------+
//|  v4.1 : manual/mobile (magic 0) trades managed; grid state auto-synced   |
//|  v4.2 : REAL broker-side TP now set on positions (shows in MT5 T/P col)  |
//|  v4.3 : 3-COLUMN panel, font-size input, recent-closes log              |
//|  v4.4 : DPI-aware panel scaling (fixes overlap on hi-res screens),      |
//|         "Label" ghost-text bug fixed, narrower columns                  |
//|  v4.5 : FULL-WIDTH 3-column dashboard (auto-fits chart width), dotted    |
//|         rows, NEXT-ADD column in monitor, auto-rebuild on resize        |
//|  v4.6 : SYMBOL WHITELIST — EA now only manages Magic-0 (manual/mobile)   |
//|         trades on pairs YOU allow, so it can no longer grab trades      |
//|         opened by a DIFFERENT EA/robot sitting on another chart         |
//|  v4.7 : ADD GAP now measured in RAW PRICE distance (e.g. $5 = 4000,     |
//|         4005, 4010... on gold), not floating-$-loss.                    |
//|  v4.8 : Max concurrent-grids cap added (later removed in v4.9)          |
//|  v4.9 : Removed the pair-count cap — unlimited pairs allowed again.      |
//|  v5.0 : FIXED broker-side TP sync — legs no longer freeze at mismatched |
//|         prices as the grid grows. TP is CLAMPED (not skipped) at the   |
//|         broker's min-distance, so ALL legs of one pair show the SAME   |
//|         TP. (Actual basket close was always correct — this only fixes  |
//|         what the T/P column displays.)                                  |
//|  v5.1 : BASKET TP scaled with total lot (reverted in v5.2)              |
//|  v5.2 : REVERTED to FLAT $3 basket TP regardless of trade count/lot     |
//|         (back to original design — confirmed)                          |
//|  v5.3 : OCO PENDING — place Buy Limit + Sell Limit (or stops) on any   |
//|         pairs; when one FILLS, the leftover pending is auto-deleted.   |
//|         OCO_Mode: SAME PAIR (default) = only that pair's opposite      |
//|         pending removed, every pair works on its own.                  |
//|         ALL PAIRS = first fill anywhere removes every older pending.   |
//|         The filled trade then runs on normal grid rules ($TP/adds).    |
//|  v5.4 : APP BRIDGE — reads orders sent by SamuSignal Chart Analysis   |
//|         from Firebase /personalfx/orders (queue, many pairs at once). |
//|         Places MARKET / BUY-SELL LIMIT / BUY-SELL STOP with the lot   |
//|         from THIS EA's input, no SL/TP (grid rules manage the trade), |
//|         writes status back (PLACED / FAILED / SKIP / STALE) and       |
//|         deletes its own app pendings not filled in 60 min (EXPIRED).  |
//|         Also: grid engine now also runs every second (all pairs) and  |
//|         filling mode is set per symbol (fixes 10030 on other pairs).  |
//+------------------------------------------------------------------+
#property copyright   "PERSONAL FX"
#property description "PERSONAL FX v5.4 — Martingale Grid + OCO Pending + SamuSignal App Bridge"
#property version     "5.40"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CPositionInfo posInfo;

enum ENUM_OCO_MODE
{
   OCO_OFF       = 0,   // OFF - pending orders are never touched
   OCO_SAME_PAIR = 1,   // SAME PAIR - fill removes opposite pending of that pair only
   OCO_ALL_PAIRS = 2    // ALL PAIRS - first fill removes every older pending on all pairs
};

//+------------------------------------------------------------------+
//|  INPUTS                                                           |
//+------------------------------------------------------------------+
input group "========== GENERAL =========="
input int    MagicNumber        = 111222;
input int    MaxOpenTrades      = 30;      // safety cap across all grids
input bool   ManageManualTrades = true;    // also manage trades opened by hand / mobile app (magic 0)
input string AllowedSymbolsCSV    = "";      // empty = ALL symbols. Else comma list e.g. "EURUSDm,GBPUSDm,XAUUSDm" — ONLY these get grid-managed (protects against other EAs' Magic-0 trades)

input group "========== MANUAL LOT =========="
input double FixedLot           = 0.01;    // starting lot for a fresh manual trade
input double MinLot             = 0.01;
input double MaxLot             = 10.0;

input group "========== MARTINGALE GRID =========="
input double Grid_TP_Dollar       = 3.0;   // single-trade TP, $ PER 0.01 LOT (auto-scales)
input bool   UsePriceDistanceGap   = true;   // true = gap is a raw PRICE move (recommended); false = old floating-$-loss basket mode
input double Grid_Gap_Price       = 5.0;    // PRICE distance per grid step when UsePriceDistanceGap=true (e.g. 5.0 = $5 on XAUUSD -> 4000,4005,4010...; for EURUSD enter the price distance e.g. 0.0050 = 50 pips)
input double Grid_Gap_Dollar      = 10.0;  // (legacy mode only) basket floating-loss gap ($) that triggers next add
input double Grid_BasketTP_Dollar = 3.0;   // combined basket TP once 2+ trades are open ($, FLAT — does not scale with lot/trade count)
input int    Grid_MaxAdds         = 6;     // max martingale additions per pair (1 orig + N adds)

input group "========== DAILY RISK CONTROL =========="
input bool   UseDailyLimits       = true;
input double MaxDailyLoss         = 50.0;  // account-wide daily loss limit ($)
input double MaxDailyProfit       = 100.0; // account-wide daily profit target ($)
input bool   DDExemptMaxedGrids   = true;  // grids at Grid_MaxAdds ignore MaxDailyLoss, wait for own basket TP

input group "========== OCO PENDING (v5.3) =========="
input ENUM_OCO_MODE OCO_Mode     = OCO_SAME_PAIR; // Buy Limit + Sell Limit: when one fills, leftover pending auto-deleted

input group "========== SAMUSIGNAL APP BRIDGE (v5.4) =========="
input bool   UseAppBridge         = true;   // read orders sent from SamuSignal Chart Analysis
input string FirebaseURL          = "";     // SAME URL as SamuSignal Settings, e.g. https://xxxx-default-rtdb.asia-southeast1.firebasedatabase.app
input string FirebaseAuth         = "";     // only if your Firebase rules need it (same as app)
input string AppSymbolSuffix      = "";     // empty = auto-find (XAUUSD -> XAUUSDc / XAUUSDm). Or force e.g. "c" or "m"
input int    AppPollSec           = 3;      // how often Firebase is checked (seconds)
input int    AppPendingExpiryMin  = 60;     // app pending not filled in this many minutes -> deleted
input int    AppMaxOrderAgeMin    = 10;     // order older than this when EA sees it -> NOT placed (STALE)

input group "========== SAFETY FILTERS =========="
input bool   UseSpreadFilter      = true;
input int    MaxSpread_Points     = 300;
input bool   CloseOnWeekend       = true;
input string FridayCloseTime      = "22:00";

input group "========== PANEL =========="
input bool   ShowPanel            = true;
input int    Panel_X              = 10;
input int    Panel_Y              = 25;
input bool   EnableFKeys          = true;   // F6 Buy / F7 Sell / F8 Close All
input int    Panel_FontSize       = 10;     // 8-12; lower it if text still overlaps on your screen
input double Panel_Scale          = 0.0;    // 0 = AUTO from screen DPI. Force e.g. 1.5 / 2.0 if layout looks wrong

input group "========== NOTIFICATIONS =========="
input bool   UsePushNotify        = true;

//+------------------------------------------------------------------+
//|  THEME                                                            |
//+------------------------------------------------------------------+
#define QT_AMBER   C'255,176,0'
#define QT_AMBERD  C'170,125,30'
#define QT_DOTS    C'82,66,26'
#define QT_BG      C'8,8,8'
#define QT_BORDER  C'70,64,40'
#define QT_SECT    C'34,27,7'
#define QT_WHITE   C'230,230,222'
#define QT_GREEN   C'80,220,100'
#define QT_RED     C'255,90,80'
#define QT_DARKBTN C'12,12,10'
#define QFONT      "Consolas"
#define PANEL_W    808
#define COL_W      260
#define MAX_GRID_ROWS 12

//+------------------------------------------------------------------+
//|  GLOBALS                                                           |
//+------------------------------------------------------------------+
double   g_DayStartBalance = 0;
double   g_DailyPL         = 0;
int      g_DailyTradeCount = 0;
bool     g_DailyLimitHit   = false;
datetime g_LastDayReset    = 0;
double   g_LotInput        = 0.01;
string   g_ActiveSymbol    = "";   // symbol manual trades go to; set from panel edit box
double   g_S               = 1.0;   // panel scale factor (screen DPI / 96)
double   g_DpiS            = 1.0;   // real screen DPI / 96 (used for text width estimate)
int      g_CW              = 400;   // column width in px (set in BuildPanel)
int      g_LabChars        = 16;    // chars used by "LABEL ......" part of a row
int      g_ValX            = 200;   // x offset of value inside a column
int      g_LastChartW      = 0;     // chart width the panel was built for

// ===== MARTINGALE GRID state (per symbol, dynamic) =====
#define MAX_GRID_SYMS 30
string   g_GSym[MAX_GRID_SYMS];
int      g_GDir[MAX_GRID_SYMS];    // 1 = buy grid, -1 = sell grid
int      g_GAdds[MAX_GRID_SYMS];   // martingale adds done so far (0 = only original trade)
double   g_GLot[MAX_GRID_SYMS];    // lot used for every trade in this grid
double   g_GEntry[MAX_GRID_SYMS];  // ORIGINAL entry price of the grid (level 0) — used for price-distance gap
int      g_GCount = 0;

// ===== APP BRIDGE state (v5.4) =====
datetime g_AppLastPoll  = 0;
datetime g_AppLastOk    = 0;
string   g_AppStatus    = "OFF";
bool     g_AppUrlWarned = false;
string   g_AppDone[300];             // keys already handled this session (no double orders)
int      g_AppDoneN     = 0;

// session log (last 5 closed deals)
string g_LogTime[5];
string g_LogText[5];
double g_LogPL[5];
int    g_LogN = 0;

const string BT_BUY  = "PFX_BUY";
const string BT_SELL = "PFX_SELL";
const string BT_LDN  = "PFX_LDN";
const string BT_LUP  = "PFX_LUP";
const string BT_CALL = "PFX_CALL";
const string BT_F6   = "PFX_F6";
const string BT_F7   = "PFX_F7";
const string BT_F8   = "PFX_F8";
const string ED_SYM   = "PFX_SYM_EDIT";
const string BT_SYMSET= "PFX_SYM_SET";

//+------------------------------------------------------------------+
//|  INIT / DEINIT                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFillingBySymbol(_Symbol);

   g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_LastDayReset    = TimeCurrent();
   g_LotInput        = FixedLot;
   g_ActiveSymbol    = _Symbol;
   g_DailyLimitHit   = false;
   g_DailyTradeCount = 0;
   g_DailyPL         = 0;
   g_GCount = 0;
   g_LogN   = 0;

   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi<=0) dpi=96;
   g_DpiS = dpi/96.0;
   g_S = (Panel_Scale>0.0) ? Panel_Scale : (dpi/96.0);
   g_S = MathMax(0.75, MathMin(3.0, g_S));
   Print("PERSONAL FX: screen DPI ",dpi," -> panel scale ",DoubleToString(g_S,2),
         (Panel_Scale>0.0 ? " (manual)" : " (auto)"));

   EventSetTimer(1);
   if(ShowPanel) BuildPanel();

   Print("PERSONAL FX v5.4 MARTINGALE GRID + OCO + APP BRIDGE Loaded | OCO mode: ", OcoModeText(),
         " | App bridge: ", (UseAppBridge && FirebaseURL!="") ? "ON" : "OFF");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, "PFX_");
}

void OnTimer()
{
   ManageOCOPending();          // every second -> catches fills on ALL pairs, not just chart pair
   PollAppOrders();             // v5.4: SamuSignal orders from Firebase
   CheckAppPendingExpiry();     // v5.4: app pendings not filled in 60 min -> delete
   ManageMartingaleGrids();     // v5.4: grid TP/adds for ALL pairs even if chart pair is quiet
   if(ShowPanel) UpdatePanel();
}

//+------------------------------------------------------------------+
//|  MAIN TICK                                                        |
//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyReset();
   if(UseDailyLimits) CheckDailyLimitsMonitor();
   if(CloseOnWeekend) CheckWeekendClose();

   ManageOCOPending();
   ManageMartingaleGrids();

   if(ShowPanel) UpdatePanel();
}

//+------------------------------------------------------------------+
//|  SESSION LOG — capture closed deals                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ManageOCOPending();          // a pending may have just filled -> remove leftovers instantly
   if(!HistoryDealSelect(trans.deal)) return;

   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY) return;

   long mg = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(mg != MagicNumber && !(ManageManualTrades && mg==0)) return;

   double pl = HistoryDealGetDouble(trans.deal, DEAL_PROFIT)
             + HistoryDealGetDouble(trans.deal, DEAL_SWAP)
             + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   datetime dt = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);

   for(int i=4;i>0;i--)
   { g_LogTime[i]=g_LogTime[i-1]; g_LogText[i]=g_LogText[i-1]; g_LogPL[i]=g_LogPL[i-1]; }
   g_LogTime[0] = StringSubstr(TimeToString(dt, TIME_SECONDS), 11, 8);
   g_LogText[0] = "CLOSE";
   g_LogPL[0]   = pl;
   if(g_LogN < 5) g_LogN++;
}

//+------------------------------------------------------------------+
//|  WHICH POSITIONS BELONG TO US                                     |
//|  EA magic  OR  (manual / mobile-app trades with magic 0)          |
//+------------------------------------------------------------------+
bool IsAllowedSymbol(string sym)
{
   if(AllowedSymbolsCSV=="") return true;   // whitelist off -> everything allowed
   string list = AllowedSymbolsCSV;
   StringToUpper(list);
   string symU = sym;
   StringToUpper(symU);
   string parts[];
   int n = StringSplit(list, ',', parts);
   for(int i=0;i<n;i++)
   {
      string p = parts[i];
      StringTrimLeft(p); StringTrimRight(p);
      if(p=="") continue;
      if(symU==p) return true;
   }
   return false;
}

bool IsOurPos()
{
   long m = posInfo.Magic();
   if(!IsAllowedSymbol(posInfo.Symbol())) return false;   // not on the whitelist -> leave it alone
   if(m==MagicNumber) return true;
   if(ManageManualTrades && m==0) return true;
   return false;
}

// Re-syncs grid state from real open positions (works for trades placed
// from mobile/terminal and survives EA restarts).
void SyncGridState(string sym, int gi, int cnt)
{
   datetime firstT=0; double lot=0; int dir=0; double entryPx=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      if(firstT==0 || posInfo.Time()<firstT)
      {
         firstT  = posInfo.Time();
         lot     = posInfo.Volume();
         dir     = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
         entryPx = posInfo.PriceOpen();
      }
   }
   if(dir==0) return;
   if(cnt==1 || g_GLot[gi]<=0 || g_GDir[gi]==0)
   { g_GDir[gi]=dir; g_GLot[gi]=lot; g_GEntry[gi]=entryPx; }
   g_GAdds[gi] = MathMax(0, cnt-1);
}

//+------------------------------------------------------------------+
//|  GRID STATE HELPERS                                               |
//+------------------------------------------------------------------+
int GridIndex(string sym, bool createIfMissing)
{
   for(int i=0; i<g_GCount; i++) if(g_GSym[i]==sym) return i;
   if(createIfMissing && g_GCount<MAX_GRID_SYMS)
   {
      g_GSym[g_GCount]  = sym;
      g_GDir[g_GCount]  = 0;
      g_GAdds[g_GCount] = 0;
      g_GLot[g_GCount]  = 0;
      g_GEntry[g_GCount]= 0;
      return g_GCount++;
   }
   return -1;
}

double GetSymbolFloatingPL(string sym)
{
   double t=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      t += posInfo.Profit()+posInfo.Swap();
   }
   return t;
}

int GetSymbolPositionCount(string sym)
{
   int c=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      c++;
   }
   return c;
}

void CloseSymbolTrades(string sym)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      trade.PositionClose(posInfo.Ticket());
   }
}

//+------------------------------------------------------------------+
//|  OPEN NEXT GRID ADD (same direction, same lot as the grid start)  |
//+------------------------------------------------------------------+
void OpenGridAdd(string sym, int gi)
{
   if(UseDailyLimits && g_DailyLimitHit) return;
   if(PositionsTotal() >= MaxOpenTrades)
   { Print("PERSONAL FX GRID: MAX OPEN TRADES — skip add on ", sym); return; }

   if(UseSpreadFilter)
   {
      long sp = SymbolInfoInteger(sym, SYMBOL_SPREAD);
      if(sp > MaxSpread_Points)
      { Print("PERSONAL FX GRID: spread too high — skip add on ", sym); return; }
   }

   trade.SetTypeFillingBySymbol(sym);   // v5.4: correct filling mode for THIS pair
   ENUM_ORDER_TYPE type = (g_GDir[gi]==1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = (type==ORDER_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_ASK)
                                         : SymbolInfoDouble(sym,SYMBOL_BID);
   double lot = g_GLot[gi];

   double marginReq=0, freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(OrderCalcMargin(type,sym,lot,price,marginReq) && marginReq>0 && marginReq>freeMargin)
   { Print("PERSONAL FX GRID [",sym,"]: NO MARGIN for add — need $",DoubleToString(marginReq,2)); return; }

   bool ok=(type==ORDER_TYPE_BUY) ?
           trade.Buy(lot,sym,price,0,0,"PFX_GRID_ADD"):
           trade.Sell(lot,sym,price,0,0,"PFX_GRID_ADD");

   if(ok)
   {
      g_GAdds[gi]++;
      g_DailyTradeCount++;
      Print("PERSONAL FX GRID [",sym,"]: Add #",g_GAdds[gi]," opened @ ",
            DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)),
            " | Lot ",DoubleToString(lot,2));
      if(UsePushNotify)
         SendNotification("PERSONAL FX GRID: Add #"+IntegerToString(g_GAdds[gi])+" "+sym+
                          " "+(g_GDir[gi]==1?"BUY":"SELL")+" @ "
                          +DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)));
   }
   else
      Print("PERSONAL FX GRID [",sym,"]: Add FAILED [",trade.ResultRetcode(),"] ",
            trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//|  BROKER-SIDE TP SYNC  (v5.0 fixed: clamp, always restamp)         |
//|  Puts a real TP price on every position so it shows in the MT5    |
//|  T/P column (desktop + mobile).                                   |
//|   1 trade  : TP price worth  Grid_TP_Dollar x (lot/0.01)          |
//|   2+ trades: ONE common TP price on ALL legs = basket average     |
//|              price shifted so the whole basket nets a flat        |
//|              Grid_BasketTP_Dollar                                  |
//+------------------------------------------------------------------+
double ProfitPerPriceUnitPerLot(string sym)
{
   double pt    = SymbolInfoDouble(sym, SYMBOL_POINT);
   double price = SymbolInfoDouble(sym, SYMBOL_BID);
   if(pt<=0 || price<=0) return 0;
   double delta = pt*100.0;
   double p=0;
   if(OrderCalcProfit(ORDER_TYPE_BUY, sym, 1.0, price, price+delta, p) && p>0)
      return p/delta;
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(ts>0 && tv>0) return tv/ts;
   return 0;
}

void SyncTPLevels(string sym, int cnt)
{
   if(cnt<=0) return;

   double V=0, W=0, swapSum=0;
   int    dir=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      int d = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      if(dir==0) dir=d;
      else if(dir!=d) return;              // mixed directions -> don't touch TP
      V       += posInfo.Volume();
      W       += posInfo.Volume()*posInfo.PriceOpen();
      swapSum += posInfo.Swap();
   }
   if(V<=0 || dir==0) return;

   double target = (cnt==1) ? Grid_TP_Dollar*(V/0.01) : Grid_BasketTP_Dollar;
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0) return;

   double avg    = W/V;
   double dist   = (target - swapSum)/(k*V);
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double tpPrice = NormalizeDouble((dir==1) ? avg+dist : avg-dist, digits);

   // Respect the broker's minimum stop distance — CLAMP, never skip.
   // (Skipping used to "freeze" older legs at a stale TP once the grid grew
   //  large enough that the true target price sat inside this distance.)
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minDist = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt + 2*pt;
   if(dir==1)
   {
      double floorPx = NormalizeDouble(bid + minDist, digits);
      if(tpPrice < floorPx) tpPrice = floorPx;
   }
   else
   {
      double ceilPx = NormalizeDouble(ask - minDist, digits);
      if(tpPrice > ceilPx) tpPrice = ceilPx;
   }

   // Always (re)stamp EVERY leg to the SAME fresh price — no tolerance-skip,
   // so every leg of the same pair shows one identical, current TP.
   bool changed=false; bool anyFail=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      if(posInfo.TakeProfit()==tpPrice) continue;   // already exactly set
      if(trade.PositionModify(posInfo.Ticket(), posInfo.StopLoss(), tpPrice))
         changed=true;
      else
      {
         anyFail=true;
         Print("PERSONAL FX TP: modify failed ",sym," #",posInfo.Ticket(),
               " [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
      }
   }
   if(changed)
      Print("PERSONAL FX TP: ",sym," ",(dir==1?"BUY":"SELL")," x",cnt,
            " -> TP ",DoubleToString(tpPrice,digits),
            " (target $",DoubleToString(target,2),")",
            anyFail ? " [some legs failed, see above]" : "");
}

//+------------------------------------------------------------------+
//|  MAIN GRID ENGINE — runs every tick for every symbol currently    |
//|  holding our positions.                                            |
//|  cnt==1 : single trade -> individual TP ($3 / 0.01 lot)           |
//|  cnt>=2 : grid active  -> basket TP (flat $3, combined) only      |
//|  either : if price moves against us by the next gap step AND      |
//|           adds < max -> open next same-side same-lot grid trade   |
//+------------------------------------------------------------------+
void ManageMartingaleGrids()
{
   string symsOpen[50]; int symCount=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym = posInfo.Symbol();
      bool found=false;
      for(int k=0; k<symCount; k++) if(symsOpen[k]==sym){ found=true; break; }
      if(!found && symCount<50) symsOpen[symCount++]=sym;
   }

   for(int k=0; k<symCount; k++)
   {
      string sym = symsOpen[k];
      int    gi  = GridIndex(sym, true);
      int    cnt = GetSymbolPositionCount(sym);
      if(cnt==0) continue;

      SyncGridState(sym, gi, cnt);

      double totalPL = GetSymbolFloatingPL(sym);
      bool   closedThisTick = false;

      if(cnt==1)
      {
         for(int i=0; i<PositionsTotal(); i++)
         {
            if(!posInfo.SelectByIndex(i)) continue;
            if(!IsOurPos()) continue;
            if(posInfo.Symbol()!=sym) continue;

            double lotFactor = posInfo.Volume()/0.01;
            double tpTarget  = Grid_TP_Dollar*lotFactor;
            double profit    = posInfo.Profit()+posInfo.Swap();

            if(profit >= tpTarget)
            {
               ulong tk = posInfo.Ticket();
               if(trade.PositionClose(tk))
               {
                  g_GAdds[gi] = 0;
                  closedThisTick = true;
                  if(UsePushNotify)
                     SendNotification("PERSONAL FX GRID: TP Hit +$"+DoubleToString(profit,2)+" "+sym);
               }
            }
            break; // only one position in this branch
         }
      }
      else // cnt >= 2 -> grid active, basket mode
      {
         if(totalPL >= Grid_BasketTP_Dollar)
         {
            CloseSymbolTrades(sym);
            g_GAdds[gi] = 0;
            closedThisTick = true;
            if(UsePushNotify)
               SendNotification("PERSONAL FX GRID: Basket TP! +$"+DoubleToString(totalPL,2)+" "+sym);
         }
      }

      if(closedThisTick) continue;

      // next grid-add trigger: PRICE-distance mode (default) or legacy $-loss mode
      bool doAdd=false;
      if(g_GAdds[gi] < Grid_MaxAdds)
      {
         if(UsePriceDistanceGap && g_GEntry[gi]>0)
         {
            double step  = (g_GAdds[gi]+1) * Grid_Gap_Price;
            double bid   = SymbolInfoDouble(sym, SYMBOL_BID);
            double ask   = SymbolInfoDouble(sym, SYMBOL_ASK);
            if(g_GDir[gi]==1  && bid <= g_GEntry[gi]-step) doAdd=true;   // buy grid: price fell $step
            if(g_GDir[gi]==-1 && ask >= g_GEntry[gi]+step) doAdd=true;   // sell grid: price rose $step
         }
         else
         {
            double nextThreshold = -((g_GAdds[gi]+1) * Grid_Gap_Dollar);   // legacy: cumulative basket $-loss
            if(totalPL <= nextThreshold) doAdd=true;
         }
      }
      if(doAdd) OpenGridAdd(sym, gi);

      // keep real broker-side TP in sync (also right after a new add)
      SyncTPLevels(sym, GetSymbolPositionCount(sym));
      // if g_GAdds[gi] >= Grid_MaxAdds -> do nothing, wait for basket TP only
   }
}

//+------------------------------------------------------------------+
//|  OCO PENDING (v5.3)                                               |
//|  You place Buy Limit + Sell Limit (stops also work) on one or     |
//|  many pairs. When one of them FILLS:                              |
//|   SAME PAIR : the OPPOSITE-side pending on THAT pair is deleted.  |
//|               Other pairs keep their pendings and work the same.  |
//|   ALL PAIRS : every pending (all pairs) placed BEFORE that fill   |
//|               is deleted -> only one pair gets traded.            |
//|  Only pendings placed BEFORE the fill are removed, so a fresh     |
//|  pending you place later is never touched. Works after EA/VPS     |
//|  restart too (fill is read from the position's opening order).    |
//|  The filled trade itself runs on the normal grid rules.           |
//+------------------------------------------------------------------+
bool IsPendingType(long t)
{
   return (t==ORDER_TYPE_BUY_LIMIT  || t==ORDER_TYPE_SELL_LIMIT ||
           t==ORDER_TYPE_BUY_STOP   || t==ORDER_TYPE_SELL_STOP  ||
           t==ORDER_TYPE_BUY_STOP_LIMIT || t==ORDER_TYPE_SELL_STOP_LIMIT);
}

int PendingDir(long t)
{
   if(t==ORDER_TYPE_BUY_LIMIT  || t==ORDER_TYPE_BUY_STOP  || t==ORDER_TYPE_BUY_STOP_LIMIT)  return 1;
   if(t==ORDER_TYPE_SELL_LIMIT || t==ORDER_TYPE_SELL_STOP || t==ORDER_TYPE_SELL_STOP_LIMIT) return -1;
   return 0;
}

bool IsOurMagicOnSymbol(string sym, long mg)
{
   if(!IsAllowedSymbol(sym)) return false;
   if(mg==MagicNumber) return true;
   if(ManageManualTrades && mg==0) return true;
   return false;
}

string OcoModeText()
{
   if(OCO_Mode==OCO_SAME_PAIR) return "SAME PAIR";
   if(OCO_Mode==OCO_ALL_PAIRS) return "ALL PAIRS";
   return "OFF";
}

int CountOurPendings()
{
   int c=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      ulong tk=OrderGetTicket(i);
      if(tk==0) continue;
      if(!IsPendingType(OrderGetInteger(ORDER_TYPE))) continue;
      if(!IsOurMagicOnSymbol(OrderGetString(ORDER_SYMBOL), OrderGetInteger(ORDER_MAGIC))) continue;
      c++;
   }
   return c;
}

void ManageOCOPending()
{
   if(OCO_Mode==OCO_OFF) return;
   if(OrdersTotal()==0)  return;

   // 1) our open positions that were opened by a PENDING order (= a fill)
   string fSym[60]; int fDir[60]; long fTime[60]; int nF=0;
   for(int i=0; i<PositionsTotal() && nF<60; i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      long ident = posInfo.Identifier();          // = ticket of the order that opened it
      if(!HistoryOrderSelect((ulong)ident)) continue;
      long ot = HistoryOrderGetInteger((ulong)ident, ORDER_TYPE);
      if(!IsPendingType(ot)) continue;            // market / grid-add trade -> not an OCO trigger
      fSym[nF]  = posInfo.Symbol();
      fDir[nF]  = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      fTime[nF] = posInfo.TimeMsc();
      nF++;
   }
   if(nF==0) return;

   // 2) delete leftover pendings that belong to the same batch (placed before the fill)
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      if(!IsPendingType(ot)) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(!IsOurMagicOnSymbol(sym, OrderGetInteger(ORDER_MAGIC))) continue;
      long setup = OrderGetInteger(ORDER_TIME_SETUP_MSC);
      int  odir  = PendingDir(ot);
      string otxt = EnumToString((ENUM_ORDER_TYPE)ot);
      double opx  = OrderGetDouble(ORDER_PRICE_OPEN);

      string trigSym=""; int trigDir=0;
      for(int f=0; f<nF; f++)
      {
         if(setup >= fTime[f]) continue;          // placed AFTER that fill -> new order, keep it
         if(OCO_Mode==OCO_ALL_PAIRS)
         { trigSym=fSym[f]; trigDir=fDir[f]; break; }
         if(fSym[f]==sym && fDir[f]==-odir)
         { trigSym=fSym[f]; trigDir=fDir[f]; break; }
      }
      if(trigSym=="") continue;

      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(trade.OrderDelete(tk))
      {
         string msg = "PERSONAL FX OCO: "+trigSym+" "+(trigDir==1?"BUY":"SELL")+
                      " filled -> removed "+sym+" "+otxt+" @ "+DoubleToString(opx,dg);
         Print(msg);
         if(UsePushNotify) SendNotification(msg);
      }
      else
         Print("PERSONAL FX OCO: delete FAILED ",sym," #",tk," [",trade.ResultRetcode(),"] ",
               trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//|  SAMUSIGNAL APP BRIDGE (v5.4)                                     |
//|  App (Chart Analysis) writes orders to Firebase:                  |
//|    /personalfx/orders/<key> = {pair, type, entry, at, status:NEW} |
//|  type = BUYMARKET / BUYLIMIT / BUYSTOP / SELLMARKET / SELLLIMIT /  |
//|         SELLSTOP. entry = 0 for MARKET.                           |
//|  EA: every AppPollSec reads the list, places each NEW order once  |
//|  with THIS EA's lot (no SL/TP -> grid rules manage it) and writes |
//|  status back: PLACED / FAILED / SKIP / STALE / EXPIRED.           |
//|  MT5: Tools > Options > Expert Advisors > "Allow WebRequest" and  |
//|  add the Firebase URL (same as FirebaseURL input).                |
//+------------------------------------------------------------------+
string AppBase()
{
   string u = FirebaseURL;
   StringTrimLeft(u); StringTrimRight(u);
   while(StringLen(u)>0 && StringGetCharacter(u, StringLen(u)-1)=='/')
      u = StringSubstr(u, 0, StringLen(u)-1);
   if(u!="" && StringFind(u,"http")!=0) u = "https://"+u;
   return u;
}

string AppUrl(string path)
{
   string u = AppBase()+"/personalfx/"+path+".json";
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
   return u;
}

// method: GET / POST. extraHdr e.g. "X-HTTP-Method-Override: PATCH\r\n"
bool AppHttp(string method, string url, string body, string extraHdr, string &resp, int &code)
{
   char data[], result[];
   string rh;
   string hdr = "Content-Type: application/json\r\n" + extraHdr;
   if(body!="")
   {
      int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
      if(n>0) ArrayResize(data, n-1);              // drop trailing 0
   }
   ResetLastError();
   code = WebRequest(method, url, hdr, 4000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_AppStatus = "URL ALLOW KARO";
         if(!g_AppUrlWarned)
         {
            g_AppUrlWarned = true;
            Alert("PERSONAL FX: MT5 > Tools > Options > Expert Advisors > 'Allow WebRequest' ON karke ye URL add karo: ", AppBase());
         }
      }
      else g_AppStatus = "NET ERR "+IntegerToString(err);
      return false;
   }
   resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   return (code>=200 && code<300);
}

string AppJsonSafe(string t)
{
   StringReplace(t, "\\", "/");
   StringReplace(t, "\"", "'");
   StringReplace(t, "{", "(");
   StringReplace(t, "}", ")");
   return t;
}

// write status back to the app (PATCH via method override — works on every MT5 build)
void AppSetStatus(string key, string status, string msg)
{
   long nowMs = (long)TimeGMT()*1000;
   string body = "{\"status\":\""+status+"\",\"msg\":\""+AppJsonSafe(msg)+"\",\"done\":"+IntegerToString(nowMs)+"}";
   string resp; int code;
   if(!AppHttp("POST", AppUrl("orders/"+key), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code))
      Print("PERSONAL FX APP: status write failed for ", key, " (", code, ")");
   Print("PERSONAL FX APP: ", key, " -> ", status, " | ", msg);
}

bool AppIsDone(string key)
{
   for(int i=0;i<g_AppDoneN;i++) if(g_AppDone[i]==key) return true;
   return false;
}
void AppMarkDone(string key)
{
   if(AppIsDone(key)) return;
   if(g_AppDoneN>=300)                       // keep the newest 299
   { for(int i=1;i<300;i++) g_AppDone[i-1]=g_AppDone[i]; g_AppDoneN=299; }
   g_AppDone[g_AppDoneN++] = key;
}

// ---- tiny JSON readers (flat objects written by the app) ----
string JsonStr(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return "";
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return "";
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ')) p++;
   if(p>=n || StringGetCharacter(obj,p)!='"') return "";
   int q = p+1;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if(c=='\\') { q+=2; continue; }
      if(c=='"') break;
      q++;
   }
   return StringSubstr(obj, p+1, q-p-1);
}

double JsonNum(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return 0;
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return 0;
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ' || StringGetCharacter(obj,p)=='"')) p++;
   int q = p;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if((c>='0' && c<='9') || c=='.' || c=='-' || c=='+' || c=='e' || c=='E') q++;
      else break;
   }
   if(q==p) return 0;
   return StringToDouble(StringSubstr(obj, p, q-p));
}

// split {"k1":{...},"k2":{...}} into keys[] / objs[]
int AppSplitRecords(string s, string &keys[], string &objs[])
{
   int n = StringLen(s), cnt = 0;
   ArrayResize(keys,0); ArrayResize(objs,0);
   int i = StringFind(s, "{");
   if(i<0) return 0;
   i++;
   while(i<n)
   {
      // find next key
      while(i<n && StringGetCharacter(s,i)!='"' && StringGetCharacter(s,i)!='}') i++;
      if(i>=n || StringGetCharacter(s,i)=='}') break;
      int k1 = i+1, k2 = StringFind(s, "\"", k1);
      if(k2<0) break;
      string key = StringSubstr(s, k1, k2-k1);
      i = StringFind(s, ":", k2);
      if(i<0) break;
      i++;
      while(i<n && StringGetCharacter(s,i)==' ') i++;
      if(i>=n) break;
      if(StringGetCharacter(s,i)!='{')
      {  // not an object -> skip value
         while(i<n && StringGetCharacter(s,i)!=',' && StringGetCharacter(s,i)!='}') i++;
         continue;
      }
      int depth=0; bool inStr=false; int start=i;
      for(; i<n; i++)
      {
         ushort c = StringGetCharacter(s,i);
         if(inStr){ if(c=='\\'){ i++; continue; } if(c=='"') inStr=false; continue; }
         if(c=='"') inStr=true;
         else if(c=='{') depth++;
         else if(c=='}'){ depth--; if(depth==0){ i++; break; } }
      }
      ArrayResize(keys,cnt+1); ArrayResize(objs,cnt+1);
      keys[cnt]=key; objs[cnt]=StringSubstr(s, start, i-start);
      cnt++;
   }
   return cnt;
}

string AppResolve(string pair)
{
   if(AppSymbolSuffix!="")
   {
      string s = pair+AppSymbolSuffix;
      if(SymbolSelect(s,true)) return s;
      return "";
   }
   return ResolveSymbol(pair);
}

// already placed earlier (EA restart / status write failed)? -> look for our comment
bool AppAlreadyPlaced(string tag, ulong &ticket)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      if(OrderGetString(ORDER_COMMENT)==tag){ ticket=tk; return true; }
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Comment()==tag){ ticket=posInfo.Ticket(); return true; }
   }
   return false;
}

// a fresher app order on the same pair replaces the older app pending (called only right before sending)
void AppReplaceOld(string sym)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;
      if(trade.OrderDelete(tk))
      {
         string k = StringSubstr(cm,4);
         if(StringLen(k)>=19) AppSetStatus(k, "REPLACED", "#"+IntegerToString((long)tk)+" naye order ne jagah li");
      }
   }
}

void ProcessAppOrder(string key, string obj)
{
   string pair = JsonStr(obj, "pair");
   string typ  = JsonStr(obj, "type");
   double entry = JsonNum(obj, "entry");
   long   atMs  = (long)JsonNum(obj, "at");
   string tag   = "PFXA"+key;                  // order comment = link back to the app record
   AppMarkDone(key);                           // never handle the same key twice in this session

   ulong oldTk=0;
   if(AppAlreadyPlaced(tag, oldTk))
   { AppSetStatus(key, "PLACED", "#"+IntegerToString((long)oldTk)+" (pehle se laga hua)"); return; }

   long nowMs = (long)TimeGMT()*1000;
   if(atMs>0 && nowMs-atMs > (long)AppMaxOrderAgeMin*60000)
   { AppSetStatus(key, "STALE", IntegerToString((nowMs-atMs)/60000)+" min purana - EA band tha? dobara bhejo"); return; }

   bool isBuy = (StringFind(typ,"BUY")==0);
   bool isSell= (StringFind(typ,"SELL")==0);
   string kind = isBuy ? StringSubstr(typ,3) : (isSell ? StringSubstr(typ,4) : "");
   if((!isBuy && !isSell) || (kind!="MARKET" && kind!="LIMIT" && kind!="STOP"))
   { AppSetStatus(key, "FAILED", "type samajh nahi aaya: "+typ); return; }

   string sym = AppResolve(pair);
   if(sym=="" || SymbolInfoDouble(sym,SYMBOL_BID)<=0)
   { AppSetStatus(key, "FAILED", pair+" symbol broker pe nahi mila (AppSymbolSuffix check karo)"); return; }
   if(!IsAllowedSymbol(sym))
   { AppSetStatus(key, "SKIP", sym+" AllowedSymbolsCSV me nahi"); return; }
   if(UseDailyLimits && g_DailyLimitHit)
   { AppSetStatus(key, "SKIP", "daily limit hit - aaj naya trade nahi"); return; }
   if(IsWeekendBlocked())
   { AppSetStatus(key, "SKIP", "weekend - trading band"); return; }
   if(GetSymbolPositionCount(sym) > 0)
   { AppSetStatus(key, "SKIP", sym+" pe grid pehle se chal raha hai"); return; }
   if(PositionsTotal() >= MaxOpenTrades)
   { AppSetStatus(key, "SKIP", "MaxOpenTrades poora"); return; }

   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double lot = NormalizeLot(sym, g_LotInput);              // lot = THIS EA's input (panel +/- if changed)
   trade.SetTypeFillingBySymbol(sym);

   // ---------- MARKET ----------
   if(kind=="MARKET")
   {
      if(UseSpreadFilter && SymbolInfoInteger(sym,SYMBOL_SPREAD) > MaxSpread_Points)
      { AppSetStatus(key, "SKIP", "spread zyada: "+IntegerToString(SymbolInfoInteger(sym,SYMBOL_SPREAD))+" pts"); return; }
      ENUM_ORDER_TYPE ot = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double px = isBuy ? ask : bid;
      double marginReq=0;
      if(OrderCalcMargin(ot, sym, lot, px, marginReq) && marginReq>0 && marginReq>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
      { AppSetStatus(key, "FAILED", "margin nahi - chahiye $"+DoubleToString(marginReq,2)); return; }
      AppReplaceOld(sym);
      bool ok = isBuy ? trade.Buy(lot, sym, px, 0, 0, tag) : trade.Sell(lot, sym, px, 0, 0, tag);
      if(!ok)
      { AppSetStatus(key, "FAILED", "MT5 error "+IntegerToString(trade.ResultRetcode())+" "+trade.ResultRetcodeDescription()); return; }
      g_DailyTradeCount++;
      int gi = GridIndex(sym, true);
      if(gi>=0){ g_GDir[gi]=isBuy?1:-1; g_GAdds[gi]=0; g_GLot[gi]=lot; g_GEntry[gi]=trade.ResultPrice()>0?trade.ResultPrice():px; }
      string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+(isBuy?"BUY":"SELL")+" "+DoubleToString(lot,2)+" @ "+DoubleToString(trade.ResultPrice()>0?trade.ResultPrice():px,dg);
      AppSetStatus(key, "PLACED", m);
      if(UsePushNotify) SendNotification("PERSONAL FX APP: "+sym+" "+m);
      return;
   }

   // ---------- PENDING (LIMIT / STOP) ----------
   if(entry<=0)
   { AppSetStatus(key, "FAILED", "entry price nahi mila"); return; }
   entry = NormalizeDouble(entry, dg);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt;
   double fz   = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL)*pt;
   if(fz>minD) minD=fz;
   string wrong="";
   if(isBuy  && kind=="LIMIT" && entry >= ask-minD) wrong="price pehle hi entry ke neeche/paas aa gaya";
   if(isBuy  && kind=="STOP"  && entry <= ask+minD) wrong="price pehle hi entry ke upar/paas chala gaya";
   if(isSell && kind=="LIMIT" && entry <= bid+minD) wrong="price pehle hi entry ke upar/paas chala gaya";
   if(isSell && kind=="STOP"  && entry >= bid-minD) wrong="price pehle hi entry ke neeche/paas aa gaya";
   if(wrong!="")
   { AppSetStatus(key, "FAILED", wrong+" (live "+DoubleToString(isBuy?ask:bid,dg)+") - dobara analyze karo"); return; }

   ENUM_ORDER_TYPE pot = isBuy ? (kind=="LIMIT"?ORDER_TYPE_BUY_LIMIT:ORDER_TYPE_BUY_STOP)
                               : (kind=="LIMIT"?ORDER_TYPE_SELL_LIMIT:ORDER_TYPE_SELL_STOP);
   double marginReq=0;
   if(OrderCalcMargin(isBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL, sym, lot, entry, marginReq) && marginReq>0
      && marginReq>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   { AppSetStatus(key, "FAILED", "margin nahi - chahiye $"+DoubleToString(marginReq,2)); return; }

   AppReplaceOld(sym);
   bool ok=false;
   if(pot==ORDER_TYPE_BUY_LIMIT)  ok = trade.BuyLimit (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_BUY_STOP)   ok = trade.BuyStop  (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_SELL_LIMIT) ok = trade.SellLimit(lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_SELL_STOP)  ok = trade.SellStop (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(!ok)
   { AppSetStatus(key, "FAILED", "MT5 error "+IntegerToString(trade.ResultRetcode())+" "+trade.ResultRetcodeDescription()); return; }
   g_DailyTradeCount++;
   string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+(isBuy?"BUY ":"SELL ")+kind+" "+DoubleToString(lot,2)+" @ "+DoubleToString(entry,dg)
              +" | "+IntegerToString(AppPendingExpiryMin)+" min";
   AppSetStatus(key, "PLACED", m);
   if(UsePushNotify) SendNotification("PERSONAL FX APP: "+sym+" "+m);
}

void PollAppOrders()
{
   if(!UseAppBridge || FirebaseURL=="") { g_AppStatus="OFF"; return; }
   if(MQLInfoInteger(MQL_TESTER)) return;                       // WebRequest not allowed in tester
   if(TimeLocal()-g_AppLastPoll < MathMax(1,AppPollSec)) return;
   g_AppLastPoll = TimeLocal();

   string resp; int code;
   if(!AppHttp("GET", AppUrl("orders"), "", "", resp, code))
   {
      if(code>0) g_AppStatus = (code==401 || code==403) ? "FIREBASE RULES" : "HTTP "+IntegerToString(code);
      return;
   }
   g_AppLastOk = TimeLocal();
   g_AppStatus = "ON | "+TimeToString(g_AppLastOk, TIME_SECONDS);
   StringTrimLeft(resp); StringTrimRight(resp);
   if(resp=="" || resp=="null") return;

   string keys[], objs[];
   int n = AppSplitRecords(resp, keys, objs);
   // oldest first, so orders are placed in the order you sent them
   for(int a=0;a<n-1;a++)
      for(int b=a+1;b<n;b++)
         if(JsonNum(objs[b],"at") < JsonNum(objs[a],"at"))
         { string tk=keys[a]; keys[a]=keys[b]; keys[b]=tk; string to=objs[a]; objs[a]=objs[b]; objs[b]=to; }
   for(int i=0;i<n;i++)
   {
      if(JsonStr(objs[i],"status")!="NEW") continue;
      if(AppIsDone(keys[i])) continue;
      ProcessAppOrder(keys[i], objs[i]);
   }
}

// app pendings (comment "PFXA<key>") not filled in AppPendingExpiryMin -> delete + tell app
void CheckAppPendingExpiry()
{
   if(AppPendingExpiryMin<=0) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(TimeCurrent()-setup < AppPendingExpiryMin*60) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(trade.OrderDelete(tk))
      {
         Print("PERSONAL FX APP: ", sym, " pending #", tk, " ", AppPendingExpiryMin, " min me nahi bhara -> hata diya");
         if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER) && StringLen(cm)>=23)
            AppSetStatus(StringSubstr(cm,4), "EXPIRED", "#"+IntegerToString((long)tk)+" "+IntegerToString(AppPendingExpiryMin)+" min me nahi bhara - hata diya");
      }
   }
}

//+------------------------------------------------------------------+
//|  MANUAL TRADE ENTRY — starts a fresh grid on this symbol          |
//+------------------------------------------------------------------+
void ExecuteManualTrade(ENUM_ORDER_TYPE type)
{
   string sym = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;

   if(sym=="" || SymbolInfoDouble(sym,SYMBOL_BID)<=0)
   { Alert("PERSONAL FX: Invalid/unknown symbol \""+sym+"\" — type it correctly and press SET"); return; }

   if(!IsAllowedSymbol(sym))
   { Alert("PERSONAL FX: \""+sym+"\" is not in AllowedSymbolsCSV — add it in inputs or clear the whitelist"); return; }

   if(UseDailyLimits && g_DailyLimitHit)
   { Alert("PERSONAL FX: DAILY LIMIT HIT — no new trades today"); return; }

   if(GetSymbolPositionCount(sym) > 0)
   { Alert("PERSONAL FX: Grid already active on "+sym+" — wait for it to close first."); return; }

   if(IsWeekendBlocked())
   { Alert("PERSONAL FX: WEEKEND - TRADING CLOSED"); return; }

   if(UseSpreadFilter)
   {
      long sp = SymbolInfoInteger(sym, SYMBOL_SPREAD);
      if(sp > MaxSpread_Points)
      { Alert("PERSONAL FX: SPREAD TOO HIGH: "+IntegerToString(sp)+" PTS"); return; }
   }

   if(PositionsTotal() >= MaxOpenTrades)
   { Alert("PERSONAL FX: MAX OPEN TRADES REACHED"); return; }

   double price = (type==ORDER_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_ASK)
                                         : SymbolInfoDouble(sym,SYMBOL_BID);
   double lot = NormalizeLot(sym, g_LotInput);
   trade.SetTypeFillingBySymbol(sym);   // v5.4

   double marginReq=0, freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!OrderCalcMargin(type, sym, lot, price, marginReq))
      Print("PERSONAL FX: OrderCalcMargin failed, err ", GetLastError());

   if(marginReq>0 && marginReq>freeMargin)
   {
      Alert("PERSONAL FX: NO MONEY! Lot ", DoubleToString(lot,2),
            " needs $", DoubleToString(marginReq,2),
            " margin, Free = $", DoubleToString(freeMargin,2));
      return;
   }

   bool ok=(type==ORDER_TYPE_BUY) ?
           trade.Buy(lot,sym,price,0,0,"PFX_MANUAL"):
           trade.Sell(lot,sym,price,0,0,"PFX_MANUAL");

   if(ok)
   {
      g_DailyTradeCount++;
      int gi = GridIndex(sym, true);
      g_GDir[gi]   = (type==ORDER_TYPE_BUY) ? 1 : -1;
      g_GAdds[gi]  = 0;
      g_GLot[gi]   = lot;
      g_GEntry[gi] = price;
      Print("PERSONAL FX: ", EnumToString(type), " opened on ", sym,
            " | Lot ", DoubleToString(lot,2), " | Grid started");
   }
   else
      Alert("PERSONAL FX: Trade FAILED [", trade.ResultRetcode(), "] ",
            trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//|  DAILY LIMITS                                                     |
//+------------------------------------------------------------------+
void CheckDailyLimitsMonitor()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double eqPL  = equity - g_DayStartBalance;
   g_DailyPL = balance - g_DayStartBalance;

   if(eqPL <= -MaxDailyLoss && !g_DailyLimitHit)
   {
      g_DailyLimitHit = true;
      CloseAllExemptMaxedGrids();
      if(UsePushNotify)
         SendNotification("PERSONAL FX: Daily Loss Limit! $"+DoubleToString(eqPL,2));
   }
   if(eqPL >= MaxDailyProfit && !g_DailyLimitHit)
   {
      g_DailyLimitHit = true;
      CloseAllOurTrades();
      if(UsePushNotify)
         SendNotification("PERSONAL FX: Daily Target Hit! +$"+DoubleToString(eqPL,2));
   }
}

void CloseAllOurTrades()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      trade.PositionClose(posInfo.Ticket());
   }
   for(int g=0; g<g_GCount; g++) g_GAdds[g]=0;
}

// Daily-loss version: skips grids that already hit Grid_MaxAdds — they
// keep running and wait only for their own basket TP (per your instruction).
void CloseAllExemptMaxedGrids()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym = posInfo.Symbol();
      int gi = GridIndex(sym, false);
      if(DDExemptMaxedGrids && gi>=0 && g_GAdds[gi]>=Grid_MaxAdds) continue; // let it ride
      trade.PositionClose(posInfo.Ticket());
   }
}

//+------------------------------------------------------------------+
//|  WEEKEND / DAILY RESET                                            |
//+------------------------------------------------------------------+
bool IsWeekendBlocked()
{
   if(!CloseOnWeekend) return false;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   string now=StringFormat("%02d:%02d",dt.hour,dt.min);
   if(dt.day_of_week==5 && now>=FridayCloseTime) return true;
   if(dt.day_of_week==6 || dt.day_of_week==0)   return true;
   return false;
}

void CheckWeekendClose()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   string now=StringFormat("%02d:%02d",dt.hour,dt.min);
   if(dt.day_of_week==5 && now>=FridayCloseTime) CloseAllOurTrades();
}

void CheckDailyReset()
{
   MqlDateTime now,last;
   TimeToStruct(TimeCurrent(),now);
   TimeToStruct(g_LastDayReset,last);
   if(now.day!=last.day)
   {
      g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_DailyPL=0; g_DailyTradeCount=0; g_DailyLimitHit=false;
      g_LastDayReset = TimeCurrent();
      g_LogN=0;
      Print("PERSONAL FX: New trading day — daily limits reset");
   }
}

//+------------------------------------------------------------------+
//|  HELPERS                                                           |
//+------------------------------------------------------------------+
double NormalizeLot(string sym, double lot)
{
   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double vstp = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(vstp <= 0) vstp = 0.01;
   lot = MathFloor(lot/vstp) * vstp;
   lot = MathMax(vmin, MathMin(vmax, lot));
   return NormalizeDouble(lot, 2);
}

void AdjustLot(int dir)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step<=0) step=0.01;
   g_LotInput = NormalizeDouble(g_LotInput + dir*step, 2);
   g_LotInput = MathMax(MinLot, MathMin(MaxLot, g_LotInput));
}

// Resolves user-typed text (e.g. "gbpusd") to the broker's exact symbol
// name (e.g. "GBPUSD.m"). Returns "" if nothing matches.
string ResolveSymbol(string typed)
{
   string want = typed;
   StringToUpper(want);
   StringTrimLeft(want);
   StringTrimRight(want);
   if(want=="") return "";

   // exact match first
   if(SymbolSelect(want,true)) return want;

   // else scan the full symbol list for one that STARTS WITH the typed text
   int total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false);
      string sUp = s;
      StringToUpper(sUp);
      if(StringFind(sUp,want)==0)
      {
         if(SymbolSelect(s,true)) return s;
      }
   }
   return "";
}

int SC_Digits()
{
   string s0 = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;
   int d=(int)SymbolInfoInteger(s0, SYMBOL_DIGITS);
   return MathMax(2, MathMin(5, d));
}

int CountActiveGrids()
{
   string syms[50]; int n=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym=posInfo.Symbol();
      bool found=false;
      for(int k=0;k<n;k++) if(syms[k]==sym){found=true;break;}
      if(!found && n<50) syms[n++]=sym;
   }
   return n;
}

double GetSymbolVolume(string sym)
{
   double v=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      v += posInfo.Volume();
   }
   return v;
}

double GetTotalFloatingPL()
{
   double t=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      t += posInfo.Profit()+posInfo.Swap();
   }
   return t;
}

//+------------------------------------------------------------------+
//|  CHART EVENTS — buttons + F-keys                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
      if(ShowPanel && MathAbs(w-g_LastChartW)>4) RebuildPanel();
      return;
   }

   if(id==CHARTEVENT_KEYDOWN && EnableFKeys)
   {
      if(lp==117) ExecuteManualTrade(ORDER_TYPE_BUY);    // F6
      if(lp==118) ExecuteManualTrade(ORDER_TYPE_SELL);   // F7
      if(lp==119) CloseAllOurTrades();                   // F8
      return;
   }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && sp==ED_SYM)
   { ApplySymbolFromEdit(); return; }

   if(id!=CHARTEVENT_OBJECT_CLICK) return;

   if(sp==BT_BUY  || sp==BT_F6) ExecuteManualTrade(ORDER_TYPE_BUY);
   if(sp==BT_SELL || sp==BT_F7) ExecuteManualTrade(ORDER_TYPE_SELL);
   if(sp==BT_LDN)                AdjustLot(-1);
   if(sp==BT_LUP)                AdjustLot(+1);
   if(sp==BT_CALL || sp==BT_F8)  CloseAllOurTrades();
   if(sp==BT_SYMSET)             ApplySymbolFromEdit();

   ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   ChartRedraw(0);
}

// Reads whatever is typed in the symbol box, resolves it against the
// broker's symbol list, and if valid makes it the active trading symbol.
void ApplySymbolFromEdit()
{
   string typed = ObjectGetString(0, ED_SYM, OBJPROP_TEXT);
   string resolved = ResolveSymbol(typed);
   if(resolved=="")
   {
      Alert("PERSONAL FX: Symbol \""+typed+"\" not found with this broker");
      ObjectSetInteger(0, ED_SYM, OBJPROP_COLOR, QT_RED);
      return;
   }
   g_ActiveSymbol = resolved;
   ObjectSetString(0, ED_SYM, OBJPROP_TEXT, resolved);
   ObjectSetInteger(0, ED_SYM, OBJPROP_COLOR, QT_GREEN);
   Print("PERSONAL FX: Active trading symbol set to ", resolved);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|  PANEL — BUILD  (FULL-WIDTH 3 columns, DPI-aware)                 |
//|  [1] ACTIVE PAIR & ORDER ENTRY | [3] ACCOUNT        | [6] MONITOR  |
//|  [2] GRID SETTINGS             | [4] RISK CONTROL   |              |
//|                                | [5] RECENT CLOSES  |              |
//+------------------------------------------------------------------+
int SC(int v) { return (int)MathRound(v*g_S); }

string DotPad(string label, int n)
{
   string r = label + " ";
   while(StringLen(r) < n) r += ".";
   return r;
}

void Sect(string n, string txt, int colx, int y)
{
   Rect("PFX_S_"+n, colx, y, g_CW, SC(24), QT_SECT);
   Lbl("PFX_SL_"+n, txt, colx+SC(8), y+SC(4), QT_AMBER, Panel_FontSize, QFONT);
}

void MakeRow(string id, string label, int colx, int y)
{
   Lbl("PFX_"+id+"_L", DotPad(label,g_LabChars), colx+SC(10), y, QT_AMBERD, Panel_FontSize, QFONT);
   Lbl("PFX_"+id+"_V", "--", colx+g_ValX, y, QT_WHITE, Panel_FontSize, QFONT);
}

void SetV(string id, string txt, color c)
{
   ObjectSetString(0,"PFX_"+id+"_V",OBJPROP_TEXT,txt);
   ObjectSetInteger(0,"PFX_"+id+"_V",OBJPROP_COLOR,c);
}

void OutBtn(string inner, string txt, int x, int y, int w, int h,
            color border, color fg, int fsz)
{
   int b=MathMax(2,SC(2));
   Rect("PFX_BR_"+inner, x, y, w, h, border);
   Btn(inner, txt, x+b, y+b, w-2*b, h-2*b, QT_DARKBTN, fg, fsz);
}

void RebuildPanel()
{
   ObjectsDeleteAll(0, "PFX_");
   BuildPanel();
   UpdatePanel();
}

void BuildPanel()
{
   int x=Panel_X, y=Panel_Y;
   int fs=Panel_FontSize;

   // ---- fit to the chart width ----
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   int PW  = MathMax(SC(760), chartW - 2*Panel_X);
   int gap = SC(8);
   int cw  = (PW - 2*SC(8) - 2*gap)/3;
   g_CW = cw;

   int c1=x+SC(8);
   int c2=c1+cw+gap;
   int c3=c2+cw+gap;

   int RH=SC(fs*2+4);            // row pitch
   int SH=SC(24);                // section header height
   int y0=y+SC(40);

   // text metrics (Consolas is monospaced, ~0.55 em wide)
   int charW = (int)MathRound(fs*96.0/72.0*g_DpiS*0.55);
   if(charW<6) charW=6;
   int avail = (cw-SC(20))/charW;
   g_LabChars = MathMax(14, MathMin(22, avail-18));
   g_ValX     = SC(10) + (g_LabChars+1)*charW;

   // background + borders (resized to real height at the end)
   Rect("PFX_BG",  x, y, PW, 100, QT_BG);
   Rect("PFX_B1",  x, y, PW, 2, QT_BORDER);
   Rect("PFX_B2",  x, y+98, PW, 2, QT_BORDER);
   Rect("PFX_B3",  x, y, 2, 100, QT_BORDER);
   Rect("PFX_B4",  x+PW-2, y, 2, 100, QT_BORDER);

   Rect("PFX_TITLE_BG", x, y, PW, SC(32), QT_AMBER);
   Lbl ("PFX_TITLE",   "PERSONAL FX v5.4 - MARTINGALE GRID  |  MANUAL + APP ENTRY + $ BASKET TP + OCO",
        x+SC(12), y+SC(7), C'0,0,0', fs+1, QFONT);
   LblR("PFX_TITLE_R", "F6 BUY    F7 SELL    F8 CLOSE ALL", x+PW-SC(12), y+SC(8), C'0,0,0', fs);

   // ================= COLUMN 1 =================
   int yy=y0;
   Sect("SY","[1] ACTIVE PAIR & ORDER ENTRY", c1, yy);          yy+=SH+SC(6);
   int editW = MathMin(cw*55/100, SC(320));
   string es = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;
   Edit(ED_SYM, es, c1+SC(10), yy, editW, SC(28), QT_DARKBTN, QT_GREEN, fs+1);
   OutBtn(BT_SYMSET, "SET", c1+SC(10)+editW+SC(8), yy, SC(90), SC(28), QT_AMBER, QT_AMBER, fs+1);
                                                                yy+=SC(28)+SC(10);
   int bw = (cw-SC(30))/2;
   OutBtn(BT_BUY,  "BUY  \x25B2", c1+SC(10),        yy, bw, SC(46), QT_GREEN, QT_GREEN, fs+3);
   OutBtn(BT_SELL, "SELL \x25BC", c1+SC(20)+bw,     yy, bw, SC(46), QT_RED,   QT_RED,   fs+3);
                                                                yy+=SC(46)+SC(10);
   int lx = c1+SC(10)+10*charW;
   Lbl ("PFX_LOT_L", DotPad("LOT SIZE",10), c1+SC(10), yy+SC(4), QT_AMBERD, fs, QFONT);
   Btn (BT_LDN,"-", lx, yy, SC(30), SC(26), QT_DARKBTN, QT_AMBER, fs+2);
   Lbl ("PFX_LOT_V","0.01", lx+SC(30)+SC(12), yy+SC(4), QT_AMBER, fs+1, QFONT);
   Btn (BT_LUP,"+", lx+SC(30)+SC(12)+6*charW, yy, SC(30), SC(26), QT_DARKBTN, QT_AMBER, fs+2);
                                                                yy+=SC(26)+SC(10);
   OutBtn(BT_CALL,"CLOSE ALL  [F8]", c1+SC(10), yy, cw-SC(20), SC(30), QT_RED, QT_RED, fs);
                                                                yy+=SC(30)+SC(12);

   Sect("GS","[2] GRID SETTINGS", c1, yy);                      yy+=SH+SC(4);
   MakeRow("GTP","TP / 0.01 LOT", c1, yy);                      yy+=RH;
   MakeRow("GGP","ADD GAP",       c1, yy);                      yy+=RH;
   MakeRow("GBT","BASKET TP",     c1, yy);                      yy+=RH;
   MakeRow("GMX","MAX ADDS",      c1, yy);                      yy+=RH;
   MakeRow("GOC","OCO PENDING",   c1, yy);                      yy+=RH;
   MakeRow("GAB","APP BRIDGE",    c1, yy);                      yy+=RH;
   int bottom1=yy;

   // ================= COLUMN 2 =================
   yy=y0;
   Sect("AC","[3] ACCOUNT", c2, yy);                            yy+=SH+SC(4);
   MakeRow("BAL","BALANCE",   c2, yy);                          yy+=RH;
   MakeRow("EQ", "EQUITY",    c2, yy);                          yy+=RH;
   MakeRow("DPL","DAILY P&L", c2, yy);                          yy+=RH;
   MakeRow("FPL","FLOAT P&L", c2, yy);                          yy+=RH+SC(8);

   Sect("RM","[4] RISK CONTROL", c2, yy);                       yy+=SH+SC(4);
   MakeRow("TD","TRADES TODAY", c2, yy);                        yy+=RH;
   MakeRow("DD","DAILY DD",     c2, yy);                        yy+=RH;
   MakeRow("DT","DAILY TARGET", c2, yy);                        yy+=RH+SC(8);

   Sect("LG","[5] RECENT CLOSES", c2, yy);                      yy+=SH+SC(4);
   for(int i=0;i<5;i++)
   {
      Lbl("PFX_LGT"+IntegerToString(i), "--", c2+SC(10),               yy, QT_DOTS,  fs-1, QFONT);
      Lbl("PFX_LGX"+IntegerToString(i), " ",  c2+SC(10)+10*charW,      yy, QT_WHITE, fs-1, QFONT);
      Lbl("PFX_LGP"+IntegerToString(i), " ",  c2+SC(10)+18*charW,      yy, QT_DOTS,  fs-1, QFONT);
      yy+=RH-SC(4);
   }
   int bottom2=yy;

   // ================= COLUMN 3 =================
   yy=y0;
   Sect("GM","[6] GRID MONITOR - LIVE (ANY PAIR)", c3, yy);    yy+=SH+SC(4);
   int mPair = SC(10);
   int mAdds = SC(10) + 14*charW;
   int mPL   = SC(10) + 20*charW;
   int mNext = SC(10) + 31*charW;
   Lbl("PFX_GMH0","PAIR / SIDE",  c3+mPair, yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH1","ADDS",         c3+mAdds, yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH2","BASKET P&L",   c3+mPL,   yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH3","NEXT ADD",     c3+mNext, yy, QT_AMBERD, fs-1, QFONT);
   yy+=RH;
   for(int i=0;i<MAX_GRID_ROWS;i++)
   {
      string k=IntegerToString(i);
      Lbl("PFX_GMS"+k, "--", c3+mPair, yy, QT_WHITE, fs, QFONT);
      Lbl("PFX_GMA"+k, "--", c3+mAdds, yy, QT_DOTS,  fs, QFONT);
      Lbl("PFX_GMP"+k, "--", c3+mPL,   yy, QT_DOTS,  fs, QFONT);
      Lbl("PFX_GMN"+k, "--", c3+mNext, yy, QT_DOTS,  fs, QFONT);
      yy+=RH-SC(4);
   }
   int bottom3=yy;

   // ---- final panel height ----
   int bottom = MathMax(bottom1, MathMax(bottom2, bottom3));
   int PH = bottom - y + SC(10);
   Rect("PFX_BG",  x, y, PW, PH, QT_BG);
   Rect("PFX_B2",  x, y+PH-2, PW, 2, QT_BORDER);
   Rect("PFX_B3",  x, y, 2, PH, QT_BORDER);
   Rect("PFX_B4",  x+PW-2, y, 2, PH, QT_BORDER);
}

//+------------------------------------------------------------------+
//|  PANEL — UPDATE                                                   |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double floatPL = GetTotalFloatingPL();
   double eqPL    = equity - g_DayStartBalance;
   double balPL   = balance - g_DayStartBalance;

   SetV("BAL","$"+DoubleToString(balance,2), QT_WHITE);
   SetV("EQ", "$"+DoubleToString(equity,2),  QT_WHITE);
   SetV("DPL",(balPL>=0?"+$":"-$")+DoubleToString(MathAbs(balPL),2),
              balPL>=0?QT_GREEN:QT_RED);
   SetV("FPL",(floatPL>=0?"+$":"-$")+DoubleToString(MathAbs(floatPL),2),
              floatPL>=0?QT_GREEN:QT_RED);

   ObjectSetString(0,"PFX_LOT_V",OBJPROP_TEXT,DoubleToString(g_LotInput,2));

   SetV("TD", IntegerToString(g_DailyTradeCount), QT_WHITE);
   SetV("DD", (eqPL>=0?"+$":"-$")+DoubleToString(MathAbs(eqPL),2)
              +" / -$"+DoubleToString(MaxDailyLoss,2),
              eqPL<=-MaxDailyLoss*0.7?QT_RED:QT_WHITE);
   SetV("DT", "+$"+DoubleToString(MathMax(balPL,0),2)+" / +$"
              +DoubleToString(MaxDailyProfit,0), QT_GREEN);

   if(UsePriceDistanceGap)
      SetV("GTP","$"+DoubleToString(Grid_TP_Dollar,2)+" /0.01L", QT_WHITE);
   else
      SetV("GTP","$"+DoubleToString(Grid_TP_Dollar,2)+" /0.01L", QT_WHITE);
   if(UsePriceDistanceGap)
      SetV("GGP", DoubleToString(Grid_Gap_Price,SC_Digits()) +" price", QT_WHITE);
   else
      SetV("GGP","$"+DoubleToString(Grid_Gap_Dollar,2), QT_WHITE);
   SetV("GBT","$"+DoubleToString(Grid_BasketTP_Dollar,2)+" flat", QT_WHITE);
   SetV("GMX",IntegerToString(Grid_MaxAdds), QT_WHITE);
   if(OCO_Mode==OCO_OFF) SetV("GOC","OFF", QT_AMBERD);
   else SetV("GOC",(OCO_Mode==OCO_ALL_PAIRS?"ALL":"PAIR")+" | "+IntegerToString(CountOurPendings())+" pend", QT_GREEN);
   SetV("GAB", g_AppStatus, (g_AppStatus=="OFF") ? QT_AMBERD : (StringFind(g_AppStatus,"ON")==0 ? QT_GREEN : QT_RED));

   // ---- Grid monitor rows ----
   string symsOpen[50]; int symCount=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym=posInfo.Symbol();
      bool found=false;
      for(int k=0;k<symCount;k++) if(symsOpen[k]==sym){found=true;break;}
      if(!found && symCount<50) symsOpen[symCount++]=sym;
   }

   for(int i=0;i<MAX_GRID_ROWS;i++)
   {
      if(i<symCount)
      {
         string sym=symsOpen[i];
         int gi = GridIndex(sym,false);
         double pl = GetSymbolFloatingPL(sym);
         string dirTxt = (gi>=0 && g_GDir[gi]==1) ? "BUY" : "SELL";
         int adds = (gi>=0) ? g_GAdds[gi] : 0;
         string addsTxt = IntegerToString(adds)+"/"+IntegerToString(Grid_MaxAdds);
         color plC = pl>=0?QT_GREEN:QT_RED;
         if(gi>=0 && g_GAdds[gi]>=Grid_MaxAdds) plC = QT_AMBER; // maxed out, waiting for TP

         ObjectSetString(0,"PFX_GMS"+IntegerToString(i),OBJPROP_TEXT, sym+" "+dirTxt);
         ObjectSetString(0,"PFX_GMA"+IntegerToString(i),OBJPROP_TEXT, addsTxt);
         ObjectSetString(0,"PFX_GMP"+IntegerToString(i),OBJPROP_TEXT,
                        (pl>=0?"+$":"-$")+DoubleToString(MathAbs(pl),2));
         ObjectSetInteger(0,"PFX_GMP"+IntegerToString(i),OBJPROP_COLOR,plC);
         string nxt;
         if(adds>=Grid_MaxAdds) nxt="MAXED";
         else if(UsePriceDistanceGap && gi>=0 && g_GEntry[gi]>0)
         {
            double step = (adds+1)*Grid_Gap_Price;
            double lvl  = (g_GDir[gi]==1) ? g_GEntry[gi]-step : g_GEntry[gi]+step;
            nxt = DoubleToString(lvl,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS));
         }
         else nxt = "-$"+DoubleToString((adds+1)*Grid_Gap_Dollar,0);
         ObjectSetString(0,"PFX_GMN"+IntegerToString(i),OBJPROP_TEXT,nxt);
         ObjectSetInteger(0,"PFX_GMN"+IntegerToString(i),OBJPROP_COLOR,(adds>=Grid_MaxAdds)?QT_AMBER:QT_WHITE);
      }
      else
      {
         ObjectSetString(0,"PFX_GMS"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetString(0,"PFX_GMA"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetString(0,"PFX_GMP"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetInteger(0,"PFX_GMP"+IntegerToString(i),OBJPROP_COLOR,QT_DOTS);
         ObjectSetString(0,"PFX_GMN"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetInteger(0,"PFX_GMN"+IntegerToString(i),OBJPROP_COLOR,QT_DOTS);
      }
   }

   // ---- recent closes log ----
   for(int i=0;i<5;i++)
   {
      string n1="PFX_LGT"+IntegerToString(i);
      string n2="PFX_LGX"+IntegerToString(i);
      string n3="PFX_LGP"+IntegerToString(i);
      if(i<g_LogN)
      {
         ObjectSetString(0,n1,OBJPROP_TEXT,g_LogTime[i]);
         ObjectSetString(0,n2,OBJPROP_TEXT,g_LogText[i]);
         ObjectSetString(0,n3,OBJPROP_TEXT,(g_LogPL[i]>=0?"+$":"-$")+DoubleToString(MathAbs(g_LogPL[i]),2));
         ObjectSetInteger(0,n3,OBJPROP_COLOR,g_LogPL[i]>=0?QT_GREEN:QT_RED);
      }
      else
      {
         ObjectSetString(0,n1,OBJPROP_TEXT,"--");
         ObjectSetString(0,n2,OBJPROP_TEXT," ");
         ObjectSetString(0,n3,OBJPROP_TEXT," ");
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|  UI PRIMITIVES                                                     |
//+------------------------------------------------------------------+
void Rect(string n,int x,int y,int w,int h,color c)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,c);
   ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void Lbl(string n,string t,int x,int y,color c,int f,string font)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void LblR(string n,string t,int x,int y,color c,int f)
{
   Lbl(n,t,x,y,c,f,QFONT);
   ObjectSetInteger(0,n,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
}

void Btn(string n,string t,int x,int y,int w,int h,color bg,color fg,int f)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,QFONT);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void Edit(string n,string t,int x,int y,int w,int h,color bg,color fg,int f)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,QT_AMBERD);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,QFONT);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,true);
}

//+------------------------------------------------------------------+
//|  END PERSONAL FX v5.4 — MARTINGALE GRID + OCO + APP BRIDGE       |
//+------------------------------------------------------------------+
