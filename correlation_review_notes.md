# Correlation review notes — June 2026 (honest rewrite)

Notes prepared in response to Andreas' May 2026 review of the cattle
uncertainty app. The first pass of this document blamed Andreas' observation
("four correlation modes produce identical results on the ZIM run") on
statistical dilution. **That was wrong.** Inspecting his actual upload showed
the real cause is mundane and fixable: the `Parameter_TimeSeries` sheet in
`uncertainty_template_ipcc2019_ZIM_v2.xlsx` is completely empty (column
headers + units rows, every data cell `NA`). So the "auto from template" mode
silently fell back to no correlations, and the four modes were genuinely the
same run.

This note is the corrected version after the June 2026 fix.

## What actually happened on Andreas' ZIM run

Running `Rscript R/_test_zim_correlation_modes.R` against his upload prints:

| mode | matrix populated? | non-zero pairs | gate (after June 2026 fix) | correlations actually applied |
|------|---|---|---|---|
| none | n/a | n/a | always available | No (by design) |
| timeseries | **FALSE** | 0 | **BLOCKED** (radio greyed out) | *** No (silent no-op without the new gate) *** |
| preset | TRUE | 7 | available | Yes |
| manual | FALSE | 0 | BLOCKED until CSV uploaded | No (no upload) |

Before the June 2026 fix, the `timeseries` radio was selectable even with an
empty TS sheet — the matrix stayed `NULL`, MC ran with no correlations, and
nothing in the UI surfaced the no-op. Same trap exists for `manual` if no CSV
has been uploaded, and for the EF block-mode if all three ρ sliders are at 0.

Andreas tested four variants of two effectively-identical modes (`none` and
`timeseries` on empty TS). The other two modes (`preset` and `manual`) — which
would have shown a real effect — he didn't test.

## What the June 2026 fix does

