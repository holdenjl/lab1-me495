function [num,den]=coefficients(p)
[jf,jc,k]=geometry(p);r=p.Rm;m=p.Km;bs=p.Bs;bb=p.Bb;bm=p.Bm;tr=bs+bb;tl=bs+bm;
num=m*[bs,k];den=[r*jc*jf,r*jc*tr+jf*(m*m+r*tl), ...
    r*(k*(jc+jf)+bb*bs)+(m*m+r*bm)*tr,k*(m*m+r*(bm+bb))];
end
