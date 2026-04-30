# AB Test Hypothesis Template

> **Fill this out BEFORE looking at any data. Pre-registration prevents p-hacking.**

---

## 1. Test Overview

**Test Name:** [e.g., Hero Section Simplification - Q1 2025]

**Test URL (Control A):** `https://example.com/landing-v1`

**Test URL (Variant B):** `https://example.com/landing-v2`

**Traffic Split:** 50% A / 50% B

**Test Duration:** [e.g., 14 days, Feb 1-14, 2025]

---

## 2. Hypothesis Statement

### Primary Hypothesis (H1)
**If** we [describe the change, e.g., "simplify the hero section by reducing text 50% and showing one CTA button"],

**Then** [expected outcome, e.g., "purchase conversion rate will increase by 15% (from 2.0% to 2.3%)"],

**Because** [reasoning, e.g., "users will experience less cognitive load and the value proposition becomes clearer"].

### Null Hypothesis (H0)
There is no difference in [primary metric] between Control (A) and Variant (B).

---

## 3. Metric Definitions

### Primary Metric (Decision Metric)
- **Metric:** [e.g., Purchase Conversion Rate]
- **Definition:** `COUNT(purchase events) / COUNT(unique sessions)`
- **Baseline:** [e.g., 2.0%]
- **Target (MDE):** [e.g., 2.3% (+15% relative improvement)]

### Secondary Metrics (Guardrails - Must NOT degrade)
| Metric | Baseline | Max Acceptable Change | Current Status |
|--------|----------|---------------------|---------------|
| Bounce Rate | 45% | +5 percentage points | ✅ / ❌ |
| Page Load Time | 1.8s | +0.5s | ✅ / ❌ |
| Support Tickets | 12/week | +20% | ✅ / ❌ |
| Cart Abandonment | 68% | +5 percentage points | ✅ / ❌ |

---

## 4. Statistical Parameters

- **Significance Level (α):** [0.05 typical]
- **Statistical Power (1-β):** [80% typical]
- **Test Type:** [Two-tailed for AB, One-tailed for superiority]
- **Minimum Detectable Effect (MDE):** [15% relative, or 0.3 percentage points]
- **Required Sample Size:** [Calculated via `ab_tests/minimum_sample_size.sql`]

### Sample Size Calculation:
```
Baseline Rate: 2.0%
MDE: 0.3 percentage points (15% relative)
α = 0.05, Power = 80%, Two-tailed
→ Required: 21,400 per variant (42,800 total)
```

---

## 5. Guardrails & Risks

### What could go wrong?
- [ ] **Novelty Effect:** Users click variant out of curiosity (run test 2+ weeks)
- [ ] **SRM (Sample Ratio Mismatch):** Traffic split not 50/50 (check `ab_tests/sample_ratio_mismatch.sql`)
- [ ] **Seasonality:** Test during normal period (avoid holidays/Black Friday)
- [ ] **Bot Traffic:** Filter invalid traffic in query
- [ ] **Cross-Device Issues:** Users switching devices mid-funnel

### Guardrail Checks (Run before decision):
```sql
-- 1. Check SRM
RUN ab_tests/sample_ratio_mismatch.sql

-- 2. Check guardrail metrics
RUN ab_tests/guardrails.sql

-- 3. Verify data quality
RUN ab_tests/data_quality_check.sql
```

---

## 6. Decision Framework

### Launch Variant B IF:
- ✅ Primary metric is statistically significant (p < 0.05)
- ✅ Practical significance achieved (MDE reached)
- ✅ Guardrail metrics not degraded
- ✅ No SRM detected
- ✅ Test ran long enough (2+ weeks minimum)

### Do NOT Launch IF:
- ❌ Only statistically significant but not practically significant
- ❌ Guardrail metrics degraded (even if primary metric improved)
- ❌ SRM detected (technical issue with test setup)
- ❌ Novelty effect suspected (check day-by-day conversion trend)

---

## 7. Results (Fill After Test)

### Primary Metric Results:
- **Conversion Rate A:** [%] (count / visitors)
- **Conversion Rate B:** [%] (count / visitors)
- **Difference:** [percentage points] ([%] relative)
- **P-value:** [p-value]
- **95% Confidence Interval:** [lower, upper]
- **Bayesian Probability B > A:** [%]

### Decision:
[ ] Launch Variant B  
[ ] Keep Control A  
[ ] Run Follow-up Test  
[ ] Invalid Test (SRM/Guardrail failure)

### Why:
[Explain decision based on statistical + practical significance + guardrails]

---

## Pre-Registration Checklist

- [ ] Hypothesis written BEFORE viewing data
- [ ] Sample size calculated BEFORE starting test
- [ ] Guardrail metrics defined BEFORE starting test
- [ ] Decision framework defined BEFORE starting test
- [ ] Stored in this file for audit trail

---

*This template ensures rigorous AB testing methodology. No p-hacking, no cherry-picking results.*
