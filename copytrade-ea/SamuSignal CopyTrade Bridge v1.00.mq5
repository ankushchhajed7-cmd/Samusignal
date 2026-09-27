//+------------------------------------------------------------------+
//|  SamuSignal CopyTrade Bridge v1.00                                |
//|  Ankush New Vision                                                |
//+------------------------------------------------------------------+
//  KAAM:
//   SamuSignal app <-> VPS ka pul. Har 2 sec:
//    1. Firebase  /copytrade/config.json  ->  <Common>\Files\SamuCopy\config.json
//       (app ke COPY tab ki settings, Executor yahan se padhta hai)
//    2. <Common>\Files\SamuCopy\status.json  ->  Firebase /copytrade/status.json
//       (Executor ka status, app pe live dikhta hai)
//   Trade ka koi kaam nahi karta. Internet ka saara kaam isi me hai taaki
//   Executor ki copy kabhi internet ki wajah se slow na ho.
//
//  SETUP: MT5 -> Tools -> Options -> Expert Advisors ->
//         "Allow WebRequest for listed URL" me apna Firebase URL daalo
//         (jaise https://xxx-default-rtdb.firebaseio.com)
//
//  CHANGELOG
//   v1.00  (27-Sep-2026)  Pehla build — config pull, status push,
//                         bridge heartbeat (br), clear error panel.
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "SamuSignal CopyTrade — app (Firebase) aur Executor EA ke beech settings/status pahunchata hai. Trade nahi karta."

input string InpFirebaseURL  = "https://xxx-default-rtdb.firebaseio.com"; // Firebase URL (SamuSignal Settings wala)
input string InpFirebaseAuth = "";   // Firebase auth/secret (app me daala ho to)
input int    InpPollSec      = 2;    // Kitni der me sync (sec)

const string CP_FOLDER = "SamuCopy";
const string F_CONFIG  = "SamuCopy\\config.json";
const string F_CFGTMP  = "SamuCopy\\config.tmp";
const string F_STATUS  = "SamuCopy\\status.json";

string g_base = "";
string g_lastCfg = "";
string g_err = "";
int    g_okPull = 0, g_okPush = 0, g_fail = 0;
datetime g_lastOk = 0;

//+------------------------------------------------------------------+
string Trim(string s) { StringTrimLeft(s); StringTrimRight(s); return s; }

string Url(const string path)
  {
   string u = g_base + path + ".json";
   if(InpFirebaseAuth != "") u += "?auth=" + InpFirebaseAuth;
   return u;
  }

//--- WebRequest wrapper: code lautata hai, body me jawab
int Http(const string method, const string url, const string body, string &resp)
  {
   char data[], res[];   // WebRequest char[] maangta hai
   string rh;
   string hdr = "Content-Type: application/json\r\n";
   if(body != "")
     {
      int n = StringToCharArray(body, data, 0, -1, CP_UTF8);
      if(n > 0) ArrayResize(data, n - 1);
     }
   ResetLastError();
   int code = WebRequest(method, url, hdr, 4000, data, res, rh);
   resp = (ArraySize(res) > 0) ? CharArrayToString(res, 0, ArraySize(res), CP_UTF8) : "";
   if(code == -1)
     {
      int e = GetLastError();
      if(e == 4014) g_err = "WebRequest allowed nahi — Tools > Options > Expert Advisors me URL daalo: " + g_base;
      else          g_err = "Internet/URL error " + IntegerToString(e);
     }
   return code;
  }

bool ReadFileText(const string name, string &out)
  {
   out = "";
   if(!FileIsExist(name, FILE_COMMON)) return false;
   int h = FileOpen(name, FILE_READ | FILE_BIN | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE) return false;
   int sz = (int)FileSize(h);
   uchar buf[];
   if(sz > 0)
     {
      ArrayResize(buf, sz);
      FileReadArray(h, buf, 0, sz);
      out = CharArrayToString(buf, 0, sz, CP_UTF8);
     }
   FileClose(h);
   return true;
  }

bool WriteFileText(const string tmp, const string name, const string text)
  {
   uchar buf[];
   int n = StringToCharArray(text, buf, 0, -1, CP_UTF8);
   if(n > 0) ArrayResize(buf, n - 1);
   int h = FileOpen(tmp, FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(h == INVALID_HANDLE) return false;
   FileWriteArray(h, buf);
   FileClose(h);
   return FileMove(tmp, FILE_COMMON, name, FILE_COMMON | FILE_REWRITE);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   g_base = Trim(InpFirebaseURL);
   while(StringLen(g_base) > 0 && StringGetCharacter(g_base, StringLen(g_base) - 1) == '/')
      g_base = StringSubstr(g_base, 0, StringLen(g_base) - 1);
   if(StringFind(g_base, "http") != 0) g_base = "https://" + g_base;
   if(StringFind(g_base, "xxx-default") >= 0)
     {
      Alert("SamuCopy Bridge: Firebase URL input me apna asli URL daalo");
      return(INIT_PARAMETERS_INCORRECT);
     }
   FolderCreate(CP_FOLDER, FILE_COMMON);
   int sec = InpPollSec < 1 ? 1 : InpPollSec;
   EventSetTimer(sec);
   Print("SamuCopy Bridge v1.00 chalu: ", g_base);
   OnTimer();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { EventKillTimer(); Comment(""); }
void OnTick() { }

//+------------------------------------------------------------------+
void OnTimer()
  {
   g_err = "";
   bool ok = true;

   //--- 1. app settings neeche lao
   string resp;
   int code = Http("GET", Url("/copytrade/config"), "", resp);
   if(code == 200)
     {
      resp = Trim(resp);
      if(resp != "null" && StringLen(resp) > 2 && resp != g_lastCfg)
        {
         if(WriteFileText(F_CFGTMP, F_CONFIG, resp))
           {
            g_lastCfg = resp;
            Print("SamuCopy Bridge: nayi settings aayi");
           }
        }
      g_okPull++;
     }
   else
     {
      ok = false;
      if(g_err == "") g_err = "Settings GET code " + IntegerToString(code) + (code == 401 ? " (auth galat)" : "");
     }

   //--- 2. status upar bhejo (br = bridge ki dhadkan)
   string st;
   string br = "\"br\":" + IntegerToString((long)TimeGMT());
   if(ReadFileText(F_STATUS, st) && StringLen(st) > 2 && StringGetCharacter(st, 0) == '{')
      st = "{" + br + "," + StringSubstr(st, 1);
   else
      st = "{" + br + ",\"at\":0,\"noExec\":true}";
   code = Http("PUT", Url("/copytrade/status"), st, resp);
   if(code == 200) g_okPush++;
   else
     {
      ok = false;
      if(g_err == "") g_err = "Status PUT code " + IntegerToString(code);
     }

   if(ok) { g_lastOk = TimeLocal(); g_fail = 0; }
   else g_fail++;

   string s = "SamuSignal CopyTrade — BRIDGE v1.00\n";
   s += "Firebase: " + g_base + "\n";
   s += "Status: " + (ok ? "OK" : "DIKKAT") + "   pull " + IntegerToString(g_okPull) + " / push " + IntegerToString(g_okPush) + "\n";
   if(g_lastOk > 0) s += "Aakhri OK: " + TimeToString(g_lastOk, TIME_SECONDS) + "\n";
   if(g_err != "") s += "! " + g_err + "\n";
   s += "Trade NAHI karta — sirf app <-> Executor settings/status.";
   Comment(s);
   if(g_fail == 5) Print("SamuCopy Bridge: ", g_err);
  }
//+------------------------------------------------------------------+
