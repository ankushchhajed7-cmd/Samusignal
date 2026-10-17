//+------------------------------------------------------------------+
//|                                       BTC Trailing Manager v1.01  |
//|                                        Ankush New Vision          |
//|                                                                   |
//|  Buster BTC ("BTC Ea Tp Sl 1.23") me trailing ki setting nahi     |
//|  hai (sirf on/off). Ye EA usi account par ALAG chart par chalta   |
//|  hai.                                                             |
//|                                                                   |
//|  MODE = SHADOW (default, ZERO RISK):                              |
//|    Real SL ko bilkul nahi chhuta. Buster apne trailing ke saath   |
//|    waise hi chalta rahe (UseTrailingStop = true). Har naye Buster |
//|    trade par ye 4 trailing settings (A,B,C,D) "kagaz par" chalata |
//|    hai - har second price dekh kar virtual SL khiskata hai, aur   |
//|    real trade band hone ke baad bhi virtual trade tab tak follow  |
//|    karta hai jab tak uska virtual SL/TP na lage. Buster ka asli   |
//|    result bhi likhta hai. Investor Account Watcher v1.04 ye sab   |
//|    app tak bhejta hai -> Trailing tab me tulna.                   |
//|                                                                   |
//|  MODE = LIVE:                                                     |
//|    Upar wala shadow test chalta rahta hai, PLUS real SL ko "Live" |
//|    settings se khiskata hai. Tab Buster me UseTrailingStop=false. |
//|                                                                   |
//|  Kabhi naya trade nahi kholta, trade band nahi karta, TP nahi     |
//|  chhedta. LIVE me bhi SL sirf profit ki taraf, kabhi peeche nahi. |
//|                                                                   |
//|  Units: POINTS (Buster ke StopLoss jaisa). BTCUSD# par            |
//|  15000 points = 150 price = 0.01 lot par $1.50.                   |
//|                                                                   |
//|  CHANGELOG                                                        |
//|   v1.01 - SHADOW mode (default) + ek saath 4 settings ka virtual  |
//|           test, Buster ka REAL result, MQL5\Files\IW_shadow_*.jsonl|
//|           panel me har setting ka kul $. LIVE mode = v1.00 jaisa. |
//|   v1.00 - Pehla build: TrailStart/Distance/Step + Break-even.     |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property link      "https://github.com/ankushchhajed7-cmd"
#property version   "1.01"
#property strict

#include <Trade/Trade.mqh>

enum ENUM_TM_MODE
{
   TM_SHADOW = 0,   // SHADOW - sirf hisaab, real SL nahi chhuta (zero risk)
   TM_LIVE   = 1    // LIVE - real SL khiskata hai (Buster me trailing false)
};

input group "=== Mode ==="
input ENUM_TM_MODE Mode       = TM_SHADOW; // SHADOW = test only | LIVE = real SL bhi

input group "=== Kis trade ko manage kare ==="
input long   MagicNumber      = 111111;  // Buster ka Magic Number (0 = magic mat dekho)
input bool   OnlyThisSymbol   = true;    // sirf is chart ke symbol ke trades

input group "=== LIVE trailing (sirf LIVE mode me, POINTS) ==="
input int    TrailStart       = 15000;   // itne points profit ke baad trailing shuru
input int    TrailDistance    = 12000;   // SL price se itne points peeche
input int    TrailStep        = 1000;    // SL tabhi khiske jab kam se kam itna aage ja sake
input bool   UseBreakEven     = false;   // break-even chalu
input int    BreakEvenAt      = 10000;   // itne points profit par
input int    BreakEvenLock    = 500;     // SL = open + itne points

input group "=== SHADOW test: 4 settings ek saath (POINTS) ==="
input int    SetA_Start       = 10000;   // A: trailing shuru
input int    SetA_Distance    = 8000;    // A: SL doori
input int    SetB_Start       = 15000;   // B: trailing shuru
input int    SetB_Distance    = 12000;   // B: SL doori
input int    SetC_Start       = 20000;   // C: trailing shuru
input int    SetC_Distance    = 15000;   // C: SL doori
input int    SetD_Start       = 30000;   // D: trailing shuru
input int    SetD_Distance    = 20000;   // D: SL doori
input int    ShadowStep       = 1000;    // virtual SL step (sab sets ke liye)

input group "=== Display ==="
input bool   ShowPanel        = true;

//--- shadow structures ----------------------------------------------
struct VTrade
{
   ulong    ticket;
   string   sym;
   int      dir;
   double   open;
   double   vol;
   double   sl;
   double   tp;
   double   peak;      // best favourable price move
   int      set;       // 1..4 = A..D
   int      start;     // points
   int      dist;      // points
   datetime t;
   int      moves;
};

