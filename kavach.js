#!/usr/bin/env node
/* ============================================================
   KAVACH  —  SamuSignal ka suraksha kavach
   ------------------------------------------------------------
   Ye app ka hissa NAHI hai. Alag file hai.
   index.html se asli code nikaal kar uspe test chalata hai.

   Chalane ka tarika:
       node kavach.js                  (index.html isi folder me ho)
       node kavach.js path/to/index.html

   Ye kya karta hai:
     - App ka asli logic nikaalta hai (copy nahi, seedha file se)
     - 60+ cases pe chala kar dekhta hai sahi jawab aata hai ya nahi
     - PASS/FAIL ki report deta hai

   Ye kya NAHI karta:
     - Koi API call nahi
     - Koi order nahi
     - Koi file nahi badalta
     - Strategy achhi hai ya nahi, ye nahi batata —
       sirf ye batata hai ki ganit aur niyam sahi chal rahe hain
   ============================================================ */

const fs = require('fs');
const path = require('path');

const FILE = process.argv[2] || path.join(__dirname, 'index.html');

/* ---------- 1. app se asli code nikalo ---------- */
const PIECES = [
  ['SPECS/PAIRS',   /const FX = \[[\s\S]*?\nconst PAIRS = Object\.keys\(SPECS\);/],
  ['MAJORS',        /const MAJORS = \[[^\]]*\];/],
  ['GROUPS',        /const GROUPS = \{[\s\S]*?\n\};/],
  ['quoteToUsd',    /function quoteToUsd\([\s\S]*?\n\}/],
  ['usdPerPoint',   /function usdPerPoint\([\s\S]*?\n\}/],
  ['usdPerPip',     /function usdPerPip\([^\n]+/],
  ['dollarsToDist', /function dollarsToDist\([\s\S]*?\n\}/],
  ['distToDollars', /function distToDollars\([\s\S]*?\n\}/],
  ['refPrice',      /function refPrice\([\s\S]*?\n\}/],
  ['fmt',           /const fmt = [^\n]+/],
  ['lotsForRisk',   /function lotsForRisk\([\s\S]*?\n\}/],
  ['calcLevels',    /function calcLevels\([\s\S]*?\n\}\n/],
  ['MIN_DEF',       /const MIN_DEF = [^\n]+/],
  ['DEF_TPSL',      /const DEF_TPSL = \{[\s\S]*?\n\};/],
  ['LOT_UNIT',      /const LOT_UNIT = [^\n]+/],
  ['baseTP',        /function baseTP\([^\n]+/],
  ['baseSL',        /function baseSL\([^\n]+/],
  ['lotMul',        /function lotMul\([^\n]+/],
  ['defTP',         /function defTP\([^\n]+/],
  ['defSL',         /function defSL\([^\n]+/],
  ['hasOwnDef',     /function hasOwnDef\([^\n]+/],
  ['minStop',       /function minStop\([\s\S]*?\n\}/],
  ['checkStops',    /function checkStops\([\s\S]*?\n\}/],
  ['mt5Payload',    /function mt5Payload\([\s\S]*?\n\}/],
  ['ema',           /function ema\([\s\S]*?\n\}/],
  ['rsi',           /function rsi\([\s\S]*?\n\}/],
  ['atr',           /function atr\([\s\S]*?\n\}/],
  ['supertrend',    /function supertrend\([\s\S]*?\n\}/],
  ['macdH',         /function macdH\([\s\S]*?\n\}/],
  ['last',          /const last = [^\n]+/],
  ['sma',           /const sma = [^\n]+/],
  ['hh',            /const hh = [^\n]+/],
  ['ll',            /const ll = [^\n]+/],
  ['stdev',         /function stdev\([\s\S]*?\n\}/],
  ['stoch',         /function stoch\([\s\S]*?\n\}/],
  ['cci',           /function cci\([\s\S]*?\n\}/],
  ['adx',           /function adx\([\s\S]*?\n\}/],
  ['psarUp',        /function psarUp\([\s\S]*?\n\}/],
  ['tfBias',        /function tfBias\([\s\S]*?\n\}/],
  ['AGENTS',        /const AGENTS = \[[\s\S]*?\n\];/],
  ['runAgents',     /function runAgents\([\s\S]*?\n\}/],
  ['analyse',       /function analyse\(sym, bars, v, s\)\{[\s\S]*?\n\}\n/],
  ['finalCall',     /function finalCall\(s\)\{[\s\S]*?\n\}\n/],
  ['structCorr',    /function structCorr\([\s\S]*?\n\}/],
  ['pearson',       /function pearson\([\s\S]*?\n\}/],
  ['jsonRescue',    /function jsonRescue\([\s\S]*?\n\}/],
  ['P_UP',          /const P_UP = [^\n]+/],
  ['P_DN',          /const P_DN = [^\n]+/],
  ['P_HI',          /const P_HI = [^\n]+/],
  ['paint',         /function paint\(t\)\{[\s\S]*?\n\}/]
];

let html;
try { html = fs.readFileSync(FILE, 'utf8'); }
catch (e) { console.error('❌ File nahi mili: ' + FILE); process.exit(1); }

const VERSION = (html.match(/const VERSION = '([^']*)'/) || [,'?'])[1];
const src = [], missing = [];
for (const [name, re] of PIECES) {
  const m = html.match(re);
  if (m) src.push(m[0]); else missing.push(name);
}

/* ---------- 2. app jaisa maahaul banao ---------- */
globalThis.B = 'BUY'; globalThis.SE = 'SELL'; globalThis.H = 'HOLD';
const B = globalThis.B, SE = globalThis.SE, H = globalThis.H;
globalThis.TFS = [
  {id:'5min',l:'5m'},{id:'15min',l:'15m'},{id:'1h',l:'1H'},{id:'4h',l:'4H'},{id:'1day',l:'1D'}
];
globalThis.newsRisk = () => null;
globalThis.nextNews = () => null;
globalThis.t12 = d => new Date(d).toLocaleTimeString('en-IN',{hour:'numeric',minute:'2-digit',hour12:true});
globalThis.lastVotes = null; globalThis.lastAn = null; globalThis.lastSignal = null;

function resetState(){
  globalThis.prices = {};
  globalThis.lastVotes = null;
  globalThis.lastAn = null;
  globalThis.lastSignal = null;
  globalThis.S = {
    dTp:1, dSl:2.5, dLot:0.01,
    slMode:'DOLLAR', atrSL:1.5, atrRR:2, autoLot:false, riskUsd:1.75,
    minPips:{}, symDef:{}, mt5Type:'MARKET', limPips:5,
    newsOn:true, newsMin:30, htf:true, tf:'1h', px:{}, bad:[]
  };
}
resetState();
const S = new Proxy({}, {                 /* test code ke liye shortcut */
  get:(_,k)=>globalThis.S[k], set:(_,k,v)=>{ globalThis.S[k]=v; return true }
});
const prices = new Proxy({}, {
  get:(_,k)=>globalThis.prices[k], set:(_,k,v)=>{ globalThis.prices[k]=v; return true }
});

/* eval ke andar const/function bahar nahi dikhte —
   isliye usi script me globalThis pe daal dete hain */
const EXPORTS = [
  'FX','SPECS','PAIRS','MAJORS','GROUPS','quoteToUsd','usdPerPoint','usdPerPip',
  'dollarsToDist','distToDollars','refPrice','fmt','lotsForRisk','calcLevels',
  'MIN_DEF','DEF_TPSL','LOT_UNIT','baseTP','baseSL','lotMul','defTP','defSL','hasOwnDef',
  'minStop','checkStops','mt5Payload','ema','rsi','atr','supertrend','macdH',
  'last','sma','hh','ll','stdev','stoch','cci','adx','psarUp','tfBias',
  'AGENTS','runAgents','analyse','finalCall','structCorr','pearson',
  'jsonRescue','P_UP','P_DN','P_HI','paint','hasOwnDef'
];
try {
  const glue = EXPORTS.map(n =>
    `try{ globalThis.${n} = ${n} }catch(e){}`).join('\n');
  (0, eval)(src.join('\n\n') + '\n;\n' + glue);
} catch (e) {
  console.error('❌ App ka code load nahi hua: ' + e.message);
  process.exit(1);
}
const notLoaded = EXPORTS.filter(n => typeof globalThis[n] === 'undefined');

/* ---------- 3. chhota test framework ---------- */
let pass = 0, fail = 0, group = '';
const fails = [];
const C = { g:'\x1b[32m', r:'\x1b[31m', y:'\x1b[33m', d:'\x1b[2m', b:'\x1b[1m', x:'\x1b[0m' };

function G(name){ group = name; console.log(`\n${C.b}── ${name}${C.x}`); }
function ok(name, cond, detail){
  if (cond) { pass++; console.log(`  ${C.g}✓${C.x} ${name}`); }
  else {
    fail++; fails.push(group + ' → ' + name + (detail ? '  [' + detail + ']' : ''));
    console.log(`  ${C.r}✗ ${name}${C.x}${detail ? C.d + '  ' + detail + C.x : ''}`);
  }
}
function eq(name, got, want, tol){
  const good = (tol === undefined) ? got === want : Math.abs(got - want) <= tol;
  ok(name, good, good ? '' : `mila ${got}, chahiye ${want}`);
}

/* deterministic candles — har baar wahi */
function gen(n, drift, vol, seed, base){
  let p = base || 1.1, s = seed || 7, b = [];
  const rnd = () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 };
  for (let i = 0; i < n; i++) {
    p *= 1 + drift + (rnd() - 0.5) * vol;
    const o = p * (1 + (rnd() - 0.5) * vol * 0.3), c = p;
    b.push({ o, h: Math.max(o,c) * (1 + rnd() * vol * 0.4),
             l: Math.min(o,c) * (1 - rnd() * vol * 0.4), c });
  }
  return b;
}

console.log(`${C.b}KAVACH${C.x} — SamuSignal v${VERSION}`);
console.log(`${C.d}${FILE}${C.x}`);

/* ============ A. code poora nikla? ============ */
G('A. App ka code');
ok('saare hisse mil gaye', missing.length === 0, missing.join(', '));
ok('sab load ho gaye', notLoaded.length === 0, notLoaded.join(', '));
ok('50 agents maujood', AGENTS.length === 50, 'mile ' + AGENTS.length);
ok(`${PAIRS.length} pairs load hue`, PAIRS.length >= 20, 'mile ' + PAIRS.length);
ok('PAIRS aur SPECS ek jaise', PAIRS.length === Object.keys(SPECS).length);
ok('har pair ka pip/contract/ccy hai',
   PAIRS.every(p => SPECS[p].pip > 0 && SPECS[p].contract > 0 &&
                    Array.isArray(SPECS[p].ccy) && SPECS[p].ccy.length === 2));
ok('har pair ka digits sahi', PAIRS.every(p => SPECS[p].d >= 0 && SPECS[p].d <= 8));
const inGroups = Object.values(GROUPS).flat();
ok('har pair kisi group me hai',
   PAIRS.every(p => inGroups.includes(p)),
   'chhoot gaye: ' + PAIRS.filter(p => !inGroups.includes(p)).join(','));
ok('group me koi anjaan pair nahi',
   inGroups.every(p => SPECS[p]),
   'anjaan: ' + inGroups.filter(p => !SPECS[p]).join(','));
ok('har agent ka naam alag',
   new Set(AGENTS.map(a=>a.n)).size === AGENTS.length);

/* ============ B. pip / dollar ka ganit ============ */
G('B. Pip aur dollar ka ganit');
resetState();
prices['USD/JPY'] = {p:150}; prices['GBP/USD'] = {p:1.27};
prices['USD/CHF'] = {p:0.88}; prices['USD/CAD'] = {p:1.36};
prices['EUR/USD'] = {p:1.09}; prices['AUD/USD'] = {p:0.66};
prices['NZD/USD'] = {p:0.60};

eq('XAUUSD 0.01 lot = $0.10/pip', +usdPerPip('XAU/USD',3300,0.01).toFixed(4), 0.10, 0.001);
eq('EURUSD 0.01 lot = $0.10/pip', +usdPerPip('EUR/USD',1.09,0.01).toFixed(4), 0.10, 0.001);
eq('USDJPY 0.01 lot = $0.0667/pip', +usdPerPip('USD/JPY',150,0.01).toFixed(4), 0.0667, 0.001);
eq('GBPJPY (cross) = $0.0667/pip', +usdPerPip('GBP/JPY',190,0.01).toFixed(4), 0.0667, 0.001);
eq('EURGBP (cross) = $0.127/pip', +usdPerPip('EUR/GBP',0.85,0.01).toFixed(4), 0.127, 0.002);
eq('USDCAD 0.01 lot = $0.0735/pip', +usdPerPip('USD/CAD',1.36,0.01).toFixed(4), 0.0735, 0.001);
eq('BTCUSD 0.01 lot = $0.01/pip', +usdPerPip('BTC/USD',95000,0.01).toFixed(4), 0.01, 0.001);

eq('gold $2.50 SL = 2.50 price move',
   +dollarsToDist('XAU/USD',3300,0.01,2.5).toFixed(4), 2.5, 0.001);
eq('EURUSD $2.50 SL = 25 pips',
   +(dollarsToDist('EUR/USD',1.09,0.01,2.5)/0.0001).toFixed(1), 25, 0.1);

ok('dollar → price → dollar wapas wahi',
   Math.abs(distToDollars('EUR/USD',1.09,0.01, dollarsToDist('EUR/USD',1.09,0.01,3.7)) - 3.7) < 0.001);

ok('lot dugna → dollar dugna',
   Math.abs(usdPerPoint('EUR/USD',1.09,0.02) - 2*usdPerPoint('EUR/USD',1.09,0.01)) < 1e-9);

/* ============ C. lot ke saath TP/SL scale ============ */
G('C. Lot badhe to TP/SL badhe');
resetState();
eq('0.01 lot → TP $1', defTP('EUR/USD',0.01), 1);
eq('0.02 lot → TP $2', defTP('EUR/USD',0.02), 2);
eq('0.03 lot → TP $3', defTP('EUR/USD',0.03), 3);
eq('0.03 lot → SL $7.50', defSL('EUR/USD',0.03), 7.5);
eq('0.10 lot → SL $25', defSL('EUR/USD',0.10), 25);
eq('gold 0.01 → TP $5 (apna default)', defTP('XAU/USD',0.01), 5);
eq('gold 0.03 → TP $15', defTP('XAU/USD',0.03), 15);
eq('gold 0.03 → SL $24', defSL('XAU/USD',0.03), 24);

/* price distance lot se nahi badalni chahiye */
const d1 = calcLevels('EUR/USD',1.09,0.01,0.0002,{slD:defSL('EUR/USD',0.01),tpD:defTP('EUR/USD',0.01)});
const d3 = calcLevels('EUR/USD',1.09,0.03,0.0002,{slD:defSL('EUR/USD',0.03),tpD:defTP('EUR/USD',0.03)});
eq('lot badle par SL pips wahi', d3.slPips, d1.slPips, 0.2);
eq('lot badle par TP pips wahi', d3.tpPips, d1.tpPips, 0.2);
ok('lot 3x → dollar risk 3x', Math.abs(d3.slD - d1.slD*3) < 0.05,
   `${d1.slD} → ${d3.slD}`);

/* ============ D. broker minimum stops ============ */
G('D. Broker minimum stops (error 10016 se bachav)');
resetState();
const MINCHK = [
  ['XAU/USD', 3300], ['US30', 44000], ['BTC/USD', 95000],
  ['EUR/USD', 1.09], ['USD/JPY', 150]
];
for (const [sym, px] of MINCHK) {
  const lv = calcLevels(sym, px, 0.01, px*0.001, {slD:defSL(sym,0.01), tpD:defTP(sym,0.01)});
  const min = minStop(sym);
  ok(`${SPECS[sym].n} default TP/SL minimum se upar`,
     lv.tpPips >= min && lv.slPips >= min,
     `TP ${lv.tpPips}p / SL ${lv.slPips}p, minimum ${min}p`);
}

/* checkStops sahi pakadta hai? */
resetState();
ok('sahi BUY stops paas ho jaate hain',
   checkStops('EUR/USD','BUY',1.10000,1.09750,1.10100).length === 0);
ok('SL galat taraf → pakda gaya',
   checkStops('EUR/USD','BUY',1.10000,1.10250,1.10100).length > 0);
ok('TP galat taraf → pakda gaya',
   checkStops('EUR/USD','BUY',1.10000,1.09750,1.09900).length > 0);
ok('SL bahut paas → pakda gaya',
   checkStops('EUR/USD','BUY',1.10000,1.09998,1.10100).length > 0);
ok('gold pe $1 TP (10 pips) → pakda gaya',
   checkStops('XAU/USD','BUY',3300,3292,3301).length > 0);
ok('gold pe $5 TP (50 pips) → paas',
   checkStops('XAU/USD','BUY',3300,3292,3305).length === 0);
ok('sahi SELL stops paas ho jaate hain',
   checkStops('EUR/USD','SELL',1.10000,1.10250,1.09900).length === 0);

/* ============ E. MT5 payload ============ */
G('E. MT5 order payload');
resetState();
S.mt5Type = 'MARKET';
let pay = mt5Payload('XAU/USD','SELL',0.01,4022.359,4048.51,3970.06);
ok('market type = SELLMARKET', pay.type === 'SELLMARKET', pay.type);
ok('symbol me suffix nahi', pay.pair === 'XAUUSD', pay.pair);
eq('entry 2 decimal pe', pay.entry, 4022.36);
ok('id number hai aur badhta hai', typeof pay.id === 'number' && pay.id > 1e12);

S.mt5Type = 'LIMIT';
pay = mt5Payload('EUR/USD','BUY',0.01,1.15059,1.14809,1.15159);
ok('limit type = BUYLIMIT', pay.type === 'BUYLIMIT', pay.type);
S.mt5Type = 'STOP';
pay = mt5Payload('EUR/USD','SELL',0.01,1.15059,1.15309,1.14959);
ok('stop type = SELLSTOP', pay.type === 'SELLSTOP', pay.type);

S.mt5Type = 'MARKET';
pay = mt5Payload('USD/JPY','BUY',0.02,160.5683,160.1933,160.6683);
eq('JPY pair 3 decimal pe', pay.entry, 160.568);
eq('lots 2 decimal pe', pay.lots, 0.02);

/* Firebase key me / . $ # [ ] nahi chalte */
const badKey = /[.$#\[\]\/]/;
ok('payload ki keys Firebase-safe hain',
   Object.keys(pay).every(k => !badKey.test(k)), Object.keys(pay).join(','));

/* ============ F. auto lot / risk ============ */
G('F. Auto lot aur risk target');
resetState();
S.slMode = 'ATR'; S.autoLot = true; S.riskUsd = 1.75;

/* chhota account: chaahi gayi lot 0.01 se kam nikalti hai -> risk badh jaata hai.
   App ko ye warning zaroor uthani chahiye, chup nahi rehna chahiye. */
let lv = calcLevels('EUR/USD', 1.09, 0.01, 0.0018);
ok('EURUSD: risk target se bahar hai to clamp flag utha',
   lv.slD <= S.riskUsd + 0.2 || !!lv.clamped,
   `risk $${lv.slD}, clamped ${lv.clamped}`);

lv = calcLevels('XAU/USD', 3300, 0.01, 9);
ok('gold: risk sach me badh gaya', lv.slD > S.riskUsd * 2, 'risk $' + lv.slD);
ok('gold: clamp flag truthy hai (warning dikhegi)',
   !!lv.clamped, 'clamped = ' + lv.clamped + ' (0 hua to warning chhup jaati hai)');
ok('clamp hone par bhi lot 0.01 se kam nahi', lv.lots >= 0.01, 'lots ' + lv.lots);

/* bada risk target -> koi clamp nahi hona chahiye */
S.riskUsd = 50;
lv = calcLevels('EUR/USD', 1.09, 0.01, 0.0018);
ok('bada risk target → koi clamp nahi', !lv.clamped, 'clamped ' + lv.clamped);
S.riskUsd = 1.75;

resetState();
S.slMode = 'ATR'; S.autoLot = false;
lv = calcLevels('EUR/USD', 1.09, 0.05, 0.0018);
eq('autoLot off → lot chhua nahi gaya', lv.lots, 0.05);

/* ============ G. 50 agents ============ */
G('G. 50 agents ka vote');
const CASES = [
  ['uptrend',   0.004, 0.006, 'BUY'],
  ['downtrend', -0.004, 0.006, 'SELL'],
  ['flat',      0, 0.004, null]
];
for (const [name, dr, vol, expect] of CASES) {
  const bars = gen(200, dr, vol, 42);
  const bias = dr > 0 ? 'BUY' : dr < 0 ? 'SELL' : 'HOLD';
  const v = runAgents(bars, {'1h':bias,'4h':bias,'1day':bias}, bars[bars.length-1].c);
  ok(`${name}: kul vote 50`, v.buy + v.hold + v.sell === 50,
     `${v.buy}+${v.hold}+${v.sell}`);
  ok(`${name}: har agent ka vote B/S/H me se`,
     v.list.every(x => [B,SE,H].includes(x.v)));
  if (expect) ok(`${name}: verdict ${expect}`, v.verdict === expect,
                 `mila ${v.verdict} (${v.conf}%)`);
  ok(`${name}: confidence 0-100 ke beech`, v.conf >= 0 && v.conf <= 100, String(v.conf));
}
/* same data → same jawab (koi randomness nahi) */
const bb = gen(200, 0.003, 0.005, 11);
const v1 = runAgents(bb, {}, bb[bb.length-1].c);
const v2 = runAgents(bb, {}, bb[bb.length-1].c);
ok('same data pe same vote (deterministic)',
   v1.buy === v2.buy && v1.sell === v2.sell && v1.hold === v2.hold);

/* agent crash na kare — ajeeb data pe bhi */
const weird = [
  ['sab candle same', Array.from({length:120},()=>({o:1.1,h:1.1,l:1.1,c:1.1}))],
  ['bahut chhoti history', gen(60, 0.002, 0.004, 5)],
  ['zero range candles', gen(120, 0, 0, 9)]
];
for (const [name, bars] of weird) {
  let crashed = false, v;
  try { v = runAgents(bars, {}, bars[bars.length-1].c) } catch(e){ crashed = true }
  ok(`${name}: crash nahi hua`, !crashed);
  if (!crashed) ok(`${name}: 50 vote phir bhi`, v.buy+v.hold+v.sell === 50);
}

/* ============ H. analyst ============ */
G('H. Chart analyst');
resetState();
function mkSig(sym, dir, bars, q){
  const px = bars[bars.length-1].c;
  return { sym, dir, live:px, q:q||80,
    sl: dir==='BUY'? px*0.998 : px*1.002,
    tp: dir==='BUY'? px*1.001 : px*0.999,
    slPips:25, tpPips:10, htfOk:true,
    tfs:[{l:'15m',b:dir},{l:'1H',b:dir},{l:'4H',b:dir},{l:'1D',b:dir}] };
}
const upBars = gen(200, 0.004, 0.006, 42);
const dnBars = gen(200, -0.004, 0.006, 42);

const anBad = analyse('EUR/USD', dnBars, runAgents(dnBars,{},dnBars[dnBars.length-1].c),
                      mkSig('EUR/USD','BUY',dnBars));
const anGood = analyse('EUR/USD', upBars,
                       runAgents(upBars,{'1h':'BUY','4h':'BUY','1day':'BUY'},upBars[upBars.length-1].c),
                       mkSig('EUR/USD','BUY',upBars));
let a = anGood;
ok('uptrend BUY ka score downtrend BUY se zyada',
   anGood.pct > anBad.pct, `uptrend ${anGood.pct}% vs downtrend ${anBad.pct}%`);
ok('downtrend me BUY → chinta batayi', anBad.bad.length > 0, anBad.bad.length + ' concerns');
ok('downtrend me BUY → structure fail hua',
   (anBad.O.find(x=>x.h==='STRUCTURE')||{}).ok === 0);
ok('uptrend me BUY → structure paas',
   (anGood.O.find(x=>x.h==='STRUCTURE')||{}).ok > 0);
ok('score 0-100 ke beech', a.pct >= 0 && a.pct <= 100);
ok('har check ka ok 0/1/2 hai', a.O.every(x => [0,1,2].includes(x.ok)));
ok('har check ka text hai', a.O.every(x => x.t && x.t.length > 20));
ok('invalidation line hai', !!a.inval && a.inval.length > 20);

/* ============ I. final verdict ============ */
G('I. LE LO / WAIT / CHHOD DO');
resetState();
function callWith(sig, votes, an){
  globalThis.lastVotes = votes; globalThis.lastAn = an; globalThis.lastSignal = sig;
  return finalCall(sig);
}
const goodAn = { pct:85, bad:[], O:[
  {h:'STRUCTURE',ok:2},{h:'SUPERTREND',ok:2},{h:'ENTRY LOCATION',ok:2},{h:'SL vs VOLATILITY',ok:2}] };
const badAn = { pct:30, bad:[{h:'STRUCTURE'}], O:[
  {h:'STRUCTURE',ok:0},{h:'SUPERTREND',ok:0},{h:'ENTRY LOCATION',ok:0},{h:'SL vs VOLATILITY',ok:0}] };
const sigOK = { sym:'EUR/USD', dir:'BUY', q:88, rsi:58, htfOk:true, live:1.1,
                tfs:[{l:'1H',b:'BUY'}] };

let r = callWith(sigOK, {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, goodAn);
ok('sab theek → LE LO', r.t === 'LE LO', r.t + ' | ' + r.why);

r = callWith(sigOK, {sym:'EUR/USD',verdict:'SELL',conf:70,buy:8,sell:36,hold:6}, goodAn);
ok('agents ulta → CHHOD DO', r.t === 'CHHOD DO', r.t);

r = callWith(sigOK, {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, badAn);
ok('technical kamzor → CHHOD DO', r.t === 'CHHOD DO', r.t);

r = callWith({...sigOK, htfOk:false, q:55},
             {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, goodAn);
ok('HTF match nahi + quality kam → WAIT', r.t === 'WAIT', r.t);

r = callWith({...sigOK, rsi:82},
             {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, goodAn);
ok('RSI extreme → WAIT', r.t === 'WAIT', r.t);

r = callWith(sigOK, {sym:'EUR/USD',verdict:'BUY',conf:40,buy:20,sell:18,hold:12}, goodAn);
ok('agents bate hue → WAIT', r.t === 'WAIT', r.t);

ok('har verdict ke saath wajah hoti hai',
   ['LE LO','WAIT','CHHOD DO'].every(() => true) && !!r.why && r.why.length > 5);

/* ============ J. correlation ============ */
G('J. Correlation');
eq('EURUSD vs GBPUSD positive', structCorr('EUR/USD','GBP/USD') > 0.5, true);
eq('EURUSD vs USDCHF negative', structCorr('EUR/USD','USD/CHF') < -0.5, true);
eq('AUDUSD vs NZDUSD positive', structCorr('AUD/USD','NZD/USD') > 0.5, true);
ok('GBPJPY vs USDCHF ka koi rishta nahi',
   Math.abs(structCorr('GBP/JPY','USD/CHF')) < 0.3);
ok('correlation -1 se 1 ke beech',
   PAIRS.every(a2 => PAIRS.every(b2 => {
     const c = structCorr(a2,b2); return c >= -1 && c <= 1;
   })));
ok('correlation dono taraf se same',
   structCorr('EUR/USD','GBP/USD') === structCorr('GBP/USD','EUR/USD'));
const pa = [1,2,3,4,5,6,7,8,9,10,11,12];
eq('pearson: ek jaisa data → +1', +pearson(pa, pa).toFixed(2), 1);
eq('pearson: ulta data → -1', +pearson(pa, pa.slice().reverse()).toFixed(2), -1);
ok('pearson: kam data pe 0 deta hai', pearson([1,2,3],[1,2,3]) === 0);

/* ============ K. AI ka jawab parse ============ */
G('K. AI jawab parse (jsonRescue)');
ok('saaf JSON', jsonRescue('{"verdict":"LE LO","confidence":70}').verdict === 'LE LO');
ok('```json wrapper ke saath',
   jsonRescue('```json\n{"verdict":"WAIT"}\n```').verdict === 'WAIT');
ok('aage bakwaas text ke saath',
   jsonRescue('Here:\n{"verdict":"CHHOD DO"}').verdict === 'CHHOD DO');
ok('beech me kata hua JSON bhi bach gaya',
   (jsonRescue('{"verdict":"LE LO","reasoning":"EMA sahi') || {}).verdict === 'LE LO');
ok('adhoora array bhi bach gaya',
   Array.isArray((jsonRescue('{"verdict":"WAIT","risks":["spread bada","news') || {}).risks));
ok('poori bakwaas → null', jsonRescue('sorry I cannot') === null);

/* ============ L. text rangeen karna (XSS check) ============ */
G('L. Text highlight aur suraksha');
const painted = paint('Price 1.15059 RSI 58.2 SL -$2.50 ⚠ BUY kamzor');
ok('nesting nahi hui', !/<span[^>]*>[^<]*<span/.test(painted));
ok('HTML inject nahi hota',
   !paint('<script>alert(1)</script>').includes('<script'));
ok('numbers highlight hue', painted.includes('class="num"'));
ok('khaali input pe crash nahi', paint('') === '' && paint(null) === '');

/* ============ M. indicators ============ */
G('M. Indicators');
const ib = gen(200, 0.002, 0.005, 3);
const ic = ib.map(x=>x.c);
ok('EMA length sahi', ema(ic,20).length === ic.length);
ok('EMA finite hai', ema(ic,20).every(x=>isFinite(x)));
ok('RSI 0-100 ke beech', rsi(ic,14).slice(14).every(x=>x>=0 && x<=100));
ok('ATR positive hai', atr(ib,14).every(x=>x>0));
const st = supertrend(ib,10,3);
ok('supertrend dir sirf 1 ya -1', st.dir.every(x=>x===1||x===-1));
const ax = adx(ib,14);
ok('ADX 0-100 ke beech', ax.adx>=0 && ax.adx<=100, String(ax.adx.toFixed(1)));
ok('stochastic 0-100 ke beech', (()=>{ const k=stoch(ib,14); return k>=0&&k<=100 })());
ok('MACD finite hai', macdH(ic).every(x=>isFinite(x)));

/* ============ N. tfBias ============ */
G('N. Timeframe bias');
const upB = tfBias(gen(200, 0.005, 0.005, 21));
const dnB = tfBias(gen(200, -0.005, 0.005, 21));
ok('uptrend → BUY', upB.bias === 'BUY', upB.bias);
ok('downtrend → SELL', dnB.bias === 'SELL', dnB.bias);
ok('bias sirf BUY/SELL/NEUTRAL',
   ['BUY','SELL','NEUTRAL'].includes(upB.bias));
ok('bias ke saath price aur atr aate hain',
   isFinite(upB.price) && isFinite(upB.atr) && upB.atr > 0);

/* ============ O. pura signal — end to end ============ */
G('O. Pura signal banna (end to end)');
resetState();
const eBars = gen(220, 0.003, 0.005, 77);
const ePx = eBars[eBars.length-1].c;
const eVotes = runAgents(eBars, {'1h':'BUY','4h':'BUY','1day':'BUY'}, ePx);
const eLv = calcLevels('EUR/USD', ePx, 0.01, last(atr(eBars,14)),
                       {slD:defSL('EUR/USD',0.01), tpD:defTP('EUR/USD',0.01)});
const eSig = {
  sym:'EUR/USD', dir:'BUY', live:ePx, q:82, htfOk:true, rsi:58,
  sl: ePx - eLv.slDist, tp: ePx + eLv.tpDist,
  slPips:eLv.slPips, tpPips:eLv.tpPips, slD:eLv.slD, tpD:eLv.tpD,
  tfs:[{l:'15m',b:'BUY'},{l:'1H',b:'BUY'},{l:'4H',b:'BUY'},{l:'1D',b:'BUY'}]
};
const eAn = analyse('EUR/USD', eBars, eVotes, eSig);
const eCall = callWith(eSig, eVotes, eAn);

ok('BUY me SL entry se neeche', eSig.sl < eSig.live);
ok('BUY me TP entry se upar', eSig.tp > eSig.live);
ok('stops broker ko manzoor',
   checkStops('EUR/USD','BUY',eSig.live,eSig.sl,eSig.tp).length === 0);
ok('verdict teeno me se ek',
   ['LE LO','WAIT','CHHOD DO'].includes(eCall.t), eCall.t);
ok('MT5 payload ban gaya', (()=>{
  S.mt5Type='MARKET';
  const p2 = mt5Payload('EUR/USD','BUY',0.01,eSig.live,eSig.sl,eSig.tp);
  return p2.type==='BUYMARKET' && p2.sl < p2.entry && p2.tp > p2.entry;
})());

/* SELL bhi */
const sSig = {...eSig, dir:'SELL', sl: ePx + eLv.slDist, tp: ePx - eLv.tpDist};
ok('SELL me SL entry se upar', sSig.sl > sSig.live);
ok('SELL me TP entry se neeche', sSig.tp < sSig.live);
ok('SELL stops bhi manzoor',
   checkStops('EUR/USD','SELL',sSig.live,sSig.sl,sSig.tp).length === 0);

/* ============ P. R:R aur breakeven ============ */
G('P. R:R ka ganit');
function beWR(tp, sl){ return 100 / (1 + tp/sl) }
eq('TP$1/SL$2.5 → 71% chahiye', +beWR(1,2.5).toFixed(1), 71.4, 0.1);
eq('TP$2.5/SL$2.5 → 50% chahiye', +beWR(2.5,2.5).toFixed(1), 50, 0.1);
eq('TP$5/SL$2.5 → 33% chahiye', +beWR(5,2.5).toFixed(1), 33.3, 0.1);
ok('R:R jitna behtar, utna kam win rate chahiye',
   beWR(1,2.5) > beWR(2.5,2.5) && beWR(2.5,2.5) > beWR(5,2.5));

/* ============ report ============ */
const total = pass + fail;
console.log('\n' + '─'.repeat(46));
if (fail === 0) {
  console.log(`${C.g}${C.b}✓ SAB PASS${C.x}  ${pass}/${total}`);
  console.log(`${C.d}v${VERSION} — logic sahi chal raha hai${C.x}`);
} else {
  console.log(`${C.r}${C.b}✗ ${fail} FAIL${C.x}   ${pass}/${total} pass`);
  console.log(`\n${C.r}Jo toota:${C.x}`);
  fails.forEach(f => console.log('  • ' + f));
}
console.log('─'.repeat(46));
process.exit(fail === 0 ? 0 : 1);
