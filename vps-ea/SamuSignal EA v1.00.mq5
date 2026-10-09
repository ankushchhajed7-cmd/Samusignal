//+------------------------------------------------------------------+
//|                                      SamuSignal EA v1.00.mq5       |
//|  SamuSignal app (index.html) ka poora signal logic, auto trade.    |
//|  (File ka naam v1.00 hi hai taaki chart setup na tute - asli       |
//|   version neeche #property version aur chart panel me.)            |
//|                                                                    |
//|  Har pair pe har nayi 15m candle par app jaisa hisaab:             |
//|    15m + 1H + 4H + 1D bias, 50 agents, quality, 10 technical       |
//|    checks, signal umar, EMA Plan, Smart Filter -> FAISLA            |
//|    TRADE LO (market) / LIMIT LAGAO / STOP LAGAO / WAIT              |
//|  Logic ka core app ke JavaScript se 7000+ test cases me milaya     |
//|  gaya hai (same candles -> same faisla).                           |
//|                                                                    |
//|  v1.03 niyam:                                                      |
//|   * 28 pairs, 5 group (app ke Market page jaise). Har group me ek  |
//|     samay sirf 1 trade/order. Ek candle pe group ke kai pairs me   |
//|     signal ho to sabse zyada quality (phir technical %) wala.      |
//|   * Micro-confirmation: TRADE LO pe turant nahi - price signal ki  |
//|     taraf 0.15 ATR chale tab entry; ulta chale ya 15 min beete to  |
//|     cancel. (LIMIT/STOP pending pe nahi.)                          |
//|   * Spread filter: spread SL ke 10% se zyada ho to entry ruki.     |
//|   * Lot fix 0.01, SL/TP $2.5 / $5 per 0.01 lot (R:R 1:2).          |
//|   * Ek pair pe din me max 2 (IST din). 08:00-22:00 IST Som-Shukra. |
//|   * High-impact news +-30 min naya trade nahi, pending bhi hatao.  |
//|   * Pending 3 ghante me na bhare to hatao. Default sirf DEMO.      |
//|  v1.04: Profit lock - profit $2 pahunche to SL +$1 par (kam se kam |
//|     $1 book). Trailing $ me: $3 ke baad SL price se $2 peeche.     |
//|     (+$1 -> +$2 -> ... -> TP $5). Breakeven ab $1.5 pe.            |
//|  v1.10: Lock seedhi - har pura $1 profit (0.01 lot) ka 75% pakka:  |
//|     +$1 -> +$0.75, +$2 -> +$1.50 ... (InpStepUsd / InpKeepPct).   |
//|     SL/TP niyam wahi (A+, SL $2.5 tak).                          |
//|  v1.09: +$1 profit (0.01 lot) pe SL +$0.75 pakka (InpFixAtUsd /  |
//|     InpFixUsd) - app + FXBridge v3.58 jaisa. Baaki BE/lock/trail   |
//|     waise hi, SL sirf aage.                                       |
//|  v1.08: Waqt ki seema hatayi (poora din, Som-Shukra). Sirf high-  |
//|     impact news se 1 ghanta pehle aur 1 ghanta baad naya trade   |
//|     nahi (pending bhi hatao). Inputs se waqt wapas laga sakte ho. |
//|  v1.07: A+ setup -                                                |
//|   * Jagah: BUY sirf 6 ghante ki range ke neeche wale hisse se,    |
//|     SELL upar wale se (kinare pe ho to LIMIT pullback pe).        |
//|   * SL pichhle swing ke peeche, kam se kam 10 pip. R:R >= 1.3.    |
//|   * Ek currency pe ek hi trade (USDJPY + CHFJPY saath nahi).      |
//|   * Sirf London + New York: 12:30 - 21:30 IST.                    |
//|   * Breakeven 50%, lock 65% -> +25%, trailing 75% ke baad.        |
//|  v1.06: Pin Bar agent band (live record 15%) - vote 49 agents pe. |
//|  v1.05: market ke hisaab se 3 mode, sab auto:                     |
//|   * NORMAL - app jaisa faisla. TREND - tagde trend me EMA9         |
//|     pullback pe entry (timing ki wajah se WAIT nahi). RANGE -      |
//|     shaant market me range ke kinare se beech tak chhota trade.    |
//|   * SL/TP ATR se (SL 1.2 ATR, TP 1.6x / trend 2x), TP $1 - $5.     |
//|     SL $2.5 se bada ho to trade nahi. Din ka loss $5 -> us din bas.|
//|   * BE / profit lock / trailing ab TP ke % se (TP chhota ho ya     |
//|     bada, sab us hisaab se). Lock kam se kam +$0.75 (jahan ho sake)|
//|                                                                    |
//|  Lagana: kisi bhi ek chart pe (jaise XAUUSDm) - EA saare pairs     |
//|  khud dekhta hai. MT5 me "Algo Trading" ON hona chahiye.           |
//+------------------------------------------------------------------+
#property copyright "SamuSignal"
#property version   "1.10"
#property description "SamuSignal app ka signal logic - 28 pairs, 5 group, auto trade (demo test)"

#include <Trade\Trade.mqh>

input group "Pairs - 5 group (har group me ek samay 1 trade)"
input string InpGrpMajors     = "EURUSD,GBPUSD,USDJPY,USDCHF,USDCAD,AUDUSD,NZDUSD";          // Group 1: Majors
input string InpGrpEur        = "EURJPY,EURGBP,EURCHF,EURCAD,EURAUD,EURNZD";                 // Group 2: EUR Cross
input string InpGrpGbp        = "GBPJPY,GBPCHF,GBPCAD,GBPAUD,GBPNZD";                        // Group 3: GBP Cross
input string InpGrpAudNzd     = "AUDJPY,AUDCHF,AUDCAD,AUDNZD,NZDJPY,NZDCHF,NZDCAD";          // Group 4: AUD / NZD
input string InpGrpCadChf     = "CADCHF,CADJPY,CHFJPY";                                      // Group 5: CAD / CHF
input string InpSuffix        = "";      // Broker suffix (jaise m) - khaali = chart ke symbol se
input bool   InpOneTradePerGroup = true; // Har group me ek samay sirf 1 trade/order
input int    InpGroupWaitSec  = 20;      // Nayi candle ke baad itne sec ruk kar group ka best chuno

input group "Trading"
input bool   InpEnableTrading = true;    // Trade lagana ON/OFF (OFF = sirf hisaab/log)
input bool   InpAllowReal     = false;   // REAL account pe bhi trade? (false = sirf DEMO)
input bool   InpModeMarket    = true;    // TRADE LO (market order)
input bool   InpModeLimit     = true;    // LIMIT LAGAO (pullback pending)
input bool   InpModeStop      = true;    // STOP LAGAO (breakout pending)
input double InpLots          = 0.01;    // Lot (fix)
input double InpTpUsd         = 5.0;     // Signal hisaab ka TP $ (app jaisa; asli TP neeche Auto se)
input double InpSlUsd         = 2.5;     // Signal hisaab ka SL $ (app jaisa; asli SL neeche Auto se)
input int    InpMaxPerPairDay = 2;       // Ek pair pe din me max trades (IST din)
input int    InpPendingHours  = 3;       // LIMIT/STOP itne ghante me na bhare to hatao

input group "Entry (tick)"
input bool   InpMicroConfirm  = true;    // TRADE LO pe micro-confirmation (price pehle signal ki taraf chale)
input double InpConfirmAtr    = 0.15;    // Kitna chale (ATR ka hissa) - itna hi ulta chale to cancel
input int    InpConfirmMin    = 15;      // Confirmation ka max intezaar (minute)
input bool   InpSpreadFilter  = true;    // Spread bada ho to entry roko
input double InpMaxSpreadPctSL = 20;     // Spread SL doori ke kitne % tak theek

input group "Auto SL/TP + Mode (v1.05)"
input bool   InpAutoSlTp      = true;    // SL/TP market (ATR) ke hisaab se (false = upar wale fix $)
input double InpSlAtr         = 1.2;     // SL = itne ATR(15m)
input double InpRrNormal      = 1.6;     // NORMAL: TP = SL x itna
input double InpRrTrend       = 2.0;     // TREND: TP = SL x itna
input double InpMinTpUsd      = 1.0;     // TP kam se kam $ (0.01 lot)
input double InpMaxTpUsd      = 5.0;     // TP zyada se zyada $
input double InpMaxSlUsd      = 2.5;     // SL isse bada ho to trade nahi ($)
input double InpMaxTpAtr      = 3.0;     // $min TP itne ATR se door = market shaant, trade nahi
input bool   InpTrendMode     = true;    // TREND mode (EMA9 pullback entry)
input double InpTrendAdx      = 25;      // ADX itna ya zyada = tagda trend
input bool   InpRangeMode     = true;    // RANGE mode (kinare se beech tak)
input double InpRangeAdx      = 20;      // ADX isse kam = range
input int    InpRangeBars     = 24;      // Range kitni candles ki (24 x 15m = 6 ghante)
input double InpRrRangeMin    = 1.2;     // RANGE me kam se kam R:R
input bool   InpAplus         = true;    // A+ setup: jagah + swing SL + R:R (v1.07)
input double InpMinSlPips     = 10;      // A+: SL kam se kam itne pip
input double InpMaxSlAtr      = 2.5;     // A+: swing SL zyada se zyada itne ATR
input double InpPosMaxNormal  = 0.5;     // A+: BUY range ke neeche itne hisse tak (0.5 = aadha)
input double InpPosMaxTrend   = 0.7;     // A+: TREND me thodi chhoot
input int    InpSwingBars     = 10;      // A+: swing high/low kitni candles ka
input double InpRrMin         = 1.3;     // A+: kam se kam R:R
input bool   InpOneTradePerCcy = true;   // Ek currency pe ek hi trade (JPY, USD ...)
input bool   InpLondonNy      = false;    // Sirf 12:30 - 21:30 IST (London + New York)
input double InpMaxDayLossUsd = 5.0;     // Din (IST) ka loss itna ho to us din naya trade nahi (0 = off)

input group "Time / News (IST)"
input int    InpStartHourIST  = 0;       // Shuru (IST ghanta) - 0 = koi seema nahi
input int    InpEndHourIST    = 24;      // Band (IST ghanta) - 24 = koi seema nahi
input bool   InpAvoidNews     = true;    // High-impact news ke paas naya trade nahi
input int    InpNewsMinutes   = 60;      // News se pehle/baad kitne minute
input bool   InpCancelOnNews  = true;    // News aane wali ho to bhara-nahi pending order hatao

input group "Breakeven / Trailing"
input bool   InpBreakEven     = true;    // Breakeven ON/OFF
input double InpBePct         = 50;      // TP ka itna % chale to SL entry par
input bool   InpProfitLock    = true;    // Profit lock ON/OFF (kam se kam $ book)
input double InpLockAtPct     = 65;      // TP ka itna % chale to...
input double InpLockPct       = 25;      // ...SL TP ke itne % profit par
input double InpMinLockUsd    = 0.75;    // Lock kam se kam itne $ ka (jahan TP itna bada ho)
input double InpStepUsd       = 1.00;    // v1.10: har itne $ profit (0.01 lot) pe...
input double InpKeepPct       = 75;      // ...uska itna % pakka: +$1 -> +$0.75, +$2 -> +$1.50 ... (0 = band)
input bool   InpTrailing      = true;    // Trailing ON/OFF
input double InpTrailStartPct = 75;      // TP ka itna % ke baad trailing shuru
input double InpTrailDistPct  = 40;      // SL price se TP ke itne % peeche chale

input group "Other"
input long   InpMagic         = 777100;  // Magic number (FXBridgeEA se alag)
input bool   InpVerboseLog    = true;    // Har pair ka hisaab Experts log me

//<<CORE  - SamuSignal app (index.html) ka signal logic, line-by-line port.
// Is hisse me sirf saada MQL5 hai (struct, array, loop, Math*) - test ke liye
// isi ko C++ me badal kar app ke JavaScript se mila kar check kiya jaata hai.
#define SS_BUY   1
#define SS_SELL -1
#define SS_HOLD  0
#define SS_NAGENTS 50
#define SS_NACTIVE 49     // Pin Bar (38) band - vote me 49

