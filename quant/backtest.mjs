/* SamuQuant backtest → quant/report.html + quant/results.json
   Chalao: node quant/backtest.mjs   (pehle node quant/fetch-data.mjs)
   - Asli Dukascopy H1 data, kharcha (spread+commission) ghata ke
   - In-sample (2016–2021) vs Out-of-sample (2022 se) — niyam pehle se tay, OOS pe tune nahi kiye
   - Monte Carlo (trades ka order 5000 baar ulat-pulat) → drawdown ka andaza
   - Randomness test: wahi waqt, disha sikka uchhaal ke — kya edge sach me hai?
   - Robustness grid: niyam thode badle to bhi chalta hai ya sirf ek jagah? */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PAIRS, DEFAULTS, runStrategy } from './strategy.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = process.env.QUANT_DATA || path.join(HERE, 'data');
const OUT = process.env.QUANT_OUT || HERE;
const OOS_FROM = Date.UTC(2022, 0, 1);
const RISK = 0.01;                                   /* har trade pe account ka 1% */

/* seed wala random — har baar wahi nateeja */
function rng(seed){ return () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296 } }

function loadCsv(file){
  const lines = fs.readFileSync(file, 'utf8').trim().split('\n').slice(1);
  return lines.map(l => { const [t, o, h, l2, c] = l.split(',').map(Number); return {t, o, h, l: l2, c} });
}

function stats(trades){
  const rs = trades.map(t => t.r);
  const n = rs.length;
  if(!n) return {n: 0};
  const wins = rs.filter(r => r > 0), losses = rs.filter(r => r <= 0);
  const sum = a => a.reduce((x, y) => x + y, 0);
  let eq = 0, peak = 0, dd = 0, streak = 0, maxStreak = 0, bal = 1, balPeak = 1, ddPct = 0;
  for(const r of rs){
    eq += r; peak = Math.max(peak, eq); dd = Math.max(dd, peak - eq);
    streak = r <= 0 ? streak + 1 : 0; maxStreak = Math.max(maxStreak, streak);
    bal *= 1 + RISK * r; balPeak = Math.max(balPeak, bal); ddPct = Math.max(ddPct, 1 - bal / balPeak);
  }
  const years = (trades.at(-1).t - trades[0].t) / (365.25 * 86400000) || 1;
  const mean = sum(rs) / n;
  const sd = Math.sqrt(sum(rs.map(r => (r - mean) ** 2)) / Math.max(1, n - 1));
  return {
    n, win: wins.length / n, avgWin: wins.length ? sum(wins) / wins.length : 0,
    avgLoss: losses.length ? sum(losses) / losses.length : 0, exp: mean,
    tStat: sd > 0 ? mean / (sd / Math.sqrt(n)) : 0,
    pf: losses.length && sum(losses) < 0 ? sum(wins) / -sum(losses) : Infinity,
    totalR: sum(rs), maxDdR: dd, maxLoseStreak: maxStreak,
    ret: bal - 1, cagr: Math.pow(bal, 1 / years) - 1, maxDdPct: ddPct, perYear: n / years
  };
}

function monteCarlo(rs, runs = 5000){
  const rand = rng(42), dds = [], rets = [];
  for(let k = 0; k < runs; k++){
    let bal = 1, peak = 1, dd = 0;
    for(let i = 0; i < rs.length; i++){
      const r = rs[Math.floor(rand() * rs.length)];        /* bootstrap: dobara chun ke */
      bal *= 1 + RISK * r; peak = Math.max(peak, bal); dd = Math.max(dd, 1 - bal / peak);
    }
    dds.push(dd); rets.push(bal - 1);
  }
  const pct = (a, q) => { const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(q * s.length))] };
  return {
    runs, dd50: pct(dds, .5), dd95: pct(dds, .95), dd99: pct(dds, .99),
    ret5: pct(rets, .05), ret50: pct(rets, .5), ret95: pct(rets, .95),
    pLoss: rets.filter(r => r < 0).length / runs, pDd30: dds.filter(d => d >= .3).length / runs
  };
}

