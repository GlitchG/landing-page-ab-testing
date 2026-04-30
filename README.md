# Landing Page AB Testing - BigQuery Portfolio (2026)

A portfolio project demonstrating **statistical rigor** in AB testing for landing page optimization using Google Analytics 4 (GA4) data in BigQuery. 

**Designed for:** Marketing analysts, data scientists, hiring managers — **zero prerequisites** required. Just a free Google account.

---

## 🎯 **What is AB Testing? (For Rookies)**

Imagine you have a landing page with a "Buy Now" button. You think changing the button color from **blue to green** might increase purchases.

**AB Test Setup:**
- **Variant A (Control):** Blue button (current version)
- **Variant B (Test):** Green button (new version)
- **Traffic Split:** 50% see blue, 50% see green
- **Goal:** Measure which version gets more purchases

**The Problem:** Most people stop at "Variant B got 15% more conversions!" — but that's not enough. You need:
1. **Statistical significance** (is this real, or random luck?)
2. **Guardrails** (did the green button break something else?)
3. **SRM detection** (was the 50/50 split actually 50/50?)

This repository shows you how to do it **right**.

---

## 📋 **AB Testing Process (Step-by-Step)**

### Step1: Write Your Hypothesis (BEFORE seeing data!)
```markdown
## Hypothesis Statement

**If** we change the button from blue to green,
**Then** purchase conversion rate will increase by 15% (from 2.0% to 2.3%),
**Because** green creates more visual contrast and draws attention.

**Null Hypothesis (H0):** No difference between blue and green buttons.
```
→ Use the template in `hypothesis/template.md`

### Step2: Calculate Required Sample Size
→ Run: `ab_tests/minimum_sample_size.sql`
- Tells you how many visitors you need (to avoid underpowered tests)
- Example: 21,400 per variant for 15% MDE (Minimum Detectable Effect)

### Step3: Run the Test
- Split traffic 50/50 between variants
- Run for 2+ weeks (avoid novelty effects)
- Collect data in GA4

### Step4: Analyze Results
→ Run: `ab_tests/frequentist_ttest.sql`
- Get p-value, confidence intervals, statistical significance

→ Run: `ab_tests/bayesian_ab_test.sql`
- Get probability that B > A (e.g., "94% chance green is better")

### Step5: Check Guardrails (CRITICAL!)
→ Run: `ab_tests/guardrails.sql`
- Bounce rate didn't increase?
- Page load time didn't worsen?
- Cart abandonment didn't spike?

→ Run: `ab_tests/sample_ratio_mismatch.sql`
- Detect SRM (Sample Ratio Mismatch) — is traffic ACTUALLY 50/50?

### Step6: Make Decision
- ✅ Significant + guardrails pass → Launch Variant B
- ❌ Not significant → Keep Control A
- ❌ Guardrails fail → Do NOT launch (even if primary metric improved!)

---

## 📊 **What's Included (6 SQL Files + Template)**

### AB Test Analysis (`/ab_tests`)

| File | What It Does | Statistical Method | When to Use |
|------|-------------|-------------------|-------------|
| **frequentist_ttest.sql** | Compare conversion rates with p-values & confidence intervals | T-test, Z-test | Standard AB test analysis |
| **bayesian_ab_test.sql** | Calculate probability that Variant B is better | Bayesian posterior | When you want "94% chance B wins" interpretation |
| **sample_ratio_mismatch.sql** | Detect SRM (traffic split issues) — **GUARDRAIL** | Chi-square test | ALWAYS run this (detects technical issues) |
| **guardrails.sql** | Check secondary metrics (bounce, duration, cart abandon) — **GUARDRAIL** | Multiple checks | ALWAYS run before launching |
| **minimum_sample_size.sql** | Calculate required sample size (MDE) | Power analysis | Run BEFORE starting the test |
| **effect_size.sql** | Measure practical significance (not just p < 0.05) | Cohen's h, Risk Difference | Ensure the improvement matters in real life |

### Landing Page Analysis (`/landing_pages`)
- **identify_test_pages.sql** - Find pages with experiment parameters or URL patterns
- **bounce_rate_comparison.sql** - Compare engagement metrics between variants

### Hypothesis Template (`/hypothesis`)
- **template.md** - Structured hypothesis formulation (fill BEFORE looking at data)

---

## 🚀 **Quick Start (No GCP Keys Required!)**

