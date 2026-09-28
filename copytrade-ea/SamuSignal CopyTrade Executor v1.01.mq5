//+------------------------------------------------------------------+
//|  SamuSignal CopyTrade Executor v1.01                              |
//|  Ankush New Vision                                                |
//+------------------------------------------------------------------+
//  KAAM:
//   Ye EA APNE account (master password) wale MT5 terminal me lagta hai.
//   Reader EA jo file likhta hai (<Common>\Files\SamuCopy\master.txt)
//   usko padh kar wahi trades is account pe kholta / SL-TP badalta /
//   band karta hai. Internet ka koi kaam isme nahi — sab local file se,
//   isliye copy turant hoti hai.
//
//   Settings SamuSignal app ke COPY tab se aati hain (Bridge EA unhe
//   Firebase se <Common>\Files\SamuCopy\config.json me rakhta hai).
//   Status bhi yahi EA status.json me likhta hai, Bridge usko app tak
//   bhejta hai.
//
//  SURAKSHA NIYAM:
//   * Source ka data 6 sec se purana ho / source disconnected ho
//     -> kuch nahi karta (na khole, na band kare).
//   * Source account ka login badal jaye -> purane copied trades ko
//     khud band nahi karta, sirf warning deta hai.
//   * Apne account pe copied trade SL/TP/manual se band ho jaye ->
//     wo source trade dobara copy NAHI hota.
//   * Copy OFF -> naye trade nahi khulte, par pehle se copied trades
//     ka SL/TP aur close sync chalta rehta hai.
//   * Source trade band dikhne ke baad 3 alag snapshots me confirm
//     hone par hi yahan band hota hai (galti se close nahi).
//
//  CHANGELOG
//   v1.01  (28-Sep-2026)  Source ke pending orders (Reader v1.01 ki "O|" lines)
//                         padh kar status.json me "pend" list — app me dikhte
//                         hain. Pending copy NAHI hote; trigger ho kar position
//                         bante hi copy hote hain (pehle jaisa). Reader v1.00
//                         ki purani file bhi chalti hai.
//   v1.00  (27-Sep-2026)  Pehla build — open/close/partial/SL-TP sync,
//                         4 lot modes, reverse, symbol mapping + auto
//                         suffix, purane trades skip, price-deviation
//                         guard, max positions, copy-loss $ limit,
//                         CLOSEALL / RESETDD commands, restart-safe
//                         state file, status.json for app.
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.01"
#property description "SamuSignal CopyTrade — Reader ki file se trades apne account pe copy karta hai. Settings SamuSignal app ke COPY tab se."

#include <Trade\Trade.mqh>

enum ENUM_CP_LOT
  {
   CP_LOT_SAME  = 0,   // Same lot jitna source
   CP_LOT_MULT  = 1,   // Source lot x Multiplier
   CP_LOT_FIXED = 2,   // Fixed lot har trade
   CP_LOT_RATIO = 3    // Balance ke hisaab se (x Multiplier)
  };

input group "=== Basic ==="
input long   InpMagic        = 770077;  // Copied trades ka magic number
input int    InpTimerMs      = 250;     // Kitni der me check kare (ms)
input int    InpStaleSec     = 6;       // Source data kitna purana chalega (sec)
input int    InpSlippagePts  = 100;     // Max slippage (points)
input bool   InpUseAppConfig = true;    // true = settings SamuSignal app se

input group "=== Sirf tab jab UseAppConfig = false ==="
input bool        InpCopyOn   = false;        // Copy ON
input ENUM_CP_LOT InpLotMode  = CP_LOT_SAME;  // Lot mode
input double      InpMult     = 1.0;          // Multiplier
input double      InpFixLot   = 0.01;         // Fixed lot
input double      InpMaxLot   = 1.0;          // Ek trade ka max lot
input bool        InpReverse  = false;        // Ulta copy (BUY->SELL)
input bool        InpCopySLTP = true;         // SL/TP bhi copy
input bool        InpCopyOld  = false;        // ON karte waqt khule purane trades bhi copy
input double      InpMaxDev   = 0;            // Max price farak (price me, 0=off)
input int         InpMaxPos   = 50;           // Max copied positions
input double      InpDDUsd    = 0;            // Copy loss limit $ (0=off)
input bool        InpDDClose  = false;        // Limit pe sab copied band
input string      InpSymMap   = "";           // Symbol map: XAUUSD+=XAUUSDm;EURUSD+=EURUSDm
input string      InpSuffix   = "";           // Mere broker ka suffix (m, .sc ...)
input long        InpSrcLogin = 0;            // Source login check (0 = koi bhi)

//---------------------------------------------------------------------
const string CP_FOLDER = "SamuCopy";
const string F_MASTER  = "SamuCopy\\master.txt";
const string F_CONFIG  = "SamuCopy\\config.json";
const string F_STATUS  = "SamuCopy\\status.json";
const string F_STTMP   = "SamuCopy\\status.tmp";
const string EA_VER    = "1.01";

CTrade trade;

//--- config
bool   cOn = false, cReverse = false, cSLTP = true, cOld = false, cDDClose = false;
int    cLotMode = 0, cMaxPos = 50;
double cMult = 1.0, cFix = 0.01, cMaxLot = 1.0, cMaxDev = 0, cDDUsd = 0, cCmdId = 0;
long   cSrcLogin = 0;
string cSymMap = "", cSuffix = "", cCmd = "";
bool   cLoaded = false;
long   cfgAt = 0;
string cfgRawLast = "";

//--- source header
long   hSeq = 0, hLocal = 0, hLogin = 0, hSrv = 0;
string hServer = "";
double hBal = 0, hEq = 0;
bool   hConn = false, hTrade = false, hOk = false;

//--- source positions
struct SrcPos
  {
   ulong  tk;
   string sym;
   int    type;
   double vol;
   double open;
   double sl;
   double tp;
   long   time;
   long   magic;
   double pl;
  };
SrcPos SP[];
int    SPn = 0;

//--- source pending orders (sirf dikhane ke liye)
struct PendO
  {
   ulong  tk;
   string sym;
   int    type;
   double vol;
   double price;
   double sl;
   double tp;
   long   exp;
  };
PendO  PO[];
int    POn = 0;

//--- map: source ticket -> meri position
struct MapE
  {
   ulong  src;
   ulong  dst;
   double srcVol0;
   double dstVol0;
   string dsym;
   int    miss;
   uint   lastMod;
  };