VTrade   gV[];
ulong    gRealTk[];     // real Buster tickets being followed
bool     gRealSkip[];   // true = was already open when EA started (ignored)
double   gSum[5];       // 0 = REAL, 1..4 = A..D  (closed $)
int      gCnt[5];
string   gSetName[5] = {"REAL", "A", "B", "C", "D"};

CTrade   gTrade;
int      gManaged = 0;
int      gMoves   = 0;
string   gLastMsg = "abhi kuch nahi";
string   gAcc     = "";

//+------------------------------------------------------------------+
string FSh()             { return "IW_shadow_" + gAcc + ".jsonl"; }
string TS(datetime t)    { return TimeToString(t, TIME_DATE | TIME_SECONDS); }
string Num(double v, int dg) { return DoubleToString(v, dg); }

void AppendLine(const string fn, const string line)
{
   int h = FileOpen(fn, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) { Print("Shadow file open fail: ", fn, " err=", GetLastError()); return; }
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, line + "\r\n");
   FileClose(h);
}

bool IsMine(const string sym, long magic)
{
   if(OnlyThisSymbol && sym != _Symbol) return false;
   if(MagicNumber != 0 && magic != MagicNumber) return false;
   return true;
}

bool Better(int dir, double cand, double cur, double minGap)
{
   if(cand <= 0) return false;
   if(cur  <= 0) return true;
   if(dir > 0) return cand > cur + minGap;
   return cand < cur - minGap;
}

int SetStart(int s) { return s == 1 ? SetA_Start    : s == 2 ? SetB_Start    : s == 3 ? SetC_Start    : SetD_Start; }
int SetDist(int s)  { return s == 1 ? SetA_Distance : s == 2 ? SetB_Distance : s == 3 ? SetC_Distance : SetD_Distance; }

// $ value of a price move for this symbol/volume
double MoneyOf(const string sym, double move, double vol)
{
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0 || tv <= 0) return 0;
   return move / ts * tv * vol;
}

int FindReal(ulong tk)
{
   for(int i = 0; i < ArraySize(gRealTk); i++) if(gRealTk[i] == tk) return i;
   return -1;
}

//+------------------------------------------------------------------+
//| REAL result line (Buster's actual close)                         |
//+------------------------------------------------------------------+
void RecordReal(ulong tk)
{
   if(!HistorySelectByPosition(tk)) return;
   double profit = 0, openPx = 0, closePx = 0, vol = 0;
   datetime ot = 0, ct = 0;
   string sym = ""; int dir = 0;
   int nd = HistoryDealsTotal();
   for(int i = 0; i < nd; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_IN)
      {
         openPx = HistoryDealGetDouble(d, DEAL_PRICE);
         vol    = HistoryDealGetDouble(d, DEAL_VOLUME);
         ot     = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
         sym    = HistoryDealGetString(d, DEAL_SYMBOL);
         dir    = (HistoryDealGetInteger(d, DEAL_TYPE) == DEAL_TYPE_BUY) ? 1 : -1;
      }
      else if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY || en == DEAL_ENTRY_INOUT)
      {
         closePx = HistoryDealGetDouble(d, DEAL_PRICE);
         ct      = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      }
      profit += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
   }
   if(ct == 0) return;   // not actually closed
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   string l = "{\"ticket\":" + (string)tk + ",\"set\":\"REAL\",\"start\":null,\"dist\":null,";
   l += "\"sym\":\"" + sym + "\",\"side\":\"" + (dir > 0 ? "BUY" : "SELL") + "\",\"vol\":" + Num(vol, 2) + ",";
   l += "\"open\":" + Num(openPx, dg) + ",\"close\":" + Num(closePx, dg) + ",";
   l += "\"move\":" + Num(dir * (closePx - openPx), dg) + ",\"peak\":null,";
   l += "\"profit\":" + Num(profit, 2) + ",\"t\":\"" + TS(ot) + "\",\"ct\":\"" + TS(ct) + "\",\"moves\":null}";
   AppendLine(FSh(), l);
   gSum[0] += profit; gCnt[0]++;
}

//+------------------------------------------------------------------+
//| SHADOW engine                                                    |
//+------------------------------------------------------------------+
void CloseVirtual(int i, double px, string why)
{
   VTrade v = gV[i];
   int dg = (int)SymbolInfoInteger(v.sym, SYMBOL_DIGITS);
   double move   = v.dir * (px - v.open);
   double profit = MoneyOf(v.sym, move, v.vol);
   string l = "{\"ticket\":" + (string)v.ticket + ",\"set\":\"" + gSetName[v.set] + "\",";
   l += "\"start\":" + (string)v.start + ",\"dist\":" + (string)v.dist + ",";
   l += "\"sym\":\"" + v.sym + "\",\"side\":\"" + (v.dir > 0 ? "BUY" : "SELL") + "\",\"vol\":" + Num(v.vol, 2) + ",";
   l += "\"open\":" + Num(v.open, dg) + ",\"close\":" + Num(px, dg) + ",";
   l += "\"move\":" + Num(move, dg) + ",\"peak\":" + Num(v.peak, dg) + ",";
   l += "\"profit\":" + Num(profit, 2) + ",\"t\":\"" + TS(v.t) + "\",\"ct\":\"" + TS(TimeCurrent()) + "\",";
   l += "\"moves\":" + (string)v.moves + ",\"exit\":\"" + why + "\"}";
   AppendLine(FSh(), l);
   gSum[v.set] += profit; gCnt[v.set]++;

   int last = ArraySize(gV) - 1;
   if(i != last) gV[i] = gV[last];
   ArrayResize(gV, last);
}

