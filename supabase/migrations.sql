-- ============================================================
-- Table Tennis Elo Tracker — Supabase SQL Migrations
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- 1. Profiles (extends auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  elo INT NOT NULL DEFAULT 1200,
  peak_elo INT NOT NULL DEFAULT 1200,
  matches_played INT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 0,  -- positive = win streak, negative = loss streak
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Matches
CREATE TABLE public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_id UUID NOT NULL REFERENCES public.profiles(id),
  loser_id UUID NOT NULL REFERENCES public.profiles(id),
  winner_score INT NOT NULL,
  loser_score INT NOT NULL,
  winner_elo_before INT NOT NULL,
  loser_elo_before INT NOT NULL,
  winner_elo_after INT NOT NULL,
  loser_elo_after INT NOT NULL,
  played_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Match Sets (granular set tracking)
CREATE TABLE public.match_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  set_number INT NOT NULL,
  winner_points INT NOT NULL,
  loser_points INT NOT NULL
);

-- 4. Elo History (for progression charts)
CREATE TABLE public.elo_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  new_elo INT NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_matches_winner ON public.matches(winner_id);
CREATE INDEX idx_matches_loser ON public.matches(loser_id);
CREATE INDEX idx_elo_history_player ON public.elo_history(player_id, recorded_at);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elo_history ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Matches
CREATE POLICY "Matches are viewable by everyone"
  ON public.matches FOR SELECT USING (true);

CREATE POLICY "Authenticated users can record matches"
  ON public.matches FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Match Sets
CREATE POLICY "Match sets viewable by everyone"
  ON public.match_sets FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert match sets"
  ON public.match_sets FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Elo History
CREATE POLICY "Elo history viewable by everyone"
  ON public.elo_history FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert elo history"
  ON public.elo_history FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- Elo Calculation RPC
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_elo_update(
  p_winner_id UUID,
  p_loser_id UUID,
  p_total_winner_points INT,
  p_total_loser_points INT
) RETURNS TABLE(new_winner_elo INT, new_loser_elo INT) AS $$
DECLARE
  r_winner INT;
  r_loser INT;
  matches_winner INT;
  matches_loser INT;
  k_base FLOAT;
  e_winner FLOAT;
  k_eff FLOAT;
  delta INT;
  point_diff INT;
BEGIN
  SELECT elo, matches_played INTO r_winner, matches_winner FROM profiles WHERE id = p_winner_id;
  SELECT elo, matches_played INTO r_loser, matches_loser FROM profiles WHERE id = p_loser_id;

  -- Dynamic K-factor: use the higher K if either player is provisional
  k_base := GREATEST(
    CASE WHEN matches_winner < 10 THEN 48.0 ELSE 32.0 END,
    CASE WHEN matches_loser  < 10 THEN 48.0 ELSE 32.0 END
  );

  -- Expected score for winner
  e_winner := 1.0 / (1.0 + POWER(10.0, (r_loser - r_winner)::FLOAT / 400.0));

  -- Margin-of-victory scaling: K_eff = K * ln(|point_diff| + 1)
  point_diff := ABS(p_total_winner_points - p_total_loser_points);
  k_eff := k_base * LN(point_diff::FLOAT + 1.0);

  delta := GREATEST(1, ROUND(k_eff * (1.0 - e_winner))::INT);

  RETURN QUERY SELECT (r_winner + delta)::INT, GREATEST(100, r_loser - delta)::INT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
