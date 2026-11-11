/* ==================================================================
   SAMUSIGNAL AI AUTO — VPS Scanner v1.00   (Ankush New Vision)
   ------------------------------------------------------------------
   KAAM (Task Scheduler se har 1 min chalta hai, har nayi 15m candle par ek scan):
    1. App wala hi engine (GitHub Pages: SAMUSIGNAL-AI/src/*.js) — har 6 ghante taaza.
    2. MT5 Data Feed (Firebase /feed) se saare pair ki 15m + 1H candles.
    3. XAUUSD / BTCUSD chhod kar har pair ka analysis; achhe (Grade A/B + 15m/1H saath)
       me se top 5 par Gemini AI check (app jaisa).
    4. AI सहमत (bharosa >= minConf) -> Firebase /samuai/auto/sig/<id>
       -> "SAMUSIGNAL AI AUTO" EA (MT5) LIMIT order lagata hai.
   EA ki halat (/samuai/auto/state) padhta hai: jis pair pe EA ka trade / news / din band —
   us par AI nahi poochta (Gemini limit bachao). EA 10 min se chup ho to AI check nahi.
   Keys sirf is VPS ki config.json me (GitHub me kabhi nahi).
   Chalao:  node scanner.mjs          (Task Scheduler)
            node scanner.mjs --test   (abhi ek scan, Firebase me signal NAHI likhta, sab dikhata hai)
   ================================================================== */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

const VER = '1.00';
const DIR = path.dirname(fileURLToPath(import.meta.url));
const TEST = process.argv.includes('--test');
const PAGES = 'https://ankushchhajed7-cmd.github.io/SAMUSIGNAL-AI/src/';
const SELF_RAW = 'https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-scanner/scanner.mjs';
const ENG_FILES = ['symbols.js', 'data.js', 'engine.js', 'ai.js'];
const ENG_DIR = path.join(DIR, 'engine');
const STATE_F = path.join(DIR, 'state.json');
const LOG_F = path.join(DIR, 'scanner.log');
const LOCK_F = path.join(DIR, 'scan.lock');
const SLOT = 15 * 60e3;

function log(m){
  const line = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' ' + m;
  console.log(line);
  try{ if(fs.existsSync(LOG_F) && fs.statSync(LOG_F).size > 1e6) fs.renameSync(LOG_F, LOG_F + '.old'); fs.appendFileSync(LOG_F, line + '\n') }catch(e){}
}
const readJson = (f, d) => { try{ return JSON.parse(fs.readFileSync(f, 'utf8')) }catch(e){ return d } };
const wait = ms => new Promise(r => setTimeout(r, ms));

/* ---------- config ---------- */
/* config.json: Notepad me haath se badalne par quote / comma chhoot jaaye to bhi keys nikaal lo (key kabhi log me nahi) */
function readCfg(){
  const f = path.join(DIR, 'config.json');
  let t; try{ t = fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, '') }catch(e){ log('config.json nahi mili (C:\\SamuScanner\\config.json) — install.ps1 dobara chalao'); return null }
  try{ return JSON.parse(t) }catch(e){
    const pos = (String(e.message).match(/position (\d+)/) || [])[1];
    const pick = k => { const m = t.match(new RegExp('["\u201c\u201d]?' + k + '["\u201c\u201d]?\\s*:\\s*["\u201c\u201d]?\\s*([^"\u201c\u201d,\\s}]+)')); return m ? m[1] : '' };
    const o = {gKey: pick('gKey'), fbAuth: pick('fbAuth')}; const u = pick('fbUrl'); if(/^https?:/.test(u)) o.fbUrl = u;
    if(o.gKey){ log('config.json ki banawat thodi galat' + (pos ? ' (jagah ' + pos + ')' : '') + ' — phir bhi keys padh li. Fursat me Notepad me theek kar lena.'); return o }
    log('config.json galat JSON' + (pos ? ' (jagah ' + pos + ')' : '') + ' — Notepad me dekho: har key "..." quotes me, line ke aakhir comma'); return null;
  }
}
const CFG = readCfg();
if(!CFG) process.exit(1);
const C = Object.assign({fbUrl: 'https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app', fbAuth: '', gKey: '', gModel: '',
  minConf: 70, topN: 5, aiPerDay: 300, exclude: ['XAUUSD', 'BTCUSD']}, CFG);
