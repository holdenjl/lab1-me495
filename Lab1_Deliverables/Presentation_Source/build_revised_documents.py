"""Physical-hardware revision. Layout only; all engineering values come from MATLAB."""
from document_layout import *
D=V['physicalDesigns'];HW=V['physicalHardware']
text(.45,.24,23.1,.76,'Physical changes to reduce flexible-shaft vibration',41,True)
text(.48,1.00,23,.33,'Gulo 3000  |  Powertrain Dynamics Group  |  ME 495  |  Experimental characterization and passive design',19,False,GRAY)
box(.45,1.48,23.1,.43,GOLD)
text(.59,1.54,22.8,.33,f'Prototype first: 165 mm distal flywheel + 4.50 mm shaft  |  {D[1]["PeakReduction_pct"]:.0f}% lower peak; {D[1]["TransientReduction_pct"]:.0f}% less switching motion',20,True)
x1,x2,x3=.45,8.25,16.05
header(x1,2.08,7.5,'1  Problem and experimental approach')
text(x1,2.78,7.5,.67,'Motor switching excites twist between the flywheels.\nTask: explain the vibration and find four ≥30% solutions.',19)
placeholder(x1,3.61,7.5,1.75,'PHOTO TO TAKE — complete test rig',
 'Take a clear front/oblique photo. Label the motor, motor-side flywheel, flexible shaft, distal flywheel and both speed sensors. Keep all components visible.')
placeholder(x1,5.58,7.5,2.14,'CAD SCREENSHOTS TO ADD — physical changes',
 'Show the baseline assembly beside option 2: a 165 mm distal wheel and 4.50 mm shaft. Dimension both. Add a small section view of option 4: an 80 mm oil-damper rotor, 1 mm gaps on each face, and a casing fixed to the frame.')
for i,lab in enumerate(['MEASURE','IDENTIFY','VALIDATE','COMPARE']):
 box(x1+i*1.90,8.02,1.79,.49,PALE);text(x1+i*1.90+.05,8.13,1.69,.27,lab,16,True,TEAL,PP_ALIGN.CENTER)
text(x1,8.80,7.5,.37,'3 frequency sweeps + 28 time recordings',21,True)
text(x1,9.36,7.5,1.03,'Steady runs identify the motor. Free-decay and coastdown tests estimate losses. Sweep data refine shaft stiffness and check the flexible model.',19)
table(x1,10.46,[3.6,3.9],[['Measured / identified','Baseline value'],['Resonance',f'{V["measuredResonance"]:.2f} Hz'],
 ['Motor resistance',f'{P["Rm"]:.3f} Ω'],['Effective shaft stiffness',f'{V["K_refined"]:.3f} N·m/rad']],.38,17)
text(x1,12.17,7.5,.59,'Coastdown: motor physically uncoupled; both flywheels stayed linked by the shaft.',16,False,GRAY)
header(x2,2.08,7.5,'2  The flexible model matches the data')
image('model_validation',x2,2.76,7.5,4.48)
table(x2,7.40,[3.42,2.04,2.04],[['Validation metric','Measured','Model'],
 ['Resonance frequency',f'{V["measuredResonance"]:.2f} Hz',f'{V["modelResonance"]:.2f} Hz'],
 ['Peak gain (rad/s/V)',f'{V["measuredPeak"]:.2f}',f'{V["modelPeak"]:.2f}']],.38,17)
