'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/components/AuthProvider'

export default function LoginPage() {
  const { user, profile, loading } = useAuth()
  const router = useRouter()
  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [error,    setError]    = useState('')
  const [busy,     setBusy]     = useState(false)

  // Redirect once we know who the user is
  useEffect(() => {
    if (!loading && user && profile) {
      router.replace(profile.role === 'admin' ? '/admin' : '/driver')
    }
  }, [loading, user, profile, router])

  async function signIn(e: React.FormEvent) {
    e.preventDefault()
    setBusy(true); setError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) { setError(error.message); setBusy(false) }
    // on success AuthProvider fires, useEffect above redirects
  }

  if (loading) return <Spinner />

  return (
    <div className="min-h-dvh flex flex-col items-center justify-center px-6 py-12">
      {/* Logo */}
      <div className="mb-10 text-center">
        <div className="text-5xl font-black tracking-tight text-gold">STRIVE</div>
        <div className="mt-1 text-slate-400 text-sm tracking-widest uppercase">Mileage Tracker</div>
      </div>

      {/* Card */}
      <form onSubmit={signIn} className="card w-full max-w-sm space-y-5">
        <div>
          <label className="label block mb-1.5">Email</label>
          <input
            type="email" required autoComplete="email"
            value={email} onChange={e => setEmail(e.target.value)}
            className="w-full px-4 py-3 text-sm"
            placeholder="you@example.com"
          />
        </div>
        <div>
          <label className="label block mb-1.5">Password</label>
          <input
            type="password" required autoComplete="current-password"
            value={password} onChange={e => setPassword(e.target.value)}
            className="w-full px-4 py-3 text-sm"
            placeholder="••••••••"
          />
        </div>

        {error && (
          <p className="text-red-400 text-sm bg-red-900/20 border border-red-500/30 rounded-lg px-3 py-2">
            {error}
          </p>
        )}

        <button type="submit" disabled={busy} className="btn-gold w-full py-3.5">
          {busy ? 'Signing in…' : 'Sign In'}
        </button>
      </form>

      <p className="mt-8 text-xs text-slate-600 text-center">
        Contact your administrator to get access.
      </p>
    </div>
  )
}

function Spinner() {
  return (
    <div className="min-h-dvh flex items-center justify-center">
      <div className="w-8 h-8 border-2 border-gold border-t-transparent rounded-full animate-spin" />
    </div>
  )
}
