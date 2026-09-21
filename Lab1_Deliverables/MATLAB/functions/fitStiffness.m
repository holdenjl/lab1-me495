function q=fitStiffness(p,f,H)
z=fminsearch(@(z)fitError(z,p,f,H),log(p.scaleK),optimset('Display','off','TolX',1e-10,'TolFun',1e-12));
q=p;q.scaleK=exp(z);
end