struct Bar { double o; double h; double l; double c; };

struct TfInfo {
   int    bias;      // SS_BUY / SS_SELL / SS_HOLD (NEUTRAL)
   double score;
   double price;
   double rsi;
   double atr;       // Supertrend(10,3) ka ATR(10)
   int    stDir;
   double stLine;
   double e20;
   double e50;
   double macd;
};

// JS Math.round = floor(x + 0.5)
double SsRound(double x) { return MathFloor(x + 0.5); }

void SsCloses(const Bar &b[], double &c[])
{
   int n = ArraySize(b);
   ArrayResize(c, n);
   for(int i = 0; i < n; i++) c[i] = b[i].c;
}

void SsEma(const double &a[], int len, double &out[])
{
   int n = ArraySize(a);
   ArrayResize(out, n);
   if(n == 0) return;
   double k = 2.0 / (len + 1);
   double e = a[0];
   for(int i = 0; i < n; i++)
   {
      if(i == 0) e = a[0];
      else       e = a[i] * k + e * (1 - k);
      out[i] = e;
   }
}

double SsEmaLast(const double &a[], int len)
{
   double o[];
   SsEma(a, len, o);
   return o[ArraySize(o) - 1];
}

void SsRsi(const double &c[], int len, double &out[])
{
   int n = ArraySize(c);
   ArrayResize(out, n);
   for(int i = 0; i < n; i++) out[i] = 50;
   double g = 0, l = 0;
   for(int i = 1; i <= len && i < n; i++)
   {
      double d = c[i] - c[i - 1];
      if(d >= 0) g += d; else l -= d;
   }
   g /= len; l /= len;
   if(len < n) out[len] = (l == 0) ? 100 : 100 - 100 / (1 + g / l);
   for(int i = len + 1; i < n; i++)
   {
      double d = c[i] - c[i - 1];
      g = (g * (len - 1) + (d > 0 ? d : 0)) / len;
      l = (l * (len - 1) + (d < 0 ? -d : 0)) / len;
      out[i] = (l == 0) ? 100 : 100 - 100 / (1 + g / l);
   }
}

double SsRsiLast(const double &c[], int len)
{
   double o[];
   SsRsi(c, len, o);
   return o[ArraySize(o) - 1];
}

void SsAtr(const Bar &b[], int len, double &out[])
{
   int n = ArraySize(b);
   double tr[];
   ArrayResize(tr, n);
   for(int i = 0; i < n; i++)
   {
      if(i == 0) tr[i] = b[i].h - b[i].l;
      else tr[i] = MathMax(b[i].h - b[i].l, MathMax(MathAbs(b[i].h - b[i - 1].c), MathAbs(b[i].l - b[i - 1].c)));
   }
   ArrayResize(out, n);
   double s = 0;
   for(int i = 0; i < len && i < n; i++) s += tr[i];
   double a = s / len;
   for(int i = 0; i < n; i++)
   {
      if(i < len) out[i] = a;
      else { a = (a * (len - 1) + tr[i]) / len; out[i] = a; }
   }
}

void SsSupertrend(const Bar &b[], int len, double mult, int &dir[], double &line[], double &atrOut[])
{
   int n = ArraySize(b);
   SsAtr(b, len, atrOut);
   ArrayResize(dir, n);
   ArrayResize(line, n);
   double up = 0, dn = 0;
   int d = 1;
   for(int i = 0; i < n; i++)
   {
      double mid = (b[i].h + b[i].l) / 2;
      double bu = mid - mult * atrOut[i];
      double bl = mid + mult * atrOut[i];
      if(i > 0)
      {
         bu = (bu > up || b[i - 1].c < up) ? bu : up;
         bl = (bl < dn || b[i - 1].c > dn) ? bl : dn;
         if(d == 1 && b[i].c < up) d = -1;
         else if(d == -1 && b[i].c > dn) d = 1;
      }
      else d = (b[i].c >= mid) ? 1 : -1;
      up = bu; dn = bl;
      dir[i] = d;
      line[i] = (d == 1) ? up : dn;
   }
}

int SsStDirLast(const Bar &b[], int len, double mult)
{
   int d[]; double ln[]; double at[];
   SsSupertrend(b, len, mult, d, ln, at);
   return d[ArraySize(d) - 1];
}

void SsMacdH(const double &c[], double &out[])
{
   int n = ArraySize(c);
   double f[]; double s[];
   SsEma(c, 12, f);
   SsEma(c, 26, s);
   double m[];
   ArrayResize(m, n);
   for(int i = 0; i < n; i++) m[i] = f[i] - s[i];
   double sig[];
   SsEma(m, 9, sig);
   ArrayResize(out, n);
   for(int i = 0; i < n; i++) out[i] = m[i] - sig[i];
}

// JS sma(a,n) ka aakhri element
double SsSmaLast(const double &a[], int n)
{
   int len = ArraySize(a);
   int i = len - 1;
   if(i < n - 1) return a[i];
   double s = 0;
   for(int k = i - n + 1; k <= i; k++) s += a[k];
   return s / n;
}

double SsStdev(const double &a[], int n)
{
   int len = ArraySize(a);
   int from = len - n; if(from < 0) from = 0;
   double s = 0;
   for(int k = from; k < len; k++) s += a[k];
   double m = s / n;
   double v = 0;
   for(int k = from; k < len; k++) v += (a[k] - m) * (a[k] - m);
   return MathSqrt(v / n);
}

double SsHH(const Bar &b[], int n)
{
   int len = ArraySize(b);
   int from = len - n; if(from < 0) from = 0;
   double m = b[from].h;
   for(int k = from; k < len; k++) if(b[k].h > m) m = b[k].h;
   return m;
}

double SsLL(const Bar &b[], int n)
{
   int len = ArraySize(b);
   int from = len - n; if(from < 0) from = 0;
   double m = b[from].l;
   for(int k = from; k < len; k++) if(b[k].l < m) m = b[k].l;
   return m;
}

double SsStoch(const Bar &b[], int n)
{
   double h = SsHH(b, n), l = SsLL(b, n), c = b[ArraySize(b) - 1].c;
   return (h == l) ? 50 : (c - l) / (h - l) * 100;
}

double SsCci(const Bar &b[], int n)
{
   int len = ArraySize(b);
   int from = len - n; if(from < 0) from = 0;
   double s = 0;
   for(int k = from; k < len; k++) s += (b[k].h + b[k].l + b[k].c) / 3;
   double m = s / n;
   double md = 0;
   for(int k = from; k < len; k++) md += MathAbs((b[k].h + b[k].l + b[k].c) / 3 - m);
   md = md / n;
   double lastTp = (b[len - 1].h + b[len - 1].l + b[len - 1].c) / 3;
   return (md == 0) ? 0 : (lastTp - m) / (0.015 * md);
}

void SsAdxRaw(const Bar &b[], int from, int len, int n, double &adx, double &pdi, double &ndi)
{
   double pdm = 0, ndm = 0, tr = 0;
   for(int i = len - n; i < len; i++)
   {
      if(i < 1) continue;
      int a = from + i, p = from + i - 1;
      double up = b[a].h - b[p].h, dn = b[p].l - b[a].l;
      if(up > dn && up > 0) pdm += up;
      if(dn > up && dn > 0) ndm += dn;
      tr += MathMax(b[a].h - b[a].l, MathMax(MathAbs(b[a].h - b[p].c), MathAbs(b[a].l - b[p].c)));
   }
   if(tr == 0) { adx = 0; pdi = 0; ndi = 0; return; }
   pdi = pdm / tr * 100; ndi = ndm / tr * 100;
   adx = (pdi + ndi == 0) ? 0 : MathAbs(pdi - ndi) / (pdi + ndi) * 100;
}

// Wilder ADX - app ka adx(b,n): aakhri n*10+1 candles
void SsAdx(const Bar &b[], int n, double &adx, double &pdi, double &ndi)
{
   int total = ArraySize(b);
   int len = n * 10 + 1; if(len > total) len = total;
   int from = total - len;
   if(len < 2 * n + 1) { SsAdxRaw(b, from, len, n, adx, pdi, ndi); return; }
   double tr = 0, pdm = 0, ndm = 0, dxSum = 0, ax = 0;
   pdi = 0; ndi = 0;
   for(int i = 1; i < len; i++)
   {
      int a = from + i, p = from + i - 1;
      double up = b[a].h - b[p].h, dn = b[p].l - b[a].l;
      double pp = (up > dn && up > 0) ? up : 0;
      double mm = (dn > up && dn > 0) ? dn : 0;
      double t = MathMax(b[a].h - b[a].l, MathMax(MathAbs(b[a].h - b[p].c), MathAbs(b[a].l - b[p].c)));
      if(i <= n)
      {
         tr += t; pdm += pp; ndm += mm;
         if(i < n) continue;
      }
      else
      {
         tr = tr - tr / n + t; pdm = pdm - pdm / n + pp; ndm = ndm - ndm / n + mm;
      }
      pdi = (tr != 0) ? pdm / tr * 100 : 0;
      ndi = (tr != 0) ? ndm / tr * 100 : 0;
      double dx = (pdi + ndi != 0) ? MathAbs(pdi - ndi) / (pdi + ndi) * 100 : 0;
      int k = i - n + 1;
      if(k <= n)
      {
         dxSum += dx;
         if(k == n) ax = dxSum / n; else ax = dxSum / k;
      }
      else ax = (ax * (n - 1) + dx) / n;
   }
   adx = ax;
}

bool SsPsarUp(const Bar &b[])
{
   double c[];
   SsCloses(b, c);
   return SsEmaLast(c, 5) > SsEmaLast(c, 13);
}

void SsTfBias(const Bar &b[], TfInfo &r)
{
   double c[];
   SsCloses(b, c);
   int n = ArraySize(c);
   double e20 = SsEmaLast(c, 20), e50 = SsEmaLast(c, 50);
   int sd[]; double sl[]; double sa[];
   SsSupertrend(b, 10, 3, sd, sl, sa);
   double rv = SsRsiLast(c, 14);
   double h[];
   SsMacdH(c, h);
   double price = c[n - 1];
   double score = 0;
   if(e20 > e50) score += 2; else score -= 2;
   if(price > e50) score += 1; else score -= 1;
   if(sd[n - 1] == 1) score += 2; else score -= 2;
   if(rv > 55) score += 1; else if(rv < 45) score -= 1;
   if(h[n - 1] > 0) score += 1; else score -= 1;
   r.bias = (score >= 2) ? SS_BUY : (score <= -2) ? SS_SELL : SS_HOLD;
   r.score = score; r.price = price; r.rsi = rv; r.atr = sa[n - 1];
   r.stDir = sd[n - 1]; r.stLine = sl[n - 1];
   r.e20 = e20; r.e50 = e50; r.macd = h[n - 1];
}

int SsTfBiasDir(const Bar &b[])
{
   TfInfo r;
   SsTfBias(b, r);
   return r.bias;
}

