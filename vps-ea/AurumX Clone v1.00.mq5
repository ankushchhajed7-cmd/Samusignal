//+------------------------------------------------------------------+
//|                                        AurumX Clone v1.00.mq5    |
//|                                        Ankush New Vision         |
//|                                                                  |
//|  Vantage demo par chal rahe "AurumX" scalper ka clone — sirf      |
//|  REAL ACCOUNT par slippage naapne ke 1 din ke test ke liye.       |
//|  Niyam (SAMU Backtest Lab research/aurumx, ticks se pakde):       |
//|   - Disha: M1 pichhli band candle ka close vs EMA(100) M1         |
//|            (upar = sirf BUY, neeche = sirf SELL)                  |
//|   - Khaali ho to STOP order price se $0.60 door, price ke peeche  |
//|     sirf achhi taraf khisakta (har 3 sec)                         |
//|   - Fill par SL $0.50, TP nahi; profit $0.40 par trailing SL      |
//|     best se $0.40 peeche                                          |
//|   - Ek waqt me 1 trade, 0.01 lot                                  |
//|  SURAKSHA ($50 account): din ka loss $3 -> sab band, din me max   |
//|  40 trade, spread $0.20 se upar nayi order nahi. Din 07:00 IST.   |
//|  LOG: MQL5\Files\AurumX_Clone_<acc>.csv — har trade ka maanga     |
//|  price vs asli fill (entry + exit slippage). Investor Account     |
//|  Watcher me JournalFiles = AurumX_Clone_{acc}.csv daalo to        |
//|  GitHub par aa jaata hai.                                         |
//|  v1.00 (25-Nov-2026) pehla version.                               |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property link      "https://github.com/ankushchhajed7-cmd"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

#define EA_NAME    "AurumX Clone"
#define EA_VERSION "v1.00"
#define PFX        "AXC_"
#define IST_SEC    19800

//--- inputs
input double InpLot          = 0.01;   // Lot (har trade)
input long   InpMagic        = 260001; // Magic number
input double InpDist         = 0.60;   // STOP order price se kitna door ($)
input double InpSL           = 0.50;   // Stop loss ($)
input double InpTrailStart   = 0.40;   // Itna profit ($) hone par trailing shuru
input double InpTrailDist    = 0.40;   // Trailing SL best price se kitna peeche ($)
input int    InpUpdSec       = 3;      // STOP order har itne sec me khisakta
input int    InpEmaPeriod    = 100;    // Disha: EMA period (M1)
input double InpMaxSpread    = 0.20;   // Spread is se zyada ($) to nayi order nahi
input double InpDayLossUsd   = 3.0;    // Din ka loss itna ($) -> sab band, din bhar ruk
input int    InpMaxTradesDay = 40;     // Din me max trade
input string InpResetIST     = "07:00";// Naya din (IST)
input string InpLogFile      = "AurumX_Clone_{acc}.csv"; // Slippage log (MQL5\Files)
input bool   InpDashboard    = true;   // Gold Luxe dashboard
input bool   InpHidePriceChart = true; // Dashboard ke peeche price chart chhupao

//--- state
CTrade   g_tr;
int      g_ema = INVALID_HANDLE;
int      g_side = 0;              // 1 BUY, -1 SELL (EMA se)
datetime g_lastMod = 0;
ulong    g_lastSlModMs = 0;
double   g_best = 0;
bool     g_paused = false, g_dayStop = false;
string   g_dayStopWhy = "";
long     g_dayKey = -1;
double   g_dayPL = 0;            // aaj band trades ka P/L
int      g_dayTrades = 0;
string   g_logName = "";
string   g_lastErr = ""; datetime g_lastErrT = 0;
uint     g_lastDash = 0;
// slippage tracking (ek waqt me ek position)
double   g_reqIn = 0, g_fillIn = 0, g_slipIn = 0, g_sprIn = 0, g_curSL = 0;
int      g_posDir = 0; datetime g_posT = 0; ulong g_posTicket = 0;
// aaj ke slippage aankde
int      g_nIn = 0, g_nOut = 0; double g_sumIn = 0, g_sumOut = 0;
// pichhli 10 band trades (dashboard)
string   g_rows[10]; int g_rowN = 0;

