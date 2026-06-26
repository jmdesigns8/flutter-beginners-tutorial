import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'

// PATCH /api/users/:id — update role
export async function PATCH(
  req: Request,
  { params }: { params: { id: string } }
) {
  const { role } = await req.json()
  if (!['admin', 'driver'].includes(role)) {
    return NextResponse.json({ error: 'Invalid role' }, { status: 400 })
  }
  const admin = supabaseAdmin()
  const { error } = await admin
    .from('profiles')
    .update({ role })
    .eq('id', params.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}

// DELETE /api/users/:id — remove user
export async function DELETE(
  _req: Request,
  { params }: { params: { id: string } }
) {
  const admin = supabaseAdmin()
  const { error } = await admin.auth.admin.deleteUser(params.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}
