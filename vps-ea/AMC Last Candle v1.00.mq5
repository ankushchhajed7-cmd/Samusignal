//+------------------------------------------------------------------+
//|  AMC Last Candle v1.00                     Ankush New Vision     |
//|------------------------------------------------------------------|
//|  STRATEGY                                                        |
//|   - Har naye candle (default M1) par pichhli BAND candle dekho:  |
//|       GREEN (close > open) = BUY,  RED (close < open) = SELL,    |
//|       DOJI (close = open) = skip. Ek candle = ek trade.          |
//|   - Har trade ka ALAG TP = $1 (lot ke hisaab se price distance). |
//|   - Ek side (BUY ya SELL) ki 10 single trades atki ho aur 11vi   |
//|     usi side ki trade aaye: pehle wali 10 ek AVG GROUP ban jaati |
//|     hain, unka common TP = poore group ka combined profit $1     |
//|     (average price + swap ke hisaab se, broker TP set hota hai). |
//|     11vi trade se phir se alag-alag $1 TP.                        |
//|   - Daily target = account balance ka 1% (07:00 IST reset):      |
//|     hit hote hi sab band + din bhar nayi trade nahi.             |
//|   - Safety: news filter (MT5 calendar High impact), spread       |
//|     filter, max trades / side, daily loss %, margin guard,       |
//|     Friday stop, HEDGING check, REAL account guard.              |
//|   - Gold Luxe FULL-SCREEN dashboard + PAUSE / CLOSE buttons.     |
//|------------------------------------------------------------------|
//|  CHANGELOG                                                       |
//|   v1.00 (20-Nov-2026) pehla build.                               |
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property version     "1.00"
#property description "AMC Last Candle: last closed candle colour = next trade, $1 TP per trade, 10 stuck same-side trades -> AVG group ($1 combined), daily 1% target, news / spread / safety filters."

#include <Trade\Trade.mqh>

//==================================================================== INPUTS
input group "===== STRATEGY ====="
input ENUM_TIMEFRAMES InpTF          = PERIOD_M1;   // Candle timeframe
input double InpLot                  = 0.01;        // Lot (har trade)
input double InpTpUsd                = 1.0;         // Har single trade ka TP ($)
input int    InpAvgAfter             = 10;          // Itni same-side single trades atki ho -> naye trade par AVG group
input double InpAvgTpUsd             = 1.0;         // AVG group ka combined profit ($)
input int    InpMinBodyPts           = 0;           // Doji filter: body <= itne points = skip (0 = sirf close=open)
input int    InpEntryWindowSec       = 30;          // Naye candle ke pehle itne second me hi entry (spread ruka ho to retry)

input group "===== DAILY ====="
input double InpDailyTargetPct       = 1.0;         // Daily target (% of balance, 0 = off)
input bool   InpTargetCloseAll       = true;        // Target par khuli trades bhi band karo
input double InpDailyLossPct         = 5.0;         // Daily loss limit (% of balance, 0 = off) -> sab band
input string InpResetIST             = "07:00";     // Din ka reset (IST)

input group "===== SAFETY ====="
input int    InpMaxSpreadPts         = 30;          // Max spread (points, 0 = off). Gold ke liye badhao
input int    InpMaxTrades            = 40;          // Max khuli trades (total)
input int    InpMaxPerSide           = 25;          // Max khuli trades ek side me
input double InpMinMarginLevel       = 300;         // Nayi trade tabhi jab margin level >= % (0 = off)
input bool   InpNewsFilter           = true;        // News filter (High impact)
input string InpNewsCurrencies       = "";          // News currency (blank = symbol ki dono currency + USD)
input int    InpNewsBeforeMin        = 30;          // News se pehle (min) nayi trade band
input int    InpNewsAfterMin         = 30;          // News ke baad (min) nayi trade band
input bool   InpFridayStop           = true;        // Friday shaam ke baad nayi trade nahi
input string InpFridayIST            = "22:00";     // Friday stop time (IST)
input bool   InpAllowReal            = false;       // REAL account par trade? (false = sirf DEMO / tester)
input long   InpMagic                = 880100;      // Magic number
input int    InpSlippagePts          = 30;          // Max slippage (points)
input double InpServerGMT            = -99;         // Server GMT offset (-99 = auto)
input double InpTesterGMT            = 0;           // Strategy Tester me server GMT offset (Exness = 0)

input group "===== DASHBOARD ====="
input bool   InpDashboard            = true;        // Gold Luxe full-screen dashboard
input bool   InpHidePriceChart       = true;        // Price chart chhupao (dashboard poori screen)

#define EA_NAME    "AMC Last Candle"
#define EA_VERSION "v1.00"
#define PFX        "AMCLC_"
#define IST_SEC    19800

CTrade trade;

//==================================================================== GLOBALS
double   g_off = 0;               // server GMT offset (hours)
int      g_resetMin = 420, g_friMin = 1320;
datetime g_lastBar = 0;
bool     g_barDone = true;
int      g_barTries = 0;
int      g_lastCandle = 0;        // 1 green, -1 red, 0 doji
double   g_lcO = 0, g_lcC = 0;
string   g_lastAct = "-";         // pichhle candle par kya hua

long     g_dayKey = -1;
double   g_dayStartBal = 0, g_dayStartFloat = 0;
bool     g_dayStopped = false;
string   g_dayReason = "";
bool     g_paused = false;
long     g_grpSeq = 0;

double   g_realToday = 0;
bool     g_realDirty = true;
uint     g_realT = 0;

string   g_block = "";            // permanent block (netting / real)
string   g_lastErr = "";
datetime g_lastErrT = 0;
uint     g_lastDash = 0;
datetime g_lastSync = 0, g_lastClean = 0, g_lastRetry = 0;

datetime g_newsLoaded = 0;
datetime g_newsT[];
string   g_newsN[];
bool     g_newsBlock = false;
string   g_newsTxt = "";

//==================================================================== SMALL HELPERS
bool     Tester()    { return (bool)MQLInfoInteger(MQL_TESTER); }
datetime NowServer() { return Tester() ? TimeCurrent() : TimeTradeServer(); }
void     SetErr(const string e) { g_lastErr = e; g_lastErrT = TimeCurrent(); Print(EA_NAME, ": ", e); }

