//+------------------------------------------------------------------+
//|  SamuSignal CopyTrade Reader v1.02                                |
//|  Ankush New Vision                                                |
//+------------------------------------------------------------------+
//  KAAM:
//   Ye EA SOURCE account wale MT5 terminal me lagta hai — jo account
//   INVESTOR (read-only) password se login hai. Ye koi trade nahi
//   karta, sirf har 200ms me open positions padh kar ek file me
//   likhta hai:
//      <Common>\Files\SamuCopy\master.txt
//   Common folder ek hi VPS ke SAARE MT5 terminals share karte hain,
//   isliye dusre terminal ka "Executor" EA ye file padh leta hai.
//
//   v1.02 se STRATEGY RECORDER bhi: source EA ki har harkat (pending
//   lagana/badalna/hatana, trade khulna/SL-TP badalna/band hona) us waqt
//   ke market ke haal (spread, ATR, M5/H1 candle, din ka high/low) ke
//   saath likhta hai:
//      <Common>\Files\SamuCopy\recorder_<login>.csv      (poori list)
//      <Common>\Files\SamuCopy\events.json               (aakhri 300 — app ke liye)
//      <Common>\Files\SamuCopy\history_orders_<login>.csv (purani history)
//      <Common>\Files\SamuCopy\history_deals_<login>.csv
//
//  CHANGELOG
//   v1.02  (28-Sep-2026)  Strategy Recorder + purani history dump. Snapshot
//                         format same (Executor v1.03 ke saath chalta hai).
//   v1.01  (28-Sep-2026)  Pending orders (Buy/Sell Stop/Limit) bhi file me
//                         "O|" lines — app me dikhane ke liye. Header me
//                         pending count. Executor v1.01 ke saath hi chalao.
//   v1.00  (27-Sep-2026)  Pehla build — positions snapshot, heartbeat,
//                         atomic write (tmp -> move), chart panel.
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.02"
#property description "SamuSignal CopyTrade — SOURCE (investor) account ke trades padh kar Common folder me likhta hai. Trade nahi karta."

input int  InpIntervalMs  = 200;   // Kitni der me padhe (ms) — 100 se 1000
input bool InpRecorder    = true;  // Strategy Recorder chalu
input bool InpDumpHistory = true;  // Start pe purani history CSV me nikalo

const string CP_FOLDER = "SamuCopy";
const string F_MASTER  = "SamuCopy\\master.txt";
const string F_TMP     = "SamuCopy\\master.tmp";

long     g_seq       = 0;
int      g_moveFail  = 0;
uint     g_lastPanel = 0;
int      g_lastCount = 0;
int      g_lastPend  = 0;
long     g_evCount   = 0;
string   g_histMsg   = "";

//+------------------------------------------------------------------+
int OnInit()
  {
   FolderCreate(CP_FOLDER, FILE_COMMON);
   int ms = InpIntervalMs;
   if(ms < 100)  ms = 100;
   if(ms > 1000) ms = 1000;
   if(!EventSetMillisecondTimer(ms))
     {
      Print("SamuCopy Reader: timer start nahi hua, error ", GetLastError());
      return(INIT_FAILED);
     }
   WriteSnapshot();
   if(InpDumpHistory) DumpHistory();
   if(InpRecorder) RecInit();
   Print("SamuCopy Reader v1.02 chalu. File: ",
         TerminalInfoString(TERMINAL_COMMONDATA_PATH), "\\Files\\", F_MASTER);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
  }

void OnTick()  { }
void OnTimer() { WriteSnapshot(); }
void OnTrade() { WriteSnapshot(); }   // position badalte hi turant likho

//+------------------------------------------------------------------+
string Num(const double v, const int d) { return DoubleToString(v, d); }

