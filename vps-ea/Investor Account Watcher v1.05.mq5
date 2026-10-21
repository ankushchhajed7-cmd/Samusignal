//+------------------------------------------------------------------+
//|                                  Investor Account Watcher v1.05   |
//|                                        Ankush New Vision          |
//|                                                                   |
//|  READ-ONLY account watcher. Attach it to ONE chart in an MT5      |
//|  terminal that is logged in with an INVESTOR (read-only) login.   |
//|  It reads the account's open positions + closed history and       |
//|  pushes them as JSON files into your GitHub repo, so your mobile  |
//|  PWA dashboard can show them live. It NEVER trades.               |
//|                                                                   |
//|  CHANGELOG                                                        |
//|   v1.05 - SAMU REPORT ke liye: har band trade ke saath magic,     |
//|           comment, SL, TP aur WORST P/L (trade me sabse bura =   |
//|           DD). Account equity har 15 min (+ beech ka sabse neecha |
//|           equity) MQL5\Files\IW_equity_<acc>.jsonl me. Naya      |
//|           data/<acc>/report.json: closes + equity + account info  |
//|           (band hone par ya har 15 min push). Trading EA nahi    |
//|           chhuta - sirf padhta hai.                              |
//|   v1.04 - BTC Trailing Manager v1.01 ke SHADOW test ke nateeje   |
//|           (MQL5\Files\IW_shadow_<acc>.jsonl) trail.json me      |
//|           "shadow" banke app tak jaate hain.                      |
//|   v1.03 - TRAILING TRACKER: har 1 sec scan, SL/TP khiske to event |
//|           (move, lock, gap, step), har position ka peak, aur band |
//|           hone par peak vs close (give-back) + deal reason.       |
//|           VPS par JSONL files, GitHub par data/<acc>/trail.json.  |
//|   v1.02 - Pending orders (buy/sell stop/limit) live.json me, aur  |
//|           order history (placed/cancel/fill) history.json me.     |
//|           Positions/deals/orders ke saath magic + comment bhi.    |
//|   v1.01 - FIX 401 "Bad credentials": token ab trim hota hai       |
//|           (aage/peeche ke space/newline hat jaate hain), token ki |
//|           length Experts log me print hoti hai, aur token ek file |
//|           se bhi padha ja sakta hai (TokenFile input) taaki chote |
//|           input cell me paste ki dikkat hi na rahe.               |
//|   v1.00 - Pehla build.                                            |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property link      "https://github.com/ankushchhajed7-cmd"
#property version   "1.05"
#property strict

//--- Inputs ---------------------------------------------------------
input string  GitHubOwner       = "ankushchhajed7-cmd"; // GitHub username
input string  GitHubRepo        = "INVESTOR-ID";        // repo name (public)
input string  GitHubBranch      = "main";               // branch GitHub Pages serves
input string  GitHubToken       = "";                   // fine-grained PAT (Contents=Read&write). Khali chhodo agar TokenFile use kar rahe ho
input string  TokenFile         = "investor_token.txt"; // MQL5\Files me ye file ho to token wahan se padhega (input se bhi chalega)
input int     LiveSeconds       = 20;                   // push open trades every N seconds
input int     HistoryDays       = 60;                   // how many days of closed history to upload
input int     HistoryRefreshMin = 30;                   // re-upload history every N minutes
input int     MaxDeals          = 1500;                 // safety cap on number of history deals
input int     MaxHistOrders     = 1500;                 // safety cap on number of history orders
input int     TrailPushSeconds  = 60;                   // trail.json push (only when something changed)
input int     TrailEventsKeep   = 400;                  // last N trailing events sent to the app
input int     TrailClosesKeep   = 200;                  // last N closed-trade summaries sent to the app
input int     ShadowKeep        = 600;                  // last N shadow-test result lines sent to the app
input bool    ReportEnabled     = true;                 // v1.05: data/<acc>/report.json (SAMU REPORT app)
input int     ReportPushMin     = 15;                   // v1.05: report.json har itne min (trade band ho to 60 sec me)
input int     EquityEveryMin    = 15;                   // v1.05: equity snapshot har itne min
input int     ReportClosesKeep  = 1500;                 // v1.05: report.json me aakhri N band trades
input int     ReportEqKeep      = 3000;                 // v1.05: report.json me aakhri N equity snapshots (~31 din)

//--- Globals --------------------------------------------------------
string   gAcc      = "";
string   gToken    = "";
datetime gLastHist = 0;
const string API   = "https://api.github.com/repos/";

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
string EscJson(string t)
{
   StringReplace(t, "\\", "\\\\");
   StringReplace(t, "\"", "\\\"");
   StringReplace(t, "\n", " ");
   StringReplace(t, "\r", " ");
   return t;
}

