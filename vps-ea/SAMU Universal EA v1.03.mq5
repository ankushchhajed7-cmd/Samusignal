//+------------------------------------------------------------------+
//|                                    SAMU Universal EA v1.03.mq5   |
//|  Reads a SAMU strategy JSON (schema samu-strategy/1) and trades  |
//|  it with the same rules as SAMU Backtest Lab                     |
//|  (docs/ENGINE-RULES.md). Gold Luxe full-screen dashboard.        |
//+------------------------------------------------------------------+
#property copyright   "SAMU"
#property version     "1.03"
#property description "SAMU Universal EA: JSON strategy (MQL5\\Files), Supertrend first trade, step grid basket, lot table, basket TP/SL/trailing, daily target/loss, 07:00 IST reset."
#property tester_file "step-basket.json"

#include <Trade\Trade.mqh>

//--- inputs
input bool   InpLiveTrading    = false;              // false = PAPER (virtual trades, broker ko order nahi); true = asli trade
input string InpStrategyFile   = "step-basket.json"; // Strategy JSON (MQL5\Files)
input bool   InpCommonFolder   = false;              // JSON in Common\Files?
input string InpPreset         = "";                 // Basket preset override (blank = JSON preset)
input long   InpMagic          = 770100;             // Magic number
input int    InpSlippagePts    = 50;                 // Max slippage (points)
input int    InpSTBars         = 600;                // Supertrend history bars
input bool   InpDashboard      = true;               // Gold Luxe dashboard
input bool   InpHidePriceChart = true;               // Hide price chart behind dashboard
input bool   InpLogTrades      = true;               // Trade log CSV (for Parity)
input bool   InpOwnMode        = true;               // Own P/L mode: daily % + basket SL sirf is EA ke trades se
input double InpAllocBalance   = 1000;               // Own mode: daily % / basket SL % ka base ($)
input datetime InpAllocFrom    = 0;                  // Own mode: realized P/L kab se gine (0 = pehli baar chalne se)
input double InpMinMarginLevel = 300;                // Nayi trade tabhi jab margin level >= ye % (0 = off)

#define EA_NAME    "SAMU Universal EA"
#define EA_VERSION "v1.03"
#define PFX        "SAMUUEA_"
#define IST_SEC    19800

//====================================================================
//  JSON
//====================================================================
enum JType { J_NULL, J_BOOL, J_NUM, J_STR, J_ARR, J_OBJ };

class JNode
  {
public:
   JType             type;
   string            key;
   string            s;
   double            num;
   bool              b;
   JNode            *kids[];
                     JNode() { type = J_NULL; num = 0; b = false; key = ""; s = ""; }
                    ~JNode()
     {
      for(int i = 0; i < ArraySize(kids); i++)
         if(CheckPointer(kids[i]) == POINTER_DYNAMIC) delete kids[i];
     }
   void              Add(JNode *k) { int z = ArraySize(kids); ArrayResize(kids, z + 1); kids[z] = k; }
   int               Size() { return ArraySize(kids); }
   JNode            *At(int i) { if(i < 0 || i >= ArraySize(kids)) return NULL; return kids[i]; }
   JNode            *Get(const string k)
     {
      for(int i = 0; i < ArraySize(kids); i++) if(kids[i].key == k) return kids[i];
      return NULL;
     }
  };

int HexVal(const ushort c)
  {
   if(c >= '0' && c <= '9') return c - '0';
   if(c >= 'a' && c <= 'f') return c - 'a' + 10;
   if(c >= 'A' && c <= 'F') return c - 'A' + 10;
   return 0;
  }