//+------------------------------------------------------------------+
void WriteSnapshot()
  {
   g_seq++;
   bool   conn   = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
   bool   canTr  = (AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) != 0);
   long   login  = AccountInfoInteger(ACCOUNT_LOGIN);
   string server = AccountInfoString(ACCOUNT_SERVER);
   StringReplace(server, "|", "/");

   string body = "";
   int    cnt  = 0;
   int    total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(dg <= 0) dg = 5;
      long   typ = PositionGetInteger(POSITION_TYPE);
      double pl  = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      body += "P|" + IntegerToString((long)tk) +
              "|" + sym +
              "|" + IntegerToString(typ) +
              "|" + Num(PositionGetDouble(POSITION_VOLUME), 3) +
              "|" + Num(PositionGetDouble(POSITION_PRICE_OPEN), dg) +
              "|" + Num(PositionGetDouble(POSITION_SL), dg) +
              "|" + Num(PositionGetDouble(POSITION_TP), dg) +
              "|" + IntegerToString(PositionGetInteger(POSITION_TIME)) +
              "|" + IntegerToString(PositionGetInteger(POSITION_MAGIC)) +
              "|" + Num(pl, 2) + "\r\n";
      cnt++;
     }

   //--- pending orders (sirf dikhane ke liye — copy nahi hote)
   string pbody = "";
   int    pcnt  = 0;
   int    ototal = OrdersTotal();
   for(int i = 0; i < ototal; i++)
     {
      ulong ot = OrderGetTicket(i);
      if(ot == 0) continue;
      long otyp = OrderGetInteger(ORDER_TYPE);
      if(otyp < ORDER_TYPE_BUY_LIMIT || otyp > ORDER_TYPE_SELL_STOP_LIMIT) continue;
      string osym = OrderGetString(ORDER_SYMBOL);
      int    odg  = (int)SymbolInfoInteger(osym, SYMBOL_DIGITS);
      if(odg <= 0) odg = 5;
      pbody += "O|" + IntegerToString((long)ot) +
               "|" + osym +
               "|" + IntegerToString(otyp) +
               "|" + Num(OrderGetDouble(ORDER_VOLUME_CURRENT), 3) +
               "|" + Num(OrderGetDouble(ORDER_PRICE_OPEN), odg) +
               "|" + Num(OrderGetDouble(ORDER_SL), odg) +
               "|" + Num(OrderGetDouble(ORDER_TP), odg) +
               "|" + IntegerToString(OrderGetInteger(ORDER_TIME_SETUP)) +
               "|" + IntegerToString(OrderGetInteger(ORDER_MAGIC)) +
               "|" + IntegerToString(OrderGetInteger(ORDER_TIME_EXPIRATION)) + "\r\n";
      pcnt++;
     }

   // H|seq|localTime|login|server|serverTime|balance|equity|connected|tradeAllowed|count|pendingCount
   string head = "H|" + IntegerToString(g_seq) +
                 "|" + IntegerToString((long)TimeLocal()) +
                 "|" + IntegerToString(login) +
                 "|" + server +
                 "|" + IntegerToString((long)TimeCurrent()) +
                 "|" + Num(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
                 "|" + Num(AccountInfoDouble(ACCOUNT_EQUITY), 2) +
                 "|" + (conn ? "1" : "0") +
                 "|" + (canTr ? "1" : "0") +
                 "|" + IntegerToString(cnt) +
                 "|" + IntegerToString(pcnt) + "\r\n";
   string tail = "E|" + IntegerToString(cnt) + "|" + IntegerToString(g_seq) + "\r\n";

   int h = FileOpen(F_TMP, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE) return;
   FileWriteString(h, head + body + pbody + tail);
   FileClose(h);

   // tmp -> master (poori file ek saath badalti hai, aadhi-adhuri kabhi nahi padhi jaati)
   if(!FileMove(F_TMP, FILE_COMMON, F_MASTER, FILE_COMMON | FILE_REWRITE))
      g_moveFail++;          // Executor us waqt padh raha tha — agli baar ho jayega
   else
      g_moveFail = 0;

   g_lastCount = cnt;
   g_lastPend  = pcnt;
   if(InpRecorder && conn) RecTick();
   if(GetTickCount() - g_lastPanel > 1000)
     {
      g_lastPanel = GetTickCount();
      Panel(login, server, conn, canTr);
     }
  }

//+------------------------------------------------------------------+
void Panel(const long login, const string server, const bool conn, const bool canTr)
  {
   string s = "SamuSignal CopyTrade — READER v1.02\n";
   s += "Source: " + IntegerToString(login) + " @ " + server + "\n";
   s += "Connection: " + (conn ? "OK" : "NAHI — login/internet check karo") + "\n";
   s += "Mode: " + (canTr ? "MASTER password (trade allowed) — investor bhi chalega"
                          : "INVESTOR (read-only) — sahi hai") + "\n";
   s += "Open positions: " + IntegerToString(g_lastCount) + "   Pending: " + IntegerToString(g_lastPend) + "\n";
   s += "Snapshot #" + IntegerToString(g_seq) +
        (g_moveFail > 20 ? "  (file likhne me dikkat!)" : "  (file OK)") + "\n";
   s += "Recorder: " + (InpRecorder ? IntegerToString(g_evCount) + " events likhe" + (g_histMsg != "" ? "   " + g_histMsg : "") : "band") + "\n";
   s += "Is terminal me trade NAHI hota. Copy dusre terminal ka Executor karta hai.";
   Comment(s);
  }
//+------------------------------------------------------------------+

//+==================================================================+
//|  STRATEGY RECORDER (v1.02)                                       |
//+==================================================================+
struct RecOrd
  {
   ulong  tk;
   string sym;
   int    type;
   double vol, price, sl, tp;
   long   setup, exp, magic;
   string cmt;
   bool   seen;
  };
