# Implementation plan: Interest rates and the household balance sheet

**Status:** Phase A+B implemented (2026-08); Phase C (Teranet/duration) skipped this pass. Checkpoint 0 defaults: cumulative = sum of period $; Results charts kept; IR section table-heavy.  
**Primary research plan:** [`07_interest_rate_section_plan.md`](07_interest_rate_section_plan.md)  
**Paper stub:** `paper/inflation_tax_canada.tex` § “Interest rates and the household balance sheet”  
**Goal:** Translate the WP 29392-style relative-role analysis into build steps, deliverables, and review checkpoints — without implementing yet.

---

## 0. Scope in one paragraph

Fill the TeX stub with a Wolff WP 29392-style **direct** revaluation accounting for Canada (SFS 1999–2023): real GoC 10y equity/business PV (with duration fallback), bond duration, CPI on LIQ/DBT, and a **toggleable** mortgage-affordability housing channel (5y conventional rate + 25y amort baseline; Wolff 30y amort benchmark). Headline objects are mean/median NW growth attribution, Gini path, and channel shut-offs — not BoC causal identification. **Do not** build renewal-risk or loan-level pass-through.

Core \(NIG\) (WP 31775) stays unchanged and continues to **exclude** housing affordability.

---

## 1. What already exists (do not rebuild)

| Asset | Location | Role in this section |
|-------|----------|----------------------|
| Period reval loop (STK/BUS/BND/LIQ/DBT ± housing) | `code/05_inequality_effects.R` | Extend, don’t rewrite |
| Helpers: `consol_reval`, `duration_reval`, `house_price_ratio`, stress | `code/utils/accounting.R` | Reuse as-is |
| Mean $ contributions by period | `revaluation_contributions_by_period.csv` | Input to **shares** |
| Mean/median/Gini with/without housing | `inequality_revaluation_by_period.csv` | Input to T-IR1; missing Wolff-30y Gini columns |
| Affordability curves + `hp_ratio` sensitivities | `code/07_mortgage_affordability.R` | Polish → T-IR4 / F-IR1 |
| Tenure housing/debt channels | `housing_channel_by_tenure_period.csv` | F-IR4; already in Results |
| Income-Q stacked contributions | `code/12_reval_by_quintile.R` | Partial P1; already in Results |
| Stacked $ contrib + ΔGini figures | `code/06_tables_figures.R` | Refresh; add share/path figures |
| Age wealth **stock** (latest wave only) | `wealth_by_age_latest.csv` | Not yet period reval incidence |

**Paper overlap note:** Results already show mortgage affordability, stacked reval $, income-Q panels, and ΔGini. The dedicated Interest-rates section should **synthesize** the relative-role story (shares, % of actual advance, shut-offs, with/without housing, CA adaptations) and cite those figures where useful — not duplicate every Results chart.

---

## 2. What to compute first vs later

### Phase A — Headline numbers (P0; code before prose)

Must exist before drafting the section’s claims:

1. **Contribution shares** by channel × period (channel $ / mean ΔNW), with/without housing; plus a **cumulative 1999–2023** summary row (chained or summed period effects — decide in A1 below).
2. **Actual vs revalued growth** of mean/median NW by period, and Wolff-style “share of actual advance explained” by the monetary package.
3. **Channel shut-off Gini experiments:** full no-housing; full +CA25y housing; equity+bus only; housing only; debt+liq only; (optional) full +Wolff30y.

### Phase B — Figures + incidence polish (P1)

4. Polished F-IR2 (stacked **shares** or $ with clearer paper caption), F-IR3 (Gini path: actual end-of-period vs revalued counterfactual).
5. Age-band **period** revaluation incidence (29392 §9 analogue).
6. P80–90 (and/or wealth-quintile) mean revaluation incidence if income-Q panels are insufficient for the inequality narrative.
7. Wire TeX subsection prose + tables.

### Phase C — Optional robustness (P2; after user checkpoint)

