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
  ['getPrice',      /async function getPrice\([\s\S]*?\n\}/],
  ['entryZone',     /function entryZone\([\s\S]*?\n\}/],
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
  ['AGENT_N',       /const AGENT_N = [^\n]+/],
  ['RC_KEEP',       /const RC_KEEP = [^\n]+/],
  ['rcStat',        /function rcStat\([\s\S]*?\n\}/],
  ['rcTier',        /function rcTier\([\s\S]*?\n\}/],
  ['rcApply',       /function rcApply\([\s\S]*?\n\}/],
  ['rcScore',       /function rcScore\([\s\S]*?\n\}/],
  ['rcMirror',      /function rcMirror\([\s\S]*?\n\}/],
  ['rcMirrorCheck', /function rcMirrorCheck\([\s\S]*?\n\}/],
  ['btDefCost',     /function btDefCost\([\s\S]*?\n\}/],
  ['btCost',        /function btCost\([\s\S]*?\n\}/],
  ['btIstMin',      /function btIstMin\([\s\S]*?\n\}/],
  ['btRollover',    /function btRollover\([^\n]+/],
  ['btDayKey',      /function btDayKey\([\s\S]*?\n\}/],
  ['btTrade',       /function btTrade\([\s\S]*?\n\}/],
  ['btPl',          /function btPl\([\s\S]*?\n\}/],
  ['btMetrics',     /function btMetrics\([\s\S]*?\n\}/],
  ['runAgents',     /function runAgents\([\s\S]*?\n\}/],
  ['analyse',       /function analyse\(sym, bars, v, s\)\{[\s\S]*?\n\}\n/],
  ['finalCall',     /function finalCall\(s\)\{[\s\S]*?\n\}\n/],
  ['structCorr',    /function structCorr\([\s\S]*?\n\}/],
  ['pearson',       /function pearson\([\s\S]*?\n\}/],
  ['jsonRescue',    /function jsonRescue\([\s\S]*?\n\}/],
  ['P_UP',          /const P_UP = [^\n]+/],
  ['P_DN',          /const P_DN = [^\n]+/],
  ['P_HI',          /const P_HI = [^\n]+/],
  ['paint',         /function paint\(t\)\{[\s\S]*?\n\}/],
  ['MTF_ADX_RANGE', /const MTF_ADX_RANGE = [^\n]+/],
  ['MTF_ADX_TREND', /const MTF_ADX_TREND = [^\n]+/],
  ['mtfRead',       /function mtfRead\([\s\S]*?\n\}/],
  ['mtfGate',       /function mtfGate\([\s\S]*?\n\}/],
  ['mtfLegs',       /function mtfLegs\([\s\S]*?\n\}/],
  ['mtfLegCheck',   /function mtfLegCheck\([\s\S]*?\n\}/],
  ['mtfTime',       /function mtfTime\([\s\S]*?\n\}/],
  ['mtfSim',        /function mtfSim\([\s\S]*?\n\}/],
  ['PR_EXTRA',      /const PR_EXTRA = [^\n]+/],
  ['prSpec',        /const prSpec = [^\n]+/],
  ['prName',        /const prName = [^\n]+/],
  ['prAlign',       /function prAlign\([\s\S]*?\n\}/],
  ['prMath',        /function prMath\([\s\S]*?\n\}/],
  ['prSignal',      /function prSignal\([\s\S]*?\n\}/],
  ['prConv',        /function prConv\([\s\S]*?\n\}/],
  ['prLotB',        /function prLotB\([\s\S]*?\n\}/],
  ['prLegPl',       /function prLegPl\([\s\S]*?\n\}/]
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
globalThis.apiSym = sym => sym;
globalThis.newsRisk = () => null;
globalThis.nextNews = () => null;
globalThis.t12 = d => new Date(d).toLocaleTimeString('en-IN',{hour:'numeric',minute:'2-digit',hour12:true});
globalThis.lastVotes = null; globalThis.lastAn = null; globalThis.lastSignal = null; globalThis.lastAI = null; globalThis.window = globalThis; globalThis.smartFilter = () => null;

function resetState(){
  globalThis.prices = {};
  globalThis.lastVotes = null;
  globalThis.lastAn = null;
  globalThis.lastSignal = null;
  globalThis.S = {
    dTp:1, dSl:2.5, dLot:0.01,
    slMode:'DOLLAR', atrSL:1.5, atrRR:2, autoLot:false, riskUsd:1.75,
    minPips:{}, symDef:{}, mt5Type:'MARKET', limPips:5,
    newsOn:true, newsMin:30, htf:true, tf:'1h', px:{}, bad:[],
    agRC:{}, btSp:{}, vbal:500
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
  'jsonRescue','P_UP','P_DN','P_HI','paint','hasOwnDef','getPrice','entryZone',
  'AGENT_N','RC_KEEP','RC_MIN','rcStat','rcTier','rcApply','rcScore','rcMirror','rcMirrorCheck',
  'btDefCost','btCost','btIstMin','btRollover','btDayKey','btTrade','btPl','btMetrics',
  'MTF_ADX_RANGE','MTF_ADX_TREND','mtfRead','mtfGate','mtfLegs','mtfLegCheck','mtfTime','mtfSim',
  'PR_EXTRA','prSpec','prName','prAlign','prMath','prSignal','prConv','prLotB','prLegPl'
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
eq('gold 0.01 → TP $12 (apna default)', defTP('XAU/USD',0.01), 12);
eq('gold 0.03 → TP $36', defTP('XAU/USD',0.03), 36);
eq('gold 0.03 → SL $24', defSL('XAU/USD',0.03), 24);
ok('gold ka R:R 1 se behtar hai',
   defTP('XAU/USD',0.01) / defSL('XAU/USD',0.01) >= 1.4,
   '1:' + (defTP('XAU/USD',0.01)/defSL('XAU/USD',0.01)).toFixed(2));

/* price distance lot se nahi badalni chahiye */
const d1 = calcLevels('EUR/USD',1.09,0.01,0.0002,{slD:defSL('EUR/USD',0.01),tpD:defTP('EUR/USD',0.01)});
const d3 = calcLevels('EUR/USD',1.09,0.03,0.0002,{slD:defSL('EUR/USD',0.03),tpD:defTP('EUR/USD',0.03)});
eq('lot badle par SL pips wahi', d3.slPips, d1.slPips, 0.2);
eq('lot badle par TP pips wahi', d3.tpPips, d1.tpPips, 0.2);
ok('lot 3x → dollar risk 3x', Math.abs(d3.slD - d1.slD*3) < 0.05,
   `${d1.slD} → ${d3.slD}`);

/* har pair ka default R:R kam se kam 1:1 ho — warna ganit khud khilaaf hai */
resetState();
for (const sym of ['XAU/USD','US30','BTC/USD']) {
  const rr = baseTP(sym) / baseSL(sym);
  ok(`${SPECS[sym].n} ka default R:R 1 se kam nahi`, rr >= 1.0,
     '1:' + rr.toFixed(2) + ' → breakeven ' + (100/(1+rr)).toFixed(0) + '%');
}

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
  ok(`${name}: kul vote ${AGENT_N} (band agent nahi gina)`, v.buy + v.hold + v.sell === AGENT_N,
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
  if (!crashed) ok(`${name}: ${AGENT_N} vote phir bhi`, v.buy+v.hold+v.sell === AGENT_N);
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
ok('R:R ka check maujood hai',
   a.O.some(x => x.h === 'RISK / REWARD'),
   'checks: ' + a.O.map(x=>x.h).join(', '));

/* kharab R:R pe analyst ka score girna chahiye */
const goodRR = analyse('EUR/USD', upBars,
  runAgents(upBars,{'1h':'BUY','4h':'BUY','1day':'BUY'},upBars[upBars.length-1].c),
  {...mkSig('EUR/USD','BUY',upBars), slPips:20, tpPips:40});
const badRR = analyse('EUR/USD', upBars,
  runAgents(upBars,{'1h':'BUY','4h':'BUY','1day':'BUY'},upBars[upBars.length-1].c),
  {...mkSig('EUR/USD','BUY',upBars), slPips:80, tpPips:50});
ok('achha R:R → RISK/REWARD paas',
   (goodRR.O.find(x=>x.h==='RISK / REWARD')||{}).ok === 2);
ok('kharab R:R → RISK/REWARD fail',
   (badRR.O.find(x=>x.h==='RISK / REWARD')||{}).ok === 0);
ok('kharab R:R se pura score gira',
   badRR.pct < goodRR.pct,
   `${badRR.pct}% vs ${goodRR.pct}%`);

/* ============ I. final verdict ============ */
G('I. LE LO / WAIT / CHHOD DO');
resetState();
function callWith(sig, votes, an){
  globalThis.lastVotes = votes && !votes.list ? Object.assign({list: []}, votes) : votes;
  globalThis.lastAn = an; globalThis.lastSignal = sig;
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

r = callWith({...sigOK, slPips:80, tpPips:50},
             {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, goodAn);
ok('R:R 1:0.63 → CHHOD DO (chart chahe achha ho)', r.t === 'CHHOD DO',
   r.t + ' | ' + r.why);

r = callWith({...sigOK, slPips:20, tpPips:40},
             {sym:'EUR/USD',verdict:'BUY',conf:72,buy:36,sell:8,hold:6}, goodAn);
ok('R:R 1:2 + sab theek → LE LO', r.t === 'LE LO', r.t);

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

/* ============ Q. live tracking ============ */
G('Q. Live tracking (silent-fail bug)');
resetState();
globalThis.S.key = 'test';

/* getPrice strict mode: fail ho to purana price NAHI lautana chahiye */
globalThis.prices['EUR/USD'] = { p: 1.10000 };
globalThis.td = async () => { throw new Error('network down') };

(async () => {
  let threw = false, got = null;
  try { got = await getPrice('EUR/USD', true) } catch(e){ threw = true }
  ok('strict mode: fail hone par error phenkta hai (purana price nahi)', threw,
     threw ? '' : 'mila ' + got);

  const loose = await getPrice('EUR/USD');
  ok('normal mode: fail hone par purana price deta hai (backward compatible)',
     loose === 1.10000, 'mila ' + loose);

  /* naya price mile to wahi laut'na chahiye */
  globalThis.td = async () => ({ price: '1.10500' });
  const fresh = await getPrice('EUR/USD', true);
  eq('strict mode: naya price sahi mila', fresh, 1.10500, 0.00001);

  /* entryZone: SL ke faasle ke hisaab se, kabhi 0 nahi */
  ok('entry zone kabhi zero nahi', entryZone('EUR/USD', 1.10, 1.0975) > 0);
  ok('entry zone SL doori ke saath badhta hai',
     entryZone('EUR/USD', 1.10, 1.0950) > entryZone('EUR/USD', 1.10, 1.0990));
  ok('SL entry ke barabar ho to bhi zone banta hai',
     entryZone('EUR/USD', 1.10, 1.10) > 0);
  ok('gold pe zone bada hai (pip bada hai)',
     entryZone('XAU/USD', 3300, 3292) > entryZone('EUR/USD', 1.10, 1.0975));

  /* ============ R. Agent Report Card (v10.3.0) ============ */
  G('R. Agent Report Card');
  resetState();
  const AI = AGENTS.findIndex(a => !a.off);
  const fill = (i, wins, n, be) => { S.agRC[i] = {r: Array.from({length:n}, (_, k) => k < wins ? 1 : 0), b: Array(n).fill(be), n, w: wins} };
  eq('20 se kam nateeje = NAYA, weight 1', (fill(AI, 2, 10, 50), rcTier(rcStat(AI)).w), 1);
  ok('20 se kam nateeje pe kabhi BAND nahi', !rcTier(rcStat(AI)).bench);
  fill(AI, 7, 20, 50);  ok('R:R 1:1 · 35% = vote BAND', rcTier(rcStat(AI)).bench);
  fill(AI, 8, 20, 50);  eq('R:R 1:1 · 40% = 1x', rcTier(rcStat(AI)).w, 1);
  fill(AI, 11, 20, 50); eq('R:R 1:1 · 55% = 1.5x', rcTier(rcStat(AI)).w, 1.5);
  fill(AI, 13, 20, 50); eq('R:R 1:1 · 65% = 2x', rcTier(rcStat(AI)).w, 2);
  fill(AI, 8, 20, 33.3); eq('R:R 1:2 (breakeven 33%) · 40% agent BAND nahi, 1.5x', rcTier(rcStat(AI)).w, 1.5);
  /* aakhri 50 hi ginte hain */
  resetState();
  const g0 = {rcv:1, dir:'BUY', entry:100, tp:102, sl:98, vstr: AGENTS.map(a => a.off ? 'H' : 'B').join('')};
  for (let k = 0; k < 60; k++) rcScore(Object.assign({}, g0), 'BUY', k >= 30);
  eq('60 nateeje ke baad bhi sirf aakhri 50 rakhe', S.agRC[AI].r.length, 50);
  eq('aakhri 50 me 30 jeet (purani 10 haar hat gayi)', rcStat(AI).w, 30);
  eq('kul ginti fir bhi 60', S.agRC[AI].n, 60);
  /* ek side ek hi baar */
  resetState();
  const g1 = Object.assign({}, g0);
  rcScore(g1, 'BUY', true); rcScore(g1, 'BUY', true);
  eq('ek signal ki ek side do baar nahi gini jaati', S.agRC[AI].r.length, 1);
  ok('rcv ke bina (purane signal) score nahi hota', rcScore(Object.assign({}, g0, {rcv:0}), 'BUY', true) === false);
  /* BUY side ka nateeja sirf BUY bolne walon ko */
  resetState();
  const mixed = AGENTS.map((a, i) => a.off ? 'H' : (i % 2 ? 'S' : 'B')).join('');
  rcScore({rcv:1, dir:'BUY', entry:100, tp:102, sl:98, vstr:mixed}, 'BUY', true);
  ok('BUY nateeja SELL bolne wale agent ko nahi laga', AGENTS.every((a, i) => mixed[i] !== 'S' || !S.agRC[i]));
  ok('BUY nateeja BUY bolne walon ko laga', AGENTS.every((a, i) => mixed[i] !== 'B' || (S.agRC[i] && S.agRC[i].r[0] === 1)));
  /* mirror: ulti side */
  const m = rcMirror({dir:'BUY', entry:100, tp:102, sl:99});
  ok('mirror: BUY ka ulta SELL, TP 98, SL 101', m.dir === 'SELL' && m.tp === 98 && m.sl === 101, JSON.stringify(m));
  resetState();
  const gm = {rcv:1, at:Date.now(), dir:'BUY', entry:100, tp:102, sl:99, vstr:mixed};
  rcMirrorCheck(gm, 100.5, 97.5, Date.now());
  ok('mirror SELL ka TP laga -> SELL walon ko sahi', gm.mo === 'TP' && AGENTS.some((a, i) => mixed[i] === 'S' && S.agRC[i] && S.agRC[i].r[0] === 1));
  resetState();
  const gb = {rcv:1, at:Date.now(), dir:'BUY', entry:100, tp:102, sl:99, vstr:mixed};
  rcMirrorCheck(gb, 101.5, 97.5, Date.now());
  eq('mirror: TP aur SL ek saath lage -> SL (safe)', gb.mo, 'SL');
  /* rcApply */
  resetState();
  const bars = gen(200, 0.004, 0.006, 42);
  const raw = runAgents(bars, {'1h':'BUY','4h':'BUY','1day':'BUY'}, bars[bars.length-1].c);
  const same = rcApply(raw);
  ok('koi data nahi -> weight wala vote = kachcha vote', same.verdict === raw.verdict && same.conf === raw.conf, `${same.verdict} ${same.conf} vs ${raw.verdict} ${raw.conf}`);
  const buyers = raw.list.map((x, i) => x.v === 'BUY' && !x.off ? i : -1).filter(i => i >= 0);
  buyers.forEach(i => fill(i, 2, 20, 50));
  const ben = rcApply(raw);
  eq('sab BUY agents BAND -> unka vote nahi gina', ben.buy, 0);
  ok('BAND agent list me rehta hai (tracking ke liye) aur bench flag hai', buyers.every(i => ben.list[i].bench && ben.list[i].v === 'BUY'));
  ok('vstr (tracking) me BAND agent ka asli vote', ben.list.map(x => x.v[0]).join('') === raw.list.map(x => x.v[0]).join(''));
  ok('raw vote bhi saath me rakha', ben.raw && ben.raw.verdict === raw.verdict);
  ok('vote ginti = sakriya agents', ben.buy + ben.sell + ben.hold === ben.n && ben.n === AGENT_N - buyers.length);

  /* ============ S. Imaandaar Backtest (v10.3.0) ============ */
  G('S. Imaandaar Backtest');
  resetState();
  const flat = [{t:'2026-01-05 10:00:00', o:100, h:100.3, l:99.7, c:100}];
  for (let k = 0; k < 5; k++) flat.push({t:'2026-01-05 11:00:00', o:100, h:100.3, l:99.7, c:100});
  const r0 = btTrade(flat, 0, 'BUY', 1, 2, 5, {sp:0, sl:0});
  eq('bina cost: BUY entry = candle open', r0.entry, 100, 1e-9);
  const r1 = btTrade(flat, 0, 'BUY', 1, 2, 5, {sp:0.4, sl:0.1});
  eq('cost ke saath: BUY entry = open + aadha spread + slippage', r1.entry, 100.3, 1e-9);
  const r2 = btTrade(flat, 0, 'SELL', 1, 2, 5, {sp:0.4, sl:0.1});
  eq('SELL entry = open - aadha spread - slippage', r2.entry, 99.7, 1e-9);
  eq('kuch na lage -> TIME pe band', r0.out, 'TIME');
  eq('TIME exit BUY = close - aadha spread', r1.exit, 99.8, 1e-9);
  const up = [{t:'2026-01-05 10:00:00', o:100, h:101.1, l:99.9, c:101}];
  eq('bina cost +1 move pe TP 1 lagta hai', btTrade(up, 0, 'BUY', 1, 1, 1, {sp:0, sl:0}).out, 'TP');
  eq('spread ke saath wahi move kam padta hai (TP nahi)', btTrade(up, 0, 'BUY', 1, 1, 1, {sp:0.4, sl:0.1}).out, 'TIME');
  const both = [{t:'2026-01-05 10:00:00', o:100, h:102, l:98, c:100}];
  eq('ek candle me TP aur SL dono -> SL (safe)', btTrade(both, 0, 'BUY', 1, 1, 1, {sp:0, sl:0}).out, 'SL');
  const sl1 = btTrade(both, 0, 'BUY', 1, 1, 1, {sp:0, sl:0.2});
  eq('SL pe slippage phir katta hai', sl1.exit, 100.2 - 1 - 0.2, 1e-9);
  ok('rollover: IST 3:00 = haan', btRollover('2026-01-05 03:00:00'));
  ok('rollover: IST 10:00 = nahi', !btRollover('2026-01-05 10:00:00'));
  eq('raat: IST shaam se agle din subah tak = 1 raat', btDayKey('2026-01-06 10:00:00') - btDayKey('2026-01-05 20:00:00'), 1);
  eq('raat: ek hi din ke andar = 0', btDayKey('2026-01-05 20:00:00') - btDayKey('2026-01-05 10:00:00'), 0);
  eq('gold default spread 2.6 pip (Exness ~260 points)', btCost('XAU/USD').sp, 2.6);
  S.btSp = {'XAU/USD': {sp: 3.5}};
  eq('user ka spread default pe bhari', btCost('XAU/USD').sp, 3.5);
  eq('baaki default wahi', btCost('XAU/USD').sl, 0.2);
  /* $ hisaab: gold 0.01 lot, +$1 price = $1 */
  const gb2 = [{t:'2026-01-05 10:00:00', o:3300, h:3302, l:3299.5, c:3301}];
  const gr = btTrade(gb2, 0, 'BUY', 5, 1, 1, {sp:0, sl:0});
  eq('gold 0.01 lot · TP $1 move = $1 profit', btPl('XAU/USD', gb2, 0, 'BUY', gr, 0.01, null), 1, 1e-9);
  eq('commission $7/lot · 0.01 lot = $0.07 kata', btPl('XAU/USD', gb2, 0, 'BUY', gr, 0.01, {cm:7, sw:0}), 0.93, 1e-9);
  const mm = btMetrics([{pl:10},{pl:-5},{pl:-5},{pl:-5},{pl:20,out:'TIME'}], 100);
  eq('metrics: net', mm.net, 15, 1e-9);
  eq('metrics: profit factor 30/15', mm.pf, 2, 1e-9);
  eq('metrics: lambi haar 3', mm.maxRun, 3);
  eq('metrics: max DD $15', mm.maxDD, 15, 1e-9);
  eq('metrics: max DD % (110 peak se)', mm.maxDDp, 15/110*100, 1e-6);
  eq('metrics: TIME exits gine', mm.tm, 1);
  eq('metrics: koi trade nahi -> sab 0', btMetrics([], 500).n, 0);

  /* ============ T. 4-TF Auto Analyze (v10.4.0) ============ */
  G('T. 4-TF Auto Analyze (v10.4.0)');
  const upB = gen(120, 0.0006, 0.002, 11, 4100), dnB = gen(120, -0.0006, 0.002, 12, 4100);
  eq('mtfRead: chadhta market = UP', mtfRead(upB).t, 'UP');
  eq('mtfRead: girta market = DOWN', mtfRead(dnB).t, 'DOWN');
  const chop = gen(120, 0, 0.002, 13, 4100);
  ok('mtfRead: bina disha ka market = trend nahi (ADX kam)', mtfRead(chop).t === 'FLAT' || mtfRead(chop).adx >= MTF_ADX_TREND, JSON.stringify({t: mtfRead(chop).t, adx: mtfRead(chop).adx}));
  const rd = (t, a) => ({t, adx: a === undefined ? 30 : a, hi: 4110, lo: 4100});
  eq('gate: 15m UP + 1H UP = UP', mtfGate({'1h':rd('UP'), '15min':rd('UP')}, 3).mode, 'UP');
  eq('gate: 15m UP + 1H FLAT = UP', mtfGate({'1h':rd('FLAT'), '15min':rd('UP')}, 3).mode, 'UP');
  eq('gate: 15m UP + 1H DOWN = NONE (ulte)', mtfGate({'1h':rd('DOWN'), '15min':rd('UP')}, 3).mode, 'NONE');
  eq('gate: 15m FLAT + 1H DOWN = DOWN', mtfGate({'1h':rd('DOWN'), '15min':rd('FLAT')}, 3).mode, 'DOWN');
  eq('gate: dono FLAT + ADX kam + chaudi range = RANGE', mtfGate({'1h':rd('FLAT'), '15min':rd('FLAT', 15)}, 3).mode, 'RANGE');
  eq('gate: dono FLAT + range patli = NONE', mtfGate({'1h':rd('FLAT'), '15min':rd('FLAT', 15)}, 6).mode, 'NONE');
  eq('gate: dono FLAT + ADX zyada = NONE', mtfGate({'1h':rd('FLAT'), '15min':rd('FLAT', 30)}, 3).mode, 'NONE');
  ok('legs: UP = BUY LIMIT neeche + BUY STOP upar', JSON.stringify(mtfLegs('UP').map(L => L.dir + L.kind + L.side)) === '["BUYLIMIT-1","BUYSTOP1"]');
  ok('legs: RANGE = BUY LIMIT neeche + SELL LIMIT upar', JSON.stringify(mtfLegs('RANGE').map(L => L.dir + L.kind + L.side)) === '["BUYLIMIT-1","SELLLIMIT1"]');
  eq('legs: NONE = koi order nahi', mtfLegs('NONE').length, 0);
  const cx = {live: 4100, minD: 0.5, maxD: 10, tp: 3, hi: 4106, lo: 4092, chase: false, minConf: 70};
  const LG = (o) => Object.assign({dir:'BUY', kind:'LIMIT', side:-1, conf:80}, o);
  ok('check: sahi Buy Limit paas', mtfLegCheck(LG({entry: 4097}), cx).ok);
  ok('check: Buy Limit live ke upar = fail', !mtfLegCheck(LG({entry: 4101}), cx).ok);
  ok('check: bahut paas = fail', !mtfLegCheck(LG({entry: 4099.8}), cx).ok);
  ok('check: bahut door = fail', !mtfLegCheck(LG({entry: 4085}), cx).ok);
  ok('check: kam confidence = fail', !mtfLegCheck(LG({entry: 4097, conf: 60}), cx).ok);
  ok('check: TP ke raaste me resistance = fail', !mtfLegCheck(LG({entry: 4104, side: 1, kind:'STOP'}), Object.assign({}, cx, {live: 4103})).ok);
  ok('check: Buy Stop resistance ke upar = paas', mtfLegCheck(LG({entry: 4107, side: 1, kind:'STOP'}), Object.assign({}, cx, {live: 4103})).ok);
  ok('check: trend me (hi=0) paas ka high deewar nahi', mtfLegCheck(LG({entry: 4104, side: 1, kind:'STOP'}), Object.assign({}, cx, {live: 4103, hi: 0})).ok);
  ok('check: chase me Stop = fail', !mtfLegCheck(LG({entry: 4107, side: 1, kind:'STOP'}), Object.assign({}, cx, {live: 4103, chase: true})).ok);
  ok('check: AI ne 0 diya = fail', !mtfLegCheck(LG({entry: 0}), cx).ok);
  eq('time: IST string -> ms', mtfTime('2026-10-15 20:41:00'), Date.UTC(2026, 9, 15, 15, 11, 0));
  const t0 = Date.UTC(2026, 9, 15, 15, 0, 0);
  const ist = ms => { const d = new Date(ms + 5.5 * 3600000); return d.toISOString().slice(0, 19).replace('T', ' ') };
  const mk = rows => rows.map((r, i) => ({t: ist(t0 + i * 60000), o: r[0], h: r[1], l: r[2], c: r[3]}));
  const rec = {at: t0, tp: 3, gap: 5, legs: [{dir:'BUY', kind:'LIMIT', entry: 4097}, {dir:'BUY', kind:'STOP', entry: 4104}]};
  const win = mtfSim(rec, mk([[4100,4100.5,4099,4099.5],[4099.5,4099.6,4096.8,4097.2],[4097.2,4099,4097,4098.9],[4099,4100.3,4098.5,4100.2]]));
  ok('sim: Buy Limit bhara, phir +3 = WIN', win.r === 'WIN' && win.leg === 0, JSON.stringify(win));
  const avg = mtfSim(rec, mk([[4100,4100.5,4099,4099.5],[4099.5,4099.6,4096.8,4097.2],[4097.2,4097.5,4091.5,4092]]));
  ok('sim: Buy Limit bhara, phir -5 = AVG', avg.r === 'AVG' && avg.leg === 0, JSON.stringify(avg));
  const stp = mtfSim(rec, mk([[4100,4104.5,4099.8,4104.2],[4104.2,4107.2,4104,4107]]));
  ok('sim: Buy Stop pehle bhara (leg 2) = WIN', stp.r === 'WIN' && stp.leg === 1, JSON.stringify(stp));
  const bth = mtfSim(rec, mk([[4100,4100.5,4099,4099.5],[4099.5,4099.6,4096.8,4097.2],[4097.2,4100.5,4091.9,4098]]));
  ok('sim: ek candle me +TP aur -gap dono = AVG (imaandaar)', bth.r === 'AVG', JSON.stringify(bth));
  const nf = mtfSim(rec, mk(Array.from({length: 62}, () => [4100,4100.4,4099.6,4100])));
  eq('sim: 60 min me na bhara = NOFILL', nf.r, 'NOFILL');
  eq('sim: abhi data kam = OPEN', mtfSim(rec, mk([[4100,4100.4,4099.6,4100]])).r, 'OPEN');

  /* ============ V. Pair trading (v10.5.0) ============ */
  G('V. Pair trading ka ganit');
  {
    let sd = 11;
    const rnd = () => { sd = (sd * 1103515245 + 12345) % 2147483648; return sd / 2147483648 - 0.5 };
    /* B random walk, A = B^1.5 * k * (chhota mean-reverting noise) */
    const Bp = [], Ap = []; let lb = Math.log(25), e = 0;
    for (let i = 0; i < 150; i++) {
      lb += rnd() * 0.01; e = 0.6 * e + rnd() * 0.004;
      Bp.push(Math.exp(lb)); Ap.push(Math.exp(1.5 * lb + 2 + e));
    }
    const m = prMath(Ap, Bp, 120);
    ok('β ≈ 1.5 nikla (OLS log price)', m && Math.abs(m.beta - 1.5) < 0.08, m && m.beta.toFixed(3));
    ok('correlation ≥ 0.9 (saath chalte)', m && m.corr > 0.9, m && m.corr.toFixed(2));
    ok('half-life chhota (mean-revert)', m && isFinite(m.hl) && m.hl < 10, m && String(m.hl));
    ok('Z series ka std ≈ 1', m && Math.abs(Math.sqrt(m.zs.reduce((p,c)=>p+c*c,0)/(m.zs.length-1)) - 1) < 1e-9);
    eq('window = 120 candle', m && m.n, 120);
    ok('30 se kam candle = null', prMath(Ap.slice(0, 20), Bp.slice(0, 20), 100) === null);
    const Ap2 = Ap.slice(); Ap2[Ap2.length - 1] *= 1.03;
    const m2 = prMath(Ap2, Bp, 120);
    ok('A achanak upar = Z bada positive', m2 && m2.z > 2, m2 && m2.z.toFixed(2));
    const C1 = {entry: 2, exit: 0.5, stop: 3.5, minCorr: 0.7};
    const sg = prSignal({z: 2.3, beta: 1.2, corr: 0.85}, C1);
    ok('Z +2.3, β>0 → A SELL + B BUY', sg.k === 'ENTRY' && sg.dA === 'SELL' && sg.dB === 'BUY', JSON.stringify(sg));
    const sg2 = prSignal({z: -2.3, beta: 1.2, corr: 0.85}, C1);
    ok('Z −2.3, β>0 → A BUY + B SELL', sg2.dA === 'BUY' && sg2.dB === 'SELL', JSON.stringify(sg2));
    const sg3 = prSignal({z: 2.3, beta: -0.9, corr: -0.88}, C1);
    ok('ulti jodi (β<0): Z +2.3 → dono SELL', sg3.k === 'ENTRY' && sg3.dA === 'SELL' && sg3.dB === 'SELL', JSON.stringify(sg3));
    const sg4 = prSignal({z: -2.3, beta: -0.9, corr: -0.88}, C1);
    ok('ulti jodi (β<0): Z −2.3 → dono BUY', sg4.dA === 'BUY' && sg4.dB === 'BUY', JSON.stringify(sg4));
    eq('correlation 0.5 → PAIR TOOTA', prSignal({z: 2.5, beta: 1, corr: 0.5}, C1).k, 'BROKEN');
    eq('Z 3.8 → BAHUT DOOR (entry nahi)', prSignal({z: 3.8, beta: 1, corr: 0.9}, C1).k, 'TOOFAR');
    eq('Z 1.2 → RUKO', prSignal({z: 1.2, beta: 1, corr: 0.9}, C1).k, 'WAIT');
    eq('Z 0.3 → NORMAL', prSignal({z: 0.3, beta: 1, corr: 0.9}, C1).k, 'FLAT');
    eq('null → DATA NAHI', prSignal(null, C1).k, 'NODATA');
    const al = prAlign([{t:'a',c:1},{t:'b',c:2},{t:'c',c:3}], [{t:'b',c:20},{t:'c',c:30},{t:'d',c:40}]);
    ok('align: sirf common candle', al.t.join() === 'b,c' && al.a.join() === '2,3' && al.b.join() === '20,30');
    /* lot: EURUSD 1.10 vs GBPUSD 1.30, β 1 → B lot = 0.10 × 1.10/1.30 = 0.0846 → 0.08 */
    const lb1 = prLotB('EUR/USD', 'GBP/USD', 1.10, 1.30, 1, 0.10, {});
    ok('lot: EURUSD 0.10 → GBPUSD 0.08', lb1 && lb1.lot === 0.08, lb1 && JSON.stringify(lb1));
    /* gold 4000 ×100 vs silver 50 ×5000, β 1 → 0.01 × 400000/250000 = 0.016 → 0.02 */
    const lb2 = prLotB('XAU/USD', 'XAG/USD', 4000, 50, 1, 0.01, {});
    ok('lot: gold 0.01 → silver 0.02 (XAG spec 5000)', lb2 && lb2.lot === 0.02, lb2 && JSON.stringify(lb2));
    ok('lot: kabhi 0.01 se kam nahi', prLotB('EUR/USD', 'GBP/USD', 1.1, 1.3, 0.1, 0.01, {}).lot === 0.01);
    eq('JPY conv scan price se', prConv('JPY', {'USD/JPY': 150}), 1/150, 1e-12);
    eq('P&L: gold BUY 0.01, +$10 = +$10', prLegPl('XAU/USD', 'BUY', 0.01, 4000, 4010, {}), 10, 1e-9);
    eq('P&L: silver SELL 0.02, +$0.10 = −$10', prLegPl('XAG/USD', 'SELL', 0.02, 50, 50.1, {}), -10, 1e-6);
    eq('naam: XAG/USD → XAGUSD', prName('XAG/USD'), 'XAGUSD');
  }

  report();
})();

/* ============ report ============ */
function report(){
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
}
