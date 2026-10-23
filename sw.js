/* ============================================================
   SamuSignal — service worker
   v10.6.5 — Report Card: pair aur session (Asia/London/NY, IST) ke hisaab se +TP pehle %
   v10.6.4 — AUTO ANALYZE card pe sirf ⚠ chetavni tag (15m tez chaal / 5m+1m ulte) — order block nahi; Report Card me ⚠ vs bina ⚠ hisaab
   v10.6.3 — v10.6.2 wale 2 NO TRADE niyam hataye (user: v10.6.1 jaisa hi rakho) — Level Engine wahi
   v10.6.2 — AUTO ANALYZE niyam: 15m FLAT + ADX 25+ = trend palat raha (NO TRADE); 5m (ADX 30+) aur 1m dono ulte = NO TRADE. Best Pair pe niyam 1 bhi
   v10.6.1 — Level Engine ka 'khush ho? (din X/5)' box hataya — engine + Settings switch wahi
   v10.6.0 — 📐 Level Engine: AUTO ANALYZE ke order ka bhaav pakke zone pe (swing/EMA/wapsi/round, STOP 15m asli swing + buffer), AI zones me se chunta hai; Report Card MAE/flip se seekhna; 5 din har chart pe 'khush ho?' + purana default switch
   v10.5.16 — Best Pair = AUTO ANALYZE ka hi faisla (extra range shart hata di): sirf trade wale pair dikhte hain (NO TRADE chhupe), trend me LIMIT + STOP, range me BUY + SELL LIMIT
   v10.5.15 — Best Pair: apni alag watchlist chips (Majors / EUR Cross / GBP Cross / AUD-NZD / CAD-CHF), ek group me se best pair
   v10.5.14 — Best Pair: 'IS PAIR PE AUTO ANALYZE' button hara chamak (AUTO ANALYZE jaisa)
   v10.5.13 — Chart Analysis: '🏆 BEST PAIR DHUNDHO' — watchlist (Gold/BTC chhod ke) me se ek best pair + BUY/SELL LIMIT andaza, 'Is pair pe AUTO ANALYZE' button
   v10.5.12 — Chart Analysis: 🧮 faisle ki line (jaise 'Range bahut patli hai — TP tak jagah nahi') green highlight
   v10.5.11 — Chart Analysis: chalti line (candles aa rahi / AI analyze / live price) green highlight + header CHART ANALYSIS button halka hara dim-dim glow
   v10.5.10 — Pair tab: scan status line (API limit / sec ruko) green highlight
   v10.5.9 — Pair tab: '🚀 AUTO TRADE → MT5' — account tick, dono leg MARKET (PERSONAL FX v6.9: dono milake lock +$1→+$0.50, −$10 dono band), MT5 Pair Trades card
   v10.5.8 — PERSONAL FX 2 account: bhejte waqt 2+ account chal rahe ho to tick list (1 ho to seedha usi pe), order me acct (EA v6.8)
   v10.5.7 — Pair: '✓ MAINE TRADE LIYA' — sirf app me, dono legs milake +$1→lock +$0.50 (har $0.10 aage), −$10 SL (0.01 lot pe), live price, notification
   v10.5.6 — Pair Tracker: '✓ BAND KARO' (khud band, result save), upar BAND/JEETE/TP·SL·KHUD/KUL $ box, × pe confirm
   v10.5.5 — Pair Virtual Tracker: apne aap update (H1 15 min / H4 45 min, scan TF kuch bhi), TP/SL Z bar, entry → abhi price, 🔄 button
   v10.5.4 — Chart Analysis order card pe '✓ Maine trade liya' — journal me TP $3 + SL $10 (0.01 lot), pending 60 min, 2 order = joda (OCO)
   v10.5.3 — Screenshot ke neeche wali '2 ORDER' patti bhi 5 min baad hat jaati hai
   v10.5.2 — PERSONAL FX ORDER result sirf 5 min dikhta hai (AUTO ANALYZE / screenshot ke baad), phir apne aap hat jaata hai
   v10.4.5 — AUTO ANALYZE button bhi hara chamak, chalte waqt tez blink
   v10.4.4 — Chart Analysis pair box ka chamak / blink ab hara (green)
   v10.4.3 — Chart Analysis pair box hamesha halka gold chamakta hai, AUTO ANALYZE / screenshot analysis ke waqt tez blink
   v10.4.2 — Journal lock: +$1 pe SL +$0.50, phir har 10 cent aage (profit se $0.50 peeche) — FXBridge v3.60 / EA v1.11 / PERSONAL FX v6.0 jaisa; Gold ke alag number (abhi same)
   v10.4.1 — AUTO ANALYZE kam sakht: AI confidence ab "setup quality" (85+ textbook, 70-84 achha, 55-69 average) — pehle "+TP pehle aane ka chance" tha jo $3/$5 me khud hi ~62% hota hai, isliye 70% ki seema kabhi paar nahi hoti thi. Min 65 (naya default), ek order ke liye 10 kam chalega
   v10.4.0 — AUTO ANALYZE ab 4 timeframe (1H · 15m · 5m · 1m): pehle app ka pakka filter (UPTREND / DOWNTREND / RANGE / NO TRADE), phir AI 2 order level (trend: Limit + Stop usi taraf, range: Buy Limit + Sell Limit), app ki jaanch (side, 60 min, TP ke raaste me deewar, chase, confidence), dono ek batch me PERSONAL FX ko (v5.9 jo pehle bhare baaki cancel) · AI Report Card (1m candles se +TP pehle ya averaging)
   v10.3.0 — Agent Report Card (har signal ka BUY+SELL virtual check, aakhri 50 vote, achhe agent ka vote bhaari, kharab ka vote band par tracking chalu) · Imaandaar Backtest (spread/slippage/swap/commission, agli candle pe entry, bina cost vs cost ke saath)
   v10.2.0 — Pre-flight check (MT5 / PERSONAL FX order se pehle: news, aaj ka loss, SL cooldown, din ke orders, currency takraav, R:R) · journal me faisla ki wajah + AI raay · Smart Vote (agents ka live record se weighted, sirf jaankari)
   v10.1.1 — AI zyada-tar Limit/Stop; Market sirf perfect haalat me (NOW + 80%+ + chase nahi), warna entry thoda door
   v10.1.0 — Live Chart ke bagal me 📸 AUTO ANALYZE: live candles se chart image + OHLC → AI → PERSONAL FX card (screenshot ki zaroorat nahi)
   v10.0.1 — Settings: Firebase auth secret 👁 Dikhao / 📋 Copy button
   v10.0.0 — Chart Analysis naye sire se: screenshot → AI ek direction → TwelveData live price → Market/Limit/Stop → sirf PERSONAL FX (Firebase /personalfx/orders), status wapas
   v9.9.54 — Chart Analysis order: SL $10 / TP $10 bhara aata hai; lock: har pura $1 profit ka 75% pakka (+$1→+$0.75, +$2→+$1.50 …)
   v9.9.53 — +$1 profit pe SL +$0.75 pakka (journal + FXBridge v3.58), SL/TP $10 tak; Performance WIN ke neeche TP/manual hataya
   v9.9.52 — Result card: SL/TP ke neeche $ box — $ likho to price khud adjust
   v9.9.51 — Chart Analysis Result me Signal strength meter (0-100%: quality + agents + technical + checks)
   v9.9.50 — App se bhi waqt ki seema (12:30–21:30 IST) hatayi — EA jaisa poora din, sirf news ka niyam
   v9.9.49 — Chart Analysis saaf: live chart, screenshot, Analyze, aur sirf ek result card (Market / Limit / Stop) — SL/TP badal sakte, MT5 + journal, joda OCO; Breakeven hamesha ON
   v9.9.48 — Market page (Market Overview + Against Trade) hataya — kabhi use nahi hua, kholte hi credits lagte the
   v9.9.47 — Range joda: kinare pe entry adjust, sirf-ek-order button; Scan page pe Range/Breakout list
   v9.9.46 — Range joda (Limit) TP saamne wale 76.4% / 23.6% pe
   v9.9.45 — Chart page Analyze: chalte waqt spinner, kab hua wo time
   v9.9.44 — Breakout (Stop) joda range ki shart ke bina (news + niyam wahi)
   v9.9.43 — Range Setup: band button dikhe aur saaf wajah (gayab nahi)
   v9.9.42 — Screenshot Share → SamuSignal (gallery nahi), photo preview
   v9.9.41 — Buyer/Seller pressure wapas Signals page pe
   v9.9.40 — Chart page: screenshot AI → S/R, pivot, Fibonacci levels → Final result (tier A/B/Watch/Range)
   v9.9.39 — Naya "Chart Analysis" page (header button): live chart, Range Setup, technical/EMA/screenshot analysis
   v9.9.38 — ⇅ Range Setup: live chart, setup photo, analysis, Limit/Stop joda (OCO) journal me
   v9.9.37 — A+ setup (jagah, swing SL, ek currency ek trade, London/NY), BE 50%
   v9.9.36 — Pin Bar agent band (vote 49 agents pe)
   v9.9.35 — Journal me profit lock + trailing; MT5 sheet me bhi AUTO mode; MT5 order me pm flag (FXBridgeEA v3.54)
   v9.9.34 — "Maine Ye Trade Liya" me AUTO mode (TREND / NORMAL / RANGE + ATR SL/TP, EA v1.05 jaisa)
   v9.9.33 — Max floating card ke neeche ki "rate sirf tab naapa jaata hai" line hatayi
   v9.9.32 — Logo launcher ke shape me na kate (safe zone)
   v9.9.31 — Naya premium SAMU logo + naam SamuSignal (data wahi rehta hai)
   v9.9.30 — Journal ka pending (LIMIT/STOP) 3 ghante me na bhare to auto-cancel
   v9.9.29 — Faisla me LIMIT LAGAO / STOP LAGAO (ATR doori) + MARKET/LIMIT/STOP shadow tracking
   v9.9.28 — "Live Price Lo" button hara blink karta hai jab tak live price na liya ho
   v9.9.27 — Journal me BUY/SELL LIMIT aur STOP (pending, price aane par khulti hai)
   v9.9.26 — Chart fix: tez move ke baad candles upar se kat-ti nahi
   v9.9.25 — EK FAISLA: Total Analysis ke upar TRADE LO / WAIT box, aur Signal History me "Faisla kitna sahi"
   v9.9.24 — Bug fixes: AI/news text escape, din badalne pe budget reset, candle se TP/SL touch, Wilder ADX
   v9.9.21 — Signals: TOTAL ANALYSIS card (sab ka saar)
   v9.9.20 — Auto MT5 hataya (order sirf tap se)
   v9.9.19 — Chart Analysis: poora analysis button ke peeche
   v9.9.18 — Signal umar box peela blink, FRESH hara highlight
   v9.9.17 — Signal umar (kitna purana, kitna chal chuka)
   v9.9.16 — Copy tab: VPS Helper report
   v9.9.15 — Copy tab: Floating Watch
   v9.9.14 — Copy settings auto VPS pe
   v9.9.13 — History se ek trade hatao
   v9.9.12 — Subah ka news brief + news cache
   v9.9.11 — SL/TP hatane ka option
   v9.9.10 — Trade SL/TP edit sheet
   v9.9.9  — EMA plan SL/TP dollar me (Settings wala)
   v9.9.8  — EMA plan se MT5 button
   v9.9.7  — Watchlist 1-5, English button, pair blink, EMA refresh upar
   v9.9.6  — Copy tab: Strategy Recorder
   v9.9.5  — Copy tab: symbol filter
   v9.9.4  — Copy tab: pending orders copy switch
   v9.9.3  — Copy tab: source pending orders
   v9.9.2  — WAIT blink border, sirf Classic design
   v9.9.1  — Telegram fix (no preflight)

   Ek hi jagah badalni hoti hai: neeche wala VERSION.
   Har naye release pe VERSION badlo, commit karo — bas.
   index.html apne aap purane cache saaf kar deta hai kyunki
   wahan CACHE_TAG bhi 'samusignal-v' + VERSION hi banta hai.
   ============================================================ */

const VERSION = '10.6.5';
const CACHE   = 'samusignal-v' + VERSION.replace(/\./g, '-');   /* samusignal-v9-9-2 */

/* App shell — inke bina app offline nahi chalega */
const SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './icon-maskable-512.png',
  './favicon.png',
  './apple-touch-icon.png'
];

/* Ye hosts kabhi cache nahi karne — live data aur API calls hain */
const NO_CACHE = [
  'twelvedata.com',
  'firebaseio.com',
  'agiliumtrade.ai',          /* MetaApi — live orders, kabhi cache nahi */
  'generativelanguage.googleapis.com',
  'api.telegram.org',
  's.tradingview.com',
  'tradingview.com'
];

/* ---------------- install: shell cache karo ---------------- */
self.addEventListener('install', e => {
  e.waitUntil((async () => {
    const c = await caches.open(CACHE);
    /* ek-ek karke — koi file missing ho to poora install fail na ho */
    await Promise.all(SHELL.map(u =>
      c.add(new Request(u, {cache: 'reload'})).catch(() => {})
    ));
    self.skipWaiting();   /* naya SW turant taiyaar */
  })());
});

/* ---------------- activate: purane cache hatao ---------------- */
self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    for(const k of await caches.keys()){
      if(k !== CACHE) await caches.delete(k);
    }
    if(self.registration.navigationPreload){
      try{ await self.registration.navigationPreload.enable() }catch(err){}
    }
    await self.clients.claim();
  })());
});

