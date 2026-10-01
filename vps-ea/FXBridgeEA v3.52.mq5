//+------------------------------------------------------------------+
//|                                         FXBridgeEA v3.52.mq5     |
//|              Firebase Bridge for ForexDiagnosis PWA              |
//|                                                                  |
//|  App Firebase pe order likhta hai, ye EA usse padh kar MT5 me    |
//|  pending order place karta hai.                                  |
//|                                                                  |
//|  Firebase path:  <FirebaseURL>/fxbridge/order.json               |
//|  JSON format: {"id":123,"pair":"XAUUSD","type":"SELLLIMIT",      |
//|                "lots":0.01,"entry":4022.36,"sl":4048.51,         |
//|                "tp":3970.06}                                     |
//|                                                                  |
//|  v3.52 (01-Oct-2026) REAL ACCOUNT ke liye:                       |
//|   * FirebaseAuth input — har request ?auth=secret ke saath, taaki |
//|     Firebase rules me fxbridge band kar sako (koi aur order na   |
//|     likh sake). Default Firebase URL hataya (khud daalo).        |
//|   * SymbolMap + auto symbol dhundhna (XM: XAUUSD -> GOLD.i#,     |
//|     BTCUSD -> BTCUSD#; Exness: XAUUSDm ...).                     |
//|   * ConfirmRealAccount: REAL account pe ye true kiye bina order  |
//|     nahi lagega (test mode). Auto-trade REAL pe kabhi nahi.      |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "3.52"
#property strict

#include <Trade\Trade.mqh>

//--- Inputs
input string  ActivationKey  = "";         // Activation Key (owner se lo - account-locked)
input string  FirebaseURL    = "";         // Firebase URL (SamuSignal Settings wala)
input string  FirebaseAuth   = "";         // Firebase secret (app Settings me jo daala) — real account ke liye zaroori
input string  SymbolSuffix   = "m";        // Broker suffix (Exness = "m", XM = "#", koi nahi = khaali)
input string  SymbolMap      = "";         // Naam alag ho to: XAUUSD=GOLD.i#;BTCUSD=BTCUSD#
input bool    ConfirmRealAccount = false;  // REAL account pe order lagane ke liye true karo
input int     PollSeconds    = 10;         // Firebase check interval (seconds)
input double  MaxLots        = 0.50;       // Safety: max lot allowed per order
input int     MagicNumber    = 777001;     // Magic number
input int     ExpiryHours    = 24;         // Pending order expiry (0 = no expiry)
input bool    EnableTrading  = false;      // Master switch (false = read-only test)
input string  TgBotToken     = "";         // Telegram Bot Token (confirmation, optional)
input string  TgChatID       = "";         // Telegram Chat ID (optional)
input bool    EnableSignalAlerts = true;                                   // Signal flip pe Telegram alert
input bool    EnablePaperTrades  = true;                                   // Auto paper-trade (24/7, app ki My Trades me)
input bool    EnableAutoTrade    = false;                                  // ⚠️ Auto REAL trade MT5 pe (DEMO pe test karo!)
input double  AutoTradeLots      = 0.01;                                   // Auto-trade lot size
input string  AlertPairs        = "EURUSD,GBPUSD,XAUUSD,BTCUSD,ETHUSD";    // Alert/Paper pairs (bina suffix, comma-separated)
input int     AlertCheckMinutes = 5;                                       // Kitne min me signal check karein

//--- Globals
CTrade   trade;
long     lastOrderID = 0;
ulong    g_trackedTickets[];    // open FXDiag positions (reverse-bridge)
long     g_trackedOrderIDs[];   // parallel: app orderId for each
double   g_trackedInitRisk[];   // parallel: initial risk distance |entry-SL| (for trailing)
long     g_lastBeCommand = 0;   // last processed breakeven command timestamp
bool     g_trailOn = false;     // trailing enabled globally (from app)
datetime g_lastSpecTime = 0;    // last time symbol specs bheji
string   g_alertSyms[];         // signal-alert: broker symbols (with suffix)
int      g_alertDir[];          // signal-alert: last known trend dir (1/-1/0)
datetime g_lastAlertCheck = 0;  // signal-alert: last check time
bool     g_startupSent = false; // startup Telegram test bheja ya nahi
long     g_paperIds[];          // paper trades: id
string   g_paperPairs[];        // parallel: base pair name
string   g_paperSyms[];         // parallel: broker symbol
double   g_paperEntry[];        // parallel: entry
double   g_paperSL[];           // parallel: SL
double   g_paperTP[];           // parallel: TP
int      g_paperDir[];          // parallel: 1=buy, -1=sell
int      g_paperSeq = 0;        // unique id counter

//--- v3.52: Firebase URL + auth, symbol resolve ---
string g_base = "";
bool   g_isReal = false;
string g_rsPair[]; string g_rsSym[];

string FbUrl(string path)
{
   string u = g_base + path;
   if(StringLen(FirebaseAuth) > 0) u += "?auth=" + FirebaseAuth;
   return u;
}

bool SymOK(string sym)
{
   if(sym == "") return false;
   return SymbolSelect(sym, true) && SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE) > 0;
}

string MapLookup(string pair)
{
   string items[];
   int n = StringSplit(SymbolMap, ';', items);
   for(int i = 0; i < n; i++)
   {
      string kv[];
      if(StringSplit(items[i], '=', kv) != 2) continue;
      string k = kv[0], v = kv[1];
      StringTrimLeft(k); StringTrimRight(k); StringTrimLeft(v); StringTrimRight(v);
      StringToUpper(k);
      if(k == pair) return v;
   }
   return "";
}