// ---------------- 50 agents (app ke AGENTS, isi kram me) ----------------
void SsAgents(const Bar &b[], int h1, int h4, int d1, double p, int &v[])
{
   ArrayResize(v, SS_NAGENTS);
   double c[];
   SsCloses(b, c);
   int n = ArraySize(c) - 1;
   int L = ArraySize(b);
   int sd[]; double sl[]; double sa[];
   SsSupertrend(b, 10, 3, sd, sl, sa);
   double rArr[];
   SsRsi(c, 14, rArr);
   double r = rArr[n], at = sa[n];
   int st = sd[n];
   int e200len = 200; if(e200len > ArraySize(c) - 1) e200len = ArraySize(c) - 1;
   double ma, mb, e;
   double adx, pdi, ndi;
   SsAdx(b, 14, adx, pdi, ndi);
   double hArr[];
   SsMacdH(c, hArr);

   // --- TREND ---
   ma = SsEmaLast(c, 9); mb = SsEmaLast(c, 21);
   v[0] = (ma > mb * 1.0002) ? SS_BUY : (ma < mb * 0.9998) ? SS_SELL : SS_HOLD;
   ma = SsEmaLast(c, 20); mb = SsEmaLast(c, 50);
   v[1] = (ma > mb) ? SS_BUY : (ma < mb) ? SS_SELL : SS_HOLD;
   ma = SsEmaLast(c, 50); mb = SsEmaLast(c, e200len);
   v[2] = (ma > mb) ? SS_BUY : (ma < mb) ? SS_SELL : SS_HOLD;
   ma = SsSmaLast(c, 10); mb = SsSmaLast(c, 30);
   v[3] = (ma > mb) ? SS_BUY : (ma < mb) ? SS_SELL : SS_HOLD;
   e = SsEmaLast(c, 50);
   v[4] = (p > e * 1.0005) ? SS_BUY : (p < e * 0.9995) ? SS_SELL : SS_HOLD;
   e = SsEmaLast(c, e200len);
   v[5] = (p > e) ? SS_BUY : (p < e) ? SS_SELL : SS_HOLD;
   v[6] = (st == 1) ? SS_BUY : SS_SELL;
   v[7] = (SsStDirLast(b, 7, 2) == 1) ? SS_BUY : SS_SELL;
   v[8] = (SsStDirLast(b, 14, 4) == 1) ? SS_BUY : SS_SELL;
   v[9] = (hArr[n] > 0) ? SS_BUY : (hArr[n] < 0) ? SS_SELL : SS_HOLD;
   v[10] = (hArr[n] > hArr[n - 1]) ? SS_BUY : SS_SELL;
   v[11] = (adx < 20) ? SS_HOLD : (pdi > ndi) ? SS_BUY : SS_SELL;
   v[12] = (adx < 25) ? SS_HOLD : (pdi > ndi) ? SS_BUY : SS_SELL;
   v[13] = SsPsarUp(b) ? SS_BUY : SS_SELL;

   // --- MOMENTUM ---
   v[14] = (r > 55) ? SS_BUY : (r < 45) ? SS_SELL : SS_HOLD;
   v[15] = (r < 30) ? SS_BUY : (r > 70) ? SS_SELL : SS_HOLD;
   double r7 = SsRsiLast(c, 7);
   v[16] = (r7 > 60) ? SS_BUY : (r7 < 40) ? SS_SELL : SS_HOLD;
   double r21 = SsRsiLast(c, 21);
   v[17] = (r21 > 52) ? SS_BUY : (r21 < 48) ? SS_SELL : SS_HOLD;
   {
      bool pUp = c[n] > c[n - 5], rUp = rArr[n] > rArr[n - 5];
      v[18] = (pUp && !rUp) ? SS_SELL : (!pUp && rUp) ? SS_BUY : SS_HOLD;
   }
   double k14 = SsStoch(b, 14);
   v[19] = (k14 < 20) ? SS_BUY : (k14 > 80) ? SS_SELL : SS_HOLD;
   double k5 = SsStoch(b, 5);
   v[20] = (k5 > 60) ? SS_BUY : (k5 < 40) ? SS_SELL : SS_HOLD;
   double cc = SsCci(b, 20);
   v[21] = (cc > 100) ? SS_BUY : (cc < -100) ? SS_SELL : SS_HOLD;
   v[22] = (cc > 0) ? SS_BUY : SS_SELL;
   {
      double hh = SsHH(b, 14), ll = SsLL(b, 14);
      double w = (hh == ll) ? -50 : (hh - p) / (hh - ll) * -100;
      v[23] = (w < -80) ? SS_BUY : (w > -20) ? SS_SELL : SS_HOLD;
   }
   {
      double roc = (c[n] - c[n - 10]) / c[n - 10] * 100;
      v[24] = (roc > 0.15) ? SS_BUY : (roc < -0.15) ? SS_SELL : SS_HOLD;
   }
   v[25] = (c[n] > c[n - 20]) ? SS_BUY : SS_SELL;

   // --- VOLATILITY / CHANNEL ---
   double m20 = SsSmaLast(c, 20), sd20 = SsStdev(c, 20);
   v[26] = (p < m20 - 2 * sd20) ? SS_BUY : (p > m20 + 2 * sd20) ? SS_SELL : SS_HOLD;
   v[27] = (p > m20) ? SS_BUY : SS_SELL;
   v[28] = (sd20 / m20 < 0.0015) ? SS_HOLD : (p > m20) ? SS_BUY : SS_SELL;
   double e20 = SsEmaLast(c, 20);
   v[29] = (p > e20 + 1.5 * at) ? SS_BUY : (p < e20 - 1.5 * at) ? SS_SELL : SS_HOLD;
   {
      double hh = SsHH(b, 20), ll = SsLL(b, 20);
      v[30] = (p >= hh * 0.999) ? SS_BUY : (p <= ll * 1.001) ? SS_SELL : SS_HOLD;
   }
   {
      int nn = 55; if(nn > L) nn = L;
      double hh = SsHH(b, nn), ll = SsLL(b, nn);
      v[31] = (p >= hh * 0.999) ? SS_BUY : (p <= ll * 1.001) ? SS_SELL : SS_HOLD;
   }
   {
      double t14[];
      SsAtr(b, 14, t14);
      int tn = ArraySize(t14) - 1;
      v[32] = (t14[tn] < t14[tn - 5]) ? SS_HOLD : (p > c[L - 2]) ? SS_BUY : SS_SELL;
   }
   {
      double hh = SsHH(b, 30), ll = SsLL(b, 30);
      double pos = (hh == ll) ? 0.5 : (p - ll) / (hh - ll);
      v[33] = (pos < 0.25) ? SS_BUY : (pos > 0.75) ? SS_SELL : SS_HOLD;
   }
   {
      double pct = at / p * 100;
      v[34] = (pct < 0.03 || pct > 2) ? SS_HOLD : (p > e20) ? SS_BUY : SS_SELL;
   }
   v[35] = (p > m20 + sd20) ? SS_BUY : (p < m20 - sd20) ? SS_SELL : SS_HOLD;

   // --- PRICE ACTION ---
   {
      bool hi = b[n].h > b[n - 2].h, lo = b[n].l > b[n - 2].l;
      v[36] = (hi && lo) ? SS_BUY : (!hi && !lo) ? SS_SELL : SS_HOLD;
   }
   {
      Bar a = b[n], pv = b[n - 1];
      if(a.c > a.o && pv.c < pv.o && a.c > pv.o && a.o < pv.c) v[37] = SS_BUY;
      else if(a.c < a.o && pv.c > pv.o && a.c < pv.o && a.o > pv.c) v[37] = SS_SELL;
      else v[37] = SS_HOLD;
   }
   v[38] = SS_HOLD;      // Pin Bar band (app v9.9.36 jaisa) - jagah wahi, vote me nahi
   if(b[n - 1].h < b[n - 2].h && b[n - 1].l > b[n - 2].l)
      v[39] = (b[n].c > b[n - 1].h) ? SS_BUY : (b[n].c < b[n - 1].l) ? SS_SELL : SS_HOLD;
   else v[39] = SS_HOLD;
   {
      bool up = true, dn = true;
      for(int i = 0; i < 3; i++)
      {
         if(!(b[n - i].c > b[n - i].o)) up = false;
         if(!(b[n - i].c < b[n - i].o)) dn = false;
      }
      v[40] = up ? SS_BUY : dn ? SS_SELL : SS_HOLD;
   }
   {
      Bar a = b[n];
      double rg = a.h - a.l;
      if(rg == 0) v[41] = SS_HOLD;
      else
      {
         double bd = (a.c - a.o) / rg;
         v[41] = (bd > 0.5) ? SS_BUY : (bd < -0.5) ? SS_SELL : SS_HOLD;
      }
   }
   v[42] = (b[n].o > b[n - 1].c * 1.0003) ? SS_BUY : (b[n].o < b[n - 1].c * 0.9997) ? SS_SELL : SS_HOLD;
   {
      int up = 0;
      int from = L - 5; if(from < 0) from = 0;
      for(int i = from; i < L; i++) if(b[i].c > b[i].o) up++;
      v[43] = (up >= 4) ? SS_BUY : (up <= 1) ? SS_SELL : SS_HOLD;
   }
   {
      double hh = SsHH(b, 24), ll = SsLL(b, 24), rg = hh - ll;
      if(rg == 0) v[44] = SS_HOLD;
      else v[44] = ((p - ll) / rg < 0.2) ? SS_BUY : ((hh - p) / rg < 0.2) ? SS_SELL : SS_HOLD;
   }
   {
      Bar a = b[L - 2];
      double pp = (a.h + a.l + a.c) / 3;
      v[45] = (p > pp) ? SS_BUY : SS_SELL;
   }

   // --- HIGHER TF ---
   v[46] = h1; v[47] = h4; v[48] = d1;
   if(h1 == SS_BUY && h4 == SS_BUY && d1 == SS_BUY) v[49] = SS_BUY;
   else if(h1 == SS_SELL && h4 == SS_SELL && d1 == SS_SELL) v[49] = SS_SELL;
   else v[49] = SS_HOLD;
}

void SsVoteCount(const int &v[], int &buy, int &sell, int &hold, int &verdict, int &conf)
{
   buy = 0; sell = 0; hold = 0;
   for(int i = 0; i < SS_NAGENTS; i++)
   {
      if(v[i] == SS_BUY) buy++;
      else if(v[i] == SS_SELL) sell++;
      else if(i != 38) hold++;
   }
   verdict = (buy > sell) ? SS_BUY : (sell > buy) ? SS_SELL : SS_HOLD;
   int lead = (buy > sell) ? buy : sell;
   conf = (int)SsRound((double)lead / SS_NACTIVE * 100);
}

// ---------------- app ka analyse(): 10 checks, ok 0/1/2 ----------------
// ok[] kram: 0 STRUCTURE, 1 SUPERTREND, 2 MOMENTUM, 3 MACD, 4 ADX, 5 ENTRY LOCATION,
//            6 BOLLINGER, 7 SL vs VOLATILITY, 8 HIGHER TIMEFRAME, 9 50 AGENTS
int SsAnalyse(const Bar &b[], int dir, double slPips, double pip, int tfAgree, int tfCount,
              int vVerdict, int vConf, int &ok[])
{
   ArrayResize(ok, 10);
   double c[];
   SsCloses(b, c);
   int n = ArraySize(c);
   double p = c[n - 1];
   double e20 = SsEmaLast(c, 20), e50 = SsEmaLast(c, 50);
   int e200len = 200; if(e200len > n - 1) e200len = n - 1;
   double e200 = SsEmaLast(c, e200len);
   int sd[]; double sl[]; double sa[];
   SsSupertrend(b, 10, 3, sd, sl, sa);
   double r = SsRsiLast(c, 14);
   double hArr[];
   SsMacdH(c, hArr);
   double h = hArr[n - 1];
   double adx, pdi, ndi;
   SsAdx(b, 14, adx, pdi, ndi);
   double at = sa[n - 1];
   double hi = SsHH(b, 30), lo = SsLL(b, 30);
   double pos = (hi == lo) ? 50 : (p - lo) / (hi - lo) * 100;
   double sdv = SsStdev(c, 20), mid = SsSmaLast(c, 20);
   double bbPos = (sdv != 0) ? (p - mid) / (2 * sdv) * 100 : 0;
   bool up = (dir == SS_BUY);

   bool strong = up ? (p > e20 && e20 > e50 && e50 > e200) : (p < e20 && e20 < e50 && e50 < e200);
   bool partial = up ? (p > e50) : (p < e50);
   ok[0] = strong ? 2 : partial ? 1 : 0;
   ok[1] = (sd[n - 1] == (up ? 1 : -1)) ? 2 : 0;
   bool rOk = up ? (r > 52 && r < 72) : (r < 48 && r > 28);
   bool rExt = up ? (r > 75) : (r < 25);
   ok[2] = rExt ? 0 : rOk ? 2 : 1;
   ok[3] = (up ? h > 0 : h < 0) ? 2 : 0;
   bool dirOk = up ? (pdi > ndi) : (ndi > pdi);
   ok[4] = (adx > 25 && dirOk) ? 2 : (adx < 20) ? 0 : 1;
   bool badLoc = up ? (pos > 80) : (pos < 20);
   ok[5] = badLoc ? 0 : (up ? pos < 55 : pos > 45) ? 2 : 1;
   ok[6] = (MathAbs(bbPos) > 95) ? 0 : 1;
   double atrPips = at / pip;
   ok[7] = (slPips > atrPips * 0.8) ? 2 : 0;
   ok[8] = (tfAgree >= tfCount - 1) ? 2 : (tfAgree >= 2) ? 1 : 0;
   ok[9] = (vConf >= 70 && vVerdict == dir) ? 2 : (vVerdict == dir) ? 1 : 0;
   int score = 0;
   for(int i = 0; i < 10; i++) score += ok[i];
   return (int)SsRound((double)score / 20 * 100);
}