class JParser
  {
private:
   string            m_t;
   int               m_p;
   int               m_n;
   ushort            Ch() { return (m_p < m_n) ? StringGetCharacter(m_t, m_p) : 0; }
   void              Ws()
     {
      while(m_p < m_n)
        {
         ushort c = Ch();
         if(c == ' ' || c == '\t' || c == '\r' || c == '\n') m_p++;
         else break;
        }
     }
   bool              Str(string &out)
     {
      m_p++; out = "";
      int seg = m_p;
      while(m_p < m_n)
        {
         ushort c = Ch();
         if(c == '"') { out += StringSubstr(m_t, seg, m_p - seg); m_p++; return true; }
         if(c == '\\')
           {
            out += StringSubstr(m_t, seg, m_p - seg);
            m_p++;
            ushort e = Ch();
            if(e == 'n') out += "\n";
            else if(e == 't') out += "\t";
            else if(e == 'r') out += "\r";
            else if(e == 'u')
              {
               int v = 0;
               for(int k = 1; k <= 4; k++) v = v * 16 + HexVal(StringGetCharacter(m_t, m_p + k));
               out += ShortToString((ushort)v);
               m_p += 4;
              }
            else out += ShortToString(e);
            m_p++; seg = m_p;
            continue;
           }
         m_p++;
        }
      err = "string band nahi hui";
      return false;
     }
   JNode            *Num()
     {
      int st = m_p;
      while(m_p < m_n)
        {
         ushort c = Ch();
         if((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E') m_p++;
         else break;
        }
      JNode *n = new JNode();
      n.type = J_NUM;
      n.num = StringToDouble(StringSubstr(m_t, st, m_p - st));
      return n;
     }
   JNode            *Obj()
     {
      m_p++;
      JNode *o = new JNode(); o.type = J_OBJ;
      Ws();
      if(Ch() == '}') { m_p++; return o; }
      while(m_p < m_n)
        {
         Ws();
         if(Ch() != '"') { err = StringFormat("key expected at %d", m_p); delete o; return NULL; }
         string k;
         if(!Str(k)) { delete o; return NULL; }
         Ws();
         if(Ch() != ':') { err = StringFormat("':' expected at %d", m_p); delete o; return NULL; }
         m_p++;
         JNode *v = Value();
         if(v == NULL) { delete o; return NULL; }
         v.key = k; o.Add(v);
         Ws();
         ushort c = Ch();
         if(c == ',') { m_p++; continue; }
         if(c == '}') { m_p++; return o; }
         err = StringFormat("',' ya '}' expected at %d", m_p); delete o; return NULL;
        }
      err = "object band nahi hua"; delete o; return NULL;
     }
   JNode            *Arr()
     {
      m_p++;
      JNode *a = new JNode(); a.type = J_ARR;
      Ws();
      if(Ch() == ']') { m_p++; return a; }
      while(m_p < m_n)
        {
         JNode *v = Value();
         if(v == NULL) { delete a; return NULL; }
         a.Add(v);
         Ws();
         ushort c = Ch();
         if(c == ',') { m_p++; continue; }
         if(c == ']') { m_p++; return a; }
         err = StringFormat("',' ya ']' expected at %d", m_p); delete a; return NULL;
        }
      err = "array band nahi hua"; delete a; return NULL;
     }
public:
   string            err;
   JNode            *Value()
     {
      Ws();
      ushort c = Ch();
      if(c == '{') return Obj();
      if(c == '[') return Arr();
      if(c == '"') { string s; if(!Str(s)) return NULL; JNode *n = new JNode(); n.type = J_STR; n.s = s; return n; }
      if(c == 't' && StringSubstr(m_t, m_p, 4) == "true")  { m_p += 4; JNode *n = new JNode(); n.type = J_BOOL; n.b = true;  return n; }
      if(c == 'f' && StringSubstr(m_t, m_p, 5) == "false") { m_p += 5; JNode *n = new JNode(); n.type = J_BOOL; n.b = false; return n; }
      if(c == 'n' && StringSubstr(m_t, m_p, 4) == "null")  { m_p += 4; JNode *n = new JNode(); n.type = J_NULL; return n; }
      if(c == '-' || (c >= '0' && c <= '9')) return Num();
      err = StringFormat("galat character at %d", m_p);
      return NULL;
     }
   JNode            *Parse(const string text)
     {
      m_t = text; m_p = 0; m_n = StringLen(text); err = "";
      JNode *r = Value();
      if(r == NULL) return NULL;
      Ws();
      if(m_p < m_n) { err = StringFormat("extra data at %d", m_p); delete r; return NULL; }
      return r;
     }
  };

JNode *JP(JNode *r, const string path)
  {
   string parts[];
   int k = StringSplit(path, '.', parts);
   JNode *c = r;
   for(int i = 0; i < k; i++)
     {
      if(c == NULL || c.type != J_OBJ) return NULL;
      c = c.Get(parts[i]);
     }
   return c;
  }
bool   JHas(JNode *r, const string path) { JNode *n = JP(r, path); return (n != NULL && n.type != J_NULL); }
double JNum(JNode *r, const string path, const double def, const bool req, string &err)
  {
   JNode *n = JP(r, path);
   if(n == NULL || n.type == J_NULL) { if(req) err += path + " missing; "; return def; }
   if(n.type == J_NUM) return n.num;
   if(n.type == J_BOOL) return n.b ? 1.0 : 0.0;
   err += path + " number nahi; ";
   return def;
  }
bool   JBool(JNode *r, const string path, const bool def)
  {
   JNode *n = JP(r, path);
   if(n == NULL || n.type == J_NULL) return def;
   if(n.type == J_BOOL) return n.b;
   if(n.type == J_NUM) return n.num != 0;
   return def;
  }
string JStr(JNode *r, const string path, const string def)
  {
   JNode *n = JP(r, path);
   if(n == NULL || n.type != J_STR) return def;
   return n.s;
  }

//====================================================================
//  CONFIG (filled from JSON)
//====================================================================
string  g_name, g_ver, g_cfgSymbol, g_tf, g_preset, g_cfgSource = "";
double  g_cs, g_point, g_off;
ENUM_TIMEFRAMES g_tfEnum;
int     g_atrP, g_warm, g_maxT, g_resetSec, g_maxSpread, g_tFrom, g_tTo;
double  g_mult, g_tp1, g_step, g_tpUsd, g_slPct, g_trStart, g_trDrop, g_dTgt, g_dLoss, g_comm;
bool    g_atrRma, g_closedBar, g_tp1On, g_sameSide, g_buyAbove, g_sellBelow, g_tpOn, g_slOn, g_trailOn, g_timeOn;
int     g_lotFrom[], g_lotTo[];
double  g_lotVal[];

ENUM_TIMEFRAMES TfFromStr(const string s)
  {
   if(s == "M1") return PERIOD_M1;   if(s == "M5") return PERIOD_M5;   if(s == "M15") return PERIOD_M15;
   if(s == "M30") return PERIOD_M30; if(s == "H1") return PERIOD_H1;   if(s == "H4") return PERIOD_H4;
   if(s == "D1") return PERIOD_D1;
   return PERIOD_CURRENT;
  }
int HhmmToMin(const string s)
  {
   string p[];
   if(StringSplit(s, ':', p) < 2) return -1;
   return (int)StringToInteger(p[0]) * 60 + (int)StringToInteger(p[1]);
  }

//--- built-in copy of strategies/step-basket.json (used when the JSON file is missing,
//--- e.g. EA deployed by VPS Helper which copies only .mq5). Kept in sync by tests/ea-config.test.js
string BuiltinStrategy()
  {
   string s = "";
   s += "{\"schema\":\"samu-strategy/1\",\"name\":\"Step Basket\",\"version\":\"1.0.0\",\"notes\":\"Supertrend sirf peh";
   s += "le trade ki direction. Uske baad $5 step grid dono taraf. Basket preset A/B/C.\",\"symbol\":\"XAUUSDm\",\"cont";
   s += "ract_size\":100,\"point\":0.001,\"server_gmt_offset_hours\":0,\"entry\":{\"type\":\"supertrend\",\"tf\":\"M15";
   s += "\",\"atr_period\":10,\"multiplier\":3.0,\"atr_method\":\"sma\",\"use_closed_bar\":true,\"warmup_bars\":50,\"ope";
   s += "n_on\":\"new_m1_bar\",\"role\":\"first_trade_direction\"},\"first_trade\":{\"tp_price\":5.0,\"remove_tp_on_sec";
   s += "ond_trade\":true,\"grid_same_side_while_tp\":false},\"grid\":{\"step_price\":5.0,\"sell_below_lowest\":true,\"";
   s += "buy_above_highest\":true,\"max_trades\":12,\"after_max\":\"wait_tp_sl\"},\"lots\":[{\"from\":1,\"to\":3,\"lot";
   s += "\":0.01},{\"from\":4,\"to\":6,\"lot\":0.02},{\"from\":7,\"to\":9,\"lot\":0.03},{\"from\":10,\"to\":12,\"lot\":0";
   s += ".04}],\"basket\":{\"preset\":\"B\",\"sl_base\":\"balance_at_basket_start\",\"presets\":{\"A\":{\"tp_usd\":10,";
   s += "\"sl_pct_balance\":null,\"trail\":null},\"B\":{\"tp_usd\":null,\"sl_pct_balance\":1.0,\"trail\":{\"start_usd\":";
   s += "10,\"drop_usd\":5}},\"C\":{\"tp_usd\":10,\"sl_pct_balance\":1.0,\"trail\":null}}},\"daily\":{\"target_pct\":1.";
   s += "0,\"loss_pct\":5.0,\"base\":\"day_start_equity\",\"reset_time\":\"07:00\",\"tz\":\"IST\",\"on_hit\":\"close_al";
   s += "l_stop_day\",\"open_basket_at_reset\":\"keep\"},\"costs\":{\"commission_per_lot\":0,\"swap\":false},\"filters";
   s += "\":{\"max_spread_points\":0,\"time\":{\"enabled\":false,\"from\":\"00:00\",\"to\":\"23:59\",\"tz\":\"IST\"},\"n";
   s += "ews\":{\"enabled\":false,\"before_min\":30,\"after_min\":30}}}";
   return s;
  }

bool LoadConfig(string &err)
  {
   err = "";
   int flags = FILE_READ | FILE_BIN | (InpCommonFolder ? FILE_COMMON : 0);
   int h = FileOpen(InpStrategyFile, flags);
   string txt = "";
   if(h == INVALID_HANDLE)
     {
      txt = BuiltinStrategy();
      g_cfgSource = "built-in";
     }
   else
     {
      int sz = (int)FileSize(h);
      uchar buf[];
      ArrayResize(buf, sz);
      FileReadArray(h, buf, 0, sz);
      FileClose(h);
      txt = CharArrayToString(buf, 0, sz, CP_UTF8);
      g_cfgSource = "file";
     }
   if(StringLen(txt) > 0 && StringGetCharacter(txt, 0) == 0xFEFF) txt = StringSubstr(txt, 1);

   JParser parser;
   JNode *root = parser.Parse(txt);
   if(root == NULL) { err = "JSON error: " + parser.err; return false; }

   if(JStr(root, "schema", "") != "samu-strategy/1") err += "schema samu-strategy/1 nahi; ";
   g_name      = JStr(root, "name", "?");
   g_ver       = JStr(root, "version", "?");
   g_cfgSymbol = JStr(root, "symbol", "");
   g_cs        = JNum(root, "contract_size", 100, true, err);
   g_point     = JNum(root, "point", _Point, false, err);
   g_off       = JNum(root, "server_gmt_offset_hours", 0, false, err);

   if(JStr(root, "entry.type", "") != "supertrend") err += "entry.type: v1.00 sirf supertrend; ";
   g_tf        = JStr(root, "entry.tf", "M15");
   g_tfEnum    = TfFromStr(g_tf);
   if(g_tfEnum == PERIOD_CURRENT) err += "entry.tf galat; ";
   g_atrP      = (int)JNum(root, "entry.atr_period", 10, true, err);
   g_mult      = JNum(root, "entry.multiplier", 3.0, true, err);
   g_atrRma    = (JStr(root, "entry.atr_method", "sma") == "rma");
   g_closedBar = JBool(root, "entry.use_closed_bar", true);
   g_warm      = (int)JNum(root, "entry.warmup_bars", 50, false, err);

   g_tp1On     = JHas(root, "first_trade.tp_price");
   g_tp1       = JNum(root, "first_trade.tp_price", 0, false, err);
   g_sameSide  = JBool(root, "first_trade.grid_same_side_while_tp", false);

   g_step      = JNum(root, "grid.step_price", 5, true, err);
   g_maxT      = (int)JNum(root, "grid.max_trades", 12, true, err);
   g_buyAbove  = JBool(root, "grid.buy_above_highest", true);
   g_sellBelow = JBool(root, "grid.sell_below_lowest", true);

   // lots
   JNode *lots = JP(root, "lots");
   ArrayResize(g_lotFrom, 0); ArrayResize(g_lotTo, 0); ArrayResize(g_lotVal, 0);
   if(lots == NULL || lots.type != J_ARR || lots.Size() == 0) err += "lots table khaali; ";
   else
     {
      int n = lots.Size();
      ArrayResize(g_lotFrom, n); ArrayResize(g_lotTo, n); ArrayResize(g_lotVal, n);
      for(int i = 0; i < n; i++)
        {
         JNode *r = lots.At(i);
         g_lotFrom[i] = (int)JNum(r, "from", 0, true, err);
         g_lotTo[i]   = (int)JNum(r, "to", 0, true, err);
         g_lotVal[i]  = JNum(r, "lot", 0, true, err);
        }
      // sort by from (small n)
      for(int i = 0; i < n; i++)
         for(int j = i + 1; j < n; j++)
            if(g_lotFrom[j] < g_lotFrom[i])
              {
               int a = g_lotFrom[i]; g_lotFrom[i] = g_lotFrom[j]; g_lotFrom[j] = a;
               int b = g_lotTo[i];   g_lotTo[i]   = g_lotTo[j];   g_lotTo[j]   = b;
               double c = g_lotVal[i]; g_lotVal[i] = g_lotVal[j]; g_lotVal[j] = c;
              }
      int expect = 1;
      for(int i = 0; i < n; i++)
        {
         if(g_lotFrom[i] != expect) err += StringFormat("lots: trade %d missing/overlap; ", expect);
         if(g_lotVal[i] <= 0) err += "lots: lot > 0 chahiye; ";
         expect = g_lotTo[i] + 1;
        }
      if(expect - 1 < g_maxT) err += StringFormat("lots sirf trade %d tak, max_trades %d; ", expect - 1, g_maxT);
     }

   // preset
   g_preset = (InpPreset != "") ? InpPreset : JStr(root, "basket.preset", "");
   string pp = "basket.presets." + g_preset;
   if(JP(root, pp) == NULL) err += "preset '" + g_preset + "' JSON mein nahi; ";
   g_tpOn    = JHas(root, pp + ".tp_usd");
   g_tpUsd   = JNum(root, pp + ".tp_usd", 0, false, err);
   g_slOn    = JHas(root, pp + ".sl_pct_balance");
   g_slPct   = JNum(root, pp + ".sl_pct_balance", 0, false, err);
   g_trailOn = JHas(root, pp + ".trail");
   g_trStart = JNum(root, pp + ".trail.start_usd", 0, g_trailOn, err);
   g_trDrop  = JNum(root, pp + ".trail.drop_usd", 0, g_trailOn, err);

   g_dTgt    = JNum(root, "daily.target_pct", 0, false, err);
   g_dLoss   = JNum(root, "daily.loss_pct", 0, false, err);
   int rm    = HhmmToMin(JStr(root, "daily.reset_time", "07:00"));
   if(rm < 0) err += "daily.reset_time galat; ";
   g_resetSec = MathMax(rm, 0) * 60;

   g_comm      = JNum(root, "costs.commission_per_lot", 0, false, err);
   g_maxSpread = (int)JNum(root, "filters.max_spread_points", 0, false, err);
   g_timeOn    = JBool(root, "filters.time.enabled", false);
   g_tFrom     = HhmmToMin(JStr(root, "filters.time.from", "00:00"));
   g_tTo       = HhmmToMin(JStr(root, "filters.time.to", "23:59"));

   delete root;
   return (err == "");
  }

int LotIndexFor(const int k)
  {
   int n = ArraySize(g_lotVal);
   for(int i = 0; i < n; i++) if(k >= g_lotFrom[i] && k <= g_lotTo[i]) return i;
   return n - 1;
  }
double NormLot(double v)
  {
   double st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP), mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(st <= 0) st = 0.01;
   v = MathFloor(v / st + 0.5) * st;
   v = MathMax(mn, MathMin(mx, v));
   return NormalizeDouble(v, 2);
  }

//====================================================================
//  STATE
//====================================================================
CTrade  trade;
bool    g_ready = false;
string  g_cfgErr = "";
string  g_warnMsg = "";
datetime g_since = 0;          // own mode: realized P/L start
double  g_realized = 0;        // own mode: closed P/L of this EA since g_since
bool    g_realDirty = true;
long    g_basketId = 0;
int     g_firstDir = 0;
bool    g_tpActive = false;     // first-trade TP still on
double  g_peak = -1e18;
double  g_bMin = 0;
double  g_bStartBal = 0;
long    g_dayKey = -1;
double  g_dayStartEq = 0;
bool    g_dayStopped = false;
string  g_dayStopReason = "";
bool    g_paused = false;
datetime g_lastBar = 0;
int     g_sig = 0;
string  g_closeReason = "";
string  g_lastErr = "";
datetime g_lastErrT = 0;
uint    g_lastDash = 0;

string GVN(const string k) { return PFX + _Symbol + "_" + (string)InpMagic + "_" + k; }
void   GVSet(const string k, const double v) { GlobalVariableSet(GVN(k), v); }
double GVGet(const string k, const double def) { return GlobalVariableCheck(GVN(k)) ? GlobalVariableGet(GVN(k)) : def; }

void SaveState()
  {
   GVSet("basketId", (double)g_basketId);
   GVSet("firstDir", g_firstDir);
   GVSet("tpActive", g_tpActive ? 1 : 0);
   GVSet("peak", g_peak);
   GVSet("bMin", g_bMin);
   GVSet("bStartBal", g_bStartBal);
   GVSet("dayKey", (double)g_dayKey);
   GVSet("dayStartEq", g_dayStartEq);
   GVSet("dayStopped", g_dayStopped ? (g_dayStopReason == "DAY_TARGET" ? 1 : 2) : 0);
   GVSet("paused", g_paused ? 1 : 0);
  }

//====================================================================
//  TIME
//====================================================================
datetime NowServer() { return MQLInfoInteger(MQL_TESTER) ? TimeCurrent() : TimeTradeServer(); }
datetime ToIst(const datetime srv) { return (datetime)((long)srv - (long)(g_off * 3600) + IST_SEC); }
long     DayKeyOf(const datetime srv) { return (long)MathFloor(((double)srv - g_off * 3600.0 + IST_SEC - g_resetSec) / 86400.0); }
string   TStr(const datetime t, const bool sec = false)
  {
   string s = TimeToString(t, TIME_DATE | TIME_MINUTES | (sec ? TIME_SECONDS : 0));
   StringReplace(s, ".", "-");
   return s;
  }
bool TimeOk(const datetime srv)
  {
   if(!g_timeOn) return true;
   long m = (((long)ToIst(srv) % 86400) + 86400) % 86400 / 60;
   if(g_tFrom <= g_tTo) return (m >= g_tFrom && m <= g_tTo);
   return (m >= g_tFrom || m <= g_tTo);
  }

//====================================================================
//  SUPERTREND (same formula as the app)
//====================================================================
int SupertrendSignal()
  {
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int n = CopyRates(_Symbol, g_tfEnum, 0, InpSTBars, r);
   if(n < g_atrP + 2) return 0;
   double tr[], atr[];
   ArrayResize(tr, n); ArrayResize(atr, n);
   double sum = 0;
   for(int i = 0; i < n; i++)
     {
      tr[i] = (i == 0) ? r[i].high - r[i].low
              : MathMax(r[i].high - r[i].low, MathMax(MathAbs(r[i].high - r[i - 1].close), MathAbs(r[i].low - r[i - 1].close)));
      atr[i] = EMPTY_VALUE;
      if(g_atrRma)
        {
         if(i < g_atrP) { sum += tr[i]; if(i == g_atrP - 1) atr[i] = sum / g_atrP; }
         else atr[i] = (atr[i - 1] * (g_atrP - 1) + tr[i]) / g_atrP;
        }
      else
        {
         sum += tr[i];
         if(i >= g_atrP) sum -= tr[i - g_atrP];
         if(i >= g_atrP - 1) atr[i] = sum / g_atrP;
        }
     }
   // last CLOSED bar = n-2 (n-1 is still forming)
   int last = g_closedBar ? n - 2 : n - 1;
   double fu = 0, fd = 0; int t = 0; bool ready = false;
   for(int i = 0; i <= last; i++)
     {
      if(atr[i] == EMPTY_VALUE) continue;
      double hl2 = (r[i].high + r[i].low) / 2.0, up = hl2 - g_mult * atr[i], dn = hl2 + g_mult * atr[i];
      if(!ready) { fu = up; fd = dn; t = 1; ready = true; continue; }
      double nfu = (r[i - 1].close > fu) ? MathMax(up, fu) : up;
      double nfd = (r[i - 1].close < fd) ? MathMin(dn, fd) : dn;
      if(t == -1 && r[i].close > fd) t = 1;
      else if(t == 1 && r[i].close < fu) t = -1;
      fu = nfu; fd = nfd;
     }
   if(!ready || last < g_warm) return 0;
   return t;
  }

//====================================================================
//  POSITIONS
//====================================================================
bool IsMine()
  {
   return (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic);
  }

//--- PAPER mode: virtual positions (broker ko koi order nahi). Strategy Tester mein hamesha asli (simulated) orders.
struct VPos { long id; int dir; double lot; double op; datetime ot; };
VPos   g_vp[];
long   g_vpNext = 1;
double g_paperReal = 0;        // paper: band virtual trades ka P/L (since g_since)
bool   Paper() { return !InpLiveTrading && !MQLInfoInteger(MQL_TESTER); }

double VProfit(const int i, const double bid, const double ask)
  {
   double close = (g_vp[i].dir == 1) ? bid : ask, pr = 0;
   if(!OrderCalcProfit(g_vp[i].dir == 1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, g_vp[i].lot, g_vp[i].op, close, pr))
      pr = g_vp[i].dir * (close - g_vp[i].op) * g_vp[i].lot * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   return pr - g_comm * g_vp[i].lot;
  }
void SaveVP()
  {
   int n = ArraySize(g_vp);
   GVSet("vp_n", n); GVSet("vp_next", (double)g_vpNext); GVSet("paperReal", g_paperReal);
   for(int i = 0; i < n; i++)
     {
      string k = "vp" + (string)i + "_";
      GVSet(k + "id", (double)g_vp[i].id); GVSet(k + "dir", g_vp[i].dir); GVSet(k + "lot", g_vp[i].lot);
      GVSet(k + "op", g_vp[i].op); GVSet(k + "ot", (double)g_vp[i].ot);
     }
  }
void LoadVP()
  {
   int n = (int)GVGet("vp_n", 0);
   g_vpNext = (long)GVGet("vp_next", 1);
   g_paperReal = GVGet("paperReal", 0);
   ArrayResize(g_vp, n);
   for(int i = 0; i < n; i++)
     {
      string k = "vp" + (string)i + "_";
      g_vp[i].id = (long)GVGet(k + "id", 0); g_vp[i].dir = (int)GVGet(k + "dir", 1); g_vp[i].lot = GVGet(k + "lot", 0.01);
      g_vp[i].op = GVGet(k + "op", 0); g_vp[i].ot = (datetime)GVGet(k + "ot", 0);
     }
  }
int RealCount()
  {
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) > 0 && IsMine()) c++;
   return c;
  }

