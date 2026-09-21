# Gulo 3000 — Lab 1 analysis and presentation

## Open these files

- **Gulo_3000_Poster.pptx** — editable, one-page 16:9 landscape poster.
- **Gulo_3000_Poster.pdf** — projected/printable poster.
- **Gulo_3000_Handout.docx** — editable technical handout.
- **Gulo_3000_Handout.pdf** — verified three-page handout.
- **MATLAB/run_all.m** — reproduce every engineering calculation from `../Data`.
- **PRESENTATION_NOTES.md** — ten-minute talk outline, likely questions and submission reminders.

The poster deliberately has **two red image placeholders**, as requested: one
for a labeled apparatus photograph and one for a CAD assembly screenshot or
schematic. The measurement and simulation figures are complete. Group attribution
is “Powertrain Dynamics Group.” Replace it with individual names if desired.

## MATLAB code is separate from the documents

All engineering calculations and scientific plots are stored in **MATLAB/**.
The original `Data/`, `Matlab code/`, `matlab stuff/` and example posters are
unchanged. No additional MATLAB toolboxes are required; tested with R2026a.

Open `MATLAB/run_all.m` in MATLAB and click **Run**, or use:

```matlab
run('Lab1_Deliverables/MATLAB/run_all.m')
```

The code resolves paths from its own location; keep `Lab1_Deliverables/` alongside
the original `Data/` folder. The expected exports are tab-delimited with a six-line
header. Tachometer units are already rad/s and must not be converted a second time.

| File | Purpose |
|---|---|
| `characterize_system.m` | Import/inventory; motor resistance and constant; four locked-side decays; two post-disengagement coastdowns; effective damping separation |
| `validate_system_model.m` | Complex sweep averaging; stiffness-only refinement; leave-one-sweep-out checks; rigid-shaft comparison; neglected inductance check |
| `analyze_sensitivity.m` | Symmetric ±1% sensitivity of all 12 parameters; fixed-band and tracked-band costs; peak and frequency sensitivity |
| `design_changes.m` | Four detailed parameter sweeps; minimum targets; rounded recommendations; switching simulations; independent broadband diagnostic; replicate combinations |
| `publication_figures.m` | Rebuild the poster/handout graphs in PNG, vector PDF/SVG and editable FIG formats |
| `verify_analysis.m` | Independent equations-versus-transfer-function check; stability; integration and time-step convergence; independent ODE comparison; target checks |
| `functions/` | Individually filed mechanics, transfer-function, fitting, spectral-estimation and simulation functions |

`Analysis/` contains the audit tables, all input-record plots, numerical JSON
results and saved MATLAB workspaces. `Figures/` contains publication figures.
`Presentation_Source/` contains the task-based content outline and the
document-layout scripts; those scripts only format MATLAB-generated results.

## Important interpretation

- The measured response spans **4–10 Hz**, not the example's suggested 1–20 Hz.
  The narrowest sweep's actual frequencies differ from its filename; actual
  recorded frequencies are used.
- Damping estimates use automatic fitted extrema. Earlier manually overridden
  damping sums are not reused. Every selected fit is saved for inspection.
- The team confirmed that the coastdown motor was **mechanically uncoupled while
  the two flywheels remained linked**. Coast fits use 4.0–19.5 seconds and inertia
  `2*Jf`. The resulting `Bb` is an effective external-assembly coefficient.
- Friction is not perfectly viscous. The Coulomb coast fits have slightly smaller
  speed residuals; the linear viscous model is an explicit design approximation.
- Shaft stiffness alone is refined against the sweeps; electrical/damping
  estimates remain fixed. Fit residuals are not presented as independent validation.
- The rigid-shaft comparison uses zero relative motion / infinite stiffness.
  Zero shaft damping is **not** a rigid shaft.
- The class cost integrates **linear gain over angular frequency**, across a
  1-Hz-wide band. Both original-band and moving-band metrics are saved.
- If strong damping eliminates the local resonance, the reported gain is the
  maximum over the measured 4–10 Hz band, and the 1-Hz cost stays at the original
  resonance. Its resonance frequency is recorded as `NaN`/`null`, not invented.
- Switching is a **unit-voltage simulation**, from rest, on for four seconds and
  then driven to zero for four seconds. An electrical open-circuit variant is also
  checked. The unit command is a normalization, not a recommendation to operate
  hardware at a particular unapproved level.
- Pulse ripple is the distal speed minus the inertia-weighted assembly speed.
  It is not total wheel speed, angular displacement, or passenger acceleration.
- Four nominal design options meet the stated fixed-voltage criteria. Their
  usefulness differs: the shaft damper retains steady-speed gain; increased
  resistance, reduced motor constant and motor-side damping reduce drive response.
  The equal-final-speed comparison quantifies this limitation.
- These are **model-based parameter targets**, not purchased components or
  experimentally tested modifications. Real dampers/motor changes can alter
  stiffness, inertia, resistance, friction, heat and torque limits together.

## Rebuilding the documents

`Presentation_Source/build_documents.py` uses `python-pptx` and `python-docx`
to read `Analysis/report_values.json` and the MATLAB figure files. It performs
layout only. Export the poster through PowerPoint (or run
`export_documents.ps1 -PosterOnly`). Then `render_and_check.py` produces its
thumbnail for the handout. Run the document builder again to include the current
thumbnail, followed by `build_handout_pdf.py`, which lays out the DOCX text,
tables and figures deterministically in three PDF pages using ReportLab.
`render_and_check.py` renders the final PDFs for inspection. The PDF is the
verified three-page layout; Word pagination can vary by version and settings.

The one-page poster is designed for landscape projection. For the required
8.5×11-inch copies, print the PDF in landscape with **Fit to printable area**.