// ---------------- signal umar: 0 FRESH, 1 CHAL RAHA, 2 PURANA, 3 LATE, -1 nahi ----------------
int SsSigAge(const Bar &b[], int dir, double live, double tpDist, int &candles, int &pct)
{
   int len = ArraySize(b);
   candles = 0; pct = 0;
   if(len < 70 || (dir != SS_BUY && dir != SS_SELL)) return -1;
   int maxBack = len - 60; if(maxBack > 48) maxBack = 48;
   int nb = 0;
   Bar t[];
   for(int k = 1; k <= maxBack; k++)
   {
      ArrayResize(t, len - k);
      for(int i = 0; i < len - k; i++) t[i] = b[i];
      if(SsTfBiasDir(t) != dir) break;
      nb = k;
   }
   double b0c = b[len - 1 - nb].c;
   double moved = (dir == SS_BUY) ? live - b0c : b0c - live;
   pct = (tpDist > 0) ? (int)SsRound(moved / tpDist * 100) : 0;
   candles = nb + 1;
   if(pct >= 50) return 3;
   if(candles >= 10) return 2;
   if(candles <= 2 && pct < 25) return 0;
   return 1;
}

// ---------------- EMA Plan ki direction (9/21/55) - raw candles par ----------------
int SsEmaPlanDir(const Bar &raw[], double pip)
{
   int n = ArraySize(raw);
   if(n < 60) return -99;                 // plan bana hi nahi
   double c[];
   SsCloses(raw, c);
   double e9[]; double e21[]; double e55[];
   SsEma(c, 9, e9); SsEma(c, 21, e21); SsEma(c, 55, e55);
   int i = n - 1;
   double a14[];
   SsAtr(raw, 14, a14);
   double a = a14[i];
   if(a == 0) a = pip * 10;
   bool bull = e9[i] > e21[i] && e21[i] > e55[i];
   bool bear = e9[i] < e21[i] && e21[i] < e55[i];
   if(!bull && !bear) return SS_HOLD;
   int j = i - 10; if(j < 0) j = 0;
   double slope = e55[i] - e55[j];
   if((bull && slope <= 0) || (bear && slope >= 0) || MathAbs(e9[i] - e55[i]) < 0.3 * a) return SS_HOLD;
   return bull ? SS_BUY : SS_SELL;
}

// ---------------- quality score (runAnalyze) ----------------
int SsQuality(const TfInfo &base, const TfInfo &h1, const TfInfo &h4, const TfInfo &d1)
{
   double q = 0;
   int dir = base.bias;
   if(dir != SS_HOLD)
   {
      q += 22;
      if(h1.bias == dir) q += 16;
      if(h4.bias == dir) q += 20;
      if(d1.bias == dir) q += 18;
      if(base.stDir == (dir == SS_BUY ? 1 : -1)) q += 10;
      double rv = base.rsi;
      if(dir == SS_BUY && rv > 50 && rv < 72) q += 8;
      else if(dir == SS_SELL && rv < 50 && rv > 28) q += 8;
      if(dir == SS_BUY ? base.macd > 0 : base.macd < 0) q += 6;
      double atrPct = base.atr / base.price * 100;
      if(!(atrPct > 0.04 && atrPct < 1.6)) q -= 10;
   }
   q = SsRound(q);
   if(q < 0) q = 0;
   if(q > 100) q = 100;
   return (int)q;
}

// ---------------- FAISLA (finalCall) ----------------
#define SS_WAIT   0
#define SS_MARKET 1
#define SS_LIMIT  2
#define SS_STOP   3
// why bits - EA inhe padh kar wajah likhta hai
#define W_AGENTS   1
#define W_STRUCT   2
#define W_TECH40   4
#define W_NEWS     8
#define W_HTF      16
#define W_RR       32
#define W_VOTE     64
#define W_TECH55   128
#define W_Q60      256
#define C_Q70      512
#define C_TECH65   1024
#define C_ST       2048
#define C_EMA      4096
#define C_HTFRULE  8192
#define T_LATE     16384
#define T_PURANA   32768
#define T_LOC      65536
#define T_RSI      131072
#define T_CHASE    262144
#define O_SL       524288

int SsFinalCall(int dir, int q, int pct, const int &ok[], int vVerdict, int vConf, double rr,
                bool news, int htfAgree, int htfCount, int age, double rsiv, int emaDir,
                bool chase, bool htfRule, int &why)
{
   why = 0;
   if(dir != SS_BUY && dir != SS_SELL) return SS_WAIT;
   int nSkip = 0, nHard = 0, nT = 0, nC = 0, nO = 0;
   bool nearCore = false;

   if(vVerdict != dir && vVerdict != SS_HOLD) { nSkip++; why |= W_AGENTS; }
   if(ok[0] == 0) { nSkip++; why |= W_STRUCT; }
   if(pct < 40) { nSkip++; why |= W_TECH40; }

   if(news) { nHard++; why |= W_NEWS; }
   if(htfCount == 0 || htfAgree == 0) { nHard++; why |= W_HTF; }
   if(!(rr >= 2)) { nHard++; why |= W_RR; }
   if(!(vVerdict == dir && vConf >= 55)) { nHard++; why |= W_VOTE; }
   if(!(pct < 40) && !(pct >= 55)) { nHard++; why |= W_TECH55; }
   if(!(q >= 60)) { nHard++; why |= W_Q60; }

   if(q >= 60 && !(q >= 70)) { nC++; nearCore = true; why |= C_Q70; }
   if(pct >= 55 && !(pct >= 65)) { nC++; nearCore = true; why |= C_TECH65; }
   if(ok[1] == 0) { nC++; why |= C_ST; }
   if(emaDir != -99 && emaDir != dir) { nC++; why |= C_EMA; }
   if(htfRule) { nC++; why |= C_HTFRULE; }

   if(age == 3) { nT++; why |= T_LATE; }
   if(age == 2) { nT++; why |= T_PURANA; }
   if(ok[5] == 0) { nT++; why |= T_LOC; }
   if(rsiv > 75 || rsiv < 25) { nT++; why |= T_RSI; }
   if(chase) { nT++; why |= T_CHASE; }

   if(ok[7] == 0) { nO++; why |= O_SL; }

   if(nSkip > 0) return SS_WAIT;
   if(nHard > 0) return SS_WAIT;
   if(nT > 0 && nC > 0) return SS_WAIT;
   if(nT + nC + nO >= 3) return SS_WAIT;
   if(nT > 0) return SS_LIMIT;
   if(nearCore || nC >= 2 || (nC == 1 && nO == 1)) return SS_STOP;
   return SS_MARKET;
}

// LIMIT/STOP kitni door (price me). raw = aakhri candle samet.
double SsOrderOff(const Bar &raw[], int dir, int type, double live, double atr, int age, double fallback)
{
   if(!(atr > 0)) return fallback;
   if(type == SS_LIMIT) return ((age == 3) ? 0.6 : 0.35) * atr;
   int L = ArraySize(raw);
   int from = L - 6; if(from < 0) from = 0;
   double off = 0.25 * atr;
   if(L > 0)
   {
      double hx = raw[from].h, lx = raw[from].l;
      for(int i = from; i < L; i++) { if(raw[i].h > hx) hx = raw[i].h; if(raw[i].l < lx) lx = raw[i].l; }
      double edge = (dir == SS_BUY) ? hx + 0.1 * atr - live : live - (lx - 0.1 * atr);
      if(edge > off) off = edge;
   }
   if(off > 1.5 * atr) off = 1.5 * atr;
   return off;
}

// Poora hisaab ek pair ka - app ka runAnalyze + finalCall.
// m15raw/h1raw/h4raw/d1raw = 120 candles, aakhri adhoori (live) candle samet.
struct SsResult {
   int dir; int q; int pct; int buy; int sell; int hold; int verdict; int conf;
   int age; int ageCandles; int agePct; int emaDir; bool chase; bool htfRule;
   int decision; int why; double off; double atr; double rsi; int htfAgree;
};

void SsDropLast(const Bar &raw[], Bar &out[])
{
   int n = ArraySize(raw) - 1;
   if(n < 0) n = 0;
   ArrayResize(out, n);
   for(int i = 0; i < n; i++) out[i] = raw[i];
}

void SsEvaluate(const Bar &m15raw[], const Bar &h1raw[], const Bar &h4raw[], const Bar &d1raw[],
                double pip, double slDist, double tpDist, double rr, bool news, SsResult &R)
{
   Bar m15[]; Bar h1b[]; Bar h4b[]; Bar d1b[];
   SsDropLast(m15raw, m15); SsDropLast(h1raw, h1b); SsDropLast(h4raw, h4b); SsDropLast(d1raw, d1b);
   TfInfo base; TfInfo t1; TfInfo t4; TfInfo td;
   SsTfBias(m15, base); SsTfBias(h1b, t1); SsTfBias(h4b, t4); SsTfBias(d1b, td);
   double live = m15raw[ArraySize(m15raw) - 1].c;
   int dir = base.bias;
   R.dir = dir; R.atr = base.atr; R.rsi = base.rsi;

   int v[];
   SsAgents(m15, t1.bias, t4.bias, td.bias, live, v);
   int vb, vs, vh, vv, vc;
   SsVoteCount(v, vb, vs, vh, vv, vc);
   R.buy = vb; R.sell = vs; R.hold = vh; R.verdict = vv; R.conf = vc;

   R.q = SsQuality(base, t1, t4, td);
   int htfAgree = 0;
   if(t4.bias == dir) htfAgree++;
   if(td.bias == dir) htfAgree++;
   R.htfAgree = htfAgree;
   int tfAgree = 0;
   if(base.bias == dir) tfAgree++;
   if(t1.bias == dir) tfAgree++;
   if(t4.bias == dir) tfAgree++;
   if(td.bias == dir) tfAgree++;

   double slPips = SsRound(slDist / pip * 10) / 10;
   int ok[];
   R.pct = SsAnalyse(m15, dir, slPips, pip, tfAgree, 4, R.verdict, R.conf, ok);
   int ac, ap;
   R.age = SsSigAge(m15, dir, live, tpDist, ac, ap);
   R.ageCandles = ac; R.agePct = ap;
   R.emaDir = SsEmaPlanDir(m15raw, pip);
   int opp = (dir == SS_BUY) ? SS_SELL : SS_BUY;
   bool sfOn = (dir == SS_BUY || dir == SS_SELL);
   R.chase = sfOn && (v[33] == opp || v[44] == opp);
   R.htfRule = sfOn && (v[49] == opp);
   int why;
   R.decision = SsFinalCall(dir, R.q, R.pct, ok, R.verdict, R.conf, rr, news, htfAgree, 2,
                            R.age, base.rsi, R.emaDir, R.chase, R.htfRule, why);
   R.why = why;
   R.off = 0;
   if(R.decision == SS_LIMIT || R.decision == SS_STOP)
      R.off = SsOrderOff(m15raw, dir, R.decision, live, base.atr, R.age, 5 * pip);
}
//CORE>>

//<<MODES - v1.05: market ka mood (TREND / NORMAL / RANGE) + auto SL/TP (ATR se).
// Core (upar) app jaisa hi faisla deta hai - ye hissa uske baad lagta hai:
//  * NORMAL : core ka faisla, SL = 1.2 ATR, TP = 1.6x SL
//  * TREND  : ADX tagda + EMA 9>21>55 + 1H/4H saath. Core sirf timing
//             (RSI/umar/chase/kinara) ki wajah se WAIT/LIMIT bole to bhi
//             EMA9 pullback pe entry. TP = 2x SL
//  * RANGE  : ADX kam. Core WAIT ho to range ke kinare se beech tak chhota trade
// TP kabhi $min se kam nahi, $max se zyada nahi; SL $max se bada ho to trade nahi.
#define MD_NORMAL 0
#define MD_TREND  1
#define MD_RANGE  2

