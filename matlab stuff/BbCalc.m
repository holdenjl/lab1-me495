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
J_t = J_m + (2*J_f);

%Damping of just the bearings (motor physically disconnected)
figure()
data2 = readmatrix("MotorDisc");
time = data2(:,1);
w = data2(:,4);
plot(time, log(w));
hold on;

idx = time >=4 & time<=18;

p = polyfit(time(idx), log(w(idx)), 1);
w_fit = polyval(p,time);
plot(time,w_fit, LineWidth=4);
slope = p(1);

B_b = -1*slope*2*J_f;


