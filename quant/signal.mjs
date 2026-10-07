/* SamuQuant LIVE signal → Telegram
   GitHub Actions (.github/workflows/quant-signal.yml) London ke waqt har ghante chalata hai.
   Wahi niyam jo backtest me (quant/strategy.mjs). Din me har pair pe max ek signal.
   Secrets: TD_KEY (TwelveData), TG_TOKEN, TG_CHAT — wahi jo Auto Signal bot ke.
   Local test: QUANT_DRY=1 (Telegram nahi bhejta, sirf print) */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PAIRS, DEFAULTS, todaysSignal, hourOf } from './strategy.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const KEY = (process.env.TD_KEY || '').trim();
const TOK = (process.env.TG_TOKEN || '').replace(/\s+/g, '').replace(/^bot(?=\d)/i, '');
const CHAT = (process.env.TG_CHAT || '').trim();
const DRY = process.env.QUANT_DRY === '1';
const FORCE = process.env.BOT_FORCE === '1';
const STATE = process.env.QUANT_STATE || path.join(ROOT, 'bot-state/quant.json');
const TD_API = process.env.TD_API || 'https://api.twelvedata.com';
const ACCOUNT = Number(process.env.QUANT_ACCOUNT || 1000);     /* lot ka udaharan: $1000 pe 1% risk */
const HOUR = 3600000;
const log = (...a) => console.log('[quant]', ...a);

async function candles(sym){
  const u = `${TD_API}/time_series?symbol=${encodeURIComponent(sym)}&interval=1h&outputsize=1200&timezone=UTC&order=ASC&apikey=${KEY}`;
  const j = await (await fetch(u)).json();
  if(!j.values) throw new Error(`TwelveData ${sym}: ${j.message || 'data nahi'}`);
  const now = Date.now();
  return j.values
    .map(v => ({t: Date.parse(v.datetime.replace(' ', 'T') + 'Z'), o: +v.open, h: +v.high, l: +v.low, c: +v.close}))
    .sort((a, b) => a.t - b.t)
    .filter(b => b.t + HOUR <= now);                    /* abhi ban rahi candle nahi */
}

async function tg(text){
  if(DRY){ console.log('--- Telegram (dry) ---\n' + text.replace(/<[^>]+>/g, '')); return }
  const r = await fetch(`https://api.telegram.org/bot${TOK}/sendMessage`, {method: 'POST',
    body: new URLSearchParams({chat_id: CHAT, text, parse_mode: 'HTML', disable_web_page_preview: 'true'})});
  const j = await r.json().catch(() => ({ok: false}));
  if(!j.ok) throw new Error('Telegram: ' + (j.description || 'fail'));
}

const ist = t => new Date(t + 5.5 * HOUR).toISOString().slice(11, 16) + ' IST';

async function main(){
  if(!KEY || (!DRY && (!TOK || !CHAT))){ console.error('❌ Secrets chahiye: TD_KEY, TG_TOKEN, TG_CHAT'); process.exit(1) }
  /* SAFETY LOCK: backtest (quant/results.json) me out-of-sample edge sabit na ho to signal nahi.
     Out-of-sample: 50+ trades, expectancy > 0, randomness test p < 0.05. Sirf testing: QUANT_UNSAFE=1 */
  try{
    const r = JSON.parse(fs.readFileSync(path.join(ROOT, 'quant/results.json'), 'utf8'));
    const o = r.summary['Dono (EURUSD + XAUUSD)'].oos, p = r.randomTest.oos.p;
    if(!(o.n >= 50 && o.exp > 0 && p < 0.05) && process.env.QUANT_UNSAFE !== '1'){
      log(`🔒 Band: backtest me edge sabit nahi (OOS ${o.n} trades, ${o.exp.toFixed(3)}R/trade, p=${p.toFixed(3)}). Paise ke signal nahi bhejunga.`);
      return;
    }
  }catch(e){ log('🔒 Band: quant/results.json nahi mila — pehle backtest chalao'); return }

  let st = {};
  try{ st = JSON.parse(fs.readFileSync(STATE, 'utf8')) }catch(e){}
  st.sent ||= {};
  for(const k in st.sent) if(Date.now() - st.sent[k] > 3 * 86400000) delete st.sent[k];

  for(const [pair, cfg] of Object.entries(PAIRS)){
    let bars;
    try{ bars = await candles(cfg.td) }catch(e){ log(e.message); continue }
    const last = bars.at(-1);
    const s = todaysSignal(bars, DEFAULTS);
    if(!s){ log(`${pair}: aaj koi setup nahi (aakhri candle ${new Date(last.t).toISOString().slice(0, 16)})`); continue }
    const key = `${pair}:${new Date(bars[s.i].t).toISOString().slice(0, 10)}`;
    if(st.sent[key]){ log(`${pair}: aaj ka signal pehle bhej chuke`); continue }
    /* signal wali candle taaza ho (max 2 ghante purani) — der se bheja signal kaam ka nahi */
    if(bars.length - 1 - s.i > 1 && !FORCE){ log(`${pair}: signal purana (${ist(bars[s.i].t)}) — nahi bheja`); st.sent[key] = Date.now(); continue }
    if(hourOf(Date.now()) >= DEFAULTS.exitHour){ log(`${pair}: exit ka waqt nikal gaya`); continue }

    const d = cfg.digits, entry = last.c, risk = s.dir * (entry - s.sl);
    if(!(risk > 0) || risk > DEFAULTS.maxRiskAtr * s.atr){ log(`${pair}: bhav SL ke paar/risk bada — skip`); st.sent[key] = Date.now(); continue }
    const tp = entry + s.dir * DEFAULTS.rr * risk;
    const usdPerLot = risk * cfg.lotValue;                        /* 1 lot pe SL lage to $ (USD quote pairs) */
    const lotRaw = Math.floor(ACCOUNT * 0.01 / usdPerLot * 100) / 100;
    const lotTxt = lotRaw >= 0.01 ? `${lotRaw} lot`
      : `0.01 lot bhi ${(usdPerLot / 100 / ACCOUNT * 100).toFixed(1)}% risk hai — account chhota, trade chhod sakte ho`;
    const side = s.dir > 0 ? '🟢 BUY' : '🔴 SELL';
    const msg = [
      `<b>SamuQuant ${side} ${pair}</b>`,
      `Entry (abhi ka bhav): <b>${entry.toFixed(d)}</b>`,
      `SL: <b>${s.sl.toFixed(d)}</b>  (${(risk / cfg.pip).toFixed(1)} pips)`,
      `TP: <b>${tp.toFixed(d)}</b>  (RR 1:${DEFAULTS.rr})`,
      `Band karo: 01:30 IST tak SL/TP na lage to`,
      ``,
      `Trend t-score: ${s.t.toFixed(2)} · Asia range ${s.aL.toFixed(d)}–${s.aH.toFixed(d)}`,
      `Risk: 0.01 lot pe SL = $${(usdPerLot / 100).toFixed(2)} · $${ACCOUNT} account pe 1% = ${lotTxt}`,
      `Candle band: ${ist(bars[s.i].t + HOUR)}`,
      ``,
      `<i>Ye 100% nahi hai — backtest win rate ~40% hai, profit RR se aata hai. Har trade pe SL zaroor lagao, 1% se zyada risk nahi.</i>`
    ].join('\n');
    await tg(msg);
    st.sent[key] = Date.now();
    log(`${pair}: ${side} bheja`);
  }
  fs.mkdirSync(path.dirname(STATE), {recursive: true});
  fs.writeFileSync(STATE, JSON.stringify(st, null, 1));
}
main().catch(e => { console.error(e); process.exit(1) });
