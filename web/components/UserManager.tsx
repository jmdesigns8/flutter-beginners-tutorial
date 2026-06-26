'use client'
import { useState, useEffect, useCallback } from 'react'
import { Plus, Trash2, ShieldCheck, User } from 'lucide-react'
import { format } from 'date-fns'
import type { Profile, Role } from '@/lib/types'

export default function UserManager() {
  const [users,   setUsers]   = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [adding,  setAdding]  = useState(false)
  const [form,    setForm]    = useState({ email: '', name: '', role: 'driver' as Role })
  const [busy,    setBusy]    = useState(false)
  const [msg,     setMsg]     = useState<{ text: string; type: 'ok' | 'err' } | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    const res = await fetch('/api/users')
    const data = await res.json()
    setUsers(data.users ?? [])
    setLoading(false)
  }, [])

  useEffect(() => { load() }, [load])

  async function invite(e: React.FormEvent) {
    e.preventDefault()
    setBusy(true); setMsg(null)
    const res  = await fetch('/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    })
    const data = await res.json()
    setBusy(false)
    if (!res.ok) { setMsg({ text: data.error || 'Failed', type: 'err' }); return }
    setMsg({
      text: `✓ User created. Temporary password: ${data.tempPassword}`,
      type: 'ok',
    })
    setAdding(false)
    setForm({ email: '', name: '', role: 'driver' })
    load()
  }

  async function remove(id: string, email: string) {
    if (!confirm(`Remove ${email}? This cannot be undone.`)) return
    await fetch(`/api/users/${id}`, { method: 'DELETE' })
    load()
  }

  async function changeRole(id: string, role: Role) {
    await fetch(`/api/users/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role }),
    })
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
        <h2 className="font-semibold">Users ({users.length})</h2>
        <button onClick={() => setAdding(a => !a)} className="btn-gold py-2 px-4 flex items-center gap-1.5 text-sm">
          <Plus size={14} /> Add User
        </button>
      </div>

      {/* Result message */}
      {msg && (
        <div className={`mb-4 rounded-lg px-4 py-3 text-sm ${
          msg.type === 'ok'
            ? 'bg-green-900/30 border border-green-500/40 text-green-300'
            : 'bg-red-900/20 border border-red-500/30 text-red-400'
        }`}>
          {msg.text}
        </div>
      )}

      {/* Add user form */}
      {adding && (
        <form onSubmit={invite} className="card mb-4 space-y-3">
          <h3 className="font-medium text-sm text-gold">New User</h3>
          <div>
            <label className="label block mb-1">Email</label>
            <input
              type="email" required autoFocus
              value={form.email}
              onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
              className="w-full px-3 py-2 text-sm"
              placeholder="driver@example.com"
            />
          </div>
          <div>
            <label className="label block mb-1">Display Name</label>
            <input
              type="text" required
              value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              className="w-full px-3 py-2 text-sm"
              placeholder="Jake Smith"
            />
          </div>
          <div>
            <label className="label block mb-1">Role</label>
            <select
              value={form.role}
              onChange={e => setForm(f => ({ ...f, role: e.target.value as Role }))}
              className="w-full px-3 py-2 text-sm"
            >
              <option value="driver">Driver</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div className="flex gap-2 pt-1">
            <button type="submit" disabled={busy} className="btn-gold flex-1 py-2 text-sm">
              {busy ? 'Creating…' : 'Create User'}
            </button>
            <button type="button" onClick={() => setAdding(false)} className="btn-ghost py-2 px-4 text-sm">
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* User list */}
      <div className="space-y-2">
        {users.map(u => (
          <div key={u.id} className="card flex items-center gap-3">
            <div className={`p-2 rounded-lg ${u.role === 'admin' ? 'bg-gold/10 text-gold' : 'bg-navy-hover text-slate-400'}`}>
              {u.role === 'admin' ? <ShieldCheck size={16} /> : <User size={16} />}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{u.name || u.email}</p>
              {u.name && <p className="text-xs text-slate-500 truncate">{u.email}</p>}
            </div>
            <select
              value={u.role}
              onChange={e => changeRole(u.id, e.target.value as Role)}
              className="text-xs px-2 py-1 rounded-lg border border-navy-border bg-navy-card text-slate-300 focus:border-gold focus:ring-1 focus:ring-gold"
            >
              <option value="driver">Driver</option>
              <option value="admin">Admin</option>
            </select>
            <button
              onClick={() => remove(u.id, u.email)}
              className="text-slate-600 hover:text-red-400 p-1.5 transition-colors"
              title="Remove user"
            ><Trash2 size={14} /></button>
          </div>
        ))}
      </div>
    </div>
  )
}
