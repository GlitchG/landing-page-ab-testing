-- Minimum Sample Size Calculator (MDE - Minimum Detectable Effect)
-- Calculate required sample size per variant for desired statistical power
-- Uses standard formula for two-proportion Z-test

DECLARE baseline_cr FLOAT64 DEFAULT 0.02; -- 2.0% baseline conversion rate
DECLARE mde_relative FLOAT64 DEFAULT 0.15; -- 15% relative improvement (2.0% → 2.3%)
DECLARE alpha FLOAT64 DEFAULT 0.05; -- Significance level (5%)
DECLARE power FLOAT64 DEFAULT 0.80; -- Statistical power (80%)

-- Calculate absolute MDE
DECLARE mde_absolute FLOAT64 DEFAULT baseline_cr * mde_relative;
DECLARE variant_cr FLOAT64 DEFAULT baseline_cr * (1 + mde_relative);

-- Z-scores for alpha (two-tailed) and power
-- Z_alpha/2 for two-tailed: 1.96 for α=0.05
-- Z_beta for power: 0.84 for power=0.80
DECLARE z_alpha FLOAT64 DEFAULT 1.96; -- NORM.S.INV(1 - alpha/2)
DECLARE z_beta FLOAT64 DEFAULT 0.84; -- NORM.S.INV(power)

-- Pooled proportion
DECLARE p_pooled FLOAT64 DEFAULT (baseline_cr + variant_cr) / 2;

-- Sample size per variant (simplified formula)
DECLARE n_per_variant FLOAT64;

SET n_per_variant = POW(z_alpha * SQRT(2 * p_pooled * (1 - p_pooled)) + 
                      z_beta * SQRT(baseline_cr * (1 - baseline_cr) + variant_cr * (1 - variant_cr)), 2) /
                     POW(mde_absolute, 2);

SELECT
  'Sample Size Calculation' AS calculation_type,
  ROUND(baseline_cr * 100, 2) AS baseline_cr_pct,
  ROUND(variant_cr * 100, 2) AS target_cr_pct,
  ROUND(mde_relative * 100, 1) AS mde_relative_pct,
  ROUND(mde_absolute * 100, 3) AS mde_absolute_pp,
  ROUND(alpha, 2) AS alpha,
  ROUND(power, 2) AS power,
  ROUND(z_alpha, 2) AS z_alpha,
  ROUND(z_beta, 2) AS z_beta,
  ROUND(n_per_variant, 0) AS sample_size_per_variant,
  ROUND(n_per_variant * 2, 0) AS total_sample_size,
  ROUND(n_per_variant * 2 / 1000, 1) AS total_sample_size_k,
  -- Duration estimate (based on daily traffic)
  ROUND(n_per_variant * 2 / 1000, 1) AS days_at_1k_daily_traffic,
  ROUND(n_per_variant * 2 / 5000, 1) AS days_at_5k_daily_traffic,
  ROUND(n_per_variant * 2 / 10000, 1) AS days_at_10k_daily_traffic
UNION ALL
SELECT
  '--- Example Scenarios ---' AS calculation_type,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
UNION ALL
-- Scenario 1: 10% MDE
SELECT
  'Scenario: 10% MDE (smaller effect)' AS calculation_type,
  2.0 AS baseline_cr_pct,
  2.2 AS target_cr_pct,
  10.0 AS mde_relative_pct,
  0.2 AS mde_absolute_pp,
  0.05 AS alpha,
  0.80 AS power,
  1.96 AS z_alpha,
  0.84 AS z_beta,
  ROUND(POW(1.96 * SQRT(2 * 0.021 * 0.979) + 0.84 * SQRT(0.02 * 0.98 + 0.022 * 0.978), 2) / POW(0.002, 2), 0) AS sample_size_per_variant,
  NULL, NULL, NULL, NULL, NULL
UNION ALL
-- Scenario 2: 20% MDE
SELECT
  'Scenario: 20% MDE (larger effect)' AS calculation_type,
  2.0 AS baseline_cr_pct,
  2.4 AS target_cr_pct,
  20.0 AS mde_relative_pct,
  0.4 AS mde_absolute_pp,
  0.05 AS alpha,
  0.80 AS power,
  1.96 AS z_alpha,
  0.84 AS z_beta,
  ROUND(POW(1.96 * SQRT(2 * 0.022 * 0.978) + 0.84 * SQRT(0.02 * 0.98 + 0.024 * 0.976), 2) / POW(0.004, 2), 0) AS sample_size_per_variant,
  NULL, NULL, NULL, NULL, NULL;

-- Quick Reference Table
SELECT
  'QUICK REFERENCE (Baseline 2.0%)' AS info,
  '' AS value
UNION ALL
SELECT 'MDE 10% (2.0%→2.2%): ~38,000 per variant (76k total)', ''
UNION ALL
SELECT 'MDE 15% (2.0%→2.3%): ~21,400 per variant (43k total)', ''
UNION ALL
SELECT 'MDE 20% (2.0%→2.4%): ~12,200 per variant (24k total)', ''
UNION ALL
SELECT 'MDE 30% (2.0%→2.6%): ~5,400 per variant (11k total)', '';
