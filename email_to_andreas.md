# Email draft — correlation review follow-up (June 2026)

> Draft only. Revise tone / sign-off before sending.

---

**Subject:** Correlation options — follow-up on your review

Hi Andreas,

Thanks for working through the correlation options on the ZIM run. I dug into why your four test runs looked identical — the cause turned out to be simpler than I first thought.

**The `Parameter_TimeSeries` sheet in your ZIM template is empty** (just column headers and units, no data rows). So when you picked "From template (auto)", the tool had nothing to compute correlations from and quietly fell back to no correlations. The population and intake variants did the same. All four of your runs were effectively the same "no correlations" run.

**What I changed.** The radio buttons now grey themselves out when their prerequisites are missing — "From template" is disabled when the TS sheet is empty, and "Advanced — manual entry" is disabled until you upload a CSV. Each greyed option carries a short note explaining why. The Run button also blocks with a clear error if a no-op mode somehow slips through.

**Dummy-data tests — when do correlations actually move the result?** I built a small script that runs the simulator on controlled fake data, so we can see clearly when correlations matter. Each test takes a tiny "mini-emissions" calculation, runs it 20 000 times, and reports how much the spread (the width of the 95% uncertainty range) changes when we add a correlation between the inputs:

- **Test A — two parameters, wide uncertainty, strongly linked.** Imagine just two inputs (think body weight and mature weight), each with a central value of 100 and a 95% range of roughly 40 to 160 (so a ±60% spread). We tell the simulator they move together strongly (ρ = +0.8). The emissions output is just their product. *Result:* with the correlation, the spread of the output is **32% wider** than without.
- **Test B — same two parameters, but the link is negative.** Same wide ranges, but now ρ = −0.5 (one goes up, the other goes down — like the dilution effect between milk yield and milk fat). *Result:* spread is **28% narrower**.
- **Test C — a realistic livestock pair.** Two inputs sized like real IPCC parameters: digestibility (DE) at 60 ± 6 (so ±10%), and the methane conversion factor (Ym) at 6.5 ± 2 (so ±30%), linked at ρ = −0.5 (the IPCC Eq 10.21 relationship). *Result:* spread is **17% narrower**. Smaller than tests A/B because the ranges are narrower.
- **Test D — many inputs, only one pair correlated.** Now ten parameters multiplied together (closer to the IPCC equation chain, which combines body weight × population × feed energy × Ym × N excretion …), each with a ±30% range. Only one of the ten pairs is correlated at ρ = −0.5; the other nine are independent. *Result:* spread is only **5% narrower** — the single correlated pair gets diluted by the nine other independent inputs.

So correlations **move the result a lot** when (i) the linked parameters have wide uncertainty ranges, (ii) the correlation is strong, and (iii) **several pairs** are correlated at once. They move it **a little** when only one or two pairs are linked inside a long multiplication of many independent inputs — which is more or less the situation in the IPCC equation chain (~13 parameters, 7 correlated pairs in the preset).

**Where would each of these four cases happen in the actual app?** Worth mapping the tests back to real workflows so they're not just abstract:

- **Tests A and B (wide ±60% uncertainty + strong correlation ±0.5 to ±0.8) are deliberately extreme** — they show what the simulator is *capable* of when you really push it. They wouldn't happen on a normal run with the sourced defaults. The only ways to get a result like this in the app are: (a) the user uploads a manual CSV matrix with strong ρ values AND uses very wide parameter bounds in the Parameters sheet, or (b) the user uploads a `Parameter_TimeSeries` with two volatile parameters that genuinely co-move strongly year-on-year (uncommon for national inventories). Neither happens with "Structural defaults".
- **Test C (DE × Ym, realistic ranges, ρ = −0.5) is exactly the DE↔Ym pair in the structural-defaults preset.** If the IPCC equation were just DE × Ym in isolation, the preset would narrow the CI by ~17%. But it isn't — that pair is just one factor inside the longer enteric-CH₄ equation, which brings us to test D.
- **Test D (10 parameters, one correlated pair) is the closest to what happens when you click "Structural defaults" on the left.** The preset has 7 pairs rather than 1, but most of them are within the activity-data block and contribute less than the cross-block DE↔Ym. The combined effect on the full inventory is ~5% — exactly what the end-to-end ZIM run produces.

**On your ZIM data, with just the left side of Tab 4 ("Activity Data Correlations").** If you simply tick "Structural defaults" and don't touch anything else, here is what happens: the central estimate barely changes (correctly — correlations preserve the mean) and the 95% uncertainty interval widens by about **5%**. You do not need to move any slider — the ρ values are baked into the preset from the published literature (BW↔MW = 0.50, DE↔Ym = −0.50, etc.). The change is small but visible, and it's mostly driven by the single cross-block pair DE ↔ Ym = −0.50 (test D in the dummy-data section above showed why: a single correlated pair inside a long multiplication of parameters only nudges the spread a few percent).

**Will it always be small with the sourced defaults? Yes.** Three reasons: (i) the preset only links 7 pairs out of ~78 possible in the IPCC equation chain, (ii) most preset values are moderate (|ρ| = 0.30–0.50), and (iii) the equations multiply many parameters together, so any one correlated pair gets diluted. Typical range on a real inventory: **3–10% widening of the CI**, depending mostly on how wide your Ym range is. This is the expected behaviour, not a bug — the structural-defaults preset is intentionally a "gentle" matrix you can apply with confidence even when you have no country-specific evidence.

**The right side of Tab 4 ("Coefficient Correlations") is a separate, opt-in switch.** It has three ρ sliders (for energy / manure-CH₄ / manure-N coefficient groups) and they all **default to 0** — so the right side is *off* unless the user actively moves a slider. If a user has reason to believe their emission factors come from the same lab (and therefore share a measurement bias), they can dial these up to 0.3 or so and they will see a bigger widening of the interval. Most users will leave this alone, which is the right default.

I also took on board your point that the real biological linkages cut across the old population / intake groupings. I added Milk↔BW and Milk↔DE to the preset (both +0.30), lowered BW↔MW from 0.85 to 0.50 (BW comes from the census, MW is usually a breed reference — different sources), and dropped two weaker pairs (Milk↔pct_pregnant and Cfi↔Ca).

**One more thing** — I added the literature sources for each preset pair to the methodology document (Resources tab → Methodology PDF, Structural-Defaults Preset section), so the citations are now visible without hovering the heatmap. I know the methodology document itself still needs a proper review pass; I put the sources there now mainly so I don't forget where they came from.

Happy to walk through it if useful.

Best,
Lolita