string MaskLogin(string a)
{
   int n = StringLen(a);
   if(n <= 3) return a;
   return "***" + StringSubstr(a, n - 3);
}

// strip spaces / tabs / CR / LF / nulls from both ends
string Trim(string s)
{
   int a = 0, b = StringLen(s) - 1;
   while(a <= b) { ushort c = StringGetCharacter(s, a); if(c==' '||c==9||c==13||c==10||c==0) a++; else break; }
   while(b >= a) { ushort c = StringGetCharacter(s, b); if(c==' '||c==9||c==13||c==10||c==0) b--; else break; }
   if(b < a) return "";
   return StringSubstr(s, a, b - a + 1);
}

// read token from MQL5\Files\<fn> (returns "" if not present/empty)
string ReadTokenFile(string fn)
{
   if(fn == "") return "";
   int h = FileOpen(fn, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return "";
   string all = "";
   while(!FileIsEnding(h)) all += FileReadString(h);
   FileClose(h);
   return Trim(all);
}

string OrderTypeStr(long t)
{
   switch((int)t)
   {
      case ORDER_TYPE_BUY:             return "BUY";
      case ORDER_TYPE_SELL:            return "SELL";
      case ORDER_TYPE_BUY_LIMIT:       return "BUY_LIMIT";
      case ORDER_TYPE_SELL_LIMIT:      return "SELL_LIMIT";
      case ORDER_TYPE_BUY_STOP:        return "BUY_STOP";
      case ORDER_TYPE_SELL_STOP:       return "SELL_STOP";
      case ORDER_TYPE_BUY_STOP_LIMIT:  return "BUY_STOP_LIMIT";
      case ORDER_TYPE_SELL_STOP_LIMIT: return "SELL_STOP_LIMIT";
      case ORDER_TYPE_CLOSE_BY:        return "CLOSE_BY";
   }
   return "OTHER";
}

string OrderStateStr(long s)
{
   switch((int)s)
   {
      case ORDER_STATE_STARTED:  return "STARTED";
      case ORDER_STATE_PLACED:   return "PLACED";
      case ORDER_STATE_CANCELED: return "CANCELED";
      case ORDER_STATE_PARTIAL:  return "PARTIAL";
      case ORDER_STATE_FILLED:   return "FILLED";
      case ORDER_STATE_REJECTED: return "REJECTED";
      case ORDER_STATE_EXPIRED:  return "EXPIRED";
   }
   return "OTHER";
}

int SymDigits(const string sym)
{
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   return (dg <= 0) ? 2 : dg;
}

string B64(const string s)
{
   uchar src[], dst[], key[];
   int n = StringToCharArray(s, src, 0, -1, CP_UTF8);
   if(n > 0 && src[n - 1] == 0) ArrayResize(src, n - 1);
   int r = CryptEncode(CRYPT_BASE64, src, key, dst);
   if(r <= 0) return "";
   return CharArrayToString(dst, 0, r);
}

string JVal(const string body, const string field)
{
   string k = "\"" + field + "\"";
   int p = StringFind(body, k);
   if(p < 0) return "";
   p = StringFind(body, ":", p + StringLen(k));
   if(p < 0) return "";
   int a = StringFind(body, "\"", p);
   if(a < 0) return "";
   int b = StringFind(body, "\"", a + 1);
   if(b < 0) return "";
   return StringSubstr(body, a + 1, b - a - 1);
}

string Headers()
{
   return "Authorization: Bearer " + gToken + "\r\n"
          "User-Agent: MT5-Investor-Watcher\r\n"
          "Accept: application/vnd.github+json\r\n"
          "Content-Type: application/json\r\n";
}

bool GhGetSha(const string path, string &sha)
{
   string url = API + GitHubOwner + "/" + GitHubRepo + "/contents/" + path + "?ref=" + GitHubBranch;
   char data[], result[]; string rh;
   ResetLastError();
   int code = WebRequest("GET", url, Headers(), 8000, data, result, rh);
   if(code == 200)
   {
      string body = CharArrayToString(result, 0, -1, CP_UTF8);
      sha = JVal(body, "sha");
      return (sha != "");
   }
   sha = "";
   return false;
}

bool GhPut(const string path, const string contentJson, const string msg)
{
   string sha;
   GhGetSha(path, sha);

   string body = "{\"message\":\"" + EscJson(msg) + "\","
                 "\"branch\":\"" + GitHubBranch + "\","
                 "\"content\":\"" + B64(contentJson) + "\"";
   if(sha != "") body += ",\"sha\":\"" + sha + "\"";
   body += "}";

   char data[], result[]; string rh;
   int n = StringToCharArray(body, data, 0, -1, CP_UTF8);
   if(n > 0 && data[n - 1] == 0) ArrayResize(data, n - 1);

   string url = API + GitHubOwner + "/" + GitHubRepo + "/contents/" + path;
   ResetLastError();
   int code = WebRequest("PUT", url, Headers(), 15000, data, result, rh);
   if(code == 200 || code == 201) return true;

   PrintFormat("GhPut FAIL %s : http=%d lastErr=%d resp=%s",
               path, code, GetLastError(), CharArrayToString(result, 0, 160));
   return false;
}

//+------------------------------------------------------------------+
//| Build JSON payloads                                              |
//+------------------------------------------------------------------+
string BuildLive()
{
   string s = "{";
   s += "\"login\":\""    + MaskLogin(gAcc) + "\",";
   s += "\"server\":\""   + EscJson(AccountInfoString(ACCOUNT_SERVER))  + "\",";
   s += "\"company\":\""  + EscJson(AccountInfoString(ACCOUNT_COMPANY)) + "\",";
   s += "\"currency\":\"" + AccountInfoString(ACCOUNT_CURRENCY) + "\",";
   s += "\"balance\":"    + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   s += "\"equity\":"     + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),  2) + ",";
   s += "\"margin\":"     + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN),  2) + ",";
   s += "\"floating\":"   + DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),  2) + ",";
   s += "\"updatedAt\":\""+ TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\",";
   s += "\"positions\":[";

   int total = PositionsTotal();
   bool first = true;
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(dg <= 0) dg = 2;
      long ty = PositionGetInteger(POSITION_TYPE);

      if(!first) s += ",";
      first = false;
      s += "{";
      s += "\"ticket\":"  + (string)tk + ",";
      s += "\"symbol\":\""+ sym + "\",";
      s += "\"type\":\""  + (ty == POSITION_TYPE_BUY ? "BUY" : "SELL") + "\",";
      s += "\"volume\":"  + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + ",";
      s += "\"open\":"    + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), dg) + ",";
      s += "\"price\":"   + DoubleToString(PositionGetDouble(POSITION_PRICE_CURRENT), dg) + ",";
      s += "\"sl\":"      + DoubleToString(PositionGetDouble(POSITION_SL), dg) + ",";
      s += "\"tp\":"      + DoubleToString(PositionGetDouble(POSITION_TP), dg) + ",";
      s += "\"profit\":"  + DoubleToString(PositionGetDouble(POSITION_PROFIT), 2) + ",";
      s += "\"magic\":"   + (string)PositionGetInteger(POSITION_MAGIC) + ",";
      s += "\"comment\":\""+ EscJson(PositionGetString(POSITION_COMMENT)) + "\",";
      s += "\"time\":\""  + TimeToString((datetime)PositionGetInteger(POSITION_TIME), TIME_DATE | TIME_SECONDS) + "\"";
      s += "}";
   }
   s += "],\"orders\":[";

   // ---- pending orders ----
   int ot = OrdersTotal();
   first = true;
   for(int i = 0; i < ot; i++)
   {
      ulong tk = OrderGetTicket(i);   // also selects the order
      if(tk == 0) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      int dg = SymDigits(sym);

      if(!first) s += ",";
      first = false;
      s += "{";
      s += "\"ticket\":"  + (string)tk + ",";
      s += "\"symbol\":\""+ sym + "\",";
      s += "\"type\":\""  + OrderTypeStr(OrderGetInteger(ORDER_TYPE)) + "\",";
      s += "\"volume\":"  + DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT), 2) + ",";
      s += "\"price\":"   + DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN), dg) + ",";
      s += "\"sl\":"      + DoubleToString(OrderGetDouble(ORDER_SL), dg) + ",";
      s += "\"tp\":"      + DoubleToString(OrderGetDouble(ORDER_TP), dg) + ",";
      s += "\"market\":"  + DoubleToString(SymbolInfoDouble(sym, SYMBOL_BID), dg) + ",";
      s += "\"magic\":"   + (string)OrderGetInteger(ORDER_MAGIC) + ",";
      s += "\"comment\":\""+ EscJson(OrderGetString(ORDER_COMMENT)) + "\",";
      s += "\"time\":\""  + TimeToString((datetime)OrderGetInteger(ORDER_TIME_SETUP), TIME_DATE | TIME_SECONDS) + "\"";
      s += "}";
   }
   s += "]}";
   return s;
}

