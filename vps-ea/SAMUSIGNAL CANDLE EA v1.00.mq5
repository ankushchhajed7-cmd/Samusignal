//+------------------------------------------------------------------+
//|                                  SAMUSIGNAL CANDLE EA v1.00.mq5  |
//|                                           Ankush New Vision      |
//+------------------------------------------------------------------+
//|  v1.00 (user 16 Nov 2026): app ke CANDLE page (Strategy 5) ka   |
//|  apna EA - naye $100 DEMO account par. VPS paper jaisa hi niyam: |
//|                                                                  |
//|  KAUNSE PAIR: sirf wahi jo app ke Candle page me ON hain         |
//|   (Firebase /candle/cfg pairs, har 20 sec). 1 MIN / 5 MIN bhi    |
//|   app ka (cfg.tf). App me pair OFF kiya = naya trade nahi (chalu |
//|   trade apne niyam se band hota hai).                            |
//|                                                                  |
//|  SIGNAL (har band candle, MT5 ki apni candles, app jaisa hi):    |
//|   body >= pichhli 10 ki average body x 1.2 aur >= range ka 50%;  |
//|   BUY = hari + EMA9 > EMA21 + close > EMA9 + RSI14 50-70,        |
//|   SELL = laal + EMA9 < EMA21 + close < EMA9 + RSI14 30-50.       |
//|   Agli candle khulte hi MARKET order (1m: 20 sec, 5m: 60 sec ke  |
//|   andar, warna chhod do).                                        |
//|                                                                  |
//|  TRADE (0.01 lot par, lot ke saath badhta):                      |
//|   TP = signal candle body ka 50% ($0.10 - $1.00), SL $10.        |
//|   Pehli candle: TP / SL, ya candle band par fayde me = BOOK.     |
//|   Dusri candle se: +$0.05 dikhte hi BOOK, ya kisi candle ka band |
//|   fayde me = BOOK. 1m: 200 candle, 5m: 72 candle baad TIME band. |
//|   1 pair = 1 trade. EK SAATH ZYADA SE ZYADA 3 TRADE (MaxOpen).   |
//|                                                                  |
//|  SURAKSHA: REAL account par trade tabhi jab AllowReal = true     |
//|   (user: DEMO). Spread $ > MaxSpreadUsd = SKIP. Din ka target /  |
//|   ghata (0 = band) - pahunche to us din naya trade nahi.         |
//|                                                                  |
//|  APP KE LIYE: /candle/ea/state (har 30 sec) aur                 |
//|   /candle/ea/trades/<key> (key = VPS paper wala hi, tulna ke     |
//|   liye). Phone push: trade khula / band.                         |
//|                                                                  |
//|  MT5: Tools > Options > Expert Advisors > Allow WebRequest me    |
//|  Firebase URL. Algo Trading ON. EA kisi bhi EK chart par.        |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "SAMUSIGNAL CANDLE EA - app ke Candle page (Strategy 5) ke ON pair par, VPS paper jaisa niyam, max 3 trade"

#include <Trade\Trade.mqh>
CTrade trade;

#define VER "1.00"
#define LBL "SSC_L"

input group "========== FIREBASE =========="
input string FirebaseURL      = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // FirebaseURL (mat badlo)
input string FirebaseAuth     = "";        // FirebaseAuth (AI AUTO / News Pusher wala hi)

input group "========== TRADE =========="
input double Lot              = 0.01;      // Lot
input int    MaxOpen          = 3;         // Ek saath zyada se zyada kitne trade
input double SL_Usd           = 10.0;      // SL $ (0.01 lot par)
input double TpBodyPct        = 50;        // TP = signal candle body ka itna %
input double TpMin_Usd        = 0.10;      // TP kam se kam $ (0.01 lot par)
input double TpMax_Usd        = 1.00;      // TP zyada se zyada $ (0.01 lot par)
input double Book_Usd         = 0.05;      // Dusri candle se itna profit dikhte hi BOOK $
input int    HoldMax1         = 200;       // 1 MIN: kitni candle baad TIME band
input int    HoldMax5         = 72;        // 5 MIN: kitni candle baad TIME band
input double MaxSpreadUsd     = 0.50;      // Spread max $ (0.01 lot par), 0 = jaanch nahi
input string ExcludeCSV       = "";        // In pair par trade nahi (jaise XAUUSD), khaali = sirf app
input string SymbolSuffix     = "";        // Symbol suffix (khaali = apne aap)
input long   Magic            = 7320001;   // Magic number
input bool   AllowReal        = false;     // REAL account par trade? (false = sirf DEMO)

input group "========== SIGNAL (app jaisa - mat badlo) =========="
input double BodyMult         = 1.2;       // body >= pichhli 10 ki average x
input double BodyPctRange     = 50;        // body >= candle range ka %
input int    EmaFast          = 9;         // EMA tez
input int    EmaSlow          = 21;        // EMA dheemi
input int    RsiLen           = 14;        // RSI
input int    CalcBars         = 250;       // Hisaab kitni band candle par (app / VPS feed = 250)