string GVN(const string k) { return PFX + _Symbol + "_" + (string)InpMagic + "_" + k; }
void   GVSet(const string k, const double v) { GlobalVariableSet(GVN(k), v); }
double GVGet(const string k, const double def) { return GlobalVariableCheck(GVN(k)) ? GlobalVariableGet(GVN(k)) : def; }
string GKey(const ulong tk) { return GVN("g" + (string)tk); }
long   GroupOf(const ulong tk) { string k = GKey(tk); return GlobalVariableCheck(k) ? (long)GlobalVariableGet(k) : 0; }

int HhmmToMin(const string s, const int def)
  {
   string p[];
   if(StringSplit(s, ':', p) != 2) return def;
   int h = (int)StringToInteger(p[0]), m = (int)StringToInteger(p[1]);
   if(h < 0 || h > 23 || m < 0 || m > 59) return def;
   return h * 60 + m;
  }

void CalcOffset()
  {
   if(Tester()) { g_off = InpTesterGMT; return; }
   if(InpServerGMT > -50) { g_off = InpServerGMT; return; }
   double d = (double)(TimeTradeServer() - TimeGMT());
   g_off = MathRound(d / 1800.0) * 0.5;
  }
datetime ToIst(const datetime srv) { return (datetime)((long)srv - (long)(g_off * 3600) + IST_SEC); }
long     DayKeyOf(const datetime srv) { return (long)MathFloor(((double)srv - g_off * 3600.0 + IST_SEC - g_resetMin * 60.0) / 86400.0); }
datetime DayStartSrv(const long key) { return (datetime)(long)((double)key * 86400.0 + g_resetMin * 60.0 - IST_SEC + g_off * 3600.0); }
string   IstHM(const datetime srv) { return TimeToString(ToIst(srv), TIME_MINUTES); }

bool FridayOk(const datetime srv)
  {
   if(!InpFridayStop) return true;
   MqlDateTime d; TimeToStruct(ToIst(srv), d);
   int m = d.hour * 60 + d.min;
   // Friday stop time ke baad, Saturday, Sunday, aur Monday 03:30 IST se pehle (market khulte hi spread zyada)
   if(d.day_of_week == 5 && m >= g_friMin) return false;
   if(d.day_of_week == 6 || d.day_of_week == 0) return false;
   if(d.day_of_week == 1 && m < 210) return false;
   return true;
  }

string TfName(const ENUM_TIMEFRAMES tf)
  {
   string s = EnumToString(tf == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)Period() : tf);
   StringReplace(s, "PERIOD_", "");
   return s;
  }

double PerUnit()   // $ per 1.0 price move per 1 lot
  {
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return (ts > 0 && tv > 0) ? tv / ts : 0;
  }
double TickSz() { double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE); return ts > 0 ? ts : _Point; }

// TP ko tick size pe round: BUY upar, SELL neeche (taaki profit kam se kam target ho)
double NormTp(const double p, const int dir)
  {
   double ts = TickSz();
   double v = (dir == 1) ? MathCeil(p / ts - 1e-9) * ts : MathFloor(p / ts + 1e-9) * ts;
   return NormalizeDouble(v, _Digits);
  }

double NormLot(double v)
  {
   double mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(st <= 0) st = 0.01;
   v = MathFloor(v / st + 1e-9) * st;
   if(v < mn) v = mn;
   if(mx > 0 && v > mx) v = mx;
   return NormalizeDouble(v, 2);
  }

bool IsMine() { return PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic; }
int  PosDir() { return PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 1 : -1; }
double PosNet() { return PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP); }

//==================================================================== STATE
void SaveState()
  {
   GVSet("paused", g_paused ? 1 : 0);
   GVSet("seq", (double)g_grpSeq);
   GVSet("dayKey", (double)g_dayKey);
   GVSet("dayBal", g_dayStartBal);
   GVSet("dayFloat", g_dayStartFloat);
   GVSet("dayStop", g_dayStopped ? (g_dayReason == "DAY_TARGET" ? 1 : 2) : 0);
  }

//==================================================================== POSITIONS
int CountMine(int &buy, int &sell)
  {
   buy = 0; sell = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0 || !IsMine()) continue;
      if(PosDir() == 1) buy++; else sell++;
     }
   return buy + sell;
  }

double FloatingMine()
  {
   double s = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0 || !IsMine()) continue;
      s += PosNet();
     }
   return s;
  }

// single (group me nahi) trades ki list, ek side ki
int Singles(const int dir, ulong &tks[])
  {
   ArrayResize(tks, 0);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || PosDir() != dir) continue;
      if(GroupOf(tk) != 0) continue;
      int k = ArraySize(tks); ArrayResize(tks, k + 1); tks[k] = tk;
     }
   return ArraySize(tks);
  }

// khule groups ki list
int Groups(long &gid[], int &gdir[], int &gcnt[], double &gpl[], double &gtp[])
  {
   ArrayResize(gid, 0); ArrayResize(gdir, 0); ArrayResize(gcnt, 0); ArrayResize(gpl, 0); ArrayResize(gtp, 0);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine()) continue;
      long g = GroupOf(tk);
      if(g == 0) continue;
      int k = -1;
      for(int j = 0; j < ArraySize(gid); j++) if(gid[j] == g) { k = j; break; }
      if(k < 0)
        {
         k = ArraySize(gid);
         ArrayResize(gid, k + 1); ArrayResize(gdir, k + 1); ArrayResize(gcnt, k + 1); ArrayResize(gpl, k + 1); ArrayResize(gtp, k + 1);
         gid[k] = g; gdir[k] = PosDir(); gcnt[k] = 0; gpl[k] = 0; gtp[k] = PositionGetDouble(POSITION_TP);
        }
      gcnt[k]++; gpl[k] += PosNet();
     }
   return ArraySize(gid);
  }

// group ka common TP: weighted average price + (target - swap) ka distance
bool GroupTarget(const long id, int &dir, double &tp, int &cnt, double &pl)
  {
   double sl = 0, slp = 0, sw = 0; cnt = 0; pl = 0; dir = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || GroupOf(tk) != id) continue;
      double lot = PositionGetDouble(POSITION_VOLUME);
      sl += lot; slp += lot * PositionGetDouble(POSITION_PRICE_OPEN);
      sw += PositionGetDouble(POSITION_SWAP);
      pl += PosNet(); cnt++; dir = PosDir();
     }
   double pu = PerUnit();
   if(cnt == 0 || sl <= 0 || pu <= 0) return false;
   double dist = (InpAvgTpUsd - sw) / (sl * pu);
   if(dist < TickSz()) dist = TickSz();
   double avg = slp / sl;
   tp = NormTp(dir == 1 ? avg + dist : avg - dist, dir);
   return true;
  }