#define SK_NONE   0
#define SK_CORE   1    // core WAIT, koi mode nahi laga
#define SK_DATA   2
#define SK_BIGSL  3    // SL $ seema se bada
#define SK_QUIET  4    // market shaant - $min target bahut door
#define SK_RR     5    // range me R:R kam
#define SK_STRECH 6    // trend me price EMA se bahut door
#define SK_NOCONF 7    // trend pullback par confirm candle nahi
#define SK_LOC    8    // A+: entry range ke galat kinare pe (chase)

struct SsModeCfg {
   bool   trendOn; bool rangeOn;
   double slAtr;  double rrTrend; double rrNormal; double rrRangeMin;
   double minTpUsd; double maxTpUsd; double maxSlUsd; double maxTpAtr;
   double trendAdx; double rangeAdx; int rangeBars;
   bool   aplus; double minSlPips; double maxSlAtr; double posMaxNormal; double posMaxTrend;
   int    swingBars; double rrMin;
};

struct SsPlan {
   int mode; int decision; int dir; double off; double sl; double tp;
   double adx; double slUsd; double tpUsd; int skip; bool viaMode;
};

int SsRegime(const Bar &m15[], int dir, int h1Bias, int h4Bias, const SsModeCfg &K, double &adx)
{
   double pdi, ndi;
   SsAdx(m15, 14, adx, pdi, ndi);
   double c[];
   SsCloses(m15, c);
   double e9 = SsEmaLast(c, 9), e21 = SsEmaLast(c, 21), e55 = SsEmaLast(c, 55);
   bool up = adx >= K.trendAdx && pdi > ndi && e9 > e21 && e21 > e55 && h1Bias == SS_BUY && h4Bias == SS_BUY;
   bool dn = adx >= K.trendAdx && ndi > pdi && e9 < e21 && e21 < e55 && h1Bias == SS_SELL && h4Bias == SS_SELL;
   if((dir == SS_BUY && up) || (dir == SS_SELL && dn)) return MD_TREND;
   if(adx < K.rangeAdx) return MD_RANGE;
   return MD_NORMAL;
}

// TP/SL ko $ seemaon me rakho. false = trade nahi (P.skip me wajah)
bool SsFitUsd(double atr, double usdPerPrice, const SsModeCfg &K, SsPlan &P)
{
   P.slUsd = P.sl * usdPerPrice;
   if(P.slUsd > K.maxSlUsd) { P.skip = SK_BIGSL; return false; }
   double tpUsd = P.tp * usdPerPrice;
   if(tpUsd > K.maxTpUsd) P.tp = K.maxTpUsd / usdPerPrice;
   if(tpUsd < K.minTpUsd)
   {
      double need = K.minTpUsd / usdPerPrice;
      if(need > K.maxTpAtr * atr) { P.skip = SK_QUIET; return false; }
      P.tp = need;
   }
   P.tpUsd = P.tp * usdPerPrice;
   return true;
}

// v1.07 A+ : (1) jagah - BUY sirf range ke neeche wale hisse se, SELL upar wale se
// (kinare pe ho to LIMIT pullback pe, door ho to trade nahi), (2) SL pichhle swing
// ke peeche (kam se kam minSlPips), (3) TP = SL x rr, R:R kam se kam rrMin.
bool SsAplus(const Bar &m15[], double live, double spread, double pip, double atr, double rr,
             double usdPerPrice, const SsModeCfg &K, SsPlan &P)
{
   bool buy = (P.dir == SS_BUY);
   bool rangeTrade = (P.mode == MD_RANGE && P.viaMode);
   double sgnOff = 0;
   if(P.decision == SS_LIMIT) sgnOff = buy ? -P.off : P.off;
   if(P.decision == SS_STOP)  sgnOff = buy ? P.off : -P.off;
   double entry = live + sgnOff;
   if(!rangeTrade)
   {
      double hi = SsHH(m15, K.rangeBars), lo = SsLL(m15, K.rangeBars), w = hi - lo;
      double maxPos = (P.mode == MD_TREND) ? K.posMaxTrend : K.posMaxNormal;
      if(w > 0)
      {
         double pos = buy ? (entry - lo) / w : (hi - entry) / w;
         if(pos > maxPos)
         {
            if(P.decision == SS_STOP) { P.skip = SK_LOC; return false; }
            double target = buy ? lo + maxPos * w : hi - maxPos * w;
            double off = buy ? live - target : target - live;
            if(off > 1.5 * atr) { P.skip = SK_LOC; return false; }
            if(off < 0.25 * atr) off = 0.25 * atr;
            P.decision = SS_LIMIT; P.off = off;
            entry = buy ? live - off : live + off;
         }
      }
   }
   double fill = (buy && P.decision == SS_MARKET) ? entry + spread : entry;   // BUY market ask pe
   double sl, tp;
   if(rangeTrade) sl = P.sl;                                     // range: kinare ke bahar (pehle se)
   else
   {
      double sw = buy ? SsLL(m15, K.swingBars) - 0.3 * atr : SsHH(m15, K.swingBars) + 0.3 * atr + spread;
      sl = buy ? fill - sw : sw - fill;
      if(sl > K.maxSlAtr * atr) sl = K.maxSlAtr * atr;
      if(sl < K.slAtr * atr) sl = K.slAtr * atr;
   }
   if(sl < K.minSlPips * pip) sl = K.minSlPips * pip;
   if(sl < 3 * spread) sl = 3 * spread;
   tp = rangeTrade ? P.tp : sl * rr;
   P.sl = sl; P.tp = tp;
   if(!SsFitUsd(atr, usdPerPrice, K, P)) return false;
   if(P.tp / P.sl < (rangeTrade ? K.rrRangeMin : K.rrMin)) { P.skip = SK_RR; return false; }
   return true;
}

// SL/TP lagao. false = trade nahi (P.skip me wajah)
bool SsSize(const Bar &m15[], double live, double spread, double pip, double atr, double rr,
            double usdPerPrice, const SsModeCfg &K, SsPlan &P)
{
   P.skip = SK_NONE;
   if(K.aplus) return SsAplus(m15, live, spread, pip, atr, rr, usdPerPrice, K, P);
   if(!(P.mode == MD_RANGE && P.viaMode))
   {
      P.sl = K.slAtr * atr; if(P.sl < 3 * spread) P.sl = 3 * spread;
      P.tp = P.sl * rr;
   }
   return SsFitUsd(atr, usdPerPrice, K, P);
}

// m15 = sirf band candles. live = abhi ka bid. usdPerPrice = 1.0 price chalne pe kitne $ (is lot pe)
void SsMakePlan(const Bar &m15[], double live, double spread, double pip, int h1Bias, int h4Bias,
                const SsResult &R, bool news, double usdPerPrice, const SsModeCfg &K, SsPlan &P)
{
   P.mode = MD_NORMAL; P.decision = SS_WAIT; P.dir = R.dir; P.off = 0; P.sl = 0; P.tp = 0;
   P.adx = 0; P.slUsd = 0; P.tpUsd = 0; P.skip = SK_CORE; P.viaMode = false;
   double atr = R.atr;
   int n = ArraySize(m15);
   if(!(atr > 0) || !(usdPerPrice > 0) || n < 60) { P.skip = SK_DATA; return; }
   double adx;
   int reg = SsRegime(m15, R.dir, h1Bias, h4Bias, K, adx);
   P.adx = adx;
   if(!K.trendOn && reg == MD_TREND) reg = MD_NORMAL;
   P.mode = reg;

   if(R.decision != SS_WAIT && !(reg == MD_TREND && R.decision == SS_LIMIT))
   {
      // core ne trade bola - wahi, bas SL/TP (aur A+ me jagah) market ke hisaab se
      P.decision = R.decision; P.dir = R.dir; P.off = R.off;
      if(!SsSize(m15, live, spread, pip, atr, (reg == MD_TREND) ? K.rrTrend : K.rrNormal, usdPerPrice, K, P))
         P.decision = SS_WAIT;
      return;
   }
   if(news) return;
   double lastO = m15[n - 1].o, lastC = m15[n - 1].c, prevC = m15[n - 2].c;

   if(reg == MD_TREND)
   {
      // sirf timing / halki kami maaf. Direction ki kami (agents, structure, HTF,
      // vote, quality, technical, supertrend, EMA Plan, HTF rule) ho to nahi.
      int block = W_AGENTS | W_STRUCT | W_TECH40 | W_NEWS | W_HTF | W_VOTE | W_TECH55 | W_Q60 |
                  C_ST | C_EMA | C_HTFRULE;
      if((R.why & block) != 0) return;
      double c[];
      SsCloses(m15, c);
      double e9 = SsEmaLast(c, 9), e21 = SsEmaLast(c, 21);
      double dist = (R.dir == SS_BUY) ? live - e9 : e9 - live;
      bool aboveSlow = (R.dir == SS_BUY) ? live > e21 : live < e21;
      bool candleOk = (R.dir == SS_BUY) ? (lastC > lastO) : (lastC < lastO);
      P.dir = R.dir; P.viaMode = true;
      if(dist > 0.3 * atr)
      {
         if(dist > 2.5 * atr) { P.skip = SK_STRECH; return; }
         P.decision = SS_LIMIT;
         P.off = dist;
         if(P.off < 0.25 * atr) P.off = 0.25 * atr;
         if(P.off > 1.5 * atr) P.off = 1.5 * atr;
      }
      else
      {
         if(!aboveSlow || !candleOk) { P.skip = SK_NOCONF; return; }
         P.decision = SS_MARKET;
      }
      if(!SsSize(m15, live, spread, pip, atr, K.rrTrend, usdPerPrice, K, P)) P.decision = SS_WAIT;
      return;
   }

   if(reg == MD_RANGE && K.rangeOn)
   {
      double hi = SsHH(m15, K.rangeBars), lo = SsLL(m15, K.rangeBars);
      double w = hi - lo;
      if(w < 3 * atr || live <= lo || live >= hi) return;
      double rsi = R.rsi;
      int d = SS_HOLD;
      if(live <= lo + 0.25 * w && rsi <= 40 && lastC > lastO && lastC > prevC) d = SS_BUY;
      else if(live >= hi - 0.25 * w && rsi >= 60 && lastC < lastO && lastC < prevC) d = SS_SELL;
      if(d == SS_HOLD) return;
      double entry = (d == SS_BUY) ? live + spread : live;
      double slPx = (d == SS_BUY) ? lo - 0.3 * atr : hi + 0.3 * atr + spread;
      double tpPx = lo + 0.5 * w;
      P.dir = d; P.viaMode = true; P.decision = SS_MARKET;
      P.sl = (d == SS_BUY) ? entry - slPx : slPx - entry;
      P.tp = (d == SS_BUY) ? tpPx - entry : entry - tpPx;
      if(P.sl < 3 * spread) P.sl = 3 * spread;
      if(!(P.tp > 0) || P.tp / P.sl < K.rrRangeMin) { P.skip = SK_RR; P.decision = SS_WAIT; return; }
      if(!SsSize(m15, live, spread, pip, atr, 0, usdPerPrice, K, P)) { P.decision = SS_WAIT; return; }
      double room = (d == SS_BUY) ? hi - entry : entry - lo;     // $min ke liye TP range ke bahar na jaye
      if(P.tp > room) { P.skip = SK_QUIET; P.decision = SS_WAIT; }
      return;
   }
}
//MODES>>


//==================================================================
//  EA SHELL v1.05 - data, 5 group, mode/auto SL-TP, micro-confirmation, spread,
//  order, breakeven/trailing, pending, panel
//==================================================================
#define NGRP 5
CTrade   trade;
string   g_sym[];          // broker ka naam (jaise EURUSDm)
int      g_grp[];          // 0..4
datetime g_lastBar[];      // aakhri hisaab wali M15 candle
string   g_line[];         // panel ki chhoti line
SsResult g_res[];          // aakhri hisaab
SsPlan   g_plan[];         // mode + asli order (dir, SL/TP doori)
bool     g_cand[];         // is candle pe trade ka umeedwar
datetime g_candBar[];      // kis candle ka umeedwar
string   g_grpName[NGRP] = {"Majors", "EUR Cross", "GBP Cross", "AUD/NZD", "CAD/CHF"};
string   g_grpLine[NGRP];

