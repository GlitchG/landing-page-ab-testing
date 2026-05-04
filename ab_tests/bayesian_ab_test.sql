-- Bayesian AB Test (Normal Approximation)
-- Calculate probability that Variant B is better than Control A
-- Uses Beta priors with normal approximation for the posterior difference
-- Note: BigQuery does not have built-in Beta CDF or Monte Carlo sampling.
--       The probability below uses a normal approximation of the Beta
--       posterior difference, which is accurate for sample sizes > 30.

DECLARE start_date STRING DEFAULT '20210101';
DECLARE end_date STRING DEFAULT '20210131';

-- Bayesian approach: Beta(alpha, beta) distribution for conversion rates
-- alpha = conversions + 1 (prior), beta = non-conversions + 1 (prior)
-- Using uninformative prior Beta(1,1) = Uniform distribution

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
    AVG(converted) AS observed_cr,
    -- Bayesian parameters (Beta distribution)
    SUM(converted) + 1 AS alpha, -- conversions + prior
    COUNT(*) - SUM(converted) + 1 AS beta -- non-conversions + prior
  FROM conversions
  GROUP BY 1
),
-- Normal approximation of P(Beta_B > Beta_A)
-- Each Beta(alpha, beta) is approximated as Normal(mu, sigma^2):
--   mu = alpha / (alpha + beta)
--   sigma^2 = alpha*beta / ((alpha+beta)^2 * (alpha+beta+1))
-- P(B > A) = Phi((mu_B - mu_A) / sqrt(sigma_A^2 + sigma_B^2))
probability_calc AS (
  SELECT
    a.variant AS control,
    b.variant AS variant,
    a.visitors AS n_a,
    b.visitors AS n_b,
    a.conversions AS conv_a,
    b.conversions AS conv_b,
    a.observed_cr AS cr_a,
    b.observed_cr AS cr_b,
    a.alpha AS alpha_a,
    a.beta AS beta_a,
    b.alpha AS alpha_b,
    b.beta AS beta_b,
    ROUND(
      0.5 * (1 + ERF(
        ( (b.alpha / (b.alpha + b.beta)) - (a.alpha / (a.alpha + a.beta)) ) /
        SQRT(
          (b.alpha * b.beta) / POW(b.alpha + b.beta, 2) / (b.alpha + b.beta + 1) +
          (a.alpha * a.beta) / POW(a.alpha + a.beta, 2) / (a.alpha + a.beta + 1)
        ) / SQRT(2)
      )),
      4
    ) AS prob_b_better_than_a
  FROM variant_stats a
  CROSS JOIN variant_stats b
  WHERE a.variant = 'Control_A' AND b.variant = 'Variant_B'
)
SELECT
  control,
  variant,
  n_a AS control_visitors,
  n_b AS variant_visitors,
  conv_a AS control_conversions,
  conv_b AS variant_conversions,
  ROUND(cr_a * 100, 2) AS control_cr_pct,
  ROUND(cr_b * 100, 2) AS variant_cr_pct,
  ROUND((cr_b - cr_a) * 100, 2) AS difference_pct_points,
  prob_b_better_than_a AS probability_b_better,
  ROUND(prob_b_better_than_a * 100, 1) AS probability_b_better_pct,
  CASE 
    WHEN prob_b_better_than_a > 0.95 THEN 'Strong evidence for Variant B (P > 95%)'
    WHEN prob_b_better_than_a > 0.90 THEN 'Moderate evidence for Variant B (P > 90%)'
    WHEN prob_b_better_than_a < 0.10 THEN 'Strong evidence for Control A (P(B) < 10%)'
    WHEN prob_b_better_than_a BETWEEN 0.40 AND 0.60 THEN 'Inconclusive (P ~ 50%)'
    ELSE 'Weak evidence, continue test'
  END AS bayesian_decision
FROM probability_calc;
