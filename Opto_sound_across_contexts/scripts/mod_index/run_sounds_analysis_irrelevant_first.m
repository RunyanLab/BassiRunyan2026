repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if isfolder('C:\Code\Github\BassiRunyan2025')
    addpath(genpath('C:\Code\Github\BassiRunyan2025'));
end
addpath(genpath(repo_root));

% Uses params.info_updated. Point that list at sessions that contain
% active condition-5 first repeats before running. Older sessions stop
% the extractor, and this script does not rewrite their saved results.

params = experiment_config();
plot_info = plotting_config();
params.plot_info = plot_info;
%%
params.info_updated.mouse_date = {'KW-2-1L\2026-10-13','KW-2-1L\2026-10-15'};
params.info_updated.serverid = {'W:','W:'};
%% Pool the original contexts, then active condition-5 first repeats
[all_celltypes, active, passive, spont] = pool_activity_sounds_simple( ...
    params.info_updated.mouse_date, params.info_updated.serverid, [60, 60]);
active_regular = active;
active_irrelevant_first = pool_active_irrelevant_first( ...
    params.info_updated.mouse_date, params.info_updated.serverid, [60, 60]);

params.info_updated.active_all_trial_info = active.all_trial_info;
params.info_updated.passive_all_trial_info = passive.all_trial_info;

all_celltypes_og = all_celltypes;
all_celltypes = {};
for i = 1:length(params.info_updated.mouse_date)
    all_celltypes{1, i}.pyr_cells = all_celltypes_og{1, i}.pyr_cells;
end
[num_cells, sorted_cells] = organize_pooled_celltypes(active.dff_st, all_celltypes);

%% Checks before modulation indices
validation = validate_irrelevant_first_inputs(active_regular, passive, spont, active_irrelevant_first);
disp(validation.summary);

base_dir = fullfile(params.info_updated.savepath_sounds, 'irrelevant_first');
if ~exist(base_dir, 'dir')
    mkdir(base_dir);
end
data_dir = fullfile(base_dir, 'data_info');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end
save(fullfile(data_dir, 'validation_irrelevant_first.mat'), 'validation');
save(fullfile(data_dir, 'active_irrelevant_first.mat'), 'active_irrelevant_first', '-v7.3');

%% Shared modulation settings from the existing sound configuration
params.info_updated.data_type = 'dff';
mod_params = params.mod_sounds;
mod_params.mod_type = 'prepost';
mod_params.mod_threshold = 0;
mod_params.min_cells = 0;

%% B. Relevant + irrelevant, original active versus passive
[context_data.dff, stim_trials_context, ctrl_trials_context] = organize_2context( ...
    active.dff_st, passive.dff_st, 'extra_contexts', {spont.dff_st});
[stim_info_combined, dff_st_combined] = combine_stim_info_dff_st( ...
    active.stim_info, passive.stim_info, active.dff_st, passive.dff_st, ...
    'extra_stim_info', {spont.stim_info}, 'extra_dff', {spont.dff_st});
[context_data.deconv, ~, ~] = organize_2context(active.deconv_st_nogap, passive.deconv_st_nogap);

combined_dir = fullfile(base_dir, 'relevant_plus_irrelevant_prepost', mod_params.mode);
mod_params.savepath = combined_dir;
[combined_results, combined_sig_boot, combined_mod] = wrapper_mod_index_calculation_white_noise( ...
    params.info_updated, dff_st_combined, mod_params.response_range, mod_params.mod_type, ...
    mod_params.mode, stim_trials_context, ctrl_trials_context, mod_params.nShuffles, mod_params.savepath);

mod_params.chosen_mice = 1:size(combined_mod, 1);
mod_params.results = combined_results;
combined_sig_thr = plot_pie_thresholded_mod_index( ...
    params.info_updated, mod_params, combined_mod, combined_sig_boot, sorted_cells, all_celltypes, combined_dir);
[combined_sig_cells, ~] = union_sig_cells(combined_sig_thr(:, 1)', combined_sig_thr(:, 2)', combined_mod);
relevant_plus_irrelevant.sig_mod_boot = combined_sig_boot;
relevant_plus_irrelevant.sig_mod_boot_thr = combined_sig_thr;
relevant_plus_irrelevant.results = combined_results;
relevant_plus_irrelevant.mod = combined_mod;
relevant_plus_irrelevant.sig_cells = combined_sig_cells;
save(fullfile(combined_dir, 'relevant_plus_irrelevant_prepost.mat'), 'relevant_plus_irrelevant');

plot_info.behavioral_contexts = {'Active', 'Passive'};
plot_info.plot_labels = {'Sounds', 'Sounds'};
plot_info.type = 'sounds';
plot_info.y_lims = [-.4, .4];
params.plot_info = plot_info;
params.min_cells = 0;
[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, combined_mod, combined_sig_boot, mod_params, ...
    fullfile(combined_dir, 'sig_cells'), 'sound_dff', plot_info);
all_cells = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), size(combined_mod, 2), 1)';
[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, combined_mod, all_cells, mod_params, ...
    combined_dir, 'sound_dff', plot_info);
params.plot_info.y_lims = [-.1, .1];
combined_stats = generate_mod_index_plots_datasets( ...
    mod_params.chosen_mice, combined_mod(mod_params.chosen_mice, :), [], ...
    all_celltypes(1, mod_params.chosen_mice), params, combined_dir);
save(fullfile(combined_dir, 'mod_index_stats_datasets.mat'), 'combined_stats');
if ~isempty([combined_sig_cells{mod_params.chosen_mice}])
    combined_sig_stats = generate_mod_index_plots_datasets( ...
        mod_params.chosen_mice, combined_mod(mod_params.chosen_mice, :), combined_sig_cells, ...
        all_celltypes(1, mod_params.chosen_mice), params, fullfile(combined_dir, 'sig_cells'));
    save(fullfile(combined_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), 'combined_sig_stats');
end

%% A. Irrelevant alone, active condition 5 versus passive spont
[irrelevant_context.dff, stim_trials_irrelevant, ctrl_trials_irrelevant] = organize_2context( ...
    active_irrelevant_first.dff_st, spont.dff_st);