//====================================================================
//  helpers
//====================================================================
double   GmtOffH()             { return MathRound(((double)TimeTradeServer() - (double)TimeGMT()) / 3600.0); }
datetime NowServer()           { return MQLInfoInteger(MQL_TESTER) ? TimeCurrent() : TimeTradeServer(); }
datetime ToIst(const datetime srv) { return (datetime)((long)srv - (long)(GmtOffH() * 3600) + IST_SEC); }
int      ResetSec()            { string p[]; if(StringSplit(InpResetIST, ':', p) < 2) return 7 * 3600; return (int)StringToInteger(p[0]) * 3600 + (int)StringToInteger(p[1]) * 60; }
long     DayKeyOf(const datetime srv) { return (long)MathFloor(((double)ToIst(srv) - ResetSec()) / 86400.0); }
datetime DayStartSrv()         { long k = DayKeyOf(NowServer()); return (datetime)((long)(k * 86400 + ResetSec()) - IST_SEC + (long)(GmtOffH() * 3600)); }
double   Spread()              { return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID); }
double   Nz(const double p)    { return NormalizeDouble(p, _Digits); }
void     Err(const string s)   { g_lastErr = s; g_lastErrT = TimeCurrent(); Print(EA_NAME, ": ", s); }

bool MyPos(ulong &tk, int &dir, double &open, double &sl, double &pl)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic || PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      tk = t; dir = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 1 : -1;
      open = PositionGetDouble(POSITION_PRICE_OPEN); sl = PositionGetDouble(POSITION_SL);
      pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      return true;
     }
   return false;
  }
bool MyOrder(ulong &tk, int &dir, double &price)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0 || !OrderSelect(t)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != InpMagic || OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      long ty = OrderGetInteger(ORDER_TYPE);
      if(ty != ORDER_TYPE_BUY_STOP && ty != ORDER_TYPE_SELL_STOP) continue;
      tk = t; dir = ty == ORDER_TYPE_BUY_STOP ? 1 : -1; price = OrderGetDouble(ORDER_PRICE_OPEN);
      return true;
     }
   return false;
  }
void DeleteOrders()
  {
   ulong tk; int d; double p;
   for(int k = 0; k < 5 && MyOrder(tk, d, p); k++) if(!g_tr.OrderDelete(tk)) { Err("Order delete fail " + (string)g_tr.ResultRetcode()); break; }
  }
void CloseAll(const string why)
  {
   DeleteOrders();
   ulong tk; int d; double o, s, pl;
   for(int k = 0; k < 5 && MyPos(tk, d, o, s, pl); k++) if(!g_tr.PositionClose(tk)) { Err("Close fail " + (string)g_tr.ResultRetcode()); break; }
   Print(EA_NAME, ": CLOSE ALL - ", why);
  }

int Side()
  {
   double e[1], c[1];
   if(CopyBuffer(g_ema, 0, 1, 1, e) != 1) return 0;
   if(CopyClose(_Symbol, PERIOD_M1, 1, 1, c) != 1) return 0;
   return c[0] > e[0] ? 1 : -1;
  }

//====================================================================
//  din ka hisaab
//====================================================================
void DayRecalc()
  {
   g_dayPL = 0; g_dayTrades = 0;
   if(!HistorySelect(DayStartSrv(), TimeCurrent() + 86400)) return;
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      ulong d = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic || HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_IN) g_dayTrades++;
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_INOUT)
         g_dayPL += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
     }
  }
void NewDayCheck()
  {
   long k = DayKeyOf(NowServer());
   if(k == g_dayKey) return;
   g_dayKey = k; g_dayStop = false; g_dayStopWhy = "";
   g_nIn = g_nOut = 0; g_sumIn = g_sumOut = 0;
   DayRecalc();
  }