MapE   MP[];
int    MPn = 0;
long   mapLogin = 0;

//--- skip list (ye source tickets kabhi copy nahi honge)
ulong  SKt[];
string SKw[];
int    SKn = 0;

//--- fail retry
ulong  FLt[];
int    FLc[];
uint   FLa[];
int    FLn = 0;

//--- symbol cache
string SCs[];
string SCd[];
int    SCn = 0;

//--- misc
bool   ddTrip = false;
long   startSrv = 0;
long   lastSeqEval = 0;
uint   lastCfgRead = 0, lastStatus = 0, lastPanel = 0;
string warnMsg = "";
string LOG[];
int    LOGn = 0;
double lastCmdDone = 0;
long   myLogin = 0;
bool   prevOn = false;

//+------------------------------------------------------------------+
//| LOG                                                              |
//+------------------------------------------------------------------+
void Log(const string m)
  {
   string line = TimeToString(TimeLocal(), TIME_SECONDS) + " " + m;
   Print("SamuCopy: ", m);
   if(LOGn < 25)
     {
      ArrayResize(LOG, LOGn + 1);
      LOG[LOGn] = line;
      LOGn++;
     }
   else
     {
      for(int i = 1; i < LOGn; i++) LOG[i - 1] = LOG[i];
      LOG[LOGn - 1] = line;
     }
  }

//+------------------------------------------------------------------+
//| helpers                                                          |
//+------------------------------------------------------------------+
string Trim(string s)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
  }

string Upper(string s)
  {
   StringToUpper(s);
   return s;
  }

string GVName(const string what) { return "SamuCopy_" + what + "_" + IntegerToString(myLogin); }

string JEsc(string s)
  {
   StringReplace(s, "\\", "\\\\");
   StringReplace(s, "\"", "\\\"");
   StringReplace(s, "\r", " ");
   StringReplace(s, "\n", " ");
   return s;
  }

//--- flat JSON se ek value nikalo ("" = nahi mili)
string JRaw(const string &js, const string key, bool &found)
  {
   found = false;
   string pat = "\"" + key + "\":";
   int p = StringFind(js, pat);
   if(p < 0) return "";
   found = true;
   int len = StringLen(js);
   p += StringLen(pat);
   while(p < len && StringGetCharacter(js, p) == ' ') p++;
   if(p >= len) return "";
   if(StringGetCharacter(js, p) == '"')
     {
      string out = "";
      p++;
      while(p < len)
        {
         ushort c = StringGetCharacter(js, p);
         if(c == '\\' && p + 1 < len)
           {
            ushort n = StringGetCharacter(js, p + 1);
            if(n == 'n') out += "\n";
            else if(n == 't') out += " ";
            else out += ShortToString(n);
            p += 2;
            continue;
           }
         if(c == '"') break;
         out += ShortToString(c);
         p++;
        }
      return out;
     }
   int e = p;
   while(e < len)
     {
      ushort c = StringGetCharacter(js, e);
      if(c == ',' || c == '}' || c == ']') break;
      e++;
     }
   return Trim(StringSubstr(js, p, e - p));
  }

bool JBool(const string &js, const string key, const bool def)
  {
   bool f;
   string r = JRaw(js, key, f);
   if(!f) return def;
   if(r == "true" || r == "1") return true;
   if(r == "false" || r == "0") return false;
   return def;
  }

double JNum(const string &js, const string key, const double def)
  {
   bool f;
   string r = JRaw(js, key, f);
   if(!f || r == "" || r == "null") return def;
   return StringToDouble(r);
  }

string JStr(const string &js, const string key, const string def)
  {
   bool f;
   string r = JRaw(js, key, f);
   if(!f || r == "null") return def;
   return r;
  }

//--- file ko UTF-8 text ki tarah padho
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
   if(n > 0) ArrayResize(buf, n - 1);          // aakhri \0 hatao
   int h = FileOpen(tmp, FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(h == INVALID_HANDLE) return false;
   FileWriteArray(h, buf);
   FileClose(h);
   return FileMove(tmp, FILE_COMMON, name, FILE_COMMON | FILE_REWRITE);
  }

//+------------------------------------------------------------------+
//| CONFIG                                                           |
//+------------------------------------------------------------------+
void InputsToCfg()
  {
   cOn = InpCopyOn; cLotMode = (int)InpLotMode; cMult = InpMult; cFix = InpFixLot;
   cMaxLot = InpMaxLot; cReverse = InpReverse; cSLTP = InpCopySLTP; cOld = InpCopyOld;
   cMaxDev = InpMaxDev; cMaxPos = InpMaxPos; cDDUsd = InpDDUsd; cDDClose = InpDDClose;
   if(cSymMap != InpSymMap || cSuffix != InpSuffix) SCn = 0;
   cSymMap = InpSymMap; cSuffix = InpSuffix; cSrcLogin = InpSrcLogin;
   cLoaded = true;
  }

void ReadConfig()
  {
   string js;
   if(!ReadFileText(F_CONFIG, js)) return;
   if(StringLen(js) < 2 || js == cfgRawLast) return;
   cfgRawLast = js;

   cOn      = JBool(js, "on", false);
   string lm = Upper(JStr(js, "lotMode", "SAME"));
   cLotMode = (lm == "MULT" ? CP_LOT_MULT : lm == "FIXED" ? CP_LOT_FIXED : lm == "RATIO" ? CP_LOT_RATIO : CP_LOT_SAME);
   cMult    = JNum(js, "mult", 1.0);    if(cMult <= 0) cMult = 1.0;
   cFix     = JNum(js, "fixLot", 0.01); if(cFix <= 0) cFix = 0.01;
   cMaxLot  = JNum(js, "maxLot", 1.0);  if(cMaxLot <= 0) cMaxLot = 1.0;
   cReverse = JBool(js, "reverse", false);
   cSLTP    = JBool(js, "sltp", true);
   cOld     = JBool(js, "copyOld", false);
   cMaxDev  = JNum(js, "maxDev", 0);
   cMaxPos  = (int)JNum(js, "maxPos", 50); if(cMaxPos <= 0) cMaxPos = 50;
   cDDUsd   = MathAbs(JNum(js, "ddUsd", 0));
   cDDClose = JBool(js, "ddClose", false);
   string sm = JStr(js, "symMap", "");
   string sf = Trim(JStr(js, "suffix", ""));
   if(sm != cSymMap || sf != cSuffix) SCn = 0;     // mapping badla -> cache saaf
   cSymMap  = sm;
   cSuffix  = sf;
   cSrcLogin = (long)StringToInteger(JStr(js, "srcLogin", "0"));
   cCmd     = Upper(JStr(js, "cmd", ""));
   cCmdId   = JNum(js, "cmdId", 0);
   cfgAt    = (long)JNum(js, "at", 0);
   if(!cLoaded) Log("App settings mili — copy " + (cOn ? "ON" : "OFF"));
   cLoaded  = true;
  }

