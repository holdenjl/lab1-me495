%% SETTINGS: edit here; variable names are consistent throughout this file
dataFolder = fullfile(projectRoot,'Data');
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
outFolder = fullfile(deliveryRoot,'Analysis');
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
        if startsWith(key,'distal bearing'),key=['eraser left side ' char(string(1+contains(key,'damping 2')))];end
        if startsWith(key,'motor + shaft'),key=['eraser right side ' char(string(1+contains(key,'damping 2')))];end
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
    fig=figure('Visible','off','Color','w');plot(M(:,3),y,'ko');hold on;
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
    fig=figure('Visible','off','Color','w');plot(tAll,direction*yAll,'Color',[.65 .65 .65]);hold on;plot(t+fitStart,ex,'b-',t+fitStart,linear,'r--','LineWidth',1.3);
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

