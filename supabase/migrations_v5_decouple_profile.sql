-- ============================================================
-- V5: Decouple profile ID from auth UUID
-- Profiles now have their own UUID; auth_id is just a pointer.
-- Deleting + re-registering with the same username restores stats.
-- Run this in the Supabase SQL Editor AFTER v4
-- ============================================================

-- 1. Add auth_id column (nullable so profiles survive auth deletion)
ALTER TABLE public.profiles
  ADD COLUMN auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL;

-- 2. Migrate existing profiles: copy current id → auth_id
UPDATE public.profiles SET auth_id = id;

-- 3. Drop the FK that tied profiles.id to auth.users.id
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 4. Allow profiles.id to be auto-generated for new rows
ALTER TABLE public.profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 5. Update RLS policies to use auth_id instead of id
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can delete matches" ON public.matches;

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = auth_id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = auth_id);

CREATE POLICY "Admin can update any profile"
  ON public.profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin can delete matches"
  ON public.matches FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid() AND is_admin = true));

-- 6. RPC: create new profile or re-link existing one by username
CREATE OR REPLACE FUNCTION public.upsert_profile(p_display_name TEXT)
RETURNS UUID AS $$
DECLARE
  existing_id UUID;
BEGIN
  SELECT id INTO existing_id FROM public.profiles WHERE display_name = p_display_name;

  IF existing_id IS NOT NULL THEN
    -- Re-link existing profile to the new auth account (stats preserved)
    UPDATE public.profiles SET auth_id = auth.uid() WHERE id = existing_id;
    RETURN existing_id;
  ELSE
    -- Brand new player
    INSERT INTO public.profiles (auth_id, display_name) VALUES (auth.uid(), p_display_name);
    RETURN (SELECT id FROM public.profiles WHERE auth_id = auth.uid());
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
