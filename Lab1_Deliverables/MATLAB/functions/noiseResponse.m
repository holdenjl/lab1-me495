function [T,metrics]=noiseResponse(A,p)
% Independent H1 estimate from the supplied last-test broadband time record.
% Base MATLAB Welch averaging: 2-s Hann windows, 50% overlap, no zero padding.
dt=median(diff(A(:,1)));fs=1/dt;N=round(2*fs);
w=.5-.5*cos(2*pi*(0:N-1)'/(N-1));
Sxx=zeros(N,1);Syy=Sxx;Syx=Sxx;nseg=0;
for first=1:floor(N/2):size(A,1)-N+1
    ii=first:first+N-1;
    u=A(ii,2);y=A(ii,4);u=u-mean(u);y=y-mean(y);
    U=fft(u.*w);Y=fft(y.*w);
    Sxx=Sxx+abs(U).^2;Syy=Syy+abs(Y).^2;Syx=Syx+Y.*conj(U);nseg=nseg+1;
end
f=(0:N/2)'*fs/N;Hn=Syx(1:N/2+1)./Sxx(1:N/2+1);
coh=abs(Syx(1:N/2+1)).^2./(Sxx(1:N/2+1).*Syy(1:N/2+1));
hp=response(p,f);keep=f>=4&f<=10&coh>=.8;
T=table(f,abs(Hn),angle(Hn)*180/pi,coh,keep,...
 'VariableNames',{'Frequency_Hz','Gain_rad_s_V','Phase_deg','Coherence','UsedForError'});
metrics=struct('segments',nseg,'df_Hz',fs/N,'coherenceThreshold',.8,'binsUsed',sum(keep), ...
 'magnitudeRMSE_dB',sqrt(mean((20*log10(abs(Hn(keep)./hp(keep)))).^2)), ...
 'phaseRMSE_deg',sqrt(mean((angle(Hn(keep)./hp(keep))*180/pi).^2)));
end
