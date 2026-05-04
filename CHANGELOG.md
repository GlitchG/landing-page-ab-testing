# Changelog

All notable changes to this project are documented in this file.

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
