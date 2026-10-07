/* SamuQuant — maths wali strategy (EURUSD + XAUUSD, H1)
   ------------------------------------------------------------------
   Backtest (quant/backtest.mjs) aur live signal (quant/signal.mjs) dono
   ISI file ka code chalate hain — jo backtest me test hua wahi live jaata hai.

   Niyam (sab waqt UTC me):
   1. Trend score (t-stat): pichhle 20 poore dinon ke log(close) par seedhi
      line (OLS regression). slope / standard error = t. |t| >= tMin ho tabhi
      us disha me trade. t > 0 → sirf BUY, t < 0 → sirf SELL.
   2. Asia range: 00:00–07:00 UTC ka high/low. Range daily ATR(14) ke
      minRangeAtr..maxRangeAtr guna ke beech ho (dabi hui, na bahut chhoti).
   3. Entry: London (07:00–12:00) me koi H1 candle range ke bahar trend ki
      disha me CLOSE kare → agli candle ke open pe entry. Din me ek hi trade.
   4. SL: range ka beech (mid) − buffer. TP: rr × risk. Risk ATR ke 1 guna
      se zyada ho to trade nahi.
   5. 20:00 UTC (01:30 IST) tak SL/TP na lage to bazaar bhav pe band.
   Koi martingale nahi, koi grid nahi, har trade pe SL. */

export const PAIRS = {
  EURUSD: {duka: 'eurusd', td: 'EUR/USD', digits: 5, cost: 0.00012, lotValue: 100000, pip: 0.0001},
  XAUUSD: {duka: 'xauusd', td: 'XAU/USD', digits: 2, cost: 0.35, lotValue: 100, pip: 0.1}
};
/* cost = poora round-trip kharcha (spread + commission + thoda slippage), price units me:
   EURUSD 1.2 pip, XAUUSD $0.35 — aam ECN account se thoda bura maana hai */

export const DEFAULTS = {
  trendDays: 20,
  tMin: 2.0,
  atrDays: 14,
  asiaEnd: 7,          /* Asia range = [00:00, 07:00) UTC */
  entryEnd: 12,        /* entry candle ka open 07..11 UTC */
  exitHour: 20,        /* 20:00 UTC pe band */
  minRangeAtr: 0.25,
  maxRangeAtr: 1.0,
  maxRiskAtr: 1.0,
  bufferAtr: 0.05,
  rr: 2.0
};

const DAY = 86400000;
export const dayOf = t => Math.floor(t / DAY);
export const hourOf = t => new Date(t).getUTCHours();

/* t-stat of OLS slope */
export function trendT(ys){
  const n = ys.length;
  if(n < 5) return 0;
  const mx = (n - 1) / 2;
  let my = 0;
  for(const y of ys) my += y;
  my /= n;
  let sxx = 0, sxy = 0;
  for(let i = 0; i < n; i++){ sxx += (i - mx) ** 2; sxy += (i - mx) * (ys[i] - my) }
  const b = sxy / sxx, a = my - b * mx;
  let sse = 0;
  for(let i = 0; i < n; i++) sse += (ys[i] - a - b * i) ** 2;
  const se = Math.sqrt(sse / (n - 2) / sxx);
  return se > 0 ? b / se : 0;
}

/* H1 candles → har din ka hisaab (Asia range, trend t, ATR). bars: [{t,o,h,l,c}] t=ms UTC, purane se naye */
export function prepare(bars, p = DEFAULTS){
  const days = new Map();
  for(let i = 0; i < bars.length; i++){
    const b = bars[i], d = dayOf(b.t), hr = hourOf(b.t);
    let D = days.get(d);
    if(!D){ D = {day: d, first: i, n: 0, o: b.o, h: -Infinity, l: Infinity, c: b.c, aH: -Infinity, aL: Infinity, aN: 0}; days.set(d, D) }
    D.n++; D.last = i; D.c = b.c;
    if(b.h > D.h) D.h = b.h;
    if(b.l < D.l) D.l = b.l;
    if(hr < p.asiaEnd){ D.aN++; if(b.h > D.aH) D.aH = b.h; if(b.l < D.aL) D.aL = b.l }
  }
  /* sirf poore trading din (Sunday ki 2–3 candles wala din nahi) */
  const full = [...days.values()].filter(D => D.n >= 8).sort((a, b) => a.day - b.day);
  for(let k = 0; k < full.length; k++){
    const D = full[k];
    if(k < Math.max(p.trendDays, p.atrDays + 1)) continue;
    const ys = full.slice(k - p.trendDays, k).map(x => Math.log(x.c));
    D.t = trendT(ys);
    let tr = 0;
    for(let j = k - p.atrDays; j < k; j++){
      const x = full[j], pc = full[j - 1].c;
      tr += Math.max(x.h - x.l, Math.abs(x.h - pc), Math.abs(x.l - pc));
    }
    D.atr = tr / p.atrDays;
  }
  return new Map(full.map(D => [D.day, D]));
}