//====================================================================
//  log
//====================================================================
void LogLine(const string ln)
  {
   bool isNew = !FileIsExist(g_logName);
   int h = FileOpen(g_logName, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
   if(h == INVALID_HANDLE) return;
   if(isNew || FileSize(h) == 0) FileWriteString(h, "time_ist,ticket,side,req_in,fill_in,slip_in,spread_in,req_out,fill_out,slip_out,reason,hold_s,profit\r\n");
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, ln + "\r\n");
   FileClose(h);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagic || HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol) return;
   long en = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   double px = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
   if(en == DEAL_ENTRY_IN)
     {
      long ty = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
      g_posDir = ty == DEAL_TYPE_BUY ? 1 : -1;
      ulong ord = (ulong)HistoryDealGetInteger(trans.deal, DEAL_ORDER);
      g_reqIn = HistoryOrderSelect(ord) ? HistoryOrderGetDouble(ord, ORDER_PRICE_OPEN) : px;
      g_fillIn = px; g_slipIn = (px - g_reqIn) * g_posDir;   // + = bura
      g_sprIn = Spread(); g_posT = TimeCurrent(); g_posTicket = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
      g_curSL = HistoryOrderSelect(ord) ? HistoryOrderGetDouble(ord, ORDER_SL) : 0;
      g_best = px; g_dayTrades++;
      g_nIn++; g_sumIn += g_slipIn;
     }
   else if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_INOUT)
     {
      double pf = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
      long rs = HistoryDealGetInteger(trans.deal, DEAL_REASON);
      string why = rs == DEAL_REASON_SL ? "SL" : rs == DEAL_REASON_TP ? "TP" : rs == DEAL_REASON_EXPERT ? "EA" : "KHUD";
      double slipOut = 0, reqOut = px;
      if(rs == DEAL_REASON_SL && g_curSL > 0) { reqOut = g_curSL; slipOut = (reqOut - px) * g_posDir; g_nOut++; g_sumOut += slipOut; }
      g_dayPL += pf;
      string ln = TimeToString(ToIst(TimeCurrent()), TIME_DATE | TIME_SECONDS) + "," + (string)g_posTicket + "," + (g_posDir > 0 ? "BUY" : "SELL") + "," +
                  DoubleToString(g_reqIn, _Digits) + "," + DoubleToString(g_fillIn, _Digits) + "," + DoubleToString(g_slipIn, _Digits) + "," + DoubleToString(g_sprIn, _Digits) + "," +
                  DoubleToString(reqOut, _Digits) + "," + DoubleToString(px, _Digits) + "," + DoubleToString(slipOut, _Digits) + "," + why + "," +
                  (string)(long)(TimeCurrent() - g_posT) + "," + DoubleToString(pf, 2);
      LogLine(ln);
      for(int i = 9; i > 0; i--) g_rows[i] = g_rows[i - 1];
      g_rows[0] = TimeToString(ToIst(TimeCurrent()), TIME_SECONDS) + "|" + (g_posDir > 0 ? "BUY" : "SELL") + "|" + DoubleToString(g_fillIn, _Digits) + "|" + DoubleToString(px, _Digits) + "|" +
                  DoubleToString(g_slipIn, 2) + "/" + DoubleToString(slipOut, 2) + "|" + DoubleToString(pf, 2);
      if(g_rowN < 10) g_rowN++;
      g_posDir = 0; g_curSL = 0;
     }
  }