input group "========== DIN KI SEEMA (0 = band) =========="
input double DayTargetUsd     = 0;         // Din ka profit $ itna = us din naya trade nahi
input double DayLossUsd       = 0;         // Din ka ghata $ itna = us din naya trade nahi

input group "========== DUSRA =========="
input int    CfgPollSec       = 20;        // App ki settings har kitne sec padhe
input bool   PushOn           = true;      // Phone par push (trade khula / band)
input bool   PanelOn          = true;      // Chart par haal
input int    FontPx           = 12;        // Panel akshar size

// ---- halat ----
string   g_CfgPairs[];      // app format "BTC/USD"
string   g_Names[];         // "BTCUSD"
string   g_Syms[];          // broker symbol ("" = nahi mila)
datetime g_LastBar[];       // har pair ki aakhri jaanchi band candle
int      g_Tf = 1;
bool     g_CfgOk = false, g_FbOk = false, g_Real = false, g_UrlWarned = false;
datetime g_CfgAt = 0;
string   g_Status = "shuru...", g_Last = "-", g_LastSkip = "-";
double   g_DayPl = 0; int g_DayW = 0, g_DayL = 0;
long     g_Off = 0;         // server - UTC (sec)
// EA ne khud band kiya to wajah (position id -> wajah)
ulong    g_WhyId[]; string g_WhyTx[];
// har trade ki aakhri dekhi candle (book / TIME ke liye)
ulong    g_MgId[];  datetime g_MgBar[];

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(50);
   g_Real = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   if(g_Real && !AllowReal)
   {
      g_Status = "REAL account - AllowReal=false, trade NAHI";
      Alert("SAMUSIGNAL CANDLE EA: ye REAL account hai. User ne DEMO kaha hai - is account par koi order nahi lagega (AllowReal=false).");
   }
   EventSetMillisecondTimer(250);
   Print("SAMUSIGNAL CANDLE EA v", VER, " shuru | lot ", DoubleToString(Lot,2), " | max ", MaxOpen, " trade | SL $", DoubleToString(SL_Usd,2),
         " | TP body ", DoubleToString(TpBodyPct,0), "% ($", DoubleToString(TpMin_Usd,2), "-", DoubleToString(TpMax_Usd,2), ") | book $", DoubleToString(Book_Usd,2));
   LoadCfg();
   DayStats();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ EventKillTimer(); ObjectsDeleteAll(0, LBL); Comment(""); }
void OnTick(){}

void OnTimer()
{
   static datetime lastCfg = 0, lastState = 0, lastDay = 0, lastPanel = 0;
   datetime now = TimeLocal();
   if(now - lastCfg >= (CfgPollSec < 5 ? 5 : CfgPollSec)){ lastCfg = now; LoadCfg(); }
   if(now - lastDay >= 10){ lastDay = now; DayStats(); }
   Manage();          // chalu trade: book / TIME (har 250 ms)
   ScanPairs();       // nayi band candle par signal
   if(now - lastState >= 30){ lastState = now; PublishState(); }
   if(now != lastPanel){ lastPanel = now; Panel(); }
}

//+------------------------------------------------------------------+
//| Firebase                                                         |
//+------------------------------------------------------------------+
string FbBase()
{
   string u = FirebaseURL;
   StringTrimLeft(u); StringTrimRight(u);
   while(StringLen(u)>0 && StringGetCharacter(u, StringLen(u)-1)=='/') u = StringSubstr(u, 0, StringLen(u)-1);
   if(u!="" && StringFind(u,"http")!=0) u = "https://"+u;
   return u;
}
string FbUrl(string path)
{
   string u = FbBase()+"/candle/"+path+".json";
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
   return u;
}
bool Http(string method, string url, string body, string extraHdr, string &resp, int &code)
{
   char data[], result[];
   string rh, hdr = "Content-Type: application/json\r\n" + extraHdr;
   if(body!="")
   {
      int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
      if(n>0) ArrayResize(data, n-1);
   }
   ResetLastError();
   code = WebRequest(method, url, hdr, 5000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_Status = "WebRequest me Firebase URL allow karo";
         if(!g_UrlWarned){ g_UrlWarned = true; Alert("SAMUSIGNAL CANDLE EA: Tools > Options > Expert Advisors > Allow WebRequest me ye URL daalo: ", FbBase()); }
      }
      else g_Status = "net error "+IntegerToString(err);
      g_FbOk = false;
      return false;
   }
   resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if(code<200 || code>=300){ g_Status = "Firebase HTTP "+IntegerToString(code)+(code==401?" (FirebaseAuth daalo)":""); g_FbOk = false; return false; }
   g_FbOk = true;
   return true;
}
string JsonSafe(string t)
{
   StringReplace(t, "\\", "/"); StringReplace(t, "\"", "'"); StringReplace(t, "{", "("); StringReplace(t, "}", ")");
   return t;
}
double JsonNum(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return 0;
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return 0;
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ' || StringGetCharacter(obj,p)=='"')) p++;
   int q = p;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if((c>='0' && c<='9') || c=='.' || c=='-' || c=='+' || c=='e' || c=='E') q++;
      else break;
   }
   if(q==p) return 0;
   return StringToDouble(StringSubstr(obj, p, q-p));
}
// "pairs":["BTC/USD","GBP/USD"] -> out[]
int JsonStrArr(string obj, string key, string &out[])
{
   ArrayResize(out, 0);
   int p = StringFind(obj, "\""+key+"\"");
   if(p<0) return -1;
   int a = StringFind(obj, "[", p), b = (a<0 ? -1 : StringFind(obj, "]", a));
   if(a<0 || b<0) return -1;
   string s = StringSubstr(obj, a+1, b-a-1);
   int n = 0, i = 0, L = StringLen(s);
   while(i < L)
   {
      int q1 = StringFind(s, "\"", i);
      if(q1<0) break;
      int q2 = StringFind(s, "\"", q1+1);
      if(q2<0) break;
      ArrayResize(out, n+1); out[n] = StringSubstr(s, q1+1, q2-q1-1); n++;
      i = q2+1;
   }
   return n;
}
string B36(long v)
{
   string d = "0123456789abcdefghijklmnopqrstuvwxyz", s = "";
   if(v <= 0) return "0";
   while(v > 0){ int m = (int)(v % 36); s = StringSubstr(d, m, 1) + s; v /= 36; }
   return s;
}

