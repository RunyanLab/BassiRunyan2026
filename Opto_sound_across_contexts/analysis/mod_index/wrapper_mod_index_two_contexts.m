function [results, sig_mod_boot, mod_indexm] = wrapper_mod_index_two_contexts(info, neural_structure, response_range, mod_type, mode, stim_trials_context, ctrl_trials_context, nShuffles, savepath)
% Two-context modulation indices using calc_mod_index_cv.
%
% Both contexts are treated like spont in wrapper_mod_index_calculation_white_noise:
% condition labels are empty, so trials are not split into left and right.
% neural_structure, trial-index cells, response_range, mode, and nShuffles
% follow that wrapper. nRepeats stays 10.

nContexts = 2;
nRepeats = 10;
results = struct();
data_type = info.data_type;

for current_dataset = 1:length(info.mouse_date)
    fprintf('Processing dataset %d/%d...\n', current_dataset, length(info.mouse_date));
    for context = 1:nContexts
        fprintf('Current context %d...\n', context);
        current_conditions = [];
        current_conditions_ctrl = [];

        stim_data = neural_structure{1, current_dataset}.stim;
        ctrl_data = neural_structure{1, current_dataset}.ctrl;
        stim_trials = stim_trials_context{1, current_dataset}{1, context};
        ctrl_trials = ctrl_trials_context{1, current_dataset}{1, context};

        if ~strcmp(mode, 'simple')
            [cv_mod_index, cv_mod_index_separate, bootstrapResults] = calc_mod_index_cv( ...
                stim_data, ctrl_data, stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl, ...
                response_range, mod_type, mode, nRepeats, nShuffles);
        else
            [~, ~, ~, ~, ~, ~, left_stim_all, left_ctrl_all, right_stim_all, right_ctrl_all] = ...
                find_sound_trials_single(stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl);
            stim_data_left = stim_data(left_stim_all, :, :);
            ctrl_data_left = ctrl_data(left_ctrl_all, :, :);
            stim_data_right = stim_data(right_stim_all, :, :);
            ctrl_data_right = ctrl_data(right_ctrl_all, :, :);

            [cv_mod_left, ~, bootstrapResults_left] = calc_mod_index_cv( ...
                stim_data_left, ctrl_data_left, stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl, ...
                response_range, mod_type, mode, nRepeats, nShuffles, data_type);
            [cv_mod_right, ~, bootstrapResults_right] = calc_mod_index_cv( ...
                stim_data_right, ctrl_data_right, stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl, ...
                response_range, mod_type, mode, nRepeats, nShuffles, data_type);

            nNeurons = size(stim_data, 2);
            [cv_mod_index, cv_mod_index_separate, side] = select_max_side( ...
                cv_mod_left, cv_mod_right, nNeurons);
            bootstrapResults = handle_separate_BootstrapResults( ...
                bootstrapResults_left.pVals, bootstrapResults_right.pVals, side, nNeurons);
        end

        results(current_dataset).context(context).cv_mod_index = cv_mod_index;
        results(current_dataset).context(context).cv_mod_index_separate = cv_mod_index_separate;
        results(current_dataset).context(context).bootstrapResults = bootstrapResults;

        mod_indexm{current_dataset, context} = cv_mod_index;
        mod_index_separate{current_dataset, context} = cv_mod_index_separate;

        sig_neurons = find(bootstrapResults.pVals <= 0.05);
        sig_mod_boot{current_dataset, context} = sig_neurons;
        results(current_dataset).context(context).sig_neurons = sig_neurons;
    end
end

if ~isempty(savepath)
    if ~exist(savepath, 'dir')
        mkdir(savepath);
    end
    save(fullfile(savepath, 'sig_mod_boot.mat'), 'sig_mod_boot');
    save(fullfile(savepath, 'mod_indexm.mat'), 'mod_indexm');
    save(fullfile(savepath, 'mod_index_separate.mat'), 'mod_index_separate');
    save(fullfile(savepath, 'mod_index_results.mat'), 'results');
end
end
