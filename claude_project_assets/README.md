# claude_project_assets — DIY-kit source files for the AI Translator

This folder is the source of truth for the **GMH Uncertainty Translator** kit that app users download from the Resources tab to set up their own Claude.ai assistant. We ship a DIY kit rather than a single shared Claude Project because Claude.ai does not currently offer public link-sharing for Projects on personal or workspace accounts — every user creates their own Project from these files.

## Files

| file | purpose | how it's produced |
|------|---------|-------------------|
| `system_instructions.md` | Custom-instructions prompt the user pastes into their Project's *Instructions* field. Defines Claude's persona, workflow, and behaviour rules. | **Hand-written.** Edit when you want to change the assistant's behaviour. |
| `param_catalogue.md` | Auto-generated dump of the 27 IPCC-aligned parameters: codes, units, defaults, distributions, aliases. | **Auto-generated** by `_build_claude_project_assets.R` at the repo root. Re-run after any change to `PARAM_CATALOGUE` or `PARAM_ALIASES` in `R/utils_template.R`. |
| `template_schema.md` | Auto-generated workbook schema: sheets, columns, validation rules, MMS list, distribution choice guide. | **Auto-generated.** Re-run after any change to the template structure, MMS list, or controlled vocabularies. |
| `mapping_examples.md` | 10 worked examples Claude can pattern-match against (Country X, Country Y, lbs→kg conversion, etc.). | **Hand-written.** Edit as you encounter real-world data patterns that should be added. |
| `questionnaire.md` | Knowledge-file copy of the pre-flight questionnaire (uploaded to the Project so Claude knows the form's shape). | **Auto-generated** copy of the user-facing `.Rmd` body. |
| `questionnaire.Rmd` | The user-facing fillable form, rendered to both `.pdf` (read-only reference) and `.docx` (the file users actually fill in). | **Hand-written.** Edit when the app adds new options (e.g. new MMS systems, sub-categories). |
| `getting_started.Rmd` | User-facing step-by-step guide that walks new users through setting up their own Translator Project. Rendered to `.pdf` and `.docx`. | **Hand-written.** |
| `README.txt` | Plain-text quick-start that lives inside `translator_kit.zip`. Tells the user the 5-step setup once they've unzipped the kit. | **Auto-generated** by the build script. |

## Build

From the repo root:

```r
source("_build_claude_project_assets.R")
```

This will:

1. Regenerate `param_catalogue.md` and `template_schema.md` from the live R source (`R/utils_template.R`, `R/utils_validation.R`, `R/utils_ipcc_defaults.R`).
2. Render `getting_started.Rmd` and `questionnaire.Rmd` to PDF (via pdflatex / MiKTeX) and DOCX.
3. Stage all user-facing files into `www/` so the Shiny app can serve them.
4. Bundle the kit into `www/translator_kit.zip` — 8 files: README.txt, getting_started.pdf, system_instructions.md, the four knowledge `.md` files, and questionnaire.docx.

Then commit and deploy as usual.

## Keeping it in sync with the app

When the parameter catalogue, template schema, or MMS list changes in the R source:

1. Re-run `source("_build_claude_project_assets.R")` — auto-regenerates `param_catalogue.md`, `template_schema.md`, and the zip.
2. Commit + deploy.
3. Existing users will see the new zip when they next visit the Resources tab. They drag-and-drop the updated `.md` files into their Project's *Files* panel, replacing the old ones.

When the assistant's behaviour needs tuning (after user feedback or a session that went off-rails):

- Edit `system_instructions.md` directly.
- Or, if it's a recurring data pattern, add an example to `mapping_examples.md`.

When the user-facing guide changes (screenshots, wording):

- Edit `getting_started.Rmd` and re-run the build.

## End-to-end test before announcing changes

Test as a brand-new user would:

1. Download the latest `translator_kit.zip` from the deployed app's Resources tab.
2. Open `claude.ai` in an incognito window, sign up for a fresh free account.
3. Follow the 5-step quick-start in `README.txt` (paste system instructions, drag in the four knowledge files).
4. Fill `questionnaire.docx` with the Country X synthetic data (see `R/utils_ipcc_defaults.R::generate_country_x_example`) with column names deliberately renamed (`pop` instead of `N`, `lw` instead of `BW`, ...).
5. Start a chat, paste the filled questionnaire, attach a messy CSV, confirm Claude produces a valid `filled_template_for_app.xlsx`.
6. Upload the produced file into the app's Data Input tab — confirm `parse_uploaded_template()` accepts it and the QA/QC tab shows all-green or only expected amber flags (for IPCC defaults).

## Cost

Zero ongoing cost to us. Every user uses their own free claude.ai account; no shared resources to maintain.