/* ---------------- fetch ---------------- */
self.addEventListener('fetch', e => {
  const req = e.request;

  /* v9.9.42: phone ka screenshot "Share → SamuSignal" — photo cache me rakho,
     app Chart page pe khud uthakar analysis chalati hai */
  if(req.method === 'POST' && new URL(req.url).pathname.endsWith('/share-target')){
    e.respondWith((async () => {
      try{
        const fd = await req.formData();
        let f = fd.get('image');
        if(!f || typeof f === 'string') f = [...fd.values()].find(v => v && typeof v === 'object' && /^image\//.test(v.type || ''));
        if(f) await (await caches.open(CACHE)).put('./__share__/img', new Response(f, {headers: {'Content-Type': f.type || 'image/png'}}));
      }catch(err){}
      return Response.redirect('./?share=1', 303);
    })());
    return;
  }
  if(req.method !== 'GET') return;

  const url = new URL(req.url);

  /* API / live data — seedha network, cache bilkul nahi */
  if(NO_CACHE.some(h => url.hostname.endsWith(h))) return;

  /* Page khud (navigation) — hamesha pehle network.
     Isse naya index.html turant milta hai, purana cache atakta nahi.
     Net na ho to cache se chalega. */
  if(req.mode === 'navigate'){
    e.respondWith((async () => {
      try{
        const pre = await e.preloadResponse;
        if(pre){
          (await caches.open(CACHE)).put('./index.html', pre.clone()).catch(()=>{});
          return pre;
        }
        const net = await fetch(req, {cache: 'no-store'});
        (await caches.open(CACHE)).put('./index.html', net.clone()).catch(()=>{});
        return net;
      }catch(err){
        const c = await caches.open(CACHE);
        return (await c.match('./index.html')) || (await c.match('./')) ||
               new Response('Offline', {status: 503, headers: {'Content-Type': 'text/plain'}});
      }
    })());
    return;
  }

  /* Baaki apni files (icon, manifest waghairah) — pehle cache, peeche
     chupke se update. Tez bhi, aur agli baar naya bhi. */
  if(url.origin === self.location.origin){
    e.respondWith((async () => {
      const c = await caches.open(CACHE);
      const hit = await c.match(req);
      const net = fetch(req).then(r => {
        if(r && r.ok) c.put(req, r.clone()).catch(()=>{});
        return r;
      }).catch(() => null);
      return hit || (await net) ||
             new Response('', {status: 504});
    })());
  }
});

/* ---------------- app se message: turant update ---------------- */
self.addEventListener('message', e => {
  if(e.data === 'SKIP_WAITING' || (e.data && e.data.type === 'SKIP_WAITING')){
    self.skipWaiting();
  }
});