// App "XAUUSD" bhejta hai — broker ka asli naam dhundho
string ResolveSymbol(string pair)
{
   StringToUpper(pair);
   for(int i = 0; i < ArraySize(g_rsPair); i++)
      if(g_rsPair[i] == pair) return g_rsSym[i];

   string found = "";
   string m = MapLookup(pair);
   if(m != "" && SymOK(m)) found = m;
   if(found == "" && SymOK(pair + SymbolSuffix)) found = pair + SymbolSuffix;
   if(found == "" && SymOK(pair)) found = pair;
   string alias = "";
   if(pair == "XAUUSD") alias = "GOLD";
   else if(pair == "XAGUSD") alias = "SILVER";
   else if(pair == "US30") alias = "US30Cash";
   if(found == "" && alias != "" && SymOK(alias + SymbolSuffix)) found = alias + SymbolSuffix;
   if(found == "")
   {
      // poori symbol list me naam ke shuru se dhundho (pehle Market Watch)
      for(int pass = 0; pass < 2 && found == ""; pass++)
      {
         int tot = SymbolsTotal(pass == 0);
         for(int i = 0; i < tot; i++)
         {
            string s = SymbolName(i, pass == 0);
            string u = s; StringToUpper(u);
            if(StringFind(u, pair) == 0 || (alias != "" && StringFind(u, alias) == 0))
            {
               if(SymOK(s)) { found = s; break; }
            }
         }
      }
   }
   int n = ArraySize(g_rsPair);
   ArrayResize(g_rsPair, n + 1); ArrayResize(g_rsSym, n + 1);
   g_rsPair[n] = pair; g_rsSym[n] = found;
   if(found != "" && found != pair + SymbolSuffix) Print("Symbol: ", pair, " -> ", found);
   return found;
}

// Broker symbol se app wala naam (specs ke liye)
string BaseOf(string sym)
{
   for(int i = 0; i < ArraySize(g_rsSym); i++)
      if(g_rsSym[i] == sym && g_rsPair[i] != "") return g_rsPair[i];
   string base = sym;
   int slen = StringLen(SymbolSuffix);
   if(slen > 0 && StringLen(sym) > slen && StringSubstr(sym, StringLen(sym) - slen) == SymbolSuffix)
      base = StringSubstr(sym, 0, StringLen(sym) - slen);
   StringToUpper(base);
   return base;
}

bool TradingOn()
{
   if(!EnableTrading) return false;
   if(g_isReal && !ConfirmRealAccount) return false;
   return true;
}

//--- EA LICENSE (account-locked) ---
#define EA_SECRET "ANV-FXBRIDGE-2026-Q9Z"   // Owner secret (keygen me SAME)

// Account number se deterministic key banao (keygen se match hona chahiye)
string MakeEAKey(long account)
{
   string seed = IntegerToString(account) + EA_SECRET;
   uint h1 = 2166136261;
   for(int i = 0; i < StringLen(seed); i++)
   {
      h1 ^= (uint)StringGetCharacter(seed, i);
      h1 *= 16777619;
   }
   uint h2 = 19088743;
   for(int i = StringLen(seed) - 1; i >= 0; i--)
   {
      h2 ^= (uint)StringGetCharacter(seed, i);
      h2 *= 2246822519;
   }
   // 3 blocks of base36-ish (A-Z0-9)
   string chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   string key = "";
   uint vals[3];
   vals[0] = h1 % 1679616;          // 36^4
   vals[1] = h2 % 1679616;
   vals[2] = (h1 ^ h2) % 1679616;
   for(int b = 0; b < 3; b++)
   {
      uint v = vals[b];
      string block = "";
      for(int c = 0; c < 4; c++)
      {
         block = StringSubstr(chars, (int)(v % 36), 1) + block;
         v /= 36;
      }
      key += (b > 0 ? "-" : "") + block;
   }
   return key;
}

bool VerifyLicense()
{
   long account = AccountInfoInteger(ACCOUNT_LOGIN);
   string expected = MakeEAKey(account);
   string entered = ActivationKey;
   StringToUpper(entered);
   StringTrimLeft(entered);
   StringTrimRight(entered);
   return (entered == expected);
}

//+------------------------------------------------------------------+
int OnInit()
{
   // ===== LICENSE CHECK - EA sirf authorized account pe chale =====
   long account = AccountInfoInteger(ACCOUNT_LOGIN);
   if(!VerifyLicense())
   {
      Print("========================================");
      Print("  FXBRIDGE EA - LICENSE REQUIRED");
      Print("  Ye account: ", account);
      Print("  Is account ke liye Activation Key chahiye.");
      Print("  Owner ko ye account number bhejo:");
      Print("  >>> ", account, " <<<");
      Print("  Key milne pe EA settings me ActivationKey me daalo.");
      Print("  WhatsApp: +91 97658 38383");
      Print("========================================");
      Alert("FXBridge EA: Account ", account, " ke liye Activation Key chahiye. Owner ko account number bhejo: ", account);
      Comment("\n\n  FXBRIDGE EA - LOCKED\n\n  Account: " + IntegerToString(account) +
              "\n\n  Ye account number owner ko bhejo,\n  Activation Key le kar settings me daalo.\n\n  WhatsApp: +91 97658 38383");
      return(INIT_FAILED);
   }
   Comment("");  // clear
   Print("License OK - Account ", account, " authorized ✓");

   g_base = FirebaseURL;
   StringTrimLeft(g_base); StringTrimRight(g_base);
   while(StringLen(g_base) > 0 && StringGetCharacter(g_base, StringLen(g_base) - 1) == '/')
      g_base = StringSubstr(g_base, 0, StringLen(g_base) - 1);
   if(StringLen(g_base) < 10)
   {
      Print("ERROR: FirebaseURL khali hai - EA settings me daalo");
      Alert("FXBridge EA: Firebase URL input me daalo (SamuSignal Settings wala)");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(StringFind(g_base, "http") != 0) g_base = "https://" + g_base;

   g_isReal = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   if(g_isReal)
   {
      Print(">>> REAL ACCOUNT. ConfirmRealAccount=", ConfirmRealAccount,
            (ConfirmRealAccount ? "  — orders LAGENGE" : "  — TEST MODE (order nahi lagega)"));
      if(StringLen(FirebaseAuth) == 0)
         Print(">>> DHYAN: FirebaseAuth khaali hai — Firebase me fxbridge khula rahega. Secret daalo.");
      if(EnableAutoTrade) Print(">>> EnableAutoTrade REAL account pe band rehta hai (sirf demo).");
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);

   // VPS restart ke baad duplicate order avoid
   lastOrderID = (long)GlobalVariableGet("FXBridge_LastOrderID");

   Print("=== FXBridge EA v3.52 (Firebase) Started ===");
   Print("URL: ", g_base, (StringLen(FirebaseAuth) > 0 ? "  (auth ON)" : "  (auth OFF)"));
   Print("Poll: ", PollSeconds, "s | Suffix: '", SymbolSuffix, "' | Trading: ", TradingOn(), (g_isReal ? " | REAL" : " | DEMO"));
   Print("Last processed order ID: ", lastOrderID);
   Print(">>> ZAROORI: Tools > Options > Expert Advisors me ye URL allow karo:");
   Print("    ", g_base);
   if(StringLen(TgBotToken) > 10) Print("    https://api.telegram.org");

   // Signal-alert pairs setup
   if(EnableSignalAlerts)
   {
      string parts[];
      int cnt = StringSplit(AlertPairs, ',', parts);
      for(int i = 0; i < cnt; i++)
      {
         string base = parts[i];
         StringTrimLeft(base); StringTrimRight(base);
         if(base == "") continue;
         string sym = ResolveSymbol(base);
         if(sym == "") { Print("Alert pair nahi mila: ", base); continue; }
         int m = ArraySize(g_alertSyms);
         ArrayResize(g_alertSyms, m + 1);
         ArrayResize(g_alertDir, m + 1);
         g_alertSyms[m] = sym;
         g_alertDir[m]  = 0;             // 0 = abhi pata nahi (pehli baar init)
      }
      Print("Signal alerts ON for ", ArraySize(g_alertSyms), " pairs (har ", AlertCheckMinutes, " min)");
   }

   EventSetTimer(PollSeconds);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);
   Print("=== FXBridge EA Stopped ===");
}

