# Architecture Decisions — landing-page-ab-testing

> Every decision with rationale and trade-offs.

## Decision Log

| Date | Decision | Rationale | Trade-offs |
|------|----------|-----------|------------|
| 2026-04 | Frequentist + Bayesian | Shows statistical breadth to hiring managers. Frequentist is standard in industry; Bayesian is increasingly demanded. | More code to maintain. Bayesian requires priors — poorly chosen priors give misleading results. |
| 2026-04 | SRM check before effect test | Sample Ratio Mismatch is the most common A/B test failure mode. Checking it first prevents wasting time on broken tests. | Adds a step. Some analysts skip this — this repo makes it non-negotiable. |
| 2026-04 | Hypothesis template in Markdown | Enforces discipline: write hypothesis before querying. Prevents p-hacking and data dredging. | Not enforceable programmatically — relies on analyst discipline. |
| 2026-04 | BigQuery-only, no Python | Same rationale as ga4-attribution-models: SQL is the lingua franca of marketing analytics. | Bayesian model is limited to what you can express in SQL. |
| 2026-04 | Guardrail metrics separate from main test | Bounce rate and other guardrails are separate queries — you check them after the main test, not inline. Cleaner code, clearer intent. | Requires running multiple queries. |
| 2026-04-30 | .brain/ folder added | AI agent context: agents read .brain/index.md first. No back-and-forth about project state. | Extra files. |
