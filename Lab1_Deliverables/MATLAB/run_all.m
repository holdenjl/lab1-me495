%% Reproduce all Lab 1 calculations from the supplied original exports.
% Tested with MATLAB R2026a. No optional toolbox is required.
% Original data and earlier student scripts are never overwritten.
clear; clc;
codeFolder=fileparts(mfilename('fullpath'));
deliveryRoot=fileparts(codeFolder);projectRoot=fileparts(deliveryRoot);
addpath(fullfile(codeFolder,'functions'));
set(groot,'defaultFigureVisible','off');
set(groot,'defaultAxesColor','w','defaultAxesXColor','k','defaultAxesYColor','k', ...
    'defaultAxesZColor','k','defaultTextColor','k','defaultLegendColor','w', ...
    'defaultLegendTextColor','k');
run(fullfile(codeFolder,'characterize_system.m'));
run(fullfile(codeFolder,'validate_system_model.m'));
run(fullfile(codeFolder,'analyze_sensitivity.m'));
save(fullfile(outFolder,'characterization.mat'));
if exist(fullfile(codeFolder,'design_changes.m'),'file')
    run(fullfile(codeFolder,'design_changes.m'));
end
run(fullfile(codeFolder,'physical_designs.m'));
if exist(fullfile(codeFolder,'publication_figures.m'),'file')
    run(fullfile(codeFolder,'publication_figures.m'));
end
if exist(fullfile(codeFolder,'verify_analysis.m'),'file')
    run(fullfile(codeFolder,'verify_analysis.m'));
end
run(fullfile(codeFolder,'physical_figures.m'));
run(fullfile(codeFolder,'verify_physical_designs.m'));
save(fullfile(outFolder,'complete_analysis.mat'));
diary off;
fprintf('Completed. Results: %s\n',outFolder);