//+------------------------------------------------------------------+
//| MASTER FILE (Reader ka snapshot)                                 |
//+------------------------------------------------------------------+
bool ReadMaster()
  {
   if(!FileIsExist(F_MASTER, FILE_COMMON)) return false;
   int h = FileOpen(F_MASTER, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE) return false;        // Reader likh raha hai — agli baar

   string lines[];
   int nl = 0;
   while(!FileIsEnding(h))
     {
      string ln = FileReadString(h);
      if(StringLen(ln) == 0) continue;
      ArrayResize(lines, nl + 1);
      lines[nl] = ln;
      nl++;
     }
   FileClose(h);
   if(nl < 2) return false;

   string f[];
   if(StringSplit(lines[0], '|', f) < 11 || f[0] != "H") return false;
   string t[];
   if(StringSplit(lines[nl - 1], '|', t) < 3 || t[0] != "E") return false;
   int cnt  = (int)StringToInteger(f[10]);
   int pcnt = (ArraySize(f) >= 12) ? (int)StringToInteger(f[11]) : 0;   // Reader v1.00 me ye field nahi
   if((int)StringToInteger(t[1]) != cnt || t[2] != f[1]) return false;   // adhuri file
   if(nl - 2 != cnt + pcnt) return false;

   // header OK -> ab bharo
   hSeq    = (long)StringToInteger(f[1]);
   hLocal  = (long)StringToInteger(f[2]);
   hLogin  = (long)StringToInteger(f[3]);
   hServer = f[4];
   hSrv    = (long)StringToInteger(f[5]);
   hBal    = StringToDouble(f[6]);
   hEq     = StringToDouble(f[7]);
   hConn   = (f[8] == "1");
   hTrade  = (f[9] == "1");

   ArrayResize(SP, cnt);
   ArrayResize(PO, pcnt);
   SPn = 0;
   POn = 0;
   for(int i = 1; i < nl - 1; i++)
     {
      string p[];
      int np = StringSplit(lines[i], '|', p);
      if(np >= 11 && p[0] == "P" && SPn < cnt)
        {
         SP[SPn].tk    = (ulong)StringToInteger(p[1]);
         SP[SPn].sym   = p[2];
         SP[SPn].type  = (int)StringToInteger(p[3]);
         SP[SPn].vol   = StringToDouble(p[4]);
         SP[SPn].open  = StringToDouble(p[5]);
         SP[SPn].sl    = StringToDouble(p[6]);
         SP[SPn].tp    = StringToDouble(p[7]);
         SP[SPn].time  = (long)StringToInteger(p[8]);
         SP[SPn].magic = (long)StringToInteger(p[9]);
         SP[SPn].pl    = StringToDouble(p[10]);
         SPn++;
        }
      else if(np >= 11 && p[0] == "O" && POn < pcnt)
        {
         PO[POn].tk    = (ulong)StringToInteger(p[1]);
         PO[POn].sym   = p[2];
         PO[POn].type  = (int)StringToInteger(p[3]);
         PO[POn].vol   = StringToDouble(p[4]);
         PO[POn].price = StringToDouble(p[5]);
         PO[POn].sl    = StringToDouble(p[6]);
         PO[POn].tp    = StringToDouble(p[7]);
         PO[POn].exp   = (long)StringToInteger(p[10]);
         POn++;
        }
     }
   hOk = true;
   return true;
  }

bool SourceFresh()
  {
   if(!hOk) return false;
   if((long)TimeLocal() - hLocal > InpStaleSec) return false;
   return hConn;
  }

