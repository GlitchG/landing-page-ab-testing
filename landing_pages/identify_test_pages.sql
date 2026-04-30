-- Identify Landing Page Test Pages
-- Finds pages that are likely part of AB tests (URL patterns, experiment params)
-- Useful for discovering which pages to include in your test analysis

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';

-- Method 1: Find pages with variant-like URL patterns
WITH url_patterns AS (
  SELECT
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
    COUNT(DISTINCT user_pseudo_id) AS unique_users,
    COUNT(*) AS pageviews,
    COUNTIF(event_name = 'purchase') AS conversions,
    ROUND(COUNTIF(event_name = 'purchase') * 100.0 / COUNT(DISTINCT user_pseudo_id), 2) AS cr_pct
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name IN ('page_view', 'purchase')
    -- Look for common AB test URL patterns
    AND (
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing%'
      OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/v1%'
      OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/v2%'
      OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%?variant=%'
      OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%?test=%'
      OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%?exp=%'
    )
  GROUP BY 1
  ORDER BY unique_users DESC
  LIMIT 50
)
SELECT * FROM url_patterns

UNION ALL

-- Method 2: Find pages with experiment-related event parameters
SELECT
  '--- Pages with experiment parameters ---' AS page_location,
  NULL AS unique_users,
  NULL AS pageviews,
  NULL AS conversions,
  NULL AS cr_pct

UNION ALL

SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
  COUNT(DISTINCT user_pseudo_id) AS unique_users,
  COUNT(*) AS pageviews,
  COUNTIF(event_name = 'purchase') AS conversions,
  ROUND(COUNTIF(event_name = 'purchase') * 100.0 / COUNT(DISTINCT user_pseudo_id), 2) AS cr_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
  AND event_name = 'page_view'
  -- Check for experiment-related parameters in ANY event parameter
  AND EXISTS (
    SELECT 1 FROM UNNEST(event_params) 
    WHERE key IN ('experiment_id', 'variant', 'test_id', 'ab_test')
  )
GROUP BY 1
ORDER BY unique_users DESC
LIMIT 50;

-- Summary: Most common landing page patterns
SELECT
  'SUMMARY: Top Landing Page Patterns' AS info,
  '' AS value

UNION ALL

SELECT
  CONCAT('Pattern: /landing-v1 vs /landing-v2 → Use control/variant classification in queries'),
  ''

UNION ALL

SELECT
  CONCAT('Pattern: ?variant=A vs ?variant=B → Extract variant from page_location'),
  ''

UNION ALL

SELECT
  CONCAT('If no clear pattern → Check if experiment params are passed via GA4 event_params'),
  '';