//+------------------------------------------------------------------+
void OnTimer()
{
   // Startup Telegram test (OnInit me WebRequest allowed nahi, isliye yahan)
   if(!g_startupSent)
   {
      g_startupSent = true;
      SendReply("EA started ✅\nAlerts ready (" + IntegerToString(ArraySize(g_alertSyms)) +
                " pairs)\nAccount: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
   }

   CheckFirebase();
   TrackAndReportClosures();   // reverse-bridge: band hue trades app ko batao
   CheckCommands();            // app se BE / Trailing commands
   ApplyTrailing();            // trailing on ho to har tick SL follow karao
   if(EnablePaperTrades) CheckPaperResults();   // paper trades ka TP/SL check (24/7)

   // Har 60 sec: Market Watch symbols ki spec app ko bhejo (auto SL/TP $)
   if(TimeCurrent() - g_lastSpecTime >= 60)
   {
      g_lastSpecTime = TimeCurrent();
      SendSymbolSpecs();
   }

   // Signal flip alerts (Telegram) — har AlertCheckMinutes
   if(EnableSignalAlerts && TimeCurrent() - g_lastAlertCheck >= AlertCheckMinutes * 60)
   {
      g_lastAlertCheck = TimeCurrent();
      CheckSignalFlips();
   }
}

//+------------------------------------------------------------------+
//| Firebase se latest order padho                                    |
//+------------------------------------------------------------------+
void CheckFirebase()
{
   string url = FbUrl("/fxbridge/order.json");

   char   post[], result[];
   string headers = "";
   string resultHeaders;

   ResetLastError();
   int res = WebRequest("GET", url, headers, 5000, post, result, resultHeaders);

   if(res == -1)
   {
      int err = GetLastError();
      if(err == 4060)
         Print("ERROR 4060: '", g_base, "' allowed URLs me add nahi hai! Tools > Options > Expert Advisors");
      else
         Print("WebRequest failed, error: ", err);
      return;
   }

   if(res != 200)
   {
      Print("Firebase HTTP ", res, (res == 401 ? "  (FirebaseAuth galat / khaali)" : ""));
      return;
   }

   string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);

   // Khali path pe Firebase "null" deta hai
   if(StringFind(json, "null") == 0 || StringLen(json) < 10)
      return;

   ProcessOrder(json);
}

//+------------------------------------------------------------------+
//| REVERSE BRIDGE: band hue FXDiag trades ka result app ko bhejo     |
//+------------------------------------------------------------------+
void TrackAndReportClosures()
{
   // 1. Jo track me the par ab OPEN nahi -> band ho gaye -> report karo
   for(int i = ArraySize(g_trackedTickets) - 1; i >= 0; i--)
   {
      ulong ticket = g_trackedTickets[i];
      if(!PositionSelectByTicket(ticket))
      {
         long   orderId = g_trackedOrderIDs[i];
         double profit  = 0;
         string reason  = "CLOSE";
         if(GetClosedInfo((long)ticket, profit, reason))
            ReportResult(orderId, profit, reason);
         RemoveTrackedAt(i);
      }
   }

   // 2. Naye OPEN FXDiag positions ko tracking me daalo
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "FXDiag_") != 0) continue;   // sirf hamare orders
      long orderId = (long)StringToInteger(StringSubstr(cmt, 7));
      if(orderId <= 0) continue;
      if(!IsTracked(ticket))
         AddTracked(ticket, orderId);
   }
}

bool IsTracked(ulong ticket)
{
   for(int i = 0; i < ArraySize(g_trackedTickets); i++)
      if(g_trackedTickets[i] == ticket) return true;
   return false;
}

void AddTracked(ulong ticket, long orderId)
{
   double risk = 0;
   if(PositionSelectByTicket(ticket))
   {
      double e   = PositionGetDouble(POSITION_PRICE_OPEN);
      double isl = PositionGetDouble(POSITION_SL);
      if(isl > 0) risk = MathAbs(e - isl);
   }
   int n = ArraySize(g_trackedTickets);
   ArrayResize(g_trackedTickets, n + 1);
   ArrayResize(g_trackedOrderIDs, n + 1);
   ArrayResize(g_trackedInitRisk, n + 1);
   g_trackedTickets[n]   = ticket;
   g_trackedOrderIDs[n]  = orderId;
   g_trackedInitRisk[n]  = risk;
   Print("Tracking position ", ticket, " (order ", orderId, ") risk=", DoubleToString(risk, _Digits));
}

