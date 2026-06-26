'use client'
import { useState, useEffect } from 'react'
import { CheckCircle } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { useAuth } from './AuthProvider'
import type { Vehicle } from '@/lib/types'

function today() {
  return new Date().toISOString().split('T')[0]
}

export default function TripForm({ onSaved }: { onSaved?: () => void }) {
  const { user } = useAuth()
  const [vehicles,  setVehicles]  = useState<Vehicle[]>([])
  const [date,      setDate]      = useState(today)
  const [vehicleId, setVehicleId] = useState('')
  const [startOdo,  setStartOdo]  = useState('')
  const [endOdo,    setEndOdo]    = useState('')
  const [purpose,   setPurpose]   = useState('')
  const [job,       setJob]       = useState('')
  const [saving,    setSaving]    = useState(false)
  const [success,   setSuccess]   = useState(false)
  const [error,     setError]     = useState('')

  const miles = (() => {
    const s = parseFloat(startOdo), e = parseFloat(endOdo)
    return !isNaN(s) && !isNaN(e) && e > s ? e - s : 0
  })()

  useEffect(() => {
    supabase
      .from('vehicles')
      .select('*')
      .eq('active', true)
      .order('name')
      .then(({ data }) => {
        if (data) {
          setVehicles(data)
          if (data.length > 0) setVehicleId(data[0].id)
        }
      })
  }, [])

  function reset() {
    setDate(today())
    setStartOdo(''); setEndOdo(''); setPurpose(''); setJob('')
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    if (!user) return
    const s = parseFloat(startOdo), en = parseFloat(endOdo)
    if (isNaN(s) || isNaN(en) || en <= s) {
      setError('End odometer must be greater than start.'); return
    }
    setSaving(true); setError('')
    const { error: dbErr } = await supabase.from('trips').insert({
      driver_id:      user.id,
      vehicle_id:     vehicleId,
      date,
      start_odometer: s,
      end_odometer:   en,
      purpose:        purpose.trim(),
      job:            job.trim() || null,
    })
    setSaving(false)
    if (dbErr) { setError(dbErr.message); return }
    setSuccess(true)
    reset()
    onSaved?.()
    setTimeout(() => setSuccess(false), 3000)
  }

  return (
    <form onSubmit={save} className="space-y-5">
      {/* Success banner */}
      {success && (
        <div className="flex items-center gap-2 bg-green-900/30 border border-green-500/40
                        text-green-400 rounded-lg px-4 py-3 text-sm">
          <CheckCircle size={16} /> Trip saved!
        </div>
      )}

      {/* Date + Vehicle row */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label block mb-1.5">Date</label>
          <input type="date" value={date} onChange={e => setDate(e.target.value)}
            className="w-full px-3 py-2.5 text-sm" required />
        </div>
        <div>
          <label className="label block mb-1.5">Vehicle</label>
          <select value={vehicleId} onChange={e => setVehicleId(e.target.value)}
            className="w-full px-3 py-2.5 text-sm" required>
            {vehicles.map(v => (
              <option key={v.id} value={v.id}>{v.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Odometer row */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label block mb-1.5">Start Odometer</label>
          <input
            type="number" inputMode="decimal" min="0" step="0.1"
            placeholder="45231.0"
            value={startOdo} onChange={e => setStartOdo(e.target.value)}
            className="w-full px-3 py-2.5 mono text-sm" required
          />
        </div>
        <div>
          <label className="label block mb-1.5">End Odometer</label>
          <input
            type="number" inputMode="decimal" min="0" step="0.1"
            placeholder="45312.0"
            value={endOdo} onChange={e => setEndOdo(e.target.value)}
            className="w-full px-3 py-2.5 mono text-sm" required
          />
        </div>
      </div>

      {/* Miles hero */}
      <div className="card text-center py-6 bg-gold/5 border-gold/20">
        <p className="label mb-2">Miles This Trip</p>
        <p className={`mono text-6xl font-bold leading-none transition-colors ${
          miles > 0 ? 'text-gold' : 'text-slate-600'
        }`}>
          {miles > 0 ? miles.toFixed(1) : '—'}
        </p>
      </div>

      {/* Purpose */}
      <div>
        <label className="label block mb-1.5">Business Purpose <span className="text-red-400">*</span></label>
        <input
          type="text"
          placeholder="Client visit, supply run, job site inspection…"
          value={purpose} onChange={e => setPurpose(e.target.value)}
          className="w-full px-3 py-2.5 text-sm" required
        />
      </div>

      {/* Job / client */}
      <div>
        <label className="label block mb-1.5">Job / Client <span className="text-slate-600">(optional)</span></label>
        <input
          type="text"
          placeholder="ABC Renovation, 123 Main St…"
          value={job} onChange={e => setJob(e.target.value)}
          className="w-full px-3 py-2.5 text-sm"
        />
      </div>

      {error && (
        <p className="text-red-400 text-sm bg-red-900/20 border border-red-500/30 rounded-lg px-3 py-2">
          {error}
        </p>
      )}

      <button type="submit" disabled={saving} className="btn-gold w-full py-4 text-base">
        {saving ? 'Saving…' : 'Save Trip'}
      </button>
    </form>
  )
}