int FindSrc(const ulong tk)
  {
   for(int i = 0; i < SPn; i++) if(SP[i].tk == tk) return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| MAP / SKIP / FAIL lists                                          |
//+------------------------------------------------------------------+
int FindMap(const ulong src)
  {
   for(int i = 0; i < MPn; i++) if(MP[i].src == src) return i;
   return -1;
  }

void AddMap(const ulong src, const ulong dst, const double sv, const double dv, const string dsym)
  {
   ArrayResize(MP, MPn + 1);
   MP[MPn].src = src; MP[MPn].dst = dst; MP[MPn].srcVol0 = sv; MP[MPn].dstVol0 = dv;
   MP[MPn].dsym = dsym; MP[MPn].miss = 0; MP[MPn].lastMod = 0;
   MPn++;
  }

void DelMap(const int idx)
  {
   for(int i = idx + 1; i < MPn; i++)
     {
      MP[i - 1].src = MP[i].src; MP[i - 1].dst = MP[i].dst;
      MP[i - 1].srcVol0 = MP[i].srcVol0; MP[i - 1].dstVol0 = MP[i].dstVol0;
      MP[i - 1].dsym = MP[i].dsym; MP[i - 1].miss = MP[i].miss; MP[i - 1].lastMod = MP[i].lastMod;
     }
   MPn--;
   ArrayResize(MP, MPn);
  }

int FindSkip(const ulong src)
  {
   for(int i = 0; i < SKn; i++) if(SKt[i] == src) return i;
   return -1;
  }

void AddSkip(const ulong src, const string why)
  {
   if(FindSkip(src) >= 0) return;
   ArrayResize(SKt, SKn + 1);
   ArrayResize(SKw, SKn + 1);
   SKt[SKn] = src; SKw[SKn] = why;
   SKn++;
  }

//--- purane skip hatao jinka source trade ab band ho chuka (list chhoti rahe)
void PruneSkip()
  {
   if(SKn < 200 || !SourceFresh()) return;   // chhoti list ko chhedo mat (reconnect glitch se dobara copy na ho)
   int w = 0;
   for(int i = 0; i < SKn; i++)
     {
      if(FindSrc(SKt[i]) < 0) continue;
      SKt[w] = SKt[i]; SKw[w] = SKw[i]; w++;
     }
   if(w != SKn)
     {
      SKn = w;
      ArrayResize(SKt, SKn);
      ArrayResize(SKw, SKn);
      SaveState();
     }
  }

int FindFail(const ulong src)
  {
   for(int i = 0; i < FLn; i++) if(FLt[i] == src) return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| STATE FILE (restart ke baad bhi yaad rahe)                       |
//+------------------------------------------------------------------+
string StateFile() { return "SamuCopy_state_" + IntegerToString(myLogin) + ".csv"; }

void SaveState()
  {
   int h = FileOpen(StateFile(), FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return;
   FileWriteString(h, "L|" + IntegerToString(mapLogin) + "\r\n");
   for(int i = 0; i < MPn; i++)
      FileWriteString(h, "M|" + IntegerToString((long)MP[i].src) + "|" + IntegerToString((long)MP[i].dst) + "|" +
                      DoubleToString(MP[i].srcVol0, 3) + "|" + DoubleToString(MP[i].dstVol0, 3) + "|" + MP[i].dsym + "\r\n");
   for(int i = 0; i < SKn; i++)
      FileWriteString(h, "S|" + IntegerToString((long)SKt[i]) + "|" + SKw[i] + "\r\n");
   FileClose(h);
  }

void LoadState()
  {
   MPn = 0; SKn = 0;
   ArrayResize(MP, 0); ArrayResize(SKt, 0); ArrayResize(SKw, 0);
   if(!FileIsExist(StateFile())) return;
   int h = FileOpen(StateFile(), FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return;
   while(!FileIsEnding(h))
     {
      string ln = FileReadString(h);
      string p[];
      int n = StringSplit(ln, '|', p);
      if(n >= 2 && p[0] == "L") mapLogin = (long)StringToInteger(p[1]);
      else if(n >= 6 && p[0] == "M")
        {
         ulong dst = (ulong)StringToInteger(p[2]);
         if(PositionSelectByTicket(dst))
            AddMap((ulong)StringToInteger(p[1]), dst, StringToDouble(p[3]), StringToDouble(p[4]), p[5]);
        }
      else if(n >= 3 && p[0] == "S") AddSkip((ulong)StringToInteger(p[1]), p[2]);
     }
   FileClose(h);
  }

//--- state file me na ho par comment "CP#..." wali position mile to wapas jodo
void RecoverByComment()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      string cm = PositionGetString(POSITION_COMMENT);
      if(StringFind(cm, "CP#") != 0) continue;
      ulong src = (ulong)StringToInteger(StringSubstr(cm, 3));
      if(src == 0 || FindMap(src) >= 0) continue;
      bool known = false;
      for(int k = 0; k < MPn; k++) if(MP[k].dst == tk) known = true;
      if(known) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
      AddMap(src, tk, 0, v, PositionGetString(POSITION_SYMBOL));
      Log("Purana copied trade wapas joda: #" + IntegerToString((long)tk) + " <- source #" + IntegerToString((long)src));
     }
  }

ulong FindDstByComment(const ulong src)
  {
   string want = "CP#" + IntegerToString((long)src);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_COMMENT) == want) return tk;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| SYMBOL MAPPING                                                   |
//+------------------------------------------------------------------+
bool SymOK(const string s)
  {
   if(s == "") return false;
   return SymbolSelect(s, true);
  }

string ResolveSym(const string src)
  {
   //--- 1. app me likha hua map:  XAUUSD+=XAUUSDm
   string m = cSymMap;
   StringReplace(m, "\r", ";");
   StringReplace(m, "\n", ";");
   StringReplace(m, ",", ";");
   string parts[];
   int n = StringSplit(m, ';', parts);
   for(int i = 0; i < n; i++)
     {
      int eq = StringFind(parts[i], "=");
      if(eq <= 0) continue;
      string a = Trim(StringSubstr(parts[i], 0, eq));
      string b = Trim(StringSubstr(parts[i], eq + 1));
      if(Upper(a) == Upper(src) && SymOK(b)) return b;
     }
   //--- 2. base naam nikalo: XAUUSD+ -> XAUUSD , XAUUSDm -> XAUUSDm / XAUUSD
   string base = "";
   for(int i = 0; i < StringLen(src); i++)
     {
      ushort c = StringGetCharacter(src, i);
      bool an = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');
      if(!an) break;
      base += ShortToString(c);
     }
   string base6 = "";
   if(StringLen(base) > 6)
     {
      string b6 = StringSubstr(base, 0, 6);
      bool letters = true;
      for(int i = 0; i < 6; i++)
        {
         ushort c = StringGetCharacter(b6, i);
         if(!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) letters = false;
        }
      if(letters) base6 = b6;
     }
   //--- 3. suffix ke saath / bina try karo
   if(cSuffix != "")
     {
      if(SymOK(base + cSuffix)) return base + cSuffix;
      if(base6 != "" && SymOK(base6 + cSuffix)) return base6 + cSuffix;
     }
   if(SymOK(src)) return src;
   if(base != "" && SymOK(base)) return base;
   if(base6 != "" && SymOK(base6)) return base6;
   //--- 4. broker ki poori list me dhoondo (XAUUSD -> XAUUSDm / XAUUSD.sc)
   string keys[2];
   keys[0] = base6; keys[1] = base;
   int total = SymbolsTotal(false);
   for(int k = 0; k < 2; k++)
     {
      string key = Upper(keys[k]);
      if(key == "") continue;
      for(int i = 0; i < total; i++)
        {
         string s = SymbolName(i, false);
         if(StringLen(s) > StringLen(key) + 4) continue;
         if(StringFind(Upper(s), key) == 0 && SymOK(s)) return s;
        }
     }
   return "";
  }

string MapSymbol(const string src)
  {
   for(int i = 0; i < SCn; i++) if(SCs[i] == src) return SCd[i];
   string d = ResolveSym(src);
   ArrayResize(SCs, SCn + 1);
   ArrayResize(SCd, SCn + 1);
   SCs[SCn] = src; SCd[SCn] = d; SCn++;
   if(d == "") Log("Symbol nahi mila: " + src + " — app me Symbol Map daalo (" + src + "=APNA_SYMBOL)");
   else if(d != src) Log("Symbol map: " + src + " -> " + d);
   return d;
  }

//+------------------------------------------------------------------+
//| LOT                                                              |
//+------------------------------------------------------------------+
double NormLot(const string sym, double v)
  {
   double step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   if(v > cMaxLot) v = cMaxLot;
   if(mx > 0 && v > mx) v = mx;
   v = MathFloor(v / step + 1e-7) * step;
   if(v < mn) v = mn;
   int dg = 0;
   double s = step;
   while(s < 1.0 - 1e-9 && dg < 8) { s *= 10; dg++; }
   return NormalizeDouble(v, dg);
  }

double CalcLot(const string dsym, const double srcVol)
  {
   double v = srcVol;
   if(cLotMode == CP_LOT_MULT)  v = srcVol * cMult;
   if(cLotMode == CP_LOT_FIXED) v = cFix;
   if(cLotMode == CP_LOT_RATIO)
     {
      double myBal = AccountInfoDouble(ACCOUNT_BALANCE);
      v = (hBal > 0 ? srcVol * (myBal / hBal) : srcVol) * cMult;
     }
   return NormLot(dsym, v);
  }

//+------------------------------------------------------------------+
//| SL / TP                                                          |
//+------------------------------------------------------------------+
//--- position type (0 buy / 1 sell) ke hisaab se sl/tp sahi jagah hai?
void FixStops(const string sym, const int ptype, double &sl, double &tp)
  {
   MqlTick tk;
   if(!SymbolInfoTick(sym, tk)) return;
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   long   lvl = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   double gap = (lvl + 2) * pt;
   if(ptype == 0)
     {
      if(sl > 0 && sl >= tk.bid - gap) sl = 0;
      if(tp > 0 && tp <= tk.bid + gap) tp = 0;
     }
   else
     {
      if(sl > 0 && sl <= tk.ask + gap) sl = 0;
      if(tp > 0 && tp >= tk.ask - gap) tp = 0;
     }
   if(sl > 0) sl = NormalizeDouble(sl, dg);
   if(tp > 0) tp = NormalizeDouble(tp, dg);
  }

void WantStops(const int si, double &sl, double &tp)
  {
   sl = 0; tp = 0;
   if(!cSLTP) return;
   if(cReverse) { sl = SP[si].tp; tp = SP[si].sl; }
   else         { sl = SP[si].sl; tp = SP[si].tp; }
  }

//+------------------------------------------------------------------+
//| TRADE ACTIONS                                                    |
//+------------------------------------------------------------------+
bool TradingAllowed()
  {
   return TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0 &&
          MQLInfoInteger(MQL_TRADE_ALLOWED) != 0 &&
          AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) != 0 &&
          AccountInfoInteger(ACCOUNT_TRADE_EXPERT) != 0;
  }

