//+------------------------------------------------------------------+
//|                                  SMC Liquidity Sweep v1.00.mq5     |
//|                                  Ankush New Vision                 |
//|                                                                    |
//|  XAUUSD ke liye SMC EA. Model wahi jo SweepDesk app me hai:        |
//|     Liquidity Sweep -> CHoCH -> FVG (limit entry)                  |
//|  plus EA me H4 bias, liquidity pools, killzone, news aur risk.     |
//|                                                                    |
//|  Kaam kaise karta hai (har nayi M15 candle close par):            |
//|   1. H4 structure se BIAS: aakhri BOS upar = BULL, neeche = BEAR.  |
//|   2. LIQUIDITY pools: last 4 swing H/L, Equal Highs/Lows,          |
//|      PDH/PDL (pichhle din ka high/low), Asian session high/low.    |
//|   3. SWEEP: candle ki wick pool ke paar jaye (max 1.5 ATR) aur     |
//|      candle wapas andar close ho. Sweep ke baad naya extreme       |
//|      ban gaya to sweep cancel.                                     |
//|   4. CHoCH: sweep se pehle wala swing high (buy) / swing low       |
//|      (sell) pehli baar CLOSE se toote - wahi candle abhi band hui. |
//|   5. ENTRY: is move me bana bina-chhua FVG mila to uske kinare pe  |
//|      LIMIT, warna (allowed ho to) MARKET.                          |
//|   6. SL: sweep wick ke paar + 0.25 ATR buffer.                     |
//|      TP: saamne wali liquidity (swing) ya fixed RR, min RR 1.5.    |
//|   7. Filter: bias match, session (killzone), news, spread,         |
//|      din me max trades / max loss, Friday stop.                    |
//|   Ek samay me sirf 1 trade/pending (is magic par).                 |
//|                                                                    |
//|  Sab kuch sirf band (closed) candles par - repaint nahi.           |
//|  Strategy Tester me "Every tick based on real ticks" se chalao.    |
//|  Tester me news filter apne aap band rehta hai (calendar nahi).    |
//|                                                                    |
//|  CHANGELOG                                                         |
//|  v1.00 (12-Oct-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "SMC Liquidity Sweep v1.00 - XAUUSD"
#property description "Sweep -> CHoCH -> FVG entry, H4 bias, liquidity pools, killzones"

#include <Trade/Trade.mqh>

//--- enums
enum ENUM_LOTMODE
  {
   LOT_FIXED        = 0,   // Fixed lot
   LOT_RISK_PERCENT = 1    // Risk % of balance
  };

enum ENUM_TPMODE
  {
   TP_LIQUIDITY = 0,       // Saamne wali liquidity (swing)
   TP_FIXED_RR  = 1        // Fixed RR
  };

//--- inputs
input group "=== General ==="
input long            InpMagic             = 261012;      // Magic number
input string          InpComment           = "SMCS";      // Order comment prefix
input ENUM_TIMEFRAMES InpEntryTF           = PERIOD_M15;  // Entry timeframe (sweep + CHoCH)
input int             InpBarsToLoad        = 300;         // Kitni candles padhni hain

input group "=== Structure / Liquidity ==="
input int    InpSwingLen          = 2;      // Swing (fractal) left/right bars
input int    InpATRPeriod         = 14;     // ATR period
input int    InpSweepWindow       = 18;     // Sweep max kitni candle purana
input int    InpSwingLevels       = 4;      // Last N swing H/L = liquidity
input double InpMinSweepATR       = 0.0;    // Wick level ke paar kam se kam (x ATR)
input double InpMaxSweepATR       = 1.5;    // Wick level ke paar zyada se zyada (x ATR)
input bool   InpUseEqualHL        = true;   // Equal Highs/Lows pools
input double InpEqualTolATR       = 0.10;   // Equal H/L tolerance (x ATR)
input bool   InpUsePDHPDL         = true;   // PDH / PDL pools
input bool   InpUseAsianRange     = true;   // Asian session high/low pools
input int    InpAsiaStartHour     = 0;      // Asia start (server hour)
input int    InpAsiaEndHour       = 6;      // Asia end (server hour)
input bool   InpStrongLiqOnly     = false;  // Sirf EQH/EQL, PDH/PDL, Asia sweep pe trade
input double InpMinChochBodyATR   = 0.0;    // CHoCH candle body min (x ATR), 0 = off
input bool   InpRequirePA         = false;  // CHoCH candle engulf/pin ho

input group "=== HTF Bias ==="
input bool            InpUseBias        = true;       // HTF bias filter
input ENUM_TIMEFRAMES InpBiasTF         = PERIOD_H4;  // Bias timeframe
input int             InpBiasSwingLen   = 2;          // Bias swing left/right bars
input bool            InpUsePremDisc    = false;      // Premium/Discount filter
input int             InpPDBars         = 30;         // Dealing range (bias TF candles)

input group "=== Entry / SL / TP ==="
input bool        InpUseFVGLimit       = true;          // FVG pe LIMIT entry
input bool        InpAllowMarket       = true;          // FVG na mile to MARKET entry
input int         InpPendingExpiryBars = 12;            // Pending kitni candle tak
input double      InpSLBufferATR       = 0.25;          // SL buffer (x ATR)
input double      InpMinSL_ATR         = 0.30;          // Min SL distance (x ATR)
input double      InpMaxSL_ATR         = 3.00;          // Max SL distance (x ATR)
input ENUM_TPMODE InpTPMode            = TP_LIQUIDITY;  // TP mode
input double      InpRR                = 2.0;           // Fixed RR / fallback RR
input double      InpMinRR             = 1.5;           // Min RR
input double      InpMaxRR             = 5.0;           // Max RR (liquidity TP cap)

input group "=== Risk ==="
input ENUM_LOTMODE InpLotMode         = LOT_FIXED;  // Lot mode
input double       InpFixedLot        = 0.01;       // Fixed lot
input double       InpRiskPercent     = 1.0;        // Risk % per trade
input double       InpMaxLot          = 1.00;       // Max lot
input int          InpMaxTradesPerDay = 3;          // Din me max trades
input int          InpMaxLossesPerDay = 2;          // Din me max loss trades
input double       InpDailyLossUSD    = 0;          // Din ka max loss $ (0 = off)
input double       InpMaxSpreadPrice  = 0.60;       // Max spread ($ price, Ask-Bid)