string BuildHistory()
{
   datetime from = TimeCurrent() - (datetime)HistoryDays * 86400;
   HistorySelect(from, TimeCurrent());
   int total = HistoryDealsTotal();
   int start = (total > MaxDeals) ? total - MaxDeals : 0;

   string s = "{\"days\":" + (string)HistoryDays + ",\"deals\":[";
   bool first = true;
   for(int i = start; i < total; i++)
   {
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      long dt = HistoryDealGetInteger(tk, DEAL_TYPE);
      if(dt != DEAL_TYPE_BUY && dt != DEAL_TYPE_SELL) continue;

      long entry = HistoryDealGetInteger(tk, DEAL_ENTRY);
      string entryS = (entry == DEAL_ENTRY_IN)   ? "IN"   :
                      (entry == DEAL_ENTRY_OUT)  ? "OUT"  :
                      (entry == DEAL_ENTRY_INOUT)? "INOUT": "OUT_BY";
      string sym = HistoryDealGetString(tk, DEAL_SYMBOL);
      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(dg <= 0) dg = 2;

      if(!first) s += ",";
      first = false;
      s += "{";
      s += "\"ticket\":" + (string)tk + ",";
      s += "\"time\":\"" + TimeToString((datetime)HistoryDealGetInteger(tk, DEAL_TIME), TIME_DATE | TIME_SECONDS) + "\",";
      s += "\"symbol\":\""+ sym + "\",";
      s += "\"type\":\"" + (dt == DEAL_TYPE_BUY ? "BUY" : "SELL") + "\",";
      s += "\"entry\":\""+ entryS + "\",";
      s += "\"volume\":" + DoubleToString(HistoryDealGetDouble(tk, DEAL_VOLUME), 2) + ",";
      s += "\"price\":"  + DoubleToString(HistoryDealGetDouble(tk, DEAL_PRICE), dg) + ",";
      s += "\"profit\":" + DoubleToString(HistoryDealGetDouble(tk, DEAL_PROFIT), 2) + ",";
      s += "\"magic\":"  + (string)HistoryDealGetInteger(tk, DEAL_MAGIC) + ",";
      s += "\"comment\":\""+ EscJson(HistoryDealGetString(tk, DEAL_COMMENT)) + "\"";
      s += "}";
   }
   s += "],\"orders\":[";

   // ---- history orders (placed / canceled / filled / expired) ----
   int ho = HistoryOrdersTotal();
   int ostart = (ho > MaxHistOrders) ? ho - MaxHistOrders : 0;
   first = true;
   for(int i = ostart; i < ho; i++)
   {
      ulong tk = HistoryOrderGetTicket(i);
      if(tk == 0) continue;
      string sym = HistoryOrderGetString(tk, ORDER_SYMBOL);
      if(sym == "") continue;
      int dg = SymDigits(sym);

      if(!first) s += ",";
      first = false;
      s += "{";
      s += "\"ticket\":" + (string)tk + ",";
      s += "\"symbol\":\""+ sym + "\",";
      s += "\"type\":\"" + OrderTypeStr(HistoryOrderGetInteger(tk, ORDER_TYPE)) + "\",";
      s += "\"state\":\""+ OrderStateStr(HistoryOrderGetInteger(tk, ORDER_STATE)) + "\",";
      s += "\"volume\":" + DoubleToString(HistoryOrderGetDouble(tk, ORDER_VOLUME_INITIAL), 2) + ",";
      s += "\"price\":"  + DoubleToString(HistoryOrderGetDouble(tk, ORDER_PRICE_OPEN), dg) + ",";
      s += "\"sl\":"     + DoubleToString(HistoryOrderGetDouble(tk, ORDER_SL), dg) + ",";
      s += "\"tp\":"     + DoubleToString(HistoryOrderGetDouble(tk, ORDER_TP), dg) + ",";
      s += "\"magic\":"  + (string)HistoryOrderGetInteger(tk, ORDER_MAGIC) + ",";
      s += "\"comment\":\""+ EscJson(HistoryOrderGetString(tk, ORDER_COMMENT)) + "\",";
      s += "\"setup\":\""+ TimeToString((datetime)HistoryOrderGetInteger(tk, ORDER_TIME_SETUP), TIME_DATE | TIME_SECONDS) + "\",";
      s += "\"done\":\"" + TimeToString((datetime)HistoryOrderGetInteger(tk, ORDER_TIME_DONE),  TIME_DATE | TIME_SECONDS) + "\"";
      s += "}";
   }
   s += "]}";
   return s;
}

