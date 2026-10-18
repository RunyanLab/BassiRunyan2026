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