// broker TP lagao (stops level check). false = nahi laga, virtual TP chalega
bool SetTP(const ulong tk, const double tp)
  {
   if(!PositionSelectByTicket(tk)) return false;
   double cur = PositionGetDouble(POSITION_TP);
   if(MathAbs(cur - tp) < TickSz() * 0.5) return true;
   int dir = PosDir();
   MqlTick t; if(!SymbolInfoTick(_Symbol, t)) return false;
   double lvl = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(dir == 1 && tp <= t.bid + lvl) return false;
   if(dir == -1 && tp >= t.ask - lvl) return false;
   if(!trade.PositionModify(tk, PositionGetDouble(POSITION_SL), tp))
     {
      SetErr(StringFormat("TP set fail #%I64u: %d %s", tk, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
      return false;
     }
   return true;
  }

bool ClosePos(const ulong tk, const string why)
  {
   for(int a = 0; a < 3; a++)
     {
      if(!PositionSelectByTicket(tk)) return true;
      if(trade.PositionClose(tk, InpSlippagePts)) { PrintFormat("%s: close #%I64u (%s)", EA_NAME, tk, why); return true; }
      Sleep(200);
     }
   SetErr(StringFormat("Close fail #%I64u: %d %s", tk, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   return false;
  }

// dir: 0 = sab, 1 = BUY, -1 = SELL; grp: 0 = koi bhi, warna sirf wo group
void CloseWhere(const int dir, const long grp, const string why)
  {
   ulong tks[];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine()) continue;
      if(dir != 0 && PosDir() != dir) continue;
      if(grp != 0 && GroupOf(tk) != grp) continue;
      int k = ArraySize(tks); ArrayResize(tks, k + 1); tks[k] = tk;
     }
   for(int i = 0; i < ArraySize(tks); i++) ClosePos(tks[i], why);
   g_realDirty = true;
  }

//==================================================================== AVG GROUP
void SyncGroup(const long id)
  {
   int dir, cnt; double tp, pl;
   if(!GroupTarget(id, dir, tp, cnt, pl)) return;
   if(pl >= InpAvgTpUsd) { CloseWhere(0, id, "AVG_GROUP_TP"); return; }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || GroupOf(tk) != id) continue;
      SetTP(tk, tp);
     }
  }

bool FormGroup(const int dir)
  {
   ulong tks[];
   int n = Singles(dir, tks);
   if(InpAvgAfter <= 0 || n < InpAvgAfter) return false;
   g_grpSeq++;
   for(int i = 0; i < n; i++) GlobalVariableSet(GKey(tks[i]), (double)g_grpSeq);
   SaveState();
   PrintFormat("%s: %d %s trades -> AVG group #%I64d (combined TP $%.2f)", EA_NAME, n, dir == 1 ? "BUY" : "SELL", g_grpSeq, InpAvgTpUsd);
   SyncGroup(g_grpSeq);
   return true;
  }

// har tick: virtual TP (broker TP na laga ho / stops level) + group ka combined profit
void ManageTicks()
  {
   ulong closeTk[];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || GroupOf(tk) != 0) continue;
      if(PosNet() >= InpTpUsd) { int k = ArraySize(closeTk); ArrayResize(closeTk, k + 1); closeTk[k] = tk; }
     }
   for(int i = 0; i < ArraySize(closeTk); i++) ClosePos(closeTk[i], "SINGLE_TP_VIRTUAL");
   if(ArraySize(closeTk) > 0) g_realDirty = true;

   long gid[]; int gdir[], gcnt[]; double gpl[], gtp[];
   int ng = Groups(gid, gdir, gcnt, gpl, gtp);
   for(int j = 0; j < ng; j++)
      if(gpl[j] >= InpAvgTpUsd) CloseWhere(0, gid[j], "AVG_GROUP_TP");
  }

// har 30 sec: single TP repair, group TP (swap ke saath) dobara
void SyncAll()
  {
   double pu = PerUnit();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || GroupOf(tk) != 0) continue;
      if(PositionGetDouble(POSITION_TP) != 0 || pu <= 0) continue;
      int dir = PosDir();
      double op = PositionGetDouble(POSITION_PRICE_OPEN), lot = PositionGetDouble(POSITION_VOLUME);
      double dist = InpTpUsd / (lot * pu);
      SetTP(tk, NormTp(dir == 1 ? op + dist : op - dist, dir));
     }
   long gid[]; int gdir[], gcnt[]; double gpl[], gtp[];
   int ng = Groups(gid, gdir, gcnt, gpl, gtp);
   for(int j = 0; j < ng; j++) SyncGroup(gid[j]);
  }

// band ho chuki trades ke group GlobalVariables hatao
void CleanGV()
  {
   string pre = GVN("g");
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      string nm = GlobalVariableName(i);
      if(StringFind(nm, pre) != 0) continue;
      ulong tk = (ulong)StringToInteger(StringSubstr(nm, StringLen(pre)));
      if(tk == 0) continue;
      if(!PositionSelectByTicket(tk)) GlobalVariableDel(nm);
     }
  }

//==================================================================== DAILY
void CalcRealized()
  {
   g_realToday = 0;
   datetime from = DayStartSrv(g_dayKey);
   if(!HistorySelect(from, TimeCurrent() + 86400)) return;
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((datetime)HistoryDealGetInteger(d, DEAL_TIME) < from) continue;
      g_realToday += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
     }
   g_realDirty = false;
   g_realT = GetTickCount();
  }

double TodayPL()
  {
   if(g_realDirty || GetTickCount() - g_realT > 3000) CalcRealized();
   return g_realToday + FloatingMine() - g_dayStartFloat;
  }
double TargetAmt() { return g_dayStartBal * InpDailyTargetPct / 100.0; }
double LossAmt()   { return g_dayStartBal * InpDailyLossPct / 100.0; }

