function e=fitError(z,p,f,H)
if ~isfinite(z) || z<log(.5) || z>log(1.5),e=1e6+sum(z.^2);return;end
p.scaleK=exp(z);h=response(p,f);e=mean(log(abs(h)./abs(H)).^2+angle(h./H).^2);
end
