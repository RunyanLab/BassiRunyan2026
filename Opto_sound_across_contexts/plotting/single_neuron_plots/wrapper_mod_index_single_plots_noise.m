function wrapper_mod_index_single_plots_noise(info, neural_structure, stim_trials_context, ctrl_trials_context, mod_index_results, dataset_to_plot, context_to_plot, sig_neurons_to_plot, modulation_type, save_string, plot_params)
% WRAPPER_MOD_INDEX_SINGLE_PLOTS computes modulation indices for each dataset/context,
% identifies significant neurons based on bootstrap results, and then plots individual neuron activity.
%
%   Inputs:
%     info                - Structure with dataset information (e.g., info.mouse_date).
%     neural_structure    - Cell array or structure array with neural data for each dataset.
%                           Each element should have fields 'stim' and 'ctrl' (3D arrays: trials x neurons x frames).
%     mod_index_results   - Structure array of modulation indices per
%                            neuron and significant neurons.
%     stim_trials_context - Cell array of stimulation trial indices for each dataset/context.
%                           For dataset i and context j, use: stim_trials_context{1,i}{1,j}.
%     ctrl_trials_context - Cell array of control trial indices for each dataset/context.
%                           For dataset i and context j, use: ctrl_trials_context{1,i}{1,j}.
%     dataset_to_plot     - Dataset indices to process.
%     context_to_plot     - Context indices to process.
%     sig_neurons_to_plot - Indices of significant neurons to plot (optional, if empty, determined from results).
%     modulation_type     - Type of modulation index to use.
%     save_string         - String to append to saved plots.
%
%   Author: CB 03/04/2025
% Set random seed for reproducibility.
rng(123);

% Load trial information (adjust paths as needed) -virmen trial info left turns/sound condition/is stim
all_trial_info_sounds = info.active_all_trial_info;
passive_all_trial_info_sounds = info.passive_all_trial_info;

nContexts = 3; size(stim_trials_context{1,1},2);
% Loop through datasets.
for current_dataset = dataset_to_plot
    fprintf('Processing dataset %d/%d...\n', current_dataset, length(dataset_to_plot));
    % Loop through contexts (assuming context 1: active, context 2: passive; adjust as needed).
    for context = context_to_plot
        % Get condition labels from trial info.
        if context == 1
            current_conditions = [all_trial_info_sounds(current_dataset).opto.condition]; 
            current_conditions_ctrl = [all_trial_info_sounds(current_dataset).sound_only.condition];
        elseif context == 2
            current_conditions = [passive_all_trial_info_sounds(current_dataset).opto.condition];
            current_conditions_ctrl = [passive_all_trial_info_sounds(current_dataset).sound_only.condition];
        else %spont has no conditions
            current_conditions = [];
            current_conditions_ctrl = [];
        end
        % Extract neural data for the current dataset.
        stim_data = neural_structure{1, current_dataset}.stim;  % [trials x neurons x frames]
        ctrl_data = neural_structure{1, current_dataset}.ctrl;  % [trials x neurons x frames]

        % Get trial indices for the current context.
        stim_trials = stim_trials_context{1, current_dataset}{1, context};
        ctrl_trials = ctrl_trials_context{1, current_dataset}{1, context};

        % Get example trials!
        [~, ~, left_stim, left_ctrl, right_stim, right_ctrl, left_stim_all, left_ctrl_all, right_stim_all, right_ctrl_all] = ...
            find_sound_trials_single(stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl);

        %Zero right for spontaneous since left and rigth are the same trials
        if context == 3
            right_stim_all = [];
            right_ctrl_all = [];
            right_stim = [];
            right_ctrl = [];
        end

        % For now, use pooled indices.
        pooled_stim_indices = [left_stim_all(:); right_stim_all(:)];
        pooled_ctrl_indices = [left_ctrl_all(:); right_ctrl_all(:)];
        
        % Identify significant neurons using your helper function.
        mod_index = mod_index_results(current_dataset).context(context).cv_mod_index;
        if isempty(sig_neurons_to_plot)
            sig_neurons = get_significant_mod_neurons(mod_index, mod_index_results(current_dataset).context(context).sig_neurons, modulation_type);
        else
            sig_neurons = sig_neurons_to_plot;
        end

        fprintf('sig_neurons dataset %d/%d...\n', current_dataset, length(sig_neurons));
        % Plot individual modulated neurons.
        time_vector = [1:122];
        if ~isempty(sig_neurons)
            plot_individual_mod_neurons(stim_data(pooled_stim_indices, :, :), ...
                                        ctrl_data(pooled_ctrl_indices, :, :), ...
                                        mod_index, sig_neurons, time_vector, [current_dataset, context], [length(left_stim_all), length(left_ctrl_all)], ...
                                        fullfile(info.savepath,'individual_neuron_plots', save_string),plot_params.plot_mode,plot_params.plot_avg,plot_params);

            if isfield(plot_params,'avg_traces') && plot_params.avg_traces == 1
                %plot avg trace and trials in gray per neuron
                if strcmp(plot_params.plot_mode,'ctrl')
                    plot_avg_trial_traces_simple(ctrl_data(pooled_ctrl_indices, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg', save_string));
                    plot_avg_trial_traces_simple(ctrl_data(left_ctrl_all, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg_left', save_string));
                    plot_avg_trial_traces_simple(ctrl_data(right_ctrl_all, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg_right', save_string));
                elseif strcmp(plot_params.plot_mode,'stim')
                    plot_avg_trial_traces_simple(stim_data(pooled_stim_indices, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg', save_string));
                else
                    plot_avg_trial_traces_simple(ctrl_data(pooled_ctrl_indices, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg', save_string),stim_data(pooled_stim_indices, :, :));
                    plot_avg_trial_traces_simple(ctrl_data(left_ctrl_all, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg_left', save_string),stim_data(right_ctrl_all, :, :));
                    plot_avg_trial_traces_simple(ctrl_data(left_ctrl_all, :, :),sig_neurons,mod_index,[current_dataset, context],plot_params,fullfile(info.savepath,'individual_neuron_plots_avg_right', save_string),stim_data(right_ctrl_all, :, :));

                end
            end

        end
    end
end
end