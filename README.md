# Landing Page AB Testing - BigQuery Portfolio

A portfolio project demonstrating **statistical rigor** in AB testing for landing page optimization using Google Analytics 4 (GA4) data in BigQuery.

---

## 🎯 What's Included

This repository showcases **proper AB testing methodology** with guardrails, hypothesis testing, and statistical validation:

### AB Test Analysis (`/ab_tests`)
| File | Description | Statistical Method |
|------|-------------|-------------------|
| **frequentist_ttest.sql** | Compare conversion rates with confidence intervals | T-test, Z-test |
| **bayesian_ab_test.sql** | Calculate probability of variant being better | Bayesian posterior |
| **sample_ratio_mismatch.sql** | Detect SRM (guardrail check) | Chi-square test |
| **guardrails.sql** | Data quality & guardrail metrics | Multiple checks |
| **minimum_sample_size.sql** | Calculate required sample size (MDE) | Power analysis |
| **effect_size.sql** | Measure practical significance | Cohen's h, Risk Difference |

### Landing Page Analysis (`/landing_pages`)
- **identify_test_pages.sql** - Find pages with experiment parameters
- **bounce_rate_comparison.sql** - Compare engagement metrics

### Hypothesis Template (`/hypothesis`)
- **template.md** - Structured hypothesis formulation

---

## 📋 Hypothesis Formulation (AB Testing Standard)

### Template:
```markdown
## Hypothesis Statement

**Primary Hypothesis (H1):**
- **If** we [change to variant B]
- **Then** [conversion rate will increase by X%]
- **Because** [psychological reason / user research insight]

**Null Hypothesis (H0):**
- No difference between control (A) and variant (B)

### Test Parameters
- **Metric:** [Primary conversion rate / CTR / Revenue]
- **Minimum Detectable Effect (MDE):** [X% relative improvement]
- **Statistical Power:** [80% typical]
- **Significance Level (α):** [0.05 typical]
- **One-tailed or Two-tailed:** [Two-tailed for AB, One-tailed for superiority]

### Guardrails (Must NOT degrade)
- Page load time < X seconds
- Bounce rate increase < X%
- Support ticket volume increase < X%

### Sample Size Required
- **Control (A):** X visitors
- **Variant (B):** X visitors
- **Total:** X visitors (calculated via `ab_tests/minimum_sample_size.sql`)
```

### Example Hypothesis:
```markdown
## Hypothesis: Simplify Hero Section

**H1:** If we simplify the hero section (reduce text by 50%, add single CTA), 
then purchase conversion rate will increase by 15% (from 2.0% to 2.3%),
because users will experience less cognitive load and clearer value proposition.

**H0:** No difference in conversion rate between current and simplified hero.

**Parameters:**
- Metric: Purchase conversion rate (events: 'purchase' / sessions)
- MDE: 15% relative improvement (0.3 percentage points)
- Power: 80%, α = 0.05, two-tailed test
- Guardrails: Page load < 2s, bounce rate increase < 5%

**Sample Size:** 21,400 per variant (42,800 total)
```

---

## 🚀 Quick Start (No GCP Keys Required!)

Dataset: `bigquery-public-data.ga4_obfuscated_sample_ecommerce` (public)

### 1. Identify Your AB Test Pages
```sql
-- Run: landing_pages/identify_test_pages.sql
-- Finds pages with experiment parameters or URL patterns like /landing-v1, /landing-v2
```

### 2. Calculate Required Sample Size
```sql
-- Run: ab_tests/minimum_sample_size.sql
-- Input: baseline conversion rate, MDE, power, alpha
-- Output: required sample size per variant
```

### 3. Run the AB Test Analysis
```sql
-- Run: ab_tests/frequentist_ttest.sql
-- Compares conversion rates between variants with confidence intervals
```

### 4. Check Guardrails (CRITICAL!)
```sql
-- Run: ab_tests/guardrails.sql
-- Ensures variant doesn't hurt secondary metrics
-- Run: ab_tests/sample_ratio_mismatch.sql
-- Detects SRM (traffic split issues)
```

---

## 🛡️ Guardrails & Quality Checks

**Always run these before interpreting test results:**

1. **Sample Ratio Mismatch (SRM)** - Is traffic split 50/50 (or target split)?
2. **Data Quality** - Are there bot traffic, missing data, or tracking issues?
3. **Guardrail Metrics** - Did bounce rate, load time, or support tickets worsen?
4. **Novelty Effects** - Run test long enough to account for learning curve
5. **Seasonality** - Ensure test period represents normal traffic patterns

---

## 📊 Example Results Interpretation

```
Variant B vs Control A:
- Conversion Rate A: 2.00% (214 / 10,700)
- Conversion Rate B: 2.35% (251 / 10,680)
- Difference: +0.35 percentage points (+17.5% relative)
- P-value: 0.012 (significant at α = 0.05)
- 95% CI: [+0.08%, +0.62%]
- Bayesian Probability B > A: 94.3%

✅ Decision: Launch Variant B (statistically significant + practical significance)
Guardrails: ✅ No degradation in bounce rate or load time
```

---

## 🎓 Why This Portfolio Stands Out

Most AB testing portfolios show **just the results**. This one demonstrates:

✅ **Proper hypothesis formulation** before looking at data  
✅ **Guardrail checks** to prevent launching harmful variants  
✅ **SRM detection** to catch technical issues  
✅ **Both Frequentist & Bayesian** approaches  
✅ **Sample size calculation** to avoid underpowered tests  
✅ **Practical significance** (not just p < 0.05)  

---

## 📚 Related Projects

- [GA4 Attribution Models](https://github.com/GlitchG/ga4-attribution-models) - Marketing attribution analysis