struct RecPos
  {
   ulong  tk;
   string sym;
   int    type;
   double vol, price, sl, tp;
   long   time, magic;
   string cmt;
   bool   seen;
  };
struct RecGone        // band hui position — history aane ka intezaar
  {
   ulong  tk;
   string sym;
   int    type;
   double vol, price, sl, tp;
   long   time, magic;
   uint   at;
  };

RecOrd RO[];  int ROn = 0;
RecPos RP[];  int RPn = 0;
RecGone RG[]; int RGn = 0;
long   g_recLogin = 0;
string EVJ[];  int EVn = 0;        // aakhri 300 events (JSON lines)
string g_atrSym[]; int g_atrM5[]; int g_atrH1[]; int g_atrN = 0;

string RecCsv()   { return "SamuCopy\\recorder_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + ".csv"; }
const string F_EVJL = "SamuCopy\\events.jsonl";
const string F_EVJ  = "SamuCopy\\events.json";
const string F_EVT  = "SamuCopy\\events.tmp";

string OTypeName(const long t)
  {
   switch((int)t)
     {
      case 0: return "BUY";
      case 1: return "SELL";
      case 2: return "BUY LIMIT";
      case 3: return "SELL LIMIT";
      case 4: return "BUY STOP";
      case 5: return "SELL STOP";
      case 6: return "BUY STOP LIMIT";
      case 7: return "SELL STOP LIMIT";
     }
   return "?";
  }

string CsvSafe(string s) { StringReplace(s, ",", " "); StringReplace(s, "\r", " "); StringReplace(s, "\n", " "); StringReplace(s, "\"", "'"); return s; }
string JsSafe(string s)  { StringReplace(s, "\\", "/"); StringReplace(s, "\"", "'"); StringReplace(s, "\r", " "); StringReplace(s, "\n", " "); return s; }

string IST(const datetime t)
  {
   datetime ist = t + 19800;
   return TimeToString(ist, TIME_DATE | TIME_SECONDS);
  }

string DowName(const datetime t)
  {
   MqlDateTime d; TimeToStruct(t, d);
   string n[7] = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};
   return n[d.day_of_week];
  }

//--- ATR handle (har symbol ka ek baar)
int AtrIdx(const string sym)
  {
   for(int i = 0; i < g_atrN; i++) if(g_atrSym[i] == sym) return i;
   ArrayResize(g_atrSym, g_atrN + 1); ArrayResize(g_atrM5, g_atrN + 1); ArrayResize(g_atrH1, g_atrN + 1);
   g_atrSym[g_atrN] = sym;
   g_atrM5[g_atrN]  = iATR(sym, PERIOD_M5, 14);
   g_atrH1[g_atrN]  = iATR(sym, PERIOD_H1, 14);
   g_atrN++;
   return g_atrN - 1;
  }

double AtrVal(const int h)
  {
   if(h == INVALID_HANDLE) return 0;
   double b[];
   if(CopyBuffer(h, 0, 1, 1, b) != 1) return 0;
   return b[0];
  }

//--- us waqt ka market: CSV columns + JSON fields
void Ctx(const string sym, string &csv, string &js, double &mid)
  {
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   if(dg <= 0) dg = 5;
   MqlTick k; ZeroMemory(k);
   SymbolInfoTick(sym, k);
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   long spr = (pt > 0) ? (long)MathRound((k.ask - k.bid) / pt) : 0;
   mid = (k.bid + k.ask) / 2.0;
   int ai = AtrIdx(sym);
   double a5 = AtrVal(g_atrM5[ai]), a1 = AtrVal(g_atrH1[ai]);
   MqlRates m5[], h1[], d1[];
   double m5o = 0, m5h = 0, m5l = 0, m5c = 0, h1o = 0, h1h = 0, h1l = 0, h1c = 0, d1h = 0, d1l = 0;
   if(CopyRates(sym, PERIOD_M5, 1, 1, m5) == 1) { m5o = m5[0].open; m5h = m5[0].high; m5l = m5[0].low; m5c = m5[0].close; }
   if(CopyRates(sym, PERIOD_H1, 1, 1, h1) == 1) { h1o = h1[0].open; h1h = h1[0].high; h1l = h1[0].low; h1c = h1[0].close; }
   if(CopyRates(sym, PERIOD_D1, 0, 1, d1) == 1) { d1h = d1[0].high; d1l = d1[0].low; }
   csv = Num(k.bid, dg) + "," + Num(k.ask, dg) + "," + IntegerToString(spr) + "," +
         Num(a5, dg) + "," + Num(a1, dg) + "," +
         Num(m5o, dg) + "," + Num(m5h, dg) + "," + Num(m5l, dg) + "," + Num(m5c, dg) + "," +
         Num(h1o, dg) + "," + Num(h1h, dg) + "," + Num(h1l, dg) + "," + Num(h1c, dg) + "," +
         Num(d1h, dg) + "," + Num(d1l, dg);
   js = "\"bid\":" + Num(k.bid, dg) + ",\"ask\":" + Num(k.ask, dg) + ",\"spr\":" + IntegerToString(spr) +
        ",\"atr5\":" + Num(a5, dg) + ",\"atr60\":" + Num(a1, dg) +
        ",\"d1h\":" + Num(d1h, dg) + ",\"d1l\":" + Num(d1l, dg);
  }