//====================================================================
//  main logic (har tick)
//====================================================================
void Manage()
  {
   NewDayCheck();
   ulong ptk; int pdir; double popen, psl, ppl;
   bool hasPos = MyPos(ptk, pdir, popen, psl, ppl);

   // din ka loss (band + khuli)
   if(!g_dayStop && g_dayPL + (hasPos ? ppl : 0) <= -InpDayLossUsd)
     {
      g_dayStop = true; g_dayStopWhy = StringFormat("DIN KA LOSS $%.2f - aaj band", -(g_dayPL + (hasPos ? ppl : 0)));
      CloseAll("day loss"); return;
     }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(hasPos)
     {
      DeleteOrders();
      if(g_curSL == 0) g_curSL = psl;
      double cur = pdir > 0 ? bid : ask;
      if(pdir > 0 ? cur > g_best : cur < g_best || g_best == 0) g_best = cur;
      if((g_best - popen) * pdir >= InpTrailStart)
        {
         double ns = Nz(g_best - pdir * InpTrailDist);
         bool better = pdir > 0 ? ns > psl + 0.02 : (psl == 0 || ns < psl - 0.02);
         if(better && GetTickCount64() - g_lastSlModMs >= 300)
           {
            g_lastSlModMs = GetTickCount64();
            if(g_tr.PositionModify(ptk, ns, 0)) g_curSL = ns; else Err("SL modify fail " + (string)g_tr.ResultRetcode());
           }
        }
      return;
     }

   // khaali: STOP order
   int want = Side();
   g_side = want;
   ulong otk; int odir; double opx;
   bool hasOrd = MyOrder(otk, odir, opx);
   bool allowNew = !g_paused && !g_dayStop && g_dayTrades < InpMaxTradesDay && want != 0 && Spread() <= InpMaxSpread;
   if(!allowNew) { if(hasOrd) DeleteOrders(); return; }
   if(hasOrd && odir != want) { DeleteOrders(); hasOrd = false; }
   double stops = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(!hasOrd)
     {
      double px = want > 0 ? Nz(bid + InpDist) : Nz(ask - InpDist);
      if(want > 0 && px - ask < stops) px = Nz(ask + stops + _Point);
      if(want < 0 && bid - px < stops) px = Nz(bid - stops - _Point);
      double sl = Nz(px - want * InpSL);
      bool ok = want > 0 ? g_tr.BuyStop(InpLot, px, _Symbol, sl, 0, ORDER_TIME_GTC, 0, "AurumX Clone")
                         : g_tr.SellStop(InpLot, px, _Symbol, sl, 0, ORDER_TIME_GTC, 0, "AurumX Clone");
      if(!ok) Err("STOP order fail " + (string)g_tr.ResultRetcode() + " " + g_tr.ResultRetcodeDescription());
      g_lastMod = TimeCurrent();
      return;
     }
   if(TimeCurrent() - g_lastMod < InpUpdSec) return;
   double np = want > 0 ? Nz(bid + InpDist) : Nz(ask - InpDist);
   bool better = want > 0 ? np < opx - 0.01 : np > opx + 0.01;
   if(want > 0 && np - ask < stops) better = false;
   if(want < 0 && bid - np < stops) better = false;
   if(better)
     {
      if(!g_tr.OrderModify(otk, np, Nz(np - want * InpSL), 0, ORDER_TIME_GTC, 0)) Err("STOP modify fail " + (string)g_tr.ResultRetcode());
      g_lastMod = TimeCurrent();
     }
  }

//====================================================================
//  GOLD LUXE DASHBOARD (full screen)
//====================================================================
#define C_BG     C'0,0,0'
#define C_PANEL  C'20,18,11'
#define C_LINE   C'74,61,26'
#define C_GOLD   C'212,175,55'
#define C_GOLD2  C'243,215,122'
#define C_TXT    C'233,228,212'
#define C_MUT    C'143,136,122'
#define C_OK     C'79,209,139'
#define C_BAD    C'255,93,93'
#define C_WARN   C'255,181,71'
#define F_SERIF  "Georgia"
#define F_SANS   "Segoe UI"
#define F_MONO   "Consolas"

double g_s = 1.0, g_k = 1.0;
int    P(const double v) { return (int)MathRound(v * g_s * g_k); }
int    FontPt(const double px) { return (int)MathMax(7, MathRound(px * g_s * 0.75)); }
void   Del(const string nm) { ObjectDelete(0, PFX + nm); }
string Dot() { return " " + ShortToString(0x00B7) + " "; }
string Spaced(const string s) { string o = ""; int n = StringLen(s); for(int i = 0; i < n; i++) o += StringSubstr(s, i, 1) + (i < n - 1 ? " " : ""); return o; }
string Money(double v) { return (v < 0 ? "-$" : "$") + DoubleToString(MathAbs(v), 2); }

void Rect(const string nm, const int x, const int y, const int w, const int h, const color bg, const color bd, const int z = 0)
  {
   string n = PFX + nm;
   if(ObjectFind(0, n) < 0)
     {
      ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, n, OBJPROP_BACK, false);
     }
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, MathMax(1, w)); ObjectSetInteger(0, n, OBJPROP_YSIZE, MathMax(1, h));
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, bd); ObjectSetInteger(0, n, OBJPROP_ZORDER, z);
  }
void Lbl(const string nm, const string txt, const int x, const int y, const double px, const color c, const string font = F_SANS, const bool right = false)
  {
   string n = PFX + nm;
   if(ObjectFind(0, n) < 0)
     {
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, n, OBJPROP_ZORDER, 5);
     }
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, right ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, n, OBJPROP_TEXT, txt == "" ? " " : txt);
   ObjectSetString(0, n, OBJPROP_FONT, font);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPt(px));
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
  }
void Btn(const string nm, const string txt, const int x, const int y, const int w, const int h, const color bg, const color fg)
  {
   string n = PFX + nm;
   if(ObjectFind(0, n) < 0)
     {
      ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, n, OBJPROP_ZORDER, 10);
     }
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetString(0, n, OBJPROP_TEXT, txt); ObjectSetString(0, n, OBJPROP_FONT, F_SANS);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPt(13));
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, C_GOLD); ObjectSetInteger(0, n, OBJPROP_STATE, false);
  }
