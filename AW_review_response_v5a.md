# Andreas comments on uncertainty calculator 15_5_26 — response v5

There are 3 parts to this feedback: A flags a potential major calculation error in the tool. B gives specific comments on each page of the tool. C gives general feedback on a pilot test-run of the tool and suggestions for revised report outputs.

This round (v5) was scoped to **Block A only** — calculation correctness. Comments outside Block A are marked "Not yet addressed — queued for follow-up round" in the third column. They have been triaged and have a fix plan; we deferred them to keep this round focused on the numbers being right before partner beta-testing.

## A) Major issue to flag

I suspect there are errors in the calculation of direct N2O emissions and indirect N2O emissions. I input Zimbabwe data for intensive dairy system in the custom upload template and ran the same input data using the tool and using @Risk in Excel as well as in the IPCC 2019 software. Results highlight significant differences in the level of direct and indirect N2O emissions from manure management. (I could not check for direct and indirect N2O from pasture deposit because the downloadable reports from the tool do not include these emission sources.) I also checked the @Risk excel file calculations against the same input data in the IPCC software, and the results are identical, so I'm sure the issue is with the tool calculations. In the screenshot below, you can see (1) for total direct N2O emissions, the 'real' mean (i.e. as directly calculated by Excel) is not in the 95%CI from the tool's simulated mean. I'm not sure of the reason, but considering that the same EF3 values were used in all calculations, I suspect it may be the calculation of N excretion in the tool is not correct, or it may be to do with the calculation of weighted mean EF3 which is dependent on how the MMS% values are treated; and (2) for total indirect N2O emissions, the tool's simulated mean is also much lower than the Excel mean. N excretion is also an input into this calculation, and needs to be checked. In addition, since the % deviation from the mean calculated in Excel and simulated in @Risk is greater than that for direct N2O emissions, there may be some other issue with the calculations. See section C below in which I find that sensitivity analysis identifies some parameters as sensitive that should not appear in those equation chains. Another possible reason may be to do with whether Fracgas and Fracleach (IPCC 2019 Table 10.22) should actually be percentages (e.g. "30") or fractions (e.g. "0.3") and how these are treated in the equations. (IPCC 2019 Table 10.22 shows fractions, while the IPCC software requires them to be entered as percentages, but I'm not sure how the tool is implementing these equations.)

| Comment | How it was addressed |
|---|---|
| A1. Direct N2O MM mean (24.77 t) much lower than Excel/@Risk (33.23 t); Excel mean outside the tool's 95% CI. | **Diagnosis run — H1 (Dirichlet) ruled out; equation/parameter level is the suspect.** Reproduced your intensive-dairy run using the source data in `22-07-2023 Zimbabwe Uncertanity Analysis input data_WSv_SWa.xlsx` and computed direct N2O MM three ways: (A) deterministic point estimate, no Monte Carlo at all — 23.89 t; (B) MC with Dirichlet OFF, 10k iter — mean 24.08 t; (C) MC with Dirichlet ON at the app default `concentration=50` — mean 24.08 t. B and C agree to four significant figures, which falsifies hypothesis H1: Dirichlet preserves the marginal mean exactly (as Dirichlet theory predicts when per-MMS EF3 is a constant) and is **not** the cause of the gap with your Excel. The gap lives at the deterministic level. The fact that our deterministic ~23.9 t closely matches your tool sim ~24.8 t — and that both are ~28 % below your Excel 33.23 t — means the equations themselves are producing a different number than the IPCC software, not the MC step. The two candidates now in front: (i) the tool's `calc_n_excretion` is a simplification of IPCC Eq 10.31-10.34 and likely under-estimates Nex relative to the IPCC software's full implementation; for the cow sub-category it computes Nex = 47.3 kg N/head/year, whereas IPCC Table 10.19 typical Africa-dairy Nex is 60-78 kg N/head/year. (ii) MMS allocation defaults from your `manure_management` sheet may not match what you entered in Excel. Next step on our side: rewrite `calc_n_excretion` against the full IPCC 2006 / 2019 Eq 10.31-10.34 worksheet and re-test. **What we need from you:** the populated `uncertainty_template_ipcc2019.xlsx` you actually uploaded, so we can compare your MMS% allocation row-by-row. Also still need: confirmation whether your @Risk run included AD uncertainty or EF-only. |
| A2. Indirect N2O MM mean (9.69 t) much lower than Excel (16.89 t); % deviation larger than for direct N2O. | **Diagnosis run — different direction in our reproduction than yours.** Same three-way comparison: (A) deterministic 22.7 t; (B) MC Dirichlet OFF 23.5 t; (C) MC Dirichlet ON 23.5 t. So Dirichlet is also ruled out for indirect MM. But our reproduction is *higher* than your Excel 16.89 t while your tool sim was *lower* (9.69 t). That ~2.4× spread between your tool sim and ours strongly suggests we are using different MMS allocations — most likely your run plumbed in the app's default `pasture = 0.70, solid_storage = 0.30` (because manure on pasture goes to PRP indirect, not MM indirect, which would naturally drag MM-indirect down to ~9.7 t), whereas our reproduction assumed `liquid_slurry = 0.70, solid_storage = 0.30` (no pasture for intensive dairy). This is consistent with comment #36: your "pasture deposit N2O is not in the downloadable report" — meaning the PRP emissions you'd expect to see balance out the lower MM indirect probably *are* in the tool's output but get aggregated away in the downloads. We can confirm this once you share the populated template. Note: hypothesis on Fracgas/Fracleach being percentage vs fraction has been ruled out by code inspection: the tool reads `Frac_GasMS_pct` from the sheet and divides by 100 before use, so unit handling is consistent. |
| Pasture emissions not in downloadable reports | Not yet addressed — queued for follow-up round (covered by comment #36, see below). |
| UNC(AD) vs UNC(EF) in your Excel comparison | Open question for you — please confirm whether your @Risk run included AD uncertainty or EF-only. This determines whether the rShiny comparison should also be EF-only (correlations=none, N fixed at point estimate). |

## B) Specific comments on each page

### "Home" page

| Comment | How it was addressed |
|---|---|
| 1. Minor edit: "5. Formats results for IPCC inventory reporting (IPCC 2006 Vol. 1 Ch. 3, Table 3.3)" | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 2. Minor edits: "Emission sources covered: Enteric fermentation CH₄, Manure management CH₄, Manure management N₂O (direct and indirect), and N₂O (direct and indirect) from dung and urine deposited on pasture." Subscripts need to be added throughout the tool's pages and reports. | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 3. "Quick start: try the tool immediately, go to 1. Data input", but on this opening page you have to first select single year or trend. I found it's quite easy to miss this at the bottom of the opening page. If possible, move it to the 1. Data input page? | Not yet addressed — queued for follow-up round (Phase 5 UX). |
| 4. What does this tool do? "Takes your country-specific input data aligned with the IPCC Tier 2 equations, with uncertainty ranges." What this tool does NOT do: "It does not produce Tier 1 estimates and is not designed for uncertainty analysis of country-specific Tier 2 methods — the IPCC Tier 2 equation chain is required." | Not yet addressed — queued for follow-up round (Phase 5 text polish). |

### "Definitions" page

| Comment | How it was addressed |
|---|---|
| 5. I am not clear what the definition of "technical" and "core" parameters is and whether referring to this as "tier" is confusing with IPCC use of the word "tier". | Not yet addressed — queued for follow-up round. Plan: rename "tier" to "core / advanced" across the catalogue, UI labels, and template. |
| 6. Parameter "W". In equation 10.3 this is "Weight". In equation 10.6 this is "BW" and elsewhere (e.g. equation 10.17, "BW" is used. (a) suggest to note that this is the same parameter in equations 10.3 and 10.6, and (b) somehow "BW" seems more intuitive than "W". If updated to "BW" this would need to be consistent throughout the tool and the upload templates. | Not yet addressed — queued for follow-up round. This is a breaking change for existing user templates; we will keep "W" as a back-compat alias and need your sign-off before flipping the canonical name to "BW". |
| 7. "CP" – crude protein – in equation 10.32 is "CP%". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 8. Milk: "Set 0 for non-dairy sub-categories" not correct, should be "Set 0 for sub-categories that do not lactate". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 9. "pct_lactating": this is not an explicit parameter in IPCC. On page "5. Simulate & results" you have "IPCC software-aligned options", which includes "Cp pro-rate" defined as "fraction of females that calve in a year". On the one hand, it is correct that these 2 values may be different (e.g. if lactation >365 days or due to abortion etc). On the other hand, (a) IPCC equation 10.8 for lactation assumes that the value of Milk is already adjusted for the proportion of cows lactating, (b) for equation 10.13 the text under Table 10.7 in the 2019 refinement indicates that the value of Cpregnancy should be weighted by the proportion of females pregnant and the weighted value should be used in the equation. So I am wondering how your equations use these two parameters differently? And whether it is both IPCC-compliant and simpler to have just one parameter (pct_pregnant) and leave it to the user to decide whether this value is equal to the value of pct_lactating? | Not yet addressed — queued for follow-up round. This interaction also feeds into the A1 diagnosis (hypothesis 3): if your Zimbabwe milk input is already a sub-category-average, the tool's `pct_lactating` term is double-counting. Please confirm which convention your input uses so we can decide between a calc fix and a template-prompt clarification. |
| 10. FracGASMS and FracLEACH_H: There should be 4 of these listed: FracGASMS for manure management volatilization (Table 10.22), FracGASM for dung and urine deposit on pasture (Table 11.3), Frac_leachms (Table 10.22) and Frac_leach-(H) (Table 11.3). | **Addressed in this round.** Added two new parameters — `Frac_GASM_PRP` (IPCC 2019 Table 11.3, default 0.21) and `Frac_LEACH_PRP` (Table 11.3, default 0.30) — to: PARAM_CATALOGUE in [R/utils_template.R](R/utils_template.R) (so they appear automatically in newly-generated Excel templates with their own uncertainty rows); IPCC_DEFAULTS in [R/utils_ipcc_defaults.R](R/utils_ipcc_defaults.R); QAQC fraction-parameter list in [R/utils_qaqc.R](R/utils_qaqc.R). Changed `calc_indirect_n2o_prp` in [R/calc_manure_n2o.R](R/calc_manure_n2o.R) to take `Frac_GASM_PRP` and `Frac_LEACH_PRP` arguments instead of reusing `Frac_GASMS` and `Frac_LEACH_H`. Threaded the new args through `ghg_emissions` / `ghg_emissions_vec` ([R/calc_ghg_master.R](R/calc_ghg_master.R)) and `run_mc_simulation` ([R/mc_simulation.R](R/mc_simulation.R)). Back-compat: existing templates that do not yet contain the new params fall back to the Table 11.3 defaults (0.21 / 0.30) automatically. PRP emissions no longer share the MM volatilization/leaching fractions. Still left to do: download a fresh template, edit your Zimbabwe inputs to include PRP-specific values, re-run, and confirm the PRP indirect output changes as expected. |
| 11. C: Growth coefficient for Neg "depends on sex", edit to "depends on sex and physiological status". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 12. Ym: Methane conversion factor: "% of gross energy in feed converted to enteric CH4 methane (IPCC Table 10.12)". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 13. Fat "Milk fat content of the diet" should be "fat content of milk". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 14. EF4 and EF5: in the Definition column you give the global default values. Seems more consistent to just give the definition and IPCC Table reference in this column, and keep the default values in later columns, considering also that IPCC 2006 and 2019 default values differ. | Not yet addressed — queued for follow-up round (Phase 4 catalogue restructure). |
| 15. You give EF3_PRP but should also add EF3_S for manure management (Table 10.21). | Not yet addressed — queued for follow-up round. Note: per-MMS EF3 values are already supplied through the Manure_Management sheet's `ef3` column; what's missing is a *named* `EF3_S` catalogue row for the MM weighted-average for documentation purposes. Will add in Phase 4. |

### "Resources" page

| Comment | How it was addressed |
|---|---|
| 16. Methodological foundations. Add a link to IPCC 2019 Vol 1 Ch 3 on uncertainties. | Not yet addressed — queued for follow-up round. |
| 17. "FAO Livestock Activity Data Guidelines Guidance (L-ADG)". | Not yet addressed — queued for follow-up round. |
| 18. I would put Monni et al. 2007 in the case studies section. | Not yet addressed — queued for follow-up round. |
| 19. Maybe add a sub-section for "learning resources" with links to FAO e-learning on assessing land sector uncertainty, FAO e-learning on Tier 2 for livestock, UNFCCC webinar notes on uncertainty analysis. | Not yet addressed — queued for follow-up round. |
| 20. "Case studies" – should it be titled "case studies" or "examples"; and in addition to the journal publications cited, should we add some online available examples from national inventories? If so, I can compile a few links. | Not yet addressed — queued for follow-up round. Please share links when convenient. |
| 21. Eventually we may have at the top a sub-section for resources specific to this tool. I think we'll need three types of content: (a) specific to explaining how the tool works (if it's not transparently documented then it's not IPCC-compliant), (b) how to use the tool (e.g. tool-specific guidance such as "if you are not accounting for uncertainty of a parameter, enter parameter value and set uncertainty-pct=0…"), (c) guidance on preparing the uncertainty inputs before entering them in the data input templates. In terms of timing, I think we should think about (b) and (c) soon so that drafts are available for the beta-testing by partners. | Not yet addressed — queued for follow-up round. Agree that (b) and (c) need to be drafted before beta-testing. |

### "1 Data input" page

| Comment | How it was addressed |
|---|---|
| 22a. "Parameters" tab includes several parameters for manure management that would be more appropriate in the Manure_management tab because they are specific to manure management systems rather than animal sub-categories, e.g. EF3, EF4, EF5, Fracgas, Fracleach. | Not yet addressed — queued for follow-up round (Phase 4 template restructure). Note: the new `Frac_GASM_PRP` and `Frac_LEACH_PRP` from comment #10 are intentionally in the Parameters tab because they apply at sub-category × pct_pasture level, not at the MMS level. The MM-side `Frac_GASMS` / `Frac_LEACH_H` and EF3/EF4/EF5 will move in the next round. |
| 22b. Some parameters are repeated in the "parameters" and "Manure_management" tab, e.g. Bo, and I'm not sure which tab the tool picks the value from. If it's specific to an animal type (e.g. Bo values vary between dairy and non-dairy) then may be better in the "parameters" tab. | Not yet addressed — queued for follow-up round (Phase 4). |
| 22c. Columns L and M are listed as "auto-fill" but did not auto-fill unless I placed the cursor at the end of the formula. If it does not auto-fill, this does not impact on the upload into the tool, but the autofill of lower and upper CIs is useful for the user to have some QC check when filling the templates before upload. | Not yet addressed — queued for follow-up round (Phase 4). Likely an openxlsx formula-evaluation quirk — will switch to pre-computed numeric values. |
| 22d. In the "manure_management" tab, Bo has a value but no columns to fill uncertainty_pct or lower & upper CIs. | Not yet addressed — queued for follow-up round (Phase 4). |
| 22e. "Parameter time series": I could not work out how to enter my data in the template. There are no columns for cattle type, aggregation level and sub-category. The filled example template looks like an aggregation or example for one production system only, so hard to reproduce from a more complex input dataset. | Not yet addressed — queued for follow-up round (Phase 4). Will add `cattle_type` / `aggregation_level` / `sub_category` columns to the time-series template. |
| 23. Adjusting Cfi for winter temperature. You have the mean daily temperature in winter as an advanced option in '5. Simulate and results'. I think it would make sense to include it in the basic upload template and all processes thereafter; if a country is not using this adjustment, then it can be left blank and the app should give a default auto-fill value that negates the winter-specific adjustment of Equation 10.2, but including this option from the start would help make the tool IPCC-compliant. Also, some countries may apply this adjustment to some production systems (e.g. 'high Andes') but not others (e.g. lowland) in the same country. | Not yet addressed — queued for follow-up round (Phase 4). Will add `Tw` as a per-row column in the Parameters template. |

### "2 QAQC" page

| Comment | How it was addressed |
|---|---|
| 24. General feedback: the tests were useful and picked up errors and omissions and gave useful advice on more appropriate PDFs. | Noted, no change required. Thank you. |
| 25. Implementation of the benchmark deviation tests works – it raises lots of flags, but it often looks like the benchmarks used are not appropriate, possibly because IPCC sub-categories are defined differently from country-specific ones, or because the default values for the benchmark is from a different IPCC version (2006 or 2019) etc, e.g. benchmark references to Monni et al (2007) seem inappropriate unless they are also reflected in the IPCC guidelines. Overall, this test is useful, but perhaps just check how it applies default benchmark values to country-specific categories. | Not yet addressed — queued for follow-up round. Plan: downgrade Monni-2007-only deviation flags from FAIL to INFO; let regional/version mismatches surface as a softer warning. |

### "3 Uncertainty" page

| Comment | How it was addressed |
|---|---|
| 26. The current set-up is to edit the flagged or failed items in the '3. Uncertainty' page. As a user, I found it logical to go back to the template, edit in the template and re-upload so that my final template contained a record of my final values. I also did this because there are more than 100 parameter values for just 1 production system in my pilot test-run, and it was easier to find and edit them in the template than using the search bar and editing in the tool. Maybe the current set-up is fine and the user guide can note both options for editing flagged/failed values… | Not yet addressed — queued for follow-up round. Agree: keep both workflows; document them in the user guide. |

### "4 correlations" page

I have no comments here, as I did not use the correlations option due to comment 22e above.

| Comment | How it was addressed |
|---|---|

### "5 Simulate and results" page

| Comment | How it was addressed |
|---|---|
| 27. Emission sources to include: I suggest to list pasture deposition direct N2O and indirect N2O separately because they are separate IPCC reporting categories. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| 28. IPCC software aligned options: see comments 9 and 23 above. | See responses to #9 and #23. |
| 29. Possible bug? I checked the "Run uncertainty decomposition (AD/EF/Combined)" option, but there was no decomposition shown in my results. (I note it does work when running a simulation for the default in-app datasets, but didn't work for my uploaded custom dataset.) | Not yet addressed — queued for follow-up round. Bug confirmed at code-review level; investigation deferred until A1/A2 diagnosis is complete since we may need the same Zimbabwe input file. |
| 30. "Use 10,000 iterations for reliable results" – is there a basis for this statement? I seem to recall when I tested this with @Risk some years ago, 10,000 still led to quite large variation that was further reduced by more iterations. NB, in my test-run with Zimbabwe data, I ran the simulation twice with 25,000 iterations and got fairly consistent results. | Not yet addressed — queued for follow-up round. Plan: soften wording to "10,000+ recommended; check convergence with the comparison-run toggle". |
| 31. Minor edit: "What to do: Configure simulation settings on the left, then click 'Run Monte Carlo Simulation' at the bottom of the left-hand panel". | Not yet addressed — queued for follow-up round (Phase 5 text polish). |
| 32. After running a simulation, the results are displayed at an inappropriate level of aggregation: results are given for each animal sub-category, whereas IPCC would require aggregation at the level of "dairy cattle" and "other cattle" for each emission source. Users may be interested in other levels of aggregation (e.g. comparing uncertainty for different production systems entered in the custom template "Parameters" tab column B) and potentially at the sub-category level (column C). Would it be possible before running the simulation to have the IPCC dairy vs other cattle as a default with the option for users to select additional lower levels of aggregation for results reporting? | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| 33. First time, the simulations worked. Today I re-tried with the same uploaded template and got the error "--- Starting simulation --- Iterations: 5000 GWP: AR5 EF correlation: none (independent) ERROR: replacement has 0 rows, data has 5000 Custom data uploaded: 120 parameters loaded from uncertainty_template_ipcc2019.xlsx (country: Zimbabwe)" I could not determine the cause of the error, but hopefully the eventual user guide can document a number of error types and their solutions. | Not yet addressed — queued for follow-up round. Investigation needs the same Zimbabwe input file as A1/A2; will bundle. |
| 34. Comment applicable to the initial display of results and all other reports subsequent: units (e.g. t CH4) are not always reported. Please make sure every column in the in-app result displays and the downloadable reports have units displayed. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |

### "6 Sensitivity" page

| Comment | How it was addressed |
|---|---|
| 35. The tornado charts list parameters with the parameter abbreviations; to be really useful, it would present the results at the sub-category level of aggregation, e.g. cattle type_aggregation level_sub-category_parameter so that the user can for example identify that the most sensitive parameter is Ym for cows in the semi-intensive system, as opposed to Ym for any sub-category. Is it possible to revise either so that this is a default level of aggregation or to give the user the option to select the level of aggregation for the tornado charts? | **Partially addressed in this round.** The structural-bug part (Frac_LEACH_H / Frac_GASMS appearing in tornadoes for emission pathways where they are *mathematically absent* — your Section C "ISSUE TO HIGHLIGHT" findings) has been fixed. Root cause: when the selected output variable is structurally zero across all iterations (e.g. PRP direct N2O for an intensive-dairy run with `pct_pasture = 0`), the SRC/PRCC regression collapses on a constant outcome and returns numerical noise — surfacing whichever parameters happen to correlate with the zero vector. [R/mc_sensitivity.R](R/mc_sensitivity.R) now checks `sd(output) > 1e-9` and, when the output is constant, returns an explanatory message instead of a tornado. The tornado renderer in [R/app_server.R](R/app_server.R) surfaces that message in place of the chart. This removes the cross-wiring artefact from the candidate-cause list for A1/A2. Still left to do: the broader request (per-cattle_type / per-sub-category aggregation in tornado labels) is queued for the follow-up round. |

### "7 IPCC reports" page and related downloaded report results

| Comment | How it was addressed |
|---|---|
| 36. The in-app reports show direct and indirect N2O from pasture deposit separately, which is good. The csv download and word reports do not. I suggest to always disaggregate these results if selected by the user. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| 37. The word report section 4 only reports by gas, not by emission category. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| 38. Excel download did not work. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). Bug confirmed for investigation. |
| 39. See Section C below for suggested revised template for word download. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). Your mock-up will be the spec. |

## C) Overall feedback on a pilot test-run and suggestions on reporting

I input the values from Zimbabwe intensive dairy system (5 animal sub-categories) into the 2019 template and ran the simulation with the following settings:

- Single year
- No correlations
- 25000 iterations
- Random seed 42
- AR5, all emission sources selected

(I also ran it in @Risk with the same inventory values, and to the extent possible the same PDFs and uncertainty_pct inputs. Results for manure management will differ because I was not able to apply the Dirichlet constraint to MMS% values.)

My general experience was that using the tool was quite smooth and feasible to enter all the data required for 5 sub-categories. QAQC checks were useful (some of the benchmarks warnings seemed inappropriate but it was OK to ignore them and proceed). I did editing of 'fails' in the template and re-uploaded.

| Comment | How it was addressed |
|---|---|
| C1. The 'headline' results in the coloured bubbles refer to total CH4 and total N2O, whereas an inventory user is always interested in IPCC-defined emission sources, e.g. enteric fermentation, manure management CH4 etc. The headline margin of error I guess refers to total CO2 equivalents, but again, this is not an IPCC-relevant number. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). Plan: replace value boxes with enteric, manure CH4, MM N2O (direct+indirect), PRP N2O (direct+indirect). |
| C2. The 'system breakdown' is per animal sub-category, whereas users initially require a breakdown by dairy/other cattle, and may be interested in second-level categories as defined in column B of the template for uploading. Results at cattle sub-category level would only be for the more advanced user. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). Plan: aggregate by `cattle_type` (dairy / other) as default, with sub-category drill-down on opt-in. |
| C3 Enteric sensitivity ranking matches @Risk (top 5 identical). | Noted as confirmation that the enteric pathway is correctly wired. |
| C4 MM CH4 tornado: MCF values rank high in @Risk but not in the tool. | **Partially addressed.** The zero-variance guard in [R/mc_sensitivity.R](R/mc_sensitivity.R) removes the spurious-correlation source of artefacts but does not by itself explain the MCF ranking gap, which is more likely the Dirichlet-vs-fixed-MMS% difference noted under A1. Will be revisited once Zimbabwe data is re-run. |
| C5 MM Direct N2O: EF3 is influential in @Risk but not in the tool. ISSUE TO HIGHLIGHT: FRAC_LEACH_H is not a variable in the Direct N2O calculations. | **Cross-wiring artefact addressed in this round.** The "FRAC_LEACH_H in Direct N2O" finding was the spurious-rank pattern caused by SRC on a constant output. Fixed by the zero-variance guard described in #35. The EF3 ranking gap is the same issue as C4 (Dirichlet effect — to be confirmed with your data). |
| C6 MM Indirect N2O: Fracleach and Fracgas do not appear in the top variables in the tool, surprising given their large uncertainty ranges. | **Partially addressed.** Now that PRP and MM Frac parameters are separate (comment #10), the MM-side `Frac_GASMS` / `Frac_LEACH_H` are no longer being shared/masked by the PRP-side parameters in the sampler. Re-running your Zimbabwe pilot is expected to surface these in the MM-indirect tornado. |
| C7 Direct N2O pasture. ISSUE TO HIGHLIGHT: Fracgasms is not a parameter in the direct N2O from pasture equations. | **Addressed in this round.** Same fix as C5 — `Frac_GASMS` showing up as a top driver of direct PRP N2O was the same zero-output spurious-rank pattern (intensive dairy → `pct_pasture = 0` → direct PRP N2O is zero across all iterations). The tornado now shows an explanatory message instead of a numerically noisy ranking when the selected output is constant. |
| C8 Indirect PRP N2O. ISSUE TO HIGHLIGHT: FRAC_LEACH_H is not a variable in the Direct N2O calculations. | **Addressed in this round** (PRP indirect now uses the new `Frac_LEACH_PRP` from Table 11.3, not `Frac_LEACH_H` from Table 10.22). Re-run is required to confirm the tornado now shows `Frac_LEACH_PRP` (Table 11.3) for indirect PRP rather than the MM-side parameter. |
| C9 Excel download doesn't work. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| C10 CSV: put emission category in column A, separate pasture direct/indirect, allow user-defined aggregation. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). |
| C11 Word report: rebuild per your proposed template with executive summary and per-source AD/EF tables. | Not yet addressed — queued for follow-up round (Phase 3 reporting overhaul). Your mock-up is the spec. |
| C12 Word report Section 7 — confirm the IPCC-reporting-context statement about column J. | Not yet addressed — queued for follow-up round. Will fact-check against IPCC 2006 Vol 1 Ch 3. |

---

## Summary of what changed in this round

Files modified in this round:

- [R/calc_manure_n2o.R](R/calc_manure_n2o.R) — `calc_indirect_n2o_prp` now takes `Frac_GASM_PRP` / `Frac_LEACH_PRP` (IPCC 2019 Table 11.3) instead of reusing MM-side fractions.
- [R/calc_ghg_master.R](R/calc_ghg_master.R) — `ghg_emissions` / `ghg_emissions_vec` thread the new PRP-side fractions through.
- [R/mc_simulation.R](R/mc_simulation.R) — `run_mc_simulation` reads `Frac_GASM_PRP` / `Frac_LEACH_PRP` from the sampled parameter set, with IPCC 2019 Table 11.3 defaults as fall-back.
- [R/utils_template.R](R/utils_template.R) — added the two PRP parameters to `PARAM_CATALOGUE` so they auto-appear in new templates with their own uncertainty bounds, definitions, IPCC references, etc.
- [R/utils_ipcc_defaults.R](R/utils_ipcc_defaults.R) — added the two PRP defaults to `IPCC_DEFAULTS`.
- [R/utils_qaqc.R](R/utils_qaqc.R) — added the two PRP parameters to `FRACTION_PARAMS` so QAQC validates them as 0–1 fractions.
- [R/mc_sensitivity.R](R/mc_sensitivity.R) — added a zero-variance output guard. When the selected output is constant across all iterations (e.g. PRP N2O when `pct_pasture = 0`), the function now returns an explanatory message instead of spurious SRC/PRCC ranks.
- [R/app_server.R](R/app_server.R) — tornado chart renderer surfaces the zero-variance message in place of an empty chart.

What is still blocked and needs your input:

- Your Zimbabwe input .xlsx so we can reproduce the A1/A2 / #33 issues locally.
- Confirmation whether your @Risk run included AD uncertainty or EF-only.
- Confirmation whether your Zimbabwe `Milk` input is per-lactating-animal or sub-category-average.
- Sign-off on the W → BW rename (#6) before we make it the canonical name.
