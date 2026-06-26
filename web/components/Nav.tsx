'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LogOut } from 'lucide-react'
import { useAuth } from './AuthProvider'

interface NavLink { href: string; label: string }

const ADMIN_LINKS: NavLink[] = [
  { href: '/admin',          label: 'Trips'    },
  { href: '/admin/vehicles', label: 'Vehicles' },
  { href: '/admin/users',    label: 'Users'    },
]

export default function Nav() {
  const { profile, signOut } = useAuth()
  const pathname = usePathname()
  const isAdmin  = profile?.role === 'admin'

  return (
    <header className="sticky top-0 z-50 border-b border-navy-border bg-navy/95 backdrop-blur">
      <div className="max-w-5xl mx-auto px-4 h-14 flex items-center gap-4">
        {/* Logo */}
        <span className="text-xl font-black tracking-tight text-gold mr-2">STRIVE</span>

        {/* Admin nav links */}
        {isAdmin && (
          <nav className="flex gap-1">
            {ADMIN_LINKS.map(({ href, label }) => {
              const active = pathname === href
              return (
                <Link
                  key={href}
                  href={href}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    active
                      ? 'bg-gold/10 text-gold'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  {label}
                </Link>
              )
            })}
          </nav>
        )}

        <div className="ml-auto flex items-center gap-3">
          <span className="hidden sm:block text-sm text-slate-400">
            {profile?.name || profile?.email}
          </span>
          <button
            onClick={signOut}
            className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-navy-hover transition-colors"
            title="Sign out"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </header>
  )
}
