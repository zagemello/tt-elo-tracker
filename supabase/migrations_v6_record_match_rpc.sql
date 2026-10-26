-- ============================================================
-- V6: record_match RPC — atomic match recording with SECURITY DEFINER
-- Fixes the RLS issue where the loser's profile couldn't be updated
-- by the person logging the match.
-- Run this in the Supabase SQL Editor AFTER v5
-- ============================================================

CREATE OR REPLACE FUNCTION public.record_match(
  p_winner_id          UUID,
  p_loser_id           UUID,
  p_winner_score       INT,
  p_loser_score        INT,
  p_total_winner_pts   INT,
  p_total_loser_pts    INT,
  p_sets               JSONB   -- [{winner_points, loser_points}, ...]
) RETURNS UUID AS $$
DECLARE
  elo           RECORD;
  match_id      UUID;
  wp            RECORD;
  lp            RECORD;
  new_w_streak  INT;
  new_l_streak  INT;
  s             JSONB;
  i             INT := 1;
BEGIN
  SELECT * INTO wp FROM public.profiles WHERE id = p_winner_id;
  SELECT * INTO lp FROM public.profiles WHERE id = p_loser_id;

  SELECT * INTO elo FROM public.calculate_elo_update(
    p_winner_id, p_loser_id, p_total_winner_pts, p_total_loser_pts
  );

  INSERT INTO public.matches (
    winner_id, loser_id,
    winner_score, loser_score,
    winner_elo_before, loser_elo_before,
    winner_elo_after,  loser_elo_after
  ) VALUES (
    p_winner_id, p_loser_id,
    p_winner_score, p_loser_score,
    elo.eff_winner_elo, elo.eff_loser_elo,
    elo.new_winner_elo, elo.new_loser_elo
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
    elo            = elo.new_winner_elo,
    rd             = elo.new_winner_rd,
    last_played_at = NOW(),
    peak_elo       = GREATEST(peak_elo, elo.new_winner_elo),
    matches_played = matches_played + 1,
    wins           = wins + 1,
    current_streak = new_w_streak
  WHERE id = p_winner_id;

  UPDATE public.profiles SET
    elo            = elo.new_loser_elo,
    rd             = elo.new_loser_rd,
    last_played_at = NOW(),
    matches_played = matches_played + 1,
    losses         = losses + 1,
    current_streak = new_l_streak
  WHERE id = p_loser_id;

  RETURN match_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