void ShadowTick()
{
   // 1) new / closed real Buster trades
   int total = PositionsTotal();
   bool present[];
   ArrayResize(present, ArraySize(gRealTk));
   ArrayInitialize(present, false);

   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      if(!IsMine(sym, PositionGetInteger(POSITION_MAGIC))) continue;

      int k = FindReal(tk);
      if(k >= 0) { present[k] = true; continue; }

      // new real trade -> start 4 virtual copies
      k = ArraySize(gRealTk);
      ArrayResize(gRealTk, k + 1);   gRealTk[k]   = tk;
      ArrayResize(gRealSkip, k + 1); gRealSkip[k] = false;
      ArrayResize(present, k + 1);   present[k]   = true;

      int    dir  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      for(int s = 1; s <= 4; s++)
      {
         int n = ArraySize(gV);
         ArrayResize(gV, n + 1);
         gV[n].ticket = tk;
         gV[n].sym    = sym;
         gV[n].dir    = dir;
         gV[n].open   = PositionGetDouble(POSITION_PRICE_OPEN);
         gV[n].vol    = PositionGetDouble(POSITION_VOLUME);
         gV[n].sl     = PositionGetDouble(POSITION_SL);   // Buster's initial SL
         gV[n].tp     = PositionGetDouble(POSITION_TP);
         gV[n].peak   = 0;
         gV[n].set    = s;
         gV[n].start  = SetStart(s);
         gV[n].dist   = SetDist(s);
         gV[n].t      = (datetime)PositionGetInteger(POSITION_TIME);
         gV[n].moves  = 0;
      }
      gLastMsg = StringFormat("Shadow start #%I64u (%s) - 4 virtual copies", tk, dir > 0 ? "BUY" : "SELL");
   }

   for(int r = ArraySize(gRealTk) - 1; r >= 0; r--)
   {
      if(present[r]) continue;
      if(!gRealSkip[r]) RecordReal(gRealTk[r]);
      int last = ArraySize(gRealTk) - 1;
      if(r != last) { gRealTk[r] = gRealTk[last]; gRealSkip[r] = gRealSkip[last]; present[r] = present[last]; }
      ArrayResize(gRealTk, last);
      ArrayResize(gRealSkip, last);
      ArrayResize(present, last);
   }

   // 2) move virtual trades along the price
   for(int i = ArraySize(gV) - 1; i >= 0; i--)
   {
      string sym = gV[i].sym;
      double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(pt <= 0) continue;
      double px  = (gV[i].dir > 0) ? SymbolInfoDouble(sym, SYMBOL_BID) : SymbolInfoDouble(sym, SYMBOL_ASK);
      if(px <= 0) continue;
      int d = gV[i].dir;

      // exit first with the SL/TP it already had
      if(gV[i].sl > 0 && ((d > 0 && px <= gV[i].sl) || (d < 0 && px >= gV[i].sl))) { CloseVirtual(i, gV[i].sl, "SL"); continue; }
      if(gV[i].tp > 0 && ((d > 0 && px >= gV[i].tp) || (d < 0 && px <= gV[i].tp))) { CloseVirtual(i, gV[i].tp, "TP"); continue; }

      double move = d * (px - gV[i].open);
      if(move > gV[i].peak) gV[i].peak = move;

      if(move >= gV[i].start * pt)
      {
         double cand = px - d * gV[i].dist * pt;
         if(Better(d, cand, gV[i].sl, ShadowStep * pt)) { gV[i].sl = cand; gV[i].moves++; }
      }
   }
}

