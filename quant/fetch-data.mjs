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
fs.mkdirSync(DIR, {recursive: true});

for(const [pair, cfg] of Object.entries(PAIRS)){
  const file = path.join(DIR, `${pair}_H1.csv`);
  const rows = await getHistoricalRates({
    instrument: cfg.duka, dates: {from: FROM, to: new Date()},
    timeframe: 'h1', priceType: 'bid', format: 'array', volumes: false, ignoreFlats: true,
    batchSize: 10, pauseBetweenBatchesMs: 500, retryCount: 5, pauseBetweenRetriesMs: 1500,
    retryOnEmpty: true, failAfterRetryCount: true
  });
  const lines = rows.map(r => r.slice(0, 5).join(','));
  fs.writeFileSync(file, 't,o,h,l,c\n' + lines.join('\n') + '\n');
  const first = new Date(rows[0][0]).toISOString(), last = new Date(rows.at(-1)[0]).toISOString();
  console.log(`${pair}: ${rows.length} candles  ${first} → ${last}`);
}
