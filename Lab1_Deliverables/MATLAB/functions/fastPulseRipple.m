function ripple=fastPulseRipple(p)
[jf,jc,k]=geometry(p);
A=[0,1,-1,0;-k/jc,-(p.Bm+p.Bs)/jc,p.Bs/jc,p.Km/jc; ...
    k/jf,p.Bs/jf,-(p.Bb+p.Bs)/jf,0;0,-p.Km/p.Lm,0,-p.Rm/p.Lm];
[V,D]=eig(A);
if rcond(V)<1e-12,[~,~,ripple]=pulseSimulation(p);return;end
steady=-(A\[0;0;0;1/p.Lm]);time=linspace(0,2,2001);
E=exp(diag(D)*time);on=steady-V*((V\steady).*E);
off=V*((V\on(:,end)).*E);x=real([on,off(:,2:end)])';
ripple=x(:,3)-(jc*x(:,2)+jf*x(:,3))/(jc+jf);
end
