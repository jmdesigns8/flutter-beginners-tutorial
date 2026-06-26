'use client'
import { format } from 'date-fns'
import { Download } from 'lucide-react'
import type { Trip, Profile, Vehicle } from '@/lib/types'

interface Props {
  trips:    Trip[]
  profiles: Profile[]
  vehicles: Vehicle[]
  driverFilter:  string
  vehicleFilter: string
  dateFrom:      string
  dateTo:        string
  onDriverFilter:  (v: string) => void
  onVehicleFilter: (v: string) => void
  onDateFrom:      (v: string) => void
  onDateTo:        (v: string) => void
}

export default function AdminTripTable({
  trips, profiles, vehicles,
  driverFilter, vehicleFilter, dateFrom, dateTo,
  onDriverFilter, onVehicleFilter, onDateFrom, onDateTo,
}: Props) {

  function exportCSV() {
    const headers = ['Date','Driver','Vehicle','Start Odo','End Odo','Miles','Purpose','Job']
    const rows = trips.map(t => [
      t.date,
      `"${t.profiles?.name || t.profiles?.email || ''}"`,
      `"${t.vehicles?.name || ''}"`,
      Number(t.start_odometer).toFixed(1),
      Number(t.end_odometer).toFixed(1),
      Number(t.miles).toFixed(1),
      `"${t.purpose}"`,
      `"${t.job || ''}"`,
    ])
    const csv = [headers, ...rows].map(r => r.join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const a    = document.createElement('a')
    a.href     = URL.createObjectURL(blob)
    a.download = `strive-mileage-${new Date().toISOString().split('T')[0]}.csv`
    a.click()
  }

  function clearFilters() {
    onDriverFilter(''); onVehicleFilter(''); onDateFrom(''); onDateTo('')
  }

  const hasFilter = driverFilter || vehicleFilter || dateFrom || dateTo

  return (
    <div>
      {/* Filter bar */}
      <div className="card mb-4">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <div>
            <label className="label block mb-1">Driver</label>
            <select value={driverFilter} onChange={e => onDriverFilter(e.target.value)}
              className="w-full px-3 py-2 text-sm">
              <option value="">All drivers</option>
              {profiles.map(p => (
                <option key={p.id} value={p.id}>{p.name || p.email}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="label block mb-1">Vehicle</label>
            <select value={vehicleFilter} onChange={e => onVehicleFilter(e.target.value)}
              className="w-full px-3 py-2 text-sm">
              <option value="">All vehicles</option>
              {vehicles.map(v => (
                <option key={v.id} value={v.id}>{v.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="label block mb-1">From</label>
            <input type="date" value={dateFrom} onChange={e => onDateFrom(e.target.value)}
              className="w-full px-3 py-2 text-sm" />
          </div>
          <div>
            <label className="label block mb-1">To</label>
            <input type="date" value={dateTo} onChange={e => onDateTo(e.target.value)}
              className="w-full px-3 py-2 text-sm" />
          </div>
        </div>
        <div className="flex items-center justify-between mt-3">
          <span className="text-sm text-slate-400">
            {trips.length} trip{trips.length !== 1 ? 's' : ''}
          </span>
          <div className="flex gap-2">
            {hasFilter && (
              <button onClick={clearFilters} className="btn-ghost text-sm py-1.5 px-3">
                Clear
              </button>
            )}
            <button onClick={exportCSV} className="btn-ghost text-sm py-1.5 px-3 flex items-center gap-1.5">
              <Download size={14} /> Export CSV
            </button>
          </div>
        </div>
      </div>

      {/* Table */}
      {trips.length === 0 ? (
        <div className="text-center py-16 text-slate-500">No trips match your filters.</div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-navy-border text-left">
                  {['Date','Driver','Vehicle','Start','End','Miles','Purpose','Job'].map(h => (
                    <th key={h} className="label px-4 py-3 whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {trips.map((t, i) => (
                  <tr key={t.id}
                    className={`border-b border-navy-border last:border-0 hover:bg-navy-hover transition-colors ${
                      i % 2 === 0 ? '' : 'bg-white/[0.02]'
                    }`}
                  >
                    <td className="px-4 py-3 mono text-slate-300 whitespace-nowrap">
                      {format(new Date(t.date), 'MMM d, yy')}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      {t.profiles?.name || t.profiles?.email || '—'}
                    </td>
                    <td className="px-4 py-3 text-slate-300 whitespace-nowrap">
                      {t.vehicles?.name || '—'}
                    </td>
                    <td className="px-4 py-3 mono text-slate-400 whitespace-nowrap">
                      {Number(t.start_odometer).toFixed(1)}
                    </td>
                    <td className="px-4 py-3 mono text-slate-400 whitespace-nowrap">
                      {Number(t.end_odometer).toFixed(1)}
                    </td>
                    <td className="px-4 py-3 mono font-bold text-gold whitespace-nowrap">
                      {Number(t.miles).toFixed(1)}
                    </td>
                    <td className="px-4 py-3 max-w-[180px] truncate">{t.purpose}</td>
                    <td className="px-4 py-3 text-slate-400 max-w-[140px] truncate">
                      {t.job || '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