text(x2,8.67,7.5,.41,f'4–10 Hz fit error: {V["refinedMagnitudeRMSE"]:.2f} dB in gain; {V["refinedPhaseRMSE"]:.2f}° in phase.',17,False,GRAY)
text(x2,9.23,7.5,.38,'Option 2 also reduces switching motion',21,True)
image('switching_transient',x2,9.82,7.5,2.20)
text(x2,12.18,7.5,.59,'Simulation: +1 V for 4 s, then 0 V. Motion = difference between the two wheel speeds.',16,False,GRAY)
header(x3,2.08,7.5,'3  Four physical design alternatives')
image('four_designs',x3,2.77,7.5,4.50)
text(x3,7.34,7.5,.40,'Dotted line: 30% peak reduction. Shading: beyond measured data.',15.6,False,GRAY)
table(x3,7.91,[3.9,1.80,1.80],[['Alternative','Peak ↓','Motion ↓']]+[[f'{i+1}  '+['Series resistor','Larger distal wheel + shaft','Smaller motor wheel + shaft','Motor-side oil damper'][i],f'{d["PeakReduction_pct"]:.0f}%',f'{d["TransientReduction_pct"]:.0f}%'] for i,d in enumerate(D)],.38,16.5)
text(x3,10.06,7.5,.43,'All four also reduce the 1-Hz response cost by ≥30%.',17,True,TEAL)
text(x3,10.69,7.5,1.23,'1  Wire a 1.6 Ω power resistor in series; steady speed falls 29%.\n2  Fit a 165 mm distal wheel + 4.50 mm shaft; preserves speed.\n3  Fit a 105 mm motor wheel + 8.00 mm shaft; retest to 60 Hz.\n4  Add an oil rotor in a fixed casing; steady speed falls 88%.',16.5)
text(x3,12.18,7.5,.44,'Full dimensions, mounting details and limitations: handout p. 3.',16,False,GRAY)
box(.45,12.83,23.1,.035,GOLD)
text(.48,13.00,23,.28,'Model predictions at equal voltage; modified hardware has not been tested. Geometry changes stiffness/inertia; extra damping needs a physical dissipater. Sources: task letter; Lab 1_1 / 1_2; handout references.',13.5)
slide.notes_slide.notes_text_frame.text=('10-minute talk: problem and prototype recommendation (1 min), experiments (2 min), model/data comparison (2 min), physical alternatives and switching evidence (3 min), tradeoffs and next tests (2 min). '
 'Sensitivity screened all course parameters, then treated the two flywheels separately. Both-wheel diameter changes mainly shift resonance; independent wheel sizes can reduce peak height. '
 'The thicker shaft reduces switching motion while the changed wheel inertia lowers the tracked peak. Option 3 predicts a 49.9 Hz mode, beyond the measured 4–10 Hz range: it needs a wider sweep. '
 'The oil damper uses two-face Newtonian shear at 25°C, with rotor inertia included; seal and edge drag need measurement. '
 'All four are separate alternatives starting from baseline. Percent reductions use linear gain, never dB. Input voltage is upstream of the added resistor. '
 'At equal final speed, the resistor and oil damper lose much of their benefit. Red boxes specify the photo/CAD to add.')
prs.save(OUT/'Gulo_3000_Poster.pptx')
if '--poster-only' in sys.argv:print('Revised poster written.');sys.exit(0)
doc.styles['Normal'].font.size=DPt(12)
doc.styles['Normal'].paragraph_format.line_spacing=1.06
doc.styles['Normal'].paragraph_format.space_after=DPt(5)
doc.styles['Heading 1'].font.size=DPt(13)
para('Reducing flexible-shaft vibration','Title')
head('1 / What we investigated')
para('The Gulo 3000 task asks us to explain vibration when the motor switches on or off and identify four passive changes that reduce it by at least 30%. We used the supplied bench measurements to build and check a model, then compared physical modifications. No modified hardware has been tested. [1,2]')
thumb=OUT/'Presentation_Source/poster_thumbnail.png'
if thumb.exists():
 p=doc.add_paragraph();p.add_run().add_picture(str(thumb),width=DInches(5.5))
