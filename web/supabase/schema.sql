-- ============================================================
-- Strive Mileage Tracker — Supabase Schema
-- Paste this entire block into:
--   Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================

-- 1. Profiles (one row per auth user)
CREATE TABLE IF NOT EXISTS profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email      TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL DEFAULT '',
  role       TEXT NOT NULL DEFAULT 'driver'
               CHECK (role IN ('admin', 'driver')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Trips
--    miles is auto-calculated from odometer readings
CREATE TABLE IF NOT EXISTS trips (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_id      UUID NOT NULL REFERENCES vehicles(id),
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  start_odometer  NUMERIC(10,1) NOT NULL,
  end_odometer    NUMERIC(10,1) NOT NULL,
  miles           NUMERIC(10,1) GENERATED ALWAYS AS (end_odometer - start_odometer) STORED,
  purpose         TEXT NOT NULL,
  job             TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Settings (key/value store for admin-editable config)
CREATE TABLE IF NOT EXISTS settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default: IRS standard mileage rate
INSERT INTO settings (key, value) VALUES ('per_mile_rate', '0.67')
ON CONFLICT (key) DO NOTHING;

-- Seed vehicles
INSERT INTO vehicles (name) VALUES
  ('F-250 · Power Stroke'),
  ('Dump trailer')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips    ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user is admin (SECURITY DEFINER avoids RLS recursion)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- profiles: authenticated users can read all (needed for admin to see driver names)
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "profiles_insert_self" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_admin" ON profiles
  FOR UPDATE USING (is_admin());

CREATE POLICY "profiles_delete_admin" ON profiles
  FOR DELETE USING (is_admin());

-- vehicles: all authenticated can read; only admin writes
CREATE POLICY "vehicles_select" ON vehicles
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "vehicles_insert_admin" ON vehicles
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "vehicles_update_admin" ON vehicles
  FOR UPDATE USING (is_admin());

CREATE POLICY "vehicles_delete_admin" ON vehicles
  FOR DELETE USING (is_admin());

-- trips: drivers see own; admin sees all
CREATE POLICY "trips_select" ON trips
  FOR SELECT USING (driver_id = auth.uid() OR is_admin());

CREATE POLICY "trips_insert" ON trips
  FOR INSERT WITH CHECK (driver_id = auth.uid());

CREATE POLICY "trips_update" ON trips
  FOR UPDATE USING (driver_id = auth.uid() OR is_admin());

CREATE POLICY "trips_delete" ON trips
  FOR DELETE USING (driver_id = auth.uid() OR is_admin());

-- settings: all authenticated can read; only admin writes
CREATE POLICY "settings_select" ON settings
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "settings_update_admin" ON settings
  FOR UPDATE USING (is_admin());

-- ============================================================
-- Trigger: create profile row whenever a user signs up
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'name',
      split_part(NEW.email, '@', 1)
    ),
    CASE
      -- Hardcode the first admin by email
      WHEN lower(NEW.email) = 'j.murphy120410@gmail.com' THEN 'admin'
      -- Honor role set by admin API (invite flow)
      WHEN NEW.raw_user_meta_data ->> 'role' IN ('admin', 'driver')
        THEN NEW.raw_user_meta_data ->> 'role'
      ELSE 'driver'
    END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