input group "=== Management ==="
input bool   InpUseBE          = true;   // Breakeven
input double InpBE_AtR         = 1.0;    // BE kab (x R)
input double InpBE_LockPrice   = 0.10;   // BE pe kitna lock ($ price)
input bool   InpUsePartial     = false;  // Partial close
input double InpPartialAtR     = 1.0;    // Partial kab (x R)
input double InpPartialPercent = 50;     // Partial kitna %

input group "=== Sessions (server time) ==="
input bool InpUseSessions = true;  // Killzone filter
input int  InpS1Start     = 7;     // Session 1 start (London)
input int  InpS1End       = 11;    // Session 1 end
input int  InpS2Start     = 12;    // Session 2 start (New York)
input int  InpS2End       = 16;    // Session 2 end

input group "=== News ==="
input bool InpUseNews       = true;  // High-impact USD news filter
input int  InpNewsBeforeMin = 30;    // News se pehle (min)
input int  InpNewsAfterMin  = 30;    // News ke baad (min)

input group "=== Weekend ==="
input bool InpFridayStop      = true;  // Friday stop
input int  InpFridayNoNewHour = 18;    // Friday is ghante ke baad naya trade nahi
input int  InpFridayCloseHour = 21;    // Friday is ghante pe sab band

input group "=== Display ==="
input bool InpShowPanel = true;  // Dashboard
input bool InpDrawSetup = true;  // Chart pe sweep/CHoCH/FVG
input bool InpCSVLog    = true;  // CSV log (MQL5/Files)

//--- liquidity kinds
#define K_SWING 0
#define K_EQUAL 1
#define K_PDHL  2
#define K_ASIA  3

#define EA_NAME "SMC LIQUIDITY SWEEP v1.00"
#define PFX     "SMCS_"

//--- structs
struct SwingPt
  {
   int               idx;
   int               type;   // 1 = high, -1 = low
   double            price;
  };

struct LiqLevel
  {
   double            price;
   int               kind;
  };

struct Setup
  {
   bool              valid;
   int               dir;        // 1 buy, -1 sell
   bool              isLimit;
   double            entry;
   double            sl;
   double            tp;
   double            rr;
   double            atr;
   int               sIdx;
   datetime          sweepTime;
   double            sweepLevel;
   int               levelKind;
   double            sweepWick;
   double            chochLevel;
   bool              hasFVG;
   double            fvgLo;
   double            fvgHi;
  };

//--- globals
CTrade   trade;
MqlRates g_r[];
int      g_n        = 0;
SwingPt  g_sw[];
int      g_swn      = 0;
double   g_atr      = 0;
int      g_bias     = 0;
double   g_rangeHi  = 0;
double   g_rangeLo  = 0;
datetime g_lastBar  = 0;
string   g_state    = "Shuru ho raha hai";
string   g_last1    = "-";
string   g_last2    = "";
string   g_newsTxt  = "clear";
string   g_gvLast   = "";
bool     g_showUI   = true;

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
string TFName(ENUM_TIMEFRAMES tf)
  {
   string s = EnumToString(tf);
   if(StringFind(s, "PERIOD_") == 0)
      s = StringSubstr(s, 7);
   return s;
  }

string KindName(int kind, int dir)
  {
   if(kind == K_EQUAL) return (dir > 0 ? "EQL" : "EQH");
   if(kind == K_PDHL)  return (dir > 0 ? "PDL" : "PDH");
   if(kind == K_ASIA)  return (dir > 0 ? "AsiaLow" : "AsiaHigh");
   return (dir > 0 ? "SwingLow" : "SwingHigh");
  }

double NormPrice(double p)
  {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts > 0)
      p = MathRound(p / ts) * ts;
   return NormalizeDouble(p, _Digits);
  }

double MinLot()  { return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); }

double NormLot(double lot)
  {
   double mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(st <= 0) st = 0.01;
   lot = MathFloor(lot / st + 1e-9) * st;
   if(lot < mn) lot = mn;
   if(lot > mx) lot = mx;
   int dp = (int)MathMax(0, MathCeil(-MathLog10(st) - 1e-9));
   return NormalizeDouble(lot, dp);
  }

