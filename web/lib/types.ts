export type Role = 'admin' | 'driver'

export interface Profile {
  id: string
  email: string
  name: string
  role: Role
  created_at: string
}

export interface Vehicle {
  id: string
  name: string
  active: boolean
  created_at: string
}

export interface Trip {
  id: string
  driver_id: string
  vehicle_id: string
  date: string
  start_odometer: number
  end_odometer: number
  miles: number
  purpose: string
  job: string | null
  created_at: string
  // joined fields
  profiles?: { email: string; name: string }
  vehicles?:  { name: string }
}