if(!C.gKey || /YAHAN/.test(C.gKey)){ log('config.json me gKey (Gemini key) daalo'); process.exit(1) }
if(/YAHAN/.test(C.fbAuth)) C.fbAuth = '';

/* ---------- ek saath do scan nahi ---------- */
try{ const l = fs.statSync(LOCK_F); if(Date.now() - l.mtimeMs < 10 * 60e3) process.exit(0) }catch(e){}
fs.writeFileSync(LOCK_F, String(process.pid));
const unlock = () => { try{ fs.unlinkSync(LOCK_F) }catch(e){} };

const ST = readJson(STATE_F, {});
ST.seen = ST.seen || {}; ST.ai = ST.ai || {}; ST.ls = ST.ls || {}; ST.aiDay = ST.aiDay || {d: '', n: 0};
const saveState = () => { try{ fs.writeFileSync(STATE_F, JSON.stringify(ST)) }catch(e){ log('state.json likh nahi paaye: ' + e.message) } };

/* app ka engine localStorage maangta hai (Gemini band-model yaad) — file me rakho */
globalThis.localStorage = {
  getItem: k => (k in ST.ls ? ST.ls[k] : null), setItem: (k, v) => { ST.ls[k] = String(v) }, removeItem: k => { delete ST.ls[k] },
  get length(){ return Object.keys(ST.ls).length }, key: i => Object.keys(ST.ls)[i] ?? null
};

async function getText(u){ const r = await fetch(u + (u.includes('?') ? '&' : '?') + 'v=' + Date.now(), {cache: 'no-store'}); if(!r.ok) throw new Error('HTTP ' + r.status); return r.text() }

/* ---------- engine + khud ka update (har 6 ghante) ---------- */
async function refreshCode(){
  const old = ENG_FILES.every(f => fs.existsSync(path.join(ENG_DIR, f)));
  if(old && Date.now() - (ST.engAt || 0) < 6 * 3600e3) return;
  fs.mkdirSync(ENG_DIR, {recursive: true});
  try{
    const got = {};
    for(const f of ENG_FILES){ const t = await getText(PAGES + f); if(!/export /.test(t)) throw new Error(f + ' galat'); got[f] = t }
    for(const f of ENG_FILES) fs.writeFileSync(path.join(ENG_DIR, f), got[f]);
    ST.engAt = Date.now(); log('engine taaza kiya (GitHub Pages)');
  }catch(e){ if(!old) throw new Error('engine download nahi hua: ' + e.message); log('engine update fail (purana chalega): ' + e.message) }
  try{
    const t = await getText(SELF_RAW), me = fs.readFileSync(fileURLToPath(import.meta.url), 'utf8');
    if(/SAMUSIGNAL AI AUTO — VPS Scanner/.test(t) && t !== me){ fs.writeFileSync(fileURLToPath(import.meta.url), t); log('scanner ka naya version utara (agli baar se)') }
  }catch(e){}
}

