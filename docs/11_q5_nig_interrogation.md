# Q5 NIG interrogation: bug or mechanical outcome?

**Verdict: not a bug** — with a **partial reporting concern**.

The extreme Q5 NIG / income ratios (≈356% in 2023 YoY; ≈+209% over 1999–2023) are the arithmetic consequence of (i) very large equity and business holdings relative to income, (ii) the project’s consol / Fisher-wedge / duration revaluation applied to those holdings, and (iii) a small income-based inflation tax. Sign checks on rising-rate (2016–19) and falling-real-rate (2019–23) windows behave as the formulas predict. No evidence of double-counted registered assets, percent/decimal unit errors, flipped debt signs, or mis-applied cumulative inflation in the annual snapshot.

The **partial concern** is interpretive, not computational: **NIG / income is a poor scale for Q5**. The same 2023 Q5 mean NIG is only **≈18.6% of mean net worth**. Excluding STK+BUS flips the full-span Q5 NIG/income from +209% to about **−110%**. So the headline ratio is equity/business-channel + wealth/income-scale, not a coding accident.

Diagnostic tables:

- `output/tables/q5_nig_interrogation_decomp.csv` — full Q3/Q5 component breakdown
- `output/tables/q5_vs_q3_nig_decomp.csv` — compact comparison
- `output/tables/q5_nig_interrogation_drivers.csv` — Q5 driver summary

---

## 1. Equations (as coded)

### Single-year (snapshot) NIG — `code/04_inflation_gain.R`

For each household in a survey year:

\[
\begin{aligned}
\text{ig\_stk} &= \texttt{pv\_inflation\_wedge}(\text{STK}, r_n, r) \\
\text{ig\_bus} &= \texttt{pv\_inflation\_wedge}(\text{BUS}, r_n, r) \\
\text{ig\_bnd} &= \texttt{pv\_inflation\_wedge}(\text{BND}, r_n, r) \\
\text{ig\_liq} &= -\text{LIQ}\cdot \text{INF} \\
\text{ig\_dbt} &= +\text{DBT}\cdot \text{INF} \\
\text{IG} &= \sum \text{ig}_\bullet \\
\text{IT} &= \text{INC}\cdot \text{INF} \\
\text{NIG} &= \text{IG} - \text{IT}
\end{aligned}
\]

`pv_inflation_wedge` (`code/utils/accounting.R`): floor rates at 0.5%, enforce \(r_n \ge r + \varepsilon\), then

\[
\text{wedge} = \min\bigl(\max(1 - r/r_n,\,0),\, \texttt{max\_wedge}=0.50\bigr).
\]

**Housing is not in IG/NIG** (Wolff WP 31775); HOUS enters wealth quintiles and separate mortgage/reval modules only.

Published quintile ratios use **ratio of weighted means** (`mean_NIG / mean_INC`), not the mean of household ratios — explicitly to avoid tiny-income blow-ups.

### Period NIG (fixed year-0 portfolio)

\[
\begin{aligned}
\Delta\text{STK} &= \texttt{consol\_reval}(\text{STK}, r_0, r_1;\ \text{floor}=0.5\%,\ D=20) \\
\Delta\text{BUS} &= \texttt{consol\_reval}(\text{BUS}, r_0, r_1;\ \ldots) \\
\Delta\text{BND} &= \texttt{duration\_reval}(\text{BND}, \Delta r_n;\ D=8) \\
\Delta\text{LIQ} &= -\text{LIQ}\cdot \text{INF}_{\text{cum}} \\
\Delta\text{DBT} &= +\text{DBT}\cdot \text{INF}_{\text{cum}}
\end{aligned}
\]

`consol_reval`: if both real rates are strictly above the floor, \(V(r_0/r_1 - 1)\); else duration approximation \(V \cdot [-D\,\Delta r / (1+r_0)]\).

---

## 2. Representative Q5 walkthrough — 2023 YoY

Macro (`data/external/macro_annual.csv`):

| Input | Value |
|-------|------:|
| GoC 10y nominal \(r_n\) | 3.36% |
| Real GoC 10y \(r\) | −0.37% |
| CPI YoY INF | 3.73% |

After floors: \(r_n=3.36\%\), \(r=0.50\%\). Raw wedge \(1 - 0.005/0.0336 \approx 85.1\%\), **capped at 50%**. So every dollar of STK/BUS/BND contributes **\$0.50 of IG** in this snapshot.

Weighted means, Q5 2023 (`portfolio_by_wealth_quintile.csv` + NIG tables):

| Bucket | Mean level (\$) | Channel | Contribution (\$) |
|--------|----------------:|---------|------------------:|
| STK | 450,288 | \(0.50\times\) STK | +225,144 |
| BUS | 441,083 | \(0.50\times\) BUS | +220,541 |
| BND | 158,401 | \(0.50\times\) BND | +79,201 |
| LIQ | 312,275 | \(-\)LIQ\(\times\)INF | −11,663 |
| DBT | 247,577 | \(+\)DBT\(\times\)INF | +9,247 |
| **IG** | | | **+522,470** |
| INC | 145,379 | IT = INC\(\times\)INF | −5,430 |
| **NIG** | | | **+517,040** |

