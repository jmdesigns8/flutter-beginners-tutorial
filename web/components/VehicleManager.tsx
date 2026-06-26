'use client'
import { useState, useEffect, useCallback } from 'react'
import { Plus, Pencil, Check, X, Trash2 } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import type { Vehicle } from '@/lib/types'

export default function VehicleManager() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [loading,  setLoading]  = useState(true)
  const [adding,   setAdding]   = useState(false)
  const [newName,  setNewName]  = useState('')
  const [editId,   setEditId]   = useState<string | null>(null)
  const [editName, setEditName] = useState('')

  const load = useCallback(async () => {
    const { data } = await supabase.from('vehicles').select('*').order('name')
    setVehicles(data ?? [])
    setLoading(false)
  }, [])

  useEffect(() => { load() }, [load])

  async function add() {
    if (!newName.trim()) return
    await supabase.from('vehicles').insert({ name: newName.trim() })
    setNewName(''); setAdding(false); load()
  }

  async function save(id: string) {
    if (!editName.trim()) return
    await supabase.from('vehicles').update({ name: editName.trim() }).eq('id', id)
    setEditId(null); load()
  }

  async function toggle(v: Vehicle) {
    await supabase.from('vehicles').update({ active: !v.active }).eq('id', v.id)
    load()
  }

  async function remove(id: string) {
    if (!confirm('Remove this vehicle? Existing trips keep their record.')) return
    await supabase.from('vehicles').delete().eq('id', id)
    load()
  }

  if (loading) return (
    <div className="flex justify-center py-12">
      <div className="w-6 h-6 border-2 border-gold border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="max-w-lg">
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-semibold">Fleet ({vehicles.length})</h2>
        <button onClick={() => setAdding(true)} className="btn-gold py-2 px-4 flex items-center gap-1.5 text-sm">
          <Plus size={14} /> Add Vehicle
        </button>
      </div>

      {/* Add row */}
      {adding && (
        <div className="card mb-3 flex items-center gap-2">
          <input
            type="text" autoFocus
            placeholder="Vehicle name"
            value={newName} onChange={e => setNewName(e.target.value)}
            className="flex-1 px-3 py-2 text-sm"
            onKeyDown={e => e.key === 'Enter' && add()}
          />
          <button onClick={add} className="text-green-400 p-1.5 hover:text-green-300"><Check size={16} /></button>
          <button onClick={() => setAdding(false)} className="text-slate-500 p-1.5 hover:text-slate-300"><X size={16} /></button>
        </div>
      )}

      <div className="space-y-2">
        {vehicles.map(v => (
          <div key={v.id} className={`card flex items-center gap-3 ${!v.active ? 'opacity-40' : ''}`}>
            {editId === v.id ? (
              <>
                <input
                  type="text" autoFocus
                  value={editName} onChange={e => setEditName(e.target.value)}
                  className="flex-1 px-3 py-1.5 text-sm"
                  onKeyDown={e => e.key === 'Enter' && save(v.id)}
                />
                <button onClick={() => save(v.id)} className="text-green-400 p-1.5"><Check size={15} /></button>
                <button onClick={() => setEditId(null)} className="text-slate-500 p-1.5"><X size={15} /></button>
              </>
            ) : (
              <>
                <span className="flex-1 text-sm font-medium">{v.name}</span>
                {!v.active && <span className="text-xs text-slate-500 bg-navy-hover px-2 py-0.5 rounded-full">Inactive</span>}
                <button
                  onClick={() => { setEditId(v.id); setEditName(v.name) }}
                  className="text-slate-500 hover:text-gold p-1.5 transition-colors"
                  title="Edit"
                ><Pencil size={14} /></button>
                <button
                  onClick={() => toggle(v)}
                  className="text-slate-500 hover:text-slate-300 p-1.5 transition-colors text-xs"
                  title={v.active ? 'Deactivate' : 'Activate'}
                >{v.active ? 'Deactivate' : 'Activate'}</button>
                <button
                  onClick={() => remove(v.id)}
                  className="text-slate-600 hover:text-red-400 p-1.5 transition-colors"
                  title="Delete"
                ><Trash2 size={14} /></button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
