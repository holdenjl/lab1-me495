%% ME495 REVIEWED COPY: automatic damping and post-disengagement coast fits
% BASE MATLAB ONLY. Save this file, open it, and click Run.
% Original exports may have .txt extensions or no extension.
% MATLAB R2019b or later. No idfrd, tfest, bode, tf or findpeaks required.
% Output: CSV tables, PNG figures, a MAT workspace and analysis_summary.txt.
% Data-backed estimates are kept separate from fitted/design parameters.
clear; clc; close all;

%% SETTINGS: edit here; variable names are consistent throughout this file
dataFolder = '/Users/paidsebs/Documents/me495/lab1 /data';
% Your selected ring-down results. Set BOTH to NaN to use automatic estimates.
B_tr_selected = NaN;       % N*m*s/rad, Bs + Bb
B_tl_selected = NaN;       % N*m*s/rad, Bs + Bm
% NaN means calculate from the appropriate experiments; finite values override.
R_m_override = NaN; K_m_override = NaN; B_b_override = NaN;
K_override = NaN;              % N*m/rad: manual initial stiffness
runStiffnessFit = true;        % Fits K ONLY; other measured parameters stay fixed
createSimulinkModel = false;   % Optional; requires Simulink, never needed for analysis
ringMaxSeconds = 8;            % Ring-down envelope window after largest extremum
ringMinFraction = 0.15;        % Stop fitting when extrema fall below this fraction
% Reviewed windows for YOUR two 'motor disconnected' recordings in data.zip.
% Tach separation occurs around 3.4-3.6 s; start after this transition.
% These are analysis settings, not fitted damping values; inspect saved plots.
coastFitWindow_s = [4.0 19.5];
% Model physics: motor mechanically uncoupled in 'motor disconnected' files;
% BOTH flywheels remain, and distal tach measures their approximately common speed.
% Assign residual external assembly loss to Bb. This is an effective coefficient.

%% Locate data and prepare results
if ~isfolder(dataFolder)
    here=fileparts(mfilename('fullpath'));
    if isfolder(fullfile(here,'data')),dataFolder=fullfile(here,'data');end
end
if ~isfolder(dataFolder)
    selected = uigetdir(pwd,'Select the folder containing your Flexible Shaft exports');
    if isequal(selected,0), error('No folder selected. Set dataFolder above and run again.'); end
    dataFolder = selected;
end
outFolder = fullfile(dataFolder,'ME495_results_reviewed');
if ~isfolder(outFolder), mkdir(outFolder); end
figFolder = fullfile(outFolder,'figures');
if ~isfolder(figFolder), mkdir(figFolder); end
diary(fullfile(outFolder,'analysis_summary.txt')); diary on;
fprintf('ME495 analysis: %s\nData folder: %s\n',datestr(now),dataFolder);

%% Import every recognizable export, including subfolders, without fixed counts
listing = dir(fullfile(dataFolder,'**','*'));
exports = struct('name',{},'key',{},'path',{},'A',{});
inventory = cell(0,5);
for k=1:numel(listing)
    if listing(k).isdir || contains(listing(k).folder,'ME495_results') || ...
            contains(listing(k).folder,'ME495_analysis_package'), continue; end
    path = fullfile(listing(k).folder,listing(k).name);
    fid=fopen(path,'r'); if fid<0, continue; end
    line=fgetl(fid); fclose(fid);
    if ~ischar(line) || ~strcmp(strtrim(line),'Flexible Shaft'), continue; end
    try
        A=readmatrix(path,'FileType','text','Delimiter','\t','NumHeaderLines',6);
        A=A(~all(isnan(A),2),:);
        bad=sum(~all(isfinite(A),2));
        if bad>0, error('%d incomplete numeric rows; inspect this file.',bad); end
        if isempty(A) || ~ismember(size(A,2),[5 12]), error('Expected 5 or 12 numeric columns.'); end
        duplicate=false;
        for j=1:numel(exports)
            if isequal(A,exports(j).A), duplicate=true; break; end
        end
        if duplicate
            inventory(end+1,:)={path,'duplicate excluded',size(A,1),size(A,2),exports(j).name}; %#ok<SAGROW>
            continue;
        end
        key=lower(regexprep(listing(k).name,'(?i)\.txt$',''));
        key=strtrim(regexprep(key,'\(\d+\)$',''));
        exports(end+1)=struct('name',listing(k).name,'key',key,'path',path,'A',A); %#ok<SAGROW>
        inventory(end+1,:)={path,'imported',size(A,1),size(A,2),''}; %#ok<SAGROW>
        fprintf('Imported %s: %d x %d\n',listing(k).name,size(A));
    catch ME
        inventory(end+1,:)={path,'ERROR',0,0,ME.message}; %#ok<SAGROW>
        warning('ME495:Import','%s: %s',listing(k).name,ME.message);
    end