//+------------------------------------------------------------------+
//| App ki settings: kaunse pair ON + 1 / 5 MIN                      |
//+------------------------------------------------------------------+
bool IsExcluded(string name)
{
   string parts[];
   int n = StringSplit(ExcludeCSV, ',', parts);
   for(int i=0;i<n;i++){ string p = parts[i]; StringTrimLeft(p); StringTrimRight(p); StringToUpper(p); if(p!="" && p==name) return true; }
   return false;
}
void LoadCfg()
{
   string resp; int code;
   if(!Http("GET", FbUrl("cfg"), "", "", resp, code)) return;
   string arr[];
   string t0 = resp; StringTrimLeft(t0); StringTrimRight(t0);
   if(t0 == "" || t0 == "null")
   {
      g_CfgOk = false; g_Status = "app settings (/candle/cfg) nahi - app me Candle page kholo";
      ArrayResize(g_CfgPairs, 0); ArrayResize(g_Names, 0); ArrayResize(g_Syms, 0); ArrayResize(g_LastBar, 0);
      return;
   }
   int n = JsonStrArr(resp, "pairs", arr);
   if(n < 0) n = 0;                                                  // app me saare pair OFF (Firebase khaali list nahi rakhta)
   int tf = (int)JsonNum(resp, "tf");
   int newTf = (tf == 5 ? 5 : 1);
   // naya pair list (purane pair ki aakhri candle yaad rakho)
   string oldN[]; datetime oldB[];
   int on = ArraySize(g_Names);
   ArrayResize(oldN, on); ArrayResize(oldB, on);
   for(int i=0;i<on;i++){ oldN[i] = g_Names[i]; oldB[i] = g_LastBar[i]; }
   ArrayResize(g_CfgPairs, 0); ArrayResize(g_Names, 0); ArrayResize(g_Syms, 0); ArrayResize(g_LastBar, 0);
   int c = 0;
   for(int i=0;i<n;i++)
   {
      string nm = arr[i]; StringReplace(nm, "/", ""); StringToUpper(nm);
      if(nm=="" || IsExcluded(nm)) continue;
      ArrayResize(g_CfgPairs, c+1); ArrayResize(g_Names, c+1); ArrayResize(g_Syms, c+1); ArrayResize(g_LastBar, c+1);
      g_CfgPairs[c] = arr[i]; g_Names[c] = nm; g_Syms[c] = Resolve(nm); g_LastBar[c] = 0;
      for(int j=0;j<on;j++) if(oldN[j]==nm && newTf==g_Tf) g_LastBar[c] = oldB[j];
      c++;
   }
   g_Tf = newTf;
   g_CfgOk = true; g_CfgAt = TimeLocal();
}

