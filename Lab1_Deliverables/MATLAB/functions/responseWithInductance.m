function h=responseWithInductance(p,f)
[jf,jc,k]=geometry(p);s=1i*2*pi*f;z=p.Bs+k./s;a=jc*s+p.Bm+z;b=jf*s+p.Bb+z;
h=p.Km*z./((p.Rm+p.Lm*s).*(a.*b-z.^2)+p.Km^2*b);
end