string CsvHeader()
  {
   return "time_server,time_ist,dow,event,ticket,symbol,type,volume,price,sl,tp,dist_from_mkt,sl_dist,tp_dist," +
          "old_price,old_sl,old_tp,life_sec,profit,reason,magic,comment,expiry," +
          "bid,ask,spread_pts,atr_m5,atr_h1,m5_open,m5_high,m5_low,m5_close,h1_open,h1_high,h1_low,h1_close,day_high,day_low";
  }

void AppendLine(const string file, const string line, const bool common)
  {
   int flags = FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ;
   if(common) flags |= FILE_COMMON;
   int h = FileOpen(file, flags);
   if(h == INVALID_HANDLE) return;
   bool fresh = (FileSize(h) == 0);
   FileSeek(h, 0, SEEK_END);
   if(fresh && file == RecCsv()) FileWriteString(h, CsvHeader() + "\r\n");
   FileWriteString(h, line + "\r\n");
   FileClose(h);
  }

void SaveEventsJson()
  {
   string all = "[";
   for(int i = 0; i < EVn; i++) { if(i > 0) all += ","; all += EVJ[i]; }
   all += "]";
   uchar buf[];
   int n = StringToCharArray(all, buf, 0, -1, CP_UTF8);
   if(n > 0) ArrayResize(buf, n - 1);
   int h = FileOpen(F_EVT, FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(h == INVALID_HANDLE) return;
   FileWriteArray(h, buf);
   FileClose(h);
   FileMove(F_EVT, FILE_COMMON, F_EVJ, FILE_COMMON | FILE_REWRITE);
  }

void PushEvent(const string js)
  {
   if(EVn < 300) { ArrayResize(EVJ, EVn + 1); EVJ[EVn] = js; EVn++; }
   else
     {
      for(int i = 1; i < EVn; i++) EVJ[i - 1] = EVJ[i];
      EVJ[EVn - 1] = js;
     }
   AppendLine(F_EVJL, js, true);
   SaveEventsJson();
  }

//--- ek event likho (CSV + JSON)
void Emit(const string ev, const ulong tk, const string sym, const string tname, const double vol,
          const double price, const double sl, const double tp,
          const double oldP, const double oldSL, const double oldTP,
          const long life, const double profit, const string why, const long magic,
          const string cmt, const long expiry)
  {
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   if(dg <= 0) dg = 5;
   string cc, cj; double mid;
   Ctx(sym, cc, cj, mid);
   datetime now = TimeCurrent();
   double dist = (price > 0 && mid > 0) ? price - mid : 0;
   double sld = (sl > 0 && price > 0) ? MathAbs(price - sl) : 0;
   double tpd = (tp > 0 && price > 0) ? MathAbs(tp - price) : 0;

   string line = TimeToString(now, TIME_DATE | TIME_SECONDS) + "," + IST(TimeGMT()) + "," + DowName(now) + "," +
                 ev + "," + IntegerToString((long)tk) + "," + sym + "," + tname + "," + Num(vol, 2) + "," +
                 Num(price, dg) + "," + Num(sl, dg) + "," + Num(tp, dg) + "," +
                 Num(dist, dg) + "," + Num(sld, dg) + "," + Num(tpd, dg) + "," +
                 Num(oldP, dg) + "," + Num(oldSL, dg) + "," + Num(oldTP, dg) + "," +
                 IntegerToString(life) + "," + Num(profit, 2) + "," + CsvSafe(why) + "," +
                 IntegerToString(magic) + "," + CsvSafe(cmt) + "," +
                 (expiry > 0 ? TimeToString((datetime)expiry, TIME_DATE | TIME_MINUTES) : "") + "," + cc;
   AppendLine(RecCsv(), line, true);

   string js = "{\"t\":" + IntegerToString((long)now) + ",\"ist\":\"" + IST(TimeGMT()) + "\",\"e\":\"" + ev + "\"" +
               ",\"tk\":" + IntegerToString((long)tk) + ",\"sym\":\"" + JsSafe(sym) + "\",\"ty\":\"" + tname + "\"" +
               ",\"v\":" + Num(vol, 2) + ",\"p\":" + Num(price, dg) + ",\"sl\":" + Num(sl, dg) + ",\"tp\":" + Num(tp, dg) +
               ",\"dist\":" + Num(dist, dg) + ",\"sld\":" + Num(sld, dg) + ",\"tpd\":" + Num(tpd, dg) +
               ",\"op\":" + Num(oldP, dg) + ",\"osl\":" + Num(oldSL, dg) + ",\"otp\":" + Num(oldTP, dg) +
               ",\"life\":" + IntegerToString(life) + ",\"pl\":" + Num(profit, 2) + ",\"why\":\"" + JsSafe(why) + "\"" +
               ",\"mg\":" + IntegerToString(magic) + "," + cj + "}";
   PushEvent(js);
   g_evCount++;
  }

//--- position band hone ki detail history se
bool CloseInfo(const ulong posId, double &price, double &profit, string &why, long &closeTime)
  {
   if(!HistorySelectByPosition(posId)) return false;
   int n = HistoryDealsTotal();
   bool found = false;
   profit = 0;
   for(int i = 0; i < n; i++)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      profit += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_SWAP);
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY)
        {
         found = true;
         price = HistoryDealGetDouble(d, DEAL_PRICE);
         closeTime = HistoryDealGetInteger(d, DEAL_TIME);
         string r = EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(d, DEAL_REASON));
         StringReplace(r, "DEAL_REASON_", "");
         why = r;
        }
     }
   return found;
  }