int CountPos()
  {
   if(Paper()) return ArraySize(g_vp);
   return RealCount();
  }
double BasketPL()
  {
   double pl = 0;
   if(Paper())
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      for(int i = 0; i < ArraySize(g_vp); i++) pl += VProfit(i, bid, ask);
      return pl;
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) > 0 && IsMine())
         pl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) - g_comm * PositionGetDouble(POSITION_VOLUME);
   return pl;
  }
void EntryRange(double &mx, double &mn)
  {
   mx = -DBL_MAX; mn = DBL_MAX;
   if(Paper())
     {
      for(int i = 0; i < ArraySize(g_vp); i++) { if(g_vp[i].op > mx) mx = g_vp[i].op; if(g_vp[i].op < mn) mn = g_vp[i].op; }
      return;
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) > 0 && IsMine())
        {
         double op = PositionGetDouble(POSITION_PRICE_OPEN);
         if(op > mx) mx = op;
         if(op < mn) mn = op;
        }
  }
ulong FirstPos(int &dir, double &op)
  {
   datetime best = 0; ulong tk = 0; dir = 0; op = 0;
   if(Paper())
     {
      for(int i = 0; i < ArraySize(g_vp); i++)
         if(tk == 0 || g_vp[i].ot < best) { best = g_vp[i].ot; tk = (ulong)(i + 1); dir = g_vp[i].dir; op = g_vp[i].op; }
      return tk;
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !IsMine()) continue;
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      if(tk == 0 || ot < best)
        {
         best = ot; tk = t;
         dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
         op = PositionGetDouble(POSITION_PRICE_OPEN);
        }
     }
   return tk;
  }
