-- Sample Ratio Mismatch (SRM) Detection
-- CRITICAL GUARDRAIL: Detects if traffic split matches target (e.g., 50/50)
-- If p < 0.01, there's likely a technical issue with the test setup

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';
DECLARE expected_ratio FLOAT64 DEFAULT 0.5; -- 50/50 split

WITH experiment_sessions AS (
  SELECT
    user_pseudo_id,
    CASE 
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v1%' THEN 'Control_A'
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v2%' THEN 'Variant_B'
      ELSE 'Unknown'
    END AS variant
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name = 'page_view'
),
variant_counts AS (
  SELECT
    variant,
    COUNT(DISTINCT user_pseudo_id) AS user_count
  FROM experiment_sessions
  WHERE variant IN ('Control_A', 'Variant_B')
  GROUP BY 1
),
total AS (
  SELECT SUM(user_count) AS total_users FROM variant_counts
),
chi_square_calc AS (
  SELECT
    v.variant,
    v.user_count AS observed,
    t.total_users * expected_ratio AS expected,
    -- Chi-square component: (observed - expected)^2 / expected
    POW(v.user_count - (t.total_users * expected_ratio), 2) / (t.total_users * expected_ratio) AS chi_square_component
  FROM variant_counts v
  CROSS JOIN total t
)
SELECT
  variant,
  observed AS users,
  ROUND(expected, 0) AS expected_users,
  ROUND(observed / (SELECT total_users FROM total) * 100, 1) AS actual_pct,
  ROUND(expected_ratio * 100, 1) AS expected_pct,
  ROUND(chi_square_component, 2) AS chi_square_component
FROM chi_square_calc
CROSS JOIN total t;

-- Chi-square test result
WITH experiment_sessions AS (
  SELECT
    CASE 
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v1%' THEN 'Control_A'
      WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v2%' THEN 'Variant_B'
      ELSE 'Unknown'
    END AS variant
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name = 'page_view'
),
variant_counts AS (
  SELECT
    variant,
    COUNT(DISTINCT user_pseudo_id) AS user_count
  FROM experiment_sessions
  WHERE variant IN ('Control_A', 'Variant_B')
  GROUP BY 1
),
total AS (
  SELECT SUM(user_count) AS total_users FROM variant_counts
)
SELECT
  'SRM Test Result' AS test_name,
  (SELECT SUM(POW(v.user_count - (t.total_users * expected_ratio), 2) / (t.total_users * expected_ratio)) 
   FROM variant_counts v CROSS JOIN total t) AS chi_square_statistic,
  1 AS degrees_of_freedom, -- 2 groups - 1
  -- P-value (approximation for chi-square with 1 df)
  ROUND(1 - 0.5 * (1 + ERF(SQRT(
    (SELECT SUM(POW(v.user_count - (t.total_users * expected_ratio), 2) / (t.total_users * expected_ratio)) 
     FROM variant_counts v CROSS JOIN total t) / 2
  ))), 4) AS p_value,
  CASE 
    WHEN (SELECT SUM(POW(v.user_count - (t.total_users * expected_ratio), 2) / (t.total_users * expected_ratio)) 
          FROM variant_counts v CROSS JOIN total t) > 6.63 
    THEN '❌ SRM DETECTED (p < 0.01) - DO NOT TRUST TEST RESULTS'
    WHEN (SELECT SUM(POW(v.user_count - (t.total_users * expected_ratio), 2) / (t.total_users * expected_ratio)) 
          FROM variant_counts v CROSS JOIN total t) > 3.84 
    THEN '⚠️ Possible SRM (p < 0.05) - Investigate'
    ELSE '✅ No SRM detected (p >= 0.05)'
  END AS srm_result
FROM total
LIMIT 1;
