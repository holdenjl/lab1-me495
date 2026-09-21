% ME495 Flexible shaft experiment
% Last Updated: Winter 2011

clearvars;

% Change the current folder to the folder of this m-file.
if(~isdeployed)
  cd(fileparts(which(mfilename)));
end

% import the data file obtained from Labview
% use factor 2*pi to convert to rad/sec
freq_test=2*pi*[ 3 4 5 6 ...
          		 7 8 9];  
   % data inside [..] should be the test frequency in Hertz

mag_test = [ -5.1  -6.0  -3.2  6.3 ...
	   		 -4.6  -12.5  -18.9];  
   % data inside [..] should be output Bode magnitude in dB		   

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

for i = 1:size(freq_test,2),
   freq = freq_test(i);
   t=sim('flex_sim',5);		% simulate for 5 seconds
   mag_sim(i) = std(y(floor(size(y,1)/2):size(y,1)))/0.7071;    
								% input amp=1, std=0.7071;
end

plot(freq_test/(2*pi),mag_test, 'ro', freq_test/(2*pi), ...
20*log10(mag_sim),'b-')
xlabel('w (Hz)')
ylabel('| theta_2 dot (rad/sec) / V_i_n (volts) | in dB')
title('Line: model    circles: test results')

