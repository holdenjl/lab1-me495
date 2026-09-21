%% Rank actual peak attenuation and quantify four feasible directions.
% Absolute percentages use LINEAR magnitudes. Cost is integrated over d(omega).
% Tracking the new resonance prevents detuning being counted as attenuation.
names={'Rm','Km','Bs','Bm'};
labels={'Added series resistance','Lower motor constant','Shaft-path damper','Motor-side damper'};
directions=[1,-1,1,1];maxFactors=[10,.05,100,100];
[tb,xb,rb,baseRipple,baseDC]=pulseExact(refined);
[~,~,~,baseOpen]=pulseExact(refined,'open');
base=designMetrics(refined,NaN);center=base(1);
desRows=cell(0,15);resRows=cell(0,8);thresholdRows=cell(0,4);solutions=repmat(refined,4,1);
transientExport=table(tb,xb(:,2),xb(:,3),rb,'VariableNames', ...
    {'Time_s','BaselineMotor_rad_s','BaselineDistal_rad_s','BaselineRipple_rad_s'});
for k=1:4
    name=names{k};direction=directions(k);
    scan=linspace(0,log(maxFactors(k)),161);screen=zeros(numel(scan),7);
    for j=1:numel(scan)
        q=refined;q.(name)=q.(name)*exp(scan(j));m=designMetrics(q,center);
        [~,~,~,pr,dc]=pulseExact(q);
        screen(j,:)=[exp(scan(j)),m(1),m(2)/base(2),m(3)/base(3),m(4)/base(4),pr/baseRipple,dc/baseDC];
    end
    writetable(array2table(screen,'VariableNames',{'Factor','Resonance_Hz','PeakRatio','MovingCostRatio','FixedCostRatio','TransientRatio','DCGainRatio'}), ...
        fullfile(outFolder,['design_' name '.csv']));
    pass=find(max(screen(:,3:4),[],2)<=.7,1);
    assert(~isempty(pass),'No resonance solution for %s',name);
    zlo=scan(pass-1);zhi=scan(pass);
    for j=1:35
        z=(zlo+zhi)/2;q=refined;q.(name)=q.(name)*exp(z);m=designMetrics(q,center);
        if max(m(2)/base(2),m(3)/base(3))<=.7,zhi=z;else,zlo=z;end
    end
    q=refined;q.(name)=q.(name)*exp(zhi);m=designMetrics(q,center);
    [~,~,~,pr]=pulseExact(q);
    resRows(end+1,:)={name,refined.(name),q.(name),exp(zhi),m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),100*(1-pr/baseRipple)};
    % Final recommendations meet resonance peak, moving cost, AND pulse ripple.
    pass=find(max(screen(:,[3 4 6]),[],2)<=.7,1);
    assert(~isempty(pass),'No joint solution for %s',name);
    zlo=scan(pass-1);zhi=scan(pass);
    for j=1:35
        z=(zlo+zhi)/2;q=refined;q.(name)=q.(name)*exp(z);m=designMetrics(q,center);
        [~,~,~,pr]=pulseExact(q);
        if max([m(2)/base(2),m(3)/base(3),pr/baseRipple])<=.7,zhi=z;else,zlo=z;end
    end
    thresholdFactor=exp(zhi);
    thresholdRows(end+1,:)={name,refined.(name),refined.(name)*thresholdFactor,thresholdFactor};
    % Report a practical target with 10% extra parameter change beyond the
    % minimum, rounded outward to two significant digits. This is a design
    % margin, not an experimental confidence bound. Thresholds are saved too.
    proposed=refined.(name)*(1+1.10*(thresholdFactor-1));
    unit=10^(floor(log10(abs(proposed)))-1);
    if direction>0,proposed=ceil(proposed/unit)*unit;else,proposed=floor(proposed/unit)*unit;end
    factor=proposed/refined.(name);
    q=refined;q.(name)=q.(name)*factor;solutions(k)=q;m=designMetrics(q,center);
    [t,x,rr,pr,dc]=pulseExact(q);[~,~,~,prOpen]=pulseExact(q,'open');
    desRows(end+1,:)={name,labels{k},refined.(name),q.(name),factor,100*(factor-1),m(1), ...
        100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),100*(1-m(4)/base(4)), ...
        100*(1-pr/baseRipple),100*(1-prOpen/baseOpen),dc/baseDC,100*(1-(pr/dc)/(baseRipple/baseDC)),logical(m(5))};
    transientExport.([name '_Ripple_rad_s'])=rr;
end
designs=cell2table(desRows,'VariableNames',{'Parameter','Option','Baseline','Proposed','Factor','Change_pct','Resonance_Hz', ...
    'PeakReduction_pct','MovingCostReduction_pct','FixedCostReduction_pct','TransientReduction_pct','OpenOffReduction_pct','DCGainRatio','EqualSpeedTransientReduction_pct','LocalResonanceExists'});
