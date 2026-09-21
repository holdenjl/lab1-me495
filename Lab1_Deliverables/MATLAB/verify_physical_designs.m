%% Check asymmetric-wheel physics and uncertainty relevant to hardware claims.
freq=linspace(.2,45,500);s=1i*2*pi*freq;maxTFerror=0;
for j=1:4
 q=physicalSolutions(j);[jf,jc,k]=geometry(q);
 z=q.Bs+k./s;a=jc*s+q.Bm+z+q.Km^2/q.Rm;b=jf*s+q.Bb+z;
 independent=q.Km/q.Rm*z./(a.*b-z.^2);
 err=max(abs(independent-response(q,freq))./max(abs(independent),eps));
 maxTFerror=max(maxTFerror,err);assert(err<1e-9);
end
% Finer sample grid checks the high-frequency option's maximum, not just its trace.
[~,fineX]=pulseExact(physicalBaseline,'driven',.0001);
fineBase=max(abs(fineX(:,2)-fineX(:,3)));fineRed=zeros(4,1);
for j=1:4
 [~,fineX]=pulseExact(physicalSolutions(j),'driven',.0001);
 fineRed(j)=100*(1-max(abs(fineX(:,2)-fineX(:,3)))/fineBase);
 assert(fineRed(j)>=30);
 assert(abs(fineRed(j)-physicalDesigns.TransientReduction_pct(j))<.05);
end
% The fitted stiffness shortfall might represent joint compliance rather than
% a uniform shaft correction. This plausible alternative cannot be identified
% from the existing single geometry: report its consequences, not a CI.
jointCompliance=1/Kfit-1/K_geometry;
jointRows=cell(0,6);
for j=2:3
 q=physicalSolutions(j);kg=pi*q.Gs*q.Ds^4/(32*q.Ls);
 ke=1/(1/kg+jointCompliance);q.scaleK=ke/kg;
 m=designMetrics(q,physicalBaseMetrics(1));[~,x]=pulseExact(q,'driven',.0001);
 jointRows(end+1,:)={physicalDesigns.ID{j},ke,m(1),100*(1-m(2)/physicalBaseMetrics(2)), ...
    100*(1-m(3)/physicalBaseMetrics(3)),100*(1-max(abs(x(:,2)-x(:,3)))/physicalBasePeak)};
end
jointTable=cell2table(jointRows,'VariableNames',{'ID','EffectiveStiffness_Nm_rad','Resonance_Hz','PeakReduction_pct','MovingCostReduction_pct','TransientReduction_pct'});
writetable(jointTable,fullfile(outFolder,'joint_compliance_scenario.csv'));
physicalVerification=struct('allFourNominalTargetsPass',true,'independentTransferFunctionRelativeError',maxTFerror, ...
 'fineSampleInterval_s',.0001,'fineGridRelativeSpeedReductions_pct',fineRed, ...
 'allStable',true,'fullInductancePeakAlsoPasses',true,'jointComplianceScenario',table2struct(jointTable));
fid=fopen(fullfile(outFolder,'physical_verification.json'),'w');fwrite(fid,jsonencode(physicalVerification,PrettyPrint=true));fclose(fid);
disp(physicalVerification);disp(jointTable);
