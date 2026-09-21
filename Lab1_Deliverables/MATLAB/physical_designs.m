%% Concrete hardware alternatives; every numerical conversion stays in MATLAB.
% Run after design_changes. Baseline identification is unchanged.
% Changing diameter/density does NOT prescribe a change in viscous damping.
% Keep effective damping fixed for geometry studies, then require remeasurement.
% Relative-speed peak uses omega1-omega2 for ALL designs, independent of inertia.
physicalBaseline=refined;physicalBaseline.driveInertiaFactor=1;physicalBaseline.loadInertiaFactor=1;
[physicalTime,physicalX]=pulseExact(physicalBaseline,'driven',.00025);
physicalBasePeak=max(abs(physicalX(:,2)-physicalX(:,3)));
physicalBaseMetrics=designMetrics(physicalBaseline,NaN);
physicalSolutions=repmat(physicalBaseline,4,1);
% 1: a nominal 1.6-ohm resistor upstream of the existing motor.
physicalSolutions(1).Rm=refined.Rm+1.6;
% 2: distal wheel diameter 165 mm, same steel and 12.7 mm thickness;
% replace shaft with 4.50 mm diameter, same material and 305 mm free length.
physicalSolutions(2).loadInertiaFactor=(165/137)^4;
physicalSolutions(2).Ds=.00450;
% 3: motor-side wheel diameter 105 mm, same steel and thickness;
% replace shaft with 8.00 mm diameter, same material and free length.
physicalSolutions(3).driveInertiaFactor=(105/137)^4;
physicalSolutions(3).Ds=.00800;
% 4: motor-side oil damper, stationary casing bolted to frame.
% Two oil films: 80 mm OD / 10 mm ID steel rotor, 2 mm thick,
% 1.00 mm face gap EACH side, 10,000 cSt silicone oil at 25 deg C.
% Source: Shin-Etsu KF-96 performance data, density 975 kg/m^3.
% https://www.shinetsusilicone-global.com/catalog/pdf/kf96_e.pdf
% Newtonian face shear: dT = mu*(omega*r/h)*(2*pi*r*dr)*r.
% Integrate both faces: c = pi*mu*(Ro^4-Ri^4)/h.
% Edge and seal drag are omitted; actual torque-speed testing is required.
oil=struct('viscosity_cSt',10000,'density_kg_m3',975,'temperature_C',25, ...
    'outerDiameter_mm',80,'innerDiameter_mm',10,'rotorThickness_mm',2,'faceGap_mm',1);
oil.dynamicViscosity_Pa_s=oil.viscosity_cSt*1e-6*oil.density_kg_m3;
oil.addedDamping=pi*oil.dynamicViscosity_Pa_s*(.04^4-.005^4)/.001;
oil.rotorMass_kg=refined.rho*pi*(.04^2-.005^2)*.002;
oil.rotorInertia_kg_m2=.5*oil.rotorMass_kg*(.04^2+.005^2);
physicalSolutions(4).Bm=refined.Bm+oil.addedDamping;
physicalSolutions(4).Jm=refined.Jm+oil.rotorInertia_kg_m2;
labels={'Series resistor','Larger distal wheel + shaft','Smaller motor wheel + shaft','Motor-side oil damper'};
ids={'resistor','distal','motorwheel','oildamper'};
rows=cell(0,18);traces=table(physicalTime,physicalX(:,2)-physicalX(:,3), ...
    'VariableNames',{'Time_s','BaselineRelativeSpeed_rad_s'});
[~,baseOpenX]=pulseExact(physicalBaseline,'open',.00025);
baseOpenPeak=max(abs(baseOpenX(:,2)-baseOpenX(:,3)));
for n=1:4
 q=physicalSolutions(n);m=designMetrics(q,physicalBaseMetrics(1));
 [~,x,~,~,dc]=pulseExact(q,'driven',.00025);[~,xo]=pulseExact(q,'open',.00025);
 relative=x(:,2)-x(:,3);relativePeak=max(abs(relative));
 [jf,jc,k]=geometry(q);[~,denPhysical]=coefficients(q);
 assert(all(real(roots(denPhysical))<0));
 peakRed=100*(1-m(2)/physicalBaseMetrics(2));costRed=100*(1-m(3)/physicalBaseMetrics(3));
 pulseRed=100*(1-relativePeak/physicalBasePeak);
 % Check full-inductance response at fine frequencies including BOTH resonances.
 ftest=unique([linspace(.1,80,24000),linspace(physicalBaseMetrics(1)-.5,physicalBaseMetrics(1)+.5,1501), ...
    linspace(m(1)-.5,m(1)+.5,1501)]);ftest=ftest(isfinite(ftest)&ftest>0);
 hFull=responseWithInductance(q,ftest);hBaseFull=responseWithInductance(physicalBaseline,ftest);
 ix=find(abs(hFull(2:end-1))>abs(hFull(1:end-2))&abs(hFull(2:end-1))>=abs(hFull(3:end)))+1;
 ib=find(abs(hBaseFull(2:end-1))>abs(hBaseFull(1:end-2))&abs(hBaseFull(2:end-1))>=abs(hBaseFull(3:end)))+1;
 if isempty(ix),fullPeak=max(abs(responseWithInductance(q,linspace(4,10,2401))));else,fullPeak=max(abs(hFull(ix)));end
 fullPeakRed=100*(1-fullPeak/max(abs(hBaseFull(ib))));
 rows(end+1,:)={ids{n},labels{n},m(1),m(2),peakRed,costRed,pulseRed, ...
  dc/baseDC,100*(1-(relativePeak/dc)/(physicalBasePeak/baseDC)), ...
  100*(1-max(abs(xo(:,2)-xo(:,3)))/baseOpenPeak),jc,jf,k, ...
  max(abs(x(:,4))),max(abs(x(:,2))),max(abs(x(:,1))),logical(m(5)),fullPeakRed};
 traces.([ids{n} '_RelativeSpeed_rad_s'])=relative;
 assert(min([peakRed costRed pulseRed fullPeakRed])>=30,'Physical design misses nominal target');