// micro-confirmation (har group me ek)
bool     g_wOn[NGRP];
int      g_wIdx[NGRP];
double   g_wRef[NGRP];
double   g_wTh[NGRP];
datetime g_wStart[NGRP];
datetime g_lastNewsChk = 0;
double   g_dayPl = 0;
datetime g_dayPlChk = 0;

string TrimStr(string s)
{
   string t = s;
   StringTrimLeft(t);
   StringTrimRight(t);
   return t;
}

// Chart ke symbol se broker ka suffix (jaise XAUUSDm -> "m")
string ChartSuffix()
{
   string s = _Symbol;
   if(StringLen(s) <= 6) return "";
   return StringSubstr(s, 6);
}

// Is account pe is symbol pe poori trading allowed hai?
bool Tradable(string s)
{
   if(!SymbolSelect(s, true)) return false;
   if(SymbolInfoInteger(s, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL) return true;
   SymbolSelect(s, false);
   return false;
}

string ResolveSymbol(string base)
{
   string suf = (InpSuffix != "") ? InpSuffix : ChartSuffix();
   string cand = base + suf;
   if(Tradable(cand)) return cand;
   int total = SymbolsTotal(false);
   for(int i = 0; i < total; i++)
   {
      string s = SymbolName(i, false);
      if(s == cand) continue;
      if(StringFind(s, base) == 0 && StringLen(s) <= StringLen(base) + 4 && Tradable(s)) return s;
   }
   return "";
}

int SymIndex(string sym)
{
   for(int i = 0; i < ArraySize(g_sym); i++) if(g_sym[i] == sym) return i;
   return -1;
}

datetime IstNow() { return TimeGMT() + 19800; }

string DayKeyOf(datetime ist)
{
   MqlDateTime d;
   TimeToStruct(ist, d);
   return StringFormat("%04d%02d%02d", d.year, d.mon, d.day);
}

string IstHM()
{
   MqlDateTime d;
   TimeToStruct(IstNow(), d);
   return StringFormat("%02d:%02d", d.hour, d.min);
}

bool InTradeTime()
{
   MqlDateTime d;
   TimeToStruct(IstNow(), d);
   if(d.day_of_week == 0 || d.day_of_week == 6) return false;
   if(!(d.hour >= InpStartHourIST && d.hour < InpEndHourIST)) return false;
   int m = d.hour * 60 + d.min;
   if(InpLondonNy && (m < 12 * 60 + 30 || m >= 21 * 60 + 30)) return false;   // London + New York
   return true;
}

string GvKey(string sym, string day) { return "SSEA." + IntegerToString(InpMagic) + "." + sym + "." + day; }

int DayCount(string sym)
{
   string k = GvKey(sym, DayKeyOf(IstNow()));
   return GlobalVariableCheck(k) ? (int)GlobalVariableGet(k) : 0;
}

void DayAdd(string sym, string day, int d)
{
   string k = GvKey(sym, day);
   double v = (GlobalVariableCheck(k) ? GlobalVariableGet(k) : 0) + d;
   if(v < 0) v = 0;
   GlobalVariableSet(k, v);
}

bool PairBusy(string sym)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == InpMagic && PositionGetString(POSITION_SYMBOL) == sym) return true;
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) == InpMagic && OrderGetString(ORDER_SYMBOL) == sym) return true;
   }
   return false;
}

// v1.07: is pair ki koi currency (base/quote) apne kisi khule trade / pending / confirmation me hai?
bool CcyIn(string a, string b) { return SymbolInfoString(a, SYMBOL_CURRENCY_BASE) == SymbolInfoString(b, SYMBOL_CURRENCY_BASE) ||
                                        SymbolInfoString(a, SYMBOL_CURRENCY_BASE) == SymbolInfoString(b, SYMBOL_CURRENCY_PROFIT) ||
                                        SymbolInfoString(a, SYMBOL_CURRENCY_PROFIT) == SymbolInfoString(b, SYMBOL_CURRENCY_BASE) ||
                                        SymbolInfoString(a, SYMBOL_CURRENCY_PROFIT) == SymbolInfoString(b, SYMBOL_CURRENCY_PROFIT); }
string CcyBusyWith(string sym)
{
   for(int g = 0; g < NGRP; g++)
      if(g_wOn[g] && g_sym[g_wIdx[g]] != sym && CcyIn(sym, g_sym[g_wIdx[g]])) return g_sym[g_wIdx[g]];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      if(CcyIn(sym, s)) return s;
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || OrderGetInteger(ORDER_MAGIC) != InpMagic) continue;
      string s = OrderGetString(ORDER_SYMBOL);
      if(CcyIn(sym, s)) return s;
   }
   return "";
}

// Group me apna khula trade / pending / confirmation chal raha hai? kaun sa?
string GroupBusyWith(int g)
{
   if(g_wOn[g]) return g_sym[g_wIdx[g]] + " (confirm)";
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      int k = SymIndex(s);
      if(k >= 0 && g_grp[k] == g) return s + " (khula)";
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0 || OrderGetInteger(ORDER_MAGIC) != InpMagic) continue;
      string s = OrderGetString(ORDER_SYMBOL);
      int k = SymIndex(s);
      if(k >= 0 && g_grp[k] == g) return s + " (pending)";
   }
   return "";
}

double PipOf(string sym)
{
   string q = SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT);
   return (q == "JPY") ? 0.01 : 0.0001;
}

// $ ko price ki doori me badlo (account currency)
double PriceDistForUsd(string sym, double usd, double lots)
{
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0 || lots <= 0) return 0;
   return usd / (tv / ts * lots);
}

double NormLots(string sym, double lots)
{
   double mn = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(st <= 0) st = 0.01;
   double v = MathFloor(lots / st + 0.5) * st;
   if(v < mn) v = mn;
   if(mx > 0 && v > mx) v = mx;
   return NormalizeDouble(v, 2);
}

// SL/TP ki price doori (lot ke hisaab se $ se)
bool SymDists(string sym, double &lots, double &slDist, double &tpDist)
{
   lots = NormLots(sym, InpLots);
   double mul = lots / 0.01;
   slDist = PriceDistForUsd(sym, InpSlUsd * mul, lots);
   tpDist = PriceDistForUsd(sym, InpTpUsd * mul, lots);
   return slDist > 0 && tpDist > 0 && InpSlUsd > 0;
}

bool CcyNews(string ccy, datetime from, datetime to)
{
   MqlCalendarValue vals[];
   int n = CalendarValueHistory(vals, from, to, NULL, ccy);
   for(int i = 0; i < n; i++)
   {
      MqlCalendarEvent ev;
      if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
   }
   return false;
}

bool NewsNear(string sym)
{
   if(!InpAvoidNews) return false;
   datetime now = TimeTradeServer();
   datetime from = now - InpNewsMinutes * 60;
   datetime to = now + InpNewsMinutes * 60;
   string b = SymbolInfoString(sym, SYMBOL_CURRENCY_BASE);
   string q = SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT);
   return CcyNews(b, from, to) || CcyNews(q, from, to);
}

bool SpreadOk(string sym, double slDist)
{
   if(!InpSpreadFilter) return true;
   double sp = SymbolInfoDouble(sym, SYMBOL_ASK) - SymbolInfoDouble(sym, SYMBOL_BID);
   return sp <= slDist * InpMaxSpreadPctSL / 100.0;
}

bool GetBars(string sym, ENUM_TIMEFRAMES tf, Bar &out[])
{
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int n = CopyRates(sym, tf, 0, 120, r);
   if(n < 120) return false;
   ArrayResize(out, n);
   for(int i = 0; i < n; i++)
   {
      out[i].o = r[i].open; out[i].h = r[i].high; out[i].l = r[i].low; out[i].c = r[i].close;
   }
   return true;
}

string DirName(int d) { return (d == SS_BUY) ? "BUY" : (d == SS_SELL) ? "SELL" : (d == -99) ? "-" : "WAIT"; }
string AgeName(int a) { return (a == 0) ? "FRESH" : (a == 1) ? "CHAL RAHA" : (a == 2) ? "PURANA" : (a == 3) ? "LATE" : "-"; }
string DecName(int d) { return (d == SS_MARKET) ? "TRADE LO" : (d == SS_LIMIT) ? "LIMIT LAGAO" : (d == SS_STOP) ? "STOP LAGAO" : "WAIT"; }
string DecShort(int d) { return (d == SS_MARKET) ? "MKT" : (d == SS_LIMIT) ? "LIM" : (d == SS_STOP) ? "STP" : "WAIT"; }

string ModeName(int m) { return (m == MD_TREND) ? "TREND" : (m == MD_RANGE) ? "RANGE" : "NORMAL"; }
string ModeChar(int m) { return (m == MD_TREND) ? "T" : (m == MD_RANGE) ? "R" : "N"; }
string SkipText(int k)
{
   if(k == SK_BIGSL)  return "SL $ seema se bada";
   if(k == SK_QUIET)  return "market shaant - $min target door";
   if(k == SK_RR)     return "range me R:R kam";
   if(k == SK_STRECH) return "trend me price EMA se bahut door";
   if(k == SK_NOCONF) return "pullback par confirm candle nahi";
   if(k == SK_DATA)   return "data kam";
   if(k == SK_LOC)    return "A+: entry range ke galat kinare pe (chase)";
   return "";
}

// Aaj (IST din) ke band trades ka P/L - sirf apne. 30 sec cache.
double TodayPl()
{
   if(TimeCurrent() - g_dayPlChk < 30) return g_dayPl;
   g_dayPlChk = TimeCurrent();
   MqlDateTime d;
   TimeToStruct(IstNow(), d);
   datetime from = TimeTradeServer() - (d.hour * 3600 + d.min * 60 + d.sec);
   double pl = 0;
   if(HistorySelect(from, TimeTradeServer() + 60))
   {
      for(int k = HistoryDealsTotal() - 1; k >= 0; k--)
      {
         ulong t = HistoryDealGetTicket(k);
         if(t == 0 || HistoryDealGetInteger(t, DEAL_MAGIC) != InpMagic) continue;
         long e = HistoryDealGetInteger(t, DEAL_ENTRY);
         if(e != DEAL_ENTRY_OUT && e != DEAL_ENTRY_OUT_BY) continue;
         pl += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
      }
   }
   g_dayPl = pl;
   return pl;
}

void ModeCfg(SsModeCfg &K)
{
   K.trendOn = InpTrendMode; K.rangeOn = InpRangeMode;
   K.slAtr = InpSlAtr; K.rrTrend = InpRrTrend; K.rrNormal = InpRrNormal; K.rrRangeMin = InpRrRangeMin;
   K.minTpUsd = InpMinTpUsd; K.maxTpUsd = InpMaxTpUsd; K.maxSlUsd = InpMaxSlUsd; K.maxTpAtr = InpMaxTpAtr;
   K.trendAdx = InpTrendAdx; K.rangeAdx = InpRangeAdx; K.rangeBars = InpRangeBars;
   K.aplus = InpAplus; K.minSlPips = InpMinSlPips; K.maxSlAtr = InpMaxSlAtr;
   K.posMaxNormal = InpPosMaxNormal; K.posMaxTrend = InpPosMaxTrend; K.swingBars = InpSwingBars; K.rrMin = InpRrMin;
}