end
writetable(cell2table(inventory,'VariableNames',{'Path','Status','Rows','Columns','Note'}),fullfile(outFolder,'inventory.csv'));
if isempty(exports), error('No Flexible Shaft exports found. Check inventory.csv and dataFolder.'); end
isSweep=arrayfun(@(x)size(x.A,2)==12,exports);
sweeps=exports(isSweep); runs=exports(~isSweep);
fprintf('\nImported %d distinct sweeps and %d distinct time histories.\n',numel(sweeps),numel(runs));
if isempty(sweeps), error('No frequency sweeps found; inspect inventory.csv.'); end

%% Given parameters, geometry and initial model
p=struct('Km',0.097,'Rm',1.6,'Lm',0.002,'Jm',4.23e-5, ...
    'Df',0.137,'Lf',0.0127,'rho',7755,'Ds',3.18e-3,'Ls',0.305, ...
    'Gs',7.31e10,'Bs',0.0012716,'Bb',0.00015721,'Bm',0.0065361,'scaleK',1);
[J_f,J_c,K_geometry]=geometry(p);
fprintf('Jf=%.10g kg*m^2; Jc=%.10g kg*m^2; geometric K=%.10g N*m/rad\n',J_f,J_c,K_geometry);

%% Inspect and plot ALL time histories; do not assign unknown tests a protocol
runRows=cell(0,6);
for k=1:numel(runs)
    A=runs(k).A; steady=max(1,floor(size(A,1)/2)):size(A,1);
    runRows(end+1,:)={runs(k).name,size(A,1),mean(A(steady,2)),mean(A(steady,3)),mean(A(steady,4)),mean(A(steady,5))}; %#ok<SAGROW>
    fig=figure('Visible','off','Color','w');
    subplot(3,1,1);plot(A(:,1),A(:,2));ylabel('Voltage (V)');grid on;title(runs(k).name,'Interpreter','none');
    subplot(3,1,2);plot(A(:,1),A(:,3));ylabel('Current (A)');grid on;
    subplot(3,1,3);plot(A(:,1),A(:,4:5));ylabel('Speed (rad/s)');xlabel('Time (s)');grid on;legend('Distal','Motor');
    saveas(fig,fullfile(figFolder,sprintf('record_%02d.png',k)));close(fig);
end
writetable(cell2table(runRows,'VariableNames',{'File','Samples','LastHalfVoltage_V','LastHalfCurrent_A','LastHalfDistal_rad_s','LastHalfMotor_rad_s'}),fullfile(outFolder,'all_time_records.csv'));

%% Motor resistance: stationary DC tests ONLY, full-record means
resistanceRows=cell(0,4);
for k=1:numel(runs)
    if ismember(string(runs(k).key),["motor resistance","motor resistance 2"])
        A=runs(k).A; V=mean(A(:,2)); I=mean(A(:,3));
        if abs(I)<1e-6, continue; end
        resistanceRows(end+1,:)={runs(k).name,V,I,V/I}; %#ok<SAGROW>
    end
end
if ~isempty(resistanceRows), p.Rm=mean(cell2mat(resistanceRows(:,4)));
else, warning('ME495:MissingR','No named DC resistance tests; using given Rm=1.6 ohm.'); end
if isfinite(R_m_override),p.Rm=R_m_override;end
writetable(cell2table(resistanceRows,'VariableNames',{'File','Voltage_V','Current_A','R_ohm'}),fullfile(outFolder,'resistance.csv'));
% 20-Hz records contain impedance, not simply winding resistance. They are
% preserved in all_time_records.csv and their raw plots; not pooled with DC.

%% Motor constant: regress V - Rm*I = Km*omega + offset across steady tests
motorRows=cell(0,4);
for k=1:numel(runs)
    if contains(runs(k).key,'motor constant')
        A=runs(k).A; ii=max(1,floor(size(A,1)/2)):size(A,1);
        motorRows(end+1,:)={runs(k).name,mean(A(ii,2)),mean(A(ii,3)),mean(A(ii,5))}; %#ok<SAGROW>
    end
end
motorR2=NaN; motorOffset=NaN;
if size(motorRows,1)>=3
    M=cell2mat(motorRows(:,2:4)); y=M(:,1)-p.Rm*M(:,2); X=[M(:,3),ones(size(y))];
    b=X\y; p.Km=b(1); motorOffset=b(2); motorR2=rSquared(y,X*b);
    fig=figure('Color','w');plot(M(:,3),y,'ko');hold on;
    xx=linspace(min(M(:,3)),max(M(:,3)),100);plot(xx,b(1)*xx+b(2),'b-');grid on;
    xlabel('Motor speed (rad/s)');ylabel('V - R_m I (V)');title('Motor constant: slope, with free intercept');
    saveas(fig,fullfile(figFolder,'motor_constant.png'));
else, warning('ME495:MissingKm','Too few motor-constant tests; using given Km=0.097.'); end
if isfinite(K_m_override),p.Km=K_m_override;end
writetable(cell2table(motorRows,'VariableNames',{'File','Voltage_V','Current_A','MotorSpeed_rad_s'}),fullfile(outFolder,'motor_constant.csv'));
fprintf('Motor model: Rm=%.8g ohm; Km=%.8g; intercept=%.6g V; R2=%.6f\n',p.Rm,p.Km,motorOffset,motorR2);

%% Locked-flywheel ring-downs: fit measured extrema, not an assumed split
ringRows=cell(0,8); leftB=[]; rightB=[];
for k=1:numel(runs)
    n=runs(k).key; A=runs(k).A;
    if contains(n,'eraser left side'), channel=4; J=J_f; combination='Btr';
    elseif contains(n,'eraser right side'), channel=5; J=J_c; combination='Btl';
    else,continue;end
    try
        [q,pt,pa,envelope]=ringEstimate(A(:,1),A(:,channel),J,ringMaxSeconds,ringMinFraction);
        ringRows(end+1,:)={runs(k).name,combination,q(1),q(2),q(3),q(4),q(5),numel(pt)}; %#ok<SAGROW>
        if strcmp(combination,'Btr'),leftB(end+1)=q(4);else,rightB(end+1)=q(4);end %#ok<SAGROW>
        fig=figure('Visible','off','Color','w');plot(A(:,1),A(:,channel));hold on;
        plot(pt,pa,'ro',pt,envelope,'k--',pt,-envelope,'k--');grid on;
        xlabel('Time (s)');ylabel('Speed / envelope (rad/s)');title([runs(k).name ' - inspect selected extrema'],'Interpreter','none');
        saveas(fig,fullfile(figFolder,sprintf('ring_%02d.png',k)));close(fig);
        writetable(table(pt,pa,envelope),fullfile(outFolder,sprintf('ring_peaks_%02d.csv',k)));
    catch ME,warning('ME495:Ring','%s: %s',runs(k).name,ME.message);end
end
writetable(cell2table(ringRows,'VariableNames',{'File','Combination','Alpha_per_s','DampedFrequency_Hz','Zeta','B_Nm_s_rad','LogEnvelope_R2','ExtremaUsed'}),fullfile(outFolder,'ringdown.csv'));
B_tr_auto=mean(leftB);B_tl_auto=mean(rightB);
if isnan(B_tr_selected),B_tr_selected=B_tr_auto;end
if isnan(B_tl_selected),B_tl_selected=B_tl_auto;end
fprintf('Automatic diagnostic sums: Btr=%.8g, Btl=%.8g\n',B_tr_auto,B_tl_auto);
fprintf('ACTIVE sums used below: Btr=%.8g, Btl=%.8g N*m*s/rad\n',B_tr_selected,B_tl_selected);

%% Mechanically uncoupled motor, BOTH flywheels: J=2*Jf, distal tach ONLY
coastRows=cell(0,10);
for k=1:numel(runs)
    if ~startsWith(runs(k).key,'motor disconnected'),continue;end
    A=runs(k).A; tAll=A(:,1); yAll=A(:,4);
    inWindow=tAll>=coastFitWindow_s(1) & tAll<=coastFitWindow_s(2);
    if nnz(inWindow)<20
        error('No usable coast interval in %s; inspect coastFitWindow_s.',runs(k).name);
    end
    direction=sign(median(yAll(inWindow)));if direction==0,continue;end
    keep=inWindow & direction*yAll>0;
    t=tAll(keep); fitStart=t(1); t=t-fitStart; y=direction*yAll(keep);
    fprintf('Coast fit %s: %.4f to %.4f s, %d samples\n', ...
        runs(k).name,tAll(find(keep,1)),tAll(find(keep,1,'last')),nnz(keep));
    if numel(y)<20,error('Insufficient moving samples in %s.',runs(k).name);end
    lin=polyfit(t,y,1);lp=polyfit(t,log(y),1);
    start=[log(max(y(1),eps)),log(max(-lp(1),1e-5))];
    z=fminsearch(@(z)mean((exp(z(1))*exp(-exp(z(2))*t)-y).^2),start, ...
        optimset('Display','off','TolX',1e-10,'TolFun',1e-12));
    alpha=exp(z(2));ex=exp(z(1))*exp(-alpha*t);linear=polyval(lin,t);
    B=(2*J_f)*alpha;Tc=-(2*J_f)*lin(1);
    coastRows(end+1,:)={runs(k).name,alpha,B,Tc,rmse(y,ex),rmse(y,linear),lin(1),numel(y),fitStart,tAll(find(keep,1,'last'))}; %#ok<SAGROW>
    fig=figure('Color','w');plot(tAll,direction*yAll,'Color',[.65 .65 .65]);hold on;plot(t+fitStart,ex,'b-',t+fitStart,linear,'r--','LineWidth',1.3);
    grid on;xlabel('Recording time (s)');ylabel('Distal speed (rad/s)');legend('Full recording','Viscous: selected interval','Coulomb: selected interval');
    title(runs(k).name,'Interpreter','none');saveas(fig,fullfile(figFolder,sprintf('coast_%02d.png',k)));
end
writetable(cell2table(coastRows,'VariableNames',{'File','Alpha_per_s','EffectiveBb_Nm_s_rad','CoulombTorque_Nm','ViscousRMSE_rad_s','CoulombRMSE_rad_s','LinearSlope_rad_s2','Samples','FitStart_s','FitEnd_s'}),fullfile(outFolder,'coastdown.csv'));
if ~isempty(coastRows),p.Bb=mean(cell2mat(coastRows(:,3)));end
if isfinite(B_b_override),p.Bb=B_b_override;end
% THREE independent equations under the effective-viscous approximation:
% Bs+Bb=Btr; Bs+Bm=Btl; Bb=Jcoast*alpha.
p.Bs=B_tr_selected-p.Bb;
p.Bm=B_tl_selected-p.Bs;
if any(~isfinite([p.Bb,p.Bs,p.Bm])) || any([p.Bb,p.Bs,p.Bm]<=0)
    error(['Missing/inconsistent damping results. Inspect ringdown.csv and coastdown.csv. ' ...
        'No coefficient was clamped to zero. Use settings to select defensible estimates.']);
end
fprintf('\nBb=%.10g; Bs=%.10g; Bm=%.10g N*m*s/rad\n',p.Bb,p.Bs,p.Bm);
fprintf('Coulomb torque is in N*m; it is NOT substituted into a viscous coefficient.\n');
if isfinite(K_override),p.scaleK=K_override/K_geometry;end
initial=p;

%% Experimental frequency response; average complex response at 0.05-Hz bins
[f,H,frequencyTable]=averageSweeps(sweeps);
writetable(frequencyTable,fullfile(outFolder,'frequency_response.csv'));
[peakMeasured,ip]=max(abs(H));
fprintf('Measured peak: %.7g rad/s/V (%.5f dB) at %.6f Hz\n',peakMeasured,20*log10(peakMeasured),f(ip));
sweepRows=cell(0,8);
for k=1:numel(sweeps)
    A=sweeps(k).A;
    sweepRows(end+1,:)={sweeps(k).name,size(A,1),min(A(:,1)),max(A(:,1)),min(A(:,5)),max(A(:,5)), ...
        sum(diff(round(A(:,1)*20)/20)<0),max(abs(A(:,3)-20*log10(A(:,7)./A(:,5))))}; %#ok<SAGROW>
end
writetable(cell2table(sweepRows,'VariableNames',{'File','Rows','MinHz','MaxHz','MinInputAmplitude_V','MaxInputAmplitude_V','DownwardFrequencySteps','AmplitudeConsistency_dB'}),fullfile(outFolder,'sweep_audit.csv'));

%% Refine K only. Keep measured motor/damping parameters and report fit error
refined=initial;
if runStiffnessFit,refined=fitStiffness(initial,f,H);end
H0=response(initial,f);Hfit=response(refined,f);
[~,~,Kfit]=geometry(refined);
fprintf('K initial=%.7g; refined K=%.7g N*m/rad; geometry multiplier=%.6f\n',K_geometry*initial.scaleK,Kfit,refined.scaleK);
fprintf('Initial RMS errors: %.4f dB, %.4f degrees\n',rmse(20*log10(abs(H)),20*log10(abs(H0))),rmse(zeros(size(H)),angle(H0./H)*180/pi));
fprintf('Refined RMS errors: %.4f dB, %.4f degrees\n',rmse(20*log10(abs(H)),20*log10(abs(Hfit))),rmse(zeros(size(H)),angle(Hfit./H)*180/pi));
fprintf('These are fit residuals, not proof of independent experimental validation.\n');
% Leave-one-sweep-out check: fit other sweeps, evaluate excluded sweep.
cvRows=cell(0,4);
if numel(sweeps)>1
    for k=1:numel(sweeps)
        [ft,ht]=averageSweeps(sweeps((1:numel(sweeps))~=k));[fv,hv]=averageSweeps(sweeps(k));
        pc=fitStiffness(initial,ft,ht);hp=response(pc,fv);[~,~,kc]=geometry(pc);
        cvRows(end+1,:)={sweeps(k).name,kc,rmse(20*log10(abs(hv)),20*log10(abs(hp))),rmse(zeros(size(hv)),angle(hp./hv)*180/pi)}; %#ok<SAGROW>
    end
end
writetable(cell2table(cvRows,'VariableNames',{'HeldOutSweep','FittedK','MagnitudeRMSE_dB','PhaseRMSE_deg'}),fullfile(outFolder,'held_out_sweeps.csv'));
fg=linspace(min(f),max(f),2000)';hg=response(refined,fg);hinit=response(initial,fg);
fig=figure('Color','w');subplot(2,1,1);plot(f,20*log10(abs(H)),'ko',fg,20*log10(abs(hinit)),'b--',fg,20*log10(abs(hg)),'r-');grid on;
ylabel('Magnitude (dB)');legend('Measured','Initial physical model','K refined');
subplot(2,1,2);plot(f,unwrap(angle(H))*180/pi,'ko',fg,unwrap(angle(hinit))*180/pi,'b--',fg,unwrap(angle(hg))*180/pi,'r-');grid on;xlabel('Frequency (Hz)');ylabel('Phase (deg)');
saveas(fig,fullfile(figFolder,'model_comparison.png'));
[numInitial,denInitial]=coefficients(initial);[num,den]=coefficients(refined);
fprintf('Refined numerator coefficients:\n');disp(num);fprintf('Refined denominator coefficients:\n');disp(den);
poles=roots(den);naturalFrequency=abs(poles);zeta=-real(poles)./abs(poles);
writetable(table(poles,naturalFrequency,zeta),fullfile(outFolder,'modal_results.csv'));
% Check neglected inductance using the full electromechanical equations.
hL=responseWithInductance(refined,f);
fprintf('Including given Lm changes prediction by at most %.4f dB / %.4f deg in measured band.\n', ...
    max(abs(20*log10(abs(hL./Hfit)))),max(abs(angle(hL./Hfit)*180/pi)));