\[
\frac{\text{NIG}}{\text{INC}} = \frac{517{,}040}{145{,}379} \approx 3.56\ (356\%),\qquad
\frac{\text{NIG}}{\text{NW}} = \frac{517{,}040}{2{,}779{,}128} \approx 0.186\ (18.6\%).
\]

STK+BUS alone are **85.3% of IG**. Debt and liquid channels nearly cancel at this wealth class. Income tax is tiny next to the equity wedge.

Compare Q3 2023: mean STK \$21.8k, BUS \$9.2k, NW/INC ≈ 4.6× vs Q5’s **19.1×**. Same 50% wedge → Q3 NIG/INC ≈ **26%**, not 356%. The gap is holdings × income scale, not a Q5-specific formula branch.

### Full span 1999–2023 (portfolio fixed at 1999)

Real rates: \(r_{1999}\approx 4.03\% \to r_{2023}\approx -0.37\%\). End rate below floor → **duration path** with \(D=20\):

\[
\text{eq\_scale} = -20\cdot\Delta r / (1+r_0) \approx 0.846
\]

(i.e. ≈84.6% of year-0 STK and BUS). Cumulative CPI inflation ≈ **62.5%**.

| Q5 1999 levels | Δ contribution |
|----------------|----------------:|
| STK \$104.7k | +\$88.6k |
| BUS \$125.1k | +\$105.8k |
| BND \$43.4k | +\$7.7k (bond duration scale ≈ +17.6%) |
| LIQ \$101.6k | −\$63.5k |
| DBT \$42.6k | +\$26.6k |
| IT on INC \$60.9k | −\$38.0k |
| **NIG** | **+\$127.1k → 209% of 1999 income; 19.4% of 1999 NW** |

Ex-STK/BUS: NIG/income ≈ **−110%** (liquid erosion + IT dominate). The +209% headline is almost entirely the long-duration equity/business revaluation on a top-quintile balance sheet.

### Sign checks

| Window | Real GoC path | Q5 NIG/inc | Interpretation |
|--------|---------------|----------:|----------------|
| 2019–23 | +1.14% → −0.37% (fall; duration scale ≈ +30%) | **+121%** | Equity/business gain > IT |
| 2016–19 | −0.32% → +1.14% (rise; scale ≈ −29%) | **−149%** | Symmetric equity/business *loss* |

Rising real rates produce large *negative* Q5 NIG. That is the opposite of a one-sided “always inflate Q5” bug.

---

## 3. Quantitative decomposition — Q5 vs Q3

| Period | Q | NW/INC | STK/INC | BUS/INC | IG STK | IG BUS | IG BND | IG LIQ | IG DBT | NIG | NIG/INC | NIG/NW | STK+BUS share of IG | NIG/INC ex STK+BUS |
|--------|---|-------:|--------:|--------:|-------:|-------:|-------:|-------:|-------:|----:|--------:|-------:|--------------------:|-------------------:|
| 2023 YoY | Q3 | 4.6 | 0.26 | 0.11 | 11k | 5k | 7k | −3k | 6k | 22k | 26% | 5.7% | 62% | +8% |
| 2023 YoY | Q5 | **19.1** | **3.10** | **3.03** | **225k** | **221k** | 79k | −12k | 9k | **517k** | **356%** | **18.6%** | **85%** | +49% |
| 1999–23 | Q3 | 1.9 | 0.10 | 0.04 | 3k | 1k | 1k | −10k | 32k | 2k | 6% | 3.0% | 17% | −6% |
| 1999–23 | Q5 | **10.8** | **1.72** | **2.05** | **89k** | **106k** | 8k | −64k | 27k | **127k** | **209%** | **19.4%** | >100%\* | **−110%** |
| 2019–23 | Q5 | 17.6 | 2.54 | 2.90 | 89k | 101k | −17k | −39k | 25k | 141k | 121% | 6.9% | >100%\* | −42% |
| 2016–19 | Q5 | 15.6 | 2.39 | 2.46 | −81k | −84k | −3k | −10k | 8k | −175k | −149% | −9.6% | ≈97% | −9% |

\*Share >100% when liquid/bond terms are net negative, so STK+BUS exceed total IG.

**Levels, not ratios, drive dollars.** In 2023, Q5 mean STK is ≈**21×** Q3; BUS ≈**48×**; income only ≈**1.7×**. Applying the same 50% wedge to that stock of productive assets is why dollar NIG is huge.

---

## 4. Input dependency list