double StopLevelPrice()
  {
   return (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
  }

bool InHourRange(int h, int a, int b)
  {
   if(a == b) return false;
   if(a < b)  return (h >= a && h < b);
   return (h >= a || h < b);          // raat ke paar wala range
  }

//+------------------------------------------------------------------+
//| ATR (last closed bars)                                           |
//+------------------------------------------------------------------+
double CalcATR(const MqlRates &c[], int n, int period)
  {
   if(period < 1 || n < period + 1) return 0;
   double s = 0;
   for(int i = n - period; i < n; i++)
     {
      double tr = MathMax(c[i].high - c[i].low,
                  MathMax(MathAbs(c[i].high - c[i - 1].close), MathAbs(c[i].low - c[i - 1].close)));
      s += tr;
     }
   return s / period;
  }

//+------------------------------------------------------------------+
//| Swings (fractal) - chronological array, index 0 = purani candle  |
//+------------------------------------------------------------------+
int FindSwings(const MqlRates &c[], int n, int L, SwingPt &out[])
  {
   ArrayResize(out, 0);
   int cnt = 0;
   for(int i = L; i < n - L; i++)
     {
      bool isH = true, isL = true;
      for(int j = i - L; j <= i + L; j++)
        {
         if(j == i) continue;
         if(c[j].high >= c[i].high) isH = false;
         if(c[j].low  <= c[i].low)  isL = false;
        }
      if(isH)
        {
         ArrayResize(out, cnt + 1);
         out[cnt].idx = i; out[cnt].type = 1; out[cnt].price = c[i].high;
         cnt++;
        }
      if(isL)
        {
         ArrayResize(out, cnt + 1);
         out[cnt].idx = i; out[cnt].type = -1; out[cnt].price = c[i].low;
         cnt++;
        }
     }
   return cnt;
  }

// idx se pehle ka aakhri swing (type 1/-1), g_sw index ya -1
int LastSwingBefore(int idx, int type)
  {
   for(int i = g_swn - 1; i >= 0; i--)
      if(g_sw[i].idx < idx && g_sw[i].type == type)
         return i;
   return -1;
  }

// price se upar sabse paas wala swing high
int NearestHighAbove(double price)
  {
   int best = -1;
   for(int i = 0; i < g_swn; i++)
      if(g_sw[i].type == 1 && g_sw[i].price > price)
         if(best < 0 || g_sw[i].price < g_sw[best].price)
            best = i;
   return best;
  }

// price se neeche sabse paas wala swing low
int NearestLowBelow(double price)
  {
   int best = -1;
   for(int i = 0; i < g_swn; i++)
      if(g_sw[i].type == -1 && g_sw[i].price < price)
         if(best < 0 || g_sw[i].price > g_sw[best].price)
            best = i;
   return best;
  }

//+------------------------------------------------------------------+
//| Price action (CHoCH candle)                                      |
//+------------------------------------------------------------------+
bool IsBullPA(int i)
  {
   if(i < 1) return false;
   double o = g_r[i].open, c = g_r[i].close, h = g_r[i].high, l = g_r[i].low;
   double po = g_r[i - 1].open, pc = g_r[i - 1].close;
   bool eng = (c > o && pc < po && c >= po && o <= pc);
   double body = MathAbs(c - o), lw = MathMin(o, c) - l, rng = h - l;
   if(rng <= 0) rng = 1e-9;
   return (eng || (lw > body * 1.5 && lw / rng > 0.5 && c > o));
  }

bool IsBearPA(int i)
  {
   if(i < 1) return false;
   double o = g_r[i].open, c = g_r[i].close, h = g_r[i].high, l = g_r[i].low;
   double po = g_r[i - 1].open, pc = g_r[i - 1].close;
   bool eng = (c < o && pc > po && c <= po && o >= pc);
   double body = MathAbs(c - o), uw = h - MathMax(o, c), rng = h - l;
   if(rng <= 0) rng = 1e-9;
   return (eng || (uw > body * 1.5 && uw / rng > 0.5 && c < o));
  }

//+------------------------------------------------------------------+
//| FVG - sweep se CHoCH tak ke move me, jo abhi tak chhua na gaya ho |
//+------------------------------------------------------------------+
bool FindBullFVG(int from, int to, double &lo, double &hi)
  {
   for(int k = to - 2; k >= from; k--)
     {
      if(g_r[k].high < g_r[k + 2].low)
        {
         double zLo = g_r[k].high, zHi = g_r[k + 2].low;
         bool touched = false;
         for(int j = k + 3; j <= to; j++)
            if(g_r[j].low <= zHi) { touched = true; break; }
         if(touched) continue;
         lo = zLo; hi = zHi;
         return true;
        }
     }
   return false;
  }

bool FindBearFVG(int from, int to, double &lo, double &hi)
  {
   for(int k = to - 2; k >= from; k--)
     {
      if(g_r[k].low > g_r[k + 2].high)
        {
         double zLo = g_r[k + 2].high, zHi = g_r[k].low;
         bool touched = false;
         for(int j = k + 3; j <= to; j++)
            if(g_r[j].high >= zLo) { touched = true; break; }
         if(touched) continue;
         lo = zLo; hi = zHi;
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Liquidity levels jo bar s se pehle maujood the                   |
//+------------------------------------------------------------------+
void AddLevel(LiqLevel &lv[], int &cnt, double price, int kind)
  {
   if(price <= 0) return;
   ArrayResize(lv, cnt + 1);
   lv[cnt].price = price;
   lv[cnt].kind  = kind;
   cnt++;
  }

int BuildLevels(int s, int dir, LiqLevel &lv[])
  {
   ArrayResize(lv, 0);
   int cnt  = 0;
   int want = (dir > 0 ? -1 : 1);       // buy = lows ka sweep, sell = highs ka sweep
   int L    = InpSwingLen;

   //--- last N confirmed swings (swing ki confirm candle bhi s se pehle)
   int taken = 0;
   for(int i = g_swn - 1; i >= 0 && taken < InpSwingLevels; i--)
     {
      if(g_sw[i].type != want) continue;
      if(g_sw[i].idx + L >= s) continue;
      AddLevel(lv, cnt, g_sw[i].price, K_SWING);
      taken++;
     }

   //--- Equal highs/lows: do swing paas-paas -> extreme wala EQUAL pool
   if(InpUseEqualHL && cnt > 1)
     {
      double tol = InpEqualTolATR * g_atr;
      for(int a = 0; a < cnt; a++)
         for(int b = a + 1; b < cnt; b++)
           {
            if(lv[a].kind == K_PDHL || lv[a].kind == K_ASIA) continue;
            if(MathAbs(lv[a].price - lv[b].price) <= tol)
              {
               int ext = a;
               if(dir > 0) ext = (lv[a].price <= lv[b].price ? a : b);
               else        ext = (lv[a].price >= lv[b].price ? a : b);
               lv[ext].kind = K_EQUAL;
              }
           }
     }

   //--- PDH / PDL (bar s ke din se pichhla din)
   if(InpUsePDHPDL)
     {
      int d = iBarShift(_Symbol, PERIOD_D1, g_r[s].time, false);
      if(d >= 0)
        {
         double v = (dir > 0 ? iLow(_Symbol, PERIOD_D1, d + 1) : iHigh(_Symbol, PERIOD_D1, d + 1));
         AddLevel(lv, cnt, v, K_PDHL);
        }
     }

   //--- Asian range (bar s ke din ka, Asia khatam hone ke baad hi)
   if(InpUseAsianRange)
     {
      datetime t      = g_r[s].time;
      datetime day0   = (datetime)(((long)t / 86400) * 86400);
      datetime aStart = day0 + InpAsiaStartHour * 3600;
      datetime aEnd   = day0 + InpAsiaEndHour * 3600;
      if(InpAsiaEndHour > InpAsiaStartHour && t >= aEnd)
        {
         double hi = -DBL_MAX, lo = DBL_MAX;
         int    found = 0;
         for(int i = 0; i < s; i++)
           {
            if(g_r[i].time < aStart || g_r[i].time >= aEnd) continue;
            if(g_r[i].high > hi) hi = g_r[i].high;
            if(g_r[i].low  < lo) lo = g_r[i].low;
            found++;
           }
         if(found > 0)
            AddLevel(lv, cnt, (dir > 0 ? lo : hi), K_ASIA);
        }
     }
   return cnt;
  }

//+------------------------------------------------------------------+
//| TP + RR                                                          |
//+------------------------------------------------------------------+
double CalcTP(int dir, double entry, double risk, double ref, double &rr)
  {
   double tp = (dir > 0 ? entry + risk * InpRR : entry - risk * InpRR);
   if(InpTPMode == TP_LIQUIDITY)
     {
      int k = (dir > 0 ? NearestHighAbove(ref) : NearestLowBelow(ref));
      if(k >= 0) tp = g_sw[k].price;
     }
   rr = (dir > 0 ? (tp - entry) / risk : (entry - tp) / risk);
   if(rr < InpMinRR)
     {
      tp = (dir > 0 ? entry + risk * InpRR : entry - risk * InpRR);
      rr = InpRR;
     }
   if(rr > InpMaxRR)
     {
      tp = (dir > 0 ? entry + risk * InpMaxRR : entry - risk * InpMaxRR);
      rr = InpMaxRR;
     }
   return tp;
  }

//+------------------------------------------------------------------+
//| Setup detection - CHoCH abhi band hui candle (last) par ho        |
//+------------------------------------------------------------------+
bool DetectDir(int dir, Setup &st)
  {
   ZeroMemory(st);
   st.valid = false;
   if(g_n < 60 || g_atr <= 0) return false;

   int    last  = g_n - 1;
   int    L     = InpSwingLen;
   int    start = MathMax(L + 1, g_n - InpSweepWindow - 1);
   double atr   = g_atr;

   for(int s = last; s >= start; s--)
     {
      //--- sweep ke baad naya extreme nahi bana hona chahiye
      bool ok = true;
      for(int j = s + 1; j <= last; j++)
        {
         if(dir > 0 && g_r[j].low  < g_r[s].low)  { ok = false; break; }
         if(dir < 0 && g_r[j].high > g_r[s].high) { ok = false; break; }
        }
      if(!ok) continue;

      LiqLevel lv[];
      int nl = BuildLevels(s, dir, lv);
      for(int li = 0; li < nl; li++)
        {
         if(InpStrongLiqOnly && lv[li].kind == K_SWING) continue;
         double lvl = lv[li].price;

         bool swept = false;
         if(dir > 0)
            swept = (g_r[s].low < lvl - InpMinSweepATR * atr &&
                     g_r[s].low >= lvl - InpMaxSweepATR * atr &&
                     g_r[s].close > lvl);
         else
            swept = (g_r[s].high > lvl + InpMinSweepATR * atr &&
                     g_r[s].high <= lvl + InpMaxSweepATR * atr &&
                     g_r[s].close < lvl);
         if(!swept) continue;

         //--- CHoCH level = sweep se pehle ka aakhri ulta swing
         int ci = LastSwingBefore(s, (dir > 0 ? 1 : -1));
         if(ci < 0) continue;
         double ch = g_sw[ci].price;

         //--- pehla close-break abhi wali candle par ho
         if(dir > 0 && !(g_r[last].close > ch)) continue;
         if(dir < 0 && !(g_r[last].close < ch)) continue;
         bool earlier = false;
         for(int k = s; k < last; k++)
           {
            if(dir > 0 && g_r[k].close > ch) { earlier = true; break; }
            if(dir < 0 && g_r[k].close < ch) { earlier = true; break; }
           }
         if(earlier) continue;

         //--- displacement / PA
         double body = MathAbs(g_r[last].close - g_r[last].open);
         if(InpMinChochBodyATR > 0 && body < InpMinChochBodyATR * atr) continue;
         if(InpRequirePA && !(dir > 0 ? IsBullPA(last) : IsBearPA(last))) continue;

         //--- entry / SL
         double sl = 0, entry = g_r[last].close, flo = 0, fhi = 0;
         bool   isLimit = false, hasF = false;
         if(dir > 0)
           {
            sl   = MathMin(g_r[s].low, ch - atr) - InpSLBufferATR * atr;
            hasF = FindBullFVG(s, last, flo, fhi);
            if(InpUseFVGLimit && hasF && fhi > sl && fhi < g_r[last].close) { entry = fhi; isLimit = true; }
           }
         else
           {
            sl   = MathMax(g_r[s].high, ch + atr) + InpSLBufferATR * atr;
            hasF = FindBearFVG(s, last, flo, fhi);
            if(InpUseFVGLimit && hasF && flo < sl && flo > g_r[last].close) { entry = flo; isLimit = true; }
           }
         if(!isLimit && !InpAllowMarket) continue;

         double risk = (dir > 0 ? entry - sl : sl - entry);
         if(risk <= 0) continue;
         if(risk < InpMinSL_ATR * atr || risk > InpMaxSL_ATR * atr) continue;

         double ref = (dir > 0 ? MathMax(entry, g_r[last].close) : MathMin(entry, g_r[last].close));
         double rr  = 0;
         double tp  = CalcTP(dir, entry, risk, ref, rr);
         if(rr < InpMinRR) continue;

         st.valid      = true;
         st.dir        = dir;
         st.isLimit    = isLimit;
         st.entry      = entry;
         st.sl         = sl;
         st.tp         = tp;
         st.rr         = rr;
         st.atr        = atr;
         st.sIdx       = s;
         st.sweepTime  = g_r[s].time;
         st.sweepLevel = lvl;
         st.levelKind  = lv[li].kind;
         st.sweepWick  = (dir > 0 ? g_r[s].low : g_r[s].high);
         st.chochLevel = ch;
         st.hasFVG     = hasF;
         st.fvgLo      = flo;
         st.fvgHi      = fhi;
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| HTF bias - aakhri BOS ki disha                                   |
//+------------------------------------------------------------------+
int CalcBias()
  {
   MqlRates b[];
   int n = CopyRates(_Symbol, InpBiasTF, 1, 300, b);
   if(n < 30) return 0;
   int    L = InpBiasSwingLen;
   double lastH = 0, lastL = 0;
   bool   hBroken = true, lBroken = true;
   int    bias = 0;
   for(int i = 2 * L; i < n; i++)
     {
      int  p = i - L;                 // ye swing candle i par confirm hoti hai
      bool isH = true, isL = true;
      for(int j = p - L; j <= p + L; j++)
        {
         if(j == p) continue;
         if(b[j].high >= b[p].high) isH = false;
         if(b[j].low  <= b[p].low)  isL = false;
        }
      if(isH) { lastH = b[p].high; hBroken = false; }
      if(isL) { lastL = b[p].low;  lBroken = false; }
      if(!hBroken && lastH > 0 && b[i].close > lastH) { bias =  1; hBroken = true; }
      if(!lBroken && lastL > 0 && b[i].close < lastL) { bias = -1; lBroken = true; }
     }

   //--- dealing range (premium/discount)
   int from = MathMax(0, n - InpPDBars);
   g_rangeHi = -DBL_MAX; g_rangeLo = DBL_MAX;
   for(int i = from; i < n; i++)
     {
      if(b[i].high > g_rangeHi) g_rangeHi = b[i].high;
      if(b[i].low  < g_rangeLo) g_rangeLo = b[i].low;
     }
   return bias;
  }

bool PremDiscOK(const Setup &st)
  {
   if(!InpUsePremDisc) return true;
   if(g_rangeHi <= g_rangeLo) return false;
   double mid = (g_rangeHi + g_rangeLo) / 2.0;
   return (st.dir > 0 ? st.entry <= mid : st.entry >= mid);
  }

//+------------------------------------------------------------------+
//| Counts / daily stats                                             |
//+------------------------------------------------------------------+
int CountPositions()
  {
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic) c++;
     }
   return c;
  }

int CountPendings()
  {
   int c = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic) c++;
     }
   return c;
  }

void DailyStats(int &trades, int &losses, double &pl)
  {
   trades = 0; losses = 0; pl = 0;
   datetime now = TimeCurrent();
   datetime d0  = (datetime)(((long)now / 86400) * 86400);
   if(!HistorySelect(d0, now + 60)) return;
   int tot = HistoryDealsTotal();
   for(int i = 0; i < tot; i++)
     {
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      if(HistoryDealGetString(tk, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(tk, DEAL_MAGIC) != InpMagic) continue;
      long e = HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(e == DEAL_ENTRY_IN) trades++;
      if(e == DEAL_ENTRY_OUT || e == DEAL_ENTRY_OUT_BY)
        {
         double p = HistoryDealGetDouble(tk, DEAL_PROFIT) + HistoryDealGetDouble(tk, DEAL_SWAP) +
                    HistoryDealGetDouble(tk, DEAL_COMMISSION);
         pl += p;
         if(p < 0) losses++;
        }
     }
  }

//+------------------------------------------------------------------+
//| Filters                                                          |
//+------------------------------------------------------------------+
string SessionName()
  {
   MqlDateTime d;
   TimeToStruct(TimeCurrent(), d);
   if(InHourRange(d.hour, InpS1Start, InpS1End)) return "LONDON";
   if(InHourRange(d.hour, InpS2Start, InpS2End)) return "NEW YORK";
   return "";
  }

bool NewsBlocked()
  {
   g_newsTxt = "clear";
   if(!InpUseNews) { g_newsTxt = "off"; return false; }
   if(MQLInfoInteger(MQL_TESTER)) { g_newsTxt = "tester me off"; return false; }

   static datetime lastCheck = 0;
   static bool     blocked   = false;
   static string   name      = "";
   if(TimeCurrent() - lastCheck >= 60)
     {
      lastCheck = TimeCurrent();
      blocked   = false;
      name      = "";
      MqlCalendarValue vals[];
      datetime from = TimeCurrent() - InpNewsAfterMin * 60;
      datetime to   = TimeCurrent() + InpNewsBeforeMin * 60;
      int cnt = CalendarValueHistory(vals, from, to, NULL, "USD");
      for(int i = 0; i < cnt; i++)
        {
         MqlCalendarEvent ev;
         if(!CalendarEventById(vals[i].event_id, ev)) continue;
         if(ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;
         blocked = true;
         name    = ev.name;
         break;
        }
     }
   if(blocked) g_newsTxt = "BLOCK " + StringSubstr(name, 0, 22);
   return blocked;
  }

bool FridayNoNew()
  {
   if(!InpFridayStop) return false;
   MqlDateTime d;
   TimeToStruct(TimeCurrent(), d);
   if(d.day_of_week == 6 || d.day_of_week == 0) return true;
   return (d.day_of_week == 5 && d.hour >= InpFridayNoNewHour);
  }

double SpreadPrice()
  {
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
  }

// "" = sab theek, warna rukne ki wajah
string BlockReason()
  {
   if(FridayNoNew()) return "Weekend/Friday stop";
   if(InpUseSessions && SessionName() == "") return "Session band (killzone nahi)";
   if(NewsBlocked()) return "News filter";
   if(InpMaxSpreadPrice > 0 && SpreadPrice() > InpMaxSpreadPrice) return "Spread zyada";
   int tr, ls; double pl;
   DailyStats(tr, ls, pl);
   if(InpMaxTradesPerDay > 0 && tr >= InpMaxTradesPerDay) return "Aaj ke max trades ho gaye";
   if(InpMaxLossesPerDay > 0 && ls >= InpMaxLossesPerDay) return "Aaj ke max loss ho gaye";
   if(InpDailyLossUSD > 0 && pl <= -InpDailyLossUSD) return "Daily loss limit";
   return "";
  }

//+------------------------------------------------------------------+
//| Lot                                                              |
//+------------------------------------------------------------------+
double CalcLot(int dir, double entry, double sl)
  {
   double lot = InpFixedLot;
   if(InpLotMode == LOT_RISK_PERCENT)
     {
      double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
      double loss = 0;
      ENUM_ORDER_TYPE t = (dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      if(OrderCalcProfit(t, _Symbol, 1.0, entry, sl, loss) && loss < 0)
         lot = riskMoney / (-loss);
      else
        {
         double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         if(tv > 0 && ts > 0) lot = riskMoney / (MathAbs(entry - sl) / ts * tv);
        }
     }
   lot = MathMin(lot, InpMaxLot);
   return NormLot(lot);
  }

//+------------------------------------------------------------------+
//| CSV log                                                          |
//+------------------------------------------------------------------+
void CSV(string line)
  {
   if(!InpCSVLog) return;
   string fn = "SMCSweep_" + _Symbol + "_" + (string)InpMagic + ".csv";
   int h = FileOpen(fn, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
   if(h == INVALID_HANDLE) return;
   if(FileSize(h) == 0)
      FileWriteString(h, "time,event,dir,type,liquidity,level,entry,sl,tp,rr,lot,bias,ticket,profit,note\r\n");
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, line + "\r\n");
   FileClose(h);
  }

string D2(double v) { return DoubleToString(v, _Digits); }

string SetupCSV(string ev, const Setup &st, double lot, ulong ticket, string note)
  {
   return TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + "," + ev + "," +
          (st.dir > 0 ? "BUY" : "SELL") + "," + (st.isLimit ? "LIMIT" : "MARKET") + "," +
          KindName(st.levelKind, st.dir) + "," + D2(st.sweepLevel) + "," + D2(st.entry) + "," +
          D2(st.sl) + "," + D2(st.tp) + "," + DoubleToString(st.rr, 2) + "," +
          DoubleToString(lot, 2) + "," + (string)g_bias + "," + (string)ticket + ",0," + note;
  }

//+------------------------------------------------------------------+
//| Execute                                                          |
//+------------------------------------------------------------------+
bool ExecuteSetup(Setup &st)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stl = StopLevelPrice();
   bool   useLimit = st.isLimit;

   //--- limit lag hi nahi sakta (price pehle se wahan) -> market
   if(useLimit)
     {
      if(st.dir > 0 && ask - st.entry <= stl) useLimit = false;
      if(st.dir < 0 && st.entry - bid <= stl) useLimit = false;
      if(!useLimit && !InpAllowMarket) { g_state = "Limit price chali gayi"; return false; }
     }

   if(!useLimit)
     {
      st.entry   = (st.dir > 0 ? ask : bid);
      st.isLimit = false;
      double risk = (st.dir > 0 ? st.entry - st.sl : st.sl - st.entry);
      if(risk <= 0) { g_state = "Price SL ke paar"; return false; }
      double ref = (st.dir > 0 ? MathMax(st.entry, g_r[g_n - 1].close) : MathMin(st.entry, g_r[g_n - 1].close));
      double rr  = 0;
      st.tp = CalcTP(st.dir, st.entry, risk, ref, rr);
      st.rr = rr;
      if(rr < InpMinRR) { g_state = "RR kam"; return false; }
     }

   double entry = NormPrice(st.entry);
   double sl    = NormPrice(st.sl);
   double tp    = NormPrice(st.tp);
   if(MathAbs(entry - sl) <= stl || MathAbs(tp - entry) <= stl) { g_state = "Stop level se paas"; return false; }

   double lot = CalcLot(st.dir, entry, sl);
   double margin = 0;
   ENUM_ORDER_TYPE mt = (st.dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcMargin(mt, _Symbol, lot, entry, margin) && margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      g_state = "Margin kam";
      Print("SMCS: margin kam, lot ", lot);
      return false;
     }

   string cm = InpComment + (st.dir > 0 ? " B " : " S ") + KindName(st.levelKind, st.dir);
   bool ok = false;
   if(useLimit)
      ok = (st.dir > 0 ? trade.BuyLimit(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cm)
                       : trade.SellLimit(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cm));
   else
      ok = (st.dir > 0 ? trade.Buy(lot, _Symbol, 0, sl, tp, cm)
                       : trade.Sell(lot, _Symbol, 0, sl, tp, cm));

   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED && rc != TRADE_RETCODE_DONE_PARTIAL))
     {
      g_state = "Order fail: " + (string)rc;
      Print("SMCS: order fail rc=", rc, " ", trade.ResultRetcodeDescription());
      CSV(SetupCSV("FAIL", st, lot, 0, (string)rc));
      return false;
     }

   ulong tk = (useLimit ? trade.ResultOrder() : trade.ResultDeal());
   st.entry = entry; st.sl = sl; st.tp = tp;
   g_state = (useLimit ? (st.dir > 0 ? "PENDING BUY LIMIT" : "PENDING SELL LIMIT")
                       : (st.dir > 0 ? "BUY chal raha hai" : "SELL chal raha hai"));
   PrintFormat("SMCS: %s %s %s | sweep %s %.2f | entry %.2f SL %.2f TP %.2f RR %.2f lot %.2f",
               (st.dir > 0 ? "BUY" : "SELL"), (useLimit ? "LIMIT" : "MARKET"), _Symbol,
               KindName(st.levelKind, st.dir), st.sweepLevel, entry, sl, tp, st.rr, lot);
   CSV(SetupCSV("PLACED", st, lot, tk, ""));
   return true;
  }

//+------------------------------------------------------------------+
//| Pending management: expiry / TP pehle chhu gaya                  |
//+------------------------------------------------------------------+
void ManagePendings()
  {
   int expSec = InpPendingExpiryBars * PeriodSeconds(InpEntryTF);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != InpMagic) continue;
      long     type  = OrderGetInteger(ORDER_TYPE);
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      double   tp    = OrderGetDouble(ORDER_TP);
      string   why   = "";
      if(expSec > 0 && TimeCurrent() - setup >= expSec) why = "expired";
      else if(type == ORDER_TYPE_BUY_LIMIT  && tp > 0 && bid >= tp) why = "TP pehle chhu gaya";
      else if(type == ORDER_TYPE_SELL_LIMIT && tp > 0 && ask <= tp) why = "TP pehle chhu gaya";
      if(why != "")
        {
         if(trade.OrderDelete(tk))
           {
            Print("SMCS: pending ", tk, " hataya - ", why);
            CSV(TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + ",CANCEL,,,,,,,,,,," + (string)tk + ",0," + why);
            g_state = "Pending hataya (" + why + ")";
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Position management: partial + breakeven                         |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stl = StopLevelPrice();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      long   type = PositionGetInteger(POSITION_TYPE);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);
      double tp   = PositionGetDouble(POSITION_TP);
      double vol  = PositionGetDouble(POSITION_VOLUME);
      bool   buy  = (type == POSITION_TYPE_BUY);

      //--- shuru ka risk (R) yaad rakho - BE ke baad SL badal jata hai
      string gvR = PFX + "R_" + (string)tk;
      if(!GlobalVariableCheck(gvR))
        {
         if(sl <= 0) continue;
         GlobalVariableSet(gvR, MathAbs(open - sl));
        }
      double R = GlobalVariableGet(gvR);
      if(R <= 0) continue;

      double prog = (buy ? bid - open : open - ask);

      //--- partial close (ek hi baar)
      string gvP = PFX + "P_" + (string)tk;
      if(InpUsePartial && prog >= InpPartialAtR * R && !GlobalVariableCheck(gvP))
        {
         double cl = NormLot(vol * InpPartialPercent / 100.0);
         if(cl >= MinLot() && vol - cl >= MinLot() - 1e-9)
           {
            if(trade.PositionClosePartial(tk, cl))
              {
               GlobalVariableSet(gvP, 1);
               Print("SMCS: partial close ", cl, " lot, ticket ", tk);
              }
           }
         else
            GlobalVariableSet(gvP, 1);   // lot itna chhota ki partial possible nahi
        }

      //--- breakeven
      if(InpUseBE && prog >= InpBE_AtR * R)
        {
         double nsl = NormPrice(buy ? open + InpBE_LockPrice : open - InpBE_LockPrice);
         bool better = (buy ? (sl == 0 || sl < nsl - _Point / 2) : (sl == 0 || sl > nsl + _Point / 2));
         bool room   = (buy ? (bid - nsl > stl) : (nsl - ask > stl));
         if(better && room)
           {
            if(trade.PositionModify(tk, nsl, tp))
               Print("SMCS: breakeven SL ", DoubleToString(nsl, _Digits), " ticket ", tk);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Close all (pehle pending, phir positions)                        |
//+------------------------------------------------------------------+
void CloseAll(string why)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic)
         trade.OrderDelete(tk);
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         if(trade.PositionClose(tk))
            Print("SMCS: close ", tk, " - ", why);
     }
  }

void FridayCheck()
  {
   if(!InpFridayStop) return;
   MqlDateTime d;
   TimeToStruct(TimeCurrent(), d);
   if(d.day_of_week == 5 && d.hour >= InpFridayCloseHour)
      if(CountPositions() + CountPendings() > 0)
        {
         CloseAll("Friday close");
         g_state = "Friday close";
        }
  }

//+------------------------------------------------------------------+
//| Chart drawing                                                    |
//+------------------------------------------------------------------+
void DrawLine(string name, datetime t0, datetime t1, double p, color clr, ENUM_LINE_STYLE style, string txt)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t0, p, t1, p);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t0);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, txt);
   string tn = name + "_T";
   if(ObjectFind(0, tn) < 0)
      ObjectCreate(0, tn, OBJ_TEXT, 0, t1, p);
   ObjectSetInteger(0, tn, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, tn, OBJPROP_PRICE, 0, p);
   ObjectSetString(0, tn, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, tn, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, tn, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, tn, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, tn, OBJPROP_SELECTABLE, false);
  }