//--- dashboard table rows (real ya paper)
int CollectRows(int &dir[], double &lot[], double &op[], datetime &ot[], double &pr[])
  {
   int n = 0;
   if(Paper())
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      n = ArraySize(g_vp);
      ArrayResize(dir, n); ArrayResize(lot, n); ArrayResize(op, n); ArrayResize(ot, n); ArrayResize(pr, n);
      for(int i = 0; i < n; i++) { dir[i] = g_vp[i].dir; lot[i] = g_vp[i].lot; op[i] = g_vp[i].op; ot[i] = g_vp[i].ot; pr[i] = VProfit(i, bid, ask); }
      return n;
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !IsMine()) continue;
      ArrayResize(dir, n + 1); ArrayResize(lot, n + 1); ArrayResize(op, n + 1); ArrayResize(ot, n + 1); ArrayResize(pr, n + 1);
      dir[n] = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      lot[n] = PositionGetDouble(POSITION_VOLUME); op[n] = PositionGetDouble(POSITION_PRICE_OPEN);
      ot[n] = (datetime)PositionGetInteger(POSITION_TIME); pr[n] = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      n++;
     }
   return n;
  }

//--- own P/L mode: EA ka apna "balance" = allocated + is EA ka realized P/L
void CalcRealized()
  {
   g_realized = 0; g_realDirty = false;
   if(Paper()) { g_realized = g_paperReal; return; }
   if(!HistorySelect(g_since, TimeCurrent() + 86400)) { g_realDirty = true; return; }
   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      long en = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_INOUT || en == DEAL_ENTRY_OUT_BY)
         g_realized += HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
      else if(en == DEAL_ENTRY_IN)
         g_realized += HistoryDealGetDouble(d, DEAL_COMMISSION);
     }
  }
double EaBalance()
  {
   if(!InpOwnMode) return AccountInfoDouble(ACCOUNT_BALANCE);
   if(g_realDirty) CalcRealized();
   return InpAllocBalance + g_realized;
  }
double EaEquity()
  {
   if(!InpOwnMode) return AccountInfoDouble(ACCOUNT_EQUITY);
   return EaBalance() + BasketPL();
  }
