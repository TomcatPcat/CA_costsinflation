# Incidence vs Wolff, and headline vs with-housing revaluation

Factual brief for dialogue. Sources: Canadian CSVs under `output/tables/`; `docs/01_wolff_methodology.md`, `docs/05_results_gallery.md`, `docs/07_interest_rate_*.md`, `docs/02_canadian_barriers.md`; Wolff NBER WP 31775 (PDF extract); code `04_inflation_gain.R`, `05_inequality_effects.R`. No new figures; numbers are cumulative period or single-year snapshots as labeled (not annualized).

---

## A. Incidence vs Wolff

### A.1 What Wolff reports (US SCF, WP 31775)

Core object: \(NIG = IG - IT\), scaled as a share of the group’s mean SCF income. Long-span results are for **1983–2019** (Table 6 / concluding §9). House-price responses to *nominal* mortgage rates are **not** inside \(IG\); middle-class gains in the NIG tables are mainly **debt devaluation** (plus small STK/BUS/BND terms), net of liquid-asset erosion and the income tax.

**Full-span NIG / mean income (1983–2019), selected wealth bands** (2019 dollars in the paper; ratios are the comparable objects):

| Wealth band (Wolff) | Rough CA analogue | NIG ($k) | NIG / mean income |
|---------------------|-------------------|----------|-------------------|
| Bottom 40% (P040) | Q1–Q2 combined | −19.3 | **−47.8%** |
| P4060 | ≈ Q3 | +39.9 | **+65.8%** (“two thirds”) |
| P6080 | ≈ Q4 | +12.7 | **+16.1%** |
| P8090 | lower Q5 | −14.2 | **−12.9%** |
| P9095 | upper Q5 | −29.1 | **−18.9%** |
| P9599 | near-top | −56.2 | **−18.5%** |
| Top 1% (P99) | ultra-top (SCF list) | +63.5 | **+6.9%** |

Related headline objects (same paper):

- **Median** household: NIG ≈ **+$14,300**, **>~25%** of median SCF income (debt-driven).
- **Aggregate mean**: NIG ≈ **−$3,600**, **−4.1%** of mean SCF income (IT slightly dominates IG).
- Abstract slogan: middle wealth quintile boosted by ~**two thirds** of income; bottom two quintiles lose almost **half**.

**Pattern to keep straight:** Wolff’s middle (P40–80) is strongly positive; the **upper-middle / top quintile bands (P80–99) are often net losers** as a share of income; only the **top 1%** is modestly positive again, via a very high wealth/income ratio—not leverage.

Sub-period signs flip with the rate/inflation path (e.g. several groups negative in 2001–2007). Full-span magnitudes above are the main published incidence benchmarks.

### A.2 What we find in Canada (SFS PUMF)

Same \(NIG/\)income concept in spirit (ratio of *means*: `mean_NIG / mean_inc`). Core \(IG\) excludes the mortgage-affordability housing channel (`code/04_inflation_gain.R`). Three different clocks:

1. **Annual snapshot** — one year’s YoY CPI + contemporaneous rates on that year’s portfolios (`nig_by_year_wealth_quintile.csv`).
2. **Inter-wave period** — start-of-spell portfolios fixed; cumulative CPI + rate path over the spell (`nig_by_period_wealth_quintile.csv`).
3. **Full SFS window** — 1999 portfolios fixed; 1999→2023 cumulative CPI + endpoint rate wedge (`nig_by_quintile_1999_2023.csv`). Closest *span-style* analogue to Wolff’s 1983–2019 table (still shorter: 24 vs 36 years).

#### Full-span 1999–2023 (`nig_by_quintile_1999_2023.csv`)

| Wealth Q | Mean NIG ($) | NIG / income |
|----------|-------------:|-------------:|
| Q1 | −6,680 | **−34.9%** |
| Q2 | −5,019 | **−16.3%** |
| Q3 | +2,338 | **+5.8%** |
| Q4 | −6,445 | **−14.0%** |
| Q5 | +127,119 | **+208.8%** |

#### Selected high-inflation / falling-rate spells (period cumulative, not annualized)

| Period | Cum. CPI | Q1 | Q2 | Q3 | Q4 | Q5 |
|--------|----------|-----|-----|-----|-----|-----|
| 1999–2005 | 13.8% | −7.4% | +0.5% | +11.9% | +27.1% | **+322%** |
| 2005–2012 | 12.9% | −1.9% | −2.2% | +8.1% | +13.8% | **+133%** |
| 2019–2023 | 14.4% | −5.1% | −0.6% | +9.8% | +7.7% | **+121%** |

