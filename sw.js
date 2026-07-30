// SamuSignal Service Worker v2
const CACHE_NAME = 'samusignal-v2';
const ASSETS = [
  './Samusignal.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Space+Grotesk:wght@400;500;600;700&display=swap',
];

// ── Install: cache all assets ──
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS).catch(() => {});
    })
  );
  self.skipWaiting();
});

// ── Activate: clear old caches ──
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// ── Fetch: Cache-first for assets, network-first for API ──
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // API calls — always go network, fall back to nothing (dynamic data)
  if (url.hostname.includes('twelvedata.com') || url.hostname.includes('api.')) {
    event.respondWith(
      fetch(event.request).catch(() => new Response(JSON.stringify({}), {
        headers: { 'Content-Type': 'application/json' }
      }))
    );
    return;
  }

  // Everything else — cache first, then network
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (!response || response.status !== 200 || response.type !== 'basic') return response;
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        return response;
      }).catch(() => caches.match('./Samusignal.html'));
    })
  );
});

// ── Push Notifications ──
self.addEventListener('push', (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.title || '📡 SamuSignal Alert';
  const options = {
    body: data.body || 'New signal available!',
    icon: './icon-192.png',
    badge: './icon-192.png',
    vibrate: [200, 100, 200],
    data: { url: data.url || './Samusignal.html' },
    actions: [
      { action: 'open', title: 'View Signal' },
      { action: 'dismiss', title: 'Dismiss' },
    ],
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

// ── Notification Click ──
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  if (event.action === 'dismiss') return;
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((windowClients) => {
      for (const client of windowClients) {
        if (client.url.includes('Samusignal') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow('./Samusignal.html');
    })
  );
});

// ── Background Sync (for offline trade saves) ──
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-trades') {
    event.waitUntil(Promise.resolve());
  }
});
