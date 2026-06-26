'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Nav from '@/components/Nav'
import VehicleManager from '@/components/VehicleManager'
import { useAuth } from '@/components/AuthProvider'

export default function VehiclesPage() {
  const { profile, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && (!profile || profile.role !== 'admin')) router.replace('/')
  }, [loading, profile, router])

  if (loading || !profile) return (
    <div className="min-h-dvh flex items-center justify-center">
      <div className="w-8 h-8 border-2 border-gold border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="min-h-dvh flex flex-col">
      <Nav />
      <main className="flex-1 max-w-5xl mx-auto w-full px-4 py-6">
        <h1 className="text-xl font-bold mb-6">Vehicle Fleet</h1>
        <VehicleManager />
      </main>
    </div>
  )
}