/* bar i band hone par signal hai? (sirf us din ki pehli qualifying candle) */
export function signalAt(bars, i, days, p = DEFAULTS){
  const b = bars[i], hr = hourOf(b.t);
  if(hr < p.asiaEnd || hr >= p.entryEnd) return null;
  const D = days.get(dayOf(b.t));
  if(!D || D.atr === undefined || D.aN < 5) return null;
  const range = D.aH - D.aL;
  if(range < p.minRangeAtr * D.atr || range > p.maxRangeAtr * D.atr) return null;
  const buf = p.bufferAtr * D.atr, mid = (D.aH + D.aL) / 2;
  const dirOf = c => c > D.aH + buf ? 1 : c < D.aL - buf ? -1 : 0;
  const dir = dirOf(b.c);
  if(!dir) return null;
  if(dir * D.t < p.tMin) return null;
  /* aaj pehle koi London candle isi disha me nikal chuki to ye pehli nahi */
  for(let j = i - 1; j >= D.first; j--){
    const hj = hourOf(bars[j].t);
    if(hj < p.asiaEnd) break;
    if(dirOf(bars[j].c) === dir) return null;
  }
  const sl = dir > 0 ? mid - buf : mid + buf;
  return {i, dir, sl, mid, range, atr: D.atr, t: D.t, aH: D.aH, aL: D.aL, buf};
}

/* entry agli candle ke open pe; SL/TP/time exit. Ek candle me SL aur TP dono → SL (bura maan ke).
   dir: default signal ki disha; ulti disha sirf randomness test ke liye (risk utna hi) */
export function simulate(bars, sig, pair, p = DEFAULTS, dir = sig.dir){
  const j = sig.i + 1;
  if(j >= bars.length) return null;
  const e = bars[j];
  if(dayOf(e.t) !== dayOf(bars[sig.i].t) || hourOf(e.t) >= p.exitHour) return null;
  const entry = e.o;
  const risk = sig.dir * (entry - sig.sl);
  if(!(risk > 0) || risk > p.maxRiskAtr * sig.atr) return null;
  const stop = entry - dir * risk, tp = entry + dir * p.rr * risk;
  let exit = null, why = '', k = j;
  for(; k < bars.length; k++){
    const x = bars[k];
    if(k > j && (dayOf(x.t) !== dayOf(e.t) || hourOf(x.t) >= p.exitHour)){ exit = x.o; why = 'time'; break }
    const hitSl = dir > 0 ? x.l <= stop : x.h >= stop;
    const hitTp = dir > 0 ? x.h >= tp : x.l <= tp;
    if(hitSl){ exit = dir > 0 ? Math.min(stop, x.o) : Math.max(stop, x.o); why = 'sl'; break }
    if(hitTp){ exit = tp; why = 'tp'; break }
  }
  if(exit === null) return null;          /* data khatam, trade abhi khula */
  const pnl = dir * (exit - entry) - PAIRS[pair].cost;
  return {pair, t: e.t, exitT: bars[k].t, dir, entry, sl: stop, tp, exit, why, risk, r: pnl / risk};
}

/* poore data pe saare trades */
export function runStrategy(bars, pair, p = DEFAULTS){
  const days = prepare(bars, p);
  const out = [];
  let lastDay = -1;
  for(let i = 0; i < bars.length - 1; i++){
    const d = dayOf(bars[i].t);
    if(d === lastDay) continue;
    const s = signalAt(bars, i, days, p);
    if(!s) continue;
    lastDay = d;                          /* din me ek hi koshish */
    const tr = simulate(bars, s, pair, p);
    if(tr){
      tr.alt = simulate(bars, s, pair, p, -s.dir);   /* ulti disha ka nateeja (randomness test) */
      out.push(tr);
    }
  }
  return out;
}

/* live: aaj ki pehli qualifying candle (backtest jaisa hi). bars ke aakhir me sirf BAND candles */
export function todaysSignal(bars, p = DEFAULTS){
  if(!bars.length) return null;
  const days = prepare(bars, p);
  const today = dayOf(bars.at(-1).t);
  for(let i = 0; i < bars.length; i++){
    if(dayOf(bars[i].t) !== today) continue;
    const s = signalAt(bars, i, days, p);
    if(s) return s;
  }
  return null;
}
