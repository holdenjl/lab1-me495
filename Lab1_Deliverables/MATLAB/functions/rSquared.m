function value=rSquared(a,b),value=1-sum((a-b).^2)/max(sum((a-mean(a)).^2),eps);end