//--- EA ka apna net P/L (band trades since g_since + khuli basket) - sirf is magic + symbol
double EaNetPL()
  {
   if(g_realDirty) CalcRealized();
   return g_realized + BasketPL();
  }
//--- margin guard: purane EAs ka margin na khaaye
bool MarginOk(const int dir, const double lot, string &why)
  {
   if(InpMinMarginLevel <= 0 || Paper()) return true;
   double price = (dir == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID), m = 0;
   if(!OrderCalcMargin(dir == 1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, m)) return true;
   double used = AccountInfoDouble(ACCOUNT_MARGIN) + m, eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(used <= 0) return true;
   double lvl = eq / used * 100.0;
   if(lvl >= InpMinMarginLevel) return true;
   why = StringFormat("Margin guard: trade ke baad margin level %.0f%% < %.0f%%  -  nayi trade nahi khuli", lvl, InpMinMarginLevel);
   return false;
  }
//--- magic clash: same magic kisi aur EA ka to nahi?
bool MagicClash(string &why)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0 || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), "SAMU#") != 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
        { why = StringFormat("Magic %I64d pe kisi aur EA / symbol ki khuli trade hai (%s). InpMagic badlo.", InpMagic, PositionGetString(POSITION_SYMBOL)); return true; }
     }
   if(HistorySelect(TimeCurrent() - 30 * 86400, TimeCurrent() + 86400))
     {
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0 || HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic || HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
         if(StringFind(HistoryDealGetString(d, DEAL_COMMENT), "SAMU#") != 0 || HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol)
           { why = StringFormat("Magic %I64d pichhle 30 din mein kisi aur EA / symbol ne use kiya (%s). InpMagic badlo.", InpMagic, HistoryDealGetString(d, DEAL_SYMBOL)); return true; }
        }
     }
   return false;
  }

void SetErr(const string e) { g_lastErr = e; g_lastErrT = TimeCurrent(); Print(EA_NAME, ": ", e); }

bool OpenTrade(const int dir, const int n)
  {
   double lot = NormLot(g_lotVal[LotIndexFor(n)]);
   string why = "";
   if(!MarginOk(dir, lot, why)) { SetErr(why); return false; }
   if(Paper())
     {
      int k = ArraySize(g_vp); ArrayResize(g_vp, k + 1);
      g_vp[k].id = g_vpNext++; g_vp[k].dir = dir; g_vp[k].lot = lot;
      g_vp[k].op = (dir == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      g_vp[k].ot = TimeCurrent();
      if(n >= 2) g_tpActive = false;
      SaveVP(); SaveState();
      return true;
     }
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tp = 0;
   if(n == 1 && g_tp1On) tp = NormalizeDouble(dir == 1 ? ask + g_tp1 : bid - g_tp1, _Digits);
   string cm = "SAMU#" + (string)g_basketId;
   bool ok = (dir == 1) ? trade.Buy(lot, _Symbol, 0, 0, tp, cm) : trade.Sell(lot, _Symbol, 0, 0, tp, cm);
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
     {
      SetErr(StringFormat("Order fail: %s %.2f lot, code %u %s", dir == 1 ? "BUY" : "SELL", lot, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
      return false;
     }
   if(n >= 2 && g_tpActive)
     {
      // second trade: first trade ka TP hatao
      g_tpActive = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong t = PositionGetTicket(i);
         if(t > 0 && IsMine() && PositionGetDouble(POSITION_TP) != 0)
            trade.PositionModify(t, PositionGetDouble(POSITION_SL), 0);
        }
     }
   SaveState();
   return true;
  }

void PaperLog(const int i, const double cp, const datetime ct, const double pr, const string reason)
  {
   if(!InpLogTrades) return;
   int h = FileOpen("SAMU_UEA_paper_" + _Symbol + "_" + (string)InpMagic + ".csv", FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return;
   if(FileSize(h) == 0)
      FileWriteString(h, "id,basket,dir,lot,open_time_server,open_time_ist,open_price,close_time_server,close_time_ist,close_price,profit,reason\r\n");
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, StringFormat("P%I64d,%I64d,%s,%.2f,%s,%s,%s,%s,%s,%s,%.2f,%s\r\n", g_vp[i].id, g_basketId, g_vp[i].dir == 1 ? "BUY" : "SELL", g_vp[i].lot,
                                   TStr(g_vp[i].ot), TStr(ToIst(g_vp[i].ot)), DoubleToString(g_vp[i].op, _Digits), TStr(ct), TStr(ToIst(ct)), DoubleToString(cp, _Digits), pr, reason));
   FileClose(h);
  }

void CloseAll(const string reason)
  {
   g_closeReason = reason;
   if(Paper())
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      datetime ct = TimeCurrent();
      for(int i = 0; i < ArraySize(g_vp); i++)
        {
         double pr = VProfit(i, bid, ask);
         g_paperReal += pr;
         PaperLog(i, g_vp[i].dir == 1 ? bid : ask, ct, pr, reason);
        }
      ArrayResize(g_vp, 0);
      g_realDirty = true; g_tpActive = false; g_peak = -1e18; g_bMin = 0;
      SaveVP(); SaveState();
      return;
     }
   for(int attempt = 0; attempt < 3; attempt++)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong t = PositionGetTicket(i);
         if(t > 0 && IsMine()) trade.PositionClose(t, InpSlippagePts);
        }
      if(CountPos() == 0) break;
     }
   if(CountPos() > 0) SetErr("Close all poora nahi hua, agle tick pe phir koshish");
   else { g_tpActive = false; g_peak = -1e18; g_bMin = 0; }
   SaveState();
  }

void StopDay(const string reason)
  {
   if(CountPos() > 0) CloseAll(reason);
   g_dayStopped = true; g_dayStopReason = reason;
   SaveState();
  }

//====================================================================
//  RULES (order = docs/ENGINE-RULES.md)
//====================================================================
void NewDayCheck()
  {
   long dk = DayKeyOf(TimeCurrent());
   if(dk != g_dayKey)
     {
      g_dayKey = dk;
      g_dayStartEq = EaEquity();
      g_dayStopped = false; g_dayStopReason = "";
      SaveState();
     }
  }

void ManageBasket()
  {
   for(int guard = 0; guard < 3; guard++)
     {
      int n = CountPos();
      double pl = BasketPL(), eq = EaEquity();
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(n > 0) { if(pl > g_peak) g_peak = pl; if(pl < g_bMin) g_bMin = pl; }
      if(!g_dayStopped)
        {
         if(g_dTgt > 0 && eq >= g_dayStartEq * (1 + g_dTgt / 100.0)) { StopDay("DAY_TARGET"); return; }
         if(g_dLoss > 0 && eq <= g_dayStartEq * (1 - g_dLoss / 100.0)) { StopDay("DAY_LOSS"); return; }
        }
      if(n == 0) return;
      if(g_tpOn && pl >= g_tpUsd) { CloseAll("BASKET_TP"); return; }
      if(g_slOn && pl <= -g_slPct / 100.0 * g_bStartBal) { CloseAll("BASKET_SL"); return; }
      if(g_trailOn && g_peak >= g_trStart && pl <= g_peak - g_trDrop) { CloseAll("TRAIL"); return; }
      if(n == 1 && g_tpActive && g_tp1On)
        {
         int d; double op; FirstPos(d, op);
         if((d == 1 && bid >= op + g_tp1) || (d == -1 && ask <= op - g_tp1)) { CloseAll("TP1"); return; }
        }
      if(n < g_maxT && !g_dayStopped && !g_paused)
        {
         double mx, mn; EntryRange(mx, mn);
         bool tp1Live = (n == 1 && g_tpActive && g_tp1On && !g_sameSide);
         bool blockBuy = tp1Live && g_firstDir == 1, blockSell = tp1Live && g_firstDir == -1;
         if(g_buyAbove && !blockBuy && ask >= mx + g_step) { if(!OpenTrade(1, n + 1)) return; continue; }
         if(g_sellBelow && !blockSell && bid <= mn - g_step) { if(!OpenTrade(-1, n + 1)) return; continue; }
        }
      return;
     }
  }