void NewDayCheck()
  {
   long k = DayKeyOf(NowServer());
   if(k == g_dayKey) return;
   g_dayKey = k;
   g_dayStartBal = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dayStartFloat = FloatingMine();
   g_dayStopped = false; g_dayReason = "";
   g_realDirty = true;
   SaveState();
   PrintFormat("%s: naya din (reset %s IST), balance %.2f, target %.2f", EA_NAME, InpResetIST, g_dayStartBal, TargetAmt());
  }

void StopDay(const string why)
  {
   g_dayStopped = true; g_dayReason = why;
   SaveState();
   PrintFormat("%s: %s - aaj nayi trade band (reset %s IST)", EA_NAME, why, InpResetIST);
  }

void DailyCheck()
  {
   double t = TodayPL();
   int b, s; int n = CountMine(b, s);
   if(InpDailyLossPct > 0 && g_dayReason != "DAY_LOSS" && t <= -LossAmt())
     { CloseWhere(0, 0, "DAY_LOSS"); StopDay("DAY_LOSS"); return; }
   if(!g_dayStopped && InpDailyTargetPct > 0 && t >= TargetAmt())
     {
      if(InpTargetCloseAll) CloseWhere(0, 0, "DAY_TARGET");
      StopDay("DAY_TARGET");
      return;
     }
   // band karne me koi trade reh gayi ho to retry
   bool mustFlat = (g_dayReason == "DAY_LOSS") || (g_dayReason == "DAY_TARGET" && InpTargetCloseAll);
   if(g_dayStopped && mustFlat && n > 0 && TimeCurrent() - g_lastRetry >= 5)
     { g_lastRetry = TimeCurrent(); CloseWhere(0, 0, g_dayReason + "_RETRY"); }
  }

//==================================================================== NEWS
void LoadNews()
  {
   g_newsLoaded = TimeCurrent();
   ArrayResize(g_newsT, 0); ArrayResize(g_newsN, 0);
   if(!InpNewsFilter || Tester()) return;
   string list = InpNewsCurrencies;
   if(list == "") list = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE) + "," + SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT) + ",USD";
   string cur[];
   int nc = StringSplit(list, ',', cur);
   string done = ",";
   datetime now = TimeTradeServer();
   for(int c = 0; c < nc; c++)
     {
      string ccy = cur[c];
      StringTrimLeft(ccy); StringTrimRight(ccy); StringToUpper(ccy);
      if(ccy == "" || StringFind(done, "," + ccy + ",") >= 0) continue;
      done += ccy + ",";
      MqlCalendarValue vals[];
      ResetLastError();
      if(CalendarValueHistory(vals, now - 6 * 3600, now + 36 * 3600, NULL, ccy) <= 0) continue;
      for(int i = 0; i < ArraySize(vals); i++)
        {
         MqlCalendarEvent ev;
         if(!CalendarEventById(vals[i].event_id, ev)) continue;
         if(ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;
         int k = ArraySize(g_newsT);
         ArrayResize(g_newsT, k + 1); ArrayResize(g_newsN, k + 1);
         g_newsT[k] = vals[i].time; g_newsN[k] = ccy + " " + ev.name;
        }
     }
  }

void UpdateNews()
  {
   g_newsBlock = false;
   if(!InpNewsFilter) { g_newsTxt = "off"; return; }
   if(Tester()) { g_newsTxt = "tester (off)"; return; }
   if(TimeCurrent() - g_newsLoaded > 600) LoadNews();
   datetime now = TimeTradeServer(), nextT = 0;
   for(int i = 0; i < ArraySize(g_newsT); i++)
     {
      datetime t = g_newsT[i];
      if(now >= t - InpNewsBeforeMin * 60 && now <= t + InpNewsAfterMin * 60)
        {
         g_newsBlock = true;
         g_newsTxt = "NEWS " + g_newsN[i] + " " + IstHM(t) + " IST  -  " + IstHM(t + InpNewsAfterMin * 60) + " IST tak nayi trade band";
         return;
        }
      if(t > now && (nextT == 0 || t < nextT)) nextT = t;
     }
   g_newsTxt = (nextT > 0) ? "next " + IstHM(nextT) + " IST" : "clear";
  }

//==================================================================== ENTRY
int CandleDir()
  {
   g_lcO = iOpen(_Symbol, InpTF, 1);
   g_lcC = iClose(_Symbol, InpTF, 1);
   if(g_lcO <= 0 || g_lcC <= 0) return 0;
   double body = (g_lcC - g_lcO) / _Point;
   if(MathAbs(body) <= InpMinBodyPts || g_lcC == g_lcO) return 0;
   return body > 0 ? 1 : -1;
  }

bool MarginOk(const int dir, const double lot, string &why)
  {
   double ml = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(InpMinMarginLevel > 0 && AccountInfoDouble(ACCOUNT_MARGIN) > 0 && ml < InpMinMarginLevel)
     { why = StringFormat("Margin level %.0f%% < %.0f%%", ml, InpMinMarginLevel); return false; }
   double need = 0, price = dir == 1 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(OrderCalcMargin(dir == 1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, need) && need > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     { why = "Free margin kam hai"; return false; }
   return true;
  }

bool OpenTrade(const int dir)
  {
   double lot = NormLot(InpLot), pu = PerUnit();
   if(pu <= 0) { SetErr("Tick value 0 - symbol data nahi mila"); return false; }
   double dist = InpTpUsd / (lot * pu);
   MqlTick t; if(!SymbolInfoTick(_Symbol, t)) return false;
   double lvl = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double price = dir == 1 ? t.ask : t.bid;
   double tp = NormTp(dir == 1 ? price + dist : price - dist, dir);
   if(dist <= lvl + (t.ask - t.bid)) tp = 0;   // broker TP nahi lag sakta -> virtual TP
   string cmt = "AMC LC " + (dir == 1 ? "B" : "S");
   bool ok = (dir == 1) ? trade.Buy(lot, _Symbol, 0, 0, tp, cmt) : trade.Sell(lot, _Symbol, 0, 0, tp, cmt);
   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED && rc != TRADE_RETCODE_DONE_PARTIAL))
     {
      SetErr(StringFormat("%s open fail: %d %s", dir == 1 ? "BUY" : "SELL", rc, trade.ResultRetcodeDescription()));
      return false;
     }
   // asli open price se TP theek karo (slippage)
   ulong pt = trade.ResultOrder();
   if(pt > 0 && PositionSelectByTicket(pt))
     {
      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      double tp2 = NormTp(dir == 1 ? op + dist : op - dist, dir);
      if(tp != 0) SetTP(pt, tp2);
     }
   g_realDirty = true;
   return true;
  }