end
physicalDesigns=cell2table(rows,'VariableNames',{'ID','Option','Resonance_Hz','PeakGain_rad_s_V','PeakReduction_pct', ...
 'MovingCostReduction_pct','TransientReduction_pct','DCGainRatio','EqualSpeedTransientReduction_pct', ...
 'OpenOffReduction_pct','DriveInertia_kg_m2','LoadInertia_kg_m2','Stiffness_Nm_rad', ...
 'PeakCurrent_A_per_V','PeakMotorSpeed_rad_s_per_V','PeakTwist_rad_per_V','LocalResonanceExists','FullInductancePeakReduction_pct'});
physicalHardware=struct();physicalHardware.oil=oil;
physicalHardware.baselineWheelMass_kg=refined.rho*pi*.137^2/4*.0127;
physicalHardware.distalWheelMass_kg=refined.rho*pi*.165^2/4*.0127;
physicalHardware.motorWheelMass_kg=refined.rho*pi*.105^2/4*.0127;
physicalHardware.addedResistor_ohm=1.6;
physicalHardware.totalResistance_ohm=physicalSolutions(1).Rm;
physicalHardware.resistorPeakPower_W_per_V2=physicalDesigns.PeakCurrent_A_per_V(1)^2*1.6;
physicalHardware.resistorStallPower_W_per_V2=1.6/physicalSolutions(1).Rm^2;
physicalHardware.damperPeakPower_W_per_V2=oil.addedDamping*physicalDesigns.PeakMotorSpeed_rad_s_per_V(4)^2;
physicalHardware.resistorStallPowerAt12V_W=physicalHardware.resistorStallPower_W_per_V2*12^2;
physicalHardware.oilTorqueAt1rad_s_Nm=oil.addedDamping;
% Finite geometry options update inertia, stiffness and optional rotor inertia.
% Expanded +/-1% parameter screen justifies separate flywheel choices.
physicalSensRows=cell(0,4);
for nm={'Rm','Km','Bs','Bm','driveInertiaFactor','loadInertiaFactor','Ds','Ls','rho','Df','Lf','Jm','Bb','Gs'}
 minus=physicalBaseline;plus=physicalBaseline;
 minus.(nm{1})=minus.(nm{1})*.99;plus.(nm{1})=plus.(nm{1})*1.01;
 mm=designMetrics(minus,physicalBaseMetrics(1));mp=designMetrics(plus,physicalBaseMetrics(1));
 physicalSensRows(end+1,:)={nm{1},(mp(2)-mm(2))/(.02*physicalBaseMetrics(2)), ...
    (mp(3)-mm(3))/(.02*physicalBaseMetrics(3)),(mp(4)-mm(4))/(.02*physicalBaseMetrics(4))};
end
writetable(cell2table(physicalSensRows,'VariableNames',{'Parameter','TrackedPeakSensitivity','MovingCostSensitivity','OriginalBandCostSensitivity'}),fullfile(outFolder,'physical_parameter_sensitivity.csv'));
writetable(physicalDesigns,fullfile(outFolder,'physical_recommended_designs.csv'));
writetable(traces,fullfile(outFolder,'physical_transient_traces.csv'));
summary.physicalDesigns=table2struct(physicalDesigns);summary.physicalHardware=physicalHardware;
summary.baselineRelativeSpeedPeak=physicalBasePeak;
summary.physicalSwitchingMetric='max abs(omega_motor - omega_distal), same +1 V / driven 0 V pulse';
fid=fopen(fullfile(outFolder,'report_values.json'),'w');fwrite(fid,jsonencode(summary,PrettyPrint=true));fclose(fid);
fid=fopen(fullfile(outFolder,'physical_verification.json'),'w');fwrite(fid,jsonencode(struct('allFourTargetsPass',true, ...
 'sampleInterval_s',.00025,'allStable',true,'fullInductancePeakAlsoPasses',true),PrettyPrint=true));fclose(fid);
disp(physicalDesigns);disp(physicalHardware);