void TryNewBasket()
  {
   datetime bt = iTime(_Symbol, PERIOD_M1, 0);
   if(bt == 0 || bt == g_lastBar) return;
   g_lastBar = bt;
   g_sig = SupertrendSignal();
   if(CountPos() > 0 || g_dayStopped || g_paused || g_sig == 0) return;
   int sp = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(g_maxSpread > 0 && sp > g_maxSpread) return;
   if(!TimeOk(bt)) return;
   g_basketId++;
   g_firstDir = g_sig;
   g_tpActive = g_tp1On;
   g_peak = -1e18; g_bMin = 0;
   g_bStartBal = EaBalance();
   if(!OpenTrade(g_sig, 1)) { g_basketId--; g_tpActive = false; }
   SaveState();
  }

//====================================================================
//  TRADE LOG (same columns as the app's trades CSV)
//====================================================================
string LogName() { return "SAMU_UEA_trades_" + _Symbol + "_" + (string)InpMagic + ".csv"; }

void LogDeal(const ulong deal)
  {
   if(!InpLogTrades || !HistoryDealSelect(deal)) return;
   if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagic) return;
   if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;
   long posId = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   datetime ct = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
   double cp = HistoryDealGetDouble(deal, DEAL_PRICE), vol = HistoryDealGetDouble(deal, DEAL_VOLUME);
   double pr = HistoryDealGetDouble(deal, DEAL_PROFIT) + HistoryDealGetDouble(deal, DEAL_SWAP) + HistoryDealGetDouble(deal, DEAL_COMMISSION);
   long reasonCode = HistoryDealGetInteger(deal, DEAL_REASON);
   datetime ot = 0; double op = 0; string dir = "", cm = "";
   if(HistorySelectByPosition(posId))
     {
      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong d = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(d, DEAL_ENTRY) == DEAL_ENTRY_IN)
           {
            ot = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
            op = HistoryDealGetDouble(d, DEAL_PRICE);
            dir = (HistoryDealGetInteger(d, DEAL_TYPE) == DEAL_TYPE_BUY) ? "BUY" : "SELL";
            cm = HistoryDealGetString(d, DEAL_COMMENT);
            pr += HistoryDealGetDouble(d, DEAL_COMMISSION);
           }
        }
     }
   string reason = (reasonCode == DEAL_REASON_TP) ? "TP1" : (reasonCode == DEAL_REASON_SL) ? "BROKER_SL" :
                   (reasonCode == DEAL_REASON_EXPERT) ? (g_closeReason != "" ? g_closeReason : "EA") : "MANUAL";
   string bk = (StringFind(cm, "SAMU#") == 0) ? StringSubstr(cm, 5) : (string)g_basketId;
   int h = FileOpen(LogName(), FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return;
   if(FileSize(h) == 0)
      FileWriteString(h, "id,basket,dir,lot,open_time_server,open_time_ist,open_price,close_time_server,close_time_ist,close_price,profit,reason\r\n");
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, StringFormat("%I64d,%s,%s,%.2f,%s,%s,%s,%s,%s,%s,%.2f,%s\r\n", posId, bk, dir, vol,
                                   TStr(ot), TStr(ToIst(ot)), DoubleToString(op, _Digits), TStr(ct), TStr(ToIst(ct)), DoubleToString(cp, _Digits), pr, reason));
   FileClose(h);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) { g_realDirty = true; LogDeal(trans.deal); }
  }

//====================================================================
//  DASHBOARD (Gold Luxe)
//====================================================================
#define C_BG     C'0,0,0'
#define C_PANEL  C'20,18,11'
#define C_LINE   C'74,61,26'
#define C_GOLD   C'212,175,55'
#define C_GOLD2  C'243,215,122'
#define C_GOLDD  C'138,115,48'
#define C_TXT    C'233,228,212'
#define C_MUT    C'143,136,122'
#define C_OK     C'79,209,139'
#define C_BAD    C'255,93,93'
#define C_WARN   C'255,181,71'
#define F_SERIF  "Georgia"
#define F_SANS   "Segoe UI"
#define F_MONO   "Consolas"

double g_s = 1.0;      // layout scale (chart size)
double g_k = 1.0;      // DPI factor (dpi / 96): coordinates are physical pixels, fonts MT5 khud scale karta hai
int    g_dpi = 96;
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
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontPt(13));
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, C_GOLD);
   ObjectSetInteger(0, n, OBJPROP_STATE, false);
  }
