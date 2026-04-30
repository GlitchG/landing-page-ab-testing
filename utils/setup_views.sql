# Setup Views for AB Testing
# Simplifies querying by creating reusable views of landing page experiment data

-- Option 1: Create a view in your own dataset (uncomment and update):
-- CREATE OR REPLACE VIEW `your_project.your_dataset.landing_page_experiments` AS
-- SELECT
--   user_pseudo_id,
--   (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
--   (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
--   event_timestamp,
--   event_name
-- FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
-- WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131';

-- Option 2: Direct query (no setup, works immediately):
-- Finds sessions with experiment landing pages
SELECT
  user_pseudo_id,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
  MIN(event_timestamp) AS session_start
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  AND event_name = 'page_view'
  AND (
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v1%'
    OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') LIKE '%/landing-v2%'
  )
GROUP BY 1, 2, 3
LIMIT 1000;

-- Helper: Classify Control vs Variant
SELECT
  user_pseudo_id,
  session_id,
  page_location,
  CASE 
    WHEN page_location LIKE '%/landing-v1%' THEN 'Control_A'
    WHEN page_location LIKE '%/landing-v2%' THEN 'Variant_B'
    ELSE 'Unknown'
  END AS experiment_variant
FROM (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name = 'page_view'
  GROUP BY 1, 2, 3
)
WHERE page_location LIKE '%/landing%'
LIMIT 100;