//+------------------------------------------------------------------+
//| Symbol                                                           |
//+------------------------------------------------------------------+
bool SymTradable(string s)
{
   long m = SymbolInfoInteger(s, SYMBOL_TRADE_MODE);
   return (m == SYMBOL_TRADE_MODE_FULL || m == SYMBOL_TRADE_MODE_LONGONLY || m == SYMBOL_TRADE_MODE_SHORTONLY);
}
string Resolve(string pair)
{
   if(SymbolSuffix!="")
   {
      string s = pair+SymbolSuffix;
      return SymbolSelect(s,true) ? s : "";
   }
   string want = pair; StringToUpper(want);
   string suf = (StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : ""); StringToUpper(suf);
   string best = "";
   int bestScore = -1, total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false), up = s;
      StringToUpper(up);
      if(StringFind(up,want)!=0 || StringLen(up) > StringLen(want)+4) continue;
      if(!SymTradable(s)) continue;
      string rest = StringSubstr(up, StringLen(want));
      int score = 1 + (rest==suf ? 2 : 0) + (rest=="" ? 1 : 0);
      if(score > bestScore){ bestScore = score; best = s; }
   }
   if(best=="" || !SymbolSelect(best,true)) return "";
   return best;
}
// 0.01 lot nahi - 1.0 lot par 1 price-unit chalne ka $ (account currency)
double UsdPerPriceLot(string sym)
{
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT), price = SymbolInfoDouble(sym, SYMBOL_BID);
   if(pt<=0 || price<=0) return 0;
   double delta = pt*100.0, p = 0;
   if(OrderCalcProfit(ORDER_TYPE_BUY, sym, 1.0, price, price+delta, p) && p>0) return p/delta;
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(ts>0 && tv>0) return tv/ts;
   return 0;
}
ENUM_TIMEFRAMES Per(int tf){ return (tf == 5 ? PERIOD_M5 : PERIOD_M1); }
int TfFromKey(string key){ return (StringSubstr(key, StringLen(key)-1, 1) == "5" ? 5 : 1); }
int CountOpen()
{
   int n = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      n++;
   }
   return n;
}
bool SelectOur(string sym)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      if(PositionGetString(POSITION_SYMBOL)==sym) return true;
   }
   return false;
}
bool HasOpen(string sym)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      if(PositionGetString(POSITION_SYMBOL)==sym) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Signal - app (candlerules.js) jaisa hi                           |
//+------------------------------------------------------------------+
double EmaLast(const double &c[], int n, int len)
{
   if(n < len) return EMPTY_VALUE;
   double k = 2.0/(len+1), e = 0;
   for(int i=0;i<len;i++) e += c[i];
   e /= len;
   for(int i=len;i<n;i++) e = c[i]*k + e*(1.0-k);
   return e;
}
double RsiLast(const double &c[], int n, int len)
{
   if(n < len+1) return EMPTY_VALUE;
   double g = 0, l = 0;
   for(int i=1;i<=len;i++){ double d = c[i]-c[i-1]; if(d>0) g += d; else l -= d; }
   g /= len; l /= len;
   for(int i=len+1;i<n;i++)
   {
      double d = c[i]-c[i-1];
      g = (g*(len-1) + MathMax(d,0.0))/len;
      l = (l*(len-1) + MathMax(-d,0.0))/len;
   }
   if(l == 0) return (g == 0 ? 50 : 100);
   return 100.0 - 100.0/(1.0 + g/l);
}
// dir: 1 BUY, -1 SELL, 0 NO
int Signal(string sym, ENUM_TIMEFRAMES per, double &body, string &why)
{
   body = 0; why = "";
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int got = CopyRates(sym, per, 1, CalcBars, r);   // sirf band candles, purani pehle
   int need = (int)MathMax(MathMax(EmaSlow+2, RsiLen+2), 12);
   if(got < need){ why = "kam candles ("+IntegerToString(got)+")"; return 0; }
   double c[];
   ArrayResize(c, got);
   for(int i=0;i<got;i++) c[i] = r[i].close;
   double e9 = EmaLast(c, got, EmaFast), e21 = EmaLast(c, got, EmaSlow), rs = RsiLast(c, got, RsiLen);
   double avg = 0;
   for(int i=got-11;i<=got-2;i++) avg += MathAbs(r[i].close - r[i].open);
   avg /= 10.0;
   MqlRates last = r[got-1];
   body = MathAbs(last.close - last.open);
   double range = last.high - last.low;
   bool green = last.close > last.open, red = last.close < last.open;
   if(!green && !red){ why = "doji"; return 0; }
   if(!(range > 0) || body < BodyPctRange/100.0*range){ why = "lambi poonch"; return 0; }
   if(!(avg > 0) || body < BodyMult*avg){ why = "candle mazboot nahi"; return 0; }
   if(e9 == EMPTY_VALUE || e21 == EMPTY_VALUE || rs == EMPTY_VALUE){ why = "hisaab adhoora"; return 0; }
   if(green)
   {
      if(!(e9 > e21)){ why = "EMA 9 < 21"; return 0; }
      if(!(last.close > e9)){ why = "close EMA 9 ke neeche"; return 0; }
      if(!(rs >= 50 && rs < 70)){ why = "RSI "+DoubleToString(rs,0); return 0; }
      why = "hari candle + EMA 9 > 21 + RSI "+DoubleToString(rs,0);
      return 1;
   }
   if(!(e9 < e21)){ why = "EMA 9 > 21"; return 0; }
   if(!(last.close < e9)){ why = "close EMA 9 ke upar"; return 0; }
   if(!(rs <= 50 && rs > 30)){ why = "RSI "+DoubleToString(rs,0); return 0; }
   why = "laal candle + EMA 9 < 21 + RSI "+DoubleToString(rs,0);
   return -1;
}