/* randomness test: har trade ki disha sikke se — strategy ka expectancy kitni baar beat hota hai */
function randomTest(trades, runs = 5000){
  const ok = trades.filter(t => t.alt);
  if(!ok.length) return {p: 1, runs: 0};
  const real = ok.reduce((s, t) => s + t.r, 0) / ok.length;
  const rand = rng(7);
  let beat = 0;
  for(let k = 0; k < runs; k++){
    let s = 0;
    for(const t of ok) s += rand() < .5 ? t.r : t.alt.r;
    if(s / ok.length >= real) beat++;
  }
  return {p: (beat + 1) / (runs + 1), runs, real};
}

/* ---------------- chalao ---------------- */
const bars = {}, trades = {};
for(const pair of Object.keys(PAIRS)){
  const f = path.join(DATA, `${pair}_H1.csv`);
  if(!fs.existsSync(f)){ console.error(`❌ ${f} nahi mila — pehle node quant/fetch-data.mjs`); process.exit(1) }
  bars[pair] = loadCsv(f);
  trades[pair] = runStrategy(bars[pair], pair, DEFAULTS);
  console.log(`${pair}: ${bars[pair].length} candles → ${trades[pair].length} trades`);
}
const all = Object.values(trades).flat().sort((a, b) => a.t - b.t);
const split = list => ({is: list.filter(t => t.t < OOS_FROM), oos: list.filter(t => t.t >= OOS_FROM)});

const groups = {'Dono (EURUSD + XAUUSD)': all, ...trades};
const summary = {};
for(const [name, list] of Object.entries(groups)){
  const s = split(list);
  summary[name] = {all: stats(list), is: stats(s.is), oos: stats(s.oos)};
}

/* saal-dar-saal */
const years = {};
for(const t of all){
  const y = new Date(t.t).getUTCFullYear();
  (years[y] ||= {EURUSD: [], XAUUSD: [], all: []});
  years[y][t.pair].push(t); years[y].all.push(t);
}

const mc = monteCarlo(all.map(t => t.r));
const mcOos = monteCarlo(split(all).oos.map(t => t.r));
const rnd = randomTest(all), rndOos = randomTest(split(all).oos);

/* robustness grid: tMin × rr, dono pair saath, IS aur OOS */
const T_GRID = [0, 1, 1.5, 2, 2.5, 3], RR_GRID = [1, 1.5, 2, 2.5, 3];
const grid = [];
for(const tMin of T_GRID){
  const row = [];
  for(const rr of RR_GRID){
    const p = {...DEFAULTS, tMin, rr};
    const tl = Object.keys(PAIRS).flatMap(pair => runStrategy(bars[pair], pair, p));
    const s = split(tl);
    row.push({tMin, rr, is: stats(s.is), oos: stats(s.oos)});
  }
  grid.push(row);
}

const why = {sl: 0, tp: 0, time: 0};
for(const t of all) why[t.why]++;

const dataInfo = Object.fromEntries(Object.entries(bars).map(([p, b]) => [p, {candles: b.length, from: b[0].t, to: b.at(-1).t}]));
const results = {generated: new Date().toISOString(), params: DEFAULTS, costs: Object.fromEntries(Object.entries(PAIRS).map(([k, v]) => [k, v.cost])),
  oosFrom: new Date(OOS_FROM).toISOString().slice(0, 10), dataInfo, summary, monteCarlo: {all: mc, oos: mcOos},
  randomTest: {all: rnd, oos: rndOos}, exits: why};
fs.writeFileSync(path.join(OUT, 'results.json'), JSON.stringify(results, null, 1));
fs.writeFileSync(path.join(OUT, 'report.html'), renderHtml());
console.log(JSON.stringify(summary, null, 1));
console.log('MC', mc, 'random', rnd, rndOos);

