/* SamuSignal AUTO ALERT robot
   ------------------------------------------------------------------
   GitHub Actions har 30 min me ise chalata hai (.github/workflows/auto-signal.yml).
   Ye asli index.html ko ek chhupe browser me kholta hai — wahi Scan, wahi
   Analyze, wahi FAISLA (finalCall) — aur TRADE LO / LIMIT LAGAO / STOP LAGAO
   aaye to Telegram pe message bhejta hai. Phone/app band ho tab bhi.

   Secrets (GitHub → Settings → Secrets and variables → Actions):
     TD_KEY   — TwelveData API key (robot ke liye alag free key behtar)
     TG_TOKEN — Telegram bot token
     TG_CHAT  — Telegram chat ID
   Settings: bot/config.json
   Yaad (kya bheja, aaj kitne credits): bot-state/state.json (Actions cache me)

   Credits: pehle sasta scan (har pair 2), phir sirf achhe pairs ka poora
   Analyze (har pair ~4–5). Din ki seema config.maxCreditsPerDay. */

import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const cfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'bot/config.json'), 'utf8'));
const KEY = (process.env.TD_KEY || '').trim();
const TOK = (process.env.TG_TOKEN || '').replace(/\s+/g, '').replace(/^bot(?=\d)/i, '');
const CHAT = (process.env.TG_CHAT || '').trim();
const FORCE = process.env.BOT_FORCE === '1';           /* "Run workflow" se haath se chalaya */
const STATE_FILE = process.env.BOT_STATE || path.join(ROOT, 'bot-state/state.json');
const APP_URL = process.env.APP_URL || pathToFileURL(path.join(ROOT, 'index.html')).href;
const TG_API = process.env.TG_API || 'https://api.telegram.org';
/* sirf local test ke liye: TD_MOCK=module.mjs jo (url) => TwelveData JSON de */
const MOCK = process.env.TD_MOCK ? (await import(pathToFileURL(path.resolve(process.env.TD_MOCK)).href)).default : null;

const log = (...a) => console.log('[robot]', ...a);
const utcDay = () => new Date().toISOString().slice(0, 10);
function istNow(){
  const d = new Date(Date.now() + 5.5 * 3600000);        /* IST = UTC + 5:30 */
  return {day: d.getUTCDay(), h: d.getUTCHours() + d.getUTCMinutes() / 60,
          txt: d.toISOString().slice(11, 16) + ' IST'};
}