void RemoveTrackedAt(int idx)
{
   int n = ArraySize(g_trackedTickets);
   for(int i = idx; i < n - 1; i++)
   {
      g_trackedTickets[i]   = g_trackedTickets[i+1];
      g_trackedOrderIDs[i]  = g_trackedOrderIDs[i+1];
      g_trackedInitRisk[i]  = g_trackedInitRisk[i+1];
   }
   ArrayResize(g_trackedTickets, n - 1);
   ArrayResize(g_trackedOrderIDs, n - 1);
   ArrayResize(g_trackedInitRisk, n - 1);
}

double GetInitRisk(ulong ticket)
{
   for(int i = 0; i < ArraySize(g_trackedTickets); i++)
      if(g_trackedTickets[i] == ticket) return g_trackedInitRisk[i];
   return 0;
}

//| Band position ka realized profit + reason history se nikalo       |
bool GetClosedInfo(long positionId, double &profit, string &reason)
{
   if(!HistorySelectByPosition(positionId))
      return false;
   profit = 0;
   reason = "CLOSE";
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;
      if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                 + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                 + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         long r = HistoryDealGetInteger(dealTicket, DEAL_REASON);
         if(r == DEAL_REASON_TP)      reason = "TP";
         else if(r == DEAL_REASON_SL) reason = "SL";
      }
   }
   return true;
}

//| Result Firebase pe likho:  /fxbridge/results/<orderId>            |
void ReportResult(long orderId, double profit, string reason)
{
   string url = FbUrl("/fxbridge/results/" + IntegerToString(orderId) + ".json");
   string body = "{\"id\":" + IntegerToString(orderId) +
                 ",\"profit\":" + DoubleToString(profit, 2) +
                 ",\"reason\":\"" + reason + "\"" +
                 ",\"time\":" + IntegerToString((long)TimeCurrent()) + "}";

   char post[], result[];
   StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, ArraySize(post) - 1);   // trailing null hatao

   string headers = "Content-Type: application/json\r\n";
   string resultHeaders;
   ResetLastError();
   int res = WebRequest("PUT", url, headers, 5000, post, result, resultHeaders);
   if(res == 200 || res == 204)
   {
      Print("RESULT -> app: ID ", orderId, "  profit=", DoubleToString(profit,2), "  reason=", reason);
      SendReply("Trade closed (" + reason + ")  P/L: " + DoubleToString(profit,2));
   }
   else
   {
      Print("RESULT report FAILED: ID ", orderId, "  HTTP ", res, "  err ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| App se commands padho:  /fxbridge/command  {be, trail}           |
//+------------------------------------------------------------------+
void CheckCommands()
{
   string url = FbUrl("/fxbridge/command.json");
   char   post[], result[];
   string headers = "";
   string resultHeaders;

   ResetLastError();
   int res = WebRequest("GET", url, headers, 5000, post, result, resultHeaders);
   if(res != 200) return;

   string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if(StringFind(json, "null") == 0 || StringLen(json) < 5) return;

   // Trailing on/off (Firebase = source of truth)
   g_trailOn = (StringFind(json, "\"trail\":true") >= 0);

   // Breakeven command: naya timestamp aaya to sabhi trades BE karo
   long be = (long)JsonNumber(json, "be");
   if(be > g_lastBeCommand)
   {
      g_lastBeCommand = be;
      MoveAllToBreakeven();
   }
}

//| Sabhi FXDiag trades ka SL entry pe (breakeven) le jao             |
void MoveAllToBreakeven()
{
   int done = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "FXDiag_") != 0) continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   ptype = PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      int    dig   = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      double buf   = 10 * point;   // chhota spread buffer

      double newSL;
      if(ptype == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(sym, SYMBOL_BID);
         if(bid <= entry + buf) continue;              // profit nahi -> BE nahi
         newSL = NormalizeDouble(entry + buf, dig);
         if(curSL != 0 && curSL >= newSL) continue;    // already better
      }
      else
      {
         double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
         if(ask >= entry - buf) continue;
         newSL = NormalizeDouble(entry - buf, dig);
         if(curSL != 0 && curSL <= newSL) continue;
      }
      if(trade.PositionModify(ticket, newSL, tp)) done++;
   }
   SendReply("Breakeven: " + IntegerToString(done) + " trade(s) SL entry pe");
   Print("Breakeven applied: ", done, " positions");
}

//| Trailing ON ho to har FXDiag trade ka SL profit ke saath khiso    |
void ApplyTrailing()
{
   if(!g_trailOn) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "FXDiag_") != 0) continue;

      double risk = GetInitRisk(ticket);
      if(risk <= 0) continue;   // init risk pata nahi -> skip

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   ptype = PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      int    dig   = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);

      if(ptype == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(sym, SYMBOL_BID);
         if(bid - entry < risk) continue;               // 1R profit ke baad hi trail
         double newSL = NormalizeDouble(bid - risk, dig);
         if(newSL > curSL)                               // sirf aage
            trade.PositionModify(ticket, newSL, tp);
      }
      else
      {
         double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
         if(entry - ask < risk) continue;
         double newSL = NormalizeDouble(ask + risk, dig);
         if(curSL == 0 || newSL < curSL)
            trade.PositionModify(ticket, newSL, tp);
      }
   }
}

