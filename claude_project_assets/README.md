# claude_project_assets — what's in here and how to publish

This folder contains everything needed to set up (and keep up-to-date) the public **GMH Uncertainty Translator** Claude Project on claude.ai, which helps app users turn their raw cattle data into the app's input template.

## Files

| file | purpose | how it's produced |
|------|---------|-------------------|
| `system_instructions.md` | The Project's custom-instructions prompt. Defines Claude's persona, workflow, and behaviour rules. | **Hand-written.** Edit when you want to change the assistant's behaviour. |
| `param_catalogue.md` | Auto-generated dump of the 27 IPCC-aligned parameters: codes, units, defaults, distributions, aliases. | **Auto-generated** by `_build_claude_project_assets.R` at the repo root. Re-run after any change to `PARAM_CATALOGUE` or `PARAM_ALIASES` in `R/utils_template.R`. |
| `template_schema.md` | Auto-generated workbook schema: sheets, columns, validation rules, MMS list, distribution choice guide. | **Auto-generated.** Re-run after any change to the template structure, MMS list, or controlled vocabularies. |
| `mapping_examples.md` | 10 worked examples Claude can pattern-match against (Country X, Country Y, lbs→kg conversion, etc.). | **Hand-written.** Edit as you encounter real-world data patterns that should be added. |
| `questionnaire.md` | The pre-flight questionnaire users fill out before starting the chat. | **Hand-written.** Edit when the app adds new options (e.g. new MMS systems, new sub-categories). |
| `getting_started.md` | One-page user-facing guide on how to use the Translator. | **Hand-written.** Update the shared Project link after creating the Project on claude.ai. |

## One-time setup: publish the Project

1. Sign in to **claude.ai** under the project's official Anthropic account (so it survives staff turnover).
2. Click **Projects → Create project**.
3. Name it `GMH Uncertainty Translator`.
4. **Custom instructions** → paste the full contents of `system_instructions.md`.
5. **Project knowledge** → upload these four files (drag-and-drop):
   - `param_catalogue.md`
   - `template_schema.md`
   - `mapping_examples.md`
   - `questionnaire.md`
6. Click **Share** → make the Project shareable via link → copy the link.
7. Replace `PASTE_PROJECT_LINK_HERE` in `getting_started.md` with the real link.
8. (Optional) Convert `getting_started.md` and `questionnaire.md` to PDF / DOCX for download. Pandoc one-liners:
   ```
   pandoc getting_started.md  -o ../www/getting_started.pdf
   pandoc questionnaire.md    -o ../www/questionnaire.docx
   ```
9. Verify the in-app UI links in `R/app_ui.R` (Resources tab + Data Input tab) point at the right hrefs.

## Keeping it in sync

When the parameter catalogue or template schema changes:

```r
# from repo root
source("_build_claude_project_assets.R")
```

Then **re-upload** `param_catalogue.md` and `template_schema.md` to the Claude Project (replace the existing files). The auto-generated files have a date stamp in their first line so you can verify the upload took.

When the assistant's behaviour needs tuning (after user feedback or a real-world session that went off-rails):

- Edit `system_instructions.md`, then re-paste it into the Project's custom-instructions field.
- Or, if it's a recurring data pattern, add an example to `mapping_examples.md` and re-upload.

## End-to-end test before announcing the Translator

Open the Project in a clean browser (incognito + a fresh free claude.ai account). Run a session using the Country X synthetic data (see `R/utils_ipcc_defaults.R::generate_country_x_example`) with column names deliberately renamed (e.g. `pop` instead of `N`, `lw` instead of `BW`). Confirm:

- Claude asks the 6 onboarding questions if you don't paste the questionnaire.
- Claude proposes a column mapping with confidence flags.
- Claude generates `filled_template_for_app.xlsx`.
- The file uploads cleanly into the app's Data Input tab.
- The QA/QC tab shows all-green or only expected amber flags (for IPCC defaults).

## Cost

Zero ongoing cost. Users use their own free claude.ai accounts. The Project itself sits on the project's claude.ai account at no additional charge.