int CountMine()
  {
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk != 0 && PositionGetInteger(POSITION_MAGIC) == InpMagic) n++;
     }
   return n;
  }

double CopiedPL()
  {
   double s = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk != 0 && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         s += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }
   return s;
  }

bool CloseDst(const ulong dst, const string why)
  {
   if(!PositionSelectByTicket(dst)) return true;
   trade.SetTypeFillingBySymbol(PositionGetString(POSITION_SYMBOL));
   bool ok = trade.PositionClose(dst, (ulong)InpSlippagePts);
   uint rc = trade.ResultRetcode();
   if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_DONE_PARTIAL || rc == TRADE_RETCODE_PLACED))
     {
      Log("BAND #" + IntegerToString((long)dst) + " (" + why + ")");
      return true;
     }
   Log("Band nahi hua #" + IntegerToString((long)dst) + " rc=" + IntegerToString(rc) + " " + trade.ResultRetcodeDescription());
   return false;
  }

void CloseAllCopied(const string why)
  {
   for(int i = MPn - 1; i >= 0; i--)
     {
      if(CloseDst(MP[i].dst, why))
        {
         if(FindSrc(MP[i].src) >= 0) AddSkip(MP[i].src, "CLOSED");
         DelMap(i);
        }
     }
   // map ke bahar bhi koi magic wali ho to
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk != 0 && PositionGetInteger(POSITION_MAGIC) == InpMagic) CloseDst(tk, why);
     }
   SaveState();
  }

void OpenCopy(const int si)
  {
   ulong src = SP[si].tk;

   //--- purana trade?
   if(!cOld && startSrv > 0 && SP[si].time < startSrv - 2)
     {
      AddSkip(src, "OLD");
      SaveState();
      return;
     }
   string dsym = MapSymbol(SP[si].sym);
   if(dsym == "") { AddSkip(src, "NOSYM"); SaveState(); return; }

   if(CountMine() >= cMaxPos)
     {
      AddSkip(src, "MAXPOS");
      Log("Max positions (" + IntegerToString(cMaxPos) + ") poore — source #" + IntegerToString((long)src) + " skip");
      SaveState();
      return;
     }

   //--- retry ka wait
   int fi = FindFail(src);
   if(fi >= 0 && GetTickCount() - FLa[fi] < 1500) return;

   MqlTick tk;
   if(!SymbolInfoTick(dsym, tk) || tk.bid <= 0) return;

   int ptype = SP[si].type;
   if(cReverse) ptype = (ptype == 0 ? 1 : 0);
   double price = (ptype == 0 ? tk.ask : tk.bid);

   //--- price bahut door chala gaya?
   if(cMaxDev > 0)
     {
      double worse = cReverse ? MathAbs(price - SP[si].open)
                              : (ptype == 0 ? price - SP[si].open : SP[si].open - price);
      if(worse > cMaxDev)
        {
         AddSkip(src, "DEV");
         Log("Skip #" + IntegerToString((long)src) + " — price " + DoubleToString(worse, 2) + " door (max " + DoubleToString(cMaxDev, 2) + ")");
         SaveState();
         return;
        }
     }

   double lot = CalcLot(dsym, SP[si].vol);
   double sl, tp;
   WantStops(si, sl, tp);
   FixStops(dsym, ptype, sl, tp);

   trade.SetTypeFillingBySymbol(dsym);
   string cm = "CP#" + IntegerToString((long)src);
   bool ok = (ptype == 0) ? trade.Buy(lot, dsym, 0, sl, tp, cm)
                          : trade.Sell(lot, dsym, 0, sl, tp, cm);
   uint rc = trade.ResultRetcode();
   if(ok && (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_DONE_PARTIAL || rc == TRADE_RETCODE_PLACED))
     {
      ulong dst = trade.ResultOrder();
      if(!PositionSelectByTicket(dst))
        {
         ulong f = FindDstByComment(src);
         if(f > 0) dst = f;
        }
      double dv = lot;
      if(PositionSelectByTicket(dst)) dv = PositionGetDouble(POSITION_VOLUME);
      AddMap(src, dst, SP[si].vol, dv, dsym);
      if(mapLogin == 0 || MPn == 1) mapLogin = hLogin;
      if(fi >= 0) FLa[fi] = 0;
      Log("COPY " + (ptype == 0 ? "BUY " : "SELL ") + DoubleToString(lot, 2) + " " + dsym +
          " @" + DoubleToString(trade.ResultPrice(), (int)SymbolInfoInteger(dsym, SYMBOL_DIGITS)) +
          "  <- source #" + IntegerToString((long)src));
      SaveState();
      return;
     }

   //--- fail
   if(fi < 0)
     {
      ArrayResize(FLt, FLn + 1); ArrayResize(FLc, FLn + 1); ArrayResize(FLa, FLn + 1);
      FLt[FLn] = src; FLc[FLn] = 0; FLa[FLn] = 0;
      fi = FLn; FLn++;
     }
   FLc[fi]++;
   FLa[fi] = GetTickCount();
   Log("Copy fail #" + IntegerToString((long)src) + " try " + IntegerToString(FLc[fi]) + "/3 rc=" +
       IntegerToString(rc) + " " + trade.ResultRetcodeDescription());
   if(FLc[fi] >= 3) { AddSkip(src, "FAIL"); SaveState(); }
  }