void Bar(const string nm, const string title, const string valTxt, double frac, const color fill, const int x, const int y, const int w)
  {
   frac = MathMax(0, MathMin(1, frac));
   Lbl(nm + "_t", title, x, y, 10, C_GOLD);
   Lbl(nm + "_v", valTxt, x + w, y, 10, C_TXT, F_MONO, true);
   Rect(nm + "_tr", x, y + P(18), w, (int)MathMax(3, P(7)), C'48,41,20', C'48,41,20', 1);
   Rect(nm + "_f", x, y + P(18), (int)MathMax(1, w * frac), (int)MathMax(3, P(7)), fill, fill, 2);
  }
void Card(const string nm, const int x, const int y, const int w, const int h, const string title, const string val, const color vc, const string s1, const string s2)
  {
   Rect(nm, x, y, w, h, C_PANEL, C_LINE, 1);
   Lbl(nm + "_t", Spaced(title), x + P(12), y + P(9), 10, C_GOLD);
   Lbl(nm + "_v", val, x + P(12), y + P(25), 21, vc, F_SERIF);
   Lbl(nm + "_1", s1, x + P(12), y + P(58), 10, C_TXT);
   Lbl(nm + "_2", s2, x + P(12), y + P(75), 10, C_MUT);
  }

void Dash()
  {
   if(!InpDashboard) return;
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   int W = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS), H = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   if(W < 50 || H < 50) return;
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI); if(dpi <= 0) dpi = 96;
   g_k = dpi / 96.0;
   double Wl = W / g_k, Hl = H / g_k;
   g_s = MathMax(0.8, MathMin(2.2, MathMin(Wl / 1000.0, Hl / 420.0)));
   double LW = Wl / g_s, LH = Hl / g_s, M = 18, IW = LW - 2 * M;
   bool showInfo = LH >= 362, showTable = LH >= 400;
   Rect("bg", 0, 0, W, H, C_BG, C_BG, 0);

   datetime srv = NowServer();
   ulong ptk; int pdir; double popen, psl, ppl;
   bool hasPos = MyPos(ptk, pdir, popen, psl, ppl);
   ulong otk; int odir; double opx;
   bool hasOrd = MyOrder(otk, odir, opx);
   double today = g_dayPL + (hasPos ? ppl : 0);
   double sp = Spread();

   Lbl("brand", Spaced("AURUMX CLONE") + "   " + EA_VERSION, P(M), P(10), 11, C_GOLD);
   Lbl("sub", "Real slippage test" + Dot() + _Symbol + Dot() + "Magic " + (string)InpMagic + Dot() + "Lot " + DoubleToString(InpLot, 2), P(M), P(28), 10, C_MUT);
   Lbl("ist", "IST  " + TimeToString(ToIst(srv), TIME_SECONDS), P(M + IW), P(9), 13, C_GOLD2, F_MONO, true);
   Lbl("srv", "SERVER  " + TimeToString(srv, TIME_SECONDS), P(M + IW), P(28), 10, C_MUT, F_MONO, true);

   Lbl("eqT", Spaced("AAJ KA P/L"), P(M), P(52), 10, C_GOLD);
   Lbl("eq", (today >= 0 ? "+" : "") + Money(today), P(M), P(64), 38, today >= 0 ? C_GOLD : C_BAD, F_SERIF);
   Lbl("eqS", "Equity " + Money(AccountInfoDouble(ACCOUNT_EQUITY)) + "     Band trades " + Money(g_dayPL) + "     Trades " + (string)g_dayTrades + " / " + (string)InpMaxTradesDay +
       "     " + (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL ? "REAL ACCOUNT" : "DEMO ACCOUNT"), P(M), P(112), 10, C_MUT);
   int bw = P(120), bh = P(32);
   Btn("btnClose", "CLOSE ALL", P(M + IW) - bw, P(66), bw, bh, C'48,10,10', C_BAD);
   Btn("btnPause", g_paused ? "RESUME" : "PAUSE", P(M + IW) - 2 * bw - P(10), P(66), bw, bh, g_paused ? C_GOLD : C_PANEL, g_paused ? C_BG : C_GOLD);

   string al; color ac = C_GOLD2, ab = C'18,15,7';
   if(g_lastErr != "" && TimeCurrent() - g_lastErrT < 60) { al = g_lastErr; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_dayStop) { al = g_dayStopWhy + "  -  " + InpResetIST + " IST tak"; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_paused) { al = "PAUSED  -  nayi order band"; ac = C_WARN; ab = C'34,24,6'; }
   else if(g_dayTrades >= InpMaxTradesDay) { al = "AAJ KE MAX TRADES POORE  -  " + InpResetIST + " IST tak"; ac = C_WARN; ab = C'34,24,6'; }
   else if(sp > InpMaxSpread) { al = StringFormat("SPREAD HIGH $%.2f (max $%.2f)  -  nayi order ruki", sp, InpMaxSpread); ac = C_WARN; ab = C'34,24,6'; }
   else if(hasPos) { al = StringFormat("%s CHAL RAHI  -  entry %s, SL %s", pdir > 0 ? "BUY" : "SELL", DoubleToString(popen, _Digits), DoubleToString(psl, _Digits)); }
   else if(hasOrd) { al = StringFormat("%s STOP %s  -  price ke peeche chal raha", odir > 0 ? "BUY" : "SELL", DoubleToString(opx, _Digits)); }
   else al = "READY";
   Rect("al", P(M), P(136), P(IW), P(30), ab, ac, 1);
   Lbl("alT", al, P(M + 12), P(143), 11, ac);

   double gap = 10, cw = (IW - 3 * gap) / 4.0;
   string up = ShortToString(0x25B2), dn = ShortToString(0x25BC);
   Card("cT", P(M), P(176), P(cw), P(96), "TREND", g_side > 0 ? up + " BUY" : g_side < 0 ? dn + " SELL" : "-", g_side > 0 ? C_OK : g_side < 0 ? C_BAD : C_MUT, "M1 close vs EMA " + (string)InpEmaPeriod, "sirf isi disha me order");
   Card("cP", P(M + cw + gap), P(176), P(cw), P(96), "TRADE", hasPos ? Money(ppl) : hasOrd ? "STOP" : "-", hasPos ? (ppl >= 0 ? C_OK : C_BAD) : C_GOLD2,
        hasPos ? "Entry " + DoubleToString(popen, _Digits) : hasOrd ? "Order " + DoubleToString(opx, _Digits) : "Koi trade nahi",
        hasPos ? "SL " + DoubleToString(psl, _Digits) : StringFormat("Doori $%.2f", InpDist));
   Card("cD", P(M + 2 * (cw + gap)), P(176), P(cw), P(96), "TODAY", (string)g_dayTrades + " trades", C_GOLD2, "Band P/L " + Money(g_dayPL), "Reset " + InpResetIST + " IST");
   double aIn = g_nIn ? g_sumIn / g_nIn : 0, aOut = g_nOut ? g_sumOut / g_nOut : 0;
   Card("cS", P(M + 3 * (cw + gap)), P(176), P(cw), P(96), "SLIPPAGE", StringFormat("$%.2f", aIn + aOut), (aIn + aOut) > 0.05 ? C_BAD : C_OK,
        StringFormat("Entry avg $%.3f (%d)", aIn, g_nIn), StringFormat("SL exit avg $%.3f (%d)", aOut, g_nOut));

   double bg2 = 26, bwl = (IW - 2 * bg2) / 3.0;
   Bar("pD", "DD OF LIMIT", StringFormat("%s / %s", Money(MathMax(0, -today)), Money(InpDayLossUsd)), InpDayLossUsd > 0 ? -today / InpDayLossUsd : 0, C_BAD, P(M), P(284), P(bwl));
   Bar("pN", "TRADES", StringFormat("%d / %d", g_dayTrades, InpMaxTradesDay), InpMaxTradesDay > 0 ? (double)g_dayTrades / InpMaxTradesDay : 0, C_GOLD, P(M + bwl + bg2), P(284), P(bwl));
   Bar("pS", "SPREAD", StringFormat("$%.2f / $%.2f", sp, InpMaxSpread), InpMaxSpread > 0 ? sp / InpMaxSpread : 0, C_WARN, P(M + 2 * (bwl + bg2)), P(284), P(bwl));

   if(showInfo)
     {
      Lbl("info", StringFormat("STOP doori $%.2f", InpDist) + Dot() + StringFormat("SL $%.2f", InpSL) + Dot() + StringFormat("Trail %.2f / %.2f", InpTrailStart, InpTrailDist) +
          Dot() + "Update " + (string)InpUpdSec + "s" + Dot() + "EMA " + (string)InpEmaPeriod + " M1" + Dot() + "TP nahi", P(M), P(322), 10, C_MUT);
      Lbl("info2", "Din ka loss max " + Money(InpDayLossUsd) + Dot() + "Max " + (string)InpMaxTradesDay + " trade" + Dot() + "Log MQL5\\Files\\" + g_logName, P(M), P(340), 10, C_MUT);
     }
   else { Del("info"); Del("info2"); }

   double cx[6]; cx[0] = M; cx[1] = M + 110; cx[2] = M + 180; cx[3] = M + 290; cx[4] = M + 400; cx[5] = M + IW;
   string hd[6] = {"TIME (IST)", "TYPE", "ENTRY", "EXIT", "SLIP in/out", "P/L"};
   int maxRows = showTable ? (int)MathMax(0, MathMin(10, MathFloor((LH - 396) / 19.0))) : 0;
   if(showTable)
     {
      for(int c = 0; c < 6; c++) Lbl("th" + (string)c, hd[c], P(cx[c]), P(372), 9, C_GOLD, F_SANS, c == 5);
      Rect("thl", P(M), P(388), P(IW), 1, C_LINE, C_LINE, 1);
     }
   else { for(int c = 0; c < 6; c++) Del("th" + (string)c); Del("thl"); }
   int row = 0;
   for(int i = 0; i < g_rowN && row < maxRows; i++)
     {
      string f[]; if(StringSplit(g_rows[i], '|', f) < 6) continue;
      double y = 394 + row * 19; double pf = StringToDouble(f[5]);
      for(int c = 0; c < 6; c++)
         Lbl("r" + (string)row + "_" + (string)c, c == 5 ? Money(pf) : f[c], P(cx[c]), P(y), 10,
             c == 1 ? (f[1] == "BUY" ? C_OK : C_BAD) : c == 5 ? (pf >= 0 ? C_OK : C_BAD) : C_TXT, F_MONO, c == 5);
      row++;
     }
   for(int r = row; r < 10; r++) for(int c = 0; c < 6; c++) Del("r" + (string)r + "_" + (string)c);
   if(showTable && row == 0) Lbl("empty", "Abhi koi band trade nahi", P(M), P(396), 10, C_MUT); else Del("empty");
   ChartRedraw(0);
  }

