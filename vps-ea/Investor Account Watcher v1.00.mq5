//+------------------------------------------------------------------+
//|                                  Investor Account Watcher v1.00   |
//|                                        Ankush New Vision          |
//|                                                                   |
//|  READ-ONLY account watcher. Attach it to ONE chart in an MT5      |
//|  terminal that is logged in with an INVESTOR (read-only) login.   |
//|  It reads the account's open positions + closed history and       |
//|  pushes them as JSON files into your GitHub repo, so your mobile  |
//|  PWA dashboard can show them live.                                |
//|                                                                   |
//|  It NEVER opens, closes or modifies any trade.                    |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property link      "https://github.com/ankushchhajed7-cmd"
#property version   "1.00"
#property strict

//--- Inputs ---------------------------------------------------------
input string  GitHubOwner       = "ankushchhajed7-cmd"; // GitHub username
input string  GitHubRepo        = "INVESTOR-ID";        // repo name (public)
input string  GitHubBranch      = "main";               // branch GitHub Pages serves
input string  GitHubToken       = "";                   // fine-grained PAT: Contents = Read & write on THIS repo only
input int     LiveSeconds       = 20;                   // push open trades every N seconds
input int     HistoryDays       = 60;                   // how many days of closed history to upload
input int     HistoryRefreshMin = 30;                   // re-upload history every N minutes
input int     MaxDeals          = 1500;                 // safety cap on number of history deals

//--- Globals --------------------------------------------------------
string   gAcc        = "";
datetime gLastHist   = 0;
const string API     = "https://api.github.com/repos/";

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

// Base64 encode a UTF-8 string
string B64(const string s)
{
   uchar src[], dst[], key[];
   int n = StringToCharArray(s, src, 0, -1, CP_UTF8);
   if(n > 0 && src[n - 1] == 0) ArrayResize(src, n - 1); // drop trailing null
   int r = CryptEncode(CRYPT_BASE64, src, key, dst);
   if(r <= 0) return "";
   return CharArrayToString(dst, 0, r);
}

// tolerant string-value extractor from a JSON body ("field": "value")
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
   return "Authorization: Bearer " + GitHubToken + "\r\n"
          "User-Agent: MT5-Investor-Watcher\r\n"
          "Accept: application/vnd.github+json\r\n"
          "Content-Type: application/json\r\n";
}

// get current blob sha of a file (empty if file does not exist yet)
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
   return false; // 404 => new file, or network/token issue
}

// create or update a file in the repo
bool GhPut(const string path, const string contentJson, const string msg)
{
   string sha;
   GhGetSha(path, sha); // ok if empty (new file)

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
      s += "\"time\":\""  + TimeToString((datetime)PositionGetInteger(POSITION_TIME), TIME_DATE | TIME_SECONDS) + "\"";
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
      if(dt != DEAL_TYPE_BUY && dt != DEAL_TYPE_SELL) continue; // skip balance/credit ops

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
      s += "\"profit\":" + DoubleToString(HistoryDealGetDouble(tk, DEAL_PROFIT), 2);
      s += "}";
   }
   s += "]}";
   return s;
}

//+------------------------------------------------------------------+
//| Push routines                                                    |
//+------------------------------------------------------------------+
void PushLive()
{
   string path = "data/" + gAcc + "/live.json";
   if(GhPut(path, BuildLive(), "live update " + TimeToString(TimeCurrent(), TIME_SECONDS)))
      Comment("Investor Watcher v1.00\nAccount: " + MaskLogin(gAcc) +
              "\nLast live push: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
              "\nOpen positions: " + (string)PositionsTotal());
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
   if(GitHubToken == "")
   {
      Alert("Investor Watcher: GitHubToken input is empty. Set your fine-grained PAT.");
      return INIT_FAILED;
   }
   if(!MQLInfoInteger(MQL_TESTER) && !TerminalInfoInteger(TERMINAL_CONNECTED))
      Print("Warning: terminal not connected yet.");

   gAcc = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

   Print("Investor Watcher v1.00 starting for account ", MaskLogin(gAcc));
   Print("IMPORTANT: Tools > Options > Expert Advisors > allow WebRequest for: https://api.github.com");

   PushHistory();   // full history once at start (permanent in repo)
   PushLive();      // first live snapshot

   EventSetTimer(MathMax(5, LiveSeconds));
   return INIT_SUCCEEDED;
}

void OnTimer()
{
   PushLive();
   if(TimeCurrent() - gLastHist >= (datetime)HistoryRefreshMin * 60)
      PushHistory();
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

// We intentionally do NOTHING on ticks – this EA never trades.
void OnTick() {}
//+------------------------------------------------------------------+