[~, irrelevant_dff_combined] = combine_stim_info_dff_st( ...
    active_irrelevant_first.stim_info, spont.stim_info, ...
    active_irrelevant_first.dff_st, spont.dff_st);

irrelevant_dir = fullfile(base_dir, 'irrelevant_alone_prepost', mod_params.mode);
[irrelevant_results, irrelevant_sig_boot, irrelevant_mod] = wrapper_mod_index_two_contexts( ...
    params.info_updated, irrelevant_dff_combined, mod_params.response_range, mod_params.mod_type, ...
    mod_params.mode, stim_trials_irrelevant, ctrl_trials_irrelevant, mod_params.nShuffles, irrelevant_dir);

mod_params.chosen_mice = 1:size(irrelevant_mod, 1);
mod_params.results = irrelevant_results;
irrelevant_sig_thr = plot_pie_thresholded_mod_index( ...
    params.info_updated, mod_params, irrelevant_mod, irrelevant_sig_boot, sorted_cells, all_celltypes, irrelevant_dir);
[irrelevant_sig_cells, ~] = union_sig_cells(irrelevant_sig_thr(:, 1)', irrelevant_sig_thr(:, 2)', irrelevant_mod);
irrelevant_alone.sig_mod_boot = irrelevant_sig_boot;
irrelevant_alone.sig_mod_boot_thr = irrelevant_sig_thr;
irrelevant_alone.results = irrelevant_results;
irrelevant_alone.mod = irrelevant_mod;
irrelevant_alone.sig_cells = irrelevant_sig_cells;
save(fullfile(irrelevant_dir, 'irrelevant_alone_prepost.mat'), 'irrelevant_alone');

spont_reproduction = compare_spont_mod_index(combined_mod, irrelevant_mod);
validation.spont_reproduction = spont_reproduction;
save(fullfile(data_dir, 'validation_irrelevant_first.mat'), 'validation');
if ~spont_reproduction.match
    error('run_sounds_analysis_irrelevant_first:SpontMismatch', ...
        'Passive spont prepost indices were not reproduced. Max absolute difference %g.', ...
        spont_reproduction.max_abs_difference);
end

plot_info.behavioral_contexts = {'Active irrelevant', 'Passive irrelevant'};
plot_info.plot_labels = {'Irrelevant', 'Irrelevant'};
plot_info.type = 'sounds';
plot_info.y_lims = [-.4, .4];
params.plot_info = plot_info;
params.min_cells = 0;
[~, ~] = wrapper_avg_cell_type_traces( ...
    irrelevant_context.dff, all_celltypes, irrelevant_mod, irrelevant_sig_boot, mod_params, ...
    fullfile(irrelevant_dir, 'sig_cells'), 'sound_dff', plot_info);
all_cells_irrelevant = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), size(irrelevant_mod, 2), 1)';
[~, ~] = wrapper_avg_cell_type_traces( ...
    irrelevant_context.dff, all_celltypes, irrelevant_mod, all_cells_irrelevant, mod_params, ...
    irrelevant_dir, 'sound_dff', plot_info);
params.plot_info.y_lims = [-.1, .1];
irrelevant_stats = generate_mod_index_plots_datasets( ...
    mod_params.chosen_mice, irrelevant_mod(mod_params.chosen_mice, :), [], ...
    all_celltypes(1, mod_params.chosen_mice), params, irrelevant_dir);
save(fullfile(irrelevant_dir, 'mod_index_stats_datasets.mat'), 'irrelevant_stats');
if ~isempty([irrelevant_sig_cells{mod_params.chosen_mice}])
    irrelevant_sig_stats = generate_mod_index_plots_datasets( ...
        mod_params.chosen_mice, irrelevant_mod(mod_params.chosen_mice, :), irrelevant_sig_cells, ...
        all_celltypes(1, mod_params.chosen_mice), params, fullfile(irrelevant_dir, 'sig_cells'));
    save(fullfile(irrelevant_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), 'irrelevant_sig_stats');
end

save(fullfile(data_dir, 'stim_trials_context_relevant_plus_irrelevant.mat'), 'stim_trials_context');
save(fullfile(data_dir, 'ctrl_trials_context_relevant_plus_irrelevant.mat'), 'ctrl_trials_context');
save(fullfile(data_dir, 'stim_info_combined_relevant_plus_irrelevant.mat'), 'stim_info_combined');
save(fullfile(data_dir, 'context_data_relevant_plus_irrelevant.mat'), 'context_data', '-v7.3');

%% repeat but using only irrelevant outside task
irrelevant_dir_irrelevant_outside_task = [irrelevant_dir '/sig_outside_task/'];
mkdir(irrelevant_dir_irrelevant_outside_task)
irrelevant_sig_cells=irrelevant_sig_thr(:, 2)';
irrelevant_alone.sig_mod_boot = irrelevant_sig_boot;
irrelevant_alone.sig_mod_boot_thr = irrelevant_sig_thr;
irrelevant_alone.results = irrelevant_results;
irrelevant_alone.mod = irrelevant_mod;
irrelevant_alone.sig_cells = irrelevant_sig_cells;
save(fullfile(irrelevant_dir_irrelevant_outside_task, 'irrelevant_alone_prepost.mat'), 'irrelevant_alone');

spont_reproduction = compare_spont_mod_index(combined_mod, irrelevant_mod);
validation.spont_reproduction = spont_reproduction;
save(fullfile(data_dir, 'validation_irrelevant_first.mat'), 'validation');
if ~spont_reproduction.match
    error('run_sounds_analysis_irrelevant_first:SpontMismatch', ...
        'Passive spont prepost indices were not reproduced. Max absolute difference %g.', ...
        spont_reproduction.max_abs_difference);
end


%% Relevant + irrelevant versus relevant alone (ctrl index)
% Active stim/ctrl are regular blocks only. Passive stim/ctrl are the
% existing relevant+irrelevant and relevant-alone sets. Context 3 of
% combined_mod is the spont prepost index used only to select neurons.
ctrl_mod_params = params.mod;
ctrl_mod_params.mod_type = 'ctrl';
ctrl_mod_params.mod_threshold = 0.1;
ctrl_mod_params.min_cells = 0;
ctrl_mod_params.chosen_mice = 1:size(combined_mod, 1);
chosen_mice = ctrl_mod_params.chosen_mice;