void Skip(const string why) { g_lastAct = why; g_barDone = true; }

void TryOpen(const datetime barT)
  {
   // pichhla nateeja chhota rakha hai (card me fit ho)
   if(NowServer() - barT > InpEntryWindowSec)
     {
      g_lastAct = (StringFind(g_lastAct, "wait ") == 0) ? "SKIP " + StringSubstr(g_lastAct, 5) : "SKIP late";
      g_barDone = true; return;
     }
   if(g_block != "")      { Skip("SKIP block"); return; }
   if(g_paused)           { Skip("SKIP paused"); return; }
   if(g_dayStopped)       { Skip(g_dayReason == "DAY_TARGET" ? "SKIP target hit" : "SKIP loss limit"); return; }
   if(g_lastCandle == 0)  { Skip("SKIP doji"); return; }
   if(!FridayOk(NowServer())) { Skip("SKIP weekend"); return; }
   if(g_newsBlock)        { Skip("SKIP news"); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     { g_lastAct = "wait algo OFF"; return; }
   int sp = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(InpMaxSpreadPts > 0 && sp > InpMaxSpreadPts) { g_lastAct = StringFormat("wait spread %d", sp); return; }
   int dir = g_lastCandle;
   int b, s; int n = CountMine(b, s);
   if(InpMaxTrades > 0 && n >= InpMaxTrades) { Skip("SKIP max trades"); return; }
   if(InpMaxPerSide > 0 && (dir == 1 ? b : s) >= InpMaxPerSide) { Skip(dir == 1 ? "SKIP BUY side max" : "SKIP SELL side max"); return; }
   string why = "";
   if(!MarginOk(dir, NormLot(InpLot), why)) { Print(EA_NAME, ": ", why); Skip("SKIP margin"); return; }

   bool grp = FormGroup(dir);   // 10 atki single -> AVG group, phir naya trade
   if(OpenTrade(dir))
     {
      g_lastAct = (dir == 1 ? "BUY " : "SELL ") + IstHM(NowServer()) + (grp ? StringFormat(" +AVG#%I64d", g_grpSeq) : "");
      g_barDone = true;
     }
   else if(++g_barTries >= 3) Skip("SKIP open fail");
  }

//==================================================================== DASHBOARD (Gold Luxe, full screen)
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

double g_s = 1.0;      // layout scale (chart size)
double g_k = 1.0;      // DPI factor
int    P(const double v) { return (int)MathRound(v * g_s * g_k); }
int    FontPt(const double px) { return (int)MathMax(7, MathRound(px * g_s * 0.75)); }
void   Del(const string nm) { ObjectDelete(0, PFX + nm); }
string Dot() { return " " + ShortToString(0x00B7) + " "; }
string Spaced(const string s)
  {
   string o = "";
   int n = StringLen(s);
   for(int i = 0; i < n; i++) o += StringSubstr(s, i, 1) + (i < n - 1 ? " " : "");
   return o;
  }
string Money(double v)
  {
   string sg = (v < 0) ? "-" : "";
   v = MathAbs(v);
   string s = DoubleToString(v, 2);
   int dot = StringFind(s, ".");
   string ip = StringSubstr(s, 0, dot), fp = StringSubstr(s, dot), o = "";
   int c = 0;
   for(int i = StringLen(ip) - 1; i >= 0; i--)
     {
      o = StringSubstr(ip, i, 1) + o; c++;
      if(c % 3 == 0 && i > 0) o = "," + o;
     }
   return sg + "$" + o + fp;
  }
string SMoney(const double v) { return (v >= 0 ? "+" : "") + Money(v); }

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
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, MathMax(1, w));
   ObjectSetInteger(0, n, OBJPROP_YSIZE, MathMax(1, h));
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, n, OBJPROP_ZORDER, z);
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
      ObjectSetInteger(0, n, OBJPROP_BACK, false);
      ObjectSetInteger(0, n, OBJPROP_ZORDER, 5);
     }
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, right ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
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
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetString(0, n, OBJPROP_FONT, F_SANS);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPt(12));
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, C_GOLD);
   ObjectSetInteger(0, n, OBJPROP_STATE, false);
  }
void Bar(const string nm, const string title, const string valTxt, double frac, const color fill, const int x, const int y, const int w)
  {
   frac = MathMax(0, MathMin(1, frac));
   Lbl(nm + "_t", Spaced(title), x, y, 10, C_GOLD);
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

// table rows (newest first)
int CollectRows(int &dir[], double &lot[], double &op[], double &tp[], long &grp[], datetime &ot[], double &pl[])
  {
   ArrayResize(dir, 0); ArrayResize(lot, 0); ArrayResize(op, 0); ArrayResize(tp, 0); ArrayResize(grp, 0); ArrayResize(ot, 0); ArrayResize(pl, 0);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine()) continue;
      int k = ArraySize(dir);
      ArrayResize(dir, k + 1); ArrayResize(lot, k + 1); ArrayResize(op, k + 1); ArrayResize(tp, k + 1); ArrayResize(grp, k + 1); ArrayResize(ot, k + 1); ArrayResize(pl, k + 1);
      dir[k] = PosDir(); lot[k] = PositionGetDouble(POSITION_VOLUME); op[k] = PositionGetDouble(POSITION_PRICE_OPEN);
      tp[k] = PositionGetDouble(POSITION_TP); grp[k] = GroupOf(tk); ot[k] = (datetime)PositionGetInteger(POSITION_TIME); pl[k] = PosNet();
     }
   int n = ArraySize(dir);
   for(int a = 1; a < n; a++)          // insertion sort, time desc
     {
      int d = dir[a]; double l = lot[a], o = op[a], t = tp[a], p = pl[a]; long g = grp[a]; datetime tm = ot[a];
      int b = a - 1;
      while(b >= 0 && ot[b] < tm)
        {
         dir[b + 1] = dir[b]; lot[b + 1] = lot[b]; op[b + 1] = op[b]; tp[b + 1] = tp[b]; grp[b + 1] = grp[b]; ot[b + 1] = ot[b]; pl[b + 1] = pl[b];
         b--;
        }
      dir[b + 1] = d; lot[b + 1] = l; op[b + 1] = o; tp[b + 1] = t; grp[b + 1] = g; ot[b + 1] = tm; pl[b + 1] = p;
     }
   return n;
  }

