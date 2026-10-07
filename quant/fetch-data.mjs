/* Dukascopy se H1 candles (free, 2008 se) → quant/data/<PAIR>_H1.csv
   GitHub Actions me chalta hai (npm install --no-save dukascopy-node).
   Chalao: node quant/fetch-data.mjs [fromYYYY-MM-DD] */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import duka from 'dukascopy-node';          /* CommonJS package */
import { PAIRS } from './strategy.mjs';

const { getHistoricalRates } = duka;
const DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), 'data');
const FROM = new Date(process.argv[2] || '2016-01-01');
const SIDE = process.argv[3] || 'bid';            /* bid (default) ya ask — spread naapne ke liye */
fs.mkdirSync(DIR, {recursive: true});

const sleep = ms => new Promise(r => setTimeout(r, ms));

/* Dukascopy zyada tez maango to 429 deta hai — chhote batch, saal-saal, ruk ruk ke */
async function year(cfg, from, to){
  for(let k = 1; ; k++){
    try{
      return await getHistoricalRates({
        instrument: cfg.duka, dates: {from, to},
        timeframe: 'h1', priceType: SIDE, format: 'array', volumes: false, ignoreFlats: true,
        batchSize: 3, pauseBetweenBatchesMs: 1500, retryCount: 8, pauseBetweenRetriesMs: 5000,
        retryOnEmpty: true, failAfterRetryCount: true
      });
    }catch(e){
      if(k >= 3){ console.log(`  ⚠ ${cfg.duka} ${from.toISOString().slice(0, 10)}: chhod diya (${e.message})`); return [] }
      console.log(`  ${cfg.duka} ${from.toISOString().slice(0, 10)}: ${e.message} — ${k * 20}s ruk ke dobara`);
      await sleep(k * 20000);
    }
  }
}

for(const [pair, cfg] of Object.entries(PAIRS)){
  const file = path.join(DIR, `${pair}_H1${SIDE === 'bid' ? '' : '_' + SIDE}.csv`);
  const rows = [];
  for(let y = FROM.getUTCFullYear(); y <= new Date().getUTCFullYear(); y++){
    const from = new Date(Math.max(FROM, Date.UTC(y, 0, 1))), to = new Date(Math.min(Date.now(), Date.UTC(y + 1, 0, 1)));
    for(const r of await year(cfg, from, to)) if(!rows.length || r[0] > rows.at(-1)[0]) rows.push(r);
    await sleep(2000);
  }
  if(!rows.length) throw new Error(`${pair}: koi data nahi mila`);
  /* weekend ki flat candles (o=h=l=c, bazaar band) hatao — ye trend/ATR bigaadti hain */
  const real = rows.filter(r => !(r[1] === r[2] && r[2] === r[3] && r[3] === r[4]));
  console.log(`${pair}: ${rows.length - real.length} flat candles hatayi`);
  rows.length = 0; rows.push(...real);
  const lines = rows.map(r => r.slice(0, 5).join(','));
  fs.writeFileSync(file, 't,o,h,l,c\n' + lines.join('\n') + '\n');
  const first = new Date(rows[0][0]).toISOString(), last = new Date(rows.at(-1)[0]).toISOString();
  console.log(`${pair} ${SIDE}: ${rows.length} candles  ${first} → ${last}`);
}