ctrl_dir = fullfile(base_dir, 'relevant_plus_irrelevant_ctrl', ctrl_mod_params.mode);
[ctrl_results, ctrl_sig_boot, ctrl_mod] = wrapper_mod_index_calculation_white_noise( ...
    params.info_updated, dff_st_combined, ctrl_mod_params.response_range, ctrl_mod_params.mod_type, ...
    ctrl_mod_params.mode, stim_trials_context, ctrl_trials_context, ctrl_mod_params.nShuffles, ctrl_dir);

sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index( ...
    params.info_updated, ctrl_mod_params, combined_mod(:, 3), combined_sig_boot(:, 3), ...
    sorted_cells, all_celltypes, ctrl_dir);
noise.sig_mod_boot = ctrl_sig_boot;
noise.results = ctrl_results;
noise.mod = ctrl_mod;
noise.sig_mod_boot_thr = sig_mod_boot_thr_spont;
noise.sig_cells = sig_mod_boot_thr_spont;
save(fullfile(ctrl_dir, 'relevant_plus_irrelevant_ctrl.mat'), 'noise');

ctrl_mod_params.results = noise.results;
plot_info.y_lims = [-.3, .3];
plot_info.plot_labels = {'Stim', 'Ctrl'};
plot_info.behavioral_contexts = {'Active', 'Passive'};
plot_info.figure_width_traces = 11;
plot_info.xlims_traces = [31, 91];
plot_info.type = 'opto';
params.plot_info = plot_info;
params.min_cells = 0;

[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, noise.mod, sig_mod_boot_thr_spont, ctrl_mod_params, ...
    fullfile(ctrl_dir, 'sig_cells'), 'opto_dff', plot_info, combined_mod);
plot_info.colors_celltypes_3contexts(1, :) = [0.54, 0.82, 0.64];
[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, noise.mod, sig_mod_boot_thr_spont, ctrl_mod_params, ...
    fullfile(ctrl_dir, 'sig_cells'), 'opto_dff_spont', plot_info, combined_mod, [3]);
plot_info.colors_celltypes_3contexts(1, :) = [0.16, 0.4, 0.24];
params.plot_info = plot_info;

all_cells_ctrl = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), 3, 1)';
[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, noise.mod, all_cells_ctrl, ctrl_mod_params, ...
    ctrl_dir, 'opto_dff', plot_info, combined_mod);

ctrl_stats = generate_mod_index_plots_datasets( ...
    chosen_mice, noise.mod(ctrl_mod_params.chosen_mice, :), [], ...
    all_celltypes(1, ctrl_mod_params.chosen_mice), params, ctrl_dir);
save(fullfile(ctrl_dir, 'mod_index_stats_datasets.mat'), 'ctrl_stats');
if ~isempty([noise.sig_cells{chosen_mice}])
    ctrl_sig_stats = generate_mod_index_plots_datasets( ...
        chosen_mice, noise.mod(ctrl_mod_params.chosen_mice, :), noise.sig_cells', ...
        all_celltypes(1, ctrl_mod_params.chosen_mice), params, fullfile(ctrl_dir, 'sig_cells'));
    save(fullfile(ctrl_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), 'ctrl_sig_stats');
end
%% Relevant alone, active versus passive (prepost_sound index)
% Uses the regular active and passive ctrl trials already in dff_st_combined.
% Significant neurons are the union of active and passive.
sound_mod_params = params.mod_sounds;
sound_mod_params.mod_type = 'prepost_sound';
sound_mod_params.mod_threshold = 0.1;
sound_mod_params.min_cells = 0;

sound_dir = fullfile(base_dir, 'relevant_alone_prepost', sound_mod_params.mode);
[sound_results, sound_sig_boot, sound_mod] = wrapper_mod_index_calculation_white_noise( ...
    params.info_updated, dff_st_combined, sound_mod_params.response_range, sound_mod_params.mod_type, ...
    sound_mod_params.mode, stim_trials_context, ctrl_trials_context, sound_mod_params.nShuffles, sound_dir);

sound_mod_params.chosen_mice = 1:size(sound_mod, 1);
chosen_mice = sound_mod_params.chosen_mice;
sound_sig_thr = plot_pie_thresholded_mod_index( ...
    params.info_updated, sound_mod_params, sound_mod, sound_sig_boot, ...
    sorted_cells, all_celltypes, sound_dir);
[sound_sig_cells, ~] = union_sig_cells(sound_sig_thr(:, 1)', sound_sig_thr(:, 2)', sound_mod);
sound.sig_mod_boot = sound_sig_boot;
sound.sig_mod_boot_thr = sound_sig_thr;
sound.results = sound_results;
sound.mod = sound_mod;
sound.sig_cells = sound_sig_cells;
save(fullfile(sound_dir, 'relevant_alone_prepost.mat'), 'sound');

sound_mod_params.results = sound.results;
plot_info.y_lims = [-.4, .4];
plot_info.plot_labels = {'Sounds', 'Sounds'};
plot_info.behavioral_contexts = {'Active', 'Passive'};
plot_info.type = 'sounds';
plot_info.figure_width_traces = 10;
plot_info.xlims_traces = [31, 91];
params.plot_info = plot_info;
params.string = 'Sounds';
params.min_cells = 0;

[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, sound.mod, sound.sig_mod_boot, sound_mod_params, ...
    fullfile(sound_dir, 'sig_cells'), 'sound_dff', plot_info);
all_cells_sound = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), 3, 1)';
[~, ~] = wrapper_avg_cell_type_traces( ...
    context_data.dff, all_celltypes, sound.mod, all_cells_sound, sound_mod_params, ...
    sound_dir, 'sound_dff', plot_info);

params.plot_info.y_lims = [-.1, .1];
sound_stats = generate_mod_index_plots_datasets( ...
    chosen_mice, sound.mod(sound_mod_params.chosen_mice, :), [], ...
    all_celltypes(1, sound_mod_params.chosen_mice), params, sound_dir);