async function main(){
  const now = Date.now(), slot = Math.floor(now / SLOT);
  if(!TEST){
    if(ST.slot === slot) return;                         // is candle ka scan ho chuka
    if(now - slot * SLOT < 25000) return;                // candle band hone ke 25 sec baad (feed bars aa jaayein)
  }
  ST.slot = slot;
  await refreshCode();
  const imp = f => import(pathToFileURL(path.join(ENG_DIR, f)).href + '?t=' + (ST.engAt || 0));
  const S = await imp('symbols.js'), D = await imp('data.js'), E = await imp('engine.js'), A = await imp('ai.js');
  const s = {fbUrl: C.fbUrl, fbAuth: C.fbAuth, gKey: C.gKey, gModel: C.gModel};
  const fbGet = async p => { const r = await fetch(D.fbUrl(s, p), {cache: 'no-store'}); if(!r.ok) throw new Error('Firebase GET ' + p + ' HTTP ' + r.status); return r.json() };
  const fbPut = async (p, v) => { const r = await fetch(D.fbUrl(s, p), {method: 'PUT', body: JSON.stringify(v), headers: {'Content-Type': 'application/json'}}); if(!r.ok) throw new Error('Firebase PUT ' + p + ' HTTP ' + r.status) };
  const status = async o => { o = Object.assign({t: Math.floor(Date.now() / 1000), v: VER}, o); if(TEST) console.log('STATUS', JSON.stringify(o)); else await fbPut('samuai/auto/scan', o).catch(e => log(e.message)) };

  const fsx = await D.feedStatus(s, true);
  if(!fsx.ok){ await status({ok: false, why: 'MT5 Data Feed band: ' + (fsx.why || '')}); log('feed band: ' + fsx.why); return }

  const ea = await fbGet('samuai/auto/state').catch(() => null);
  const eaAge = ea && ea.t ? Math.round((Date.now() / 1000 - ea.t) / 60) : 9999;
  if(eaAge > 10 && !TEST){ await status({ok: false, why: `EA ${eaAge >= 9999 ? 'ka data nahi' : eaAge + ' min se chup'} — AI check nahi kiya`}); log('EA chup (' + eaAge + ' min) — scan chhoda'); return }
  if(ea && ea.stop && !TEST){ await status({ok: true, why: 'EA: aaj band (' + (ea.why || '') + ')'}); log('EA aaj band: ' + (ea.why || '')); return }
  const busy = new Set([...Object.values((ea && ea.busy) || {}), ...Object.values((ea && ea.news) || {})].map(x => String(x).toUpperCase()));
  const excl = new Set(C.exclude.map(x => String(x).toUpperCase()));

  const [A15, B1h] = await Promise.all([D.feedAllBars(s, '15min'), D.feedAllBars(s, '1h')]);
  const rows = [];
  for(const sym of S.PAIRS){
    const n = S.SPECS[sym].n; if(excl.has(n)) continue;
    const x = A15[n], y = B1h[n];
    if(!x || !y || x.bars.length < 60 || y.bars.length < 60) continue;
    let sig; try{ sig = E.analyze({b15: x.bars, b1h: y.bars, live: x.live, spec: S.SPECS[sym]}) }catch(e){ continue }
    const Dd = sig.dir === 'BUY' ? 1 : -1, al = Math.sign(sig.t15) === Dd && Math.sign(sig.t1h) === Dd;
    const far = Math.abs(sig.live - sig.entry) / (sig.atr || 1);
    const why = busy.has(n) ? 'EA: trade / news' : sig.grade === 'C' ? 'Grade C' : !al ? '15m/1H saath nahi' : '';
    const score = (sig.grade === 'A' ? 3 : sig.grade === 'B' ? 2 : 0) + (al ? 2 : 0) + Math.min(3, Math.abs(sig.t15) + Math.abs(sig.t1h)) / 2 - Math.min(2, far) / 2 + (sig.smart && sig.smart.type !== 'LIMIT' ? 0.5 : 0);
    rows.push({sym, n, sig, b15: x.bars, cand: !why, why, score, ai: null});
  }
  rows.sort((p, q) => (q.cand - p.cand) || (q.score - p.score));
  const top = rows.filter(r => r.cand).slice(0, C.topN);

  /* Gemini — 60 min ka cache, roz ki seema */
  const today = new Date().toISOString().slice(0, 10);
  if(ST.aiDay.d !== today) ST.aiDay = {d: today, n: 0};
  Object.keys(ST.ai).forEach(k => { if(Date.now() - ST.ai[k].t > 3600e3) delete ST.ai[k] });
  let aiNote = '';
  for(let i = 0; i < top.length; i++){
    const r = top[i], k = r.n + '|' + r.sig.dir + '|' + r.sig.entry;
    if(ST.ai[k]){ r.ai = ST.ai[k].ai; continue }
    if(ST.aiDay.n >= C.aiPerDay){ aiNote = 'aaj ki AI seema (' + C.aiPerDay + ') poori'; break }
    try{ ST.aiDay.n++; r.ai = await A.aiCheck(s, r.sym, r.sig, r.b15); ST.ai[k] = {t: Date.now(), ai: r.ai} }
    catch(e){ r.ai = {err: String(e.message || e).slice(0, 80)}; log('AI ' + r.n + ': ' + r.ai.err) }
    if(i < top.length - 1) await wait(4000);
  }

  /* AI सहमत -> EA ke liye signal */
  Object.keys(ST.seen).forEach(k => { if(Date.now() - ST.seen[k] > 2 * 864e5) delete ST.seen[k] });
  const sent = [];
  for(const r of top){
    if(!r.ai || !r.ai.agree || (r.ai.conf || 0) < C.minConf) continue;
    const k = r.n + '|' + r.sig.dir + '|' + r.sig.entry;
    if(ST.seen[k]) continue;
    const t = Date.now(), id = 'a' + t.toString(36) + sent.length;
    const o = {id, sym: r.n, dir: r.sig.dir, entry: r.sig.entry, sl: r.sig.sl, grade: r.sig.grade, conf: r.ai.conf,
      why: String(r.ai.reason || '').slice(0, 120), live: r.sig.live, at: Math.floor(t / 1000), exp: Math.floor(t / 1000) + 3600, v: VER};
    if(TEST) console.log('SIGNAL (test — likha NAHI)', JSON.stringify(o));
    else{ try{ await fbPut('samuai/auto/sig/' + id, o); ST.seen[k] = t; sent.push(r.n + ' ' + r.sig.dir) }catch(e){ log(e.message) } }
  }

  /* purane signal saaf (2 din) */
  if(!TEST && slot % 8 === 0) try{
    const u = D.fbUrl(s, 'samuai/auto/sig'); const r = await fetch(u + (u.includes('?') ? '&' : '?') + 'shallow=true'); const j = r.ok ? await r.json() : null;
    for(const id of Object.keys(j || {})){ const t = parseInt(id.slice(1, 9), 36); if(t && Date.now() - t > 2 * 864e5) await fetch(D.fbUrl(s, 'samuai/auto/sig/' + id), {method: 'DELETE'}) }
  }catch(e){}

  const agree = top.filter(r => r.ai && r.ai.agree).length;
  await status({ok: true, pairs: rows.length, cand: rows.filter(r => r.cand).length, ai: top.length, agree, sent: sent.length, aiToday: ST.aiDay.n, why: aiNote,
    top: top.map(r => ({n: r.n, dir: r.sig.dir, g: r.sig.grade, a: r.ai ? (r.ai.err ? 'err' : (r.ai.agree ? 'Y' : 'N') + (r.ai.conf || 0)) : '-'}))});
  log(`scan: ${rows.length} pair · ${rows.filter(r => r.cand).length} achhe · AI ${top.length} · sahmat ${agree} · EA ko ${sent.length}${sent.length ? ' (' + sent.join(', ') + ')' : ''}${aiNote ? ' · ' + aiNote : ''}`);
  if(TEST) top.forEach(r => console.log(`  ${r.n} ${r.sig.dir} ${r.sig.grade} entry ${r.sig.entry} live ${r.sig.live} AI ${r.ai ? JSON.stringify(r.ai) : '-'}`));
}

main().catch(e => log('GALTI: ' + (e && e.stack || e))).finally(() => { saveState(); unlock() });