void SideStats(const int side, int &single, int &groups, double &pl)
  {
   single = 0; groups = 0; pl = 0;
   long seen[];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !IsMine() || PosDir() != side) continue;
      pl += PosNet();
      long g = GroupOf(tk);
      if(g == 0) { single++; continue; }
      bool f = false;
      for(int j = 0; j < ArraySize(seen); j++) if(seen[j] == g) { f = true; break; }
      if(!f) { int k = ArraySize(seen); ArrayResize(seen, k + 1); seen[k] = g; groups++; }
     }
  }

// Layout logical units (96 dpi, scale 1): header 0-44, equity 52-128, banner 136-166,
// cards 176-272, bars 284-310, info 322-358, table 372+
void Dash()
  {
   if(!InpDashboard) return;
   if(Tester() && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   int W = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS), H = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   if(W < 50 || H < 50) return;
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI); if(dpi <= 0) dpi = 96;
   g_k = dpi / 96.0;
   double Wl = W / g_k, Hl = H / g_k;
   g_s = MathMax(0.8, MathMin(2.2, MathMin(Wl / 1000.0, Hl / 420.0)));
   double LW = Wl / g_s, LH = Hl / g_s;
   double M = 18, IW = LW - 2 * M;
   bool showInfo = LH >= 362, showTable = LH >= 400;

   Rect("bg", 0, 0, W, H, C_BG, C_BG, 0);
   datetime srv = NowServer();
   string up = ShortToString(0x25B2), dn = ShortToString(0x25BC);
   int nb, ns; int n = CountMine(nb, ns);
   double flt = FloatingMine(), today = TodayPL();
   double tgt = TargetAmt(), loss = LossAmt();
   bool isReal = AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL;
   bool hedge = AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;

   // header
   Lbl("brand", Spaced("AMC LAST CANDLE") + "   " + EA_VERSION, P(M), P(10), 11, C_GOLD);
   Lbl("sub", _Symbol + Dot() + TfName(InpTF) + " candle" + Dot() + "Magic " + (string)InpMagic + Dot() + (hedge ? "HEDGING" : "NETTING") + Dot() + (Tester() ? "TESTER" : isReal ? "REAL" : "DEMO"), P(M), P(28), 10, C_MUT);
   Lbl("ist", "IST  " + TimeToString(ToIst(srv), TIME_SECONDS), P(M + IW), P(9), 13, C_GOLD2, F_MONO, true);
   Lbl("srv", "SERVER  " + TimeToString(srv, TIME_SECONDS), P(M + IW), P(28), 10, C_MUT, F_MONO, true);

   // equity
   double eq = AccountInfoDouble(ACCOUNT_EQUITY), ml = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   Lbl("eqT", Spaced("EQUITY"), P(M), P(52), 10, C_GOLD);
   Lbl("eq", Money(eq), P(M), P(64), 38, C_GOLD, F_SERIF);
   Lbl("eqS", "Balance " + Money(AccountInfoDouble(ACCOUNT_BALANCE)) + "     EA floating " + SMoney(flt) + "     EA aaj " + SMoney(today) +
       "     Margin " + (ml > 0 ? DoubleToString(ml, 0) + "%" : "-"), P(M), P(112), 10, C_MUT);

   // buttons
   int bw = P(104), bh = P(32), bg = P(8);
   int bx = P(M + IW) - bw;
   Btn("btnAll", "CLOSE ALL", bx, P(66), bw, bh, C'48,10,10', C_BAD);
   Btn("btnSell", "CLOSE SELL", bx - (bw + bg), P(66), bw, bh, C_PANEL, C_BAD);
   Btn("btnBuy", "CLOSE BUY", bx - 2 * (bw + bg), P(66), bw, bh, C_PANEL, C_OK);
   Btn("btnPause", g_paused ? "RESUME" : "PAUSE", bx - 3 * (bw + bg), P(66), bw, bh, g_paused ? C_GOLD : C_PANEL, g_paused ? C_BG : C_GOLD);

   // alert banner
   string al; color ac = C_GOLD2, ab = C'18,15,7';
   int sp = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   bool algo = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED);
   if(g_block != "") { al = "BLOCK: " + g_block; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_lastErr != "" && TimeCurrent() - g_lastErrT < 60) { al = g_lastErr; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_dayStopped && g_dayReason == "DAY_TARGET") { al = "DAILY TARGET HIT  " + SMoney(today) + "  -  " + InpResetIST + " IST tak nayi trade band"; ac = C_OK; ab = C'8,30,20'; }
   else if(g_dayStopped) { al = "DAILY LOSS LIMIT HIT  -  sab band, " + InpResetIST + " IST tak trading band"; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_paused) { al = "PAUSED  -  nayi trade band, khuli trades ke TP chal rahe hain"; ac = C_WARN; ab = C'34,24,6'; }
   else if(!algo) { al = "Algo Trading OFF  -  MT5 toolbar me Algo Trading button ON karo"; ac = C_WARN; ab = C'34,24,6'; }
   else if(!FridayOk(srv)) { al = "FRIDAY / WEEKEND STOP  -  Friday " + InpFridayIST + " IST ke baad se Monday 03:30 IST tak nayi trade nahi"; ac = C_WARN; ab = C'34,24,6'; }
   else if(g_newsBlock) { al = g_newsTxt; ac = C_WARN; ab = C'34,24,6'; }
   else if(InpMaxSpreadPts > 0 && sp > InpMaxSpreadPts) { al = StringFormat("Spread high: %d pts (max %d)  -  nayi trade ruki", sp, InpMaxSpreadPts); ac = C_WARN; ab = C'34,24,6'; }
   else if(InpMaxTrades > 0 && n >= InpMaxTrades) { al = StringFormat("MAX TRADES %d  -  nayi trade tab tak band jab tak koi TP na ho", InpMaxTrades); ac = C_WARN; ab = C'34,24,6'; }
   else
     {
      string nx = g_lastCandle == 1 ? "BUY" : g_lastCandle == -1 ? "SELL" : "skip (doji)";
      al = "READY  -  pichhli " + TfName(InpTF) + " candle " + (g_lastCandle == 1 ? "GREEN" : g_lastCandle == -1 ? "RED" : "DOJI") + ", naye candle par: " + nx + Dot() + "Last: " + g_lastAct;
     }
   Rect("al", P(M), P(136), P(IW), P(30), ab, ac, 1);
   Lbl("alT", al, P(M + 12), P(143), 11, ac);

   // 4 cards
   double gap = 10, cw = (IW - 3 * gap) / 4.0;
   string cv = g_lastCandle == 1 ? up + " GREEN" : g_lastCandle == -1 ? dn + " RED" : "DOJI";
   color cc = g_lastCandle == 1 ? C_OK : g_lastCandle == -1 ? C_BAD : C_MUT;
   Card("cL", P(M), P(176), P(cw), P(96), "LAST CANDLE", cv, cc, "O " + DoubleToString(g_lcO, _Digits) + "   C " + DoubleToString(g_lcC, _Digits), g_lastAct);
   int bS, bG, sS, sG; double bPL, sPL;
   SideStats(1, bS, bG, bPL); SideStats(-1, sS, sG, sPL);
   Card("cB", P(M + cw + gap), P(176), P(cw), P(96), "BUY SIDE", StringFormat("%d open", nb), C_OK,
        StringFormat("Single %d / %d  " + ShortToString(0x2022) + "  AVG grp %d", bS, InpAvgAfter, bG), "P/L " + SMoney(bPL));
   Card("cS", P(M + 2 * (cw + gap)), P(176), P(cw), P(96), "SELL SIDE", StringFormat("%d open", ns), C_BAD,
        StringFormat("Single %d / %d  " + ShortToString(0x2022) + "  AVG grp %d", sS, InpAvgAfter, sG), "P/L " + SMoney(sPL));
   Card("cD", P(M + 3 * (cw + gap)), P(176), P(cw), P(96), "TODAY", SMoney(today), today >= 0 ? C_OK : C_BAD,
        StringFormat("%+.2f%% of %s", g_dayStartBal > 0 ? today / g_dayStartBal * 100 : 0, Money(g_dayStartBal)), "Target " + DoubleToString(InpDailyTargetPct, 2) + "%" + Dot() + "Reset " + InpResetIST + " IST");

   // progress bars
   double bg2 = 26, bwl = (IW - 2 * bg2) / 3.0;
   Bar("pT", "TARGET", tgt > 0 ? StringFormat("%s / %s", Money(MathMax(0, today)), Money(tgt)) : "off", tgt > 0 ? today / tgt : 0, C_GOLD, P(M), P(284), P(bwl));
   Bar("pD", "DD OF LIMIT", loss > 0 ? StringFormat("%s / %s", Money(MathMax(0, -today)), Money(loss)) : "off", loss > 0 ? -today / loss : 0, C_BAD, P(M + bwl + bg2), P(284), P(bwl));
   Bar("pN", "TRADES", StringFormat("%d / %d", n, InpMaxTrades), InpMaxTrades > 0 ? (double)n / InpMaxTrades : 0, C_WARN, P(M + 2 * (bwl + bg2)), P(284), P(bwl));

   // info
   if(showInfo)
     {
      long gid[]; int gdir[], gcnt[]; double gpl[], gtp[];
      int ng = Groups(gid, gdir, gcnt, gpl, gtp);
      string gs = "";
      for(int j = 0; j < ng && j < 3; j++)
         gs += (j ? "  |  " : "") + StringFormat("%s#%I64d x%d TP %s (%s)", gdir[j] == 1 ? "B" : "S", gid[j], gcnt[j], DoubleToString(gtp[j], _Digits), SMoney(gpl[j]));
      if(ng > 3) gs += StringFormat("  +%d", ng - 3);
      Lbl("info", "Lot " + DoubleToString(NormLot(InpLot), 2) + Dot() + "TP $" + DoubleToString(InpTpUsd, 2) + " / trade" + Dot() + "AVG " + (string)InpAvgAfter + " ke baad $" + DoubleToString(InpAvgTpUsd, 2) +
          Dot() + "Spread " + (string)sp + (InpMaxSpreadPts > 0 ? "/" + (string)InpMaxSpreadPts : "") + Dot() + "News " + (g_newsBlock ? "BLOCK" : g_newsTxt) +
          Dot() + "Fri " + (InpFridayStop ? InpFridayIST : "off") + Dot() + "Loss " + (InpDailyLossPct > 0 ? DoubleToString(InpDailyLossPct, 1) + "%" : "off") +
          Dot() + "Max " + (string)InpMaxTrades + "/" + (string)InpMaxPerSide + (InpMinMarginLevel > 0 ? Dot() + "Margin " + DoubleToString(InpMinMarginLevel, 0) + "%" : ""), P(M), P(322), 10, C_MUT);
      Lbl("info2", "AVG GROUPS:  " + (ng > 0 ? gs : "koi nahi"), P(M), P(340), 10, ng > 0 ? C_GOLD2 : C_MUT);
     }
   else { Del("info"); Del("info2"); }

   // trade table
   double cx[8]; cx[0] = M; cx[1] = M + 40; cx[2] = M + 104; cx[3] = M + 160; cx[4] = M + 280; cx[5] = M + 400; cx[6] = M + 500; cx[7] = M + IW;
   string hd[8] = {"#", "TYPE", "LOT", "OPEN", "TP", "MODE", "TIME (IST)", "P/L"};
   int maxRows = showTable ? (int)MathMax(0, MathMin(14, MathFloor((LH - 396) / 19.0))) : 0;
   if(showTable)
     {
      for(int c = 0; c < 8; c++) Lbl("th" + (string)c, Spaced(hd[c]), P(cx[c]), P(372), 9, C_GOLD, F_SANS, c == 7);
      Rect("thl", P(M), P(388), P(IW), 1, C_LINE, C_LINE, 1);
     }
   else { for(int c = 0; c < 8; c++) Del("th" + (string)c); Del("thl"); }
   int rd[]; double rl[], ro[], rtp[], rp[]; long rg[]; datetime rt[];
   int rn = CollectRows(rd, rl, ro, rtp, rg, rt, rp);
   int row = 0;
   for(int i = 0; i < rn && row < maxRows; i++)
     {
      bool buy = rd[i] == 1;
      double y = 394 + row * 19;
      string r = "r" + (string)row + "_";
      Lbl(r + "0", (string)(row + 1), P(cx[0]), P(y), 10, C_MUT, F_MONO);
      Lbl(r + "1", buy ? "BUY" : "SELL", P(cx[1]), P(y), 10, buy ? C_OK : C_BAD, F_MONO);
      Lbl(r + "2", DoubleToString(rl[i], 2), P(cx[2]), P(y), 10, C_TXT, F_MONO);
      Lbl(r + "3", DoubleToString(ro[i], _Digits), P(cx[3]), P(y), 10, C_TXT, F_MONO);
      Lbl(r + "4", rtp[i] > 0 ? DoubleToString(rtp[i], _Digits) : "virtual", P(cx[4]), P(y), 10, C_TXT, F_MONO);
      Lbl(r + "5", rg[i] > 0 ? StringFormat("AVG #%I64d", rg[i]) : "SINGLE", P(cx[5]), P(y), 10, rg[i] > 0 ? C_GOLD2 : C_MUT, F_MONO);
      Lbl(r + "6", TimeToString(ToIst(rt[i]), TIME_MINUTES), P(cx[6]), P(y), 10, C_MUT, F_MONO);
      Lbl(r + "7", SMoney(rp[i]), P(cx[7]), P(y), 10, rp[i] >= 0 ? C_OK : C_BAD, F_MONO, true);
      row++;
     }
   for(int r2 = row; r2 < 14; r2++)
      for(int c = 0; c < 8; c++) Del("r" + (string)r2 + "_" + (string)c);
   if(showTable && row == 0) Lbl("empty", "Koi khuli trade nahi", P(M), P(396), 10, C_MUT); else Del("empty");
   if(showTable && rn > row && row > 0) Lbl("more", StringFormat("+%d aur (chart ki height badhao)", rn - row), P(M + IW), P(396 + row * 19), 9, C_MUT, F_SANS, true); else Del("more");
   ChartRedraw(0);
  }

