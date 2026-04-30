# Architecture — landing-page-ab-testing

## Stack
BigQuery, SQL (Standard SQL), dbt 1.8+, GitHub Actions CI

## Data Flow
```
GA4 raw events (BigQuery export)
    → utils/setup_views.sql (flatten landing page data)
        → landing_pages/identify_test_pages.sql (find A/B test candidates)
            → ab_tests/*.sql (statistical tests on identified variants)
                → landing_pages/bounce_rate_comparison.sql (guardrail metric)
```

The pipeline is a recommended sequence, not a strict dependency: you can run any test SQL independently against your GA4 data.

## File Map
- `hypothesis/template.md` — Markdown template for writing test hypotheses BEFORE seeing data
- `landing_pages/` — identify_test_pages.sql (find pages with A/B variants), bounce_rate_comparison.sql (guardrail metric)
- `ab_tests/` — 5 SQL files: minimum_sample_size.sql, sample_ratio_mismatch.sql, frequentist_ttest.sql, bayesian_ab_test.sql, guardrails.sql
- `utils/setup_views.sql` — flattens GA4 event_params for landing page analysis
- `dbt_project.yml` — dbt project configuration
- `.github/workflows/test-sql.yml` — CI: validates SQL syntax on every push

## Design Patterns
- **Hypothesis-first**: template.md enforces writing the hypothesis before querying data — prevents p-hacking
- **Dual statistical approach**: both Frequentist (t-test) and Bayesian — shows understanding of trade-offs to statistically-literate reviewers
- **SRM as first step**: sample_ratio_mismatch.sql runs before any effect test — catches broken randomisation early
- **Guardrail metrics**: bounce_rate_comparison.sql checks that the test variant didn't break other behaviours
