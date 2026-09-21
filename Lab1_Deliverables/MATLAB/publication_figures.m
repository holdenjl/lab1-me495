%% Figures use ONLY variables recalculated by the MATLAB analysis.
pubFolder=fullfile(deliveryRoot,'Figures');
navy=[.02 .18 .31];teal=[0 .48 .48];orange=[.85 .38 .08];gray=[.48 .52 .57];
fg=linspace(4,10,1800)';hf=response(refined,fg);h0=response(initial,fg);
hr=refined.Km./(refined.Rm*(2*J_f+refined.Jm)*1i*2*pi*fg+refined.Km^2+refined.Rm*(refined.Bm+refined.Bb));
fig=figure('Visible','off','Position',[80 80 1000 650],'Color','w');
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
nexttile;plot(f,20*log10(abs(H)),'o','Color',orange,'MarkerFaceColor','w','MarkerSize',6);hold on;
plot(fg,20*log10(abs(hf)),'Color',navy,'LineWidth',2.6);
ylabel('Gain (dB re 1 rad s^{-1} V^{-1})');xlim([4 10]);ylim([-32 12]);grid on;
legend('Measured','Flexible model','Location','northeast');
nexttile;plot(f,unwrap(angle(H))*180/pi,'o','Color',orange,'MarkerFaceColor','w','MarkerSize',6);hold on;
plot(fg,unwrap(angle(hf))*180/pi,'Color',navy,'LineWidth',2.6);
xlabel('Frequency (Hz)');ylabel('Phase (degrees)');xlim([4 10]);ylim([-290 -70]);yticks([-270 -180 -90]);grid on;
savePublication(fig,pubFolder,'model_validation');