double NormLotRaw(const string sym, double v)
  {
   double step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   v = MathFloor(v / step + 1e-7) * step;
   int dg = 0;
   double s = step;
   while(s < 1.0 - 1e-9 && dg < 8) { s *= 10; dg++; }
   return NormalizeDouble(v, dg);
  }

//+------------------------------------------------------------------+
//| SYNC                                                             |
//+------------------------------------------------------------------+
void Sync()
  {
   warnMsg = "";
   if(!cLoaded) { warnMsg = "App settings abhi nahi aayi (Bridge EA check karo)"; return; }
   if(!SourceFresh()) { warnMsg = hOk ? "Source data purana / disconnected — ruka hua" : "Reader EA ki file nahi mili"; return; }
   if(cSrcLogin > 0 && hLogin != cSrcLogin)
     {
      warnMsg = "Source login " + IntegerToString(hLogin) + " hai, app me " + IntegerToString(cSrcLogin) + " — match nahi, copy ruka";
      return;
     }
   if(MPn == 0) mapLogin = hLogin;     // koi copied trade nahi -> naye source se shuru
   bool loginSame = (mapLogin == 0 || mapLogin == hLogin);
   if(!loginSame) warnMsg = "Source account badla — purane copied trades khud band nahi honge";

   bool newSeq = (hSeq != lastSeqEval);
   lastSeqEval = hSeq;
   bool changed = false;

   //--- copy start time
   if(cOn && startSrv == 0 && hSrv > 0)
     {
      startSrv = hSrv;
      GlobalVariableSet(GVName("start"), (double)startSrv);
      Log("Copy ON — " + (cOld ? "abhi ke khule trades bhi copy honge" : "sirf naye trades copy honge"));
     }

   //--- DD limit
   if(cDDUsd > 0 && !ddTrip)
     {
      double pl = CopiedPL();
      if(pl <= -cDDUsd)
        {
         ddTrip = true;
         GlobalVariableSet(GVName("dd"), 1);
         Log("LOSS LIMIT hit: " + DoubleToString(pl, 2) + " — naye copy band" + (cDDClose ? ", sab copied band" : ""));
         if(cDDClose) CloseAllCopied("LOSS LIMIT");
        }
     }

   //--- 1. mere copied trades
   for(int i = MPn - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(MP[i].dst))
        {
         ulong f = FindDstByComment(MP[i].src);
         if(f > 0) { MP[i].dst = f; changed = true; }
         else
           {
            if(FindSrc(MP[i].src) >= 0)
              {
               AddSkip(MP[i].src, "MYCLOSE");
               Log("Mera #" + IntegerToString((long)MP[i].dst) + " band hua (SL/TP/manual) — source #" +
                   IntegerToString((long)MP[i].src) + " dobara copy nahi hoga");
              }
            DelMap(i);
            changed = true;
            continue;
           }
        }
      if(!loginSame) continue;

      int si = FindSrc(MP[i].src);
      if(si < 0)
        {
         if(newSeq) MP[i].miss++;
         if(MP[i].miss >= 3 && TradingAllowed())
           {
            if(CloseDst(MP[i].dst, "source band")) { DelMap(i); changed = true; }
           }
         continue;
        }
      MP[i].miss = 0;
      if(!TradingAllowed()) continue;

      //--- partial close
      double dvol = PositionGetDouble(POSITION_VOLUME);
      if(MP[i].srcVol0 > 0 && SP[si].vol < MP[i].srcVol0 - 1e-6)
        {
         double target = MP[i].dstVol0 * SP[si].vol / MP[i].srcVol0;
         double step = SymbolInfoDouble(MP[i].dsym, SYMBOL_VOLUME_STEP);
         if(step <= 0) step = 0.01;
         target = MathFloor(target / step + 1e-7) * step;
         double cut = dvol - target;
         if(cut >= step - 1e-7 && target >= SymbolInfoDouble(MP[i].dsym, SYMBOL_VOLUME_MIN) - 1e-7)
           {
            cut = NormLotRaw(MP[i].dsym, cut);
            trade.SetTypeFillingBySymbol(MP[i].dsym);
            if(trade.PositionClosePartial(MP[i].dst, cut, (ulong)InpSlippagePts))
               Log("PARTIAL " + DoubleToString(cut, 2) + " band #" + IntegerToString((long)MP[i].dst));
            if(!PositionSelectByTicket(MP[i].dst)) continue;
           }
        }

      //--- SL / TP
      if(cSLTP && GetTickCount() - MP[i].lastMod > 1000)
        {
         double sl, tp;
         WantStops(si, sl, tp);
         int ptype = (int)PositionGetInteger(POSITION_TYPE);
         FixStops(MP[i].dsym, ptype, sl, tp);
         double csl = PositionGetDouble(POSITION_SL), ctp = PositionGetDouble(POSITION_TP);
         double pt = SymbolInfoDouble(MP[i].dsym, SYMBOL_POINT);
         // agar naya level abhi galat jagah hai (0 ban gaya) to purana hi rehne do
         double wantSL = sl, wantTP = tp;
         if(wantSL == 0 && (cReverse ? SP[si].tp : SP[si].sl) > 0) wantSL = csl;
         if(wantTP == 0 && (cReverse ? SP[si].sl : SP[si].tp) > 0) wantTP = ctp;
         if(MathAbs(wantSL - csl) > pt * 0.5 || MathAbs(wantTP - ctp) > pt * 0.5)
           {
            MP[i].lastMod = GetTickCount();
            if(trade.PositionModify(MP[i].dst, wantSL, wantTP))
               Log("SL/TP sync #" + IntegerToString((long)MP[i].dst) + " SL " + DoubleToString(wantSL, 2) + " TP " + DoubleToString(wantTP, 2));
           }
        }
     }

   //--- 2. naye source trades
   if(cOn && !ddTrip && loginSame && TradingAllowed())
     {
      for(int s = 0; s < SPn; s++)
        {
         if(FindMap(SP[s].tk) >= 0) continue;
         if(FindSkip(SP[s].tk) >= 0) continue;
         OpenCopy(s);
        }
     }
   else if(cOn && !TradingAllowed())
      warnMsg = "Algo Trading band hai — MT5 me AutoTrading button ON karo";

   if(changed) SaveState();
  }

