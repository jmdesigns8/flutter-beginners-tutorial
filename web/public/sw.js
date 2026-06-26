const CACHE = 'strive-v1'
const PRECACHE = ['/', '/driver', '/admin']

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(PRECACHE)))
  self.skipWaiting()
})

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  )
  self.clients.claim()
})

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url)
  // Always network for API routes and Supabase
  if (url.pathname.startsWith('/api/') || url.hostname.includes('supabase')) {
    return
  }
  if (e.request.method !== 'GET') return
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  )
})