//+------------------------------------------------------------------+
//| TRAILING TRACKER (v1.03)                                         |
//|  Har 1 sec positions scan: SL khiske to event, position band ho  |
//|  to close-summary (peak vs close = give-back, deal reason).      |
//|  Dono JSONL files VPS ke MQL5\Files me (restart pe bhi bache),   |
//|  unki aakhri lines trail.json bankar GitHub jaati hain.          |
//+------------------------------------------------------------------+
struct PosTrack
{
   ulong    ticket;
   string   sym;
   int      dir;          // +1 buy, -1 sell
   double   open;
   double   vol;
   double   lastSL;
   double   lastTP;
   double   peakMove;     // best favourable price move from open
   double   peakProfit;
   double   firstTrig;    // price move when SL moved first time (-1 = not yet)
   double   firstLock;    // SL distance beyond open at first move
   int      trails;
   datetime openTime;
   bool     pre;          // already open when EA started
   bool     seen;
   long     magic;        // v1.05
   string   cm;           // v1.05 opening comment
   double   worstProfit;  // v1.05 sabse bura P/L (DD)
};

PosTrack gPos[];
bool     gRepDirty     = false;   // v1.05
datetime gLastRepPush  = 0;       // v1.05
datetime gLastRepTry   = 0;       // v1.05 fail ho to har second dobara na bheje
datetime gLastEqSnap   = 0;       // v1.05
double   gEqLow        = 0;       // v1.05 snapshot ke beech sabse neecha equity
bool     gTrailDirty   = false;
datetime gLastTrailPush = 0;
int      gSec          = 0;

