%Motor Resistance from 20Hz Test 
data = readmatrix("MotRes");
figure()
v = data(:,2);
i = data(:,3);
plot(i,v);
xlabel("Current");
ylabel("Voltage");
hold on;
p = polyfit(i,v,1);
R_m = p(1);
offset = p(2);

plot(i, polyval(p,i));
hold on;

%Locked Motor Rm_DC
data2 = readmatrix("DCRes");
v_dc = data2(:,2);
i_dc = data2(:,3);
plot(i_dc,v_dc);
v_avg = mean(v_dc);
i_avg = mean(i_dc);
rm_dc = v_avg/i_avg;




