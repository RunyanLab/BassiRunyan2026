%% Demo: neuron-dropping plots from subsampled-population SVM results
% This is a thin wrapper around the main-script demo so it can be run from
% the existing Decoding_SVM/scripts workflow folder.

run(fullfile(fileparts(mfilename('fullpath')), ...
    '..', 'main_scripts', 'run_analysis_SVM_glm_inputs_final_subsampled_populations.m'));