caption('Poster overview. Red boxes describe the apparatus photo and CAD views the team still needs to add.')
head('The main finding')
para(f'The measurements show a resonance near {V["measuredResonance"]:.2f} Hz: repeated voltage changes near this frequency produce unusually large speed oscillations. The flexible-shaft model reproduces this peak near {V["modelResonance"]:.2f} Hz. This supports shaft twisting as a cause of the bench vibration; it does not establish passenger comfort in the vehicle.')
head('Recommended first prototype')
para(f'Replace only the distal flywheel with a 165 mm diameter steel wheel, and use a 4.50 mm diameter shaft of the original material. Keep wheel thickness at 12.7 mm and shaft free length at 305 mm. The model predicts a {D[1]["PeakReduction_pct"]:.0f}% lower resonance peak and {D[1]["TransientReduction_pct"]:.0f}% less switching motion, while preserving steady speed at the same voltage.')
head('How the evidence was collected')
para('Three sweeps covered 4–10 Hz. Another 28 recordings captured steady motor operation, free vibration and coastdown. Steady runs identified motor resistance and the relationship between speed and generated voltage. Decay tests estimated energy losses. Only effective shaft stiffness was adjusted to improve the sweep fit.')
para('For the motor-disconnected coastdowns, the motor was physically uncoupled and both flywheels remained connected by the shaft. Their combined inertia was therefore used in the calculations. Duplicate copies of the data were not counted as extra tests.')
doc.add_page_break();head('2 / Why these changes should help')
pic('model_validation',5.5)
caption('Measured points and the flexible-shaft model. Gain means distal-wheel speed response per volt; phase shows its timing relative to the voltage. The large gain near 5.7 Hz is the resonance.')
dtable([['Comparison','Measured','Model'],['Resonance frequency',f'{V["measuredResonance"]:.2f} Hz',f'{V["modelResonance"]:.2f} Hz'],['Peak gain',f'{V["measuredPeak"]:.2f} rad/s/V',f'{V["modelPeak"]:.2f} rad/s/V']],[3.4,2,2],10)
para(f'Across 4–10 Hz, the average fit error is {V["refinedMagnitudeRMSE"]:.2f} dB in gain and {V["refinedPhaseRMSE"]:.2f}° in phase, using root-mean-square error. Leaving one sweep out and checking a separate broadband record supported the comparison, with larger errors retained in the analysis files.')
head('What counts as a successful change?')
para('We checked three things: the height of the new resonance peak, the response across a one-hertz band around that peak, and the largest difference between the two wheel speeds after switching. Each proposed option reduces all three by at least 30% in the nominal model. Moving the peak away from 5.7 Hz alone does not count as reducing its height.')
para('All switching comparisons start at rest, apply the same voltage for four seconds, then drive the input to zero for four seconds. The resistor and oil damper also slow the system; their switching benefit is much smaller if voltage is raised to restore the original speed.')
head('How we chose the hardware')
para('Small-change sensitivity tests screened all course parameters, then treated the flywheels separately. Independent flywheel sizes strongly affect peak height. A thicker shaft helps switching motion but barely lowers the peak by itself, so wheel changes are paired with shaft changes. Changing both wheel sizes together mainly shifts resonance.')
para('Resistance and motor-side damping remain physical alternatives. A lower motor constant was dropped because replacing a motor changes other properties too. A large shaft-damping target was dropped because shaft diameter or density cannot establish that damping increase. Detailed equations and sensitivity tables remain in the separate MATLAB folder.')
doc.add_page_break();head('3 / Four alternatives: what to change')
para('Each option starts from the original rig; do not combine the four sets of numbers. All percentages below are predictions at the same voltage. Replacement shafts use the original shaft material; replacement wheels use the original steel.')
dtable([['Alternative','Peak ↓','Switching ↓','Speed kept']]+[[f'{i+1}. '+['Series resistor','Larger distal wheel + shaft','Smaller motor wheel + shaft','Oil damper'][i],f'{d["PeakReduction_pct"]:.0f}%',f'{d["TransientReduction_pct"]:.0f}%',f'{100*d["DCGainRatio"]:.0f}%'] for i,d in enumerate(D)],[3.35,1.05,1.40,1.60],10)
head('1. Add a 1.6 Ω power resistor — simplest trial')
para(f'Wire it between the source and motor; total resistance becomes {HW["totalResistance_ohm"]:.2f} Ω. Measure input voltage upstream. Mount a power-rated part to its specified heat sink. Size it for actual voltage/current: at 12 V, the calculated stalled-motor load on this resistor is {HW["resistorStallPowerAt12V_W"]:.1f} W. This is a sizing example, not a prescribed test voltage. Expect lower speed and starting torque. [4]')
head('2. Enlarge the distal wheel and thicken the shaft — preferred')
para(f'Distal wheel: 137 → 165 mm diameter, still 12.7 mm thick. Shaft: 3.18 → 4.50 mm diameter, still 305 mm free length. Keep the motor-side wheel unchanged. Fit matching hubs/clamps; check bearing clearance and balance. Wheel mass rises from {HW["baselineWheelMass_kg"]:.2f} to {HW["distalWheelMass_kg"]:.2f} kg. Predicted resonance: {D[1]["Resonance_Hz"]:.1f} Hz.')
head('3. Reduce the motor-side wheel and thicken the shaft — conditional')
para(f'Motor-side wheel: 137 → 105 mm diameter, still 12.7 mm thick. Shaft: 3.18 → 8.00 mm diameter, still 305 mm free length. Keep the distal wheel unchanged; fit matching hubs/clamps. Steady speed is preserved, but the predicted {D[2]["Resonance_Hz"]:.1f} Hz resonance is outside the measured range. Extend testing to 60 Hz before relying on this option.')
head('4. Add a motor-side oil damper — lowest priority')
para('Attach an 80 mm diameter, 2 mm thick steel rotor with a 10 mm bore to the motor-side hub. Enclose it in a sealed casing fixed to the frame. Leave a 1 mm oil gap on each flat face; fill with 10,000 cSt silicone oil. At 25°C, the face-shear estimate gives 0.078 N·m of drag at 1 rad/s. Rotor inertia is included. Test actual torque versus speed: seals, edge drag and temperature affect it. Continuous drag leaves only 12% of steady speed. [5]')
head('Before claiming success')
para('Add the photo and dimensioned CAD views requested in the red boxes. Check fit; remeasure stiffness and losses after assembly. Repeat switching tests and sweep through the new peak. A separate check allowing joint flexibility still predicts about 33% and 31% motion reductions for options 2 and 3; this smaller margin makes stiffness measurement important. Oil damping also needs measurement.')
caption('[1] ME 495 Task Letter Lab 1, Sept. 4, 2026. [2] Lab 1_1 / Lab 1_2; Flexible Shaft Student Guide. [3] F26 ME495 Posters-1 and supplied exemplars (format). [4] Vishay RH/NH: vishay.com/docs/30201/rhnh.pdf. [5] Shin-Etsu KF-96: shinetsusilicone-global.com/catalog/pdf/kf96_e.pdf. Full calculations and sources: MATLAB/ and HARDWARE_DESIGNS.md.')
doc.save(OUT/'Gulo_3000_Handout.docx');print('Revised editable poster and handout written.')