//--- pending gayab: kyon? (FILLED / CANCELED / EXPIRED)
string OrderFate(const ulong tk)
  {
   datetime now = TimeCurrent();
   if(!HistorySelect(now - 86400 * 40, now + 3600)) return "";
   if(!HistoryOrderSelect(tk)) return "";
   long st = HistoryOrderGetInteger(tk, ORDER_STATE);
   if(st == ORDER_STATE_FILLED || st == ORDER_STATE_PARTIAL) return "FILLED";
   if(st == ORDER_STATE_CANCELED) return "CANCELED";
   if(st == ORDER_STATE_EXPIRED)  return "EXPIRED";
   if(st == ORDER_STATE_REJECTED) return "REJECTED";
   return "GONE";
  }

int FindRO(const ulong tk) { for(int i = 0; i < ROn; i++) if(RO[i].tk == tk) return i; return -1; }
int FindRP(const ulong tk) { for(int i = 0; i < RPn; i++) if(RP[i].tk == tk) return i; return -1; }

void RecInit()
  {
   //--- purane events (app ke liye aakhri 300) wapas lo
   EVn = 0; ArrayResize(EVJ, 0);
   if(FileIsExist(F_EVJL, FILE_COMMON))
     {
      int h = FileOpen(F_EVJL, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON | FILE_SHARE_READ);
      if(h != INVALID_HANDLE)
        {
         while(!FileIsEnding(h))
           {
            string ln = FileReadString(h);
            if(StringLen(ln) < 5) continue;
            if(EVn < 300) { ArrayResize(EVJ, EVn + 1); EVJ[EVn] = ln; EVn++; }
            else { for(int i = 1; i < EVn; i++) EVJ[i - 1] = EVJ[i]; EVJ[EVn - 1] = ln; }
           }
         FileClose(h);
        }
      //--- jsonl ko chhota rakho
      int w = FileOpen(F_EVJL, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
      if(w != INVALID_HANDLE) { for(int i = 0; i < EVn; i++) FileWriteString(w, EVJ[i] + "\r\n"); FileClose(w); }
     }
   RecLoadState(true);
  }

//--- abhi ke orders/positions yaad karo; first=true ho to "EXISTING" events likho
void RecLoadState(const bool first)
  {
   g_recLogin = AccountInfoInteger(ACCOUNT_LOGIN);
   ROn = 0; RPn = 0; RGn = 0;
   ArrayResize(RO, 0); ArrayResize(RP, 0); ArrayResize(RG, 0);
   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      long ty = OrderGetInteger(ORDER_TYPE);
      if(ty < ORDER_TYPE_BUY_LIMIT) continue;
      ArrayResize(RO, ROn + 1);
      RO[ROn].tk = t; RO[ROn].sym = OrderGetString(ORDER_SYMBOL); RO[ROn].type = (int)ty;
      RO[ROn].vol = OrderGetDouble(ORDER_VOLUME_CURRENT); RO[ROn].price = OrderGetDouble(ORDER_PRICE_OPEN);
      RO[ROn].sl = OrderGetDouble(ORDER_SL); RO[ROn].tp = OrderGetDouble(ORDER_TP);
      RO[ROn].setup = OrderGetInteger(ORDER_TIME_SETUP); RO[ROn].exp = OrderGetInteger(ORDER_TIME_EXPIRATION);
      RO[ROn].magic = OrderGetInteger(ORDER_MAGIC); RO[ROn].cmt = OrderGetString(ORDER_COMMENT);
      if(first) Emit("EXISTING_ORDER", t, RO[ROn].sym, OTypeName(ty), RO[ROn].vol, RO[ROn].price, RO[ROn].sl, RO[ROn].tp,
                     0, 0, 0, (long)TimeCurrent() - RO[ROn].setup, 0, "", RO[ROn].magic, RO[ROn].cmt, RO[ROn].exp);
      ROn++;
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      ArrayResize(RP, RPn + 1);
      RP[RPn].tk = t; RP[RPn].sym = PositionGetString(POSITION_SYMBOL); RP[RPn].type = (int)PositionGetInteger(POSITION_TYPE);
      RP[RPn].vol = PositionGetDouble(POSITION_VOLUME); RP[RPn].price = PositionGetDouble(POSITION_PRICE_OPEN);
      RP[RPn].sl = PositionGetDouble(POSITION_SL); RP[RPn].tp = PositionGetDouble(POSITION_TP);
      RP[RPn].time = PositionGetInteger(POSITION_TIME); RP[RPn].magic = PositionGetInteger(POSITION_MAGIC);
      RP[RPn].cmt = PositionGetString(POSITION_COMMENT);
      if(first) Emit("EXISTING_POS", t, RP[RPn].sym, OTypeName(RP[RPn].type), RP[RPn].vol, RP[RPn].price, RP[RPn].sl, RP[RPn].tp,
                     0, 0, 0, (long)TimeCurrent() - RP[RPn].time, 0, "", RP[RPn].magic, RP[RPn].cmt, 0);
      RPn++;
     }
  }