//+------------------------------------------------------------------+
//| LIVE engine (same as v1.00)                                      |
//+------------------------------------------------------------------+
void ManageLive()
{
   gManaged = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   magic = PositionGetInteger(POSITION_MAGIC);
      if(!IsMine(sym, magic)) continue;
      gManaged++;
      if(Mode != TM_LIVE) continue;

      int    dir  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);
      double tp   = PositionGetDouble(POSITION_TP);
      double pt   = SymbolInfoDouble(sym, SYMBOL_POINT);
      int    dg   = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(pt <= 0) continue;

      double px = (dir > 0) ? SymbolInfoDouble(sym, SYMBOL_BID) : SymbolInfoDouble(sym, SYMBOL_ASK);
      if(px <= 0) continue;

      double profitPts = dir * (px - open) / pt;
      double stopsLvl  = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)  * pt;
      double freezeLvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL) * pt;
      if(sl > 0 && freezeLvl > 0 && MathAbs(px - sl) <= freezeLvl) continue;

      double newSL = sl;
      string why   = "";
      if(UseBreakEven && profitPts >= BreakEvenAt)
      {
         double be = open + dir * BreakEvenLock * pt;
         if(Better(dir, be, newSL, pt * 0.5)) { newSL = be; why = "BE"; }
      }
      if(profitPts >= TrailStart)
      {
         double tr = px - dir * TrailDistance * pt;
         if(Better(dir, tr, newSL, TrailStep * pt)) { newSL = tr; why = "TRAIL"; }
      }
      if(why == "") continue;

      double minGap = stopsLvl + pt;
      if(dir > 0 && newSL > px - minGap) newSL = px - minGap;
      if(dir < 0 && newSL < px + minGap) newSL = px + minGap;
      newSL = NormalizeDouble(newSL, dg);
      if(!Better(dir, newSL, sl, pt * 0.5)) continue;

      if(gTrade.PositionModify(tk, newSL, tp))
      {
         gMoves++;
         gLastMsg = StringFormat("LIVE %s #%I64u SL %s -> %s (profit %.0f pts)", why, tk,
                                 DoubleToString(sl, dg), DoubleToString(newSL, dg), profitPts);
         Print("BTC Trailing Manager: ", gLastMsg);
      }
      else
         PrintFormat("BTC Trailing Manager: modify fail #%I64u code=%u %s", tk, gTrade.ResultRetcode(), gTrade.ResultRetcodeDescription());
   }
}

void Panel()
{
   if(!ShowPanel) return;
   string s = "BTC Trailing Manager v1.01   MODE: " + (Mode == TM_LIVE ? "LIVE (real SL khiskata hai)" : "SHADOW (sirf test, real SL nahi chhuta)") + "\n";
   s += StringFormat("Magic: %I64d   Symbol: %s   Buster trades now: %d   Virtual open: %d\n",
                     MagicNumber, OnlyThisSymbol ? _Symbol : "ALL", gManaged, ArraySize(gV));
   if(Mode == TM_LIVE)
      s += StringFormat("LIVE: start %d  distance %d  step %d pts   SL moves: %d\n", TrailStart, TrailDistance, TrailStep, gMoves);
   s += "Closed so far ($):\n";
   s += StringFormat("  Buster REAL : %d trades  %.2f\n", gCnt[0], gSum[0]);
   for(int k = 1; k <= 4; k++)
      s += StringFormat("  %s %d/%d : %d trades  %.2f\n", gSetName[k], SetStart(k), SetDist(k), gCnt[k], gSum[k]);
   s += "Last: " + gLastMsg + "\n";
   s += (Mode == TM_LIVE) ? "Yaad rahe: Buster me UseTrailingStop = false" : "Buster me UseTrailingStop = true hi rehne do";
   Comment(s);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(TrailDistance <= 0 || SetA_Distance <= 0 || SetB_Distance <= 0 || SetC_Distance <= 0 || SetD_Distance <= 0)
   {
      Alert("BTC Trailing Manager: saari Distance values 0 se zyada honi chahiye.");
      return INIT_PARAMETERS_INCORRECT;
   }
   gAcc = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   ArrayInitialize(gSum, 0);
   ArrayInitialize(gCnt, 0);
   ArrayResize(gV, 0);
   ArrayResize(gRealTk, 0);
   ArrayResize(gRealSkip, 0);

   // trades already open now: follow them but skip (their SL may already be trailed)
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;
      if(!IsMine(PositionGetString(POSITION_SYMBOL), PositionGetInteger(POSITION_MAGIC))) continue;
      int k = ArraySize(gRealTk);
      ArrayResize(gRealTk, k + 1);   gRealTk[k]   = tk;
      ArrayResize(gRealSkip, k + 1); gRealSkip[k] = true;
   }

   gTrade.SetDeviationInPoints(50);
   Print("BTC Trailing Manager v1.01 start. Mode=", (Mode == TM_LIVE ? "LIVE" : "SHADOW"), " Magic=", MagicNumber,
         " | shadow file MQL5\\Files\\", FSh());
   EventSetTimer(1);
   Panel();
   return INIT_SUCCEEDED;
}

void OnTick()  { ShadowTick(); ManageLive(); }

void OnTimer() { ShadowTick(); ManageLive(); Panel(); }

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}
//+------------------------------------------------------------------+