//+------------------------------------------------------------------+
//| Nayi band candle -> signal -> order                              |
//+------------------------------------------------------------------+
void ScanPairs()
{
   if(!g_CfgOk) return;
   g_Off = (long)MathRound(((double)TimeTradeServer() - (double)TimeGMT())/900.0)*900;
   ENUM_TIMEFRAMES per = Per(g_Tf);
   int winSec = (g_Tf == 5 ? 60 : 20);
   for(int i=0;i<ArraySize(g_Names);i++)
   {
      if(g_Syms[i]=="") continue;                                  // symbol nahi mila (har 20 sec phir dhoondhte hain)
      string sym = g_Syms[i];
      datetime b0 = iTime(sym, per, 0), b1 = iTime(sym, per, 1);
      if(b0 <= 0 || b1 <= 0) continue;
      if(g_LastBar[i] == 0){ g_LastBar[i] = b1; continue; }       // pehli baar: purana signal nahi
      if(b1 <= g_LastBar[i]) continue;
      g_LastBar[i] = b1;
      if((long)TimeTradeServer() - (long)b0 > winSec) continue;   // der ho gayi
      double body; string why;
      int dir = Signal(sym, per, body, why);
      if(dir == 0) continue;
      long nextMs = ((long)b0 - g_Off) * 1000;
      string key = "c" + B36(nextMs) + g_Names[i] + IntegerToString(g_Tf);
      Open(i, sym, dir, body, key, why);
   }
}
void SkipMsg(string nm, string dir, string msg)
{
   g_LastSkip = nm+" "+dir+": "+msg;
   Print("SAMUSIGNAL CANDLE EA: SKIP ", g_LastSkip);
}
void Open(int idx, string sym, int dir, double body, string key, string why)
{
   string nm = g_Names[idx], ds = (dir > 0 ? "BUY" : "SELL");
   if(g_Real && !AllowReal){ SkipMsg(nm, ds, "REAL account - AllowReal=false"); return; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)){ SkipMsg(nm, ds, "MT5 me Algo Trading band"); return; }
   if(DayTargetUsd > 0 && g_DayPl >= DayTargetUsd){ SkipMsg(nm, ds, "aaj ka target poora ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd){ SkipMsg(nm, ds, "aaj ki ghata seema ($"+DoubleToString(g_DayPl,2)+")"); return; }
   if(HasOpen(sym)){ SkipMsg(nm, ds, "1 pair 1 trade - pehle wala chalu"); return; }
   int op = CountOpen();
   if(op >= MaxOpen){ SkipMsg(nm, ds, "pehle se "+IntegerToString(op)+" / "+IntegerToString(MaxOpen)+" trade chalu"); return; }

   double k = UsdPerPriceLot(sym) * Lot;                 // is lot par 1 price-unit = $k
   if(k <= 0){ SkipMsg(nm, ds, "tick value nahi mila"); return; }
   double sc = Lot/0.01;
   double tp01 = MathMin(TpMax_Usd, MathMax(TpMin_Usd, body * (k/sc) * TpBodyPct/100.0));
   tp01 = MathRound(tp01*100.0)/100.0;
   double tpUsd = tp01*sc, slUsd = SL_Usd*sc;
   double tpD = tpUsd/k, slD = slUsd/k;
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(ask <= 0 || bid <= 0){ SkipMsg(nm, ds, "bhaav nahi"); return; }
   double sprUsd = (ask-bid) * k / sc;
   if(MaxSpreadUsd > 0 && sprUsd > MaxSpreadUsd + 1e-9){ SkipMsg(nm, ds, "spread $"+DoubleToString(sprUsd,2)+" > $"+DoubleToString(MaxSpreadUsd,2)); return; }
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   double tpUse = MathMax(tpD, minD + pt), slUse = MathMax(slD, minD + pt);
   double px = (dir > 0 ? ask : bid);
   double tp = NormalizeDouble(dir > 0 ? px + tpUse : px - tpUse, dg);
   double sl = NormalizeDouble(dir > 0 ? px - slUse : px + slUse, dg);
   trade.SetTypeFillingBySymbol(sym);
   bool ok = (dir > 0 ? trade.Buy(Lot, sym, 0, sl, tp, key) : trade.Sell(Lot, sym, 0, sl, tp, key));
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
   {
      string m = "order nahi laga: "+IntegerToString((int)trade.ResultRetcode())+" "+trade.ResultRetcodeDescription();
      SkipMsg(nm, ds, m);
      if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" - "+m);
      return;
   }
   // asli bhaav se TP / SL dobara (paper jaisa: entry se TP ki doori)
   double fill = trade.ResultPrice();
   ulong posId = 0;
   if(SelectOur(sym))
   {
      posId = (ulong)PositionGetInteger(POSITION_TICKET);
      fill = PositionGetDouble(POSITION_PRICE_OPEN);
      double tp2 = NormalizeDouble(dir > 0 ? fill + tpUse : fill - tpUse, dg);
      double sl2 = NormalizeDouble(dir > 0 ? fill - slUse : fill + slUse, dg);
      if(MathAbs(tp2-tp) > pt/2 || MathAbs(sl2-sl) > pt/2) trade.PositionModify(posId, sl2, tp2);
   }
   int n = CountOpen();
   g_Last = nm+" "+ds+" khula @ "+DoubleToString(fill, dg)+" | TP $"+DoubleToString(tpUsd,2);
   Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", why);
   if(PushOn) SendNotification("CANDLE EA: "+nm+" "+ds+" khula | TP $"+DoubleToString(tpUsd,2)+" | "+IntegerToString(n)+"/"+IntegerToString(MaxOpen)+" chalu");
   long nextMs = 0;
   { long b0 = (long)iTime(sym, Per(g_Tf), 0); nextMs = (b0 - g_Off)*1000; }
   string js = "{\"id\":\""+key+"\",\"sym\":\""+JsonSafe(g_CfgPairs[idx])+"\",\"n\":\""+nm+"\",\"dir\":\""+ds+"\",\"tf\":"+IntegerToString(g_Tf)
      +",\"next\":"+IntegerToString(nextMs)+",\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"entry\":"+DoubleToString(fill, dg)
      +",\"tp\":"+DoubleToString(tpUsd,2)+",\"sl\":"+DoubleToString(slUsd,2)+",\"spread\":"+DoubleToString(sprUsd,2)
      +",\"lot\":"+DoubleToString(Lot,2)+",\"done\":false}";
   string resp; int code;
   Http("POST", FbUrl("ea/trades/"+key), js, "X-HTTP-Method-Override: PUT\r\n", resp, code);
}