string WhyText(int w)
{
   string s = "";
   if((w & W_AGENTS) != 0)  s += "agents ulta, ";
   if((w & W_STRUCT) != 0)  s += "structure ulta, ";
   if((w & W_TECH40) != 0)  s += "technical <40%, ";
   if((w & W_NEWS) != 0)    s += "news paas, ";
   if((w & W_HTF) != 0)     s += "4H/1D dono ulte, ";
   if((w & W_RR) != 0)      s += "R:R < 1:2, ";
   if((w & W_VOTE) != 0)    s += "agents <55% saath, ";
   if((w & W_TECH55) != 0)  s += "technical <55%, ";
   if((w & W_Q60) != 0)     s += "quality <60%, ";
   if((w & C_Q70) != 0)     s += "quality <70%, ";
   if((w & C_TECH65) != 0)  s += "technical <65%, ";
   if((w & C_ST) != 0)      s += "supertrend ulta, ";
   if((w & C_EMA) != 0)     s += "EMA Plan ulta/WAIT, ";
   if((w & C_HTFRULE) != 0) s += "HTF rule, ";
   if((w & T_LATE) != 0)    s += "signal LATE, ";
   if((w & T_PURANA) != 0)  s += "signal PURANA, ";
   if((w & T_LOC) != 0)     s += "range ka kinara, ";
   if((w & T_RSI) != 0)     s += "RSI extreme, ";
   if((w & T_CHASE) != 0)   s += "chase, ";
   if((w & O_SL) != 0)      s += "SL tight, ";
   if(StringLen(s) > 2) s = StringSubstr(s, 0, StringLen(s) - 2);
   return s;
}

bool RetOk()
{
   uint rc = trade.ResultRetcode();
   return rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL;
}

// Order se pehle ke niyam. "" = theek. retry=true matlab abhi ruko, baad me phir dekho.
string PreCheck(int i, int decision, bool &retry)
{
   retry = false;
   string sym = g_sym[i];
   if(!InpEnableTrading) return "trading OFF (input)";
   if(!InpAllowReal && AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) return "REAL account - band";
   if(decision == SS_MARKET && !InpModeMarket) return "Market mode OFF";
   if(decision == SS_LIMIT && !InpModeLimit) return "Limit mode OFF";
   if(decision == SS_STOP && !InpModeStop) return "Stop mode OFF";
   if(!InTradeTime()) return "waqt ke bahar (IST)";
   if(NewsNear(sym)) return StringFormat("high-impact news %d min ke andar", InpNewsMinutes);
   if(PairBusy(sym)) return "pair pe trade/order khula";
   if(DayCount(sym) >= InpMaxPerPairDay) return "aaj is pair ki seema puri";
   if(InpOneTradePerCcy)
   {
      string cb = CcyBusyWith(sym);
      if(cb != "") return "currency pehle se " + cb + " me";
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return "MT5 me Algo Trading OFF";
   if(InpMaxDayLossUsd > 0 && TodayPl() <= -InpMaxDayLossUsd)
      return StringFormat("aaj ka loss seema puri ($%.2f)", TodayPl());
   if(!(g_plan[i].sl > 0) || !(g_plan[i].tp > 0)) return "SL/TP nahi bana";
   if(!SpreadOk(sym, g_plan[i].sl)) { retry = true; return "spread zyada - intezaar"; }
   return "";
}

// Asli order. Market = abhi ke ask/bid se, Limit/Stop = live se off door. SL/TP = plan ki doori.
string PlaceOrder(int i, int decision, int dir, double off, int q)
{
   string sym = g_sym[i];
   double lots = NormLots(sym, InpLots);
   double slDist = g_plan[i].sl, tpDist = g_plan[i].tp;
   if(!(slDist > 0) || !(tpDist > 0)) return "SL/TP nahi bana";
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   double lvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * point;
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) return "price nahi mila";
   if(slDist <= lvl || tpDist <= lvl) return "SL/TP broker ki min doori se kam";

   bool buy = (dir == SS_BUY);
   string cm = StringFormat("SSEA %s %s q%d", ModeChar(g_plan[i].mode), DecShort(decision), q);
   bool sent = false;
   double entry = 0;
   if(decision == SS_MARKET)
   {
      entry = buy ? ask : bid;
      double sl = NormalizeDouble(buy ? entry - slDist : entry + slDist, digits);
      double tp = NormalizeDouble(buy ? entry + tpDist : entry - tpDist, digits);
      sent = buy ? trade.Buy(lots, sym, 0, sl, tp, cm) : trade.Sell(lots, sym, 0, sl, tp, cm);
   }
   else
   {
      double sign = (decision == SS_LIMIT) ? -1.0 : 1.0;
      double sh = (buy ? sign : -sign) * off;
      entry = NormalizeDouble(bid + sh, digits);
      double sl = NormalizeDouble(buy ? entry - slDist : entry + slDist, digits);
      double tp = NormalizeDouble(buy ? entry + tpDist : entry - tpDist, digits);
      if(decision == SS_LIMIT)
      {
         if(buy && entry >= ask - lvl) return "BUY LIMIT price live ke bahut paas";
         if(!buy && entry <= bid + lvl) return "SELL LIMIT price live ke bahut paas";
         sent = buy ? trade.BuyLimit(lots, entry, sym, sl, tp, ORDER_TIME_GTC, 0, cm)
                    : trade.SellLimit(lots, entry, sym, sl, tp, ORDER_TIME_GTC, 0, cm);
      }
      else
      {
         if(buy && entry <= ask + lvl) return "BUY STOP price live ke bahut paas";
         if(!buy && entry >= bid - lvl) return "SELL STOP price live ke bahut paas";
         sent = buy ? trade.BuyStop(lots, entry, sym, sl, tp, ORDER_TIME_GTC, 0, cm)
                    : trade.SellStop(lots, entry, sym, sl, tp, ORDER_TIME_GTC, 0, cm);
      }
   }
   if(!sent || !RetOk())
      return StringFormat("ORDER FAIL %u %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
   DayAdd(sym, DayKeyOf(IstNow()), 1);
   return StringFormat("ORDER LAGA [%s]: %s %s @ %s  SL $%.2f TP $%.2f", ModeName(g_plan[i].mode), DirName(dir),
                       (decision == SS_MARKET) ? "MARKET" : (decision == SS_LIMIT) ? "LIMIT" : "STOP",
                       DoubleToString(entry, digits), g_plan[i].slUsd, g_plan[i].tpUsd);
}

// Har nayi M15 candle pe ek pair ka hisaab (app jaisa). Trade yahan nahi - group tay karta hai.
void EvaluateSymbol(int i)
{
   string sym = g_sym[i];
   datetime bt = iTime(sym, PERIOD_M15, 0);
   if(bt == 0 || bt == g_lastBar[i]) return;
   Bar m15[]; Bar h1[]; Bar h4[]; Bar d1[];
   if(!GetBars(sym, PERIOD_M15, m15) || !GetBars(sym, PERIOD_H1, h1) ||
      !GetBars(sym, PERIOD_H4, h4) || !GetBars(sym, PERIOD_D1, d1)) return;     // data load ho raha - agle timer pe
   g_lastBar[i] = bt;
   g_cand[i] = false;

   double lots, slDist, tpDist;
   if(!SymDists(sym, lots, slDist, tpDist))
   {
      g_line[i] = sym + " - tick value nahi mila";
      return;
   }
   double pip = PipOf(sym);
   double rr = InpTpUsd / InpSlUsd;
   bool news = NewsNear(sym);

   SsResult R;
   SsEvaluate(m15, h1, h4, d1, pip, slDist, tpDist, rr, news, R);
   g_res[i] = R;

   // mode + asli SL/TP
   SsPlan P;
   double bid = SymbolInfoDouble(sym, SYMBOL_BID), ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double usdPerPrice = (ts > 0) ? tv / ts * lots : 0;
   if(InpAutoSlTp)
   {
      Bar m15c[]; Bar h1c[]; Bar h4c[];
      SsDropLast(m15, m15c); SsDropLast(h1, h1c); SsDropLast(h4, h4c);
      SsModeCfg K;
      ModeCfg(K);
      SsMakePlan(m15c, bid, ask - bid, pip, SsTfBiasDir(h1c), SsTfBiasDir(h4c), R, news, usdPerPrice, K, P);
   }
   else
   {
      P.mode = MD_NORMAL; P.decision = R.decision; P.dir = R.dir; P.off = R.off;
      P.sl = slDist; P.tp = tpDist; P.adx = 0; P.slUsd = InpSlUsd * lots / 0.01; P.tpUsd = InpTpUsd * lots / 0.01;
      P.skip = (R.decision == SS_WAIT) ? SK_CORE : SK_NONE; P.viaMode = false;
   }
   g_plan[i] = P;

   string head = StringFormat("%s [%s adx%.0f] %s q%d tech%d%% %dB/%dH/%dS(%d%%) umar:%s ema:%s",
                              sym, ModeName(P.mode), P.adx, DirName(R.dir), R.q, R.pct, R.buy, R.hold, R.sell, R.conf,
                              AgeName(R.age), DirName(R.emaDir));
   string why = (R.dir == SS_HOLD) ? "koi saaf direction nahi" : WhyText(R.why);
   if(P.decision == SS_WAIT)
   {
      g_line[i] = StringFormat("%-9s %s %s %-4s q%d WAIT", sym, IstHM(), ModeChar(P.mode), DirName(R.dir), R.q);
      string sk = SkipText(P.skip);
      if(InpVerboseLog) Print("[SSEA] ", IstHM(), "  ", head, " -> WAIT | ", (sk != "" ? sk + " | " : ""), why);
      return;
   }
   g_cand[i] = true;
   g_candBar[i] = bt;
   g_line[i] = StringFormat("%-9s %s %s %-4s q%d %s - group ka intezaar", sym, IstHM(), ModeChar(P.mode), DirName(P.dir), R.q, DecName(P.decision));
   if(InpVerboseLog)
      Print("[SSEA] ", IstHM(), "  ", head, " -> ", (P.viaMode ? ModeName(P.mode) + " " : ""), DecName(P.decision), " ", DirName(P.dir),
            (P.decision != SS_MARKET ? StringFormat(" off %.1f pip", P.off / pip) : ""),
            StringFormat(" SL %.1f pip $%.2f TP %.1f pip $%.2f", P.sl / pip, P.slUsd, P.tp / pip, P.tpUsd),
            (R.why != 0 ? " | dhyan: " + why : ""));
}

void SetLine(int i, string status)
{
   SsPlan P = g_plan[i];
   g_line[i] = StringFormat("%-9s %s %s %-4s %s - %s", g_sym[i], IstHM(), ModeChar(P.mode), DirName(P.dir), DecShort(P.decision), status);
   if(InpVerboseLog) Print("[SSEA] ", g_sym[i], " [", ModeName(P.mode), "] ", DecName(P.decision), " ", DirName(P.dir), " -> ", status);
}

// Har group: umeedwaron me se best chuno, phir order / micro-confirmation
void ProcessGroups()
{
   for(int g = 0; g < NGRP; g++)
   {
      string busy = InpOneTradePerGroup ? GroupBusyWith(g) : "";
      g_grpLine[g] = (busy == "") ? "khaali" : busy;
      while(true)
      {
         int best = -1;
         bool waitMore = false;
         for(int i = 0; i < ArraySize(g_sym); i++)
         {
            if(g_grp[i] != g || !g_cand[i]) continue;
            if(iTime(g_sym[i], PERIOD_M15, 0) != g_candBar[i]) { g_cand[i] = false; continue; }   // candle nikal gayi
            if(TimeCurrent() - g_candBar[i] < InpGroupWaitSec) { waitMore = true; continue; }
            if(best < 0 || g_res[i].q > g_res[best].q ||
               (g_res[i].q == g_res[best].q && g_res[i].pct > g_res[best].pct)) best = i;
         }
         if(best < 0 || waitMore) break;
         if(InpOneTradePerGroup && busy != "")
         {
            for(int i = 0; i < ArraySize(g_sym); i++)
               if(g_grp[i] == g && g_cand[i]) { g_cand[i] = false; SetLine(i, "group busy: " + busy); }
            break;
         }
         SsResult R = g_res[best];
         SsPlan P = g_plan[best];
         bool retry;
         string pc = PreCheck(best, P.decision, retry);
         if(pc != "")
         {
            if(retry) { g_line[best] = g_sym[best] + " " + IstHM() + " " + DecName(P.decision) + " - " + pc; break; }
            g_cand[best] = false;
            SetLine(best, pc);
            continue;                              // group ka agla umeedwar
         }
         // chuna gaya - baaki umeedwar is candle ke liye khatam
         for(int i = 0; i < ArraySize(g_sym); i++)
            if(g_grp[i] == g && g_cand[i] && i != best) { g_cand[i] = false; SetLine(i, "group me " + g_sym[best] + " behtar (q" + IntegerToString(R.q) + ")"); }
         g_cand[best] = false;
         if(P.decision == SS_MARKET && InpMicroConfirm)
         {
            g_wOn[g] = true; g_wIdx[g] = best;
            g_wRef[g] = SymbolInfoDouble(g_sym[best], SYMBOL_BID);
            g_wTh[g] = InpConfirmAtr * R.atr;
            g_wStart[g] = TimeCurrent();
            SetLine(best, StringFormat("confirm ka intezaar: %s %.1f pip chale", DirName(P.dir), g_wTh[g] / PipOf(g_sym[best])));
         }
         else SetLine(best, PlaceOrder(best, P.decision, P.dir, P.off, R.q));
         break;
      }
   }
}

// Micro-confirmation: price signal ki taraf chale to market entry, ulta ya time khatam to cancel
void ProcessWatches()
{
   for(int g = 0; g < NGRP; g++)
   {
      if(!g_wOn[g]) continue;
      int i = g_wIdx[g];
      string sym = g_sym[i];
      SsResult R = g_res[i];
      SsPlan P = g_plan[i];
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double moved = (P.dir == SS_BUY) ? bid - g_wRef[g] : g_wRef[g] - bid;
      if(moved <= -g_wTh[g]) { g_wOn[g] = false; SetLine(i, "confirm FAIL - price ulta chala, cancel"); continue; }
      if(TimeCurrent() - g_wStart[g] > InpConfirmMin * 60) { g_wOn[g] = false; SetLine(i, "confirm nahi hua (" + IntegerToString(InpConfirmMin) + " min) - cancel"); continue; }
      if(moved < g_wTh[g]) continue;
      bool retry;
      string pc = PreCheck(i, SS_MARKET, retry);
      if(pc != "")
      {
         if(retry) continue;                       // spread - time khatam hone tak ruko
         g_wOn[g] = false; SetLine(i, "confirm hua par " + pc); continue;
      }
      g_wOn[g] = false;
      SetLine(i, "confirm hua -> " + PlaceOrder(i, SS_MARKET, P.dir, 0, R.q));
   }
}

// Breakeven + trailing (sirf apne trades)
void ManagePositions()
{
   if(!InpBreakEven && !InpProfitLock && !InpTrailing) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      long type = PositionGetInteger(POSITION_TYPE);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double vol = PositionGetDouble(POSITION_VOLUME);
      double U = PriceDistForUsd(sym, vol / 0.01, vol);    // $1 (0.01 lot pe) ki price doori
      if(U <= 0) continue;
      double T = (tp > 0) ? MathAbs(tp - open) : InpMaxTpUsd * U;   // is trade ka TP doori
      double beD = InpBePct / 100.0 * T;
      double lockD = MathMax(InpLockPct / 100.0 * T, MathMin(InpMinLockUsd * U, 0.5 * T));
      double lockAtD = MathMax(InpLockAtPct / 100.0 * T, lockD + 0.2 * T);
      double trStD = InpTrailStartPct / 100.0 * T, trDD = InpTrailDistPct / 100.0 * T;
      bool   fixOn = InpProfitLock && InpKeepPct > 0 && InpKeepPct < 100 && InpStepUsd > 0;   // v1.10: har pura $1 ka 75% pakka
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      double lvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * point;
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      double newSl = sl;
      if(type == POSITION_TYPE_BUY)
      {
         double gain = bid - open;
         if(InpBreakEven && gain >= beD * 0.9999 && (sl == 0 || sl < open)) newSl = open;
         if(InpProfitLock && gain >= lockAtD * 0.9999)
         {
            double lk = open + lockD;
            if(newSl == 0 || lk > newSl) newSl = lk;
         }
         double stB = fixOn && gain > 0 ? MathFloor(gain / U / InpStepUsd + 1e-6) : 0;
         if(stB >= 1)
         {
            double fk = open + InpKeepPct / 100.0 * stB * InpStepUsd * U;
            if(newSl == 0 || fk > newSl) newSl = fk;
         }
         if(InpTrailing && gain >= trStD)
         {
            double tr = bid - trDD;
            if(tr > newSl) newSl = tr;
         }
         newSl = NormalizeDouble(newSl, digits);
         if(newSl > sl + point / 2 && newSl <= bid - lvl)
         {
            if(trade.PositionModify(t, newSl, tp))
               Print("[SSEA] ", sym, " BUY SL -> ", DoubleToString(newSl, digits), " (profit lock $",
                     DoubleToString((newSl - open) / U * vol / 0.01, 2), ")");
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double gain = open - ask;
         if(InpBreakEven && gain >= beD * 0.9999 && (sl == 0 || sl > open)) newSl = open;
         if(InpProfitLock && gain >= lockAtD * 0.9999)
         {
            double lk = open - lockD;
            if(newSl == 0 || lk < newSl) newSl = lk;
         }
         double stS = fixOn && gain > 0 ? MathFloor(gain / U / InpStepUsd + 1e-6) : 0;
         if(stS >= 1)
         {
            double fk = open - InpKeepPct / 100.0 * stS * InpStepUsd * U;
            if(newSl == 0 || fk < newSl) newSl = fk;
         }
         if(InpTrailing && gain >= trStD)
         {
            double tr = ask + trDD;
            if(newSl == 0 || tr < newSl) newSl = tr;
         }
         newSl = NormalizeDouble(newSl, digits);
         if(newSl > 0 && (sl == 0 || newSl < sl - point / 2) && newSl >= ask + lvl)
         {
            if(trade.PositionModify(t, newSl, tp))
               Print("[SSEA] ", sym, " SELL SL -> ", DoubleToString(newSl, digits), " (profit lock $",
                     DoubleToString((open - newSl) / U * vol / 0.01, 2), ")");
         }
      }
   }
}

// LIMIT/STOP InpPendingHours me na bhare to hatao (din ki ginti wapas)
void CleanPendings()
{
   datetime srv = TimeTradeServer();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) != InpMagic) continue;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(srv - setup < (long)InpPendingHours * 3600) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(trade.OrderDelete(t))
      {
         datetime ist = setup - srv + TimeGMT() + 19800;
         DayAdd(sym, DayKeyOf(ist), -1);
         Print("[SSEA] ", sym, " pending ", InpPendingHours, " ghante me nahi bhara - hata diya");
      }
   }
}