Contrast spell (mild inflation, rising real rates): **2016–2019** — Q1 −2.1%, Q2 −2.3%, Q3 −3.9%, Q4 −17.7%, Q5 **−149%** (equity/business channel flips).

#### Latest annual snapshot (2023 YoY)

| Q | NIG / income | Debt/assets |
|---|-------------:|------------:|
| Q1 | −0.3% | ~1.07 |
| Q2 | +6.7% | ~0.44 |
| Q3 | +26.2% | ~0.28 |
| Q4 | +59.9% | ~0.16 |
| Q5 | **+355.7%** | ~0.08 |

*(Note: older `paper_notes.md` 2023 table rows are stale relative to current CSVs after the consol/duration fix; cite the CSVs.)*

**Mechanism reminder (Canada):** Middle/lower cells lean on **debt devaluation** relative to thin asset books; Q5 dollars and ratios are dominated by **STK+BUS** revaluation (low leverage). Gallery/paper: 2023 mean STK+BUS ~$900k in Q5 vs ~$30k in Q3; STK+BUS ≈ 85% of Q5 \(IG\).

### A.3 User hypothesis: “relative differences smaller in Canada except Q5”

**Short verdict: mostly yes for Q1–Q4 gaps vs Wolff’s bottom–middle gulf; yes that Q5 is the Canadian outlier — but Q5’s *role* differs from Wolff’s upper-tail story.**

Precision:

1. **Smaller Q1–Q4 gaps (levels), relative to Wolff’s long-span drama.**  
   Wolff’s full-span swing from bottom 40% (**−48%**) to middle P4060 (**+66%**) is ~**114 percentage points** of income. Canada’s full-span Q1→Q3 swing is **−35% → +6%** (~**41 pp**). In high-inflation inter-wave spells, Q1–Q4 often sit in a narrower band (e.g. 2019–2023 roughly **−5% to +10%**; 2005–2012 roughly **−2% to +14%**). So: *relative differences among the bottom four fifths are typically milder than Wolff’s US bottom-vs-middle contrast.*

2. **Q5 is the outlier in Canada — by levels and by Q5/Q3 ratios.**  
   Full-span Q5/Q3 ≈ **2.09 / 0.058 ≈ 36×**; 2019–2023 ≈ **12×**; 2023 annual ≈ **14×**. Among Q1–Q4 alone, no cell approaches those magnitudes. So “except Q5” is the right carve-out for Canada.

3. **Do not read that as “Canada matches Wolff’s top.”**  
   Wolff’s P80–99 bands are often **negative** NIG/income; only the **top 1%** is modestly positive (~7% of income). Our Q5 is a **thick top fifth** with large **positive** equity/business-driven NIG/income. That is a different upper-tail accounting story (and fragile under PUMF top-coding).

4. **Levels vs ratios; annual vs period.**  
   - **Levels (pp of income):** Q1–Q4 compression vs Wolff is clearest on **full-span** and many **period** tables.  
   - **Ratios (Q5/Q3):** amplify the Q5 outlier; they are *not* “small.”  
   - **Annual 2023:** Q2–Q4 still differ a lot (+7% → +60%); “small gaps” is *not* a claim about every annual snapshot.  
   - **Period vs Wolff full-span:** our multi-year `% of income` figures are **cumulative over the spell**, not annual rates. Another agent is producing annualized displays; until then, compare shapes/ranks within a clock, not raw 2019–2023 +10% to Wolff’s 36-year +66%.

5. **Middle-class “two thirds” is weaker in Canada’s full span.**  
   Wolff P4060 **+66%** over 36 years; Canada Q3 full-span only **+5.8%**. Qualitative “middle often positive in high-inflation spells” still holds (period Q3 ~+8% to +12% in 1999–2005 / 2005–2012 / 2019–2023); the long-horizon middle boom is not a one-for-one replica.

### A.4 Comparability limits (flag in any dialogue)