/* ---------------- report ---------------- */
function renderHtml(){
  const f = (x, d = 2) => Number.isFinite(x) ? x.toFixed(d) : '∞';
  const pc = (x, d = 1) => Number.isFinite(x) ? (x * 100).toFixed(d) + '%' : '—';
  const sg = (x, d = 2) => (x > 0 ? '+' : '') + f(x, d);
  const cls = x => x > 0 ? 'up' : x < 0 ? 'dn' : '';
  const date = t => new Date(t).toISOString().slice(0, 10);
  const A = summary['Dono (EURUSD + XAUUSD)'];

  /* faisla — nateeje se khud likha jaata hai, haath se nahi */
  const oos = A.oos, edgeOk = oos.n >= 50 && oos.exp > 0 && rndOos.p < 0.05;
  const verdict = edgeOk
    ? `Out-of-sample (${results.oosFrom} se, jo data niyam banate waqt dekha hi nahi) me bhi expectancy <b class="up">${sg(oos.exp)}R</b> per trade raha, aur randomness test p = ${f(rndOos.p, 3)} (5% se kam). Matlab edge sirf kismat nahi lagta. Phir bhi win rate ${pc(oos.win, 0)} hai, 100% nahi, aur lagatar ${oos.maxLoseStreak} loss tak aaye.`
    : oos.exp > 0
      ? `Out-of-sample me expectancy <b class="up">${sg(oos.exp)}R</b> positive hai, lekin randomness test p = ${f(rndOos.p, 3)} hai. Itne trades me ye nateeja kismat se bhi aa sakta hai, isliye edge <b>pakka sabit nahi</b> hua. Pehle demo pe chalao.`
      : `Out-of-sample me expectancy <b class="dn">${sg(oos.exp)}R</b> hai. Is version me <b>asli paise lagane layak edge nahi</b> mila. Ye imaandaar nateeja hai; isse live na chalao.`;

  /* equity curve (R) */
  const W = 720, H = 220, P = 34;
  let eq = 0;
  const pts = all.map(t => (eq += t.r));
  const minE = Math.min(0, ...pts), maxE = Math.max(1, ...pts);
  const t0 = all[0]?.t || 0, t1 = all.at(-1)?.t || 1;
  const X = t => P + (W - 2 * P) * (t - t0) / ((t1 - t0) || 1);
  const Y = v => H - P + 10 - (H - 2 * P) * (v - minE) / ((maxE - minE) || 1);
  const path1 = pts.map((v, i) => `${i ? 'L' : 'M'}${X(all[i].t).toFixed(1)},${Y(v).toFixed(1)}`).join('');
  const xo = X(OOS_FROM);
  const yTicks = [minE, 0, maxE / 2, maxE].filter((v, i, a) => a.indexOf(v) === i);
  const yearTicks = Object.keys(years).map(Number).filter(y => Date.UTC(y, 0, 1) >= t0);
  const svg = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Equity curve in R">
    ${yTicks.map(v => `<line x1="${P}" x2="${W - P}" y1="${Y(v)}" y2="${Y(v)}" class="grid"/><text x="${P - 4}" y="${Y(v) + 3}" text-anchor="end" class="ax">${f(v, 0)}R</text>`).join('')}
    ${yearTicks.map(y => `<text x="${X(Date.UTC(y, 0, 1))}" y="${H - 6}" text-anchor="middle" class="ax">${String(y).slice(2)}</text>`).join('')}
    <rect x="${xo}" y="${P - 14}" width="${W - P - xo}" height="${H - 2 * P + 14}" class="oosbg"/>
    <text x="${xo + 4}" y="${P - 3}" class="ax">Out-of-sample →</text>
    <path d="${path1}" class="eq"/>
  </svg>`;

  const row = (label, s) => s.n ? `<tr><td>${label}</td><td>${s.n}</td><td>${pc(s.win, 0)}</td><td>${sg(s.avgWin)}</td><td>${f(s.avgLoss)}</td>
    <td class="${cls(s.exp)}"><b>${sg(s.exp, 3)}</b></td><td>${f(s.pf)}</td><td class="${cls(s.totalR)}">${sg(s.totalR, 1)}</td>
    <td>${f(s.maxDdR, 1)}R</td><td>${s.maxLoseStreak}</td><td class="${cls(s.ret)}">${pc(s.ret, 0)}</td><td class="${cls(s.cagr)}">${pc(s.cagr)}</td><td class="dn">${pc(s.maxDdPct)}</td></tr>`
    : `<tr><td>${label}</td><td colspan="12">koi trade nahi</td></tr>`;
  const head = `<tr><th></th><th>Trades</th><th>Win%</th><th>Avg jeet</th><th>Avg haar</th><th>Expectancy</th><th>PF</th><th>Kul R</th><th>Max DD</th><th>Lagatar loss</th><th>Return @1%</th><th>CAGR</th><th>Max DD %</th></tr>`;

  const sumTables = Object.entries(summary).map(([name, s]) => `
    <h3>${name}</h3>
    <div class="tw"><table>${head}${row('Poora', s.all)}${row('In-sample (2016–21)', s.is)}${row('Out-of-sample (2022→)', s.oos)}</table></div>`).join('');

  const yearRows = Object.entries(years).map(([y, v]) => {
    const a = stats(v.all), e = stats(v.EURUSD), x = stats(v.XAUUSD);
    const c = s => s.n ? `<td>${s.n}</td><td class="${cls(s.totalR)}">${sg(s.totalR, 1)}</td>` : '<td>0</td><td>—</td>';
    return `<tr><td>${y}${Date.UTC(+y, 0, 1) >= OOS_FROM ? ' <span class="tag">OOS</span>' : ''}</td>${c(e)}${c(x)}<td>${a.n}</td><td class="${cls(a.totalR)}"><b>${sg(a.totalR, 1)}</b></td><td>${pc(a.win, 0)}</td><td class="${cls(a.ret)}">${pc(a.ret, 1)}</td></tr>`;
  }).join('');

  const gridHtml = which => `<div class="tw"><table class="grid"><tr><th>t-score ↓ / RR →</th>${RR_GRID.map(r => `<th>${r}</th>`).join('')}</tr>
    ${grid.map(r => `<tr><th>${r[0].tMin}</th>${r.map(c => { const s = c[which]; const on = c.tMin === DEFAULTS.tMin && c.rr === DEFAULTS.rr;
      return `<td class="${cls(s.exp)}${on ? ' on' : ''}">${s.n ? sg(s.exp, 2) : '—'}<small>${s.n || 0}</small></td>` }).join('')}</tr>`).join('')}</table></div>`;

  const last = all.slice(-25).reverse().map(t => `<tr><td>${date(t.t)}</td><td>${t.pair}</td><td class="${t.dir > 0 ? 'up' : 'dn'}">${t.dir > 0 ? 'BUY' : 'SELL'}</td>
    <td>${f(t.entry, PAIRS[t.pair].digits)}</td><td>${f(t.sl, PAIRS[t.pair].digits)}</td><td>${f(t.tp, PAIRS[t.pair].digits)}</td><td>${t.why.toUpperCase()}</td><td class="${cls(t.r)}">${sg(t.r)}R</td></tr>`).join('');

  const di = Object.entries(dataInfo).map(([p, d]) => `${p}: ${d.candles.toLocaleString('en-IN')} H1 candles (${date(d.from)} → ${date(d.to)})`).join(' · ');

  return `<!doctype html>
<html lang="hi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SamuQuant Backtest</title>
<style>
:root{--bg:#0d0d0d;--panel:#151515;--line:#2c2c2c;--txt:#f2f2f2;--mut:#9aa0a6;--up:#18c37e;--dn:#ff5a5a;--gold:#ffb800;--acc:#38bdf8;--oos:rgba(56,189,248,.07)}
@media (prefers-color-scheme: light){:root:not([data-theme="dark"]){--bg:#f6f6f4;--panel:#fff;--line:#e2e2de;--txt:#151515;--mut:#5f6368;--up:#0a8a55;--dn:#cc2f2f;--gold:#9a6b00;--acc:#0b6fa4;--oos:rgba(11,111,164,.07)}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--txt);font:14px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:980px;margin:0 auto;padding:20px 16px 60px}
h1{font-size:22px;margin:0 0 2px;color:var(--gold);letter-spacing:.5px}h2{font-size:17px;margin:34px 0 10px}h3{font-size:14px;margin:18px 0 6px;color:var(--mut)}
p{margin:6px 0}.mut{color:var(--mut);font-size:12.5px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:12px 0}
.verdict{border-left:4px solid var(--gold)}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px;margin:14px 0}
.kpi{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 12px}
.kpi b{display:block;font-size:20px;font-variant-numeric:tabular-nums}.kpi span{font-size:12px;color:var(--mut)}
.tw{overflow-x:auto;border:1px solid var(--line);border-radius:10px;background:var(--panel)}
table{border-collapse:collapse;width:100%;font-variant-numeric:tabular-nums;font-size:12.5px}
th,td{padding:6px 9px;text-align:right;border-bottom:1px solid var(--line);white-space:nowrap}
th:first-child,td:first-child{text-align:left}th{color:var(--mut);font-weight:600}
tr:last-child td{border-bottom:0}
table.grid td small{display:block;color:var(--mut);font-size:10px}table.grid td.on{outline:2px solid var(--gold);outline-offset:-2px}
.up{color:var(--up)}.dn{color:var(--dn)}.tag{font-size:10px;color:var(--acc);border:1px solid var(--acc);border-radius:4px;padding:0 4px}
svg{width:100%;height:auto;display:block}.eq{fill:none;stroke:var(--gold);stroke-width:1.6}.grid{stroke:var(--line)}
.ax{fill:var(--mut);font-size:10px}.oosbg{fill:var(--oos)}
ol li,ul li{margin:4px 0}
</style></head><body><main>
<h1>SamuQuant — Backtest Report</h1>
<p class="mut">EURUSD + XAUUSD · H1 · ${di}<br>Bana: ${results.generated.slice(0, 16).replace('T', ' ')} UTC · kharcha ghata ke (EURUSD ${PAIRS.EURUSD.cost / PAIRS.EURUSD.pip} pip, XAUUSD $${PAIRS.XAUUSD.cost} round-trip)</p>

<div class="card verdict"><b>Faisla:</b> ${verdict}</div>

<div class="kpis">
  <div class="kpi"><span>Kul trades</span><b>${A.all.n}</b></div>
  <div class="kpi"><span>Win rate</span><b>${pc(A.all.win, 1)}</b></div>
  <div class="kpi"><span>Expectancy / trade</span><b class="${cls(A.all.exp)}">${sg(A.all.exp, 3)}R</b></div>
  <div class="kpi"><span>Profit factor</span><b>${f(A.all.pf)}</b></div>
  <div class="kpi"><span>Max drawdown @1%</span><b class="dn">${pc(A.all.maxDdPct)}</b></div>
  <div class="kpi"><span>Lagatar max loss</span><b>${A.all.maxLoseStreak}</b></div>
</div>

<h2>Equity curve (R me, dono pair)</h2>
<div class="card">${svg}<p class="mut">1R = ek trade ka risk. Neela hissa = out-of-sample (niyam banate waqt ye data istemal nahi hua).</p></div>

<h2>Nateeje</h2>
<p class="mut">Expectancy = har trade pe ausat kitne R. Return/CAGR/DD = har trade pe account ka 1% risk, compounding.</p>
${sumTables}

<h2>Saal-dar-saal</h2>
<div class="tw"><table><tr><th>Saal</th><th>EUR trades</th><th>EUR R</th><th>XAU trades</th><th>XAU R</th><th>Kul trades</th><th>Kul R</th><th>Win%</th><th>Return @1%</th></tr>${yearRows}</table></div>

<h2>Monte Carlo (${mc.runs.toLocaleString('en-IN')} baar)</h2>
<div class="card">
<p>Trades ko 5000 baar ulat-pulat (bootstrap) karke dekha ki bura kismat ho to kya hota, 1% risk par:</p>
<div class="tw"><table><tr><th></th><th>Median DD</th><th>95% DD</th><th>99% DD</th><th>Return 5% (bura)</th><th>Return median</th><th>Return 95% (accha)</th><th>Loss ka chance</th><th>DD ≥ 30% ka chance</th></tr>
${[['Poora', mc], ['Sirf OOS', mcOos]].map(([l, m]) => `<tr><td>${l}</td><td>${pc(m.dd50)}</td><td>${pc(m.dd95)}</td><td class="dn">${pc(m.dd99)}</td><td class="${cls(m.ret5)}">${pc(m.ret5, 0)}</td><td class="${cls(m.ret50)}">${pc(m.ret50, 0)}</td><td class="${cls(m.ret95)}">${pc(m.ret95, 0)}</td><td>${pc(m.pLoss)}</td><td>${pc(m.pDd30)}</td></tr>`).join('')}
</table></div></div>

<h2>Randomness test — kya edge asli hai?</h2>
<div class="card">
<p>Wahi entry waqt, wahi SL/TP doori, lekin BUY/SELL sikka uchhaal ke. ${rnd.runs.toLocaleString('en-IN')} baar. p-value = kitni baar sikke ne strategy jitna ya behtar kiya.</p>
<div class="tw"><table><tr><th></th><th>Strategy expectancy</th><th>p-value</th><th>Matlab</th></tr>
${[['Poora', rnd], ['Sirf OOS', rndOos]].map(([l, r]) => `<tr><td>${l}</td><td class="${cls(r.real)}">${sg(r.real || 0, 3)}R</td><td>${f(r.p, 4)}</td><td>${r.p < .01 ? 'Bahut mazboot (1% se kam)' : r.p < .05 ? 'Mazboot (5% se kam)' : 'Kismat se alag nahi'}</td></tr>`).join('')}
</table></div></div>

<h2>Robustness — niyam badle to?</h2>
<div class="card">
<p>Expectancy (R/trade), neeche chhota number = trades. Peela dabba = chuna hua (t ≥ ${DEFAULTS.tMin}, RR ${DEFAULTS.rr}). Accha system wo jiske aas-paas ke dabbe bhi theek hon, sirf ek dabba nahi.</p>
<h3>In-sample (2016–21)</h3>${gridHtml('is')}
<h3>Out-of-sample (2022→)</h3>${gridHtml('oos')}
</div>

<h2>Trade kaise band hue</h2>
<div class="card"><p>TP: <b class="up">${why.tp}</b> · SL: <b class="dn">${why.sl}</b> · Waqt (20:00 UTC): <b>${why.time}</b></p></div>

<h2>Aakhri 25 trades</h2>
<div class="tw"><table><tr><th>Din</th><th>Pair</th><th>Disha</th><th>Entry</th><th>SL</th><th>TP</th><th>Band</th><th>R</th></tr>${last}</table></div>

<h2>Niyam (pehle se tay, backtest dekh ke nahi badle)</h2>
<div class="card"><ol>
<li><b>Trend score:</b> pichhle ${DEFAULTS.trendDays} poore dinon ke log(close) pe seedhi line (OLS regression). t = slope ÷ standard error. t ≥ +${DEFAULTS.tMin} → sirf BUY, t ≤ −${DEFAULTS.tMin} → sirf SELL, beech me koi trade nahi.</li>
<li><b>Asia range:</b> 00:00–07:00 UTC (05:30–12:30 IST) ka high/low. Range daily ATR(${DEFAULTS.atrDays}) ke ${DEFAULTS.minRangeAtr}–${DEFAULTS.maxRangeAtr} guna ke beech.</li>
<li><b>Entry:</b> 07:00–12:00 UTC (12:30–17:30 IST) me pehli H1 candle jo range + ${DEFAULTS.bufferAtr}×ATR ke bahar trend ki disha me CLOSE kare → agli candle ke open pe.</li>
<li><b>SL:</b> range ka beech − buffer. Risk ATR se zyada ho to skip. <b>TP:</b> ${DEFAULTS.rr} × risk.</li>
<li><b>Waqt:</b> 20:00 UTC (01:30 IST) tak na lage to band. Din me ek trade per pair. Har trade pe 1% risk.</li>
<li>Ek candle me SL aur TP dono chhue to SL maana (bura maan ke). Koi martingale/grid nahi.</li>
</ol></div>

<div class="card mut"><b>Zaroori:</b> Backtest bhavishya ki guarantee nahi hai. Live me slippage, spread badhna, news aur broker ka fark nateeje bigaad sakte hain. Kam se kam 2–3 mahine demo pe chalao, phir chhote lot se. Koi bhi system 100% accurate nahi hota. Jo dawa kare, wo ya martingale hai ya jhooth.</div>
</main></body></html>`;
}
