-- ============================================================
-- V4: Drop email-based admin trigger (now using username auth)
-- Run this in the Supabase SQL Editor
-- ============================================================

DROP TRIGGER IF EXISTS trg_set_admin ON public.profiles;
DROP FUNCTION IF EXISTS public.set_admin_on_profile_insert();

-- After signing up, run this to make yourself admin (replace 'your_username'):
-- UPDATE public.profiles SET is_admin = true WHERE display_name = 'your_username';
