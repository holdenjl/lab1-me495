function [Jf,Jc,K]=geometry(p)
baseJ=p.rho*pi*p.Df^4*p.Lf/32;
driveFactor=1;loadFactor=1;
if isfield(p,'driveInertiaFactor'),driveFactor=p.driveInertiaFactor;end
if isfield(p,'loadInertiaFactor'),loadFactor=p.loadInertiaFactor;end
Jf=baseJ*loadFactor;Jc=baseJ*driveFactor+p.Jm;
K=p.scaleK*pi*p.Gs*p.Ds^4/(32*p.Ls);
end
