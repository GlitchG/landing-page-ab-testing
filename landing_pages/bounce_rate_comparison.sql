-- Bounce Rate Comparison (Landing Pages)
-- Compare engagement metrics between Control (A) and Variant (B)

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
session_events AS (
  SELECT
    e.user_pseudo_id,
    e.session_id,
    e.variant,
    ev.event_name,
    ev.event_timestamp
  FROM experiment_sessions e
  LEFT JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` ev
    ON e.user_pseudo_id = ev.user_pseudo_id
    AND ev.event_timestamp >= e.session_start
    AND _TABLE_SUFFIX BETWEEN start_date AND end_date
),
session_metrics AS (
  SELECT
    variant,
    session_id,
    COUNTIF(event_name = 'page_view') AS pageviews,
    COUNTIF(event_name = 'scroll') AS scrolls,
    COUNTIF(event_name = 'click') AS clicks,
    COUNTIF(event_name = 'purchase') AS purchases,
    -- Bounce: single page view
    CASE WHEN COUNTIF(event_name = 'page_view') = 1 THEN 1 ELSE 0 END AS is_bounce,
    -- Session duration (minutes)
    ROUND((MAX(event_timestamp) - MIN(event_timestamp)) / (1000000 * 60), 2) AS duration_min
  FROM session_events
  GROUP BY 1, 2, 3
)
SELECT
  variant,
  COUNT(DISTINCT session_id) AS sessions,
  -- Bounce rate
  ROUND(AVG(is_bounce) * 100, 2) AS bounce_rate_pct,
  -- Avg pageviews per session
  ROUND(AVG(pageviews), 2) AS avg_pageviews,
  -- Avg duration
  ROUND(AVG(duration_min), 2) AS avg_duration_min,
  -- Engagement rate (non-bounce)
  ROUND((1 - AVG(is_bounce)) * 100, 2) AS engagement_rate_pct,
  -- Click-through rate
  ROUND(COUNTIF(clicks > 0) * 100.0 / COUNT(*), 2) AS click_rate_pct,
  -- Purchase conversion rate
  ROUND(COUNTIF(purchases > 0) * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM session_metrics
GROUP BY 1
ORDER BY 1;

-- Comparison
WITH metrics AS (
  SELECT
    variant,
    COUNT(DISTINCT session_id) AS sessions,
    AVG(is_bounce) AS bounce_rate,
    AVG(pageviews) AS avg_pageviews,
    AVG(duration_min) AS avg_duration_min
  FROM (
    SELECT
      e.variant,
      e.session_id,
      CASE WHEN COUNTIF(ev.event_name = 'page_view') = 1 THEN 1 ELSE 0 END AS is_bounce,
      COUNTIF(ev.event_name = 'page_view') AS pageviews,
      ROUND((MAX(ev.event_timestamp) - MIN(ev.event_timestamp)) / (1000000 * 60), 2) AS duration_min
    FROM experiment_sessions e
    LEFT JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` ev
      ON e.user_pseudo_id = ev.user_pseudo_id
      AND ev.event_timestamp >= e.session_start
      AND _TABLE_SUFFIX BETWEEN start_date AND end_date
    GROUP BY 1, 2, 3
  )
  GROUP BY 1
),
comparison AS (
  SELECT
    a.bounce_rate AS control_bounce,
    b.bounce_rate AS variant_bounce,
    b.bounce_rate - a.bounce_rate AS bounce_diff,
    a.avg_pageviews AS control_pageviews,
    b.avg_pageviews AS variant_pageviews,
    b.avg_pageviews - a.avg_pageviews AS pageviews_diff
  FROM metrics a
  CROSS JOIN metrics b
  WHERE a.variant = 'Control_A' AND b.variant = 'Variant_B'
)
SELECT
  ROUND(control_bounce * 100, 2) AS control_bounce_pct,
  ROUND(variant_bounce * 100, 2) AS variant_bounce_pct,
  ROUND(bounce_diff * 100, 2) AS bounce_diff_pct_points,
  CASE WHEN variant_bounce < control_bounce THEN '✅ Variant better (lower is better)' ELSE '❌ Variant worse' END AS bounce_verdict,
  ROUND(control_pageviews, 2) AS control_pageviews,
  ROUND(variant_pageviews, 2) AS variant_pageviews,
  ROUND(pageviews_diff, 2) AS pageviews_diff,
  CASE WHEN variant_pageviews > control_pageviews THEN '✅ Variant better (higher is better)' ELSE '❌ Variant worse' END AS pageviews_verdict
FROM comparison;
