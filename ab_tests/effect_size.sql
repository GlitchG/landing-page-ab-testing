-- Effect Size (Cohen's h + Absolute Risk Difference)
-- Statistical significance answers "is the difference real?"; effect size
-- answers "is the difference big enough to care about?". A +0.1pp lift can be
-- significant on huge traffic yet not worth shipping. Run this alongside
-- frequentist_ttest.sql to size the win, not just confirm it exists.
--
-- Cohen's h = 2*asin(sqrt(p_b)) - 2*asin(sqrt(p_a))
--   Rule of thumb: |h| ~ 0.2 small, ~ 0.5 medium, ~ 0.8 large.
-- Absolute risk difference = p_b - p_a (in percentage points).
-- Relative lift = (p_b - p_a) / p_a.

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';

WITH experiment_sessions AS (
  SELECT
    user_pseudo_id,
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
    MAX(CASE WHEN ev.event_name = 'purchase' THEN 1 ELSE 0 END) AS converted
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
    SUM(converted) AS conversions,
    AVG(converted) AS cr
  FROM conversions
  GROUP BY 1
),
effect AS (
  SELECT
    a.variant AS control,
    b.variant AS variant,
    a.visitors AS n_a,
    b.visitors AS n_b,
    a.cr AS p_a,
    b.cr AS p_b,
    -- Cohen's h (variance-stabilising arcsine transform)
    2 * ASIN(SQRT(b.cr)) - 2 * ASIN(SQRT(a.cr)) AS cohens_h,
    b.cr - a.cr AS risk_difference,
    SAFE_DIVIDE(b.cr - a.cr, a.cr) AS relative_lift
  FROM variant_stats a
  CROSS JOIN variant_stats b
  WHERE a.variant = 'Control_A' AND b.variant = 'Variant_B'
)
SELECT
  control,
  variant,
  n_a AS control_visitors,
  n_b AS variant_visitors,
  ROUND(p_a * 100, 2) AS control_cr_pct,
  ROUND(p_b * 100, 2) AS variant_cr_pct,
  ROUND(risk_difference * 100, 3) AS risk_difference_pp,
  ROUND(relative_lift * 100, 2) AS relative_lift_pct,
  ROUND(cohens_h, 4) AS cohens_h,
  CASE
    WHEN ABS(cohens_h) < 0.2 THEN 'Negligible (|h| < 0.2)'
    WHEN ABS(cohens_h) < 0.5 THEN 'Small (0.2 <= |h| < 0.5)'
    WHEN ABS(cohens_h) < 0.8 THEN 'Medium (0.5 <= |h| < 0.8)'
    ELSE 'Large (|h| >= 0.8)'
  END AS effect_size_label
FROM effect;
