-- ============================================================
-- V3: Glicko-inspired RD + inactivity decay
-- Run this in the Supabase SQL Editor AFTER v2
-- ============================================================

-- 1. New columns
ALTER TABLE public.profiles
  ADD COLUMN rd FLOAT NOT NULL DEFAULT 150,
  ADD COLUMN last_played_at TIMESTAMPTZ;

-- 2. Updated ELO function
CREATE OR REPLACE FUNCTION calculate_elo_update(
  p_winner_id UUID,
  p_loser_id UUID,
  p_total_winner_points INT,
  p_total_loser_points INT
) RETURNS TABLE(
  new_winner_elo   INT,
  new_loser_elo    INT,
  new_winner_rd    FLOAT,
  new_loser_rd     FLOAT,
  eff_winner_elo   INT,
  eff_loser_elo    INT
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
  DECAY_RATE CONSTANT FLOAT := 0.99;  -- 1% per inactive day toward 1200
  MAX_DECAY  CONSTANT INT   := 150;
  RD_FLOOR   CONSTANT FLOAT := 40.0;
  RD_CEIL    CONSTANT FLOAT := 200.0;
  RD_C       CONSTANT FLOAT := 12.0;  -- RD units added per week inactive
  RD_STEP    CONSTANT FLOAT := 8.0;   -- RD decrease per game played
BEGIN
  SELECT elo, rd, last_played_at INTO r_w, rd_w, last_w FROM profiles WHERE id = p_winner_id;
  SELECT elo, rd, last_played_at INTO r_l, rd_l, last_l FROM profiles WHERE id = p_loser_id;

  -- Days inactive beyond grace period
  days_w := GREATEST(0, EXTRACT(EPOCH FROM (NOW() - COALESCE(last_w, NOW()))) / 86400.0 - GRACE);
  days_l := GREATEST(0, EXTRACT(EPOCH FROM (NOW() - COALESCE(last_l, NOW()))) / 86400.0 - GRACE);

  -- ELO inactivity decay (only pulls above-1200 ratings toward 1200)
  eff_w := r_w - LEAST(MAX_DECAY, GREATEST(0, ROUND((r_w - 1200)::FLOAT * (1.0 - POWER(DECAY_RATE, days_w)))::INT));
  eff_l := r_l - LEAST(MAX_DECAY, GREATEST(0, ROUND((r_l - 1200)::FLOAT * (1.0 - POWER(DECAY_RATE, days_l)))::INT));

  -- RD increases with inactivity: RD_new = sqrt(RD^2 + (c * weeks_inactive)^2)
  rd_w := LEAST(RD_CEIL, SQRT(POWER(rd_w, 2) + POWER(RD_C * days_w / 7.0, 2)));
  rd_l := LEAST(RD_CEIL, SQRT(POWER(rd_l, 2) + POWER(RD_C * days_l / 7.0, 2)));

  -- K from RD — your uncertainty drives your volatility (asymmetric)
  k_w := GREATEST(12.0, rd_w / 4.0);
  k_l := GREATEST(12.0, rd_l / 4.0);

  -- Expected score for winner
  e_w := 1.0 / (1.0 + POWER(10.0, (eff_l - eff_w)::FLOAT / 400.0));

  -- Margin of victory scaling
  pdiff := ABS(p_total_winner_points - p_total_loser_points);

  -- Each player's delta uses their own K (asymmetric gain/loss)
  d_w := GREATEST(1, ROUND(k_w * LN(pdiff::FLOAT + 1.0) * (1.0 - e_w))::INT);
  d_l := GREATEST(1, ROUND(k_l * LN(pdiff::FLOAT + 1.0) * (1.0 - e_w))::INT);

  -- RD decreases after playing
  nrd_w := GREATEST(RD_FLOOR, rd_w - RD_STEP);
  nrd_l := GREATEST(RD_FLOOR, rd_l - RD_STEP);

  RETURN QUERY SELECT
    (eff_w + d_w)::INT,
    GREATEST(100, eff_l - d_l)::INT,
    nrd_w, nrd_l,
    eff_w, eff_l;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
