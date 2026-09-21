# Physical design specifications and interpretation

These are four independent alternatives starting from the original rig. They are
dimensioned prototype concepts, with nominal model predictions. The team still
needs to verify fit, fabricate or fit parts, and repeat the measurements. The
poster and handout distinguish this from experimentally demonstrated improvement.

## Baseline and selection

The course model uses two solid cylindrical steel flywheels, each 137 mm diameter
and 12.7 mm thick, density 7,755 kg/m³. The original shaft has 3.18 mm diameter,
305 mm free length, and the course-specified material. The effective shaft
stiffness was fitted to the supplied sweeps; its correction factor is retained
when shaft diameter changes in the nominal design model.

The original 12-parameter screen remains available. Separating the motor-side
and distal flywheel inertias reveals strong peak-height sensitivities that a
simultaneous change of both wheels hides. Among the expanded variables, resistance
and the two independent wheel inertias are strong practical directions. Motor-side
damping offers a fourth physical alternative. A lower motor constant would require
re-identifying a replacement motor's coupled properties; a large shaft-damping
target lacks a simple, demonstrated geometry-to-damping conversion. Those abstract
targets remain calculation studies rather than the current hardware recommendations.

Changing wheel diameter changes inertia. Changing shaft diameter changes
stiffness. Neither change establishes a specified increase in viscous damping.
Geometry designs retain the measured loss coefficients as an assumption, which
must be checked after assembly. Each wheel change is paired with a thicker shaft
because reducing the resonance peak alone did not also meet the switching target.

## 1. Add a resistor

- Add a **1.6 Ω series power resistor** between the source and existing motor.
- Total modeled resistance is approximately **4.095 Ω**.
- Define input voltage upstream of the resistor, consistently with the model.
- Choose tolerance, continuous/pulse rating and mounting for the actual current,
  voltage and duty cycle. MATLAB exports the current and heat calculations.
- At a hypothetical 12 V stalled-motor condition, resistor dissipation is about
  **13.7 W**. A **25 W chassis-mounted part** is a candidate only when its specified
  heat sink and ambient derating support that load. This is not approval of a
  particular drive voltage or a claim that a loose 25 W part has that rating.

