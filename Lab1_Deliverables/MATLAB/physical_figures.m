%% Publication figures for dimensioned hardware alternatives.
pubFolder=fullfile(deliveryRoot,'Figures');
navy=[.02 .18 .31];teal=[0 .48 .48];orange=[.85 .38 .08];gray=[.50 .54 .58];
fg=linspace(3,60,16000);hf=response(physicalBaseline,fg);
fig=figure('Visible','off','Position',[80 80 1100 730],'Color','w');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
titles={'1  Add a 1.6-ohm resistor','2  Distal wheel: 165 mm; shaft: 4.50 mm', ...
    '3  Motor wheel: 105 mm; shaft: 8.00 mm','4  Add a motor-side oil damper'};
for n=1:4
 nexttile;
 patch([10 60 60 10],[0 0 2.9 2.9],[.94 .95 .96],'EdgeColor','none','HandleVisibility','off');hold on;
 semilogx(fg,abs(hf),'Color',gray,'LineWidth',2.1);
 semilogx(fg,abs(response(physicalSolutions(n),fg)),'Color',teal,'LineWidth',2.7);
 yline(.7*physicalBaseMetrics(2),':','Color',orange,'LineWidth',1.5,'HandleVisibility','off');
 set(gca,'XScale','log');xlim([3 60]);ylim([0 2.9]);xticks([4 6 10 20 60]);
 xlabel('Frequency (Hz)');ylabel('Speed gain (rad/s/V)');grid on;
 title(titles{n},'FontSize',14);if n==1,legend('Baseline','Modified','Location','northeast','FontSize',12);end
end
savePublication(fig,pubFolder,'four_designs');
fig=figure('Visible','off','Position',[80 80 1000 400],'Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
[tt,xb]=pulseExact(physicalBaseline,'driven',.00025);
[~,xm]=pulseExact(physicalSolutions(2),'driven',.00025);
for n=1:2
 nexttile;offset=(n-1)*4;ii=tt>=offset&tt<=offset+.8;
 plot(tt(ii)-offset,xb(ii,2)-xb(ii,3),'Color',gray,'LineWidth',2.0);hold on;
 plot(tt(ii)-offset,xm(ii,2)-xm(ii,3),'Color',teal,'LineWidth',2.6);
 xlabel('Time since switch (s)');ylabel('Wheel-speed difference (rad/s)');grid on;xlim([0 .8]);ylim([-.32 .32]);
 if n==1,title('Switch on');legend('Baseline','Option 2','Location','northeast','FontSize',13);else,title('Switch off');end
end
savePublication(fig,pubFolder,'switching_transient');
fig=figure('Visible','off','Position',[80 80 1000 310],'Color','w');
barh(100*physicalDesigns.DCGainRatio,'FaceColor',teal);set(gca,'YDir','reverse', ...
 'YTick',1:4,'YTickLabel',{'1 Resistor','2 Larger distal wheel','3 Smaller motor wheel','4 Oil damper'});
xlim([0 118]);xlabel('Steady speed retained at the same voltage (%)');
for n=1:4,text(100*physicalDesigns.DCGainRatio(n)+2,n,sprintf('%.0f%%',100*physicalDesigns.DCGainRatio(n)),'FontSize',16);end
savePublication(fig,pubFolder,'drive_response');