| Limit | Why it bites incidence comparisons |
|-------|-------------------------------------|
| **SCF vs SFS PUMF** | SCF high-income list sample vs no equivalent + top-coding → weak ultra-top; Q5 magnitudes fragile |
| **Period length** | Wolff dense triennial 1983–2019 vs SFS spells of 3–7 years; cumulative CPI differs |
| **Wealth definition** | Both marketable NW excl. vehicles/DB; CA registered mix is **PBO-imputed** (likely understates equity in TFSA/RRSP) |
| **Unit** | SCF household vs SFS economic family |
| **Upper bins** | Wolff splits P80–99 and top 1%; we report quintiles (Q5 = top 20%) |
| **Housing in NIG** | Both keep mortgage-affordability HP **out** of core \(IG\) — good — but Wolff’s broader WP 29392 housing story is a separate object |
| **Clock** | Full-span vs inter-wave vs annual YoY; do not mix without saying so |
| **Income concept** | Wolff sometimes contrasts SCF vs CPS income; we use SFS income on the EFAM file |

---

## B. Alternative scalings for Q5 (suggestions; not implemented)

Q5 \(NIG\)/income is large because income in the denominator grows much more slowly than equity/business holdings in the numerator. Different scalings answer different questions:

| Scaling | Question it answers | Likely behaviour for CA Q5 |
|---------|---------------------|----------------------------|
| **NIG / net worth** | How large is the revaluation relative to the balance sheet? | Compresses Q5 vs middle (high NW denominator); closer to a “% return” reading |
| **NIG / liquid assets** | How much of a buffer is the gain vs cash-like holdings? | Can *inflate* Q5 if LIQ is small relative to STK/BUS; useful for liquidity stress, not incidence fairness |
| **Share of aggregate NIG** | How much of the economy-wide dollar NIG sits in Q5? | Incidence of *totals*; Q5 can dominate even when /income is noisy |
| **Winsorized / trimmed top** | How sensitive is Q5 to a few extreme PUMF cells? | Stress test for top-coding / outliers; report range, not one number |
| **Per adult / equivalized** | Does household size drive Q5 income or wealth? | Modest shifts; unlikely to remove STK/BUS dominance |
| **Exclude STK and/or BUS** | How much of Q5 is the equity/business channel alone? | Often the decisive shut-off: Q5 may look much closer to Q3–Q4 on debt+liq+bonds only |
| **NIG / (STK+BUS)** | Return-like multiple on the assets that drive the result | Interprets the consol/duration assumption; not a welfare ranking |
| **P80–90 vs P90–100** (if sample allows) | Is “Q5” really one group? | Echoes Wolff’s P80–99 vs top 1% split; SFS PUMF may only support a soft P80–90 cut |

**Practical mapping for dialogue**

- “Is inflation a tax relative to **earnings**?” → keep **NIG/income** (Wolff’s headline), but treat Q5 as fragile.  
- “Is the top’s gain **outsized relative to its wealth**?” → **NIG/NW** or share of aggregate NIG.  
- “Is Q5 an artifact of equities?” → **STK/BUS shut-off** (and registered-mix sensitivity).  
- “Can we trust the level?” → **winsorize / P80–90** bounds + Hempel/PBO top-tail external checks (`docs/04_top_tail_commentary.md`).

---

## C. Housing explainer (slow)

### C.1 Start from two different questions

Think of two ledgers that use the **same** interest rates and inflation, but ask different questions:

1. **Core NIG (WP 31775 style)** — “Did inflation help or hurt this household *net of the tax on income*?” Balance-sheet pieces in \(IG\), minus \(IT = INC \times INF\).  
2. **Interest-rate revaluation package (WP 29392 style)** — “If we reprice the start-of-period portfolio for the observed path of real yields, bond yields, inflation on cash/debt, and *optionally* mortgage-linked house prices, how does mean/median wealth and the Gini move?”

“Headline / no-housing” and “with housing” are two settings of the **second** ledger. Core NIG stays on the first ledger and does **not** get replaced.

### C.2 What “headline” / no-housing revaluation includes

Hold each household’s portfolio fixed at the **start** of an SFS spell. Then add dollar revaluations:

| Channel | Intuition |
|---------|-----------|
| **Stocks (STK)** | Lower real discount rates → higher present value of future earnings (consol / duration helper) |
| **Business (BUS)** | Same real-rate logic as equities |
| **Bonds (BND)** | Yields fall → bond prices up (duration ≈ 8) |
| **Liquid assets (LIQ)** | Face value fixed; **real** value falls with cumulative CPI → negative contribution |
| **Debt (DBT)** | Face value fixed; **real** burden falls with CPI → positive contribution |

In code (`05_inequality_effects.R`):

`d_total_no_hous = d_stk + d_bus + d_bnd + d_liq + d_dbt`

