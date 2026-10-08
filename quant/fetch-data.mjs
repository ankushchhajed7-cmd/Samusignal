/* Dukascopy se H1 candles → quant/data/<PAIR>_H1[_ask].csv
   GitHub Actions me chalta hai (npm install --no-save dukascopy-node).
   Chalao: node quant/fetch-data.mjs [fromYYYY-MM-DD] [bid|ask] [extra,pairs]

   Incremental: quant/history/*.csv.gz (pehle ka data) padh ke sirf woh saal
   laata hai jo gayab/adhoore hain (aur chalu saal). Dukascopy 429 (zyada tez)
   de to saal chhod ke aage, aur aakhir me dobara koshish. Har pair ke baad
   file likh di jaati hai, taaki beech me ruke to bhi kaam bacha rahe. */
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';
import duka from 'dukascopy-node';          /* CommonJS package */
import { PAIRS } from './strategy.mjs';

const { getHistoricalRates } = duka;
const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, 'data'), HIST = path.join(HERE, 'history');
const FROM = new Date(process.argv[2] || '2016-01-01');
const SIDE = process.argv[3] || 'bid';            /* bid (default) ya ask — spread naapne ke liye */
/* research ke liye aur pairs: node quant/fetch-data.mjs 2008-01-01 bid gbpusd,usdjpy */
const LIST = process.argv[4] ? Object.fromEntries(process.argv[4].split(',').map(x => [x.trim().toUpperCase(), {duka: x.trim().toLowerCase()}])) : PAIRS;
const TF = process.env.QUANT_TF || 'h1';           /* h1 (default) ya d1 (research: bahut saare markets) */
const FULL_YEAR = TF === 'd1' ? 200 : 5000;       /* isse kam candles = saal adhoora */
const sleep = ms => new Promise(r => setTimeout(r, ms));
fs.mkdirSync(DIR, {recursive: true});

function readOld(name){
  const rows = new Map();
  for(const f of [path.join(DIR, name), path.join(HIST, name + '.gz')]){
    if(!fs.existsSync(f)) continue;
    let txt = fs.readFileSync(f);
    if(f.endsWith('.gz')) txt = zlib.gunzipSync(txt);
    for(const l of txt.toString().trim().split('\n').slice(1)){
      const r = l.split(',').map(Number);
      if(r.length >= 5) rows.set(r[0], r.slice(0, 5));
    }
  }
  return rows;
}

async function year(cfg, from, to, tries){       /* from..to ka data (ek ya kai saal) */
  for(let k = 1; k <= tries; k++){
    try{
      return await getHistoricalRates({
        instrument: cfg.duka, dates: {from, to},
        timeframe: TF, priceType: SIDE, format: 'array', volumes: false, ignoreFlats: true,
        batchSize: 3, pauseBetweenBatchesMs: 1500, retryCount: 4, pauseBetweenRetriesMs: 5000,
        retryOnEmpty: true, failAfterRetryCount: true
      });
    }catch(e){
      console.log(`  ${cfg.duka} ${SIDE} ${from.toISOString().slice(0, 4)}: ${e.message} (koshish ${k}/${tries})`);
      if(k < tries) await sleep(k * 30000);
    }
  }
  return null;
}

for(const [pair, cfg] of Object.entries(LIST)){
  const name = `${pair}_${TF.toUpperCase()}${SIDE === 'bid' ? '' : '_' + SIDE}.csv`;
  const rows = readOld(name);
  const perYear = {};
  for(const t of rows.keys()){ const y = new Date(t).getUTCFullYear(); perYear[y] = (perYear[y] || 0) + 1 }
  const nowY = new Date().getUTCFullYear();
  let todo = [];
  for(let y = FROM.getUTCFullYear(); y <= nowY; y++) if(y === nowY || (perYear[y] || 0) < FULL_YEAR) todo.push(y);
  console.log(`${pair} ${SIDE}: ${rows.size} purani candles, laana hai: ${todo.join(' ') || 'kuch nahi'}`);
  for(let pass = 1; pass <= 3 && todo.length; pass++){
    const failed = [];
    /* d1: lagatar saalon ko 3-3 ke tukdon me ek saath (requests kam, 429 pe kam nuksaan) */
    const chunks = [];
    for(const y of todo){
      const c = chunks.at(-1);
      if(TF === 'd1' && c && y === c.at(-1) + 1 && c.length < 3) c.push(y); else chunks.push([y]);
    }
    for(const ys of chunks){
      const from = new Date(Math.max(FROM, Date.UTC(ys[0], 0, 1))), to = new Date(Math.min(Date.now(), Date.UTC(ys.at(-1) + 1, 0, 1)));
      const got = await year(cfg, from, to, 2);
      if(got === null){ failed.push(...ys); await sleep(60000); continue }
      for(const r of got) rows.set(r[0], r.slice(0, 5));
      await sleep(3000);
    }
    todo = failed;
    if(todo.length) console.log(`  ⚠ ${pair} ${SIDE} pass ${pass} me nahi aaye: ${todo.join(' ')}`);
  }
  /* weekend ki flat candles (o=h=l=c, bazaar band) hatao — ye trend/ATR bigaadti hain */
  const real = [...rows.values()].filter(r => !(r[1] === r[2] && r[2] === r[3] && r[3] === r[4])).sort((a, b) => a[0] - b[0]);
  if(!real.length){ console.log(`  ⚠ ${pair} ${SIDE}: koi data nahi`); continue }
  fs.writeFileSync(path.join(DIR, name), 't,o,h,l,c\n' + real.map(r => r.join(',')).join('\n') + '\n');
  console.log(`${pair} ${SIDE}: ${real.length} candles  ${new Date(real[0][0]).toISOString()} → ${new Date(real.at(-1)[0]).toISOString()}${todo.length ? '  (gayab: ' + todo.join(' ') + ')' : ''}`);
}