//+------------------------------------------------------------------+
//| Market Watch symbols ki spec app ko bhejo (auto SL/TP $)          |
//| /fxbridge/specs = { "EURUSD":{tv,ts,cs}, "XRPUSD":{...}, ... }    |
//+------------------------------------------------------------------+
void SendSymbolSpecs()
{
   int total = SymbolsTotal(true);   // sirf Market Watch wale
   string body = "{";
   int count = 0;
   for(int i = 0; i < total; i++)
   {
      string sym = SymbolName(i, true);
      if(sym == "") continue;
      double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
      if(ts <= 0) continue;
      double tv  = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
      double csz = SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE);
      int    dig = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);

      // base name = app wala naam (map / suffix hata ke)
      string base = BaseOf(sym);

      // Firebase key sanitize: sirf A-Z 0-9 _ allowed (warna HTTP 400)
      bool validKey = (StringLen(base) > 0);
      for(int k = 0; k < StringLen(base); k++)
      {
         ushort ch = StringGetCharacter(base, k);
         bool okc = (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_';
         if(!okc) { validKey = false; break; }
      }
      if(!validKey) continue;   // dot/hash/slash wale symbols skip

      // number safety: NaN/Inf skip
      if(!MathIsValidNumber(tv) || !MathIsValidNumber(ts) || !MathIsValidNumber(csz)) continue;

      if(count > 0) body += ",";
      body += "\"" + base + "\":{\"tv\":" + DoubleToString(tv, 5) +
              ",\"ts\":" + DoubleToString(ts, (dig > 0 ? dig : 6)) +
              ",\"cs\":" + DoubleToString(csz, 2) + "}";
      count++;
   }
   body += "}";
   if(count == 0) return;

   string url = FbUrl("/fxbridge/specs.json");
   char post[], result[];
   StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, ArraySize(post) - 1);   // trailing null hatao
   string headers = "Content-Type: application/json\r\n";
   string resultHeaders;
   ResetLastError();
   int res = WebRequest("PUT", url, headers, 5000, post, result, resultHeaders);
   if(res == 200 || res == 204)
      Print("Specs sent: ", count, " symbols");
   else
      Print("Specs send FAILED: HTTP ", res, "  err ", GetLastError(),
            "  resp: ", CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
}

//+------------------------------------------------------------------+
//| Supertrend direction (1=bull, -1=bear, 0=error) - last CLOSED bar |
//+------------------------------------------------------------------+
int GetSupertrendDir(string sym, ENUM_TIMEFRAMES tf)
{
   int period = 10; double mult = 3.0; int n = 120;
   double H[], L[], C[];
   if(CopyHigh(sym, tf, 0, n, H)  < n) return 0;   // index 0 = oldest
   if(CopyLow(sym, tf, 0, n, L)   < n) return 0;
   if(CopyClose(sym, tf, 0, n, C) < n) return 0;

   double atr[];
   ArrayResize(atr, n);
   ArrayInitialize(atr, 0.0);
   double trsum = 0;
   for(int i = 1; i <= period; i++)
      trsum += MathMax(H[i]-L[i], MathMax(MathAbs(H[i]-C[i-1]), MathAbs(L[i]-C[i-1])));
   atr[period] = trsum / period;
   for(int i = period+1; i < n; i++)
   {
      double tr = MathMax(H[i]-L[i], MathMax(MathAbs(H[i]-C[i-1]), MathAbs(L[i]-C[i-1])));
      atr[i] = (atr[i-1]*(period-1) + tr) / period;
   }

   double pU=0, pL=0, pST=0;
   int dir = -1, resultDir = 0;
   for(int i = period; i < n; i++)
   {
      double hl2 = (H[i]+L[i]) / 2.0;
      double bU = hl2 + mult*atr[i], bL = hl2 - mult*atr[i];
      if(i == period) { pU=bU; pL=bL; pST=bU; dir=-1; continue; }
      double fU = (bU < pU || C[i-1] > pU) ? bU : pU;
      double fL = (bL > pL || C[i-1] < pL) ? bL : pL;
      double st;
      if(pST == pU) st = (C[i] <= fU) ? fU : fL;
      else          st = (C[i] >= fL) ? fL : fU;
      dir = (st == fL) ? 1 : -1;
      pU=fU; pL=fL; pST=st;
      if(i == n-2) resultDir = dir;   // last CLOSED bar (forming bar skip -> no flicker)
   }
   return resultDir;
}

//| Har pair ka trend check karo, flip pe Telegram alert bhejo        |
void CheckSignalFlips()
{
   for(int i = 0; i < ArraySize(g_alertSyms); i++)
   {
      string sym = g_alertSyms[i];
      int dir = GetSupertrendDir(sym, PERIOD_H1);
      if(dir == 0) continue;   // data nahi mila -> skip

      int prev = g_alertDir[i];
      if(prev == 0)             // pehli baar -> sirf init, alert nahi
      {
         g_alertDir[i] = dir;
         continue;
      }
      if(dir != prev)           // FLIP hua!
      {
         g_alertDir[i] = dir;
         string base = BaseOf(sym);
         string newSig = (dir == 1) ? "BUY (Bullish)" : "SELL (Bearish)";
         SendReply("🔔 SIGNAL FLIP\n" + base + " ab " + newSig + "\n(Supertrend H1 palta) " + TimeToString(TimeCurrent(), TIME_MINUTES));
         Print("Signal flip: ", base, " -> ", newSig);
         if(EnablePaperTrades) CreatePaperTrade(sym, base, dir);   // 24/7 auto paper record
      }
   }
}

//+------------------------------------------------------------------+
//| Generic Firebase write (PUT / PATCH)                              |
//+------------------------------------------------------------------+
void FirebaseWrite(string method, string path, string body)
{
   string url = FbUrl(path);
   char post[], result[];
   StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, ArraySize(post) - 1);
   string headers = "Content-Type: application/json\r\n";
   string rh;
   WebRequest(method, url, headers, 5000, post, result, rh);
}

