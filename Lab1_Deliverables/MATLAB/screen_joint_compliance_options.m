%% Optional screen that led to the final 105 mm wheel / 8.00 mm shaft option.
codeFolder=fileparts(mfilename('fullpath'));deliveryRoot=fileparts(codeFolder);
load(fullfile(deliveryRoot,'Analysis','complete_analysis.mat'));
addpath(fullfile(codeFolder,'functions'));
rows=zeros(0,8);
for wheel_mm=[100 105 107]
 for shaft_mm=[7 7.5 8]
  q=physicalBaseline;q.driveInertiaFactor=(wheel_mm/137)^4;q.Ds=shaft_mm/1000;
  m=designMetrics(q,physicalBaseMetrics(1));[~,x]=pulseExact(q,'driven',.0001);
  nominal=100*(1-max(abs(x(:,2)-x(:,3)))/physicalBasePeak);
  kg=pi*q.Gs*q.Ds^4/(32*q.Ls);
  q.scaleK=1/(1/kg+1/Kfit-1/K_geometry)/kg;
  [~,x]=pulseExact(q,'driven',.0001);
  alternate=100*(1-max(abs(x(:,2)-x(:,3)))/physicalBasePeak);
  rows(end+1,:)=[wheel_mm shaft_mm m(1),100*(1-m(2)/physicalBaseMetrics(2)), ...
      100*(1-m(3)/physicalBaseMetrics(3)),nominal,alternate,min(nominal,alternate)>=30];
 end
end
T=array2table(rows,'VariableNames',{'MotorWheelDiameter_mm','ShaftDiameter_mm','NominalResonance_Hz', ...
 'PeakReduction_pct','CostReduction_pct','NominalMotionReduction_pct','JointComplianceMotionReduction_pct','BothMotionTargetsPass'});
writetable(T,fullfile(outFolder,'joint_compliance_design_screen.csv'));disp(T);