//+------------------------------------------------------------------+
//| Chalu trade: BOOK / TIME (paper jaisa)                           |
//+------------------------------------------------------------------+
void SetWhy(ulong id, string w)
{
   int n = ArraySize(g_WhyId);
   for(int i=0;i<n;i++) if(g_WhyId[i]==id){ g_WhyTx[i] = w; return; }
   if(n >= 50){ for(int i=1;i<n;i++){ g_WhyId[i-1] = g_WhyId[i]; g_WhyTx[i-1] = g_WhyTx[i]; } n--; }
   ArrayResize(g_WhyId, n+1); ArrayResize(g_WhyTx, n+1);
   g_WhyId[n] = id; g_WhyTx[n] = w;
}
string GetWhy(ulong id)
{
   for(int i=0;i<ArraySize(g_WhyId);i++) if(g_WhyId[i]==id) return g_WhyTx[i];
   return "";
}
int MgIdx(ulong id)
{
   for(int i=0;i<ArraySize(g_MgId);i++) if(g_MgId[i]==id) return i;
   int n = ArraySize(g_MgId);
   ArrayResize(g_MgId, n+1); ArrayResize(g_MgBar, n+1);
   g_MgId[n] = id; g_MgBar[n] = 0;
   return n;
}
void MgClean()
{
   for(int i=ArraySize(g_MgId)-1;i>=0;i--)
   {
      if(PositionSelectByTicket(g_MgId[i])) continue;
      int n = ArraySize(g_MgId);
      for(int j=i+1;j<n;j++){ g_MgId[j-1] = g_MgId[j]; g_MgBar[j-1] = g_MgBar[j]; }
      ArrayResize(g_MgId, n-1); ArrayResize(g_MgBar, n-1);
   }
}
void Manage()
{
   static datetime lastClean = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      string sym = PositionGetString(POSITION_SYMBOL), key = PositionGetString(POSITION_COMMENT);
      int tf = TfFromKey(key), perSec = tf*60;
      ENUM_TIMEFRAMES per = Per(tf);
      datetime openT = (datetime)PositionGetInteger(POSITION_TIME);
      datetime entryBar = (datetime)((long)openT - (long)openT % perSec);
      datetime b0 = iTime(sym, per, 0);
      if(b0 <= 0) continue;
      int idx = (int)(((long)b0 - (long)entryBar)/perSec);   // abhi kaunsi candle (0 = entry wali)
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double sc = PositionGetDouble(POSITION_VOLUME)/0.01;
      int m = MgIdx(t);
      bool newBar = (g_MgBar[m] != 0 && b0 > g_MgBar[m]);
      if(g_MgBar[m] == 0) g_MgBar[m] = (idx > 0 ? b0 : entryBar);
      if(newBar)
      {
         g_MgBar[m] = b0;
         int holdMax = (tf == 5 ? HoldMax5 : HoldMax1);
         if(pl > 0.004*sc){ CloseIt(t, "PROFIT BOOK"); continue; }        // candle band hui fayde me
         if(idx >= holdMax){ CloseIt(t, "TIME"); continue; }               // itni candle ho gayi
      }
      if(idx >= 1 && pl >= Book_Usd*sc){ CloseIt(t, "PROFIT BOOK"); continue; }   // dusri candle se +$0.05
   }
   if(TimeLocal() - lastClean >= 60){ lastClean = TimeLocal(); MgClean(); }
}
void CloseIt(ulong t, string why)
{
   SetWhy(t, why);
   if(!trade.PositionClose(t))
      Print("SAMUSIGNAL CANDLE EA: band nahi hua (", why, "): ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| Trade band -> Firebase + push                                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &tr, const MqlTradeRequest &rq, const MqlTradeResult &rs)
{
   if(tr.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(tr.deal)) return;
   if(HistoryDealGetInteger(tr.deal, DEAL_MAGIC) != Magic) return;
   long en = HistoryDealGetInteger(tr.deal, DEAL_ENTRY);
   if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_OUT_BY) return;
   double pl = HistoryDealGetDouble(tr.deal, DEAL_PROFIT) + HistoryDealGetDouble(tr.deal, DEAL_SWAP) + HistoryDealGetDouble(tr.deal, DEAL_COMMISSION);
   string sym = HistoryDealGetString(tr.deal, DEAL_SYMBOL);
   ulong  pid = (ulong)HistoryDealGetInteger(tr.deal, DEAL_POSITION_ID);
   long   rsn = HistoryDealGetInteger(tr.deal, DEAL_REASON);
   datetime outT = (datetime)HistoryDealGetInteger(tr.deal, DEAL_TIME);
   double   outP = HistoryDealGetDouble(tr.deal, DEAL_PRICE);
   string res = GetWhy(pid);
   if(rsn == DEAL_REASON_TP) res = "TP";
   else if(rsn == DEAL_REASON_SL) res = "SL";
   else if(res == "") res = "BAND (haath / dusra)";
   // entry wala deal: key (comment), dir, samay
   string key = "", ds = "";
   datetime inT = 0;
   if(HistorySelectByPosition(pid))
   {
      for(int i=0;i<HistoryDealsTotal();i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d==0 || HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
         key = HistoryDealGetString(d, DEAL_COMMENT);
         ds  = (HistoryDealGetInteger(d, DEAL_TYPE) == DEAL_TYPE_BUY ? "BUY" : "SELL");
         inT = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      }
   }
   int tf = TfFromKey(key), perSec = tf*60;
   int nC = (inT > 0 ? (int)(((long)outT - ((long)inT - (long)inT % perSec))/perSec) + 1 : 0);
   DayStats();
   string nm = Name6(sym);
   g_Last = nm+" "+ds+" "+res+" "+(pl>=0?"+":"")+DoubleToString(pl,2)+"$";
   Print("SAMUSIGNAL CANDLE EA: ", g_Last, " | ", nC, " candle | aaj ", DoubleToString(g_DayPl,2), "$");
   if(PushOn) SendNotification("CANDLE EA: "+g_Last+" | "+IntegerToString(nC)+" candle | aaj "+(g_DayPl>=0?"+":"")+DoubleToString(g_DayPl,2)+"$ ("+IntegerToString(g_DayW)+"/"+IntegerToString(g_DayL)+")");
   if(key != "" && StringGetCharacter(key, 0) == 'c')
   {
      string body = "{\"done\":true,\"res\":\""+JsonSafe(res)+"\",\"pl\":"+DoubleToString(pl,2)+",\"exitT\":"+IntegerToString(((long)outT - g_Off)*1000)
         +",\"cn\":"+IntegerToString(nC)+",\"exit\":"+DoubleToString(outP, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS))+"}";
      string resp; int code;
      Http("POST", FbUrl("ea/trades/"+key), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code);
   }
   PublishState();
}
string Name6(string sym){ string u = sym; StringToUpper(u); return StringSubstr(u, 0, 6); }

