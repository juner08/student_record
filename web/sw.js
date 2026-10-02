/* Service worker for the Student Record PWA.
 *
 * Responsibilities:
 *  - precache the app shell so the app opens with no network
 *  - serve cached assets while revalidating them in the background
 *  - fall back to the cached shell for navigations when offline
 *
 * Bump CACHE_VERSION whenever you want browsers to drop the old cache.
 */

const CACHE_VERSION = 'student-record-v1';

const SHELL = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) =>
      // addAll is atomic: one 404 would reject everything, so add
      // individually and ignore the optional files that may be missing.
      Promise.all(
        SHELL.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch(() => undefined),
        ),
      ),
    ),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((key) => key !== CACHE_VERSION).map((key) => caches.delete(key)),
      ),
    ),
  );
  self.clients.claim();
});

function isSameOrigin(url) {
  return new URL(url, self.location.href).origin === self.location.origin;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;

  if (request.method !== 'GET') {
    return;
  }

  if (!isSameOrigin(request.url)) {
    return;
  }

  // Navigations: prefer the network so a fresh deploy is picked up,
  // then fall back to the cached shell when offline.
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() =>
          caches.match(request).then(
            (cached) =>
              cached ||
              caches.match('./index.html').then((shell) => shell || Response.error()),
          ),
        ),
    );
    return;
  }

  // Everything else: cache first, revalidate in the background.
  event.respondWith(
    caches.match(request).then((cached) => {
      const network = fetch(request)
        .then((response) => {
          if (response && response.status === 200 && response.type === 'basic') {
            const copy = response.clone();
            caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(() => cached || Response.error());

      return cached || network;
    }),
  );
});