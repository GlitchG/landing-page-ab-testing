### Landing Page AB Testing — SQL Templates

A **dbt** project with SQL templates for AB test analysis on GA4 BigQuery data: power analysis, t-test, Bayesian comparison, SRM detection, guardrails. Templates can also be run standalone — paste into the BigQuery console.

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

#### Run a test, step by step

The files are meant to be run in this order — before, during, and after the experiment. Each is a standalone query; the only thing to wire up is the variant URL patterns (`/landing-v1`, `/landing-v2`) and, on your own data, the dataset name and `start_date` / `end_date`.

**Before you launch**

1. **Write the hypothesis.** Fill in [`hypothesis/template.md`](hypothesis/template.md) — the metric, the expected direction, the minimum effect worth shipping. Doing this before you see data is the cheapest defence against p-hacking.
2. **Size the test.** Run [`ab_tests/minimum_sample_size.sql`](ab_tests/minimum_sample_size.sql) with your baseline conversion rate and target MDE. It tells you how many visitors per variant you need and roughly how long that takes at your traffic. If the answer is "longer than you'll wait," shrink the scope now, not later.

**While it runs**

3. **Confirm the variants are tracked.** Run [`landing_pages/identify_test_pages.sql`](landing_pages/identify_test_pages.sql) to check your test pages actually show up with the URL patterns you expect.
4. **Validate the split — first.** Run [`ab_tests/sample_ratio_mismatch.sql`](ab_tests/sample_ratio_mismatch.sql). If it flags SRM (p < 0.01), the bucketing is broken and **nothing downstream is trustworthy** — stop and fix the assignment before reading any result.

**After it reaches sample size**

5. **Read the primary result.** Run [`ab_tests/frequentist_ttest.sql`](ab_tests/frequentist_ttest.sql) for the p-value and confidence interval, and/or [`ab_tests/bayesian_ab_test.sql`](ab_tests/bayesian_ab_test.sql) for P(B > A). The p-value goes in the doc; "B is better with 94% probability" is what you say in the meeting.
6. **Size the effect.** A significant result still has to be *big enough*. Run [`ab_tests/effect_size.sql`](ab_tests/effect_size.sql) for Cohen's h and the absolute risk difference, then compare against the "minimum effect worth shipping" you wrote down in step 1.
7. **Check the guardrails.** Run [`ab_tests/guardrails.sql`](ab_tests/guardrails.sql) (and [`landing_pages/bounce_rate_comparison.sql`](landing_pages/bounce_rate_comparison.sql)) for bounce rate, session duration, and cart abandonment. A primary-metric win that regresses a guardrail is usually a bug, not a win.

**Decision rule:** ship only when all four hold — the result is significant, the effect clears your threshold, no guardrail regresses, and there's no SRM. If any one fails, don't launch.

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
