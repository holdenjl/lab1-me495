function m=designMetrics(p,center)
fg=logspace(-1,2,2400);mag=abs(response(p,fg));ix=find(mag(2:end-1)>mag(1:end-2)&mag(2:end-1)>=mag(3:end))+1;
hasPeak=~isempty(ix);
if hasPeak
    [~,j]=max(mag(ix));i=ix(j);fr=fminbnd(@(f)-abs(response(p,f)),fg(i-1),fg(i+1));pk=abs(response(p,fr));
else
    % Strong damping can eliminate the local torsional peak. Do not relabel
    % low-frequency commanded rotation as a new resonance. Conservatively
    % report maximum gain over the MEASURED 4-10 Hz band and mark fr as NaN.
    assess=linspace(4,10,2401);pk=max(abs(response(p,assess)));fr=NaN;
end
if isnan(center)
    if hasPeak,center=fr;
    else,[jf,jc,k]=geometry(p);center=sqrt(k*(jf+jc)/(jf*jc))/(2*pi);end
end
costCenter=fr;if ~hasPeak,costCenter=center;end
fc=linspace(max(.001,costCenter-.5),costCenter+.5,401);cost=trapz(2*pi*fc,abs(response(p,fc)));
fc=linspace(max(.001,center-.5),center+.5,401);fixed=trapz(2*pi*fc,abs(response(p,fc)));
m=[fr,pk,cost,fixed,hasPeak];
end
