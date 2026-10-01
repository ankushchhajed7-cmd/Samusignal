/* ============================================================
   SamuSignal — service worker
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

const VERSION = '9.9.20';
const CACHE   = 'samusignal-v' + VERSION.replace(/\./g, '-');   /* samusignal-v9-9-2 */

/* App shell — inke bina app offline nahi chalega */
const SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './icon-maskable-512.png',
  './favicon.png'
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
