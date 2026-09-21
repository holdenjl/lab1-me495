% Example program for Sensitivity analysis
% Last Updated: Winter 2011
% Frequency domain
% Construct the model using system parameters
K_m 			= 0.06;		% N-m/A or V/(rad/sec)
R_m 			= 0.9;		% Ohms
L_m 			= 0.002;	% Henry
J_m 			= 3.8e-5;	% Kg-m^2
D_flywheel		= 0.137;	% m
L_flywheel		= 0.0127;	% m
rho_flywheel	= 7755;		% kg/m^3
D_shaft			= 3.18e-3;	% m
L_shaft			= 0.305;	% m
G_shaft			= 7.31e10;	% N/m^2

% Computed parameters
J_f = rho_flywheel*pi*D_flywheel^4*L_flywheel/32;
K  = pi*G_shaft*D_shaft^4/(32*L_shaft);
J_c = J_m + J_f;

% Key in the damping terms you obtained in the following two lines
B_s 		= 0.003;		% Type in your value here
B_b         = 0.003;		% Type in your value here
B_m         = 0.003;        % Type in your value here
B_tr     	= B_s + B_b;
B_tl        = B_s + B_m;

num_o = [K_m*B_s,  K_m*K];
den_o = [R_m*J_c*J_f,   R_m*J_c*B_tr+J_f*(K_m^2+B_tl*R_m), ...
       	R_m*(K*(J_c+J_f)+B_b*B_s)+(K_m^2+R_m*B_m)*B_tr, K*(K_m^2+(B_m+B_b)*R_m)];

freq_FR=2*pi*[3:0.05:10];	% Assume resonance is between 3 and 10 Hz (need to check!)
[mag_o1 phase_o1] = bode(num_o,den_o,freq_FR);
[max_mag_o1, index1] = max(mag_o1);
resonance_frq = freq_FR(index1);
plot(freq_FR/(2*pi), mag_o1, '-', resonance_frq/(2*pi), max_mag_o1, 'x')
xlabel('w (Hz)')
ylabel('theta 2 dot/Vin (rad/sec/volt) (NOT in dB)')
pause

% Calculate the cost function (0.5 Hz around resonance)
min_freq = resonance_frq - pi/2;   % Minimum frequency in rad/sec
max_freq = resonance_frq + pi/2;   % Maximum frequency in rad/sec
freq_COST = min_freq: (pi)/100 : max_freq;

[mag_o2 phase_o2] = bode(num_o, den_o, freq_COST);
cost_o = sum(mag_o2);			% This is a 'sum" but is a good
								% approximate of integral

% Choose which parametere to perturb here (B_s in the following)
B_s = B_s*1.01;

% Update all the computed parameters
J_f = rho_flywheel*pi*D_flywheel^4*L_flywheel/32;
K  = pi*G_shaft*D_shaft^4/(32*L_shaft);
J_c = J_m + J_f;
B_tr     	= B_s + B_b;
B_tl        = B_s + B_m;

num_plus = [K_m*B_s,  K_m*K];
den_plus = [R_m*J_c*J_f,   R_m*J_c*B_tr+J_f*(K_m^2+B_tl*R_m), ...
       	R_m*(K*(J_c+J_f)+B_b*B_s)+(K_m^2+R_m*B_m)*B_tr, K*(K_m^2+(B_m+B_b)*R_m)];

% Find the new resonance frequency
[mag_plus1 phase_plus1] = bode(num_plus, den_plus, freq_FR);
[max_mag_plus1, index1] = max(mag_plus1);
resonance_frq_plus = freq_FR(index1);

% Calculate the new cost
min_freq = resonance_frq_plus - pi/2;   % Minimum frequency in rad/sec
max_freq = resonance_frq_plus + pi/2;   % Maximum frequency in rad/sec
freq_COST = min_freq: (pi)/100 : max_freq;
[mag_plus2 phase_plus2] = bode(num_plus,den_plus,freq_COST);
cost_plus = sum(mag_plus2);	
B_s = B_s/1.01;         % Undo the change


B_s = B_s*0.99;            % Perturb in the other direction
% Update all the computed parameters
J_f = rho_flywheel*pi*D_flywheel^4*L_flywheel/32;
K  = pi*G_shaft*D_shaft^4/(32*L_shaft);
J_c = J_m + J_f;
B_tr     	= B_s + B_b;
B_tl        = B_s + B_m;

num_minus = [K_m*B_s,  K_m*K];
den_minus = [R_m*J_c*J_f,   R_m*J_c*B_tr+J_f*(K_m^2+B_tl*R_m), ...
       	R_m*(K*(J_c+J_f)+B_b*B_s)+(K_m^2+R_m*B_m)*B_tr, K*(K_m^2+(B_m+B_b)*R_m)];
% Find the new resonance frequency
[mag_minus1 phase_minus1] = bode(num_minus,den_minus,freq_FR);
[max_mag_minus1, index1] = max(mag_minus1);
resonance_frq_minus = freq_FR(index1);

% Calculate the new cost
min_freq = resonance_frq_minus - pi/2;   % Minimum frequency in rad/sec
max_freq = resonance_frq_minus + pi/2;   % Maximum frequency in rad/sec
freq_COST = min_freq: (pi)/100 : max_freq;
[mag_minus2 phase_minus2] = bode(num_minus,den_minus,freq_COST);
cost_minus = sum(mag_minus2);
B_s = B_s/0.99;		% Undo the change

error_plus = abs(cost_o-cost_plus)/cost_o;
error_minus = abs(cost_o-cost_minus)/cost_o;

% Average error in percentage
% With 1% parameter perturbation, The cost function changes by
(error_plus+error_minus)/2 * 100
%(%)