//==================================================================== EVENTS
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePts);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   if(InpLot <= 0 || InpTpUsd <= 0 || InpAvgTpUsd <= 0) { Alert(EA_NAME, ": Lot / TP 0 se bada rakho"); return INIT_PARAMETERS_INCORRECT; }
   g_resetMin = HhmmToMin(InpResetIST, 420);
   g_friMin   = HhmmToMin(InpFridayIST, 1320);
   CalcOffset();

   g_block = "";
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      g_block = "NETTING account hai - ye EA BUY + SELL saath rakhta hai, HEDGING account chahiye";
   else if(!Tester() && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL && !InpAllowReal)
      g_block = "REAL account - InpAllowReal = false hai (pehle DEMO pe test karo, phir true karo)";

   // restore state (restart / VPS reboot)
   g_paused = GVGet("paused", 0) == 1;
   g_grpSeq = (long)GVGet("seq", 0);
   long dk = DayKeyOf(NowServer());
   if((long)GVGet("dayKey", -1) == dk)
     {
      g_dayKey = dk;
      g_dayStartBal = GVGet("dayBal", AccountInfoDouble(ACCOUNT_BALANCE));
      g_dayStartFloat = GVGet("dayFloat", 0);
      int ds = (int)GVGet("dayStop", 0);
      g_dayStopped = ds > 0; g_dayReason = ds == 1 ? "DAY_TARGET" : ds == 2 ? "DAY_LOSS" : "";
     }
   NewDayCheck();
   CleanGV();
   g_lastBar = iTime(_Symbol, InpTF, 0);   // pehla trade agle naye candle se
   g_barDone = true;
   g_lastCandle = CandleDir();
   g_realDirty = true;
   SaveState();
   SyncAll();
   LoadNews(); UpdateNews();

   if(InpDashboard && !(Tester() && !MQLInfoInteger(MQL_VISUAL_MODE)))
     {
      if(InpHidePriceChart) ChartSetInteger(0, CHART_SHOW, false);
      Dash();
     }
   EventSetTimer(1);
   if(g_block != "") { Print(EA_NAME, ": ", g_block); if(!Tester()) Alert(EA_NAME, ": ", g_block); }
   PrintFormat("%s %s ready: %s %s, lot %.2f, TP $%.2f, AVG after %d ($%.2f), daily +%.2f%% / -%.2f%%, GMT %+.1f",
               EA_NAME, EA_VERSION, _Symbol, TfName(InpTF), NormLot(InpLot), InpTpUsd, InpAvgAfter, InpAvgTpUsd, InpDailyTargetPct, InpDailyLossPct, g_off);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   SaveState();
   ObjectsDeleteAll(0, PFX);
   ChartSetInteger(0, CHART_SHOW, true);
   ChartRedraw(0);
  }