//| Naya paper trade banao (TP $1 / SL $2.5) -> Firebase + tracking   |
void CreatePaperTrade(string sym, string base, int dir)
{
   // us pair pe pehle se paper open ho to skip (duplicate)
   for(int i = 0; i < ArraySize(g_paperPairs); i++)
      if(g_paperPairs[i] == base) return;

   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0) return;
   int    dig  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double lots = (AutoTradeLots > 0) ? AutoTradeLots : 0.01;
   double usdPerUnit = (1.0 / ts) * tv * lots;   // $ per 1.0 price move
   if(usdPerUnit <= 0) return;
   double slDist = 2.5 / usdPerUnit;
   double tpDist = 1.0 / usdPerUnit;

   double entry, sl, tp;
   if(dir == 1)
   {
      entry = SymbolInfoDouble(sym, SYMBOL_ASK);
      sl = NormalizeDouble(entry - slDist, dig);
      tp = NormalizeDouble(entry + tpDist, dig);
   }
   else
   {
      entry = SymbolInfoDouble(sym, SYMBOL_BID);
      sl = NormalizeDouble(entry + slDist, dig);
      tp = NormalizeDouble(entry - tpDist, dig);
   }
   entry = NormalizeDouble(entry, dig);

   long id = (long)TimeCurrent() * 1000 + (g_paperSeq++ % 1000);

   string sig = (dir == 1) ? "BUY" : "SELL";
   string body = "{\"id\":" + IntegerToString(id) +
                 ",\"pair\":\"" + base + "\"" +
                 ",\"signal\":\"" + sig + "\"" +
                 ",\"entry\":" + DoubleToString(entry, dig) +
                 ",\"sl\":" + DoubleToString(sl, dig) +
                 ",\"tp\":" + DoubleToString(tp, dig) +
                 ",\"lots\":" + DoubleToString(lots, 2) +
                 ",\"time\":" + IntegerToString((long)TimeCurrent()) +
                 ",\"result\":null,\"profit\":0}";
   FirebaseWrite("PUT", "/fxbridge/papertrades/" + IntegerToString(id) + ".json", body);

   if(EnableAutoTrade && !g_isReal && EnableTrading)
   {
      // ⚠️ REAL order MT5 pe (demo). Reverse-bridge isko track + result report karega.
      string cmt = "FXDiag_" + IntegerToString(id);
      bool ok = (dir == 1) ? trade.Buy(lots, sym, 0.0, sl, tp, cmt)
                           : trade.Sell(lots, sym, 0.0, sl, tp, cmt);
      Print("AUTO-TRADE ", base, " ", sig, ok ? " placed" : (" FAILED " + IntegerToString(trade.ResultRetcode())));
      SendReply("⚡ AUTO-TRADE " + base + " " + sig + (ok ? " placed (demo test)" : " FAILED"));
      // real trade -> reverse-bridge resolve karega, paper tracking me nahi daalte
   }
   else
   {
      // paper only -> tracking me daalo (CheckPaperResults resolve karega)
      int n = ArraySize(g_paperIds);
      ArrayResize(g_paperIds, n+1);   ArrayResize(g_paperPairs, n+1); ArrayResize(g_paperSyms, n+1);
      ArrayResize(g_paperEntry, n+1); ArrayResize(g_paperSL, n+1);    ArrayResize(g_paperTP, n+1);
      ArrayResize(g_paperDir, n+1);
      g_paperIds[n]=id; g_paperPairs[n]=base; g_paperSyms[n]=sym;
      g_paperEntry[n]=entry; g_paperSL[n]=sl; g_paperTP[n]=tp; g_paperDir[n]=dir;
      Print("Paper trade: ", base, " ", sig, " (TP $1 / SL $2.5)");
   }
}

//| Har paper trade ka TP/SL check karo (24/7) -> hit pe result likho |
void CheckPaperResults()
{
   for(int i = ArraySize(g_paperIds) - 1; i >= 0; i--)
   {
      string sym = g_paperSyms[i];
      int    dir = g_paperDir[i];
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      if(bid <= 0 || ask <= 0) continue;

      string result = ""; double profit = 0;
      if(dir == 1)   // BUY, exit at bid
      {
         if(bid >= g_paperTP[i])      { result = "TP"; profit =  1.0; }
         else if(bid <= g_paperSL[i]) { result = "SL"; profit = -2.5; }
      }
      else           // SELL, exit at ask
      {
         if(ask <= g_paperTP[i])      { result = "TP"; profit =  1.0; }
         else if(ask >= g_paperSL[i]) { result = "SL"; profit = -2.5; }
      }

      if(result != "")
      {
         long id = g_paperIds[i];
         string body = "{\"result\":\"" + result + "\",\"profit\":" + DoubleToString(profit, 2) +
                       ",\"closeTime\":" + IntegerToString((long)TimeCurrent()) + "}";
         FirebaseWrite("PATCH", "/fxbridge/papertrades/" + IntegerToString(id) + ".json", body);
         Print("Paper ", g_paperPairs[i], " -> ", result, " (", DoubleToString(profit, 2), ")");
         RemovePaperAt(i);
      }
   }
}

void RemovePaperAt(int idx)
{
   int n = ArraySize(g_paperIds);
   for(int i = idx; i < n - 1; i++)
   {
      g_paperIds[i]=g_paperIds[i+1]; g_paperPairs[i]=g_paperPairs[i+1]; g_paperSyms[i]=g_paperSyms[i+1];
      g_paperEntry[i]=g_paperEntry[i+1]; g_paperSL[i]=g_paperSL[i+1]; g_paperTP[i]=g_paperTP[i+1];
      g_paperDir[i]=g_paperDir[i+1];
   }
   ArrayResize(g_paperIds, n-1);   ArrayResize(g_paperPairs, n-1); ArrayResize(g_paperSyms, n-1);
   ArrayResize(g_paperEntry, n-1); ArrayResize(g_paperSL, n-1);    ArrayResize(g_paperTP, n-1);
   ArrayResize(g_paperDir, n-1);
}

//+------------------------------------------------------------------+
//| JSON se number nikalo:  "key":123.45                              |
//+------------------------------------------------------------------+
double JsonNumber(string json, string key)
{
   string tag = "\"" + key + "\":";
   int pos = StringFind(json, tag);
   if(pos < 0) return(0);

   int start = pos + StringLen(tag);
   int len = StringLen(json);

   while(start < len && StringGetCharacter(json, start) == ' ') start++;

   int end = start;
   while(end < len)
   {
      ushort c = StringGetCharacter(json, end);
      if((c >= '0' && c <= '9') || c == '.' || c == '-' || c == '+' || c == 'e' || c == 'E')
         end++;
      else
         break;
   }
   if(end <= start) return(0);
   return(StringToDouble(StringSubstr(json, start, end - start)));
}

