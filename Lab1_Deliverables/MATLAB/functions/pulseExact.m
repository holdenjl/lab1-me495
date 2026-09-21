function [t,x,ripple,peak,dcGain]=pulseExact(p,turnOffMode,dt)
% Exact matrix-exponential solution, unit voltage for 4 s then off for 4 s.
% States: [theta1-theta2, omega1, omega2, current].
% 'driven' uses a zero-voltage source; 'open' removes electromagnetic torque.
% Ripple = omega2 - inertia-weighted assembly speed (not total wheel speed).
if nargin<2,turnOffMode='driven';end
if nargin<3,dt=.001;end
[jf,jc,k]=geometry(p);
A=[0 1 -1 0;-k/jc -(p.Bm+p.Bs)/jc p.Bs/jc p.Km/jc; ...
   k/jf p.Bs/jf -(p.Bb+p.Bs)/jf 0;0 -p.Km/p.Lm 0 -p.Rm/p.Lm];
b=[0;0;0;1/p.Lm];ss=-A\b;tv=0:dt:4;
[V,D]=eig(A);on=real(ss-V*((V\ss).*exp(diag(D)*tv)));
if strcmp(turnOffMode,'open')
    [Vo,Do]=eig(A(1:3,1:3));
    off=[real(Vo*((Vo\on(1:3,end)).*exp(diag(Do)*tv)));zeros(size(tv))];
else
    off=real(V*((V\on(:,end)).*exp(diag(D)*tv)));
end
x=[on,off(:,2:end)]';t=[tv,tv(2:end)+4]';
ripple=x(:,3)-(jc*x(:,2)+jf*x(:,3))/(jc+jf);
peak=max(abs(ripple));dcGain=ss(3);
end
