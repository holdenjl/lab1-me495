%% Plot YOUR report results. Base MATLAB; no sample points or copied constants.
clear; clc; close all;
dataFolder = '/Users/paidsebs/Documents/me495/lab1 /data';
resultFile = fullfile(dataFolder,'ME495_results_reviewed','ME495_results.mat');
if ~isfile(resultFile)
    [name,folder] = uigetfile('*.mat','Choose the reviewed ME495_results.mat');
    if isequal(name,0),return;end
    resultFile = fullfile(folder,name);
end
S = load(resultFile);
needed = {'f','H','numInitial','denInitial','num','den','initial','refined'};
for k=1:numel(needed)
    if ~isfield(S,needed{k}),error('Missing %s in %s.',needed{k},resultFile);end
end
f = S.f(:); H = S.H(:);
fine = linspace(min(f),max(f),1200)'; z = 1i*2*pi*fine;
H0 = polyval(S.numInitial,z)./polyval(S.denInitial,z);
H1 = polyval(S.num,z)./polyval(S.den,z);
phaseMeasured = unwrap(angle(H))*180/pi;
phase0 = unwrap(angle(H0))*180/pi;
phase1 = unwrap(angle(H1))*180/pi;
phase0 = phase0+360*round((phaseMeasured(1)-phase0(1))/360);
phase1 = phase1+360*round((phaseMeasured(1)-phase1(1))/360);
figure('Color','w');
subplot(2,1,1);
plot(f,20*log10(abs(H)),'ko',fine,20*log10(abs(H0)),'--', ...
    fine,20*log10(abs(H1)),'-','LineWidth',1.3);
grid on;ylabel('Distal speed / voltage (dB)');
legend('Your measured data','Initial model','K-refined model','Location','best');
title('Your saved ME495 results');
subplot(2,1,2);
plot(f,phaseMeasured,'ko',fine,phase0,'--',fine,phase1,'-','LineWidth',1.3);
grid on;xlabel('Frequency (Hz)');ylabel('Phase (deg)');
fprintf('Results loaded from: %s\n',resultFile);
fprintf('Rm = %.8g ohm; Km = %.8g V*s/rad; Jm = %.8g kg*m^2\n', ...
    S.refined.Rm,S.refined.Km,S.refined.Jm);
fprintf('Bb = %.8g; Bs = %.8g; Bm = %.8g N*m*s/rad\n', ...
    S.refined.Bb,S.refined.Bs,S.refined.Bm);
fprintf('This plot uses saved measurements and coefficients; it performs no new fit.\n');