string FEv() { return "IW_trail_events_" + gAcc + ".jsonl"; }
string FCl() { return "IW_trail_closes_" + gAcc + ".jsonl"; }
string FSh() { return "IW_shadow_" + gAcc + ".jsonl"; }      // written by BTC Trailing Manager v1.01+
string FEq() { return "IW_equity_" + gAcc + ".jsonl"; }      // v1.05
long   gShSize = -1;

// shadow file grew? -> trail.json needs a push
void CheckShadowFile()
{
   if(!FileIsExist(FSh())) return;
   long sz = FileGetInteger(FSh(), FILE_SIZE);
   if(sz >= 0 && sz != gShSize) { gShSize = sz; gTrailDirty = true; }
}

void AppendLine(const string fn, const string line)
{
   int h = FileOpen(fn, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) { Print("Trail file open fail: ", fn, " err=", GetLastError()); return; }
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, line + "\r\n");
   FileClose(h);
}

// last N non-empty lines of a JSONL file, joined with commas
string TailJoin(const string fn, int maxLines)
{
   int h = FileOpen(fn, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return "";
   string lines[];
   int n = 0;
   while(!FileIsEnding(h))
   {
      string l = Trim(FileReadString(h));
      if(l == "") continue;
      ArrayResize(lines, n + 1);
      lines[n++] = l;
   }
   FileClose(h);
   int start = (n > maxLines) ? n - maxLines : 0;
   string out = "";
   for(int i = start; i < n; i++) { if(out != "") out += ","; out += lines[i]; }
   return out;
}

int FindPos(ulong tk)
{
   for(int i = 0; i < ArraySize(gPos); i++) if(gPos[i].ticket == tk) return i;
   return -1;
}

string DealReasonStr(long r)
{
   switch((int)r)
   {
      case DEAL_REASON_SL:     return "SL";
      case DEAL_REASON_TP:     return "TP";
      case DEAL_REASON_SO:     return "STOPOUT";
      case DEAL_REASON_EXPERT: return "EA";
      case DEAL_REASON_CLIENT: return "MANUAL";
      case DEAL_REASON_MOBILE: return "MOBILE";
      case DEAL_REASON_WEB:    return "WEB";
   }
   return "OTHER";
}

string Num(double v, int dg) { return DoubleToString(v, dg); }
string TS(datetime t)        { return TimeToString(t, TIME_DATE | TIME_SECONDS); }

void RecordClose(const PosTrack &p)
{
   double closePx = 0, profit = 0;
   datetime ct = 0;
   string reason = "UNKNOWN";
   string inCm = "";
   if(HistorySelectByPosition(p.ticket))
   {
      int nd = HistoryDealsTotal();
      for(int i = 0; i < nd; i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0) continue;
         long en = HistoryDealGetInteger(d, DEAL_ENTRY);
         if(en == DEAL_ENTRY_IN && inCm == "") inCm = HistoryDealGetString(d, DEAL_COMMENT);
         if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY || en == DEAL_ENTRY_INOUT)
         {
            closePx = HistoryDealGetDouble(d, DEAL_PRICE);
            profit += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
            ct = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
            reason = DealReasonStr(HistoryDealGetInteger(d, DEAL_REASON));
         }
      }
   }
   int dg = SymDigits(p.sym);
   double closeMove = (closePx > 0) ? p.dir * (closePx - p.open) : 0;
   string l = "{";
   l += "\"t\":\""   + TS(p.openTime) + "\",";
   l += "\"ct\":\""  + TS(ct) + "\",";
   l += "\"ticket\":"+ (string)p.ticket + ",";
   l += "\"sym\":\"" + p.sym + "\",";
   l += "\"side\":\""+ (p.dir > 0 ? "BUY" : "SELL") + "\",";
   l += "\"vol\":"   + Num(p.vol, 2) + ",";
   l += "\"open\":"  + Num(p.open, dg) + ",";
   l += "\"close\":" + Num(closePx, dg) + ",";
   l += "\"move\":"  + Num(closeMove, dg) + ",";
   l += "\"peak\":"  + Num(p.peakMove, dg) + ",";
   l += "\"giveBack\":" + Num(p.peakMove - closeMove, dg) + ",";
   l += "\"profit\":"+ Num(profit, 2) + ",";
   l += "\"peakProfit\":" + Num(p.peakProfit, 2) + ",";
   l += "\"trails\":"+ (string)p.trails + ",";
   l += "\"first\":" + ((p.trails > 0 && !p.pre) ? Num(p.firstTrig, dg) : "null") + ",";
   l += "\"firstLock\":" + (p.trails > 0 && !p.pre ? Num(p.firstLock, dg) : "null") + ",";
   l += "\"reason\":\"" + reason + "\",";
   l += "\"magic\":" + (string)p.magic + ",";
   l += "\"cm\":\""   + EscJson(p.cm != "" ? p.cm : inCm) + "\",";
   l += "\"sl\":"    + Num(p.lastSL, dg) + ",";
   l += "\"tp\":"    + Num(p.lastTP, dg) + ",";
   l += "\"worst\":" + Num(p.worstProfit, 2) + ",";
   l += "\"pre\":"   + (p.pre ? "true" : "false");
   l += "}";
   AppendLine(FCl(), l);
   gTrailDirty = true;
   gRepDirty   = true;     // v1.05
}