save(fullfile(sound_dir, 'mod_index_stats_datasets.mat'), 'sound_stats');
if ~isempty([sound.sig_cells{chosen_mice}])
    sound_sig_stats = generate_mod_index_plots_datasets( ...
        chosen_mice, sound.mod(sound_mod_params.chosen_mice, :), sound.sig_cells, ...
        all_celltypes(1, sound_mod_params.chosen_mice), params, fullfile(sound_dir, 'sig_cells'));
    save(fullfile(sound_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), 'sound_sig_stats');
end
%% compare overlap of active neurons sound vs irrelevant alone
contexts_to_compare = 1;
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_mod_boot_thr(:,1),irrelevant_sig_thr(:,1),sound.mod, contexts_to_compare);


sound_repeat_colors = [0.5 0.5 0.5
                       [173 185 227] / 255
                        [163 121 201] / 255
                            0.3,0.2,0.6];
savepath_fig2 = base_dir;
overlap_labels = {'Sound Only','White Noise Only', 'Both','Unmodulated'}; 

plot_sig_overlap_pie(mean(percent_cells_per_dataset)*100, overlap_labels, ['W:\Connie\results\Bassi2025\fig3\reviews\sounds\irrelevant_first\percent_overlap_active\'], contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',sound_repeat_colors,'FigureWidth',9);


contexts_to_compare = 1;
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_mod_boot_thr(:,2),irrelevant_sig_thr(:, 2),sound.mod, contexts_to_compare);


sound_repeat_colors = [0.5 0.5 0.5
                       [173 185 227] / 255
                        [163 121 201] / 255
                            0.3,0.2,0.6];
savepath_fig2 = base_dir;
overlap_labels = {'Sound Only','White Noise Only', 'Both','Unmodulated'}; 