fig=figure('Visible','off','Position',[80 80 1000 500],'Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;rr=find(arrayfun(@(r)contains(r.key,'eraser left side'),runs),1);A=runs(rr).A;
[q,pt,pa,envelope]=ringEstimate(A(:,1),A(:,4),J_f,8,.15);
plot(A(:,1),A(:,4),'Color',navy,'LineWidth',1);hold on;
plot(pt,envelope,'--','Color',orange,'LineWidth',2.4);plot(pt,-envelope,'--','Color',orange,'LineWidth',2.4);
xlim([0 8]);xlabel('Time (s)');ylabel('Distal speed (rad/s)');title('Locked-motor free decay');grid on;
nexttile;rr=find(arrayfun(@(r)strcmp(r.key,'motor disconnected'),runs),1);A=runs(rr).A;
keep=A(:,1)>=4&A(:,1)<=19.5;t=A(keep,1);y=A(keep,4);ts=t-t(1);alpha=coastRows{1,2};
v0=exp(-alpha*ts)\y;lin=polyfit(ts,y,1);
plot(t(1:30:end),y(1:30:end),'.','Color',[.7 .73 .77]);hold on;
plot(t,v0*exp(-alpha*ts),'Color',navy,'LineWidth',2.3);
plot(t,polyval(lin,ts),'--','Color',orange,'LineWidth',2.3);
xlabel('Recording time (s)');ylabel('Distal speed (rad/s)');title('Motor mechanically uncoupled');xlim([4 19.5]);grid on;
legend('Measured','Viscous fit','Coulomb fit','Location','southwest');
savePublication(fig,pubFolder,'damping_evidence');

fig=figure('Visible','off','Position',[80 80 1000 470],'Color','w');
sel={'Rm','Km','Bm','Bs','Df','Ds'};idx=cellfun(@(n)find(strcmp(sensitivity.Parameter,n)),sel);
barh([sensitivity.FixedBandCostSensitivity(idx),sensitivity.PeakSensitivity(idx)],.75);ax=gca;ax.ColorOrder=[gray;teal];
set(ax,'YDir','reverse','YTick',1:6,'YTickLabel',{'R_m','K_m','B_m','B_s','D_f','D_s'});grid on;
xlabel('Normalized sensitivity (1% parameter perturbations)');xline(0,'Color',navy);
legend('Original 1-Hz band cost','Tracked peak height','Location','southwest');xlim([-3.65 1.65]);
savePublication(fig,pubFolder,'sensitivity_screen');

fig=figure('Visible','off','Position',[80 80 1000 650],'Color','w');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for k=1:4
 nexttile;plot(fg,abs(hf),'Color',gray,'LineWidth',2);hold on;
 plot(fg,abs(response(solutions(k),fg)),'Color',teal,'LineWidth',2.7);
 yline(.7*base(2),':','30% target','Color',orange,'LabelHorizontalAlignment','right','FontSize',12);
 xlim([4 8]);ylim([0 2.9]);xlabel('Frequency (Hz)');ylabel('Gain (rad s^{-1} V^{-1})');grid on;
 title(sprintf('%s: %+.1f%%',names{k},designs.Change_pct(k)),'Interpreter','none');
 if k==1,legend('Baseline','Modified','Location','northwest');end
end
savePublication(fig,pubFolder,'four_designs');

fig=figure('Visible','off','Position',[80 80 1000 400],'Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
[tt,~,baselineR]=pulseExact(refined);[~,~,shaftR]=pulseExact(solutions(3));
for k=1:2
 nexttile;timeOffset=(k-1)*4;ii=tt>=timeOffset&tt<=timeOffset+.8;
 plot(tt(ii)-timeOffset,baselineR(ii),'Color',gray,'LineWidth',2);hold on;
 plot(tt(ii)-timeOffset,shaftR(ii),'Color',teal,'LineWidth',2.7);
 xlabel('Time since switching (s)');ylabel('Torsional speed ripple (rad/s)');grid on;xlim([0 .8]);ylim([-.2 .2]);
 if k==1,title('Motor on: +1 V');legend('Baseline','Shaft-path damper','Location','southeast');else,title('Motor off: driven to 0 V');end
end
savePublication(fig,pubFolder,'switching_transient');

fig=figure('Visible','off','Position',[80 80 1000 420],'Color','w');
M=cell2mat(motorRows(:,2:4));y=M(:,1)-refined.Rm*M(:,2);
plot(M(:,3),y,'o','MarkerFaceColor',teal,'MarkerEdgeColor','w','MarkerSize',9);hold on;
xx=linspace(min(M(:,3)),max(M(:,3)),100);plot(xx,refined.Km*xx+motorOffset,'Color',navy,'LineWidth',2);
xlabel('Motor speed (rad/s)');ylabel('V - R_m I (V)');grid on;
title(sprintf('K_m = %.4f V s/rad; R^2 = %.5f',refined.Km,motorR2));
savePublication(fig,pubFolder,'motor_characterization');

if ~isempty(noiseTable)
 fig=figure('Visible','off','Position',[80 80 1000 440],'Color','w');
 tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
 nexttile;ii=noiseTable.Frequency_Hz>=4&noiseTable.Frequency_Hz<=10;
 plot(fg,abs(hf),'Color',navy,'LineWidth',2.3);hold on;
 plot(noiseTable.Frequency_Hz(ii),noiseTable.Gain_rad_s_V(ii),'o','Color',orange,'MarkerSize',6);
 xlabel('Frequency (Hz)');ylabel('Gain (rad s^{-1} V^{-1})');legend('Sweep-fitted model','Broadband H1 estimate');grid on;xlim([4 10]);
 nexttile;plot(noiseTable.Frequency_Hz(ii),noiseTable.Coherence(ii),'o-','Color',teal,'LineWidth',1.6);
 yline(.8,'--','Inclusion threshold','Color',gray);xlabel('Frequency (Hz)');ylabel('Magnitude-squared coherence');ylim([0 1]);xlim([4 10]);grid on;
 savePublication(fig,pubFolder,'broadband_diagnostic');
end

fig=figure('Visible','off','Position',[80 80 1000 550],'Color','w');
plot(f,20*log10(abs(H)),'o','Color',orange);hold on;plot(fg,20*log10(abs(h0)),'--','Color',gray,'LineWidth',2);
plot(fg,20*log10(abs(hf)),'Color',navy,'LineWidth',2.5);xlabel('Frequency (Hz)');ylabel('Gain (dB re 1 rad s^{-1} V^{-1})');grid on;
legend('Measured','Geometry-based K','Refined effective K');
savePublication(fig,pubFolder,'model_refinement');

fig=figure('Visible','off','Position',[80 80 1000 280],'Color','w');
bb=barh(100*designs.DCGainRatio,'FaceColor','flat');bb.CData=repmat(gray,4,1);bb.CData(3,:)=teal;
set(gca,'YDir','reverse','YTick',1:4,'YTickLabel',{'Resistance','Motor constant','Shaft damper','Motor damper'});
xlim([0 115]);xlabel('Steady-speed response retained at fixed voltage (%)');
for j=1:4,text(100*designs.DCGainRatio(j)+2,j,sprintf('%.0f%%',100*designs.DCGainRatio(j)),'FontSize',16);end
savePublication(fig,pubFolder,'drive_response');