Dataset: `bigquery-public-data.ga4_obfuscated_sample_ecommerce` (public — free to query)

### **Option 1: Run in BigQuery Console (2 minutes, zero setup)**

1. **Open BigQuery Console:** https://console.cloud.google.com/bigquery
   - Sign in with any Google account
   - Create a project if prompted (free, 10 seconds)

2. **Copy SQL file content:**
   - Go to: https://github.com/GlitchG/landing-page-ab-testing
   - Click `ab_tests/frequentist_ttest.sql`
   - Click "Raw" button → Copy entire content

3. **Paste into BigQuery Query Editor** and click "Run"
   - Results show conversion rates, p-value, confidence intervals

4. **Understand your results:**
   - `control_cr_pct` = Conversion rate for Variant A (Control)
   - `variant_cr_pct` = Conversion rate for Variant B
   - `p_value_two_tailed` = Statistical significance (p < 0.05 = significant)
   - `significance` = ✅ Significant or ❌ Not Significant

### **Option 2: Clone & Explore Locally**
```bash
git clone https://github.com/GlitchG/landing-page-ab-testing.git
cd landing-page-ab-testing
```
Open any `.sql` file and paste into BigQuery Console.

---

## 🛡️ **Guardrails & Quality Checks (Why They Matter)**

### **1. Sample Ratio Mismatch (SRM) — The Silent Killer**
**Problem:** You think traffic is split 50/50, but it's actually 52/48 due to a technical bug.
**Consequence:** Your test results are INVALID (even if p < 0.05).
**Solution:** Run `sample_ratio_mismatch.sql` — if p < 0.01, **kill the test**.

**Real-world example:**
- Variant B shows +20% conversions (p = 0.03)
- SRM test reveals 52% went to A, 48% to B
- **Decision:** Test is invalid, re-run with proper split

