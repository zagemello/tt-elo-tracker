-- ============================================================
-- V2: Admin role
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Add is_admin column
ALTER TABLE public.profiles ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT false;

-- 2. Auto-set admin when anthony.mal.rivett@gmail.com signs up
CREATE OR REPLACE FUNCTION public.set_admin_on_profile_insert()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT email FROM auth.users WHERE id = NEW.id) = 'anthony.mal.rivett@gmail.com' THEN
    NEW.is_admin := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_set_admin
  BEFORE INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_admin_on_profile_insert();

-- 3. RLS: admin can delete any match
CREATE POLICY "Admin can delete matches"
  ON public.matches FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- 4. RLS: admin can update any profile (e.g. reset ELO)
CREATE POLICY "Admin can update any profile"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );
