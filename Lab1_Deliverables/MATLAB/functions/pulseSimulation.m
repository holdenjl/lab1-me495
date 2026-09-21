function [t,x,ripple]=pulseSimulation(p)
[jf,jc,k]=geometry(p);
A=[0,1,-1,0;-k/jc,-(p.Bm+p.Bs)/jc,p.Bs/jc,p.Km/jc; ...
    k/jf,p.Bs/jf,-(p.Bb+p.Bs)/jf,0;0,-p.Km/p.Lm,0,-p.Rm/p.Lm];
b=[0;0;0;1/p.Lm];opt=odeset('RelTol',1e-7,'AbsTol',1e-9);
[t1,x1]=ode45(@(~,x)A*x+b,linspace(0,2,2001),zeros(4,1),opt);
[t2,x2]=ode45(@(~,x)A*x,linspace(2,4,2001),x1(end,:)',opt);
t=[t1;t2(2:end)];x=[x1;x2(2:end,:)];common=(jc*x(:,2)+jf*x(:,3))/(jc+jf);ripple=x(:,3)-common;
end