// News se pehle (aur dauraan) apna bhara-nahi pending hatao. Har 30 sec.
void CancelPendingsOnNews()
{
   if(!InpAvoidNews || !InpCancelOnNews) return;
   if(TimeCurrent() - g_lastNewsChk < 30) return;
   g_lastNewsChk = TimeCurrent();
   datetime srv = TimeTradeServer();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) != InpMagic) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(!NewsNear(sym)) continue;
      if(trade.OrderDelete(t))
      {
         datetime ist = setup - srv + TimeGMT() + 19800;
         DayAdd(sym, DayKeyOf(ist), -1);
         Print("[SSEA] ", sym, " high-impact news paas - pending order hata diya");
      }
   }
}

// Chart panel (MT5 Comment ~2000 akshar tak - isliye chhoti lines)
void DrawPanel()
{
   int pos = 0, pend = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t != 0 && PositionGetInteger(POSITION_MAGIC) == InpMagic) pos++;
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong t = OrderGetTicket(i);
      if(t != 0 && OrderGetInteger(ORDER_MAGIC) == InpMagic) pend++;
   }
   bool demo = AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO;
   string s = StringFormat("SamuSignal EA v1.10 | %s | trading %s | %02d-%02d IST %s | IST %s\n",
                           demo ? "DEMO" : "REAL", InpEnableTrading ? "ON" : "OFF",
                           InpStartHourIST, InpEndHourIST, InTradeTime() ? "(chalu)" : "(band)", IstHM());
   s += StringFormat("Mkt %s Lim %s Stp %s | confirm %s | spread %s | news %s | BE %s lock %s trail %s | khule %d pending %d\n",
                     InpModeMarket ? "ON" : "OFF", InpModeLimit ? "ON" : "OFF", InpModeStop ? "ON" : "OFF",
                     InpMicroConfirm ? "ON" : "OFF", InpSpreadFilter ? "ON" : "OFF", InpAvoidNews ? "ON" : "OFF",
                     InpBreakEven ? "ON" : "OFF", InpProfitLock ? "ON" : "OFF", InpTrailing ? "ON" : "OFF", pos, pend);
   s += StringFormat("SL/TP %s%s (TP $%.2f-$%.0f) | TREND %s RANGE %s | 1/ccy %s | %s | aaj P/L $%.2f%s\n",
                     InpAutoSlTp ? "AUTO" : "FIX", InpAplus ? " A+" : "", InpMinTpUsd, InpMaxTpUsd, InpTrendMode ? "ON" : "OFF", InpRangeMode ? "ON" : "OFF",
                     InpOneTradePerCcy ? "ON" : "OFF", InpLondonNy ? "12:30-21:30" : "poora din",
                     TodayPl(), (InpMaxDayLossUsd > 0 && TodayPl() <= -InpMaxDayLossUsd) ? " (seema puri - aaj band)" : "");
   for(int g = 0; g < NGRP; g++) s += g_grpName[g] + ": " + g_grpLine[g] + "   ";
   s += "\n";
   for(int i = 0; i < ArraySize(g_sym); i++)
   {
      string ln = (g_line[i] == "") ? g_sym[i] + " ..." : g_line[i];
      if(StringLen(ln) > 62) ln = StringSubstr(ln, 0, 62);
      s += ln + "\n";
   }
   if(StringLen(s) > 2000) s = StringSubstr(s, 0, 2000);
   Comment(s);
}

void AddGroup(string list, int g)
{
   string parts[];
   int n = StringSplit(list, ',', parts);
   for(int i = 0; i < n; i++)
   {
      string base = TrimStr(parts[i]);
      StringToUpper(base);
      if(base == "") continue;
      string s = ResolveSymbol(base);
      if(s == "") { Print("[SSEA] ", base, " is account pe tradable nahi mila - chhod diya"); continue; }
      if(SymIndex(s) >= 0) continue;
      int k = ArraySize(g_sym);
      ArrayResize(g_sym, k + 1);
      ArrayResize(g_grp, k + 1);
      g_sym[k] = s;
      g_grp[k] = g;
      Print("[SSEA] ", g_grpName[g], ": ", base, " -> ", s);
   }
}

int OnInit()
{
   ArrayResize(g_sym, 0);
   ArrayResize(g_grp, 0);
   AddGroup(InpGrpMajors, 0);
   AddGroup(InpGrpEur, 1);
   AddGroup(InpGrpGbp, 2);
   AddGroup(InpGrpAudNzd, 3);
   AddGroup(InpGrpCadChf, 4);
   int m = ArraySize(g_sym);
   ArrayResize(g_lastBar, m);
   ArrayResize(g_line, m);
   ArrayResize(g_res, m);
   ArrayResize(g_plan, m);
   ArrayResize(g_cand, m);
   ArrayResize(g_candBar, m);
   for(int i = 0; i < m; i++) { g_lastBar[i] = 0; g_line[i] = ""; g_cand[i] = false; g_candBar[i] = 0; }
   for(int g = 0; g < NGRP; g++) { g_wOn[g] = false; g_wIdx[g] = 0; g_grpLine[g] = ""; }
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints(20);
   bool demo = AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO;
   Print("=== SamuSignal EA v1.10 chalu - ", m, " pairs, 5 group | ", demo ? "DEMO" : "REAL",
         " | trading ", InpEnableTrading ? "ON" : "OFF", " | confirm ", InpMicroConfirm ? "ON" : "OFF", " ===");
   if(!demo && !InpAllowReal) Print("[SSEA] REAL account hai - InpAllowReal=false, isliye sirf hisaab/log, trade nahi");
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

void OnTick() { }

void OnTimer()
{
   ManagePositions();
   CleanPendings();
   CancelPendingsOnNews();
   for(int i = 0; i < ArraySize(g_sym); i++) EvaluateSymbol(i);
   ProcessWatches();
   ProcessGroups();
   DrawPanel();
}