resonanceOnly=cell2table(resRows,'VariableNames',{'Parameter','Baseline','Proposed','Factor','Resonance_Hz','PeakReduction_pct','MovingCostReduction_pct','TransientReduction_pct'});
writetable(designs,fullfile(outFolder,'parameter_only_designs.csv'));
writetable(resonanceOnly,fullfile(outFolder,'resonance_only_designs.csv'));
writetable(cell2table(thresholdRows,'VariableNames',{'Parameter','Baseline','MinimumJointTarget','Factor'}),fullfile(outFolder,'joint_threshold_designs.csv'));
writetable(transientExport,fullfile(outFolder,'transient_traces.csv'));
disp(designs);

%% Geometry screening: update all linked quantities, identify frequency shifts.
screenRows=cell(0,7);
for name={'Df','Lf','rho','Ds','Ls','Gs','Bb'}
    for factor=[.8 1.2]
        q=refined;q.(name{1})=q.(name{1})*factor;m=designMetrics(q,center);
        screenRows(end+1,:)={name{1},factor,m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),100*(1-m(4)/base(4)),m(5)};
    end
end
writetable(cell2table(screenRows,'VariableNames',{'Parameter','Factor','Resonance_Hz','PeakReduction_pct','MovingCostReduction_pct','FixedCostReduction_pct','LocalPeak'}),fullfile(outFolder,'geometry_screen.csv'));

%% An independent excitation record; not used to fit model parameters.
noiseMetrics=struct();noiseTable=table();
for k=1:numel(runs)
    if strcmp(runs(k).key,'last test')
        [noiseTable,noiseMetrics]=noiseResponse(runs(k).A,refined);
        writetable(noiseTable,fullfile(outFolder,'noise_validation.csv'));disp(noiseMetrics);
    end
end

%% Replicate-based design sensitivity (8 combinations, not a confidence interval).
% Refit K for each combination of two ringdowns on each side and two coastdowns.
robRows=cell(0,5);
for a=1:numel(leftB)
 for b=1:numel(rightB)
  for c=1:size(coastRows,1)
    alt=initial;alt.Bb=coastRows{c,3};alt.Bs=leftB(a)-alt.Bb;alt.Bm=rightB(b)-alt.Bs;
    alt=fitStiffness(alt,f,H);ab=designMetrics(alt,NaN);[~,~,~,arp]=pulseExact(alt);
    for k=1:4
        aq=alt;aq.(names{k})=alt.(names{k})*designs.Factor(k);
        am=designMetrics(aq,ab(1));[~,~,~,rrp]=pulseExact(aq);
        robRows(end+1,:)={names{k},sprintf('%d-%d-%d',a,b,c),100*(1-am(2)/ab(2)),100*(1-am(3)/ab(3)),100*(1-rrp/arp)};
    end
  end
 end
end
robustness=cell2table(robRows,'VariableNames',{'Parameter','ReplicateCombination','PeakReduction_pct','CostReduction_pct','TransientReduction_pct'});
writetable(robustness,fullfile(outFolder,'replicate_robustness.csv'));

%% Machine-readable report values: calculations remain entirely in MATLAB.
summary=struct();summary.generated=datestr(now,30);summary.matlabVersion=version;
summary.parameters=refined;summary.Jf=J_f;summary.Jc=J_c;summary.K_geometry=K_geometry;summary.K_refined=Kfit;
summary.Btr=B_tr_selected;summary.Btl=B_tl_selected;summary.motorOffset=motorOffset;summary.motorR2=motorR2;
summary.sweepCount=numel(sweeps);summary.timeRecordCount=numel(runs);summary.rawSweepRows=sum(arrayfun(@(s)size(s.A,1),sweeps));summary.frequencyBins=numel(f);
summary.frequencyRange=[min(f),max(f)];summary.measuredPeak=peakMeasured;summary.measuredResonance=f(ip);
summary.modelResonance=base(1);summary.modelPeak=base(2);summary.modelCost=base(3);
summary.baselineRipple=baseRipple;summary.baselineDCGain=baseDC;
summary.initialMagnitudeRMSE=sqrt(mean((20*log10(abs(H0./H))).^2));summary.initialPhaseRMSE=sqrt(mean((angle(H0./H)*180/pi).^2));
summary.refinedMagnitudeRMSE=sqrt(mean((20*log10(abs(Hfit./H))).^2));summary.refinedPhaseRMSE=sqrt(mean((angle(Hfit./H)*180/pi).^2));
near=f>=5.2&f<=6.2;summary.resonanceRegionMagnitudeRMSE=sqrt(mean((20*log10(abs(Hfit(near)./H(near)))).^2));
summary.noiseValidation=noiseMetrics;summary.designs=table2struct(designs);summary.sensitivity=table2struct(sensitivity);
summary.ringdown=table2struct(readtable(fullfile(outFolder,'ringdown.csv')));summary.coastdown=table2struct(readtable(fullfile(outFolder,'coastdown.csv')));
summary.heldOut=table2struct(readtable(fullfile(outFolder,'held_out_sweeps.csv')));
summary.maxInductanceDifference_dB=max(abs(20*log10(abs(hL./Hfit))));summary.maxInductanceDifference_deg=max(abs(angle(hL./Hfit)*180/pi));
fid=fopen(fullfile(outFolder,'report_values.json'),'w');fwrite(fid,jsonencode(summary,PrettyPrint=true));fclose(fid);