**What NIG does with housing:** principal residence and other real estate are part of **wealth stocks**, but the **mortgage-rate → house-price affordability shock is not inside \(IG\)**. Core NIG can still include debt devaluation on mortgages (via `DBT × INF`), which is *not* the same as repricing the house.

### C.3 What “with housing” adds

Add one more channel for owners (mortgagors and free-and-clear):

1. Take the start- and end-of-spell **mortgage rates** (Canada: 5-year conventional).  
2. Compute an **affordability ratio** `hp_ratio`: at fixed payment and 20% down, how much house can you “afford” at the new rate vs the old rate? (Baseline amortization **25 years**; Wolff **30-year** curve kept as a benchmark.)  
3. Apply `d_hous = HOUS × (hp_ratio − 1)` to owners’ housing stock.

- Rates **fall** → `hp_ratio > 1` → positive housing contribution (1999–2012 style).  
- Rates **rise** → `hp_ratio < 1` → negative housing contribution (2019–2023).

Renters get `d_hous = 0` (they do not hold `HOUS` in this shock).

Then:

`d_total = d_total_no_hous + d_hous`

### C.4 The one major accounting change

**The only structural difference between headline and with-housing is whether you add the mortgage-affordability house-price term `d_hous`.**

Everything else (STK, BUS, BND, LIQ, DBT) is shared. You are not changing CPI, not changing \(IT\), and not rewriting core NIG. You are toggling one asset-price channel that Wolff himself keeps **out** of the inflation-tax identity and **in** the broader interest-rate / inequality package.

### C.5 Why 2019–2023 can show ~+$41k vs ~−$600

From `revaluation_contributions_by_period.csv` / `inequality_revaluation_by_period.csv` (means, start-of-2019 portfolios):

| Object | 2019–2023 mean Δ NW |
|--------|--------------------:|
| No-housing package | **+$41,165** |
| Housing channel alone (CA 25y) | **−$41,778** |
| With housing (sum) | **−$613** |
| `hp_ratio` (CA 25y) | **0.891** (affordable price ≈ 11% lower) |

**Plain story:** over 2019–2023, real-rate / equity / business / debt channels still deliver a large positive mean revaluation (~$41k). But mortgage rates rose, so the affordability schedule marks owners’ housing down by about the same amount on average. Turn the housing toggle on, and the mean nearly **washes out**. (Wolff 30y amort: mean with housing ≈ **−$5.8k** — same qualitative wipeout, a bit more negative.)

Shares of the with-housing total are undefined when the denominator is near zero (`share_unstable = TRUE` for 2019–2023 with housing). That is a feature of the wipeout, not a missing file.

### C.6 Why this is a toggle, not a replacement for NIG

| | Core NIG | Revaluation ± housing |
|--|----------|------------------------|
| Subtracts income tax \(IT\)? | **Yes** | No (wealth-only) |
| Includes STK/BUS/BND/LIQ/DBT? | Yes (in \(IG\)) | Yes |
| Includes mortgage HP affordability? | **No** | Optional toggle |
| Typical question | Tax vs rebate relative to income | How much of wealth/Gini moves with the rate path |

Keep both:

- Use **NIG** when the sentence is about whether inflation is a net tax on a group relative to income.  
- Use **no-housing reval** when the sentence is about financial + debt revaluation without taking a stand on a mortgage-affordability house-price model.  
- Use **with-housing reval** when the sentence is about the WP 29392-style package in which housing often dominates medians (US) or can cancel means (CA 2019–2023).

Canadian mortgage institutions (short term, 25y amort) change the *size* of `hp_ratio`, not the logic of the toggle. Renewal-risk / payment pass-through remain deferred (`docs/02_canadian_barriers.md`).

---

## Sources (pointers)

- Wolff WP 31775 Table 6 & §9; abstract “two thirds / almost half”; median NIG ~$14.3k.  
- CA tables: `nig_by_year_wealth_quintile.csv`, `nig_by_period_wealth_quintile.csv`, `nig_by_quintile_1999_2023.csv`, `revaluation_contributions_by_period.csv`, `inequality_revaluation_by_period.csv`.  
- Code: `code/04_inflation_gain.R` (NIG; no `d_hous`); `code/05_inequality_effects.R` (`d_total_no_hous` vs `d_total`); `code/utils/accounting.R` (`house_price_ratio`, `consol_reval`).  
- Docs: `01_wolff_methodology.md`, `07_interest_rate_section_plan.md`, `05_results_gallery.md` §4–5, `02_canadian_barriers.md`.
