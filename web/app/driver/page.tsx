'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Nav from '@/components/Nav'
import TripForm from '@/components/TripForm'
import DriverTripList from '@/components/DriverTripList'
import { useAuth } from '@/components/AuthProvider'

type Tab = 'log' | 'history'

export default function DriverPage() {
  const { profile, loading } = useAuth()
  const router  = useRouter()
  const [tab,     setTab]     = useState<Tab>('log')
  const [refresh, setRefresh] = useState(0)

  useEffect(() => {
    if (!loading && !profile) router.replace('/')
    if (!loading && profile?.role === 'admin') router.replace('/admin')
  }, [loading, profile, router])

  if (loading || !profile) return <Spinner />

  return (
    <div className="min-h-dvh flex flex-col">
      <Nav />
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-6">
        {/* Tab switcher */}
        <div className="flex rounded-xl bg-navy-card border border-navy-border p-1 mb-6">
          {(['log', 'history'] as Tab[]).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex-1 py-2 text-sm font-medium rounded-lg transition-colors ${
                tab === t
                  ? 'bg-gold text-navy'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {t === 'log' ? 'Log Trip' : 'My Trips'}
            </button>
          ))}
        </div>

        {tab === 'log' ? (
          <TripForm onSaved={() => setRefresh(r => r + 1)} />
        ) : (
          <DriverTripList refresh={refresh} />
        )}
      </main>
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
