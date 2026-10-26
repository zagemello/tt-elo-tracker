-- ============================================================
-- TT Elo Tracker — Full Database Schema
-- Run this once in the Supabase SQL Editor for a fresh setup.
-- ============================================================

-- ============================================================
-- Tables
-- ============================================================

CREATE TABLE public.profiles (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id        UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  display_name   TEXT UNIQUE NOT NULL,
  avatar_url     TEXT,
  elo            INT NOT NULL DEFAULT 1200,
  peak_elo       INT NOT NULL DEFAULT 1200,
  rd             FLOAT NOT NULL DEFAULT 150,
  matches_played INT NOT NULL DEFAULT 0,
  wins           INT NOT NULL DEFAULT 0,
  losses         INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 0,
  is_admin       BOOLEAN NOT NULL DEFAULT false,
  last_played_at TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.matches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_id         UUID NOT NULL REFERENCES public.profiles(id),
  loser_id          UUID NOT NULL REFERENCES public.profiles(id),
  winner_score      INT NOT NULL,
  loser_score       INT NOT NULL,
  winner_elo_before INT NOT NULL,
  loser_elo_before  INT NOT NULL,
  winner_elo_after  INT NOT NULL,
  loser_elo_after   INT NOT NULL,
  played_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.match_sets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  set_number    INT NOT NULL,
  winner_points INT NOT NULL,
  loser_points  INT NOT NULL
);

CREATE TABLE public.elo_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_id    UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  new_elo     INT NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_matches_winner    ON public.matches(winner_id);
CREATE INDEX idx_matches_loser     ON public.matches(loser_id);
CREATE INDEX idx_elo_history_player ON public.elo_history(player_id, recorded_at);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_sets  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elo_history ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = auth_id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = auth_id);

CREATE POLICY "Admin can update any profile"
  ON public.profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid() AND is_admin = true));

-- Matches
CREATE POLICY "Matches are viewable by everyone"
  ON public.matches FOR SELECT USING (true);

CREATE POLICY "Authenticated users can record matches"
  ON public.matches FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin can delete matches"
  ON public.matches FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid() AND is_admin = true));

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
-- RPCs
-- ============================================================

-- Glicko-inspired ELO calculation with RD, inactivity decay, asymmetric K
CREATE OR REPLACE FUNCTION public.calculate_elo_update(
  p_winner_id          UUID,
  p_loser_id           UUID,
  p_total_winner_points INT,
  p_total_loser_points  INT
) RETURNS TABLE(
  new_winner_elo INT, new_loser_elo INT,
  new_winner_rd  FLOAT, new_loser_rd  FLOAT,
  eff_winner_elo INT, eff_loser_elo INT
) AS $$
DECLARE
  r_w INT;   r_l INT;
  rd_w FLOAT; rd_l FLOAT;
  last_w TIMESTAMPTZ; last_l TIMESTAMPTZ;
  days_w FLOAT; days_l FLOAT;
  eff_w INT;  eff_l INT;
  k_w FLOAT;  k_l FLOAT;
  e_w FLOAT;
  pdiff INT;
  d_w INT;    d_l INT;
  nrd_w FLOAT; nrd_l FLOAT;

  GRACE      CONSTANT FLOAT := 14.0;
  DECAY_RATE CONSTANT FLOAT := 0.99;
  MAX_DECAY  CONSTANT INT   := 150;
  RD_FLOOR   CONSTANT FLOAT := 40.0;
  RD_CEIL    CONSTANT FLOAT := 200.0;
  RD_C       CONSTANT FLOAT := 12.0;
  RD_STEP    CONSTANT FLOAT := 8.0;
