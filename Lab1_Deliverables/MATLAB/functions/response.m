function h=response(p,f)
[n,d]=coefficients(p);s=1i*2*pi*f;h=polyval(n,s)./polyval(d,s);
end
