'use client'
import { useState, useEffect, useCallback } from 'react'
import { format } from 'date-fns'
import { supabase } from '@/lib/supabase'
import { useAuth } from './AuthProvider'
import type { Trip } from '@/lib/types'

export default function DriverTripList({ refresh }: { refresh: number }) {
  const { user } = useAuth()
  const [trips,   setTrips]   = useState<Trip[]>([])
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    if (!user) return
    setLoading(true)
    const { data } = await supabase
      .from('trips')
      .select('*, vehicles:vehicle_id(name)')
      .eq('driver_id', user.id)
      .order('date', { ascending: false })
      .limit(50)
    setTrips(data ?? [])
    setLoading(false)
  }, [user])

  useEffect(() => { load() }, [load, refresh])

  if (loading) return (
    <div className="flex justify-center py-12">
      <div className="w-6 h-6 border-2 border-gold border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (trips.length === 0) return (
    <div className="text-center py-16 text-slate-500">
      <p className="text-4xl mb-3">🚛</p>
      <p>No trips logged yet.</p>
    </div>
  )

  return (
    <div className="space-y-3">
      {trips.map(t => (
        <div key={t.id} className="card flex items-start gap-4">
          {/* Miles hero */}
          <div className="text-right shrink-0 min-w-[56px]">
            <span className="mono text-2xl font-bold text-gold">{Number(t.miles).toFixed(1)}</span>
            <span className="block text-xs text-slate-500">mi</span>
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xs text-slate-400 mono">
                {format(new Date(t.date), 'MMM d, yyyy')}
              </span>
              <span className="text-xs bg-navy-hover px-2 py-0.5 rounded-full text-slate-300">
                {(t as any).vehicles?.name ?? '—'}
              </span>
            </div>
            <p className="text-sm text-white mt-1 font-medium truncate">{t.purpose}</p>
            {t.job && <p className="text-xs text-slate-400 mt-0.5 truncate">{t.job}</p>}
            <p className="text-xs text-slate-600 mono mt-1">
              {Number(t.start_odometer).toFixed(1)} → {Number(t.end_odometer).toFixed(1)}
            </p>
          </div>
        </div>
      ))}
    </div>
  )
}
