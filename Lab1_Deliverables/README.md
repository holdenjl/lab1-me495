# Gulo 3000 ? revised physical designs

Open **Gulo_3000_Poster.pdf** and **Gulo_3000_Handout.pdf**. The poster is one
16:9 landscape page; the handout is three pages with 12-point body text.
Editable versions are **Gulo_3000_Poster.pptx** and **Gulo_3000_Handout.docx**.

The current recommendations specify a resistor, two wheel/shaft combinations,
and a dimensioned oil-damper concept. The preferred first mechanical prototype
uses a 165 mm distal wheel and a 4.50 mm shaft. Four nominal options meet the
30% peak, one-hertz-band cost and switching criteria. These are predictions;
modified hardware has not been tested. Option 3 needs measurements through 60 Hz.

Two red boxes describe the real apparatus photo and dimensioned CAD views to add.
There are no generated apparatus images. The scientific plots are complete.
The rigid-shaft line was removed from the poster and handout model comparison.

- **EXEMPLAR_REVIEW.md** compares the two new references and explains the redesign.
- **HARDWARE_DESIGNS.md** gives dimensions, mounting details, source links and limits.
- **PRESENTATION_NOTES.md** gives the talk outline and remaining team actions.
- **MATLAB/** contains all engineering calculations as separately filed scripts/functions.
- **Analysis/physical_recommended_designs.csv** is the CURRENT numerical design table.
- **Analysis/physical_verification.json** contains the current verification results.
- **Analysis/joint_compliance_scenario.csv** checks an alternate stiffness interpretation.
- **Figures/** contains PNG, vector PDF/SVG and editable MATLAB FIG plots.

## Reproduce the calculations

Open `MATLAB/run_all.m` and click Run in MATLAB, or run:

```matlab
run('Lab1_Deliverables/MATLAB/run_all.m')
```

Tested using MATLAB R2026a without optional toolboxes. Keep this folder alongside
original `Data/`; paths resolve from the script location. Original data, earlier
student code, and supplied exemplars are unchanged.

| MATLAB file | Purpose |
|---|---|
| characterize_system.m | Import, motor identification, decay/coast fits and loss estimates |
| validate_system_model.m | Sweep processing, effective stiffness refinement and validation diagnostics |
| analyze_sensitivity.m | All 12 course parameters with symmetric 1% perturbations |
| design_changes.m | Earlier ideal parameter studies, retained as supporting calculations |
| physical_designs.m | CURRENT dimensions, separate-wheel sensitivity, linked parameter changes, transient and heat calculations |
| publication_figures.m / physical_figures.m | Publication plots; physical figures replace earlier parameter-only design plots |
| verify_analysis.m / verify_physical_designs.m | Independent dynamics, stability, finer time sampling, inductance and joint-compliance checks |
| screen_physical_options.m / screen_geometry_pairs.m | Optional preliminary design screens, not the final recommendation table |
| functions/ | Individually filed geometry, response, fitting and simulation functions |

`run_all.m` regenerates the final analysis and graphs. The preliminary screen
scripts can be run separately after it. The original 12-parameter study and its
parameter-only recommendations remain in `Analysis/parameter_only_designs.csv`;
they are not the revised poster recommendations. In `report_values.json`, use
`physicalDesigns` and `physicalHardware` for the CURRENT results; `designs` retains
the earlier ideal-parameter study for traceability.

Current switching motion is the maximum absolute difference between the two wheel
speeds. This keeps the metric consistent when inertias change. The earlier study
used an inertia-weighted measure and is labeled separately. All reported reduction
percentages are based on linear response amplitudes, never percentages of dB.

## Rebuild the documents

`Presentation_Source/build_documents.py` calls the current revised builder.
`document_layout.py` supplies formatting helpers; neither performs engineering
calculations. The recommended build order is:

1. Run `build_documents.py --poster-only` with Python.
2. Run `export_documents.ps1 -PosterOnly` to export through PowerPoint.
3. Run `render_and_check.py` to refresh the poster thumbnail.
4. Run `build_documents.py` to include the thumbnail in the handout.
5. Run `build_handout_pdf.py`, then `render_and_check.py` for final PDF inspection.

The Python dependencies are in `Presentation_Source/requirements.txt`. On this
workspace they are available through the local `.task_review_tools` directory.
The PDF handout uses deterministic ReportLab layout from the DOCX content because
native Word PDF export stalled on this host. The PDF is the checked three-page
print version; Word pagination can vary across installations.

The original document version is preserved in `Archive/Before_Physical_Revision/`.
For letter-size poster copies, print landscape and fit to the printable area.
Submission, adding team member names, and taking the requested photo/CAD screenshots
remain team actions. No files were emailed or submitted.