plot_sig_overlap_pie(mean(percent_cells_per_dataset)*100, overlap_labels, ['W:\Connie\results\Bassi2025\fig3\reviews\sounds\irrelevant_first\percent_overlap_passive\'], contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',sound_repeat_colors,'FigureWidth',9);

%%
%% Exploratory: within-block halves and repeat 2
% Does not modify active, passive, spont, or active_irrelevant_first.
half_scope = 'within_block'; % 'within_block' or 'session'
half_pack = extract_exploratory_active( ...
    params.info_updated.mouse_date, params.info_updated.serverid, [60, 60], half_scope);

exp_dir = fullfile(base_dir, 'exploratory', ['half_' half_scope]);
if ~exist(exp_dir, 'dir')
    mkdir(exp_dir);
end
save(fullfile(exp_dir, 'selection_catalog.mat'), 'half_pack', 'half_scope');

% Irrelevant alone, prepost. Passive context is the existing spont stim.
run_prepost_contexts(params.info_updated, half_pack.irrelevant_early, spont, spont, false, ...
    fullfile(exp_dir, 'irrelevant_early_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Early', 'Passive'}, params);
run_prepost_contexts(params.info_updated, half_pack.irrelevant_late, spont, spont, false, ...
    fullfile(exp_dir, 'irrelevant_late_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Late', 'Passive'}, params);
run_prepost_contexts(params.info_updated, half_pack.irrelevant_early, half_pack.irrelevant_late, spont, false, ...
    fullfile(exp_dir, 'irrelevant_early_vs_late'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Early', 'Late'}, params);

% Regular active blocks only, ctrl index. Passive and spont stay intact.
% Significant neurons remain the spont prepost set from section B.
run_ctrl_half_vs_passive(params.info_updated, half_pack.regular_early, passive, spont, ...
    fullfile(exp_dir, 'regular_early_ctrl'), params.mod, combined_mod, combined_sig_boot, ...
    sorted_cells, all_celltypes, num_cells, {'Early', 'Passive'}, params);
run_ctrl_half_vs_passive(params.info_updated, half_pack.regular_late, passive, spont, ...
    fullfile(exp_dir, 'regular_late_ctrl'), params.mod, combined_mod, combined_sig_boot, ...
    sorted_cells, all_celltypes, num_cells, {'Late', 'Passive'}, params);

%% Repeat 2. Block type comes from repeat 1; sound type comes from repeat 2.
rep_dir = fullfile(base_dir, 'exploratory', 'repeat2');
if ~exist(rep_dir, 'dir')
    mkdir(rep_dir);
end

passive_relevant = struct();
passive_relevant.dff_st = cell(size(passive.dff_st));
passive_relevant.stim_info = passive.stim_info;
passive_relevant.all_trial_info = passive.all_trial_info;
for dataset_id = 1:numel(passive.dff_st)
    passive_relevant.dff_st{dataset_id}.stim = passive.dff_st{dataset_id}.ctrl;
    passive_relevant.dff_st{dataset_id}.ctrl = passive.dff_st{dataset_id}.ctrl;
    passive_relevant.dff_st{dataset_id}.z_stim = passive.dff_st{dataset_id}.z_ctrl;
    passive_relevant.dff_st{dataset_id}.z_ctrl = passive.dff_st{dataset_id}.z_ctrl;
    passive_relevant.all_trial_info(dataset_id).opto = passive.all_trial_info(dataset_id).sound_only;
    passive_relevant.all_trial_info(dataset_id).sound_only = passive.all_trial_info(dataset_id).sound_only;
end

run_prepost_contexts(params.info_updated, half_pack.repeat2.regular_relevant, half_pack.repeat2.irrelevant_first_relevant, spont, true, ...
    fullfile(rep_dir, 'relevant_regular_vs_irrelevant_first'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Regular', 'Irrelevant-first'}, params);
run_prepost_contexts(params.info_updated, half_pack.repeat2.regular_combined, half_pack.repeat2.irrelevant_first_combined, spont, true, ...
    fullfile(rep_dir, 'combined_regular_vs_irrelevant_first'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Regular', 'Irrelevant-first'}, params);

run_prepost_contexts(params.info_updated, half_pack.repeat2.regular_relevant, passive_relevant, spont, true, ...
    fullfile(rep_dir, 'relevant_regular_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Regular repeat 2', 'Passive'}, params);
run_prepost_contexts(params.info_updated, half_pack.repeat2.irrelevant_first_relevant, passive_relevant, spont, true, ...
    fullfile(rep_dir, 'relevant_irrelevant_first_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Irrelevant-first repeat 2', 'Passive'}, params);
run_prepost_contexts(params.info_updated, half_pack.repeat2.regular_combined, passive, spont, true, ...
    fullfile(rep_dir, 'combined_regular_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Regular repeat 2', 'Passive'}, params);
run_prepost_contexts(params.info_updated, half_pack.repeat2.irrelevant_first_combined, passive, spont, true, ...
    fullfile(rep_dir, 'combined_irrelevant_first_vs_passive'), mod_params, sorted_cells, all_celltypes, num_cells, ...
    {'Irrelevant-first repeat 2', 'Passive'}, params);


%%

function validation = validate_irrelevant_first_inputs(active_regular, passive, spont, active_irrelevant_first)
n_datasets = numel(active_irrelevant_first.dff_st);
if numel(active_regular.dff_st) ~= n_datasets || numel(passive.dff_st) ~= n_datasets || numel(spont.dff_st) ~= n_datasets
    error('run_sounds_analysis_irrelevant_first:DatasetCount', ...
        'Active, passive, spont, and active irrelevant-first dataset counts differ.');
end

validation.n_condition5 = zeros(1, n_datasets);
validation.n_stim_trials = zeros(1, n_datasets);
validation.n_ctrl_trials = zeros(1, n_datasets);
validation.n_neurons = zeros(1, n_datasets);
validation.n_ctrl_windows_with_sound = zeros(1, n_datasets);
validation.condition5_disjoint_from_regular = true(1, n_datasets);

for dataset = 1:n_datasets
    qc = active_irrelevant_first.qc(dataset);
    if qc.n_stim_trials < 1 || any(qc.condition5_codes ~= 5)
        error('run_sounds_analysis_irrelevant_first:Condition5', ...
            'Dataset %d did not return active condition-5 first repeats.', dataset);
    end
    regular_rows = [active_regular.stim_info{dataset, 2}(:); active_regular.stim_info{dataset, 3}(:)];
    if ~isempty(intersect(qc.condition5_rows, regular_rows))
        validation.condition5_disjoint_from_regular(dataset) = false;
        error('run_sounds_analysis_irrelevant_first:Condition5InRegular', ...
            'Condition-5 rows are present in the regular active stim or ctrl indices for dataset %d.', dataset);
    end

    stim_size = size(active_irrelevant_first.dff_st{dataset}.stim);
    ctrl_size = size(active_irrelevant_first.dff_st{dataset}.ctrl);
    regular_size = size(active_regular.dff_st{dataset}.stim);
    passive_size = size(passive.dff_st{dataset}.stim);
    spont_size = size(spont.dff_st{dataset}.stim);
    if stim_size(2) ~= regular_size(2) || stim_size(2) ~= passive_size(2) || stim_size(2) ~= spont_size(2)
        error('run_sounds_analysis_irrelevant_first:NeuronCount', ...
            'Neuron count differs across structures for dataset %d.', dataset);
    end
    if stim_size(3) ~= regular_size(3) || ctrl_size(3) ~= stim_size(3) || spont_size(3) ~= stim_size(3)
        error('run_sounds_analysis_irrelevant_first:FrameCount', ...
            'Frame count differs across structures for dataset %d.', dataset);
    end
    if ctrl_size(1) < 1
        error('run_sounds_analysis_irrelevant_first:MissingControl', ...
            'Dataset %d has no shifted control trials.', dataset);
    end

    validation.n_condition5(dataset) = qc.n_stim_trials;
    validation.n_stim_trials(dataset) = stim_size(1);
    validation.n_ctrl_trials(dataset) = ctrl_size(1);
    validation.n_neurons(dataset) = stim_size(2);
    validation.n_ctrl_windows_with_sound(dataset) = qc.ctrl_overlap.n_windows_with_sound;
end

validation.passive_stim_size = cellfun(@(x) size(x.stim), passive.dff_st, 'UniformOutput', false);
validation.spont_stim_size = cellfun(@(x) size(x.stim), spont.dff_st, 'UniformOutput', false);
validation.regular_stim_size = cellfun(@(x) size(x.stim), active_regular.dff_st, 'UniformOutput', false);
validation.regular_ctrl_size = cellfun(@(x) size(x.ctrl), active_regular.dff_st, 'UniformOutput', false);
validation.ctrl_shift_frames = active_irrelevant_first.ctrl_shift_frames;
validation.ctrl_shift_reference = active_irrelevant_first.ctrl_shift_reference;
validation.summary = sprintf( ...
    ['Condition-5 stim trials per dataset: %s. ' ...
     'Shifted control windows that overlap another sound: %s of %s.'], ...
    mat2str(validation.n_condition5), ...
    mat2str(validation.n_ctrl_windows_with_sound), ...
    mat2str(validation.n_ctrl_trials));
end

function spont_reproduction = compare_spont_mod_index(combined_mod, irrelevant_mod)
n_datasets = size(combined_mod, 1);
differences = zeros(1, n_datasets);
for dataset = 1:n_datasets
    differences(dataset) = max(abs(combined_mod{dataset, 3} - irrelevant_mod{dataset, 2}));
end
spont_reproduction.max_abs_difference_per_dataset = differences;
spont_reproduction.max_abs_difference = max(differences);
spont_reproduction.match = spont_reproduction.max_abs_difference <= 1e-10;
end

function pack = extract_exploratory_active(mouse_date, server, before_after_frames, half_scope)
n_datasets = length(mouse_date);
pack.half_scope = half_scope;
pack.catalog = struct('onset', {}, 'offset', {}, 'condition', {}, ...
    'trial_num', {}, 'repeat_index', {}, 'block_id', {}, 'first_condition', {});
for dataset = 1:n_datasets
    mm = mouse_date{dataset};
    ss = server{dataset};
    deconv = load(strcat(ss, '/Connie/ProcessedData/', mm, '/deconv/deconv.mat'));
    load(strcat(ss, '/Connie/ProcessedData/', mm, '/dff.mat'));
    deconv = deconv.deconv;
    load(strcat(ss, '/Connie/ProcessedData/', mm, '/VR/vr_sound_frames.mat'));
    load(strcat(ss, '/Connie/ProcessedData/', mm, '/VR/imaging.mat'));
    load(strcat(ss, '/Connie/ProcessedData/', mm, '/alignment_info.mat'));
    updated = fix_vr_sound_frames(vr_sound_frames, imaging, alignment_info, 'dir_string', 'VR');
    catalog = catalog_active_sounds(updated);
    pack.catalog(dataset) = catalog;

    selections = struct();
    [selections.irrelevant_early.stim, selections.irrelevant_early.ctrl] = deal( ...
        select_active_rows(catalog, 1, 5, 'irrelevant_first', 'early', half_scope), []);
    [selections.irrelevant_late.stim, selections.irrelevant_late.ctrl] = deal( ...
        select_active_rows(catalog, 1, 5, 'irrelevant_first', 'late', half_scope), []);
    [selections.regular_early.stim, selections.regular_early.ctrl] = regular_ctrl_rows(catalog, 'early', half_scope);
    [selections.regular_late.stim, selections.regular_late.ctrl] = regular_ctrl_rows(catalog, 'late', half_scope);
    [selections.repeat2_regular_relevant.stim, selections.repeat2_regular_relevant.ctrl] = deal( ...
        select_active_rows(catalog, 2, [1, 2], 'regular', 'all', half_scope), []);
    [selections.repeat2_irrelevant_first_relevant.stim, selections.repeat2_irrelevant_first_relevant.ctrl] = deal( ...
        select_active_rows(catalog, 2, [1, 2], 'irrelevant_first', 'all', half_scope), []);
    [selections.repeat2_regular_combined.stim, selections.repeat2_regular_combined.ctrl] = deal( ...
        select_active_rows(catalog, 2, [3, 4], 'regular', 'all', half_scope), []);
    [selections.repeat2_irrelevant_first_combined.stim, selections.repeat2_irrelevant_first_combined.ctrl] = deal( ...
        select_active_rows(catalog, 2, [3, 4], 'irrelevant_first', 'all', half_scope), []);

    names = fieldnames(selections);
    for n = 1:numel(names)
        fprintf('%s dataset %d: %d stim rows, %d ctrl rows\n', names{n}, dataset, ...
            numel(selections.(names{n}).stim), numel(selections.(names{n}).ctrl));
        aligned = align_selected_rows(dff, deconv, imaging, updated, catalog, ...
            selections.(names{n}).stim, selections.(names{n}).ctrl, before_after_frames, names{n}, dataset);
        pack = store_aligned(pack, names{n}, dataset, n_datasets, aligned);
    end
    pack.repeat2_prewindow_overlap(dataset) = count_repeat2_prewindow_overlap(catalog);
end
end

function catalog = catalog_active_sounds(updated)
onset = updated.corr_frames(:, 1);
offset = updated.corr_frames(:, 2);
condition = updated.condition(:);
trial_num = updated.trial_num(:);
n = numel(condition);
repeat_index = zeros(n, 1);
for trial_id = unique(trial_num)'
    rows = find(trial_num == trial_id);
    [~, order] = sort(onset(rows));
    rows = rows(order);
    repeat_index(rows) = (1:numel(rows))';
end
first_rows = find(repeat_index == 1);
[~, order] = sortrows([trial_num(first_rows), onset(first_rows)]);
first_rows = first_rows(order);
block_of_first = ones(numel(first_rows), 1);
first_is_irrelevant = condition(first_rows) == 5;
for k = 2:numel(first_rows)
    block_of_first(k) = block_of_first(k - 1) + (first_is_irrelevant(k) ~= first_is_irrelevant(k - 1));
end
block_id = zeros(n, 1);
first_condition = nan(n, 1);
for k = 1:numel(first_rows)
    same_trial = trial_num == trial_num(first_rows(k));
    block_id(same_trial) = block_of_first(k);
    first_condition(same_trial) = condition(first_rows(k));
end
catalog.onset = onset;
catalog.offset = offset;
catalog.condition = condition;
catalog.trial_num = trial_num;
catalog.repeat_index = repeat_index;
catalog.block_id = block_id;
catalog.first_condition = first_condition;
end

function rows = select_active_rows(catalog, repeat_number, sound_codes, block_mode, half, scope)
mask = catalog.repeat_index == repeat_number & ismember(catalog.condition, sound_codes(:));
if strcmp(block_mode, 'irrelevant_first')
    mask = mask & catalog.first_condition == 5;
elseif strcmp(block_mode, 'regular')
    mask = mask & catalog.first_condition ~= 5;
end
rows = apply_chronological_half(catalog, find(mask), half, scope);
end

function [stim_rows, ctrl_rows] = regular_ctrl_rows(catalog, half, scope)
rows = select_active_rows(catalog, 1, [1, 2, 3, 4], 'regular', half, scope);
condition = catalog.condition(rows);
stim_rows = sort(rows(ismember(condition, [3, 4])));
ctrl_rows = sort(rows(ismember(condition, [1, 2])));
stim_rows = stim_rows(:)';
ctrl_rows = ctrl_rows(:)';
end

function chosen = apply_chronological_half(catalog, candidate_rows, half, scope)
candidate_rows = candidate_rows(:);
if isempty(candidate_rows)
    chosen = [];
    return
end
if strcmp(scope, 'session') || strcmp(half, 'all')
    group_ids = ones(size(candidate_rows));
else
    group_ids = catalog.block_id(candidate_rows);
end
keep = false(size(candidate_rows));
for group_id = unique(group_ids)'
    members = find(group_ids == group_id);
    [~, order] = sort(catalog.onset(candidate_rows(members)));
    members = members(order);
    n_early = floor(numel(members) / 2);
    if strcmp(half, 'early')
        take = members(1:n_early);
    elseif strcmp(half, 'late')
        take = members(n_early + 1:end);
    else
        take = members;
    end
    keep(take) = true;
end
chosen = candidate_rows(keep);
[~, order] = sort(catalog.onset(chosen));
chosen = chosen(order)';
end

function aligned = align_selected_rows(dff, deconv, imaging, updated, catalog, stim_rows, ctrl_rows, before_after_frames, tag, dataset)
stim_rows = stim_rows(:)';
ctrl_rows = ctrl_rows(:)';
if isempty(stim_rows) || (~isempty(ctrl_rows) && isempty(ctrl_rows))
    error('extract_exploratory_active:NoTrials', ...
        '%s has no stim trials in dataset %d. A one-trial block contributes only to the late half.', tag, dataset);
end
placeholder = isempty(ctrl_rows);
if isempty(stim_rows)
    error('extract_exploratory_active:NoTrials', ...
        '%s has no stim trials in dataset %d. A one-trial block contributes only to the late half.', tag, dataset);
end
placeholder = isempty(ctrl_rows);
if placeholder
    spare = find(catalog.repeat_index == 1 & catalog.condition == 1);
    spare = setdiff(spare(:)', stim_rows, 'stable');
    if isempty(spare)
        error('extract_exploratory_active:NoPlaceholder', ...
            '%s dataset %d has no condition-1 repeat outside the stim set.', tag, dataset);
    end
    ctrl_rows = spare(1);
end
[allcells, ~, ~, valid_trials] = optoalign_function( ...
    stim_rows, ctrl_rows, [onset, onset], dff, deconv, ...
    before_after_frames(1), before_after_frames(2), [0, 0]);
[stim_matrix, ctrl_matrix, z_stim, z_ctrl] = make_tr_cel_time(allcells, 1);
valid_stim = stim_rows(ismember(stim_rows, valid_trials));
valid_ctrl = ctrl_rows(~ismember(ctrl_rows, stim_rows));
valid_ctrl = valid_ctrl(ismember(valid_ctrl, valid_trials));
if isempty(valid_stim) || (~placeholder && isempty(valid_ctrl))
    error('extract_exploratory_active:NoValidWindows', ...
        '%s dataset %d has no valid aligned trials.', tag, dataset);
end
aligned.dff_st.stim = stim_matrix;
aligned.dff_st.ctrl = ctrl_matrix;
aligned.dff_st.z_stim = z_stim;
aligned.dff_st.z_ctrl = z_ctrl;
aligned.all_trial_info.opto = define_trial_info_sounds(imaging, updated.trial_num(valid_stim));
aligned.all_trial_info.sound_only = define_trial_info_sounds(imaging, updated.trial_num(valid_ctrl));
% aligned.stim_info = {alignment, valid_stim, valid_ctrl};
aligned.stim_info = {updated.corr_frames, valid_stim(:)', valid_ctrl(:)'};
aligned.trial_num = updated.trial_num(valid_stim);
aligned.condition = updated.condition(valid_stim);
aligned.block_id = catalog.block_id(valid_stim);
aligned.first_condition = catalog.first_condition(valid_stim);
aligned.repeat_index = catalog.repeat_index(valid_stim);
if placeholder
    aligned.dff_st.ctrl = aligned.dff_st.stim;
    aligned.dff_st.z_ctrl = aligned.dff_st.z_stim;
    aligned.all_trial_info.sound_only = aligned.all_trial_info.opto;
    aligned.stim_info{3} = valid_stim;
end
end

function pack = store_aligned(pack, name, dataset, n_datasets, aligned)
if contains(name, 'repeat2_')
    group = 'repeat2';
    field_name = erase(name, 'repeat2_');
else
    group = '';
    field_name = name;
end
if isempty(group)
    target = pack;
else
    if ~isfield(pack, group)
        pack.(group) = struct();
    end
    target = pack.(group);
end
if ~isfield(target, field_name)
    target.(field_name).dff_st = cell(1, n_datasets);
    target.(field_name).stim_info = cell(n_datasets, 3);
    target.(field_name).qc = struct([]);
end
target.(field_name).dff_st{dataset} = aligned.dff_st;
target.(field_name).stim_info(dataset, :) = aligned.stim_info;
target.(field_name).all_trial_info(dataset) = aligned.all_trial_info;
target.(field_name).qc(dataset).trial_num = aligned.trial_num;
target.(field_name).qc(dataset).condition = aligned.condition;
target.(field_name).qc(dataset).block_id = aligned.block_id;
target.(field_name).qc(dataset).first_condition = aligned.first_condition;
target.(field_name).qc(dataset).repeat_index = aligned.repeat_index;
if isempty(group)
    pack = target;
else
    pack.(group) = target;
end
end

function overlap = count_repeat2_prewindow_overlap(catalog)
% Existing prepost pre window is frames 51:60. Onset is frame 61, so this is onset-10:onset-1.
repeat2 = find(catalog.repeat_index == 2);
overlap.n_repeat2 = numel(repeat2);
overlap.n_prewindow_contains_previous_sound = 0;
for k = 1:numel(repeat2)
    previous = find(catalog.trial_num == catalog.trial_num(repeat2(k)) & catalog.repeat_index == 1, 1);
    if ~isempty(previous) && catalog.offset(previous) >= catalog.onset(repeat2(k)) - 10
        overlap.n_prewindow_contains_previous_sound = overlap.n_prewindow_contains_previous_sound + 1;
    end
end
end

function result = run_prepost_contexts(info, ctx1, ctx2, spont, sided, save_dir, mod_template, sorted_cells, all_celltypes, num_cells, labels, params)
modp = mod_template;
modp.mod_type = 'prepost';
modp.mod_threshold = 0;
modp.min_cells = 0;
if sided
    info_run = info;
    info_run.active_all_trial_info = ctx1.all_trial_info;
    info_run.passive_all_trial_info = ctx2.all_trial_info;
    [context_dff, stim_trials, ctrl_trials] = organize_2context( ...
        ctx1.dff_st, ctx2.dff_st, 'extra_contexts', {spont.dff_st});
    [~, dff_combined] = combine_stim_info_dff_st( ...
        ctx1.stim_info, ctx2.stim_info, ctx1.dff_st, ctx2.dff_st, ...
        'extra_stim_info', {spont.stim_info}, 'extra_dff', {spont.dff_st});
    [result.results, result.sig_mod_boot, result.mod] = wrapper_mod_index_calculation_white_noise( ...
        info_run, dff_combined, modp.response_range, modp.mod_type, modp.mode, ...
        stim_trials, ctrl_trials, modp.nShuffles, save_dir);
else
    [context_dff, stim_trials, ctrl_trials] = organize_2context(ctx1.dff_st, ctx2.dff_st);
    [~, dff_combined] = combine_stim_info_dff_st( ...
        ctx1.stim_info, ctx2.stim_info, ctx1.dff_st, ctx2.dff_st);
    [result.results, result.sig_mod_boot, result.mod] = wrapper_mod_index_two_contexts( ...
        info, dff_combined, modp.response_range, modp.mod_type, modp.mode, ...
        stim_trials, ctrl_trials, modp.nShuffles, save_dir);
end
mod_plot = result.mod(:, 1:2);
sig_plot = result.sig_mod_boot(:, 1:2);
modp.chosen_mice = 1:size(mod_plot, 1);
modp.results = result.results;
result.sig_mod_boot_thr = plot_pie_thresholded_mod_index( ...
    info, modp, mod_plot, sig_plot, sorted_cells, all_celltypes, save_dir);
[result.sig_cells, ~] = union_sig_cells(result.sig_mod_boot_thr(:, 1)', result.sig_mod_boot_thr(:, 2)', mod_plot);
save(fullfile(save_dir, 'prepost_result.mat'), 'result');

plot_info = plotting_config();
plot_info.behavioral_contexts = labels;
plot_info.plot_labels = {'Sounds', 'Sounds'};
plot_info.type = 'sounds';
plot_info.y_lims = [-.4, .4];
params.plot_info = plot_info;
params.min_cells = 0;
[~, ~] = wrapper_avg_cell_type_traces(context_dff, all_celltypes, mod_plot, sig_plot, modp, ...
    fullfile(save_dir, 'sig_cells'), 'sound_dff', plot_info);
n_ctx = size(context_dff, 1);
all_cells = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), n_ctx, 1)';
[~, ~] = wrapper_avg_cell_type_traces(context_dff, all_celltypes, mod_plot, all_cells, modp, ...
    save_dir, 'sound_dff', plot_info);
params.plot_info.y_lims = [-.1, .1];
result.stats = generate_mod_index_plots_datasets( ...
    modp.chosen_mice, mod_plot, [], all_celltypes(1, modp.chosen_mice), params, save_dir);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), '-struct', 'result', 'stats');
if ~isempty([result.sig_cells{modp.chosen_mice}])
    result.sig_stats = generate_mod_index_plots_datasets( ...
        modp.chosen_mice, mod_plot, result.sig_cells, all_celltypes(1, modp.chosen_mice), ...
        params, fullfile(save_dir, 'sig_cells'));
    save(fullfile(save_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), '-struct', 'result', 'sig_stats');
end
end

function result = run_ctrl_half_vs_passive(info, active_half, passive, spont, save_dir, ctrl_template, combined_mod, combined_sig_boot, sorted_cells, all_celltypes, num_cells, labels, params)
ctrl_params = ctrl_template;
ctrl_params.mod_type = 'ctrl';
ctrl_params.mod_threshold = 0.1;
ctrl_params.min_cells = 0;
info_run = info;
info_run.active_all_trial_info = active_half.all_trial_info;
[context_dff, stim_trials, ctrl_trials] = organize_2context( ...
    active_half.dff_st, passive.dff_st, 'extra_contexts', {spont.dff_st});
[~, dff_combined] = combine_stim_info_dff_st( ...
    active_half.stim_info, passive.stim_info, active_half.dff_st, passive.dff_st, ...
    'extra_stim_info', {spont.stim_info}, 'extra_dff', {spont.dff_st});
[result.results, result.sig_mod_boot, result.mod] = wrapper_mod_index_calculation_white_noise( ...
    info_run, dff_combined, ctrl_params.response_range, ctrl_params.mod_type, ctrl_params.mode, ...
    stim_trials, ctrl_trials, ctrl_params.nShuffles, save_dir);
ctrl_params.chosen_mice = 1:size(result.mod, 1);
ctrl_params.results = result.results;
result.sig_cells = plot_pie_thresholded_mod_index( ...
    info, ctrl_params, combined_mod(:, 3), combined_sig_boot(:, 3), sorted_cells, all_celltypes, save_dir);
save(fullfile(save_dir, 'ctrl_result.mat'), 'result');

plot_info = plotting_config();
plot_info.y_lims = [-.3, .3];
plot_info.plot_labels = {'Stim', 'Ctrl'};
plot_info.behavioral_contexts = labels;
plot_info.figure_width_traces = 11;
plot_info.xlims_traces = [31, 91];
plot_info.type = 'opto';
params.plot_info = plot_info;
params.min_cells = 0;
[~, ~] = wrapper_avg_cell_type_traces(context_dff, all_celltypes, result.mod, result.sig_cells, ctrl_params, ...
    fullfile(save_dir, 'sig_cells'), 'opto_dff', plot_info, combined_mod);
plot_info.colors_celltypes_3contexts(1, :) = [0.54, 0.82, 0.64];
[~, ~] = wrapper_avg_cell_type_traces(context_dff, all_celltypes, result.mod, result.sig_cells, ctrl_params, ...
    fullfile(save_dir, 'sig_cells'), 'opto_dff_spont', plot_info, combined_mod, [3]);
plot_info.colors_celltypes_3contexts(1, :) = [0.16, 0.4, 0.24];
params.plot_info = plot_info;
all_cells = repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false), 3, 1)';
[~, ~] = wrapper_avg_cell_type_traces(context_dff, all_celltypes, result.mod, all_cells, ctrl_params, ...
    save_dir, 'opto_dff', plot_info, combined_mod);
result.stats = generate_mod_index_plots_datasets( ...
    ctrl_params.chosen_mice, result.mod, [], all_celltypes(1, ctrl_params.chosen_mice), params, save_dir);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), '-struct', 'result', 'stats');
if ~isempty([result.sig_cells{ctrl_params.chosen_mice}])
    result.sig_stats = generate_mod_index_plots_datasets( ...
        ctrl_params.chosen_mice, result.mod, result.sig_cells', all_celltypes(1, ctrl_params.chosen_mice), ...
        params, fullfile(save_dir, 'sig_cells'));
    save(fullfile(save_dir, 'sig_cells', 'mod_index_stats_datasets.mat'), '-struct', 'result', 'sig_stats');
end
end