### **2. Guardrail Metrics — Don't Optimize Blindly**
**Problem:** Variant B increases conversions by 15%, BUT:
- Bounce rate increases by 10% (users hate the page)
- Cart abandonment increases by 8% (something's broken)
- Page load time increases by 2 seconds (UX nightmare)

**Solution:** Run `guardrails.sql` — if ANY guardrail fails, **do NOT launch**.

### **3. Novelty Effects — The Learning Curve**
**Problem:** Users click Variant B more on Day 1 (curiosity), but by Day 14 they prefer Control A.
**Solution:** Run tests for 2+ weeks, check day-by-day trends.

### **4. Minimum Detectable Effect (MDE) — Avoid Underpowered Tests**
**Problem:** You run a test with 1,000 visitors per variant, but need 21,400 to detect a 15% improvement.
**Consequence:** Test will likely fail (false negative).
**Solution:** Run `minimum_sample_size.sql` BEFORE starting the test.

---

## 📈 **Example Results Interpretation (For Beginners)**

### **Scenario: Button Color Test (Blue vs Green)**

```
Variant B vs Control A:
- Conversion Rate A: 2.00% (214 conversions / 10,700 visitors)
- Conversion Rate B: 2.35% (251 conversions / 10,680 visitors)
- Difference: +0.35 percentage points (+17.5% relative improvement)
- P-value: 0.012 (significant at α = 0.05)
- 95% CI: [+0.08%, +0.62%] (we're 95% confident true difference is in this range)
- Bayesian Probability B > A: 94.3% (94% chance green button is truly better)
```

### **Decision Framework:**

✅ **Launch Variant B IF:**
1. P-value < 0.05 (statistically significant)
2. Confidence interval doesn't include 0 (same as #1)
3. Bayesian probability > 95% (optional, but persuasive)
4. Guardrail metrics pass (bounce, load time, etc.)
5. No SRM detected (traffic split was 50/50)
6. Test ran 2+ weeks (avoid novelty effects)

❌ **Do NOT Launch IF:**
- Only "statistically significant" but effect size is tiny (e.g., +0.1%)
- Guardrails fail (even if primary metric improved!)
- SRM detected (technical issue with test setup)
- Test ran < 2 weeks (novelty effect possible)

### **Verdict for This Example:**
✅ **Launch Green Button** — Significant, practical, guardrails pass, no SRM.

---

## 🎓 **Why This Portfolio Stands Out**

Most AB testing portfolios show **just the results** (p-value, conversion rates). This one demonstrates:

✅ **Hypothesis Pre-Registration** — Fill out template BEFORE looking at data (prevents p-hacking)  
✅ **SRM Detection** — Catch technical issues that invalidate tests (most analysts miss this!)  
✅ **Guardrail Checks** — Ensure variant doesn't hurt secondary metrics  
✅ **Both Frequentist & Bayesian** — p-values AND "probability B is better"  
✅ **Sample Size Calculator** — Avoid underpowered tests (false negatives)  
✅ **Practical Significance** — Not just "p < 0.05", but "does it matter in real life?"  

---

## 📂 **File Structure & How to Use**

```
landing-page-ab-testing/
├── README.md                      ← You are here (start here!)
├── hypothesis/
│   └── template.md                ← Fill this BEFORE running test
├── ab_tests/
│   ├── frequentist_ttest.sql      ← Run this first (main analysis)
│   ├── bayesian_ab_test.sql       ← Run for "probability B wins"
│   ├── sample_ratio_mismatch.sql  ← GUARDRAIL: Detect SRM
│   ├── guardrails.sql             ← GUARDRAIL: Check secondary metrics
│   ├── minimum_sample_size.sql   ← Run BEFORE test (how many visitors?)
│   └── effect_size.sql           ← Measure practical significance
├── landing_pages/
│   ├── identify_test_pages.sql   ← Find your test pages in GA4
│   └── bounce_rate_comparison.sql← Compare engagement
└── utils/
    └── setup_views.sql           ← (Optional) Simplify queries
```

### **Recommended Workflow:**
1. Read this README (understand AB testing basics)
2. Fill `hypothesis/template.md` (define your hypothesis)
3. Run `ab_tests/minimum_sample_size.sql` (calculate sample size)
4. Run your test (collect data for 2+ weeks)
5. Run `ab_tests/frequentist_ttest.sql` (analyze results)
6. Run `ab_tests/guardrails.sql` (check guardrails)
7. Run `ab_tests/sample_ratio_mismatch.sql` (check SRM)
8. Make decision using framework above

---

## 🧪 **Sample Data Explained (For Beginners)**

### What is `ga4_obfuscated_sample_ecommerce`?
- **Public dataset** provided by Google for learning (free to query)
- Contains **fake ecommerce data** (no real customer PII)
- **Time period:** December 2020 - January 2021
- **Events tracked:** `page_view`, `view_item`, `add_to_cart`, `purchase`

### How to Modify Date Range in SQL Files:
```sql
-- In any SQL file, modify these lines:
DECLARE start_date STRING DEFAULT '20210101';  -- Format: YYYYMMDD
DECLARE end_date STRING DEFAULT '20210131';    -- Change to explore other dates
```
- The sample data has dates from 2020-12-01 to 2021-01-31
- Format: `YYYYMMDD` (Year-Month-Day, no spaces or dashes)

---

## ❓ **Troubleshooting (For Beginners)**

### "I get zero results!"
- **Cause:** Date range doesn't match sample data
- **Fix:** Ensure dates are between `20201201` and `20210131`

### "Table not found" error
- **Cause:** Dataset name typo
- **Fix:** Use: `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

### "No control/variant classification"
- **Cause:** Sample data doesn't have real AB test URLs
- **Fix:** This is expected! The SQL uses `/landing-v1` and `/landing-v2` patterns as examples. Replace with YOUR test URLs.

### "P-value is always 1.0 (not significant)"
- **Cause:** Sample data is small (only 2 months) and has no real AB test
- **Fix:** This is expected! Use your own GA4 data for real tests.

---

## 🔗 **Related Projects**

- [GA4 Attribution Models](https://github.com/GlitchG/ga4-attribution-models) - Marketing attribution analysis (8 models)
- [Marketing Analytics Sample Reporting](https://github.com/GlitchG/marketing_analytics_sample_reporting) - dbt project for multi-channel ads

---

## 📬 **Connect & Hire**

**Gleb Baraniuk**  
Freelance Marketing Analytics Consultant  
- LinkedIn: [linkedin.com/in/glitchg](https://linkedin.com/in/glitchg)
- GitHub: [github.com/GlitchG](https://github.com/GlitchG)
- Specializing in: GA4, BigQuery, Attribution, Paid Ads, n8n Automation

---

**© 2026 Gleb Baraniuk | MIT License | Portfolio Project**

*This repository demonstrates professional AB testing methodology. No p-hacking, no cherry-picking, no shortcuts.*