8. Actual HPI (Teranet / NHPI) vs affordability-implied `hp_ratio` path (F-IR5).
9. Bond-duration / maturity sensitivity (Wolff §10 lite).
10. Docs gallery / `paper_notes.md` pointers.

---

## 3. R scripts: create vs extend

| Script | Action | Deliverables |
|--------|--------|--------------|
| **`code/05_inequality_effects.R`** | **Extend (primary)** | Shares CSV; actual-vs-reval growth CSV; shut-off Gini CSV; add Wolff-30y NW/Gini columns to period reval table; optional age-band period loop; cumulative row |
| **`code/06_tables_figures.R`** | **Extend** | F-IR2 (shares stack), F-IR3 (Gini path), polish captions; read new CSVs |
| **`code/07_mortgage_affordability.R`** | **Light polish** | Ensure T-IR4 / F-IR1/F-IR4 paper-ready; no renewal logic |
| **`code/12_reval_by_quintile.R`** | **Reuse** | Already covers income-Q incidence; optionally add share columns if needed for text |
| **`code/utils/accounting.R`** | **Touch only if needed** | Prefer no API change; duration sensitivity via args in `05` loop if P2 |
| **New thin script?** | **Avoid unless necessary** | Prefer extending `05` over a new `13_*` unless age/P80–90 block becomes large; if so, `code/13_interest_rate_incidence.R` is acceptable |
| **`code/02_macro_series.R`** | **P2 only** | Add NHPI/Teranet series if F-IR5 approved |
| **`code/run_all.R`** | **Wire** | Ensure extended `05`/`06` still run in order; no new SHS dependency |
| **`paper/inflation_tax_canada.tex`** | **Fill stub** | Subsections below; `\input` or inline tables from `output/tables/` |
| **`docs/paper_notes.md`**, gallery | **P2** | Point to new IR tables/figures |

### Design rule for `05`

Keep one period loop that computes household-level `d_*` once, then summarise multiple tables from that frame (means, shares, shut-off Ginis, age cuts). Avoid three independent loops that can drift from `12` / `07`.

---

## 4. Canadian adaptations (must be coded + stated in text)

| Wolff US | Canada implementation | Where |
|----------|----------------------|--------|
| SCF ~triennial 1983–2019 | SFS waves **1999, 2005, 2012, 2016, 2019, 2023** (5 inter-wave spells) | `period_rates.csv` |
| 10y Treasury real | **GoC 10y** real = nominal − CPI | `02` / periods |
| 30y FRM affordability | Baseline: **5y conventional mortgage rate + 25y amort**, LTV 0.80; retain Wolff **30y amort** on same 5y rates as hybrid benchmark | `05`, `07` |
| Continuous FRM narrative | Short fixed terms: use 5y rate path for `hp_ratio`; **do not** model renewal payment shock | text + `07` header |
| Consol equity PV | `consol_reval(..., r_floor=0.005, duration=20)` — consol only if both real rates > floor; else duration fallback | `accounting.R` (already) |
| Bond duration | Keep **D ≈ 8**; sensitivity later (P2) | `05` |
| Racial gaps | **Age + tenure** primary; race only if recent-wave coverage allows a footnote | `05`/`07`/`08` |
| Top-tail ratios | Prefer **quintiles / P80–90**, not P99 | text + optional cut |

**Sensitivities already coded (publish as robustness, not pass-through):** CA 30y amort, 3y-rate proxy (−20 bp), OSFI-style stress rate (`mortgage_hp_ratio_sensitivities.csv`).

---

## 5. Explicit deferrals (restate once in paper; do not build)

Per `07_interest_rate_section_plan.md` §5, `02_canadian_barriers.md`, and `07` header:

1. **Renewal-risk incidence** — distribution of payment shock from short Canadian terms at renewal.
2. **Detailed rate pass-through** — mapping policy/market rates into existing loan payments and renegotiation.