| Dependency | Where | Role for Q5 |
|------------|-------|-------------|
| GoC 10-year yield | `macro_annual.csv` → `goc10` | Nominal discount / bond \(\Delta r_n\) |
| CPI / YoY / cumulative | `cpi`, `infl_yoy`; period `infl_cum` | LIQ tax, DBT gain, IT; Fisher real rate |
| Real GoC 10y | `real_goc10 = goc10/100 − infl_yoy` | Equity/business wedge and `consol_reval` path |
| Rate floor 0.5% | `pv_inflation_wedge`, `consol_reval` | Binds whenever real rates ≤ 0.5% (2023, parts of 2010s) |
| `max_wedge = 0.50` | annual PV wedge only | **Binds in 2023** (raw wedge ~85% → 50%) |
| Equity/business duration \(D=20\) | period `consol_reval` fallback | Sets ~85% of 1999 STK/BUS over full span |
| Bond duration \(D=8\) | `duration_reval` | Secondary for Q5 |
| MF look-through 60/40 | `SHARES$mf_*` in `00_setup.R` | Non-reg mutual funds → STK/BND |
| PBO registered mix | `03_portfolio_map.R` | RRSP/RRIF/TFSA/other → STK/BND/LIQ from non-reg mix; fallback 60/30/10 |
| Wealth quintiles | weighted `w_wolff` within year | Q5 = above p80; HOUS in NW but not in NIG |
| Income `INC` | after-tax / IT concept from panel | Denominator and IT |

Portfolio construction does **not** double-count registered assets: registered totals are allocated once into STK/BND/LIQ; `nw_consol` matches `w_wolff` in the diagnostic means.

---

## 5. Bug checklist (done)

| Hypothesis | Finding |
|------------|---------|
| Double-counted registered assets | **No** — single unpack into STK/BND/LIQ |
| Percent vs decimal mix-up | **No** — `goc10/100`, INF already decimal |
| Wrong debt sign | **No** — `+DBT×INF`; rising-rate window hurts Q5 via equity, not debt |
| Cumulative INF used as annual | **No** — annual uses `infl_yoy`; periods use `infl_cum` |
| Mis-assigned quintiles | **No** — ordered NW, STK, BUS by Q; within-year weights |
| Missing survey weights | **No** — `wtd_mean(..., weight)` |
| Near-zero income inflating ratios | **Not the published figure** — share INC≤0 in Q5 2023 ≈ 0.3%; ratio-of-means = 3.56 while mean of HH ratios ≈ 8.3 (worse). Code already uses the conservative aggregator |
| Top-coding / PUMF fragility | **Levels likely understated** at the ultra-top (`docs/04_top_tail_commentary.md`); that does not create a false *high* Q5 ratio via overstatement of STK/BUS in PUMF. Q5 remains a coarse P80–100 cell |

---

## 6. What would need to be true for Q5 NIG to be “too high”

The estimate is “too high” as an *economic* object if any of these hold (not as arithmetic errors):

1. **Equities/businesses are not ~20-year consols of the real GoC 10y** — private business cash flows may not revalue \(1\!:\!1\) with sovereign real yields; duration 20 may be too long.
2. **The 50% annual wedge cap is still too aggressive** when real rates are negative (raw Fisher gap ~85%; even half of STK+BUS in one year is a strong PV claim).
3. **BUS should not share the equity consol formula** — if business wealth is more like illiquid book/appraisal value, Q5 IG is overstated (BUS ≈ STK in Q5 2023).
4. **Equity share in STK is overstated** — MF 60/40 or PBO registered copy too equity-heavy. (Project docs argue the opposite bias for registered accounts: PBO mix likely *understates* TFSA/RRSP equity.)
5. **NIG/income is the wrong normalizer** — with NW/INC ≈ 19, any wealth revaluation of order 10–20% of NW becomes a multi-hundred-percent income ratio. Prefer NIG/NW or shutoffs.

---

## 7. Recommended robustness checks

Cheap checks already computed in the diagnostic tables:

1. **NIG / NW** for Q5 (2023 ≈ 18.6%; 1999–23 ≈ 19.4%) — report beside NIG/income.
2. **IG / NIG excluding STK+BUS** — full-span Q5 turns sharply negative; shows dependence on the consol channel.

Further checks (not run here):

3. Vary equity duration \(D \in \{10,20,30\}\) and `max_wedge ∈ \{0.25,0.35,0.50\}\`.
4. Halve or zero the BUS revaluation channel.
5. Split Q5 into P80–90 vs P90–100 (`wealth_detail`) — see whether the ratio is a top-tail cell vs broad upper quintile.
6. Alternative real-rate series (e.g. break-evens) if the Fisher residual `goc10 − infl_yoy` overstates the discount-rate move.

---

## 8. Bottom line

Q5’s huge NIG/income figures are an **expected mechanical outcome** of Wolff-style PV accounting applied to a Canadian top wealth quintile that is equity- and business-rich and only moderately higher-income. The code path is consistent across years and flips sign when real rates rise. Treat **356% / 209% as “large wealth revaluation ÷ income,”** not as “households gained three years of income in cash,” and pair any Q5 income ratio with **NIG/NW** and an **ex-STK/BUS** shutoff before policy interpretation.
