{% macro ga4_session_source(event_table) %}
-- GA4-UI-style first-non-auto-event source extraction with session_start fallback.
-- Use this macro in any model that needs session-level source/medium from GA4 events.

WITH session_event_traffic AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_timestamp,
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS source,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS medium
  FROM {{ event_table }}
  WHERE (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') IS NOT NULL
),
session_traffic_resolved AS (
  SELECT
    user_pseudo_id,
    session_id,
    ARRAY_AGG(
      STRUCT(source, medium, event_timestamp)
      ORDER BY
        CASE WHEN event_name NOT IN ('session_start', 'first_visit') AND (source IS NOT NULL OR medium IS NOT NULL) THEN 0 ELSE 1 END,
        CASE WHEN event_name = 'session_start' AND (source IS NOT NULL OR medium IS NOT NULL) THEN 0 ELSE 1 END,
        event_timestamp
    )[SAFE_OFFSET(0)] AS resolved_traffic
  FROM session_event_traffic
  GROUP BY 1, 2
)
SELECT
  user_pseudo_id,
  session_id,
  TIMESTAMP_MICROS(resolved_traffic.event_timestamp) AS session_start,
  COALESCE(resolved_traffic.source, '(direct)') AS source,
  COALESCE(resolved_traffic.medium, '(none)') AS medium,
  CASE
    WHEN COALESCE(resolved_traffic.medium, '(none)') IN ('cpc', 'ppc', 'paidsearch') THEN 'Paid Search'
    WHEN COALESCE(resolved_traffic.medium, '(none)') = 'organic' THEN 'Organic Search'
    WHEN LOWER(COALESCE(resolved_traffic.medium, '')) LIKE '%social%' THEN 'Social'
    WHEN COALESCE(resolved_traffic.medium, '(none)') = 'email' THEN 'Email'
    WHEN COALESCE(resolved_traffic.medium, '(none)') IN ('display', 'banner') THEN 'Display'
    WHEN COALESCE(resolved_traffic.medium, '(none)') = 'referral' THEN 'Referral'
    WHEN COALESCE(resolved_traffic.medium, '(none)') = 'affiliate' THEN 'Affiliate'
    WHEN COALESCE(resolved_traffic.medium, '(none)') IN ('(none)', '') THEN 'Direct'
    ELSE CONCAT(COALESCE(resolved_traffic.source, '(direct)'), ' / ', COALESCE(resolved_traffic.medium, '(none)'))
  END AS channel
FROM session_traffic_resolved
{% endmacro %}