//+------------------------------------------------------------------+
//| JSON se string nikalo:  "key":"value"                             |
//+------------------------------------------------------------------+
string JsonString(string json, string key)
{
   string tag = "\"" + key + "\":\"";
   int pos = StringFind(json, tag);
   if(pos < 0) return("");

   int start = pos + StringLen(tag);
   int end = StringFind(json, "\"", start);
   if(end <= start) return("");
   return(StringSubstr(json, start, end - start));
}

//+------------------------------------------------------------------+
//| Order parse karke place karo                                      |
//+------------------------------------------------------------------+
void ProcessOrder(string json)
{
   long   orderID = (long)JsonNumber(json, "id");
   string pair    = JsonString(json, "pair");
   string type    = JsonString(json, "type");
   double lots    = JsonNumber(json, "lots");
   double entry   = JsonNumber(json, "entry");
   double sl      = JsonNumber(json, "sl");
   double tp      = JsonNumber(json, "tp");

   if(orderID <= 0 || pair == "" || type == "")
   {
      Print("Invalid JSON: ", json);
      return;
   }

   // Duplicate guard - same order dobara place nahi hoga
   if(orderID <= lastOrderID)
      return;

   // Extra guard - agar is orderID ka order/position MT5 me pehle se hai to skip
   string checkComment = "FXDiag_" + IntegerToString(orderID);
   if(OrderExistsForThisID(checkComment) || PositionExistsForThisID(checkComment))
   {
      Print("Order ID ", orderID, " already exists in MT5 - skip (duplicate)");
      lastOrderID = orderID;
      GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);
      return;
   }

   Print("--- Naya order mila: ID ", orderID, " ---");

   if(entry <= 0 || sl <= 0 || tp <= 0)
   {
      Print("REJECTED: invalid prices  E=", entry, " SL=", sl, " TP=", tp);
      lastOrderID = orderID;
      GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);
      return;
   }

   string symbol = ResolveSymbol(pair);
   if(symbol == "")
   {
      Print("REJECTED: symbol ", pair, " broker pe nahi mila — SymbolMap me daalo (", pair, "=APNA_NAAM)");
      SendReply("REJECTED: symbol " + pair + " nahi mila — EA ke SymbolMap me daalo");
      lastOrderID = orderID;
      GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);
      return;
   }

   // ===== AUTO-ADJUST: symbol ke rules ke hisaab se lot aur price fix karo =====
   int    digits    = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double minLot    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   long   stopsLvl  = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point     = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // --- Lot size adjust: step me round karo, min/max ke andar rakho ---
   double origLots = lots;
   if(lotStep > 0)
      lots = MathRound(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   lots = NormalizeDouble(lots, 2);

   // MaxLots safety (user ka apna cap)
   if(lots > MaxLots)
   {
      Print("REJECTED: adjusted lot ", lots, " > MaxLots ", MaxLots);
      SendReply("REJECTED: lot " + DoubleToString(lots, 2) + " > MaxLots " + DoubleToString(MaxLots, 2) +
                "\n(" + symbol + " ka min lot " + DoubleToString(minLot,2) + " hai - MaxLots badhao)");
      lastOrderID = orderID;
      GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);
      return;
   }

   if(origLots != lots)
      Print("Lot adjusted: ", origLots, " -> ", lots, " (min=", minLot, " step=", lotStep, ")");

   // --- Price adjust: tick size me round karo ---
   if(tickSize > 0)
   {
      entry = MathRound(entry / tickSize) * tickSize;
      sl    = MathRound(sl / tickSize) * tickSize;
      tp    = MathRound(tp / tickSize) * tickSize;
   }
   entry = NormalizeDouble(entry, digits);
   sl    = NormalizeDouble(sl, digits);
   tp    = NormalizeDouble(tp, digits);

   // --- Entry price current market se valid distance pe honi chahiye ---
   // (Buy Limit current se NEECHE, Sell Limit UPAR - warna "invalid price")
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double minStop = (stopsLvl > 0 ? stopsLvl : 10) * point;
   // thoda extra buffer taaki fast-moving pairs (crypto) me bhi valid rahe
   double buffer = MathMax(minStop, (ask - bid) * 3);
   if(buffer <= 0) buffer = 10 * point;

   bool isMarketOrder = (type == "BUYMARKET" || type == "SELLMARKET");

   if(type == "BUYLIMIT")
   {
      // Buy Limit ask se neeche hona chahiye
      if(entry >= ask - buffer)
      {
         entry = NormalizeDouble(ask - buffer, digits);
         Print("BuyLimit entry adjusted below market: ", entry);
      }
   }
   else if(type == "SELLLIMIT")
   {
      // Sell Limit bid se upar hona chahiye
      if(entry <= bid + buffer)
      {
         entry = NormalizeDouble(bid + buffer, digits);
         Print("SellLimit entry adjusted above market: ", entry);
      }
   }
   else if(type == "BUYSTOP")
   {
      if(entry <= ask + buffer)
      {
         entry = NormalizeDouble(ask + buffer, digits);
         Print("BuyStop entry adjusted above market: ", entry);
      }
   }
   else if(type == "SELLSTOP")
   {
      if(entry >= bid - buffer)
      {
         entry = NormalizeDouble(bid - buffer, digits);
         Print("SellStop entry adjusted below market: ", entry);
      }
   }

   // --- Stops level check: SL/TP entry se kaafi door hone chahiye ---
   double minDist = stopsLvl * point;
   // Market order me reference current price hai, limit me entry
   double refPrice = isMarketOrder ? (type == "BUYMARKET" ? ask : bid) : entry;
   if(minDist > 0)
   {
      bool isBuy = (type == "BUYLIMIT" || type == "BUYSTOP" || type == "BUYMARKET");
      // SL refPrice se minDist door
      if(MathAbs(refPrice - sl) < minDist)
      {
         sl = isBuy ? (refPrice - minDist) : (refPrice + minDist);
         sl = NormalizeDouble(sl, digits);
         Print("SL adjusted to respect stops level (", stopsLvl, " points)");
      }
      // TP refPrice se minDist door
      if(MathAbs(tp - refPrice) < minDist)
      {
         tp = isBuy ? (refPrice + minDist) : (refPrice - minDist);
         tp = NormalizeDouble(tp, digits);
         Print("TP adjusted to respect stops level (", stopsLvl, " points)");
      }
   }

   // Mark processed pehle hi (crash pe duplicate na ho)
   lastOrderID = orderID;
   GlobalVariableSet("FXBridge_LastOrderID", (double)lastOrderID);

   if(!TradingOn())
   {
      Print("TEST MODE - would place: ", symbol, " ", type, " ", lots, " @ ", entry, " SL=", sl, " TP=", tp,
            (g_isReal && EnableTrading ? "  (REAL account: ConfirmRealAccount=true karo)" : ""));
      SendReply("TEST MODE (" + (g_isReal && EnableTrading ? "REAL: ConfirmRealAccount=false" : "EnableTrading=false") + ")\n" + symbol + " " + type +
                "\nLots: " + DoubleToString(lots, 2) +
                "\nEntry: " + DoubleToString(entry, digits) +
                "\nSL: " + DoubleToString(sl, digits) +
                "\nTP: " + DoubleToString(tp, digits));
      return;
   }

   datetime expiry = (ExpiryHours > 0) ? TimeCurrent() + ExpiryHours * 3600 : 0;
   ENUM_ORDER_TYPE_TIME timeType = (ExpiryHours > 0) ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC;
   trade.SetTypeFillingBySymbol(symbol);

   string comment = "FXDiag_" + IntegerToString(orderID);
   bool ok = false;
   int rc = 0;

   // SIRF EK BAAR place karo - retry NAHI (retry se duplicate ban jate the)
   if(type == "BUYLIMIT")
      ok = trade.BuyLimit(lots, entry, symbol, sl, tp, timeType, expiry, comment);
   else if(type == "SELLLIMIT")
      ok = trade.SellLimit(lots, entry, symbol, sl, tp, timeType, expiry, comment);
   else if(type == "BUYSTOP")
      ok = trade.BuyStop(lots, entry, symbol, sl, tp, timeType, expiry, comment);
   else if(type == "SELLSTOP")
      ok = trade.SellStop(lots, entry, symbol, sl, tp, timeType, expiry, comment);
   else if(type == "BUYMARKET")
      ok = trade.Buy(lots, symbol, 0.0, sl, tp, comment);
   else if(type == "SELLMARKET")
      ok = trade.Sell(lots, symbol, 0.0, sl, tp, comment);
   else
   {
      Print("Unknown order type: ", type);
      return;
   }

   rc = (int)trade.ResultRetcode();

   // Timeout (10012) aaya - order shayad LAG chuka hai bas confirmation late aaya
   // Retry MAT karo - 2 sec ruk ke check karo ki laga ya nahi
   if(!ok && rc == 10012)
   {
      Print("Timeout aaya - 2s ruk ke check karte hain order laga ya nahi...");
      Sleep(2000);
      if(OrderExistsForThisID(comment) || PositionExistsForThisID(comment))
      {
         Print("Order laga tha (timeout sirf confirmation me tha) - OK");
         ok = true;
      }
      else
      {
         Print("Order sach me nahi laga - user dobara bhej sakta hai");
      }
   }

   if(ok)
   {
      Print("PLACED: ", symbol, " ", type, " ", lots, " @ ", entry, " SL=", sl, " TP=", tp);
      SendReply("PLACED " + symbol + " " + type +
                "\nLots: " + DoubleToString(lots, 2) +
                "\nEntry: " + DoubleToString(entry, digits) +
                "\nSL: " + DoubleToString(sl, digits) +
                "\nTP: " + DoubleToString(tp, digits));
   }
   else
   {
      Print("FAILED after retries: ", symbol, " retcode=", rc, " - ", trade.ResultRetcodeDescription());
      SendReply("FAILED " + symbol + " " + type +
                "\nError " + IntegerToString(rc) + ": " + trade.ResultRetcodeDescription() +
                (rc == 10012 ? "\n(Timeout - VPS internet ya broker slow hai)" : ""));
   }
}

