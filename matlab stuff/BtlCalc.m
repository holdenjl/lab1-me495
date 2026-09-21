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

%Eraser right side - Motor + Shaft Damping (Btl = Bs + Bm)
data = readmatrix("MotorDamping2");

time = data(:,1);
tach = data(:,5);
figure()
plot(time, tach);
xlabel('Time (s)');
ylabel('Motor rad/s');

grid on;
hold on;

[peaks, t] = findpeaks(tach, time, "MinPeakProminence", .2, "MinPeakDistance",.1);
plot(t, peaks,'o' );

periods = diff(t);
meanPeriod = mean(periods);

f_d = 1/meanPeriod;
w_d = (2*pi)/meanPeriod;

r = log((peaks(1: (end-1))./(peaks(2:end))));

B_tl = (2*J_c*r)/periods;
B_tl_avg = mean(B_tl(2:5,2)); %excludes range with very small peaks

