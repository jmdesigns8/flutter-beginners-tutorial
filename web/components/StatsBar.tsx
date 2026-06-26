'use client'
import { useState } from 'react'
import { Check, Pencil } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import type { Trip } from '@/lib/types'

interface Props {
  trips: Trip[]
  rate:  number
  onRateChange: (r: number) => void
}

export default function StatsBar({ trips, rate, onRateChange }: Props) {
  const totalMiles  = trips.reduce((s, t) => s + Number(t.miles), 0)
  const totalTrips  = trips.length
  const deduction   = totalMiles * rate
  const [editing, setEditing] = useState(false)
  const [draft,   setDraft]   = useState(rate.toString())

  async function saveRate() {
    const n = parseFloat(draft)
    if (!isNaN(n) && n > 0) {
      await supabase.from('settings')
        .update({ value: n.toString(), updated_at: new Date().toISOString() })
        .eq('key', 'per_mile_rate')
      onRateChange(n)
    }
    setEditing(false)
  }

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
      <StatCard label="Total Miles"  value={totalMiles.toFixed(1)} mono />
      <StatCard label="Total Trips"  value={totalTrips.toString()} />

      {/* Editable rate */}
      <div className="card">
        <p className="label mb-2">Per-Mile Rate</p>
        {editing ? (
          <div className="flex items-center gap-1">
            <span className="text-slate-400">$</span>
            <input
              type="number" step="0.001" min="0"
              value={draft}
              onChange={e => setDraft(e.target.value)}
              className="w-full px-2 py-1 text-lg mono border border-gold/40 rounded"
              autoFocus
              onKeyDown={e => e.key === 'Enter' && saveRate()}
            />
            <button onClick={saveRate} className="text-green-400 p-1">
              <Check size={16} />
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-2">
            <span className="mono text-2xl font-bold text-gold">
              ${rate.toFixed(3)}
            </span>
            <button
              onClick={() => { setDraft(rate.toString()); setEditing(true) }}
              className="text-slate-500 hover:text-gold transition-colors"
            >
              <Pencil size={13} />
            </button>
          </div>
        )}
      </div>

      <StatCard label="Tax Deduction" value={`$${deduction.toFixed(2)}`} mono highlight />
    </div>
  )
}

function StatCard({
  label, value, mono, highlight,
}: {
  label: string; value: string; mono?: boolean; highlight?: boolean
}) {
  return (
    <div className={`card ${highlight ? 'border-gold/30 bg-gold/5' : ''}`}>
      <p className="label mb-2">{label}</p>
      <p className={`text-2xl font-bold leading-none ${mono ? 'mono' : ''} ${highlight ? 'text-gold' : 'text-white'}`}>
        {value}
      </p>
    </div>
  )
}