//====================================================================
//  events
//====================================================================
int OnInit()
  {
   g_tr.SetExpertMagicNumber(InpMagic);
   g_tr.SetDeviationInPoints(50);
   g_ema = iMA(_Symbol, PERIOD_M1, InpEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(g_ema == INVALID_HANDLE) { Alert(EA_NAME, ": EMA handle nahi bana"); return INIT_FAILED; }
   string acc = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   g_logName = InpLogFile; StringReplace(g_logName, "{acc}", acc);
   g_dayKey = -1; NewDayCheck();
   if(InpDashboard) { if(InpHidePriceChart) ChartSetInteger(0, CHART_SHOW, false); Dash(); }
   EventSetTimer(1);
   PrintFormat("%s %s ready: %s, STOP $%.2f, SL $%.2f, trail %.2f/%.2f, din loss $%.2f, max %d trade, log %s",
               EA_NAME, EA_VERSION, AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL ? "REAL" : "DEMO", InpDist, InpSL, InpTrailStart, InpTrailDist, InpDayLossUsd, InpMaxTradesDay, g_logName);
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_ema != INVALID_HANDLE) IndicatorRelease(g_ema);
   ObjectsDeleteAll(0, PFX);
   ChartSetInteger(0, CHART_SHOW, true);
   ChartRedraw(0);
  }
void OnTick()
  {
   Manage();
   if(GetTickCount() - g_lastDash > 500) { g_lastDash = GetTickCount(); Dash(); }
  }
void OnTimer() { Dash(); }
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE) { Dash(); return; }
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == PFX + "btnPause") { g_paused = !g_paused; if(g_paused) DeleteOrders(); Print(EA_NAME, g_paused ? ": PAUSED" : ": RESUMED"); }
   else if(sparam == PFX + "btnClose") CloseAll("CLOSE ALL button");
   else return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   Dash();
  }
//+------------------------------------------------------------------+