Vishay's RH/NH series provides chassis-mounted power-resistor construction and
heat-sink-dependent ratings; its non-inductive NH version is also described in
the [official RH/NH datasheet](https://www.vishay.com/docs/30201/rhnh.pdf).
No supplier stock or exact purchased part has been assumed.

## 2. Larger distal flywheel and thicker shaft — first prototype

- Replace **only the distal flywheel**: **137 → 165 mm** diameter.
- Retain **12.7 mm thickness** and the original steel.
- Replace the shaft: **3.18 → 4.50 mm** diameter, **305 mm free length**.
- Retain the motor-side wheel. Use hub bores/clamps that fit the new shaft.
- Check the actual bearing interface, radial clearance and wheel balance in CAD.
- The solid-wheel mass estimate rises from **1.45 to 2.11 kg**. Holes and actual
  hub geometry should be included once the team supplies the final CAD.

This option preserves nominal steady speed at equal voltage. It is the preferred
mechanical prototype because its predicted resonance remains near the upper end
of the measured frequency range. The larger wheel increases bearing load and
changes acceleration; steady speed alone does not describe those effects.

## 3. Smaller motor-side flywheel and thicker shaft — wider tests required

- Replace **only the motor-side flywheel**: **137 → 105 mm** diameter.
- Retain **12.7 mm thickness** and the original steel.
- Replace the shaft: **3.18 → 8.00 mm** diameter, **305 mm free length**.
- Retain the distal flywheel; fit matching hub bores/clamps and check all supports.
- Extend the frequency sweep to **60 Hz**, covering the predicted mode near 50 Hz.

The thicker shaft remains flexible in the model; no rigid-shaft comparison is
needed on the poster. This option is less mature than option 2 because its mode
lies far outside the 4–10 Hz validation data. The diameter was increased after a
joint-compliance sensitivity check showed that a smaller shaft could miss the
switching target. Even this revised design requires actual stiffness measurement.

## 4. Motor-side oil damper — low priority because of continuous drag

- Fix a sealed casing to the stationary frame; couple its rotor to the
  **motor-side hub**, so it resists absolute motor-side speed.
- Steel annular rotor: **80 mm outside diameter, 10 mm bore, 2 mm thickness**.
- Leave a **1.00 mm oil film on each flat face**.
- Use **10,000 cSt silicone fluid**, evaluated at **25°C**.
- Show a CAD section with rotor, both face gaps, shaft adapter, seals and the
  stationary casing. Allow radial clearance so the disk does not touch the casing.
- Bearings/supports must carry the mechanical loads; the oil films provide drag.

The [Shin-Etsu KF-96 performance data](https://www.shinetsusilicone-global.com/catalog/pdf/kf96_e.pdf)
lists 10,000 cSt fluid with specific gravity 0.975 at 25°C. These are the source
fluid properties used in our calculation. The proposed damper is our design
concept, not a manufacturer-rated assembly.

Integrating ideal Newtonian shear over both rotor faces gives about
**0.0784 N·m·s/rad added damping** (0.0784 N·m torque at 1 rad/s). This converts
the damping target into geometry and fluid choice. The rotor's calculated inertia
is added to the motor-side model. The estimate omits seal friction, rotor-edge
drag, adapter inertia and changes with temperature; measure the assembled
torque-versus-speed curve before using it as a validated coefficient.

This design sacrifices about 88% of nominal steady speed at the same voltage.
Restoring speed by increasing voltage severely worsens the relative-motion
comparison. It is retained as a quantified fourth alternative, not the preferred
vehicle solution.

## Metrics, coupled changes and limits

The current numerical table is `Analysis/physical_recommended_designs.csv`.
It contains peak-height, moving one-hertz-band cost and switching reductions,
steady-speed retention, equal-final-speed comparisons, full-inductance checks,
both wheel inertias, shaft stiffness, peak current and peak twist.

Switching motion means the largest absolute **difference between motor-side and
distal-wheel speeds**, using the same +1 V for four seconds / driven 0 V for four
seconds from rest. This is the same physical metric for different wheel sizes.
The previous inertia-weighted measure is retained only in the earlier parameter
studies. The motion measure describes torsion, not passenger acceleration.

Frequency response uses distal speed divided by source voltage. The one-hertz
cost integrates linear gain over angular frequency, centered on each new peak.
The peak search follows the resonance, so shifting it outside the original band
cannot by itself satisfy the attenuation claim. Motor inductance is retained in
switching simulations and separately checked for the higher-frequency design.

The fitted stiffness correction could instead come from compliant joints.
`Analysis/joint_compliance_scenario.csv` tests that alternative interpretation;
it is a plausible model scenario, not a measured bound or statistical confidence
interval. The final dimensions pass that scenario nominally, but it has little
margin for some geometry changes. Re-identification on the modified rig remains
necessary. The four solutions are selected from the modeled practical candidates;
no global optimum over all possible passive hardware is claimed.

## MATLAB source map

- `MATLAB/physical_designs.m`: physical specifications, conversions, simulations,
  heat calculations, separate-wheel sensitivity and numerical tables.
- `MATLAB/functions/geometry.m`: separate wheel inertias and shaft stiffness.
- `MATLAB/verify_physical_designs.m`: independent equations, finer transient
  sampling, stability/inductance checks and joint-compliance scenario.
- `MATLAB/physical_figures.m`: current design and switching plots.
- `MATLAB/screen_physical_options.m` and `screen_geometry_pairs.m`: preliminary
  one-variable and paired-geometry screens, stored separately from final designs.
- `MATLAB/run_all.m`: reproduce the full analysis from the original data.