%% Shaft-flexibility evidence: compare flexible model with rigid-shaft limit
rigid=refined.Km./(refined.Rm*(2*J_f+refined.Jm)*1i*2*pi*fg+refined.Km^2+refined.Rm*(refined.Bm+refined.Bb));
fig=figure('Color','w');plot(f,abs(H),'ko',fg,abs(hg),'b-',fg,abs(rigid),'k--');grid on;
xlabel('Frequency (Hz)');ylabel('Speed / voltage (rad/s/V)');legend('Measured','Flexible shaft','Rigid shaft');
saveas(fig,fullfile(figFolder,'flexible_vs_rigid.png'));

%% Class cost: integral |H(jw)| dw across a 1-Hz band; NOT an integral of dB
base=designMetrics(refined,NaN);center=base(1);
fprintf('Refined resonance %.5f Hz; peak %.6g; 1-Hz cost %.6g (rad/s/V)*(rad/s)\n',base(1:3));
parameterNames={'Km','Rm','Jm','Df','Lf','rho','Ds','Ls','Gs','Bs','Bb','Bm'};
sensitivityRows=cell(0,5);epsP=.01;
for k=1:numel(parameterNames)
    n=parameterNames{k};plus=refined;minus=refined;plus.(n)=refined.(n)*(1+epsP);minus.(n)=refined.(n)*(1-epsP);
    mp=designMetrics(plus,center);mm=designMetrics(minus,center);
    sensitivityRows(end+1,:)={n,(mp(4)-mm(4))/(2*epsP*base(4)), ...
        (mp(3)-mm(3))/(2*epsP*base(3)),(mp(2)-mm(2))/(2*epsP*base(2)),(mp(1)-mm(1))/(2*epsP*base(1))}; %#ok<SAGROW>
end
sensitivity=cell2table(sensitivityRows,'VariableNames',{'Parameter','FixedBandCostSensitivity','MovingBandCostSensitivity','PeakSensitivity','FrequencySensitivity'});
writetable(sensitivity,fullfile(outFolder,'sensitivity.csv'));disp(sensitivity);
fig=figure('Color','w');bar([sensitivity.FixedBandCostSensitivity,sensitivity.PeakSensitivity]);set(gca,'XTick',1:numel(parameterNames),'XTickLabel',parameterNames);
ylabel('Normalized sensitivity');grid on;legend('Fixed 1-Hz band cost','Moving resonance peak');saveas(fig,fullfile(figFolder,'sensitivity.png'));

%% Four detailed passive attenuation studies; ALSO screen geometry changes
% Larger inertia/changed shaft stiffness often move the peak without lowering
% its height. These are screened, but not counted as peak-reduction successes.
% Rm here means total series resistance. Added resistance reduces drive authority.
designNames={'Rm','Bs','Bm','Bb'};
screenNames=[designNames,{'Df','Ds'}]; designRows=cell(0,9);
for k=1:numel(screenNames)
    name=screenNames{k};factors=unique([logspace(log10(.5),log10(2),241),1]);
    if startsWith(name,'B'),factors=unique([factors,logspace(log10(2),log10(200),241)]);end
    values=zeros(numel(factors),6);
    for j=1:numel(factors)
        q=refined;q.(name)=refined.(name)*factors(j);m=designMetrics(q,center);
        values(j,:)=[factors(j),m(1),m(2)/base(2),m(3)/base(3),m(4)/base(4),m(5)];
    end
    writetable(array2table(values,'VariableNames',{'Factor','Resonance_Hz','PeakRatio','MovingBandCostRatio','FixedBandCostRatio','LocalResonanceExists'}),fullfile(outFolder,['design_' name '.csv']));
    fig=figure('Visible','off','Color','w');semilogx(values(:,1),values(:,3:5),'LineWidth',1.3);hold on;yline(.7,'k--');grid on;
    xlabel([name ' multiplier']);ylabel('Modified / baseline');legend('Peak','Moving-band cost','Fixed-band cost','30% target');title(['One-parameter study: ' name]);
    saveas(fig,fullfile(figFolder,['design_' name '.png']));close(fig);
    acceptable=find(values(:,3)<=.7 & values(:,4)<=.7 & values(:,6)>0);
    if isempty(acceptable)
        fprintf('%s: no design in searched range reduced BOTH moving peak and moving-band cost by 30%%.\n',name);continue;
    end
    [~,a]=min(abs(log(values(acceptable,1))));j=acceptable(a);q=refined;q.(name)=q.(name)*values(j,1);
    designRows(end+1,:)={name,refined.(name),q.(name),values(j,1),values(j,2),100*(1-values(j,3)),100*(1-values(j,4)),100*(1-values(j,5)),numel(acceptable)}; %#ok<SAGROW>