Also out of scope for this section (Wolff exclusions): mortgage cash-flow as NW change; GE/BoC identification; deposit-rate accumulation in base case; portfolio rebalancing between waves.

---

## 6. Paper section fill plan

**TeX location:** `\section{Interest rates and the household balance sheet}` (currently TODO comments only).  
**Placement:** After core \(NIG\) results; before Barriers. Cross-ref Results figures where they already exist to avoid duplication.

### Subsection outline → outputs

| # | Subsection | Tables / figures | Source |
|---|------------|------------------|--------|
| 6.1 | Wolff’s channels and exclusions (short) | prose only | methodology docs |
| 6.2 | Canadian rate/inflation backdrop | optional small rate table or cite macro figure | `11` / `period_rates` |
| 6.3 | Aggregate revaluation: mean, median, Gini | **T-IR1**; cite F-IR3 / existing ΔGini | extend `05`, `06` |
| 6.4 | Contribution decomposition (Wolff Table-8 style) | **T-IR2**; **F-IR2** | extend `05`, `06` |
| 6.5 | Canadian adaptations & sensitivities | **T-IR4**; cite F-IR1 | `07` |
| 6.6 | Tenure and age incidence | cite F-IR4; new age incidence table/fig | `07`, extend `05` |
| 6.7 | Relative role vs \(NIG\) | short prose: same rates, housing toggle only here | — |
| 6.8 | Limits | deferrals + SFS top-tail/race | — |

### Output IDs (from research plan)

| ID | Content | Priority | Build |
|----|---------|----------|-------|
| **T-IR1** | Period mean/median/Gini: actual Δ vs reval (no hous / +CA25y / +Wolff30y) | P0 | extend `05` |
| **T-IR2** | Contribution *shares* of mean (optional median) by channel × period + cumulative | P0 | extend `05` |
| **T-IR3** | Gini Δ under channel shut-offs | P0 | extend `05` → `06` plot optional |
| **T-IR4** | `hp_ratio` sensitivities by period | P1 polish | `07` (exists) |
| **F-IR1** | Affordability curves Wolff vs CA | exists | refresh caption |
| **F-IR2** | Stacked contributions (prefer shares for paper table narrative) | P1 | `06` |
| **F-IR3** | Gini path: actual vs revalued counterfactual | P1 | `06` |
| **F-IR4** | Tenure housing/debt | exists | refresh |
| **F-IR5** | Actual HPI vs affordability path | P2 optional | new |

### Suggested new CSV names

- `output/tables/revaluation_contribution_shares_by_period.csv` (T-IR2)
- `output/tables/revaluation_vs_actual_growth_by_period.csv` (% of advance)
- `output/tables/revaluation_gini_shutoffs_by_period.csv` (T-IR3)
- `output/tables/revaluation_by_age_period.csv` (P1)
- Optionally extend `inequality_revaluation_by_period.csv` with Wolff-30y mean/median/gini and actual end-year mean/median for T-IR1 joins

---

## 7. Sequencing and user-review checkpoints

```text
Checkpoint 0  Approve this plan (scope, deferrals, P0 vs P2)
     │
     ▼
Phase A (P0 code)  extend 05 → new CSVs; smoke-run via run_all / source 05
     │
Checkpoint 1  Review headline numbers:
              - Are CA Gini signs (sometimes +) the story we want front-and-center?
              - Cumulative method: sum of period $ vs compound index — pick one
              - With-housing wipeout in 2019–2023: feature, not bug?
     │
     ▼
Phase B (P1)  figures in 06; age incidence; TeX draft of § Interest rates
     │
Checkpoint 2  Review draft prose + T-IR1–T-IR3 placement vs Results overlap
     │
     ▼
Phase C (P2, optional)  Teranet/NHPI; bond-duration sensitivity; docs sync
     │
Checkpoint 3  Freeze section for working-paper pass
```

**Estimated effort (order of magnitude):** Phase A ~0.5–1 day; Phase B ~0.5–1 day including TeX; Phase C optional half-day if data paths are ready.

