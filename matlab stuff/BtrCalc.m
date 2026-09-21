%Given Parameters
K_m = 0.097;		% N-m/A or V/(rad/sec)
R_m = 1.6;		% Ohms
L_m = 0.002;	% Henry
J_m = 4.23e-5;	% Kg-m^2
D_f = 0.137;	% m
L_f = 0.0127;	% m
rho_f = 7755;		% kg/m^3
D_s	= 3.18e-3;	% m
L_s = 0.305;	% m
G_s	= 7.31e10;	% N/m^2

% Computed parameters
J_f = (rho_f * pi * D_f^4 * L_f)/32;
K  = (pi * G_s * D_s^4)/(32*L_s);
J_c = J_m + J_f;

%Free Decay Tests for Damping

%Eraser left side - Distal Bearing + Shaft Damping (Btr=Bs+Bb)

%Test 1 data
data = readmatrix("Dist2.txt");
time = data(:,1);
tach = data(:,4);
figure()
plot(time, tach);
xlabel('Time (s)');
ylabel('Distal rad/s');

%grid on;
hold on;

[peaks, t] = findpeaks(tach, time, "MinPeakProminence", 2, "MinPeakDistance",.1);
plot(t, peaks,'o' );

periods = diff(t);
meanPeriod = mean(periods);

f_d = 1/meanPeriod;
w_d = (2*pi)/meanPeriod;

r = log((peaks(1: (end-1))./(peaks(2:end))));

B_tr = (2*J_f*r)/periods;
B_tr_avg = mean(B_tr); %Uses full range of values, may need to be a smaller range where Btr remains fairly constant 






