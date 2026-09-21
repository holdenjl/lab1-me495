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
fig=figure('Visible','off','Color','w');subplot(2,1,1);plot(f,20*log10(abs(H)),'ko',fg,20*log10(abs(hinit)),'b--',fg,20*log10(abs(hg)),'r-');grid on;
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
fig=figure('Visible','off','Color','w');plot(f,abs(H),'ko',fg,abs(hg),'b-',fg,abs(rigid),'k--');grid on;
xlabel('Frequency (Hz)');ylabel('Speed / voltage (rad/s/V)');legend('Measured','Flexible shaft','Rigid shaft');
saveas(fig,fullfile(figFolder,'flexible_vs_rigid.png'));

