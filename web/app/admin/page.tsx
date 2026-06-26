'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Nav from '@/components/Nav'
import StatsBar from '@/components/StatsBar'
import AdminTripTable from '@/components/AdminTripTable'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/components/AuthProvider'
import type { Trip, Profile, Vehicle } from '@/lib/types'

export default function AdminPage() {
  const { profile, loading } = useAuth()
  const router = useRouter()

  const [trips,    setTrips]    = useState<Trip[]>([])
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [rate,     setRate]     = useState(0.67)
  const [busy,     setBusy]     = useState(true)

  // Filters
  const [driverFilter,  setDriverFilter]  = useState('')
  const [vehicleFilter, setVehicleFilter] = useState('')
  const [dateFrom,      setDateFrom]      = useState('')
  const [dateTo,        setDateTo]        = useState('')

  useEffect(() => {
    if (!loading && !profile) router.replace('/')
    if (!loading && profile?.role !== 'admin') router.replace('/driver')
  }, [loading, profile, router])

  const load = useCallback(async () => {
    setBusy(true)
    const [tripsRes, profilesRes, vehiclesRes, settingsRes] = await Promise.all([
      supabase
        .from('trips')
        .select('*, profiles:driver_id(email,name), vehicles:vehicle_id(name)')
        .order('date', { ascending: false }),
      supabase.from('profiles').select('*').order('name'),
      supabase.from('vehicles').select('*').order('name'),
      supabase.from('settings').select('*').eq('key', 'per_mile_rate').single(),
    ])
    setTrips(tripsRes.data ?? [])
    setProfiles(profilesRes.data ?? [])
    setVehicles(vehiclesRes.data ?? [])
    if (settingsRes.data) setRate(parseFloat(settingsRes.data.value))
    setBusy(false)
  }, [])

  useEffect(() => { if (profile?.role === 'admin') load() }, [profile, load])

  const filtered = trips.filter(t => {
    if (driverFilter  && t.driver_id  !== driverFilter)  return false
    if (vehicleFilter && t.vehicle_id !== vehicleFilter) return false
    if (dateFrom && t.date < dateFrom) return false
    if (dateTo   && t.date > dateTo)   return false
    return true
  })

  if (loading || !profile) return <Spinner />

  return (
    <div className="min-h-dvh flex flex-col">
      <Nav />
      <main className="flex-1 max-w-5xl mx-auto w-full px-4 py-6">
        <h1 className="text-xl font-bold mb-6">
          All Trips
          {busy && <span className="inline-block ml-3 w-4 h-4 border-2 border-gold border-t-transparent
                                    rounded-full animate-spin align-middle" />}
        </h1>

        <StatsBar trips={filtered} rate={rate} onRateChange={setRate} />

        <AdminTripTable
          trips={filtered}
          profiles={profiles.filter(p => p.role === 'driver')}
          vehicles={vehicles}
          driverFilter={driverFilter}
          vehicleFilter={vehicleFilter}
          dateFrom={dateFrom}
          dateTo={dateTo}
          onDriverFilter={setDriverFilter}
          onVehicleFilter={setVehicleFilter}
          onDateFrom={setDateFrom}
          onDateTo={setDateTo}
        />
      </main>
    </div>
  )
}

function Spinner() {
  return (
    <div className="min-h-dvh flex items-center justify-center">
      <div className="w-8 h-8 border-2 border-gold border-t-transparent rounded-full animate-spin" />
    </div>
  )
}
