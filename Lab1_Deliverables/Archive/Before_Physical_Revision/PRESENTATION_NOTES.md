# Ten-minute presentation and preparation

## What to add to the two red boxes

1. **Apparatus photograph:** take a well-lit front or oblique photograph showing
   the entire motor–flywheel–shaft–flywheel path. Label the motor, flywheels 1 and
   2, flexible shaft, distal bearing, motor tachometer and distal tachometer.
   Keep labels off the thin shaft itself. The supplied rig photos can be used
   if they provide the required clarity.
2. **CAD/schematic:** a new detailed CAD model is not required by the task letter.
   A simple labeled assembly screenshot or a clean two-inertia schematic is
   sufficient. Show `Jc = Jm + Jf`, the distal `Jf`, shaft `K` and `Bs`, motor-side
   `Bm`, distal `Bb`, voltage input `Vin`, and angular-speed output `ω2`. Include
   the motor electrical model (`Rm`, `Km`, optional `Lm`) if it remains legible.
   The handout supplies the equations.

Replace only the red placeholders in the editable poster. Do not replace data
plots with photographs of plots. Re-export the poster PDF and update the handout
thumbnail after adding the images.

## Talk timing

- **0:00–1:00 — Problem and recommendation.** Mesa needs four ways to reduce shaft
  vibration by at least 30%. The leading concept is a shaft-path damper because
  it attenuates relative motion while preserving modeled steady-speed response.
- **1:00–3:00 — Measurements.** Explain the two flywheels, torque transmission,
  frequency sweeps and decay experiments. Distinguish the locked-side tests from
  the mechanically uncoupled motor coastdown.
- **3:00–5:00 — Model adequacy.** Point to the measured 5.65-Hz resonance and the
  model's 5.69-Hz prediction. The rigid-shaft limit cannot reproduce the torsional
  peak. Describe stiffness refinement and the measured/model residuals without
  claiming perfect agreement.
- **5:00–6:15 — Sensitivity.** Changing a diameter can move the peak without
  lowering it. All 12 parameters were screened; Rm, Km, Bm and Bs most strongly
  affect the tracked peak height.
- **6:15–8:30 — Four options.** Show the parameter targets and both gain and pulse
  reductions. Explain why the damping changes are much larger when the switching
  transient must also improve. Note that the shaft-damper design eliminates the
  local peak, so its gain statistic covers the measured 4–10 Hz band.
- **8:30–10:00 — Decision and next experiment.** Recommend testing a shaft-path
  damper with effective `Bs = 0.039 N·m·s/rad`. State its large required damping
  change and the need to measure linked stiffness, inertia and heating. The other
  three concepts trade vibration against steady-speed response.

Distribute these sections among the team members. Practice aloud without reading
from phones or cards; leave time for transitions. The cutoff is ten minutes.

## Questions to prepare for

- **How does the evidence implicate flexibility?** The two-inertia flexible model
  reproduces the measured resonant feature and phase transition. The rigid-shaft
  limit has no torsional mode. This supports the mechanism in the test rig;
  it is not a measurement of vibration in a full vehicle.
- **Does zero damping mean a rigid shaft?** No. A rigid shaft constrains relative
  rotation; damping removes energy, while stiffness relates twist to torque.
- **Were four new designs tested?** No. The measurements characterize the original
  apparatus; the modifications are predictions from the calibrated model.
- **Why not simply change shaft diameter?** It strongly changes stiffness and
  resonance frequency but has little local influence on resonant peak height.
- **Why use viscous damping when coastdown looks nearly linear?** It is an effective
  approximation for frequency-domain comparison. The Coulomb fits are slightly
  better and the approximation is disclosed; physical prototypes must test it.
- **How independent is validation?** One sweep at a time is withheld, but all
  sweeps share the setup. A separate broadband excitation record is also checked;
  its short duration/coarse frequency resolution limits peak accuracy.
- **Does the proposed motor damper hurt operation?** Yes. The chosen fixed-voltage
  target leaves roughly 13% of baseline steady-speed gain. It is a less attractive
  alternative, which is why the shaft-path damper is preferred.
- **Does added resistance actually reduce vibration at equal vehicle speed?** Its
  advantage is smaller when input voltage is rescaled to restore final speed;
  that separate comparison appears in the handout and calculation tables.
- **What does 30% refer to?** Linear response magnitude/cost and the explicitly
  defined torsional-speed ripple. It is not a percent change in dB or a claim
  about measured passenger comfort.
- **What changes together in real hardware?** A new motor changes Km, Rm, inertia
  and friction; a real torsional damper can add stiffness and inertia. Those
  coupled changes need renewed model validation.

## Submission reminders from the supplied instructions

- Session is during the week of September 21, 2026, in GGBL 2541; use your lab's
  assigned start time.
- Bring four printed copies of the poster and handout. Poster copies are 8.5×11.
- Upload poster and handout to both the technical and technical-communication
  Canvas assignments as directed by the poster guide.
- Email both to the GSI at least 30 minutes before the presentation.
- All team members attend the approximately two-hour session and present.
- Allow approximately 10–15 minutes of Q&A after your talk.

Files have been prepared locally; submission and email have not been performed.