//+------------------------------------------------------------------+
//| COMMANDS from app                                                |
//+------------------------------------------------------------------+
void HandleCmd()
  {
   if(cCmdId <= 0 || cCmdId <= lastCmdDone) return;
   lastCmdDone = cCmdId;
   GlobalVariableSet(GVName("cmd"), lastCmdDone);
   if(cCmd == "CLOSEALL")
     {
      Log("App se: SAB COPIED TRADES BAND");
      CloseAllCopied("app command");
     }
   else if(cCmd == "RESETDD")
     {
      ddTrip = false;
      GlobalVariableDel(GVName("dd"));
      Log("App se: loss limit reset — copy phir chalu");
     }
  }

//--- ON/OFF badla?
void TrackOnOff()
  {
   if(cOn == prevOn) return;
   startSrv = 0;                       // ON: Sync() source ke time se naya start set karega
   GlobalVariableDel(GVName("start"));
   if(cOn)
     {
      ddTrip = false;                  // OFF -> ON = loss limit bhi reset
      GlobalVariableDel(GVName("dd"));
      Log("Copy ON (app se)");
     }
   else
      Log("Copy OFF — naye trade nahi khulenge (copied trades ka sync chalta rahega)");
   prevOn = cOn;
  }

//+------------------------------------------------------------------+
//| STATUS for app                                                   |
//+------------------------------------------------------------------+
string TypeName(const int t) { return t == 0 ? "BUY" : "SELL"; }

string PendName(const int t)
  {
   switch(t)
     {
      case 2: return "BUY LIMIT";
      case 3: return "SELL LIMIT";
      case 4: return "BUY STOP";
      case 5: return "SELL STOP";
      case 6: return "BUY STOP LIMIT";
      case 7: return "SELL STOP LIMIT";
     }
   return "PENDING";
  }

void WriteStatus()
  {
   string js = "{";
   js += "\"v\":\"" + EA_VER + "\"";
   js += ",\"at\":" + IntegerToString((long)TimeGMT());
   js += ",\"on\":" + (cOn ? "true" : "false");
   js += ",\"cfg\":" + (cLoaded ? "true" : "false");
   js += ",\"cfgAt\":" + IntegerToString(cfgAt);
   js += ",\"dd\":" + (ddTrip ? "true" : "false");
   js += ",\"algo\":" + (TradingAllowed() ? "true" : "false");
   js += ",\"warn\":\"" + JEsc(warnMsg) + "\"";
   js += ",\"cmdDone\":" + DoubleToString(lastCmdDone, 0);

   long age = hOk ? (long)TimeLocal() - hLocal : -1;
   js += ",\"src\":{\"ok\":" + (SourceFresh() ? "true" : "false") +
         ",\"age\":" + IntegerToString(age) +
         ",\"login\":" + IntegerToString(hLogin) +
         ",\"server\":\"" + JEsc(hServer) + "\"" +
         ",\"inv\":" + (hTrade ? "false" : "true") +
         ",\"bal\":" + DoubleToString(hBal, 2) +
         ",\"eq\":" + DoubleToString(hEq, 2) +
         ",\"n\":" + IntegerToString(SPn) +
         ",\"np\":" + IntegerToString(POn) + "}";

   js += ",\"dst\":{\"login\":" + IntegerToString(myLogin) +
         ",\"server\":\"" + JEsc(AccountInfoString(ACCOUNT_SERVER)) + "\"" +
         ",\"bal\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
         ",\"eq\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) +
         ",\"cur\":\"" + JEsc(AccountInfoString(ACCOUNT_CURRENCY)) + "\"" +
         ",\"n\":" + IntegerToString(MPn) +
         ",\"pl\":" + DoubleToString(CopiedPL(), 2) + "}";

   //--- rows
   js += ",\"rows\":[";
   int rows = 0;
   for(int s = 0; s < SPn && rows < 40; s++)
     {
      string st = "WAIT";
      string dsym = "";
      long   dtk = 0;
      double dv = 0, dp = 0;
      int mi = FindMap(SP[s].tk);
      if(mi >= 0)
        {
         st = "COPY";
         dtk = (long)MP[mi].dst;
         dsym = MP[mi].dsym;
         if(PositionSelectByTicket(MP[mi].dst))
           {
            dv = PositionGetDouble(POSITION_VOLUME);
            dp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
           }
        }
      else
        {
         int k = FindSkip(SP[s].tk);
         if(k >= 0) st = "SKIP:" + SKw[k];
         else if(FindFail(SP[s].tk) >= 0) st = "RETRY";
         else if(!cOn) st = "OFF";
         else if(ddTrip) st = "LIMIT";
        }
      if(rows > 0) js += ",";
      js += "{\"s\":" + IntegerToString((long)SP[s].tk) +
            ",\"sym\":\"" + JEsc(SP[s].sym) + "\"" +
            ",\"t\":\"" + TypeName(SP[s].type) + "\"" +
            ",\"sv\":" + DoubleToString(SP[s].vol, 2) +
            ",\"sp\":" + DoubleToString(SP[s].pl, 2) +
            ",\"d\":" + IntegerToString(dtk) +
            ",\"dsym\":\"" + JEsc(dsym) + "\"" +
            ",\"dv\":" + DoubleToString(dv, 2) +
            ",\"dp\":" + DoubleToString(dp, 2) +
            ",\"st\":\"" + st + "\"}";
      rows++;
     }
   //--- mere trades jinka source ab nahi dikh raha
   for(int i = 0; i < MPn && rows < 40; i++)
     {
      if(FindSrc(MP[i].src) >= 0) continue;
      double dv = 0, dp = 0;
      int typ = 0;
      if(PositionSelectByTicket(MP[i].dst))
        {
         dv = PositionGetDouble(POSITION_VOLUME);
         dp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         typ = (int)PositionGetInteger(POSITION_TYPE);
        }
      if(rows > 0) js += ",";
      js += "{\"s\":" + IntegerToString((long)MP[i].src) +
            ",\"sym\":\"\",\"t\":\"" + TypeName(typ) + "\",\"sv\":0,\"sp\":0" +
            ",\"d\":" + IntegerToString((long)MP[i].dst) +
            ",\"dsym\":\"" + JEsc(MP[i].dsym) + "\"" +
            ",\"dv\":" + DoubleToString(dv, 2) +
            ",\"dp\":" + DoubleToString(dp, 2) +
            ",\"st\":\"" + (mapLogin == hLogin ? "CLOSING" : "ORPHAN") + "\"}";
      rows++;
     }
   js += "]";

   //--- source ke pending orders (sirf dikhane ke liye)
   js += ",\"pend\":[";
   for(int k = 0; k < POn && k < 20; k++)
     {
      int dg = (int)SymbolInfoInteger(PO[k].sym, SYMBOL_DIGITS);
      if(dg <= 0) dg = 2;
      if(k > 0) js += ",";
      js += "{\"s\":" + IntegerToString((long)PO[k].tk) +
            ",\"sym\":\"" + JEsc(PO[k].sym) + "\"" +
            ",\"t\":\"" + PendName(PO[k].type) + "\"" +
            ",\"v\":" + DoubleToString(PO[k].vol, 2) +
            ",\"p\":" + DoubleToString(PO[k].price, dg) +
            ",\"sl\":" + DoubleToString(PO[k].sl, dg) +
            ",\"tp\":" + DoubleToString(PO[k].tp, dg) +
            ",\"exp\":" + IntegerToString(PO[k].exp) + "}";
     }
   js += "]";

   //--- log (naya pehle)
   js += ",\"log\":[";
   for(int i = LOGn - 1; i >= 0; i--)
     {
      if(i < LOGn - 1) js += ",";
      js += "\"" + JEsc(LOG[i]) + "\"";
     }
   js += "]}";

   WriteFileText(F_STTMP, F_STATUS, js);
  }