void RecTick()
  {
   if(AccountInfoInteger(ACCOUNT_LOGIN) != g_recLogin)   // account badla: bina event ke naya shuru
     {
      RecLoadState(false);
      return;
     }
   long now = (long)TimeCurrent();
   for(int i = 0; i < ROn; i++) RO[i].seen = false;
   for(int i = 0; i < RPn; i++) RP[i].seen = false;

   //--- ORDERS: naye / badle
   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      long ty = OrderGetInteger(ORDER_TYPE);
      if(ty < ORDER_TYPE_BUY_LIMIT) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      double v = OrderGetDouble(ORDER_VOLUME_CURRENT), p = OrderGetDouble(ORDER_PRICE_OPEN);
      double sl = OrderGetDouble(ORDER_SL), tp = OrderGetDouble(ORDER_TP);
      int k = FindRO(t);
      if(k < 0)
        {
         ArrayResize(RO, ROn + 1);
         RO[ROn].tk = t; RO[ROn].sym = sym; RO[ROn].type = (int)ty; RO[ROn].vol = v; RO[ROn].price = p;
         RO[ROn].sl = sl; RO[ROn].tp = tp; RO[ROn].setup = OrderGetInteger(ORDER_TIME_SETUP);
         RO[ROn].exp = OrderGetInteger(ORDER_TIME_EXPIRATION); RO[ROn].magic = OrderGetInteger(ORDER_MAGIC);
         RO[ROn].cmt = OrderGetString(ORDER_COMMENT); RO[ROn].seen = true;
         Emit("ORDER_PLACED", t, sym, OTypeName(ty), v, p, sl, tp, 0, 0, 0, 0, 0, "", RO[ROn].magic, RO[ROn].cmt, RO[ROn].exp);
         ROn++;
         continue;
        }
      RO[k].seen = true;
      double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(pt <= 0) pt = 0.00001;
      if(MathAbs(p - RO[k].price) > pt * 0.5 || MathAbs(sl - RO[k].sl) > pt * 0.5 || MathAbs(tp - RO[k].tp) > pt * 0.5)
        {
         Emit("ORDER_MODIFY", t, sym, OTypeName(ty), v, p, sl, tp, RO[k].price, RO[k].sl, RO[k].tp,
              now - RO[k].setup, 0, "", RO[k].magic, RO[k].cmt, OrderGetInteger(ORDER_TIME_EXPIRATION));
         RO[k].price = p; RO[k].sl = sl; RO[k].tp = tp;
        }
     }

   //--- POSITIONS: naye / badle
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      double v = PositionGetDouble(POSITION_VOLUME), p = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL), tp = PositionGetDouble(POSITION_TP);
      int ty = (int)PositionGetInteger(POSITION_TYPE);
      int k = FindRP(t);
      if(k < 0)
        {
         //--- pending se bana? (position ticket = order ticket)
         int o = FindRO(t);
         double pendP = (o >= 0) ? RO[o].price : 0;
         string why = (o >= 0) ? "FROM " + OTypeName(RO[o].type) + " slip " + DoubleToString(p - pendP, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)) : "MARKET";
         ArrayResize(RP, RPn + 1);
         RP[RPn].tk = t; RP[RPn].sym = sym; RP[RPn].type = ty; RP[RPn].vol = v; RP[RPn].price = p;
         RP[RPn].sl = sl; RP[RPn].tp = tp; RP[RPn].time = PositionGetInteger(POSITION_TIME);
         RP[RPn].magic = PositionGetInteger(POSITION_MAGIC); RP[RPn].cmt = PositionGetString(POSITION_COMMENT); RP[RPn].seen = true;
         Emit("POS_OPEN", t, sym, OTypeName(ty), v, p, sl, tp, pendP, 0, 0,
              (o >= 0) ? now - RO[o].setup : 0, 0, why, RP[RPn].magic, RP[RPn].cmt, 0);
         RPn++;
         continue;
        }
      RP[k].seen = true;
      double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(pt <= 0) pt = 0.00001;
      if(MathAbs(sl - RP[k].sl) > pt * 0.5 || MathAbs(tp - RP[k].tp) > pt * 0.5)
        {
         string why = "";
         if(sl > 0 && MathAbs(sl - p) <= pt * 2) why = "BREAKEVEN";
         else if(sl != RP[k].sl && RP[k].sl > 0) why = (ty == 0 ? (sl > RP[k].sl ? "TRAIL" : "SL_WIDER") : (sl < RP[k].sl ? "TRAIL" : "SL_WIDER"));
         Emit("POS_MODIFY", t, sym, OTypeName(ty), v, p, sl, tp, p, RP[k].sl, RP[k].tp,
              now - RP[k].time, PositionGetDouble(POSITION_PROFIT), why, RP[k].magic, RP[k].cmt, 0);
         RP[k].sl = sl; RP[k].tp = tp;
        }
      if(v < RP[k].vol - 1e-8)
        {
         Emit("POS_PARTIAL", t, sym, OTypeName(ty), v, p, sl, tp, RP[k].price, 0, 0,
              now - RP[k].time, PositionGetDouble(POSITION_PROFIT), "closed " + DoubleToString(RP[k].vol - v, 2), RP[k].magic, RP[k].cmt, 0);
         RP[k].vol = v;
        }
     }

   //--- ORDERS gayab
   for(int i = ROn - 1; i >= 0; i--)
     {
      if(RO[i].seen) continue;
      string fate = OrderFate(RO[i].tk);
      if(fate == "" && FindRP(RO[i].tk) >= 0) fate = "FILLED";
      if(fate == "") fate = "REMOVED";
      string ev = (fate == "FILLED") ? "ORDER_FILLED" : (fate == "EXPIRED") ? "ORDER_EXPIRED" : "ORDER_CANCEL";
      Emit(ev, RO[i].tk, RO[i].sym, OTypeName(RO[i].type), RO[i].vol, RO[i].price, RO[i].sl, RO[i].tp, 0, 0, 0,
           now - RO[i].setup, 0, fate, RO[i].magic, RO[i].cmt, RO[i].exp);
      for(int j = i + 1; j < ROn; j++) RO[j - 1] = RO[j];
      ROn--;
      ArrayResize(RO, ROn);
     }

   //--- POSITIONS gayab -> history ka intezaar list me
   for(int i = RPn - 1; i >= 0; i--)
     {
      if(RP[i].seen) continue;
      ArrayResize(RG, RGn + 1);
      RG[RGn].tk = RP[i].tk; RG[RGn].sym = RP[i].sym; RG[RGn].type = RP[i].type; RG[RGn].vol = RP[i].vol;
      RG[RGn].price = RP[i].price; RG[RGn].sl = RP[i].sl; RG[RGn].tp = RP[i].tp; RG[RGn].time = RP[i].time;
      RG[RGn].magic = RP[i].magic; RG[RGn].at = GetTickCount();
      RGn++;
      for(int j = i + 1; j < RPn; j++) RP[j - 1] = RP[j];
      RPn--;
      ArrayResize(RP, RPn);
     }

   //--- band hui positions: history mili to POS_CLOSE likho (max 10 sec intezaar)
   for(int i = RGn - 1; i >= 0; i--)
     {
      double cp = 0, pl = 0; string why = ""; long ct = now;
      bool ok = CloseInfo(RG[i].tk, cp, pl, why, ct);
      if(!ok && GetTickCount() - RG[i].at < 10000) continue;
      if(!ok) why = "UNKNOWN";
      Emit("POS_CLOSE", RG[i].tk, RG[i].sym, OTypeName(RG[i].type), RG[i].vol, cp, RG[i].sl, RG[i].tp, RG[i].price, 0, 0,
           ct - RG[i].time, pl, why, RG[i].magic, "", 0);
      for(int j = i + 1; j < RGn; j++) RG[j - 1] = RG[j];
      RGn--;
      ArrayResize(RG, RGn);
     }
  }

