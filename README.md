# ME 495 — Gulo 3000 flexible-shaft lab

Complete lab workspace: original measurements and course references, photographs,
earlier analysis, revised poster/handout, and separately organized MATLAB calculations.

## Start here

- [Poster PDF](Lab1_Deliverables/Gulo_3000_Poster.pdf) · [Editable PowerPoint](Lab1_Deliverables/Gulo_3000_Poster.pptx)
- [Three-page handout PDF](Lab1_Deliverables/Gulo_3000_Handout.pdf) · [Editable Word document](Lab1_Deliverables/Gulo_3000_Handout.docx)
- [Physical hardware specifications](Lab1_Deliverables/HARDWARE_DESIGNS.md)
- [Poster exemplar review](Lab1_Deliverables/EXEMPLAR_REVIEW.md)
- [MATLAB calculations](Lab1_Deliverables/MATLAB/) · [Run the full analysis](Lab1_Deliverables/MATLAB/run_all.m)
- [Detailed reproduction instructions](Lab1_Deliverables/README.md)

The recommended first prototype uses a 165 mm distal flywheel and a 4.50 mm shaft.
The nominal model predicts about 44% lower resonance peak and 39% less switching
motion while preserving steady speed at equal voltage. The four alternatives
are model predictions; modified hardware has not been tested. The smaller
motor-side wheel option requires validation through 60 Hz.

The poster intentionally contains red boxes describing the real apparatus photo
and dimensioned CAD views the team still needs to add.

## Workspace contents

| Folder/file | Contents |
|---|---|
| `Data/` | Original measured data exports |
| `lab instructions/` | Task letter, slides, lab guides and poster guidance/examples |
| `Pictures/` | Original apparatus photographs |
| `Matlab code/` | Earlier supplied MATLAB script |
| `matlab stuff/` | Earlier analysis, renamed data copies and figures |
| `Lab 1.pptx` | Original supplied PowerPoint file |
| `Lab1_Deliverables/` | Current documents, all calculation code, results, figures, document builders and archived earlier deliverables |

Run `Lab1_Deliverables/MATLAB/run_all.m` in MATLAB R2026a to reproduce the final
analysis from the original `Data/` folder. No optional MATLAB toolbox is required.
Numerical tables and verification results are in `Lab1_Deliverables/Analysis/`.

The repository preserves original data bytes. Local tool installations,
dependency caches and temporary application lock files are excluded; all project
data, references, editable documents, results and source code are included.