void OnTick()
  {
   NewDayCheck();
   ManageTicks();
   DailyCheck();
   if(Tester()) { UpdateNews(); if(TimeCurrent() - g_lastSync >= 30) { g_lastSync = TimeCurrent(); SyncAll(); } }

   datetime bt = iTime(_Symbol, InpTF, 0);
   if(bt > 0 && bt != g_lastBar)
     {
      g_lastBar = bt; g_barDone = false; g_barTries = 0;
      g_lastCandle = CandleDir();
     }
   if(!g_barDone && bt > 0) TryOpen(bt);

   if(InpDashboard && GetTickCount() - g_lastDash > 500) { g_lastDash = GetTickCount(); Dash(); }
  }

void OnTimer()
  {
   if(!Tester())
     {
      UpdateNews();
      if(TimeCurrent() - g_lastSync >= 30) { g_lastSync = TimeCurrent(); SyncAll(); }
      if(TimeCurrent() - g_lastClean >= 300) { g_lastClean = TimeCurrent(); CleanGV(); }
     }
   if(InpDashboard) Dash();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) g_realDirty = true;
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE) { Dash(); return; }
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == PFX + "btnPause")      { g_paused = !g_paused; SaveState(); Print(EA_NAME, g_paused ? ": PAUSED" : ": RESUMED"); }
   else if(sparam == PFX + "btnAll")   { CloseWhere(0, 0, "MANUAL_CLOSE_ALL"); }
   else if(sparam == PFX + "btnBuy")   { CloseWhere(1, 0, "MANUAL_CLOSE_BUY"); }
   else if(sparam == PFX + "btnSell")  { CloseWhere(-1, 0, "MANUAL_CLOSE_SELL"); }
   else return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   Dash();
  }
//+------------------------------------------------------------------+