//+------------------------------------------------------------------+
//| PURANI HISTORY (ek baar, start pe)                               |
//+------------------------------------------------------------------+
void DumpHistory()
  {
   datetime now = TimeCurrent();
   if(!HistorySelect(0, now + 86400)) { g_histMsg = "history nahi mili"; return; }
   string login = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

   int ho = FileOpen("SamuCopy\\history_orders_" + login + ".csv", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   int no = HistoryOrdersTotal();
   if(ho != INVALID_HANDLE)
     {
      FileWriteString(ho, "ticket,setup_time,done_time,life_sec,symbol,type,state,volume,price,sl,tp,expiry,magic,position_id,reason,comment\r\n");
      for(int i = 0; i < no; i++)
        {
         ulong t = HistoryOrderGetTicket(i);
         if(t == 0) continue;
         string sym = HistoryOrderGetString(t, ORDER_SYMBOL);
         int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS); if(dg <= 0) dg = 5;
         long su = HistoryOrderGetInteger(t, ORDER_TIME_SETUP), dn = HistoryOrderGetInteger(t, ORDER_TIME_DONE);
         string st = EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(t, ORDER_STATE)); StringReplace(st, "ORDER_STATE_", "");
         string rs = EnumToString((ENUM_ORDER_REASON)HistoryOrderGetInteger(t, ORDER_REASON)); StringReplace(rs, "ORDER_REASON_", "");
         long ex = HistoryOrderGetInteger(t, ORDER_TIME_EXPIRATION);
         FileWriteString(ho, IntegerToString((long)t) + "," + TimeToString((datetime)su, TIME_DATE | TIME_SECONDS) + "," +
                         TimeToString((datetime)dn, TIME_DATE | TIME_SECONDS) + "," + IntegerToString(dn - su) + "," + sym + "," +
                         OTypeName(HistoryOrderGetInteger(t, ORDER_TYPE)) + "," + st + "," +
                         Num(HistoryOrderGetDouble(t, ORDER_VOLUME_INITIAL), 2) + "," + Num(HistoryOrderGetDouble(t, ORDER_PRICE_OPEN), dg) + "," +
                         Num(HistoryOrderGetDouble(t, ORDER_SL), dg) + "," + Num(HistoryOrderGetDouble(t, ORDER_TP), dg) + "," +
                         (ex > 0 ? TimeToString((datetime)ex, TIME_DATE | TIME_MINUTES) : "") + "," +
                         IntegerToString(HistoryOrderGetInteger(t, ORDER_MAGIC)) + "," + IntegerToString(HistoryOrderGetInteger(t, ORDER_POSITION_ID)) + "," +
                         rs + "," + CsvSafe(HistoryOrderGetString(t, ORDER_COMMENT)) + "\r\n");
        }
      FileClose(ho);
     }

   int hd = FileOpen("SamuCopy\\history_deals_" + login + ".csv", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   int nd = HistoryDealsTotal();
   if(hd != INVALID_HANDLE)
     {
      FileWriteString(hd, "ticket,time,symbol,type,entry,volume,price,profit,commission,swap,magic,position_id,order,reason,comment\r\n");
      for(int i = 0; i < nd; i++)
        {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0) continue;
         string sym = HistoryDealGetString(d, DEAL_SYMBOL);
         int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS); if(dg <= 0) dg = 5;
         string ty = EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(d, DEAL_TYPE));   StringReplace(ty, "DEAL_TYPE_", "");
         string en = EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY)); StringReplace(en, "DEAL_ENTRY_", "");
         string rs = EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(d, DEAL_REASON)); StringReplace(rs, "DEAL_REASON_", "");
         FileWriteString(hd, IntegerToString((long)d) + "," + TimeToString((datetime)HistoryDealGetInteger(d, DEAL_TIME), TIME_DATE | TIME_SECONDS) + "," +
                         sym + "," + ty + "," + en + "," + Num(HistoryDealGetDouble(d, DEAL_VOLUME), 2) + "," +
                         Num(HistoryDealGetDouble(d, DEAL_PRICE), dg) + "," + Num(HistoryDealGetDouble(d, DEAL_PROFIT), 2) + "," +
                         Num(HistoryDealGetDouble(d, DEAL_COMMISSION), 2) + "," + Num(HistoryDealGetDouble(d, DEAL_SWAP), 2) + "," +
                         IntegerToString(HistoryDealGetInteger(d, DEAL_MAGIC)) + "," + IntegerToString(HistoryDealGetInteger(d, DEAL_POSITION_ID)) + "," +
                         IntegerToString(HistoryDealGetInteger(d, DEAL_ORDER)) + "," + rs + "," + CsvSafe(HistoryDealGetString(d, DEAL_COMMENT)) + "\r\n");
        }
      FileClose(hd);
     }
   g_histMsg = "history: " + IntegerToString(no) + " orders, " + IntegerToString(nd) + " deals";
   Print("SamuCopy Reader: ", g_histMsg, " -> Common\\Files\\SamuCopy\\history_*_", login, ".csv");
  }
//+------------------------------------------------------------------+
