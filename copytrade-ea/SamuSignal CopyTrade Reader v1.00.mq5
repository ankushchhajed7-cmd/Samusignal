//+------------------------------------------------------------------+
//|  SamuSignal CopyTrade Reader v1.00                                |
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
//  CHANGELOG
//   v1.00  (27-Sep-2026)  Pehla build — positions snapshot, heartbeat,
//                         atomic write (tmp -> move), chart panel.
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "SamuSignal CopyTrade — SOURCE (investor) account ke trades padh kar Common folder me likhta hai. Trade nahi karta."

input int InpIntervalMs = 200;   // Kitni der me padhe (ms) — 100 se 1000

const string CP_FOLDER = "SamuCopy";
const string F_MASTER  = "SamuCopy\\master.txt";
const string F_TMP     = "SamuCopy\\master.tmp";

long     g_seq       = 0;
int      g_moveFail  = 0;
uint     g_lastPanel = 0;
int      g_lastCount = 0;

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
   Print("SamuCopy Reader v1.00 chalu. File: ",
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

   // H|seq|localTime|login|server|serverTime|balance|equity|connected|tradeAllowed|count
   string head = "H|" + IntegerToString(g_seq) +
                 "|" + IntegerToString((long)TimeLocal()) +
                 "|" + IntegerToString(login) +
                 "|" + server +
                 "|" + IntegerToString((long)TimeCurrent()) +
                 "|" + Num(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
                 "|" + Num(AccountInfoDouble(ACCOUNT_EQUITY), 2) +
                 "|" + (conn ? "1" : "0") +
                 "|" + (canTr ? "1" : "0") +
                 "|" + IntegerToString(cnt) + "\r\n";
   string tail = "E|" + IntegerToString(cnt) + "|" + IntegerToString(g_seq) + "\r\n";

   int h = FileOpen(F_TMP, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE) return;
   FileWriteString(h, head + body + tail);
   FileClose(h);

   // tmp -> master (poori file ek saath badalti hai, aadhi-adhuri kabhi nahi padhi jaati)
   if(!FileMove(F_TMP, FILE_COMMON, F_MASTER, FILE_COMMON | FILE_REWRITE))
      g_moveFail++;          // Executor us waqt padh raha tha — agli baar ho jayega
   else
      g_moveFail = 0;

   g_lastCount = cnt;
   if(GetTickCount() - g_lastPanel > 1000)
     {
      g_lastPanel = GetTickCount();
      Panel(login, server, conn, canTr);
     }
  }

//+------------------------------------------------------------------+
void Panel(const long login, const string server, const bool conn, const bool canTr)
  {
   string s = "SamuSignal CopyTrade — READER v1.00\n";
   s += "Source: " + IntegerToString(login) + " @ " + server + "\n";
   s += "Connection: " + (conn ? "OK" : "NAHI — login/internet check karo") + "\n";
   s += "Mode: " + (canTr ? "MASTER password (trade allowed) — investor bhi chalega"
                          : "INVESTOR (read-only) — sahi hai") + "\n";
   s += "Open positions: " + IntegerToString(g_lastCount) + "\n";
   s += "Snapshot #" + IntegerToString(g_seq) +
        (g_moveFail > 20 ? "  (file likhne me dikkat!)" : "  (file OK)") + "\n";
   s += "Is terminal me trade NAHI hota. Copy dusre terminal ka Executor karta hai.";
   Comment(s);
  }
//+------------------------------------------------------------------+
