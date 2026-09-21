
clear; clc;



p.K_m = 0.06;                  % motor constant, V/(rad/s)
p.R_m = 0.9;                   % motor resistance, ohm
p.J_m = 3.8e-5;                % motor inertia, kg*m^2
p.D_flywheel = 0.137;          % flywheel diameter, m
p.L_flywheel = 0.0127;         % flywheel thickness, m
p.rho_flywheel = 7755;         % flywheel density, kg/m^3
p.D_shaft = 3.18e-3;           % shaft diameter, m
p.L_shaft = 0.305;             % shaft length, m
p.G_shaft = 7.31e10;           % shaft shear modulus, Pa
p.K_scale = 1.0;               % no fitted stiffness correction
p.B_s = 0.003;                 % placeholder shaft damping, N*m*s/rad
p.B_b = 0.003;                 % placeholder distal bearing damping, N*m*s/rad
p.B_m = 0.003;                 % placeholder motor-side damping, N*m*s/rad

%% 2. Baseline response
[baselineCost, baselinePeak, baselineFrequency] = responseMetrics(p);

fprintf('Baseline resonance frequency: %.3f Hz\n', baselineFrequency);
fprintf('Baseline 1-Hz-band cost:       %.4f\n', baselineCost);
fprintf('Baseline resonance peak:       %.4f rad/s/V\n\n', baselinePeak);

%% 3. Parameters and ranges to investigate
% A multiplier of 1 means no change.
% Example: 1.50 means a 50%% increase and 0.50 means a 50%% decrease.
parameterNames = {'R_m', 'K_m', 'B_m', 'B_b'};

multiplierRanges = { ...
    linspace(1, 10, 3001), ...      % increase R_m
    linspace(1, 0.01, 2501), ...    % decrease K_m
    linspace(1, 50, 4001), ...      % increase B_m
    linspace(1, 50, 4001)};         % increase B_b

targetRatio = 0.70;                 % 70%% remaining = 30%% reduction

%% 4. Change each parameter and find the first design that meets both goals
numberOfParameters = numel(parameterNames);
baselineValue = zeros(numberOfParameters,1);
requiredValue = zeros(numberOfParameters,1);
changePercent = zeros(numberOfParameters,1);
costReductionPercent = zeros(numberOfParameters,1);
peakReductionPercent = zeros(numberOfParameters,1);
newResonanceHz = zeros(numberOfParameters,1);

for parameterNumber = 1:numberOfParameters
    name = parameterNames{parameterNumber};
    multipliers = multiplierRanges{parameterNumber};
    baselineValue(parameterNumber) = p.(name);
    foundDesign = false;

    for multiplier = multipliers
        trial = p;
        trial.(name) = p.(name)*multiplier;

        [newCost, newPeak, newFrequency] = responseMetrics(trial);
        costRatio = newCost/baselineCost;
        peakRatio = newPeak/baselinePeak;

        % Both ratios must be 0.70 or lower.
        if costRatio <= targetRatio && peakRatio <= targetRatio
            requiredValue(parameterNumber) = trial.(name);
            changePercent(parameterNumber) = 100*(multiplier-1);
            costReductionPercent(parameterNumber) = 100*(1-costRatio);
            peakReductionPercent(parameterNumber) = 100*(1-peakRatio);
            newResonanceHz(parameterNumber) = newFrequency;
            foundDesign = true;
            break
        end
    end

    if ~foundDesign
        error('%s did not meet both goals inside its search range.', name);
    end
end

%% 5. Display the final results
results = table(string(parameterNames(:)), baselineValue, requiredValue, ...
    changePercent, costReductionPercent, peakReductionPercent, newResonanceHz, ...
    'VariableNames', {'Parameter','BaselineValue','RequiredValue', ...
    'ChangePercent','CostReductionPercent','PeakReductionPercent', ...
    'NewResonance_Hz'});

disp(results);


function [cost, peak, resonanceHz] = responseMetrics(p)
    % Build the transfer-function numerator and denominator.
    J_f = p.rho_flywheel*pi*p.D_flywheel^4*p.L_flywheel/32;
    K = p.K_scale*pi*p.G_shaft*p.D_shaft^4/(32*p.L_shaft);
    J_c = p.J_m + J_f;
    B_tr = p.B_s + p.B_b;
    B_tl = p.B_s + p.B_m;

    numerator = [p.K_m*p.B_s, p.K_m*K];
    denominator = [ ...
        p.R_m*J_c*J_f, ...
        p.R_m*J_c*B_tr + J_f*(p.K_m^2 + B_tl*p.R_m), ...
        p.R_m*(K*(J_c+J_f) + p.B_b*p.B_s) + ...
            (p.K_m^2 + p.R_m*p.B_m)*B_tr, ...
        K*(p.K_m^2 + (p.B_m+p.B_b)*p.R_m)];

    % Find the resonance in the 3-10 Hz range specified in Example2.m.
    frequencyHz = linspace(3, 10, 7001);
    omega = 2*pi*frequencyHz;
    response = polyval(numerator, 1i*omega) ./ polyval(denominator, 1i*omega);
    magnitude = abs(response);

    [peak, peakIndex] = max(magnitude);
    resonanceHz = frequencyHz(peakIndex);

    % Calculate area over a 1-Hz band centered on resonance.
    bandHz = linspace(resonanceHz-0.5, resonanceHz+0.5, 1001);
    bandOmega = 2*pi*bandHz;
    bandResponse = polyval(numerator, 1i*bandOmega) ./ ...
        polyval(denominator, 1i*bandOmega);
    cost = trapz(bandHz, abs(bandResponse));
end
