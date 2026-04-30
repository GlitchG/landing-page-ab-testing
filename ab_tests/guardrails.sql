-- Guardrail Metrics Check
-- Ensures variant doesn't hurt secondary metrics (bounce rate, load time, etc.)
-- Run BEFORE making a launch decision

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';

WITH experiment_sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
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
session_metrics AS (
  SELECT
    e.variant,
    e.session_id,
    e.user_pseudo_id,
    -- Bounce: single page session (only 1 page_view event)
    CASE 
      WHEN COUNTIF(ev.event_name = 'page_view') = 1 THEN 1 
      ELSE 0 
    END AS is_bounce,
    -- Session duration
    ROUND((MAX(ev.event_timestamp) - MIN(ev.event_timestamp)) / (1000000 * 60), 2) AS session_duration_min,
    -- Pages per session
    COUNT(DISTINCT CASE WHEN ev.event_name = 'page_view' THEN ev.event_name END) AS pages_per_session,
    -- Cart abandonment (added to cart but no purchase)
    MAX(CASE WHEN ev.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
    MAX(CASE WHEN ev.event_name = 'purchase' THEN 1 ELSE 0 END) AS purchased,
    -- Engagement: scroll, click, etc.
    COUNTIF(ev.event_name IN ('scroll', 'click', 'view_item')) AS engagement_events
  FROM experiment_sessions e
  LEFT JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` ev
    ON e.user_pseudo_id = ev.user_pseudo_id
    AND ev.event_timestamp >= e.session_start
    AND _TABLE_SUFFIX BETWEEN start_date AND end_date
  GROUP BY 1, 2, 3
),
guardrail_stats AS (
  SELECT
    variant,
    COUNT(DISTINCT user_pseudo_id) AS sessions,
    -- Bounce rate
    ROUND(AVG(is_bounce) * 100, 2) AS bounce_rate_pct,
    -- Avg session duration
    ROUND(AVG(session_duration_min), 2) AS avg_session_duration_min,
    -- Avg pages per session
    ROUND(AVG(pages_per_session), 2) AS avg_pages_per_session,
    -- Cart abandonment rate
    ROUND(SUM(CASE WHEN added_to_cart = 1 AND purchased = 0 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(added_to_cart), 0), 2) AS cart_abandonment_rate_pct,
    -- Avg engagement events
    ROUND(AVG(engagement_events), 2) AS avg_engagement_events
  FROM session_metrics
  GROUP BY 1
)
SELECT
  a.variant AS control,
  b.variant AS variant,
  a.sessions AS control_sessions,
  b.sessions AS variant_sessions,
  -- Bounce rate comparison
  a.bounce_rate_pct AS control_bounce_pct,
  b.bounce_rate_pct AS variant_bounce_pct,
  ROUND(b.bounce_rate_pct - a.bounce_rate_pct, 2) AS bounce_rate_diff_pct,
  CASE WHEN b.bounce_rate_pct > a.bounce_rate_pct + 5 THEN '❌ FAIL: Bounce rate +5pp' ELSE '✅ PASS' END AS bounce_check,
  -- Session duration comparison
  a.avg_session_duration_min AS control_duration_min,
  b.avg_session_duration_min AS variant_duration_min,
  ROUND(b.avg_session_duration_min - a.avg_session_duration_min, 2) AS duration_diff_min,
  CASE WHEN b.avg_session_duration_min < a.avg_session_duration_min * 0.8 THEN '❌ FAIL: Duration -20%' ELSE '✅ PASS' END AS duration_check,
  -- Cart abandonment comparison
  a.cart_abandonment_rate_pct AS control_cart_abandon_pct,
  b.cart_abandonment_rate_pct AS variant_cart_abandon_pct,
  ROUND(b.cart_abandonment_rate_pct - a.cart_abandonment_rate_pct, 2) AS cart_diff_pct,
  CASE WHEN b.cart_abandonment_rate_pct > a.cart_abandonment_rate_pct + 10 THEN '❌ FAIL: Abandonment +10pp' ELSE '✅ PASS' END AS cart_check
FROM guardrail_stats a
CROSS JOIN guardrail_stats b
WHERE a.variant = 'Control_A' AND b.variant = 'Variant_B';

-- Summary
SELECT 'GUARDRAIL CHECK SUMMARY' AS check_type, '' AS result UNION ALL
SELECT 'Bounce Rate: Variant should NOT increase > 5pp' AS check_type, '' AS result UNION ALL
SELECT 'Session Duration: Variant should NOT decrease > 20%' AS check_type, '' AS result UNION ALL
SELECT 'Cart Abandonment: Variant should NOT increase > 10pp' AS check_type, '' AS result UNION ALL
SELECT 'If any ❌ FAIL: DO NOT LAUNCH (even if primary metric is significant)' AS check_type, '' AS result;