end
designs=cell2table(designRows,'VariableNames',{'Parameter','InitialValue','ProposedValue','Factor','NewResonance_Hz','PeakReduction_pct','MovingCostReduction_pct','FixedCostReduction_pct','PassingGridPoints'});
writetable(designs,fullfile(outFolder,'design_proposals.csv'));disp(designs);
fprintf('Proposals are model predictions on a finite search grid, not experimentally verified designs.\n');

%% Turn-on / driven-zero turn-off simulation: compare torsional-speed ripple
% Four-state ODE retains inductance: [shaft twist; motor speed; distal speed; i].
% Voltage is +1 V for 2 seconds, then driven to zero for 2 seconds.
% This is NOT the electrical open-circuit unplugged test.
fig=figure('Color','w');transientRows=cell(0,4);
[tt,xx,rr]=pulseSimulation(refined);baseRipple=max(abs(rr));
plot(tt,rr,'k-','LineWidth',1.5);hold on;labels={'Baseline'};
transientRows(end+1,:)={'Baseline',baseRipple,max(abs(xx(:,1))),0};
for k=1:height(designs)
    if ~any(strcmp(designs.Parameter{k},designNames)),continue;end
    q=refined;q.(designs.Parameter{k})=designs.ProposedValue(k);[tt,xx,rr]=pulseSimulation(q);
    plot(tt,rr);labels{end+1}=designs.Parameter{k}; %#ok<SAGROW>
    transientRows(end+1,:)={designs.Parameter{k},max(abs(rr)),max(abs(xx(:,1))),100*(1-max(abs(rr))/baseRipple)}; %#ok<SAGROW>
end
grid on;xlabel('Time (s)');ylabel('Distal speed minus inertia-weighted speed (rad/s)');legend(labels,'Location','best');
saveas(fig,fullfile(figFolder,'turn_on_off_ripple.png'));
writetable(cell2table(transientRows,'VariableNames',{'Design','PeakTorsionalSpeedRipple_rad_s','PeakShaftTwist_rad','RippleReduction_pct'}),fullfile(outFolder,'transient_comparison.csv'));

%% Stronger proposals: meet BOTH class resonance and task-letter transient targets
% Search further along the same four levers. A successful row must reduce
% peak, moving 1-Hz-band cost AND this defined pulse ripple by at least 30%.
jointRows=cell(0,9);fig=figure('Color','w');
[tb,~,rb]=pulseSimulation(refined);plot(tb,rb,'k-','LineWidth',1.5);hold on;jointLabels={'Baseline'};
for k=1:height(designs)
    name=designs.Parameter{k};if ~any(strcmp(name,designNames)),continue;end
    upper=10;if startsWith(name,'B'),upper=200;end
    candidates=logspace(log10(designs.Factor(k)),log10(upper),150);found=false;
    for factor=candidates
        q=refined;q.(name)=refined.(name)*factor;
        ripple=fastPulseRipple(q);reduction=100*(1-max(abs(ripple))/baseRipple);
        m=designMetrics(q,center);
        if reduction>=30 && m(5)>0 && m(2)<=.7*base(2) && m(3)<=.7*base(3)
            [tt,~,rr]=pulseSimulation(q);reduction=100*(1-max(abs(rr))/baseRipple);
            if reduction<30,continue;end
            jointRows(end+1,:)={name,q.(name),factor,m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),reduction,max(abs(rr)),q.Bs}; %#ok<SAGROW>
            plot(tt,rr);jointLabels{end+1}=name;found=true;break; %#ok<SAGROW>
        end
    end
    if ~found,fprintf('%s alone did not meet all three targets within the search range.\n',name);end
    % A bearing-only change can reduce resonance yet worsen the differential
    % loading transient. For the fourth solution, explicitly test a TWO-part
    % load-side + shaft damper design rather than claim bearing-only success.
    if ~found && strcmp(name,'Bb')
        for shaftFactor=logspace(0,2,150)
            q=refined;q.Bb=designs.ProposedValue(k);q.Bs=q.Bs*shaftFactor;
            rr=fastPulseRipple(q);reduction=100*(1-max(abs(rr))/baseRipple);m=designMetrics(q,center);
            if reduction>=30 && m(5)>0 && m(2)<=.7*base(2) && m(3)<=.7*base(3)
                [tt,~,rr]=pulseSimulation(q);reduction=100*(1-max(abs(rr))/baseRipple);
                if reduction<30,continue;end
                jointRows(end+1,:)={'Bb + Bs',q.Bb,designs.Factor(k),m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),reduction,max(abs(rr)),q.Bs}; %#ok<SAGROW>
                plot(tt,rr);jointLabels{end+1}='Bb + Bs';found=true;break; %#ok<SAGROW>
            end
        end
        if ~found,fprintf('Combined bearing/shaft change also failed within the search range.\n');end
    end
