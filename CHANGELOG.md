# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added
- `ab_tests/effect_size.sql` — Cohen's h and absolute risk difference (the README advertised it but the file was missing).
- README "Run a test, step by step" section sequencing the queries from hypothesis → sample size → SRM → primary result → effect size → guardrails → decision.

### Fixed
- `ab_tests/sample_ratio_mismatch.sql` — chi-square p-value was off by 2× (`0.5*(1+ERF(...))` returned half the upper tail); now uses `1 - ERF(sqrt(x/2))`.
- `ab_tests/guardrails.sql` — `pages_per_session` used `COUNT(DISTINCT event_name)` of a constant, so it was always 1; now `COUNTIF(event_name = 'page_view')`.
- `ab_tests/frequentist_ttest.sql` — confidence interval now uses the unpooled standard error (the pooled SE assumes the null and is only correct for the test statistic).

## [1.0.0] — 2026-05-04

### Added
- Complete A/B testing pipeline for GA4 BigQuery: page identification, experiment assignment, bounce rate comparison, and significance testing.
- SQL models for test page detection via URL pattern matching and event-level attribution.
- Compatible with the public GA4 sample dataset and production GA4 exports.

### Changed
- Session extraction updated to GA4-UI-style first-non-auto-event rule for consistent source/medium attribution.

## Related

- [ga4-attribution-models](https://github.com/GlitchG/ga4-attribution-models) — multi-touch attribution
- [ga4-bigquery-incremental](https://github.com/GlitchG/ga4-bigquery-incremental) — GA4 data pipeline patterns
- [bigquery-meridian-mmm](https://github.com/GlitchG/bigquery-meridian-mmm) — Bayesian MMM