1. **`corr_mode` radio is now server-rendered** with per-choice gating
   ([R/app_ui.R](R/app_ui.R) `uiOutput("corr_mode_ui")` ↔ [R/app_server.R](R/app_server.R) `output$corr_mode_ui`):
   - `timeseries` is greyed out when the upload's TS sheet is empty / missing.
   - `manual` is greyed out until a CSV correlation matrix has been uploaded.
   - `preset` is greyed out until at least one template (built-in example or
     custom upload) has been loaded — required because the preset matrix is
     built against the current parameter set.
   - Each greyed option carries a one-line explanation underneath ("your
     Parameter_TimeSeries sheet is empty…", "no manual CSV uploaded yet…").
   - When a previously-selected mode becomes unavailable (e.g. user uploads a
     new template whose TS sheet is empty while the radio was on `timeseries`),
     the selection auto-snaps back to `none`.

2. **State tracking** added in [R/app_server.R](R/app_server.R):
   - `rv$ts_available` — TRUE when `parse_uploaded_template()` produced a
     usable TS-derived matrix.
   - `rv$manual_uploaded` — TRUE once the user has uploaded a CSV manual
     matrix; reset whenever a new template is loaded.

3. **EF block-mode warning** ([R/app_server.R](R/app_server.R) `output$ef_rho_all_zero_warning`):
   when the user picks block-structured EF correlation but leaves all three ρ
   sliders at 0, an inline amber warning appears under the sliders.

4. **Belt-and-suspenders pre-run check** in `observeEvent(input$run_sim, …)`:
   if the selected mode somehow reaches the run button without a usable matrix
   (state desync, future code path that bypasses the gated UI), the simulation
   is blocked with an explicit error notification instead of silently running
   with `unified_corr_matrix = NULL`.

## PRESET_PAIRS — June 2026 livestock-science revision

While reviewing, the seven structural-default pairs were re-examined.
Two were dropped (Milk↔pct_pregnant for sign ambiguity, Cfi↔Ca for absence of
real statistical linkage in IPCC Eq 10.3 / 10.4 — continues the May 2026
trajectory that already lowered Cfi↔Ca from 0.60 to 0.30). Two new pairs were
added at Andreas' suggestion, covering the cross-group biological linkages he
specifically pointed out ("milk yield ↔ body weight ↔ feed digestibility").
BW↔MW was lowered from 0.85 to 0.50 because in practice MW is usually a
breed-reference constant while BW is from the national livestock census, so
the cross-source correlation is weaker than the same-survey 0.85.

| Pair | Before | After | Change |
|------|--------|-------|--------|
| BW ↔ MW | +0.85 | **+0.50** | lowered (mixed-source default) |
| BW ↔ WG | +0.40 | +0.40 | unchanged, sign-ambiguity flagged in source comment |
| Milk ↔ Fat | −0.30 | −0.30 | unchanged |
| Milk ↔ pct_pregnant | +0.20 | — | **dropped** (sign ambiguous between per-cow genetic and per-herd management interpretations) |
| Milk ↔ BW | — | **+0.30** | **NEW** (Holstein vs Jersey, NRC Dairy 2001) |
| Milk ↔ DE | — | **+0.30** | **NEW** (higher digestibility → higher milk, NRC Dairy 2001) |
| DE ↔ CP | +0.50 | +0.50 | unchanged |
| DE ↔ Ym | −0.50 | −0.50 | unchanged (strongest theoretically justified pair, IPCC Eq 10.21) |
| Cfi ↔ Ca | +0.30 | — | **dropped** (Cfi/Ca are independent inputs in IPCC Eq 10.3/10.4, not jointly estimated) |

Net: 7 pairs total (was 7), but the composition has shifted toward biology
that cuts across the old population/intake groupings — better matching what
Andreas flagged as real-world linkages.

## End-to-end test results on the ZIM template

Running the preset mode against Andreas' uploaded inventory:

```
mode='none':   mean=  67360 t CO2eq   sd=  9712
mode='preset': mean=  67375 t CO2eq   sd= 10208
→ mean shift: +0.02%   sd shift: +5.10%
```

So if Andreas now picks the **structural-defaults preset** on his data, he
will see a small but real shift — essentially no movement on the central
estimate (correctly, because correlations preserve marginal means), but a
~5% widening of the uncertainty interval. The driver is DE↔Ym (=−0.50, the
cross-block pair that links activity data and emission factors) plus the new
Milk↔BW and Milk↔DE links.

## The four diagnostic scenarios (still useful)

`Rscript R/_test_correlation_effect.R` continues to demonstrate when
correlations DO move things at the sampler level. These tables are
pedagogically useful and stay in the codebase as regression evidence; they're
no longer used to explain ZIM's flat result (the empty TS sheet does that).

| Scenario | Output SD ratio (correlated / independent) |
|---|---|
| A: 2-param, wide CVs, ρ=+0.80 | 1.32 — amplifies |
| B: 2-param, wide CVs, ρ=−0.50 | 0.72 — dampens |
| C: 2-param, DE×Ym preset (CVs 5% & 15%), ρ=−0.50 | 0.83 — single-pair upper bound |
| D: 10-param product, ONE pair at ρ=−0.50 | 0.95 — sparse-matrix effect |

The sampler hits target Spearman correlations within ±0.04 in every scenario
— ratified by audit guards C15/C16/C17. C18 (new) codifies the empty-TS-sheet
return-NULL invariant that the UI gate and pre-run check both rely on.

## Will Andreas see changes if he ticks correlations now?

| If he picks… | What happens |
|---|---|
| **No correlations** | same as before — no correlations applied |
| **From template (auto, time-series)** | radio is **greyed out** on his upload; he can't select it without populating the TS sheet first |
| **Structural defaults** | applies the 7 revised preset pairs → ~5% widening of his uncertainty interval (small but visible) |
| **Advanced — manual entry** | greyed out until he uploads a CSV matrix |

So yes — on his current upload, with one click on "Structural defaults" he
gets a real (small) shift. Previously this option was equally available but
the radio gave him no nudge toward it; now it's effectively the only mode
that does anything on a single-year inventory without historical TS data.

## Files changed in this pass

- [R/mc_sampling.R](R/mc_sampling.R) — `PRESET_PAIRS` revised per the June 2026 review.
- [R/app_ui.R](R/app_ui.R) — replaced static `corr_mode` radio with `uiOutput("corr_mode_ui")`; added `uiOutput("ef_rho_all_zero_warning")` under the EF block sliders.
- [R/app_server.R](R/app_server.R) — added `rv$ts_available` and `rv$manual_uploaded`; defined `output$corr_mode_ui` and `output$ef_rho_all_zero_warning`; extended the `corr_mode` observer to recompute the matrix on mode switches; added pre-run validation; updated the preset-loaded notification text.
- [_audit.R](_audit.R) — added C18 regression guard.
- [R/_test_zim_correlation_modes.R](R/_test_zim_correlation_modes.R) — **new** end-to-end script that reproduces Andreas' four-mode diagnostic against the actual ZIM xlsx and prints the mode-by-mode table.
- `correlation_review_notes.md` — this file.
- `email_to_andreas.md` — short email draft.

## Reproducibility

```sh
Rscript R/_test_correlation_effect.R       # unit-level sampler diagnostic
Rscript R/_test_zim_correlation_modes.R    # end-to-end ZIM mode-by-mode test
Rscript _audit.R                           # full regression suite (74/74 pass)
```