end
grid on;xlabel('Time (s)');ylabel('Torsional speed ripple (rad/s)');legend(jointLabels,'Location','best');
saveas(fig,fullfile(figFolder,'combined_target_transients.png'));
jointDesigns=cell2table(jointRows,'VariableNames',{'Parameter','ProposedValue','Factor','NewResonance_Hz','PeakReduction_pct','MovingCostReduction_pct','RippleReduction_pct','PeakRipple_rad_s','ShaftDamping_Nm_s_rad'});
writetable(jointDesigns,fullfile(outFolder,'combined_target_proposals.csv'));disp(jointDesigns);

%% Optional Simulink replica of the REFINED linear transfer function
if createSimulinkModel
    if exist('new_system','file')==2
        model='ME495_refined_model';if bdIsLoaded(model),close_system(model,0);end
        new_system(model);add_block('simulink/Sources/Step',[model '/Step']);
        add_block('simulink/Continuous/Transfer Fcn',[model '/Flexible shaft'],'Numerator',mat2str(num,16),'Denominator',mat2str(den,16));
        add_block('simulink/Sinks/Scope',[model '/Speed']);
        add_line(model,'Step/1','Flexible shaft/1');add_line(model,'Flexible shaft/1','Speed/1');
        set_param(model,'StopTime','4');save_system(model,fullfile(outFolder,[model '.slx']));
    else,warning('ME495:NoSimulink','Simulink unavailable; all analysis above still completed.');end
end

%% Preserve everything and state what the experiments do NOT establish
save(fullfile(outFolder,'ME495_results.mat'),'initial','refined','f','H','frequencyTable','num','den', ...
    'numInitial','denInitial','sensitivity','designs','jointDesigns','coastRows','ringRows','B_tr_auto','B_tl_auto','B_tr_selected','B_tl_selected');
fprintf('\nInterpretation and report limits:\n');
fprintf('0. This reviewed run uses automatic ring-down sums and explicit post-disengagement coast windows.\n');
fprintf('1. Bb is an effective viscous approximation from the motor-uncoupled, two-flywheel test.\n');
fprintf('2. Compare coastdown.csv RMSE columns before defending viscous versus Coulomb friction.\n');
fprintf('3. Automatic ring-down results depend on the selected envelope. Inspect every ring plot.\n');
fprintf('4. Held-out sweeps test transfer across these records; their shared setup limits independence.\n');
fprintf('5. Check sweep_audit.csv for amplitude coverage and sweep direction. More tests may be needed.\n');
fprintf('6. Df changes BOTH flywheel inertias; Ds changes K as Ds^4. Other properties are held fixed.\n');
fprintf('7. K refinement is empirical; it does not independently establish a new shear modulus.\n');
fprintf('8. Damping modifications and added series resistance have torque, heat and efficiency costs.\n');
fprintf('9. Final 30%% claims need a modified-hardware test, and transient reduction is a separate metric.\n');
fprintf('10. Eraser 1, last test, 20-Hz impedance and connected-unplugged traces are retained as diagnostics.\n');
fprintf('    Their filenames alone do not establish additional independent material coefficients.\n');
fprintf('\nSaved tables, plots and workspace in %s\n',outFolder);diary off;

%% Local functions
function [Jf,Jc,K]=geometry(p)
Jf=p.rho*pi*p.Df^4*p.Lf/32;Jc=Jf+p.Jm;K=p.scaleK*pi*p.Gs*p.Ds^4/(32*p.Ls);
end
function [num,den]=coefficients(p)
[jf,jc,k]=geometry(p);r=p.Rm;m=p.Km;bs=p.Bs;bb=p.Bb;bm=p.Bm;tr=bs+bb;tl=bs+bm;
num=m*[bs,k];den=[r*jc*jf,r*jc*tr+jf*(m*m+r*tl), ...
    r*(k*(jc+jf)+bb*bs)+(m*m+r*bm)*tr,k*(m*m+r*(bm+bb))];
end
function h=response(p,f)
[n,d]=coefficients(p);s=1i*2*pi*f;h=polyval(n,s)./polyval(d,s);
end
function h=responseWithInductance(p,f)
[jf,jc,k]=geometry(p);s=1i*2*pi*f;z=p.Bs+k./s;a=jc*s+p.Bm+z;b=jf*s+p.Bb+z;
h=p.Km*z./((p.Rm+p.Lm*s).*(a.*b-z.^2)+p.Km^2*b);
end
function value=rmse(a,b),value=sqrt(mean(abs(a-b).^2));end
function value=rSquared(a,b),value=1-sum((a-b).^2)/max(sum((a-mean(a)).^2),eps);end
function [f,H,T]=averageSweeps(sweeps)
A=vertcat(sweeps.A);valid=A(:,1)>0;A=A(valid,:);
bin=round(A(:,1)*20)/20;[nom,~,g]=unique(bin);f=accumarray(g,A(:,1),[],@mean);
raw=10.^(A(:,3)/20).*exp(1i*A(:,4)*pi/180);
H=accumarray(g,real(raw),[],@mean)+1i*accumarray(g,imag(raw),[],@mean);
n=accumarray(g,1);scatter=sqrt(accumarray(g,abs(raw-H(g)).^2)./max(n-1,1));
T=table(nom,f,n,abs(H),20*log10(abs(H)),unwrap(angle(H))*180/pi,scatter, ...
    'VariableNames',{'Nominal_Hz','Measured_Hz','Count','Gain_rad_s_V','Magnitude_dB','Phase_deg','ComplexScatter_rad_s_V'});
