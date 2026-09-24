save_string = '30frames_pre';
mod_params = params.mod_sounds; %use 'prespose'/'separate'?

params.mod_sounds.response_range = {63:92; 31:60}; %56:60// 31:60
mod_params.savepath = fullfile(params.info.savepath_sounds, 'mod', mod_params.mod_type, mod_params.mode, save_string);
params.info.data_type = 'dff';

[mod_index_results, sig_mod_boot, mod_indexm] = ...
    wrapper_mod_index_calculation(params.info, dff_st_combined, mod_params.response_range, mod_params.mod_type, mod_params.mode, stim_trials_context, ctrl_trials_context,mod_params.nShuffles,  mod_params.savepath);


% Set y-axis limits for the plots.
params.info.chosen_mice = [1:25]
plot_info.y_lims = [-.2, .20];
params.min_cells = 0;
% Set labels for plots.
plot_info.plot_labels = {'Sounds','Sounds'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
params.plot_info = plot_info;
params.info.chosen_mice = [1:25];

%save directory
save_dir = mod_params.savepath;%

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm, [], all_celltypes, params, save_dir);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');


%use same sig cells as original plots
[combined_sig_cells, ~] = union_sig_cells(sound.sig_mod_boot_thr(:,1)', sound.sig_mod_boot_thr(:,2)', sound.mod);
%datasets
plot_info.y_lims = [-.2, .3];params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm, combined_sig_cells, all_celltypes, params, [save_dir '\sig_cells']);