void Bar(const string nm, const string title, const string valTxt, double frac, const color fill, const int x, const int y, const int w)
  {
   frac = MathMax(0, MathMin(1, frac));
   Lbl(nm + "_t", title, x, y, 10, C_GOLD);
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

// Layout logical units (96 dpi, scale 1). Rows: header 0-44, P/L 52-128, banner 136-166,
// cards 176-272, bars 284-310, info 322-358, table 372+. Kam height pe table / info chhup jaate hain.
void Dash()
  {
   if(!InpDashboard) return;
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   int W = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS), H = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   if(W < 50 || H < 50) return;
   g_dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI); if(g_dpi <= 0) g_dpi = 96;
   g_k = g_dpi / 96.0;
   double Wl = W / g_k, Hl = H / g_k;
   g_s = MathMax(0.8, MathMin(2.2, MathMin(Wl / 1000.0, Hl / 420.0)));
   double LW = Wl / g_s, LH = Hl / g_s;            // logical canvas at this scale
   double M = 18, IW = LW - 2 * M;
   bool showInfo = LH >= 362, showTable = LH >= 400;

   Rect("bg", 0, 0, W, H, C_BG, C_BG, 0);
   datetime srv = NowServer();
   string up = ShortToString(0x25B2), dn = ShortToString(0x25BC);
   int n = g_ready ? CountPos() : 0;
   double pl = g_ready ? BasketPL() : 0;
   double net = g_ready ? EaNetPL() : 0;
   double eaEq = g_ready ? EaEquity() : 0;

   // header
   Lbl("brand", Spaced("SAMU UNIVERSAL EA") + "   " + EA_VERSION, P(M), P(10), 11, C_GOLD);
   Lbl("sub", g_name + " " + g_ver + " (" + (g_cfgSource == "file" ? InpStrategyFile : "built-in") + ")" + Dot() + "Preset " + g_preset + Dot() + _Symbol + Dot() + "Magic " + (string)InpMagic, P(M), P(28), 10, C_MUT);
   Lbl("ist", "IST  " + TimeToString(ToIst(srv), TIME_SECONDS), P(M + IW), P(9), 13, C_GOLD2, F_MONO, true);
   Lbl("srv", "SERVER  " + TimeToString(srv, TIME_SECONDS), P(M + IW), P(28), 10, C_MUT, F_MONO, true);

   // EA P/L (sirf is EA ke trades)
   Lbl("eqT", Spaced(Paper() ? "PAPER P/L" : "EA P/L"), P(M), P(52), 10, C_GOLD);
   Lbl("eq", (net >= 0 ? "+" : "") + Money(net), P(M), P(64), 38, net >= 0 ? C_GOLD : C_BAD, F_SERIF);
   double ml = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   Lbl("eqS", (Paper() ? "PAPER MODE (koi asli order nahi)     " : "LIVE TRADING     ") + "Band trades " + Money(g_realized) + "     Khuli basket " + Money(pl) + "     Since " + TimeToString(ToIst(g_since), TIME_DATE) +
       "     Margin " + (ml > 0 ? DoubleToString(ml, 0) + "%" : "-"), P(M), P(112), 10, C_MUT);
   Del("eqA");

   // buttons (top right, P/L row)
   int bw = P(120), bh = P(32);
   Btn("btnClose", "CLOSE ALL", P(M + IW) - bw, P(66), bw, bh, C'48,10,10', C_BAD);
   Btn("btnPause", g_paused ? "RESUME" : "PAUSE", P(M + IW) - 2 * bw - P(10), P(66), bw, bh, g_paused ? C_GOLD : C_PANEL, g_paused ? C_BG : C_GOLD);

   // alert banner
   string al; color ac = C_TXT, ab = C'18,15,7';
   int sp = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double accEq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(!g_ready) { al = "CONFIG ERROR: " + g_cfgErr; ac = C_BAD; ab = C'34,8,8'; }
   else if(Paper() && RealCount() > 0) { al = StringFormat("PAPER MODE  -  magic %I64d ki %d ASLI trade khuli hai (purane version ki): haath se band karo, EA ise nahi chhoota", InpMagic, RealCount()); ac = C_WARN; ab = C'34,24,6'; }
   else if(g_lastErr != "" && TimeCurrent() - g_lastErrT < 60) { al = g_lastErr; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_dayStopped && g_dayStopReason == "DAY_TARGET") { al = "DAILY TARGET HIT  -  07:00 IST tak nayi trade band"; ac = C_OK; ab = C'8,30,20'; }
   else if(g_dayStopped) { al = "DAILY LOSS LIMIT HIT  -  07:00 IST tak trading band"; ac = C_BAD; ab = C'34,8,8'; }
   else if(g_paused) { al = "PAUSED  -  nayi trade band, khuli basket ke TP/SL chal rahe hain"; ac = C_WARN; ab = C'34,24,6'; }
   else if(!Paper() && InpOwnMode && InpAllocBalance > accEq) { al = StringFormat("DHYAN: base $%.0f > account equity $%.2f  -  daily loss / SL account se bade ho sakte hain", InpAllocBalance, accEq); ac = C_WARN; ab = C'34,24,6'; }
   else if(g_maxSpread > 0 && sp > g_maxSpread) { al = StringFormat("Spread high: %d pts (max %d)  -  nayi basket ruki", sp, g_maxSpread); ac = C_WARN; ab = C'34,24,6'; }
   else if(g_warnMsg != "") { al = g_warnMsg; ac = C_WARN; ab = C'34,24,6'; }
   else if(n == 0 && g_sig == 0) { al = "Supertrend signal ka wait (warmup)"; ac = C_MUT; }
   else if(n == 0) { al = (Paper() ? "PAPER READY  -  naye M1 bar pe virtual " : "READY  -  naye M1 bar pe ") + (g_sig == 1 ? "BUY" : "SELL") + " basket khulegi"; ac = C_GOLD2; }
   else { al = StringFormat("%sBasket #%I64d chal rahi hai  -  %d / %d trades", Paper() ? "PAPER " : "", g_basketId, n, g_maxT); ac = C_GOLD2; }
   Rect("al", P(M), P(136), P(IW), P(30), ab, ac, 1);
   Lbl("alT", al, P(M + 12), P(143), 11, ac);

   // 4 cards
   double gap = 10, cw = (IW - 3 * gap) / 4.0;
   string tv = (g_sig == 1) ? up + " BUY" : (g_sig == -1) ? dn + " SELL" : "-";
   color tc = (g_sig == 1) ? C_OK : (g_sig == -1) ? C_BAD : C_MUT;
   Card("cT", P(M), P(176), P(cw), P(96), "TREND", tv, tc, "Supertrend " + g_tf + " (" + (string)g_atrP + ", x" + DoubleToString(g_mult, 1) + ")", g_closedBar ? "closed bar" + Dot() + (g_atrRma ? "RMA" : "SMA") : "live bar");
   double base = n > 0 ? g_bStartBal : EaBalance();
   double slAmt = g_slOn ? g_slPct / 100.0 * base : 0;
   string pk = (n > 0 && g_peak > -1e17) ? "Peak " + Money(g_peak) : "Peak -";
   Card("cB", P(M + cw + gap), P(176), P(cw), P(96), "BASKET", StringFormat("%d / %d", n, g_maxT), C_GOLD2, "P/L " + Money(pl), pk + (g_slOn ? Dot() + "SL " + Money(-slAmt) : ""));
   double today = eaEq - g_dayStartEq;
   Card("cD", P(M + 2 * (cw + gap)), P(176), P(cw), P(96), "TODAY", (today >= 0 ? "+" : "") + Money(today), today >= 0 ? C_OK : C_BAD,
        StringFormat("%+.2f%% of $%.0f", g_dayStartEq > 0 ? today / g_dayStartEq * 100 : 0, InpOwnMode ? InpAllocBalance : g_dayStartEq), "Reset 07:00 IST");
   string nb = "-", ns = "-";
   if(n > 0) { double mx, mn; EntryRange(mx, mn); nb = DoubleToString(mx + g_step, _Digits); ns = DoubleToString(mn - g_step, _Digits); }
   Card("cC", P(M + 3 * (cw + gap)), P(176), P(cw), P(96), "CYCLE", "#" + (string)g_basketId, C_GOLD2, "Next BUY >= " + nb, "Next SELL <= " + ns);

   // progress bars
   double bg2 = 26, bwl = (IW - 2 * bg2) / 3.0;
   double tgtAmt = g_dayStartEq * g_dTgt / 100.0, lossAmt = g_dayStartEq * g_dLoss / 100.0;
   Bar("pT", "TARGET", StringFormat("%s / %s", Money(MathMax(0, today)), Money(tgtAmt)), tgtAmt > 0 ? today / tgtAmt : 0, C_GOLD, P(M), P(284), P(bwl));
   Bar("pD", "DD OF LIMIT", StringFormat("%s / %s", Money(MathMax(0, -today)), Money(lossAmt)), lossAmt > 0 ? -today / lossAmt : 0, C_BAD, P(M + bwl + bg2), P(284), P(bwl));
   Bar("pS", "BASKET SL", g_slOn ? StringFormat("%s / %s", Money(MathMax(0, -pl)), Money(slAmt)) : "off", slAmt > 0 ? -pl / slAmt : 0, C_WARN, P(M + 2 * (bwl + bg2)), P(284), P(bwl));

   // info (2 lines)
   if(showInfo)
     {
      string lots = "";
      for(int i = 0; i < ArraySize(g_lotVal); i++) lots += (i ? "/" : "") + DoubleToString(g_lotVal[i], 2);
      Lbl("info", "Step $" + DoubleToString(g_step, 2) + Dot() + "Lots " + lots + Dot() + "TP1 " + (g_tp1On ? "$" + DoubleToString(g_tp1, 2) : "off") +
          Dot() + "Basket TP " + (g_tpOn ? Money(g_tpUsd) : "off") + Dot() + "SL " + (g_slOn ? DoubleToString(g_slPct, 2) + "%" : "off") +
          Dot() + "Trail " + (g_trailOn ? DoubleToString(g_trStart, 0) + "/" + DoubleToString(g_trDrop, 0) : "off"), P(M), P(322), 10, C_MUT);
      Lbl("info2", "Daily +" + DoubleToString(g_dTgt, 1) + "% / -" + DoubleToString(g_dLoss, 1) + "%" + Dot() + "Spread " + (string)sp + " pts" +
          Dot() + (Paper() ? "PAPER" : "LIVE") + Dot() + (InpOwnMode ? "Base $" + DoubleToString(InpAllocBalance, 0) + " (sirf % ke liye)" : "Account P/L mode") +
          (InpMinMarginLevel > 0 ? Dot() + "Margin guard " + DoubleToString(InpMinMarginLevel, 0) + "%" : ""), P(M), P(340), 10, C_MUT);
     }
   else { Del("info"); Del("info2"); }

   // trade table
   double cx[6]; cx[0] = M; cx[1] = M + 44; cx[2] = M + 120; cx[3] = M + 196; cx[4] = M + 320; cx[5] = M + IW;
   string hd[6] = {"#", "TYPE", "LOT", "OPEN", "TIME (IST)", "P/L"};
   int maxRows = showTable ? (int)MathMax(0, MathMin(12, MathFloor((LH - 396) / 19.0))) : 0;
   if(showTable)
     {
      for(int c = 0; c < 6; c++) Lbl("th" + (string)c, hd[c], P(cx[c]), P(372), 9, C_GOLD, F_SANS, c == 5);
      Rect("thl", P(M), P(388), P(IW), 1, C_LINE, C_LINE, 1);
     }
   else { for(int c = 0; c < 6; c++) Del("th" + (string)c); Del("thl"); }
   int rd[]; double rl[], ro[], rp[]; datetime rt[];
   int rn = CollectRows(rd, rl, ro, rt, rp);
   int row = 0;
   for(int i = 0; i < rn && row < maxRows; i++)
     {
      bool buy = rd[i] == 1;
      double y = 394 + row * 19;
      Lbl("r" + (string)row + "_0", (string)(row + 1), P(cx[0]), P(y), 10, C_MUT, F_MONO);
      Lbl("r" + (string)row + "_1", buy ? "BUY" : "SELL", P(cx[1]), P(y), 10, buy ? C_OK : C_BAD, F_MONO);
      Lbl("r" + (string)row + "_2", DoubleToString(rl[i], 2), P(cx[2]), P(y), 10, C_TXT, F_MONO);
      Lbl("r" + (string)row + "_3", DoubleToString(ro[i], _Digits), P(cx[3]), P(y), 10, C_TXT, F_MONO);
      Lbl("r" + (string)row + "_4", TimeToString(ToIst(rt[i]), TIME_MINUTES), P(cx[4]), P(y), 10, C_MUT, F_MONO);
      Lbl("r" + (string)row + "_5", Money(rp[i]), P(cx[5]), P(y), 10, rp[i] >= 0 ? C_OK : C_BAD, F_MONO, true);
      row++;
     }
   for(int r = row; r < 12; r++)
      for(int c = 0; c < 6; c++) Del("r" + (string)r + "_" + (string)c);
   if(showTable && row == 0) Lbl("empty", "Koi khuli trade nahi", P(M), P(396), 10, C_MUT); else Del("empty");
   if(showTable && n > row && row > 0) Lbl("more", StringFormat("+%d aur (chart ki height badhao)", n - row), P(M + IW), P(396 + row * 19), 9, C_MUT, F_SANS, true); else Del("more");
   ChartRedraw(0);
  }

