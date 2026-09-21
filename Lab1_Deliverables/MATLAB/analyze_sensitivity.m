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
fig=figure('Visible','off','Color','w');bar([sensitivity.FixedBandCostSensitivity,sensitivity.PeakSensitivity]);set(gca,'XTick',1:numel(parameterNames),'XTickLabel',parameterNames);
ylabel('Normalized sensitivity');grid on;legend('Fixed 1-Hz band cost','Moving resonance peak');saveas(fig,fullfile(figFolder,'sensitivity.png'));

