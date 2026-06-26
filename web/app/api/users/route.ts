import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'

// GET /api/users — list all profiles
export async function GET() {
  const admin = supabaseAdmin()
  const { data, error } = await admin.from('profiles').select('*').order('name')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ users: data })
}

// POST /api/users — create a user with a temporary password
export async function POST(req: Request) {
  const { email, name, role } = await req.json()
  if (!email || !name || !role) {
    return NextResponse.json({ error: 'email, name, and role are required' }, { status: 400 })
  }

  const tempPassword =
    'Strive' +
    Math.random().toString(36).slice(2, 6).toUpperCase() +
    Math.random().toString(36).slice(2, 5) +
    '!'

  const admin = supabaseAdmin()
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password:      tempPassword,
    email_confirm: true,   // skip email confirmation
    user_metadata: { name, role },
  })

  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ user: data.user, tempPassword })
}
