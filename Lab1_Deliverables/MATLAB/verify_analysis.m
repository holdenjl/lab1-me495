%% Numerical/physics checks tied to the actual scientific claims.
[jf,jc,k]=geometry(refined);s=1i*2*pi*linspace(.2,30,300);
% Independent two-inertia dynamic-stiffness solution, Lm neglected.
z=refined.Bs+k./s;aa=jc*s+refined.Bm+z+refined.Km^2/refined.Rm;bb=jf*s+refined.Bb+z;
independent=(refined.Km/refined.Rm)*z./(aa.*bb-z.^2);
hfcheck=response(refined,imag(s)/(2*pi));
tfError=max(abs(independent-hfcheck)./max(abs(independent),eps));
assert(tfError<1e-10,'Transfer-function expansion disagrees with equations of motion.');
assert(all(real(roots(den))<0),'Baseline is not stable.');
assert(height(designs)==4,'Four recommendations required.');
assert(all(designs.PeakReduction_pct>=30&designs.MovingCostReduction_pct>=30&designs.TransientReduction_pct>=30), ...
    'A recommendation fails a stated nominal target.');
% Independent integration and transient sample spacing.
fb=linspace(center-.5,center+.5,1601);integralFine=trapz(2*pi*fb,abs(response(refined,fb)));
integralError=abs(integralFine/base(3)-1);assert(integralError<1e-4);
[~,~,~,fineBase]=pulseExact(refined,'driven',.00025);
fineReductions=zeros(4,1);
for j=1:4
 [~,~,~,finePeak]=pulseExact(solutions(j),'driven',.00025);
 fineReductions(j)=100*(1-finePeak/fineBase);
 assert(fineReductions(j)>=29.99,'Transient threshold not resolved in time.');
 [~,dj]=coefficients(solutions(j));assert(all(real(roots(dj))<0));
end
% Solve the full startup using an independent stiff ODE integrator.
A=[0 1 -1 0;-k/jc -(refined.Bm+refined.Bs)/jc refined.Bs/jc refined.Km/jc; ...
   k/jf refined.Bs/jf -(refined.Bb+refined.Bs)/jf 0;0 -refined.Km/refined.Lm 0 -refined.Rm/refined.Lm];
b=[0;0;0;1/refined.Lm];[tExact,xExact]=pulseExact(refined,'driven',.001);
[~,xODE]=ode15s(@(~,x)A*x+b,tExact(tExact<=4),zeros(4,1),odeset('RelTol',1e-9,'AbsTol',1e-11));
odeError=max(abs(xODE-xExact(1:size(xODE,1),:)),[],'all');assert(odeError<1e-6);
verification=struct('transferFunctionRelativeError',tfError,'costIntegrationRelativeError',integralError, ...
 'startupODEMaxAbsoluteError',odeError,'fineGridTransientReductions_pct',fineReductions, ...
 'allNominalTargetsPass',true,'baselineStable',true,'designsStable',true);
fid=fopen(fullfile(outFolder,'verification.json'),'w');fwrite(fid,jsonencode(verification,PrettyPrint=true));fclose(fid);
disp(verification);