void ScanPositions(bool initial)
{
   for(int i = 0; i < ArraySize(gPos); i++) gPos[i].seen = false;

   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;

      string sym  = PositionGetString(POSITION_SYMBOL);
      int    dir  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);
      double tp   = PositionGetDouble(POSITION_TP);
      double px   = (dir > 0) ? SymbolInfoDouble(sym, SYMBOL_BID) : SymbolInfoDouble(sym, SYMBOL_ASK);
      if(px <= 0) px = PositionGetDouble(POSITION_PRICE_CURRENT);
      double move   = dir * (px - open);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(pt <= 0) pt = 0.01;
      int    dg     = SymDigits(sym);

      int k = FindPos(tk);
      if(k < 0)
      {
         k = ArraySize(gPos);
         ArrayResize(gPos, k + 1);
         gPos[k].ticket    = tk;
         gPos[k].sym       = sym;
         gPos[k].dir       = dir;
         gPos[k].open      = open;
         gPos[k].vol       = PositionGetDouble(POSITION_VOLUME);
         gPos[k].lastSL    = sl;
         gPos[k].lastTP    = tp;
         gPos[k].peakMove  = move;
         gPos[k].peakProfit= profit;
         gPos[k].firstTrig = -1;
         gPos[k].firstLock = 0;
         gPos[k].trails    = 0;
         gPos[k].openTime  = (datetime)PositionGetInteger(POSITION_TIME);
         gPos[k].pre       = initial;
         gPos[k].magic     = PositionGetInteger(POSITION_MAGIC);
         gPos[k].cm        = PositionGetString(POSITION_COMMENT);
         gPos[k].worstProfit = profit;
      }
      gPos[k].seen = true;
      if(move   > gPos[k].peakMove)   gPos[k].peakMove   = move;
      if(profit > gPos[k].peakProfit) gPos[k].peakProfit = profit;
      if(profit < gPos[k].worstProfit) gPos[k].worstProfit = profit;   // v1.05
      if(gPos[k].cm == "") gPos[k].cm = PositionGetString(POSITION_COMMENT);

      bool slChanged = MathAbs(sl - gPos[k].lastSL) > pt * 0.5;
      bool tpChanged = MathAbs(tp - gPos[k].lastTP) > pt * 0.5;
      if(slChanged || tpChanged)
      {
         if(slChanged)
         {
            gPos[k].trails++;
            if(gPos[k].trails == 1) { gPos[k].firstTrig = move; gPos[k].firstLock = (sl > 0) ? dir * (sl - open) : 0; }
         }
         string l = "{";
         l += "\"t\":\""     + TS(TimeCurrent()) + "\",";
         l += "\"ticket\":"  + (string)tk + ",";
         l += "\"sym\":\""   + sym + "\",";
         l += "\"side\":\""  + (dir > 0 ? "BUY" : "SELL") + "\",";
         l += "\"vol\":"     + Num(gPos[k].vol, 2) + ",";
         l += "\"open\":"    + Num(open, dg) + ",";
         l += "\"price\":"   + Num(px, dg) + ",";
         l += "\"oldSL\":"   + Num(gPos[k].lastSL, dg) + ",";
         l += "\"sl\":"      + Num(sl, dg) + ",";
         l += "\"tp\":"      + Num(tp, dg) + ",";
         l += "\"step\":"    + ((gPos[k].lastSL > 0 && sl > 0) ? Num(dir * (sl - gPos[k].lastSL), dg) : "null") + ",";
         l += "\"lock\":"    + ((sl > 0) ? Num(dir * (sl - open), dg) : "null") + ",";
         l += "\"gap\":"     + ((sl > 0) ? Num(dir * (px - sl), dg) : "null") + ",";
         l += "\"move\":"    + Num(move, dg) + ",";
         l += "\"peak\":"    + Num(gPos[k].peakMove, dg) + ",";
         l += "\"profit\":"  + Num(profit, 2) + ",";
         l += "\"n\":"       + (string)gPos[k].trails + ",";
         l += "\"kind\":\""  + (slChanged ? (tpChanged ? "SL+TP" : "SL") : "TP") + "\",";
         l += "\"pre\":"     + (gPos[k].pre ? "true" : "false");
         l += "}";
         AppendLine(FEv(), l);
         gTrailDirty = true;
         gPos[k].lastSL = sl;
         gPos[k].lastTP = tp;
      }
   }

   // positions that disappeared -> closed
   for(int i = ArraySize(gPos) - 1; i >= 0; i--)
   {
      if(gPos[i].seen) continue;
      RecordClose(gPos[i]);
      int last = ArraySize(gPos) - 1;
      if(i != last) gPos[i] = gPos[last];
      ArrayResize(gPos, last);
   }
}