//+------------------------------------------------------------------+
//| Telegram pe confirmation (ye direction kaam karta hai)            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Is comment ka pending order pehle se hai?                         |
//+------------------------------------------------------------------+
bool OrderExistsForThisID(string comment)
{
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_COMMENT) == comment)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Is comment ki position pehle se hai?                             |
//+------------------------------------------------------------------+
bool PositionExistsForThisID(string comment)
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_COMMENT) == comment)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void SendReply(string text)
{
   if(StringLen(TgBotToken) < 10 || StringLen(TgChatID) < 3) return;

   string url = "https://api.telegram.org/bot" + TgBotToken + "/sendMessage";
   string body = "chat_id=" + TgChatID + "&text=" + UrlEncode("🤖 ForexDiagnosis\n" + text);

   char post[], result[];
   StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, ArraySize(post) - 1);

   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   string resultHeaders;
   ResetLastError();
   int res = WebRequest("POST", url, headers, 5000, post, result, resultHeaders);
   if(res == 200)
      Print("Telegram OK");
   else
      Print("Telegram FAILED: HTTP ", res, " err ", GetLastError(),
            " resp ", CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
}

//+------------------------------------------------------------------+
string UrlEncode(string text)
{
   uchar bytes[];
   int n = StringToCharArray(text, bytes, 0, WHOLE_ARRAY, CP_UTF8);  // UTF-8 bytes (+ null)
   string result = "";
   for(int i = 0; i < n - 1; i++)   // -1 = null terminator skip
   {
      uchar b = bytes[i];
      if((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
         (b >= '0' && b <= '9') || b == '-' || b == '_' || b == '.' || b == '~')
         result += CharToString(b);
      else if(b == ' ')
         result += "+";
      else
         result += StringFormat("%%%02X", b);   // har byte alag encode
   }
   return result;
}
//+------------------------------------------------------------------+
