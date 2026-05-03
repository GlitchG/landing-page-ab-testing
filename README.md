### Landing Page AB Testing — SQL Templates

A set of SQL templates for AB test analysis on GA4 BigQuery data: power analysis, t-test, Bayesian comparison, SRM detection, guardrails.

#### A note on the dataset

The repo runs against `bigquery-public-data.ga4_obfuscated_sample_ecommerce`, which has no actual AB test variants in it. If you run the queries as-is, you'll get empty results or `p = 1.0` — which is the correct answer when there are no variants. The value here is the **methodology and the SQL patterns**, not a worked example. To actually use it, point each query at your own GA4 export and replace the placeholder URL patterns (`/landing-v1`, `/landing-v2`) with whatever scheme your test uses to identify variants.

#### What's in here

| File | What it does |
|---|---|
| `ab_tests/minimum_sample_size.sql` | Calculate required N per variant given a target MDE. Run before launching the test. |
| `ab_tests/frequentist_ttest.sql` | Two-proportion test on conversion rate. Returns CR per variant, lift, p-value, 95% CI. |
| `ab_tests/bayesian_ab_test.sql` | Posterior P(B > A) from a Beta-Binomial conjugate prior. Easier to communicate to non-statisticians than p-values. |
| `ab_tests/sample_ratio_mismatch.sql` | Chi-square test on the actual traffic split. If it's not what you set, the test is invalid regardless of what the primary metric says. |
| `ab_tests/guardrails.sql` | Secondary metrics check — bounce rate, session duration, cart abandonment. If any regress, the variant doesn't ship even if the primary metric won. |
| `ab_tests/effect_size.sql` | Cohen's h and absolute risk difference, so you can argue about whether a +0.1pp lift is worth shipping. |
| `landing_pages/identify_test_pages.sql` | Find pages with experiment URL parameters or naming patterns. |
| `landing_pages/bounce_rate_comparison.sql` | Engagement comparison between variants. |
| `hypothesis/template.md` | Pre-test hypothesis template. Filling this in before looking at data is the cheapest insurance against p-hacking. |

#### Why these specific things

The frequentist + Bayesian split is intentional. P-values are what you put in the doc; "94% probability B is better" is what you say in the meeting. Both come from the same data.

SRM is the one most analyst portfolios skip and the one that invalidates the most real-world tests I've seen. If your test bucketing is broken, none of the rest matters.

Guardrails are similarly underweighted. A +15% conversion lift that comes with a +20% bounce rate is usually a bug, not a win. The principle here is the same as running multiple attribution models: agreement across signals is the actual evidence.

#### Running it

```
git clone https://github.com/GlitchG/landing-page-ab-testing.git
cd landing-page-ab-testing
```

Open any `.sql` file, paste into the [BigQuery console](https://console.cloud.google.com/bigquery), and run. To use it with your own data: change the dataset name at the top and replace the variant URL patterns.

#### Related

- [ga4-attribution-models](https://github.com/GlitchG/ga4-attribution-models) — same dataset, attribution rather than experimentation
- [cohort-log-predict](https://github.com/GlitchG/cohort-log-predict) — retention prediction from two data points

MIT