end
function q=fitStiffness(p,f,H)
z=fminsearch(@(z)fitError(z,p,f,H),log(p.scaleK),optimset('Display','off','TolX',1e-10,'TolFun',1e-12));
q=p;q.scaleK=exp(z);
end
function e=fitError(z,p,f,H)
if ~isfinite(z) || z<log(.5) || z>log(1.5),e=1e6+sum(z.^2);return;end
p.scaleK=exp(z);h=response(p,f);e=mean(log(abs(h)./abs(H)).^2+angle(h./H).^2);
end
function [q,pt,pa,envelope]=ringEstimate(t,y,J,maxSec,minFrac)
y=y-mean(y(round(.9*numel(y)):end));dt=median(diff(t));sm=movmean(y,max(3,round(.005/dt)));a=abs(sm);
c=find(a(2:end-1)>=a(1:end-2)&a(2:end-1)>a(3:end))+1;
[~,order]=sort(a(c),'descend');selected=[];
for i=order(:)'
    if isempty(selected)||all(abs(t(c(i))-t(selected))>.07),selected(end+1)=c(i);end %#ok<AGROW>
end
selected=sort(selected);[~,imax]=max(a(selected));selected=selected(imax:end);
floorAmp=max(minFrac*a(selected(1)),.08);stop=find(a(selected)<floorAmp,1);
if ~isempty(stop),selected=selected(1:stop-1);end
selected=selected(t(selected)-t(selected(1))<=maxSec);
if numel(selected)<6,error('Fewer than six clean extrema; adjust window or inspect trace.');end
pt=t(selected);pa=a(selected);tt=pt-pt(1);b=polyfit(tt,log(pa),1);alpha=-b(1);
if alpha<=0,error('Envelope is not decaying.');end
fd=1/(2*median(diff(pt)));wn=sqrt((2*pi*fd)^2+alpha^2);
envelope=exp(polyval(b,tt));q=[alpha,fd,alpha/wn,2*J*alpha,rSquared(log(pa),polyval(b,tt))];
end
function m=designMetrics(p,center)
fg=logspace(-1,2,2400);mag=abs(response(p,fg));ix=find(mag(2:end-1)>mag(1:end-2)&mag(2:end-1)>=mag(3:end))+1;
hasPeak=~isempty(ix);
if hasPeak
    [~,j]=max(mag(ix));i=ix(j);fr=fminbnd(@(f)-abs(response(p,f)),fg(i-1),fg(i+1));pk=abs(response(p,fr));
else,[pk,i]=max(mag);fr=fg(i);end
fc=linspace(max(.001,fr-.5),fr+.5,401);cost=trapz(2*pi*fc,abs(response(p,fc)));
if isnan(center),center=fr;end
fc=linspace(max(.001,center-.5),center+.5,401);fixed=trapz(2*pi*fc,abs(response(p,fc)));
m=[fr,pk,cost,fixed,hasPeak];
end
function [t,x,ripple]=pulseSimulation(p)
[jf,jc,k]=geometry(p);
A=[0,1,-1,0;-k/jc,-(p.Bm+p.Bs)/jc,p.Bs/jc,p.Km/jc; ...
    k/jf,p.Bs/jf,-(p.Bb+p.Bs)/jf,0;0,-p.Km/p.Lm,0,-p.Rm/p.Lm];
b=[0;0;0;1/p.Lm];opt=odeset('RelTol',1e-7,'AbsTol',1e-9);
[t1,x1]=ode45(@(~,x)A*x+b,linspace(0,2,2001),zeros(4,1),opt);
[t2,x2]=ode45(@(~,x)A*x,linspace(2,4,2001),x1(end,:)',opt);
t=[t1;t2(2:end)];x=[x1;x2(2:end,:)];common=(jc*x(:,2)+jf*x(:,3))/(jc+jf);ripple=x(:,3)-common;
end
function ripple=fastPulseRipple(p)
[jf,jc,k]=geometry(p);
A=[0,1,-1,0;-k/jc,-(p.Bm+p.Bs)/jc,p.Bs/jc,p.Km/jc; ...
    k/jf,p.Bs/jf,-(p.Bb+p.Bs)/jf,0;0,-p.Km/p.Lm,0,-p.Rm/p.Lm];
[V,D]=eig(A);
if rcond(V)<1e-12,[~,~,ripple]=pulseSimulation(p);return;end
steady=-(A\[0;0;0;1/p.Lm]);time=linspace(0,2,2001);
E=exp(diag(D)*time);on=steady-V*((V\steady).*E);
off=V*((V\on(:,end)).*E);x=real([on,off(:,2:end)])';
ripple=x(:,3)-(jc*x(:,2)+jf*x(:,3))/(jc+jf);
end