string BuildTrail()
{
   string s = "{";
   s += "\"updatedAt\":\"" + TS(TimeCurrent()) + "\",";
   s += "\"open\":[";
   for(int i = 0; i < ArraySize(gPos); i++)
   {
      int dg = SymDigits(gPos[i].sym);
      if(i > 0) s += ",";
      s += "{\"ticket\":" + (string)gPos[i].ticket + ",\"sym\":\"" + gPos[i].sym + "\",\"side\":\"" + (gPos[i].dir > 0 ? "BUY" : "SELL") +
           "\",\"open\":" + Num(gPos[i].open, dg) + ",\"sl\":" + Num(gPos[i].lastSL, dg) + ",\"peak\":" + Num(gPos[i].peakMove, dg) +
           ",\"peakProfit\":" + Num(gPos[i].peakProfit, 2) + ",\"trails\":" + (string)gPos[i].trails + "}";
   }
   s += "],\"events\":[" + TailJoin(FEv(), TrailEventsKeep) + "]";
   s += ",\"closes\":["  + TailJoin(FCl(), TrailClosesKeep) + "]";
   s += ",\"shadow\":["  + TailJoin(FSh(), ShadowKeep) + "]}";
   return s;
}

//+------------------------------------------------------------------+
//| v1.05 SAMU REPORT - report.json                                  |
//+------------------------------------------------------------------+
void EquityTick()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(gEqLow <= 0 || eq < gEqLow) gEqLow = eq;
   int every = (EquityEveryMin < 1) ? 1 : EquityEveryMin;
   if(gLastEqSnap != 0 && TimeCurrent() - gLastEqSnap < (datetime)every * 60) return;
   string l = "{\"t\":\"" + TS(TimeCurrent()) + "\",\"b\":" + Num(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
              ",\"e\":" + Num(eq, 2) + ",\"lo\":" + Num(gEqLow, 2) + "}";
   AppendLine(FEq(), l);
   gLastEqSnap = TimeCurrent();
   gEqLow      = eq;
}