//+------------------------------------------------------------------+
//| PANEL                                                            |
//+------------------------------------------------------------------+
void Panel()
  {
   string s = "SamuSignal CopyTrade — EXECUTOR v" + EA_VER + "\n";
   s += "Copy: " + (cOn ? "ON" : "OFF") + (ddTrip ? "  (LOSS LIMIT — ruka)" : "") +
        "   Settings: " + (InpUseAppConfig ? (cLoaded ? "App se" : "App ka intezaar") : "Inputs se") + "\n";
   s += "Source: " + (hOk ? IntegerToString(hLogin) + " @ " + hServer : "—") +
        "   " + (SourceFresh() ? "LIVE" : "OFFLINE") + "   trades " + IntegerToString(SPn) +
        "   pending " + IntegerToString(POn) + "\n";
   s += "Copied: " + IntegerToString(MPn) + "   P/L " + DoubleToString(CopiedPL(), 2) + "\n";
   if(warnMsg != "") s += "! " + warnMsg + "\n";
   if(LOGn > 0) s += "Last: " + LOG[LOGn - 1];
   Comment(s);
  }

//+------------------------------------------------------------------+
//| EVENTS                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   myLogin = AccountInfoInteger(ACCOUNT_LOGIN);
   FolderCreate(CP_FOLDER, FILE_COMMON);
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints((ulong)InpSlippagePts);
   trade.SetAsyncMode(false);
   trade.LogLevel(LOG_LEVEL_ERRORS);

   LoadState();
   RecoverByComment();

   if(GlobalVariableCheck(GVName("start"))) startSrv = (long)GlobalVariableGet(GVName("start"));
   if(GlobalVariableCheck(GVName("dd")))    ddTrip = true;
   if(GlobalVariableCheck(GVName("cmd")))   lastCmdDone = GlobalVariableGet(GVName("cmd"));

   if(InpUseAppConfig) ReadConfig(); else InputsToCfg();
   // pehli baar: agar copy pehle se ON thi aur start time yaad hai to wahi chalega
   prevOn = cOn;                     // restart ko ON/OFF badlaav nahi maante
   if(cOn && startSrv == 0) Log("Copy ON mila — start time source se set hoga");
   if(cCmdId > 0 && lastCmdDone == 0) { lastCmdDone = cCmdId; GlobalVariableSet(GVName("cmd"), lastCmdDone); } // purana command dobara na chale

   int ms = InpTimerMs;
   if(ms < 100) ms = 100;
   if(!EventSetMillisecondTimer(ms))
     {
      Print("SamuCopy Executor: timer start nahi hua ", GetLastError());
      return(INIT_FAILED);
     }
   Log("Executor v" + EA_VER + " chalu — account " + IntegerToString(myLogin) + ", yaad " +
       IntegerToString(MPn) + " copied trades");
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      Log("DHYAN: ye NETTING account hai — hedge account best rehta hai");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   SaveState();
   Comment("");
  }

void OnTick() { }

void OnTimer()
  {
   if(InpUseAppConfig)
     {
      if(GetTickCount() - lastCfgRead > 1000)
        {
         lastCfgRead = GetTickCount();
         ReadConfig();
        }
     }
   else InputsToCfg();

   TrackOnOff();
   HandleCmd();
   ReadMaster();
   Sync();

   if(GetTickCount() - lastStatus > 2000)
     {
      lastStatus = GetTickCount();
      PruneSkip();
      WriteStatus();
     }
   if(GetTickCount() - lastPanel > 1000)
     {
      lastPanel = GetTickCount();
      Panel();
     }
  }
//+------------------------------------------------------------------+
