function [q,pt,pa,envelope]=ringEstimate(t,y,J,maxSec,minFrac)
y=y-mean(y(round(.9*numel(y)):end));dt=median(diff(t));sm=movmean(y,max(3,round(.005/dt)));a=abs(sm);
c=find(a(2:end-1)>=a(1:end-2)&a(2:end-1)>a(3:end))+1;
[~,order]=sort(a(c),'descend');selected=[];
for i=order(:)'
    if isempty(selected)||all(abs(t(c(i))-t(selected))>.07),selected(end+1)=c(i);end %#ok<AGROW>
end
selected=sort(selected);[~,imax]=max(a(selected));selected=selected(imax:end);
floorAmp=max(minFrac*a(selected(1)),.08);stop=find(a(selected)<floorAmp,1);
if ~isempty(stop),selected=selected(1:stop-1);end
selected=selected(t(selected)-t(selected(1))<=maxSec);
if numel(selected)<6,error('Fewer than six clean extrema; adjust window or inspect trace.');end
pt=t(selected);pa=a(selected);tt=pt-pt(1);b=polyfit(tt,log(pa),1);alpha=-b(1);
if alpha<=0,error('Envelope is not decaying.');end
fd=1/(2*median(diff(pt)));wn=sqrt((2*pi*fd)^2+alpha^2);
envelope=exp(polyval(b,tt));q=[alpha,fd,alpha/wn,2*J*alpha,rSquared(log(pa),polyval(b,tt))];
end