function loadState(){
  try{ return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')) }catch(e){ return {} }
}
function saveState(st){
  fs.mkdirSync(path.dirname(STATE_FILE), {recursive: true});
  fs.writeFileSync(STATE_FILE, JSON.stringify(st, null, 1));
}

async function tg(text){
  const send = async (body) => {
    const r = await fetch(`${TG_API}/bot${TOK}/sendMessage`, {method: 'POST', body: new URLSearchParams(body)});
    return r.json().catch(() => ({ok: false, description: 'HTTP ' + r.status}));
  };
  let j = await send({chat_id: CHAT, text, parse_mode: 'HTML', disable_web_page_preview: 'true'});
  if(!j.ok && /parse|entit/i.test(j.description || '')){         /* HTML toota — saada text bhejo */
    j = await send({chat_id: CHAT, text: text.replace(/<[^>]+>/g, ''), disable_web_page_preview: 'true'});
  }
  if(!j.ok) throw new Error('Telegram: ' + (j.description || 'fail'));
}

async function main(){
  if(!KEY || !TOK || !CHAT){
    console.error('❌ Secrets missing: TD_KEY, TG_TOKEN aur TG_CHAT teeno GitHub Secrets me daalo.');
    process.exit(1);
  }
  const now = istNow();
  const [h0, h1] = cfg.hoursIST || [0, 24];
  if(!FORCE && (now.day === 0 || now.day === 6 || now.h < h0 || now.h >= h1)){
    log(`Abhi ${now.txt} — chalne ka waqt nahi (${h0}:00–${h1}:00 IST, Som–Shukra). Band.`);
    return;
  }

  const st = loadState();
  if(st.day !== utcDay()){ st.day = utcDay(); st.credits = 0 }
  st.sent = st.sent || {};
  const dedupMs = (cfg.dedupHours || 4) * 3600000;
  for(const k in st.sent) if(Date.now() - st.sent[k] > 24 * 3600000) delete st.sent[k];

  const pairs = cfg.pairs || [];
  const budget = cfg.maxCreditsPerDay || 650;
  if(st.credits + pairs.length * 2 > budget){
    log(`Aaj ke credits (${st.credits}/${budget}) khatam — kal UTC din badalne par phir.`);
    saveState(st);
    return;
  }

  const browser = await chromium.launch();
  const ctx = await browser.newContext({viewport: {width: 420, height: 900}, timezoneId: 'Asia/Kolkata'});   /* report ka waqt IST me */
  const page = await ctx.newPage();
  page.on('dialog', d => d.dismiss());
  page.on('pageerror', e => log('page error:', e.message));

  /* sirf candles chahiye — quote/price (ticker) band, taaki credits na jaayein */
  let used = 0, limitHit = false;
  await page.route(/api\.twelvedata\.com/, route => {
    const u = route.request().url();
    if(/\/time_series/.test(u)){
      used++;
      return MOCK ? route.fulfill({contentType: 'application/json', body: JSON.stringify(MOCK(u))}) : route.continue();
    }
    return route.abort();
  });
  page.on('response', async r => {
    if(!/api\.twelvedata\.com\/time_series/.test(r.url())) return;
    try{ const j = await r.json(); if(j && (j.code === 429 || /credits/i.test(j.message || ''))) limitHit = true }catch(e){}
  });

  /* app ki settings — bilkul naya profile, robot ke hisaab se */
  const ls = {
    key: KEY, tf: cfg.tf || '15min', htf: true, watch: pairs, scanDeep: false,
    tgTok: TOK, tgId: CHAT, tgAuto: false, notif: false, tts: false,
    gAuto: false, cloud: false, newsOn: true, cap: 800, autoM: 0
  };
  for(const k of ['dTp', 'dSl', 'dLot']) if(cfg[k] !== undefined) ls[k] = cfg[k];
  await page.addInitScript(o => {
    try{ for(const k in o) localStorage.setItem('samu_' + k, JSON.stringify(o[k])) }catch(e){}
  }, ls);

  await page.goto(APP_URL);
  await page.waitForFunction(() => typeof runScan === 'function' && typeof finalCall === 'function');
  await page.waitForTimeout(6000);                    /* news (ForexFactory) aa jaaye */

  /* 1) sasta scan */
  await page.evaluate(() => runScan());
  const rows = await page.evaluate(() => (S.scan && S.scan.rows) || []);
  const cands = rows.filter(r => r.score >= (cfg.minScanScore || 60)).slice(0, cfg.maxDeep || 3);
  log(`Scan: ${rows.length} pairs me direction, ${cands.length} achhe — ${cands.map(r => `${r.sym} ${r.dir} ${r.score}`).join(', ') || 'koi nahi'}`);

  /* 2) achhe pairs ka poora Analyze + FAISLA */
  const results = [];
  for(const c of cands){
    if(limitHit || st.credits + used + 5 > budget) break;
    const r = await page.evaluate(async sym => {
      S.pair = sym;
      await runAnalyze();
      const s = lastSignal;
      if(!s || s.sym !== sym) return null;
      const f = finalCall(s);
      return {sym, dir: s.dir, t: f.t, go: f.go, type: f.ord ? f.ord.type : null,
              why: f.why, report: fullReport(true)};
    }, c.sym);
    if(!r) continue;
    results.push(r);
    log(`${r.sym} ${r.dir}: ${r.t} — ${r.why}`);
    if(!r.go || !(cfg.notify || []).includes(r.t)) continue;
    const key = `${r.sym}|${r.dir}|${r.type}`;
    if(st.sent[key] && Date.now() - st.sent[key] < dedupMs){ log(`  (${key} pehle hi bheja tha — dobara nahi)`); continue }
    const head = `🔔 <b>AUTO ALERT — ${r.t}</b>\n<i>SamuSignal robot · ${now.txt}</i>\n\n`;
    try{ await tg(head + r.report); st.sent[key] = Date.now(); log('  📲 Telegram bheja') }
    catch(e){ log('  ❌', e.message) }
  }

  st.credits += used;
  saveState(st);
  log(`Is round me ${used} credits · aaj ${st.credits}/${budget}${limitHit ? ' · ⚠ TwelveData limit' : ''}`);

  if(FORCE){                                            /* haath se chalaya — test message */
    const lines = results.map(r => `• ${r.sym} ${r.dir}: ${r.t}`).join('\n') || '• koi pair achha nahi mila';
    await tg(`✅ <b>SamuSignal robot chal raha hai</b>\n${now.txt}\n\nScan: ${rows.length} pairs · gehra analyze: ${results.length}\n${lines}\n\nCredits: ${used} (aaj ${st.credits}/${budget})`)
      .catch(e => log('test message fail:', e.message));
  }
  await browser.close();
}

main().catch(e => { console.error(e); process.exit(1) });