void DrawSetup(const Setup &st)
  {
   if(!InpDrawSetup || !g_showUI) return;
   ObjectsDeleteAll(0, PFX + "SET_");
   int      ps = PeriodSeconds(InpEntryTF);
   datetime t0 = st.sweepTime - ps * 6;
   datetime t1 = TimeCurrent() + ps * InpPendingExpiryBars;
   color    dc = (st.dir > 0 ? clrLimeGreen : clrTomato);

   DrawLine(PFX + "SET_LIQ", t0, t1, st.sweepLevel, clrOrange, STYLE_DOT, KindName(st.levelKind, st.dir) + " swept");
   DrawLine(PFX + "SET_CH", st.sweepTime, t1, st.chochLevel, clrDeepSkyBlue, STYLE_DASHDOT, "CHoCH");
   DrawLine(PFX + "SET_EN", st.sweepTime, t1, st.entry, dc, STYLE_SOLID, (st.isLimit ? "LIMIT " : "ENTRY ") + D2(st.entry));
   DrawLine(PFX + "SET_SL", st.sweepTime, t1, st.sl, clrRed, STYLE_DASH, "SL " + D2(st.sl));
   DrawLine(PFX + "SET_TP", st.sweepTime, t1, st.tp, clrLime, STYLE_DASH, "TP " + D2(st.tp) + "  RR " + DoubleToString(st.rr, 2));

   if(st.hasFVG)
     {
      string fn = PFX + "SET_FVG";
      ObjectCreate(0, fn, OBJ_RECTANGLE, 0, st.sweepTime, st.fvgHi, t1, st.fvgLo);
      ObjectSetInteger(0, fn, OBJPROP_COLOR, C'107,77,255');
      ObjectSetInteger(0, fn, OBJPROP_FILL, true);
      ObjectSetInteger(0, fn, OBJPROP_BACK, true);
      ObjectSetInteger(0, fn, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, fn, OBJPROP_TOOLTIP, "FVG " + D2(st.fvgLo) + " - " + D2(st.fvgHi));
     }

   //--- sweep wick pe nishaan
   string an = PFX + "SET_WICK";
   ObjectCreate(0, an, OBJ_ARROW, 0, st.sweepTime, st.sweepWick);
   ObjectSetInteger(0, an, OBJPROP_ARROWCODE, (st.dir > 0 ? 233 : 234));
   ObjectSetInteger(0, an, OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, an, OBJPROP_ANCHOR, (st.dir > 0 ? ANCHOR_TOP : ANCHOR_BOTTOM));
   ObjectSetInteger(0, an, OBJPROP_SELECTABLE, false);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Dashboard                                                        |
//+------------------------------------------------------------------+
void PanelRow(int i, string txt, color clr)
  {
   string n = PFX + "P_" + (string)i;
   if(ObjectFind(0, n) < 0)
     {
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, n, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, n, OBJPROP_YDISTANCE, 34 + i * 17);
      ObjectSetString(0, n, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, n, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
     }
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
  }

void Panel()
  {
   if(!InpShowPanel || !g_showUI) return;
   int rows = 12;
   string bg = PFX + "P_BG";
   if(ObjectFind(0, bg) < 0)
     {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, 26);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, 390);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, rows * 17 + 14);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'12,12,14');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_COLOR, C'255,176,0');
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
     }

   color amber = C'255,176,0', grey = C'170,170,170', white = clrWhite;
   string biasTxt = (g_bias > 0 ? "BULLISH" : (g_bias < 0 ? "BEARISH" : "NEUTRAL"));
   color  biasClr = (g_bias > 0 ? clrLimeGreen : (g_bias < 0 ? clrTomato : grey));
   if(!InpUseBias) { biasTxt = biasTxt + " (filter off)"; }

   string ses = SessionName();
   string sesTxt = (!InpUseSessions ? "filter off" : (ses == "" ? "band" : ses + " open"));

   double sp = SpreadPrice();
   int tr, ls; double pl;
   DailyStats(tr, ls, pl);
   NewsBlocked();

   string lotTxt = (InpLotMode == LOT_FIXED ? "FIXED " + DoubleToString(InpFixedLot, 2)
                                            : "RISK " + DoubleToString(InpRiskPercent, 1) + "%");

   PanelRow(0,  EA_NAME, amber);
   PanelRow(1,  _Symbol + " | Entry " + TFName(InpEntryTF) + " | Bias " + TFName(InpBiasTF), grey);
   PanelRow(2,  "Bias     : " + biasTxt, biasClr);
   PanelRow(3,  "Session  : " + sesTxt, (ses == "" && InpUseSessions ? grey : clrLimeGreen));
   PanelRow(4,  "News     : " + g_newsTxt, (StringFind(g_newsTxt, "BLOCK") == 0 ? clrTomato : grey));
   PanelRow(5,  "Spread   : " + DoubleToString(sp, 2) + " (max " + DoubleToString(InpMaxSpreadPrice, 2) + ")",
            (InpMaxSpreadPrice > 0 && sp > InpMaxSpreadPrice ? clrTomato : grey));
   PanelRow(6,  "ATR      : " + DoubleToString(g_atr, 2), grey);
   PanelRow(7,  "State    : " + g_state, white);
   PanelRow(8,  "Last     : " + g_last1, amber);
   PanelRow(9,  "           " + g_last2, amber);
   PanelRow(10, "Today    : " + (string)tr + "/" + (string)InpMaxTradesPerDay + " trades | " +
                (string)ls + "/" + (string)InpMaxLossesPerDay + " loss | P/L " + DoubleToString(pl, 2),
            (pl >= 0 ? clrLimeGreen : clrTomato));
   PanelRow(11, "Lot      : " + lotTxt + " | Magic " + (string)InpMagic, grey);
  }