BEGIN
  SELECT elo, rd, last_played_at INTO r_w, rd_w, last_w FROM profiles WHERE id = p_winner_id;
  SELECT elo, rd, last_played_at INTO r_l, rd_l, last_l FROM profiles WHERE id = p_loser_id;

  days_w := GREATEST(0, EXTRACT(EPOCH FROM (NOW() - COALESCE(last_w, NOW()))) / 86400.0 - GRACE);
  days_l := GREATEST(0, EXTRACT(EPOCH FROM (NOW() - COALESCE(last_l, NOW()))) / 86400.0 - GRACE);

  eff_w := r_w - LEAST(MAX_DECAY, GREATEST(0, ROUND((r_w - 1200)::FLOAT * (1.0 - POWER(DECAY_RATE, days_w)))::INT));
  eff_l := r_l - LEAST(MAX_DECAY, GREATEST(0, ROUND((r_l - 1200)::FLOAT * (1.0 - POWER(DECAY_RATE, days_l)))::INT));

  rd_w := LEAST(RD_CEIL, SQRT(POWER(rd_w, 2) + POWER(RD_C * days_w / 7.0, 2)));
  rd_l := LEAST(RD_CEIL, SQRT(POWER(rd_l, 2) + POWER(RD_C * days_l / 7.0, 2)));

  k_w := GREATEST(12.0, rd_w / 4.0);
  k_l := GREATEST(12.0, rd_l / 4.0);

  e_w := 1.0 / (1.0 + POWER(10.0, (eff_l - eff_w)::FLOAT / 400.0));

  pdiff := ABS(p_total_winner_points - p_total_loser_points);

  d_w := GREATEST(1, ROUND(k_w * LN(pdiff::FLOAT + 1.0) * (1.0 - e_w))::INT);
  d_l := GREATEST(1, ROUND(k_l * LN(pdiff::FLOAT + 1.0) * (1.0 - e_w))::INT);

  nrd_w := GREATEST(RD_FLOOR, rd_w - RD_STEP);
  nrd_l := GREATEST(RD_FLOOR, rd_l - RD_STEP);

  RETURN QUERY SELECT
    (eff_w + d_w)::INT, GREATEST(100, eff_l - d_l)::INT,
    nrd_w, nrd_l, eff_w, eff_l;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Create or re-link a profile by username (used on signup)
CREATE OR REPLACE FUNCTION public.upsert_profile(p_display_name TEXT)
RETURNS UUID AS $$
DECLARE
  existing_id UUID;
BEGIN
  SELECT id INTO existing_id FROM public.profiles WHERE display_name = p_display_name;

  IF existing_id IS NOT NULL THEN
    UPDATE public.profiles SET auth_id = auth.uid() WHERE id = existing_id;
    RETURN existing_id;
  ELSE
    INSERT INTO public.profiles (auth_id, display_name) VALUES (auth.uid(), p_display_name);
    RETURN (SELECT id FROM public.profiles WHERE auth_id = auth.uid());
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Atomic match recording (bypasses RLS to update both players)
CREATE OR REPLACE FUNCTION public.record_match(
  p_winner_id          UUID,
  p_loser_id           UUID,
  p_winner_score       INT,
  p_loser_score        INT,
  p_total_winner_pts   INT,
  p_total_loser_pts    INT,
  p_sets               JSONB
) RETURNS UUID AS $$
DECLARE
  elo          RECORD;
  match_id     UUID;
  wp           RECORD;
  lp           RECORD;
  new_w_streak INT;
  new_l_streak INT;
  s            JSONB;
  i            INT := 1;
