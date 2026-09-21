function [f,H,T]=averageSweeps(sweeps)
A=vertcat(sweeps.A);valid=A(:,1)>0;A=A(valid,:);
bin=round(A(:,1)*20)/20;[nom,~,g]=unique(bin);f=accumarray(g,A(:,1),[],@mean);
raw=(A(:,7)./A(:,5)).*exp(1i*A(:,4)*pi/180);
H=accumarray(g,real(raw),[],@mean)+1i*accumarray(g,imag(raw),[],@mean);
n=accumarray(g,1);scatter=sqrt(accumarray(g,abs(raw-H(g)).^2)./max(n-1,1));
T=table(nom,f,n,abs(H),20*log10(abs(H)),unwrap(angle(H))*180/pi,scatter, ...
    'VariableNames',{'Nominal_Hz','Measured_Hz','Count','Gain_rad_s_V','Magnitude_dB','Phase_deg','ComplexScatter_rad_s_V'});
end
