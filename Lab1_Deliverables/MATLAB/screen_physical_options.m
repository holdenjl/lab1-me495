%% Screen identifiable geometry/material changes, without inventing damping laws.
% This supplemental screen leaves all measured damping coefficients fixed.
% flywheel thickness/density changes map linearly to inertia; diameter to D^4.
addpath(fullfile(fileparts(mfilename('fullpath')),'functions'));
deliveryRoot=fileparts(fileparts(mfilename('fullpath')));
load(fullfile(deliveryRoot,'Analysis','characterization.mat'));
refined.driveInertiaFactor=1;refined.loadInertiaFactor=1;
base=designMetrics(refined,NaN);[~,bx,~,~,bg]=pulseExact(refined);br=max(abs(bx(:,2)-bx(:,3)));
rows=cell(0,8);
for nm={'driveInertiaFactor','loadInertiaFactor','Ds','Ls','Df','rho'}
 for fac=[.25 .4 .5 .6 .7 .8 1 1.2 1.5 2 3 4 6 8]
  q=refined;q.(nm{1})=q.(nm{1})*fac;m=designMetrics(q,base(1));
  [~,x,~,~,g]=pulseExact(q);r=max(abs(x(:,2)-x(:,3)));
  rows(end+1,:)={nm{1},fac,m(1),100*(1-m(2)/base(2)),100*(1-m(3)/base(3)),100*(1-m(4)/base(4)),100*(1-r/br),g/bg};
 end
end
T=cell2table(rows,'VariableNames',{'Parameter','Factor','ResonanceHz','PeakReduction_pct','MovingCostReduction_pct','FixedCostReduction_pct','PulseReduction_pct','DCGainRatio'});
writetable(T,fullfile(deliveryRoot,'Analysis','physical_options_screen.csv'));disp(T);