//+------------------------------------------------------------------+
//| New bar logic                                                    |
//+------------------------------------------------------------------+
void OnNewBar()
  {
   ArraySetAsSeries(g_r, false);
   g_n = CopyRates(_Symbol, InpEntryTF, 1, InpBarsToLoad, g_r);
   if(g_n < 60) { g_state = "Data load ho raha hai"; return; }
   g_atr = CalcATR(g_r, g_n, InpATRPeriod);
   g_swn = FindSwings(g_r, g_n, InpSwingLen, g_sw);
   g_bias = ((InpUseBias || InpUsePremDisc) ? CalcBias() : 0);

   int pos = CountPositions(), pend = CountPendings();
   if(pos > 0)  { g_state = "Trade chal raha hai"; return; }
   if(pend > 0) { g_state = "Pending laga hai";   return; }

   Setup cand[2];
   int   nc = 0;
   Setup tmp;
   if(DetectDir(1, tmp))  { cand[nc] = tmp; nc++; }
   if(DetectDir(-1, tmp)) { cand[nc] = tmp; nc++; }

   string block = BlockReason();
   if(nc == 0)
     {
      g_state = (block == "" ? "Setup ka intezaar" : "Ruka: " + block);
      return;
     }

   double lastSweep = (GlobalVariableCheck(g_gvLast) ? GlobalVariableGet(g_gvLast) : 0);
   for(int i = 0; i < nc; i++)
     {
      Setup st;
      st = cand[i];
      g_last1 = StringFormat("%s sweep %s %.2f @%s", (st.dir > 0 ? "BUY" : "SELL"),
                             KindName(st.levelKind, st.dir), st.sweepLevel,
                             TimeToString(g_r[g_n - 1].time + PeriodSeconds(InpEntryTF), TIME_MINUTES));
      g_last2 = StringFormat("%s %.2f SL %.2f TP %.2f RR %.1f", (st.isLimit ? "LMT" : "MKT"),
                             st.entry, st.sl, st.tp, st.rr);

      string why = "";
      if((double)st.sweepTime <= lastSweep)        why = "ye sweep pehle trade ho chuka";
      else if(block != "")                         why = block;
      else if(InpUseBias && st.dir != g_bias)      why = "HTF bias ulta";
      else if(!PremDiscOK(st))                     why = "Premium/Discount fail";

      if(why != "")
        {
         g_state = "Skip: " + why;
         Print("SMCS: setup skip (", why, ") ", g_last1, " | ", g_last2);
         CSV(SetupCSV("SKIP", st, 0, 0, why));
         continue;
        }

      if(ExecuteSetup(st))
        {
         GlobalVariableSet(g_gvLast, (double)st.sweepTime);
         DrawSetup(st);
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert events                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   g_gvLast = PFX + _Symbol + "_" + (string)InpMagic + "_last";
   g_showUI = !(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE));

   if(InpRR < InpMinRR)
      Print("SMCS: dhyan do - InpRR (", InpRR, ") InpMinRR (", InpMinRR, ") se kam hai, fallback TP kabhi pass nahi hoga");
   if(InpSwingLen < 1 || InpATRPeriod < 2 || InpBarsToLoad < 100)
     {
      Print("SMCS: galat inputs (SwingLen>=1, ATR>=2, BarsToLoad>=100)");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(StringFind(_Symbol, "XAU") < 0 && StringFind(_Symbol, "GOLD") < 0)
      Print("SMCS: dhyan do - ye EA XAUUSD ke liye tune hai, chart symbol ", _Symbol);

   g_lastBar = 0;
   Panel();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, PFX);
   ChartRedraw(0);
  }

void OnTick()
  {
   ManagePendings();
   ManagePositions();
   FridayCheck();

   datetime bt = iTime(_Symbol, InpEntryTF, 0);
   if(bt != 0 && bt != g_lastBar)
     {
      g_lastBar = bt;
      OnNewBar();
     }

   static datetime lastPanel = 0;
   if(g_showUI && TimeCurrent() != lastPanel)
     {
      lastPanel = TimeCurrent();
      Panel();
     }
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagic) return;
   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol) return;

   long  e   = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   ulong pid = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   string t  = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
   double px = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
   double vl = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);

   if(e == DEAL_ENTRY_IN)
     {
      long dt = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
      CSV(t + ",FILL," + (dt == DEAL_TYPE_BUY ? "BUY" : "SELL") + ",,,," + D2(px) + ",,,," +
          DoubleToString(vl, 2) + ",," + (string)pid + ",0,");
      g_state = "Trade chal raha hai";
     }
   else if(e == DEAL_ENTRY_OUT || e == DEAL_ENTRY_OUT_BY)
     {
      double p = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) +
                 HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
      CSV(t + ",CLOSE,,,,," + D2(px) + ",,,," + DoubleToString(vl, 2) + ",," + (string)pid + "," +
          DoubleToString(p, 2) + ",");
      if(!PositionSelectByTicket(pid))
        {
         GlobalVariableDel(PFX + "R_" + (string)pid);
         GlobalVariableDel(PFX + "P_" + (string)pid);
         g_state = (p >= 0 ? "Trade band: PROFIT " : "Trade band: LOSS ") + DoubleToString(p, 2);
        }
     }
  }
//+------------------------------------------------------------------+