string BuildReport()
{
   bool real = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   string s = "{\"v\":1,";
   s += "\"updatedAt\":\"" + TS(TimeCurrent()) + "\",";
   s += "\"login\":\""   + MaskLogin(gAcc) + "\",";
   s += "\"server\":\""  + EscJson(AccountInfoString(ACCOUNT_SERVER))  + "\",";
   s += "\"company\":\"" + EscJson(AccountInfoString(ACCOUNT_COMPANY)) + "\",";
   s += "\"currency\":\""+ AccountInfoString(ACCOUNT_CURRENCY) + "\",";
   s += "\"real\":"       + (real ? "true" : "false") + ",";
   s += "\"balance\":"    + Num(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   s += "\"equity\":"     + Num(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
   s += "\"open\":[";
   for(int i = 0; i < ArraySize(gPos); i++)
   {
      if(i > 0) s += ",";
      s += "{\"ticket\":" + (string)gPos[i].ticket + ",\"worst\":" + Num(gPos[i].worstProfit, 2) +
           ",\"best\":" + Num(gPos[i].peakProfit, 2) + ",\"pre\":" + (gPos[i].pre ? "true" : "false") + "}";
   }
   s += "],\"closes\":[" + TailJoin(FCl(), ReportClosesKeep) + "]";
   s += ",\"eq\":["      + TailJoin(FEq(), ReportEqKeep) + "]}";
   return s;
}

void PushReport()
{
   if(!ReportEnabled) return;
   gLastRepTry = TimeCurrent();
   string path = "data/" + gAcc + "/report.json";
   if(GhPut(path, BuildReport(), "report update " + TimeToString(TimeCurrent(), TIME_SECONDS)))
   {
      gRepDirty   = false;
      gLastRepPush = TimeCurrent();
   }
}

void PushTrail()
{
   string path = "data/" + gAcc + "/trail.json";
   if(GhPut(path, BuildTrail(), "trail update " + TimeToString(TimeCurrent(), TIME_SECONDS)))
   {
      gTrailDirty = false;
      gLastTrailPush = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Push routines                                                    |
//+------------------------------------------------------------------+
void PushLive()
{
   string path = "data/" + gAcc + "/live.json";
   if(GhPut(path, BuildLive(), "live update " + TimeToString(TimeCurrent(), TIME_SECONDS)))
      Comment("Investor Watcher v1.05\nAccount: " + MaskLogin(gAcc) +
              "\nLast live push: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
              "\nOpen positions: " + (string)PositionsTotal() + "  Pending: " + (string)OrdersTotal() +
              "\nTracked for trailing: " + (string)ArraySize(gPos));
}

void PushHistory()
{
   string path = "data/" + gAcc + "/history.json";
   if(GhPut(path, BuildHistory(), "history refresh"))
      gLastHist = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Lifecycle                                                        |
//+------------------------------------------------------------------+
int OnInit()
{
   gToken = ReadTokenFile(TokenFile);
   string srcMsg = "file (" + TokenFile + ")";
   if(gToken == "") { gToken = Trim(GitHubToken); srcMsg = "input"; }

   PrintFormat("Investor Watcher v1.05: token source=%s, token length=%d (fine-grained PAT ~93 chars)",
               srcMsg, StringLen(gToken));

   if(gToken == "")
   {
      Alert("Investor Watcher: token khali hai. GitHubToken input bharo ya MQL5\\Files\\" + TokenFile + " banao.");
      return INIT_FAILED;
   }

   gAcc = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Investor Watcher v1.05 starting for account ", MaskLogin(gAcc));
   Print("Reminder: Tools > Options > Expert Advisors > allow WebRequest for: https://api.github.com");

   ArrayResize(gPos, 0);
   ScanPositions(true);     // already-open positions marked 'pre'

   PushHistory();
   PushLive();
   PushTrail();
   EquityTick();            // v1.05
   PushReport();            // v1.05

   EventSetTimer(1);        // 1-second scan for trailing
   return INIT_SUCCEEDED;
}

void OnTimer()
{
   ScanPositions(false);
   CheckShadowFile();
   gSec++;

   int liveEvery  = (LiveSeconds < 5) ? 5 : LiveSeconds;
   int trailEvery = (TrailPushSeconds < 30) ? 30 : TrailPushSeconds;

   if(gSec % liveEvery == 0)
      PushLive();

   if(gTrailDirty && TimeCurrent() - gLastTrailPush >= (datetime)trailEvery)
      PushTrail();

   if(TimeCurrent() - gLastHist >= (datetime)HistoryRefreshMin * 60)
      PushHistory();

   // v1.05 SAMU REPORT
   if(ReportEnabled)
   {
      EquityTick();
      int repEvery = (ReportPushMin < 1) ? 1 : ReportPushMin;
      if(TimeCurrent() - gLastRepTry >= 60 &&
         ((gRepDirty && TimeCurrent() - gLastRepPush >= 60) || TimeCurrent() - gLastRepPush >= (datetime)repEvery * 60))
         PushReport();
   }
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

void OnTick() {}
//+------------------------------------------------------------------+