---

## 8. Open design decisions (resolve at Checkpoint 0 or 1)

1. **Cumulative 1999–2023:** (a) sum of period mean channel dollars as share of sum of period mean ΔNW; (b) compound start-of-wave portfolio chain (Wolff closer); (c) both, with (a) as default for transparency. **Recommendation:** (a) + footnote that gaps are long and compounding is illustrative; optionally (b) as sensitivity.
2. **% of actual advance:** Denominator = actual SFS mean (median) change from year0→year1 (`inequality_baseline_by_year`); numerator = reval Δ mean (median). Flag periods where actual Δ is small/negative (ratio unstable).
3. **Median shares:** P0 for mean shares; median shares optional if median ΔNW is noisy.
4. **Income-Q vs wealth-Q for IR incidence:** `12` already does income-Q (SHS juxtaposition). For inequality narrative, T-IR3 Gini shut-offs may suffice; add wealth-Q or P80–90 only if Checkpoint 1 wants it.
5. **Results vs Interest-rates duplication:** Prefer moving detailed relative-role tables into the Interest-rates section and keeping Results charts as preview — or keep charts in Results and make Interest-rates table-heavy. **Recommendation:** leave existing Results figures; put T-IR1–T-IR3 and F-IR3 in the new section.

---

## 9. Explicit non-goals

- No renewal schedules, term-remaining imputation, or payment-shock distributions.
- No loan-level or policy-rate pass-through model.
- No BoC / VAR / QE causal identification.
- No change to core \(IG\)/\(IT\)/\(NIG\) formulas (housing stays out of \(IG\)).
- No race/ethnicity primary stratification (footnote only if data allow).
- No P99 ultra-top claims; no top-tail reweighting.
- No new SHS work in this pass.
- No Teranet/NHPI or bond-duration work until Phase C is approved.
- No git commit as part of planning; implementation commits only when requested.

---

## 10. Risks and mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| CA Gini often **rises** when rates fall (equity at top) | Conflicts with Wolff’s “strongly equalizing” US headline | Make shut-offs (T-IR3) and with/without housing the explanatory core |
| 2019–2023 housing channel ≈ cancels non-housing gains | Can dominate narrative | Report both toggles; don’t bury no-housing results |
| Long SFS gaps | Cumulative chain ≠ continuous FRM economy | State sparse waves; prefer period tables + cautious cumulative |
| Low real-rate duration fallback | Affects 2012–2016 and nearby spells | Already fixed in `consol_reval`; cite in adaptations subsection |
| PUMF top-coding | Mean shares / Gini fragile at top | Emphasize medians + shut-offs; avoid P99 |
| Overlap with Results section | Reader fatigue / contradiction | Cross-ref; new section owns shares & % of advance |
| Drift between `05` and `12` | Inconsistent channels | Shared helper mutate block or single sourced function later if drift appears |

---

## 11. Success criteria

Done when:

1. T-IR1–T-IR3 (and polished T-IR4) exist under `output/tables/` and regenerate from `run_all.R`.
2. F-IR2/F-IR3 (or clear upgrades of existing contrib/Gini figs) exist under `output/figures/`.
3. TeX Interest-rates section replaces TODOs with drafted subsections 6.1–6.8, citing those outputs, restating deferrals once.
4. Canadian adaptations (5y + 25y, duration fallback, SFS waves) are explicit in text.
5. User has reviewed Checkpoint 1 numbers and Checkpoint 2 prose; P2 items are either shipped or explicitly parked.
6. No renewal/pass-through code introduced; core \(NIG\) pipeline unchanged.

---

## 12. Immediate next step after approval

Implement **Phase A only** in `code/05_inequality_effects.R` (+ minimal `run_all` smoke check): contribution shares, actual-vs-reval growth, Gini shut-offs, Wolff-30y columns. Pause for Checkpoint 1 before figures and TeX.