BEGIN
  SELECT * INTO wp FROM public.profiles WHERE id = p_winner_id;
  SELECT * INTO lp FROM public.profiles WHERE id = p_loser_id;

  SELECT * INTO elo FROM public.calculate_elo_update(
    p_winner_id, p_loser_id, p_total_winner_pts, p_total_loser_pts
  );

  INSERT INTO public.matches (
    winner_id, loser_id, winner_score, loser_score,
    winner_elo_before, loser_elo_before, winner_elo_after, loser_elo_after
  ) VALUES (
    p_winner_id, p_loser_id, p_winner_score, p_loser_score,
    elo.eff_winner_elo, elo.eff_loser_elo, elo.new_winner_elo, elo.new_loser_elo
  ) RETURNING id INTO match_id;

  FOR s IN SELECT * FROM jsonb_array_elements(p_sets) LOOP
    INSERT INTO public.match_sets (match_id, set_number, winner_points, loser_points)
    VALUES (match_id, i, (s->>'winner_points')::INT, (s->>'loser_points')::INT);
    i := i + 1;
  END LOOP;

  INSERT INTO public.elo_history (player_id, match_id, new_elo) VALUES
    (p_winner_id, match_id, elo.new_winner_elo),
    (p_loser_id,  match_id, elo.new_loser_elo);

  new_w_streak := CASE WHEN wp.current_streak >= 0 THEN wp.current_streak + 1 ELSE 1 END;
  new_l_streak := CASE WHEN lp.current_streak <= 0 THEN lp.current_streak - 1 ELSE -1 END;

  UPDATE public.profiles SET
    elo = elo.new_winner_elo, rd = elo.new_winner_rd, last_played_at = NOW(),
    peak_elo = GREATEST(peak_elo, elo.new_winner_elo),
    matches_played = matches_played + 1, wins = wins + 1, current_streak = new_w_streak
  WHERE id = p_winner_id;

  UPDATE public.profiles SET
    elo = elo.new_loser_elo, rd = elo.new_loser_rd, last_played_at = NOW(),
    matches_played = matches_played + 1, losses = losses + 1, current_streak = new_l_streak
  WHERE id = p_loser_id;

  RETURN match_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Recalculate a player's current streak from match history
CREATE OR REPLACE FUNCTION public.recalculate_streak(p_player_id UUID)
RETURNS INT AS $$
DECLARE
  streak INT := 0;
  first  BOOL := true;
  is_win BOOL;
  sign   INT;
  m      RECORD;
BEGIN
  FOR m IN
    SELECT winner_id, played_at FROM public.matches
    WHERE winner_id = p_player_id OR loser_id = p_player_id
    ORDER BY played_at DESC
  LOOP
    is_win := m.winner_id = p_player_id;
    sign   := CASE WHEN is_win THEN 1 ELSE -1 END;
    IF first THEN
      streak := sign; first := false;
    ELSIF (is_win AND streak > 0) OR (NOT is_win AND streak < 0) THEN
      streak := streak + sign;
    ELSE
      EXIT;
    END IF;
  END LOOP;
  RETURN streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Delete a match and reverse its ELO impact
CREATE OR REPLACE FUNCTION public.delete_match(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
  m       RECORD;
  w_delta INT;
  l_delta INT;
BEGIN
  SELECT * INTO m FROM public.matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Match not found'; END IF;

  w_delta := m.winner_elo_after - m.winner_elo_before;
  l_delta := m.loser_elo_before - m.loser_elo_after;

  UPDATE public.profiles SET
    elo = GREATEST(100, elo - w_delta),
    matches_played = GREATEST(0, matches_played - 1),
    wins = GREATEST(0, wins - 1)
  WHERE id = m.winner_id;

  UPDATE public.profiles SET
    elo = GREATEST(100, elo + l_delta),
    matches_played = GREATEST(0, matches_played - 1),
    losses = GREATEST(0, losses - 1)
  WHERE id = m.loser_id;

  DELETE FROM public.elo_history WHERE match_id = p_match_id;
  DELETE FROM public.match_sets   WHERE match_id = p_match_id;
  DELETE FROM public.matches      WHERE id = p_match_id;

  UPDATE public.profiles SET current_streak = public.recalculate_streak(id)
  WHERE id IN (m.winner_id, m.loser_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- After running this file:
-- 1. In Supabase Auth settings, turn OFF "Confirm email"
-- 2. Sign up in the app with your username
-- 3. Run: UPDATE public.profiles SET is_admin = true WHERE display_name = 'YourUsername';
-- ============================================================