//+------------------------------------------------------------------+
//| Din ka hisaab (server din)                                       |
//+------------------------------------------------------------------+
void DayStats()
{
   long ns = (long)TimeTradeServer();
   datetime now = (datetime)ns, d0 = (datetime)(ns - ns % 86400);
   g_DayPl = 0; g_DayW = 0; g_DayL = 0;
   if(!HistorySelect(d0, now + 3600)) return;
   int n = HistoryDealsTotal();
   for(int i=0;i<n;i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d==0 || HistoryDealGetInteger(d, DEAL_MAGIC)!=Magic) continue;
      double pr = HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
      g_DayPl += pr;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY){ if(pr < 0) g_DayL++; else g_DayW++; }
   }
}

//+------------------------------------------------------------------+
//| App ke liye halat                                                |
//+------------------------------------------------------------------+
string StopWhy()
{
   if(g_Real && !AllowReal) return "REAL account - AllowReal=false";
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return "MT5 me Algo Trading band";
   if(DayTargetUsd > 0 && g_DayPl >= DayTargetUsd) return "aaj ka target poora";
   if(DayLossUsd > 0 && g_DayPl <= -DayLossUsd) return "aaj ki ghata seema";
   if(!g_CfgOk) return "app settings nahi mili";
   return "";
}
void PublishState()
{
   string open = "[";
   int op = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      open += (op ? "," : "") + "{\"n\":\""+Name6(sym)+"\",\"dir\":\""+(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "BUY" : "SELL")+"\",\"pl\":"+DoubleToString(pl,2)
            +",\"key\":\""+JsonSafe(PositionGetString(POSITION_COMMENT))+"\"}";
      op++;
   }
   open += "]";
   string pairs = "[";
   for(int i=0;i<ArraySize(g_Names);i++) pairs += (i ? "," : "") + "\""+g_Names[i]+(g_Syms[i]=="" ? "?" : "")+"\"";
   pairs += "]";
   string sw = StopWhy();
   string body = "{\"t\":"+IntegerToString((long)TimeGMT())+",\"v\":\""+VER+"\",\"tf\":"+IntegerToString(g_Tf)+",\"pairs\":"+pairs
      +",\"open\":"+IntegerToString(op)+",\"max\":"+IntegerToString(MaxOpen)+",\"list\":"+open
      +",\"dayPl\":"+DoubleToString(g_DayPl,2)+",\"dayW\":"+IntegerToString(g_DayW)+",\"dayL\":"+IntegerToString(g_DayL)
      +",\"bal\":"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+",\"eq\":"+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)
      +",\"demo\":"+(g_Real ? "false" : "true")+",\"stop\":\""+JsonSafe(sw)+"\",\"last\":\""+JsonSafe(g_Last)+"\",\"skip\":\""+JsonSafe(g_LastSkip)+"\"}";
   string resp; int code;
   Http("POST", FbUrl("ea/state"), body, "X-HTTP-Method-Override: PUT\r\n", resp, code);
}

