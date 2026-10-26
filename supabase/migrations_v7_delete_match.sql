-- ============================================================
-- V7: delete_match RPC — reverses ELO and stats on match deletion
-- Run this in the Supabase SQL Editor AFTER v6
-- ============================================================

-- Helper: recalculate a player's current streak from match history
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
      streak := sign;
      first  := false;
    ELSIF (is_win AND streak > 0) OR (NOT is_win AND streak < 0) THEN
      streak := streak + sign;
    ELSE
      EXIT;
    END IF;
  END LOOP;

  RETURN streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Main: delete a match and reverse its ELO impact
CREATE OR REPLACE FUNCTION public.delete_match(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
  m           RECORD;
  w_delta     INT;
  l_delta     INT;
BEGIN
  SELECT * INTO m FROM public.matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Match not found'; END IF;

  -- How much ELO the winner gained and loser lost in this match
  w_delta := m.winner_elo_after - m.winner_elo_before;
  l_delta := m.loser_elo_before - m.loser_elo_after;

  -- Reverse winner stats
  UPDATE public.profiles SET
    elo            = GREATEST(100, elo - w_delta),
    matches_played = GREATEST(0, matches_played - 1),
    wins           = GREATEST(0, wins - 1)
  WHERE id = m.winner_id;

  -- Reverse loser stats
  UPDATE public.profiles SET
    elo            = GREATEST(100, elo + l_delta),
    matches_played = GREATEST(0, matches_played - 1),
    losses         = GREATEST(0, losses - 1)
  WHERE id = m.loser_id;

  -- Delete match records
  DELETE FROM public.elo_history WHERE match_id = p_match_id;
  DELETE FROM public.match_sets   WHERE match_id = p_match_id;
  DELETE FROM public.matches      WHERE id = p_match_id;

  -- Recalculate streaks from remaining matches
  UPDATE public.profiles SET current_streak = public.recalculate_streak(id)
  WHERE id IN (m.winner_id, m.loser_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
