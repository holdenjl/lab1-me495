%% Supplemental physical screening, with the SAME relative-speed metric.
codeFolder=fileparts(mfilename('fullpath')); deliveryRoot=fileparts(codeFolder);
load(fullfile(deliveryRoot,'Analysis','characterization.mat'));
addpath(fullfile(codeFolder,'functions'));
refined.driveInertiaFactor=1;refined.loadInertiaFactor=1;
base=designMetrics(refined,NaN);[~,xb]=pulseExact(refined);
br=max(abs(xb(:,2)-xb(:,3)));rows=cell(0,7);
for side={'drive','load'}
 if strcmp(side{1},'drive'),diameters=[85 90 95 100 105 110];else,diameters=[160 165 170 175 180 185];end
 for D=diameters
  for Ds=[3.18 4 4.5 4.76 5 5.5 6.35]
   q=refined;q.([side{1} 'InertiaFactor'])=(D/137)^4;q.Ds=Ds/1000;
   m=designMetrics(q,base(1));[~,x]=pulseExact(q);r=max(abs(x(:,2)-x(:,3)));
   rows(end+1,:)={side{1},D,Ds,m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),100*(1-r/br)};
  end
 end
end
T=cell2table(rows,'VariableNames',{'Side','WheelDiameter_mm','ShaftDiameter_mm','Resonance_Hz','PeakReduction_pct','CostReduction_pct','RelativeSpeedReduction_pct'});
writetable(T,fullfile(outFolder,'geometry_pair_screen.csv'));
disp(T(T.PeakReduction_pct>=30&T.CostReduction_pct>=30&T.RelativeSpeedReduction_pct>=30,:));