//+------------------------------------------------------------------+
//| Chart par haal (bade hare akshar)                                |
//+------------------------------------------------------------------+
void Line(int row, string txt, color c)
{
   string nm = LBL+IntegerToString(row);
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, 10);
      ObjectSetString(0, nm, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, 20 + row*(int)(FontPx*1.9));
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, FontPx);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetString(0, nm, OBJPROP_TEXT, txt);
}
void Panel()
{
   if(!PanelOn) return;
   color G = C'134,239,172', W = clrWhite, Y = C'232,195,90', R = C'255,93,108';
   int row = 0;
   string sw = StopWhy();
   Line(row++, "SAMUSIGNAL CANDLE EA v"+VER+"  |  "+(g_Real ? "REAL" : "DEMO")+"  |  "+(sw=="" ? "CHALU" : "RUKA: "+sw), sw=="" ? G : R);
   string pl = "";
   for(int i=0;i<ArraySize(g_Names);i++) pl += (i ? " " : "") + g_Names[i] + (g_Syms[i]=="" ? "(?)" : "");
   Line(row++, "App ke pair ("+IntegerToString(g_Tf)+" MIN): "+(pl=="" ? "koi ON nahi" : pl), W);
   Line(row++, "Chalu: "+IntegerToString(CountOpen())+" / "+IntegerToString(MaxOpen)+"   |   Aaj: "+(g_DayPl>=0?"+$":"-$")+DoubleToString(MathAbs(g_DayPl),2)
        +" ("+IntegerToString(g_DayW)+" jeet / "+IntegerToString(g_DayL)+" haar)   |   Balance $"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2), g_DayPl >= 0 ? G : R);
   Line(row++, "TP body "+DoubleToString(TpBodyPct,0)+"% ($"+DoubleToString(TpMin_Usd,2)+"-"+DoubleToString(TpMax_Usd,2)+")  |  SL $"+DoubleToString(SL_Usd,2)
        +"  |  BOOK +$"+DoubleToString(Book_Usd,2)+"  |  lot "+DoubleToString(Lot,2), G);
   for(int i=PositionsTotal()-1;i>=0 && row < 10;i--)
   {
      ulong t = PositionGetTicket(i);
      if(t==0 || PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      string sym = PositionGetString(POSITION_SYMBOL), key = PositionGetString(POSITION_COMMENT);
      int tf = TfFromKey(key), perSec = tf*60;
      datetime openT = (datetime)PositionGetInteger(POSITION_TIME);
      datetime b0 = iTime(sym, Per(tf), 0);
      int idx = (b0 > 0 ? (int)(((long)b0 - ((long)openT - (long)openT % perSec))/perSec) + 1 : 0);
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      Line(row++, "  > "+Name6(sym)+" "+(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "BUY" : "SELL")+"   "+(p>=0?"+$":"-$")+DoubleToString(MathAbs(p),2)
           +"   candle "+IntegerToString(idx)+"/"+IntegerToString(tf==5 ? HoldMax5 : HoldMax1), p >= 0 ? G : Y);
   }
   Line(row++, "Aakhri: "+g_Last, W);
   Line(row++, "Aakhri SKIP: "+g_LastSkip, Y);
   Line(row++, "Firebase: "+(g_FbOk ? "OK" : "nahi")+"  |  app settings "+(g_CfgOk ? IntegerToString((int)(TimeLocal()-g_CfgAt))+" sec purani" : "nahi mili")+"  |  "+g_Status, g_FbOk ? G : R);
   for(int k=row;k<14;k++){ string nm = LBL+IntegerToString(k); if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm); }
   ChartRedraw();
}
//+------------------------------------------------------------------+
