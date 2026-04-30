-- Frequentist AB Test (T-Test / Z-Test)
-- Compare conversion rates between Control (A) and Variant (B)
-- Uses standard two-proportion Z-test (approximation of T-test for large samples)

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';

-- Step 1: Identify Control (A) and Variant (B) sessions
-- Assumes experiment is tracked via page_location containing /landing-v1 (A) or /landing-v2 (B)
-- Modify the WHERE clause to match your experiment setup

WITH experiment_sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    -- Classify as Control (A) or Variant (B) based on landing page
    CASE 
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v1%' THEN 'Control_A'
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v2%' THEN 'Variant_B'
      ELSE NULL
    END AS variant,
    MIN(event_timestamp) AS session_start
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name = 'page_view'
  GROUP BY 1, 2
  HAVING variant IS NOT NULL
),
conversions AS (
  SELECT
    e.user_pseudo_id,
    e.variant,
    COUNTIF(ev.event_name = 'purchase') AS conversions
  FROM experiment_sessions e
  LEFT JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` ev
    ON e.user_pseudo_id = ev.user_pseudo_id
    AND ev.event_timestamp >= e.session_start
    AND _TABLE_SUFFIX BETWEEN start_date AND end_date
  GROUP BY 1, 2
),
variant_stats AS (
  SELECT
    variant,
    COUNT(*) AS visitors,
    SUM(conversions) AS total_conversions,
    AVG(conversions) AS conversion_rate,
    AVG(conversions) AS p, -- proportion for Z-test
    STDDEV(conversions) AS stddev
  FROM conversions
  GROUP BY 1
),
z_test_calculation AS (
  SELECT
    a.variant AS control_name,
    b.variant AS variant_name,
    a.visitors AS n_a,
    b.visitors AS n_b,
    a.total_conversions AS conversions_a,
    b.total_conversions AS conversions_b,
    a.conversion_rate AS p_a,
    b.conversion_rate AS p_b,
    -- Pooled proportion
    (a.total_conversions + b.total_conversions) / (a.visitors + b.visitors) AS p_pooled,
    -- Standard error
    SQRT(
      (a.total_conversions + b.total_conversions) / (a.visitors + b.visitors) *
      (1 - (a.total_conversions + b.total_conversions) / (a.visitors + b.visitors)) *
      (1.0/a.visitors + 1.0/b.visitors)
    ) AS se,
    -- Z-score
    (b.conversion_rate - a.conversion_rate) / 
    SQRT(
      (a.total_conversions + b.total_conversions) / (a.visitors + b.visitors) *
      (1 - (a.total_conversions + b.total_conversions) / (a.visitors + b.visitors)) *
      (1.0/a.visitors + 1.0/b.visitors)
    ) AS z_score
  FROM variant_stats a
  CROSS JOIN variant_stats b
  WHERE a.variant = 'Control_A' AND b.variant = 'Variant_B'
)
SELECT
  control_name,
  variant_name,
  n_a AS control_visitors,
  n_b AS variant_visitors,
  conversions_a AS control_conversions,
  conversions_b AS variant_conversions,
  ROUND(p_a * 100, 2) AS control_cr_pct,
  ROUND(p_b * 100, 2) AS variant_cr_pct,
  ROUND((p_b - p_a) * 100, 2) AS difference_pct_points,
  ROUND((p_b - p_a) / p_a * 100, 2) AS relative_improvement_pct,
  ROUND(z_score, 2) AS z_score,
  -- Two-tailed p-value (approximation using error function)
  ROUND(2 * (1 - 0.5 * (1 + ERF(ABS(z_score) / SQRT(2)))), 4) AS p_value_two_tailed,
  -- 95% Confidence Interval for difference
  ROUND((p_b - p_a) - 1.96 * se, 4) AS ci_lower,
  ROUND((p_b - p_a) + 1.96 * se, 4) AS ci_upper,
  -- Significance indicator
  CASE 
    WHEN ABS(z_score) > 1.96 THEN '✅ Significant (p < 0.05)'
    ELSE '❌ Not Significant (p >= 0.05)'
  END AS significance
FROM z_test_calculation;