//====================================================================
//  EVENTS
//====================================================================
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePts);
   trade.SetTypeFillingBySymbol(_Symbol);

   g_ready = LoadConfig(g_cfgErr);
   if(!g_ready)
     {
      Print(EA_NAME, " config error: ", g_cfgErr);
      Alert(EA_NAME, ": ", g_cfgErr);
      if(MQLInfoInteger(MQL_TESTER)) return INIT_PARAMETERS_INCORRECT;
      // live chart: EA chart pe rahe, dashboard pe laal CONFIG ERROR dikhe (trade nahi karega)
      if(InpDashboard) { if(InpHidePriceChart) ChartSetInteger(0, CHART_SHOW, false); Dash(); }
      EventSetTimer(1);
      return INIT_SUCCEEDED;
     }
   g_warnMsg = "";
   // own mode start time
   if(InpAllocFrom > 0) g_since = InpAllocFrom;
   else { g_since = (datetime)GVGet("since", 0); if(g_since == 0) { g_since = TimeCurrent(); GVSet("since", (double)g_since); } }
   g_realDirty = true;
   if(Paper())
     {
      LoadVP();
      if(InpAllocFrom == 0 && GVGet("paperSince", 0) == 0) GVSet("paperSince", (double)TimeCurrent());
      if(InpAllocFrom == 0) g_since = (datetime)GVGet("paperSince", (double)g_since);
     }
   string clash = "";
   if(!Paper() && MagicClash(clash))
     {
      g_ready = false; g_cfgErr = clash;
      Print(EA_NAME, ": ", clash); Alert(EA_NAME, ": ", clash);
      if(MQLInfoInteger(MQL_TESTER)) return INIT_PARAMETERS_INCORRECT;
      if(InpDashboard) { if(InpHidePriceChart) ChartSetInteger(0, CHART_SHOW, false); Dash(); }
      EventSetTimer(1);
      return INIT_SUCCEEDED;
     }
   if(g_cfgSource == "built-in") g_warnMsg = "MQL5\\Files\\" + InpStrategyFile + " nahi mili  -  built-in Step Basket settings se chal raha hai";
   if(g_cfgSymbol != "" && g_cfgSymbol != _Symbol) g_warnMsg = "Strategy symbol " + g_cfgSymbol + " hai, chart " + _Symbol + " hai";
   double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(MathAbs(cs - g_cs) > 1e-9) g_warnMsg = StringFormat("Contract size: JSON %.0f, broker %.0f", g_cs, cs);

   // restore state (EA restart / VPS reboot)
   g_basketId   = (long)GVGet("basketId", 0);
   g_paused     = GVGet("paused", 0) == 1;
   long dk = DayKeyOf(TimeCurrent());
   if((long)GVGet("dayKey", -1) == dk)
     {
      g_dayKey = dk;
      g_dayStartEq = GVGet("dayStartEq", EaEquity());
      int ds = (int)GVGet("dayStopped", 0);
      g_dayStopped = ds > 0; g_dayStopReason = ds == 1 ? "DAY_TARGET" : ds == 2 ? "DAY_LOSS" : "";
     }
   int n = CountPos();
   if(n > 0)
     {
      int d; double op; ulong tk = FirstPos(d, op);
      g_firstDir  = d;
      if(Paper()) g_tpActive = (n == 1 && g_tp1On && GVGet("tpActive", 0) == 1);
      else g_tpActive = (n == 1 && g_tp1On && PositionSelectByTicket(tk) && PositionGetDouble(POSITION_TP) != 0);
      g_peak      = GVGet("peak", BasketPL());
      g_bMin      = GVGet("bMin", 0);
      g_bStartBal = GVGet("bStartBal", EaBalance());
     }
   NewDayCheck();
   g_lastBar = iTime(_Symbol, PERIOD_M1, 0);   // naya basket agle M1 bar se
   g_sig = SupertrendSignal();
   SaveState();

   if(InpDashboard && !(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)))
     {
      if(InpHidePriceChart) ChartSetInteger(0, CHART_SHOW, false);
      Dash();
     }
   EventSetTimer(1);
   PrintFormat("%s %s ready [%s] (%s, %s): %s %s preset %s, step %.2f, max %d, TP1 %s, daily +%.1f%%/-%.1f%%",
               EA_NAME, EA_VERSION, Paper() ? "PAPER - koi asli order nahi" : "LIVE TRADING", g_cfgSource, InpOwnMode ? "own P/L $" + DoubleToString(InpAllocBalance, 0) : "account P/L", g_name, g_ver, g_preset, g_step, g_maxT, g_tp1On ? DoubleToString(g_tp1, 2) : "off", g_dTgt, g_dLoss);
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
   if(!g_ready) return;
   NewDayCheck();
   ManageBasket();
   TryNewBasket();
   if(GetTickCount() - g_lastDash > 500) { g_lastDash = GetTickCount(); Dash(); }
  }

void OnTimer()
  {
   if(InpDashboard) Dash();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE) { Dash(); return; }
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == PFX + "btnPause")
     {
      g_paused = !g_paused;
      SaveState();
      Print(EA_NAME, g_paused ? ": PAUSED" : ": RESUMED");
     }
   else if(sparam == PFX + "btnClose")
     {
      if(CountPos() > 0) { CloseAll("MANUAL_CLOSE_ALL"); Print(EA_NAME, ": CLOSE ALL button"); }
     }
   else return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   Dash();
  }
//+------------------------------------------------------------------+
