%% Supplementary experimental controls
% 1) Passive corridor: sound modulation (active vs passive corridor) and
%    running velocity (active vs passive corridor).
% 2) Irrelevant sound analysis: to be added.
%
% Contexts: 1 = active, 2 = passive, 3 = spont, 4 = passive corridor.
% Datasets, pooling and sound MI results follow
% scripts/mod_index/run_sounds_analysis_main_w_noise_passive_corridor.m.

addpath(genpath('C:\Code\Github\BassiRunyan2025'))
params = experiment_config();
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;

%% PASSIVE CORRIDOR
%% 1) Passive corridor datasets
info.mouse_date = {
    'LD2-1L\2026-08-24'
    'LD2-1L\2026-08-26'
    'LD2-1L\2026-08-31'
    'LD1-00\2026-08-24'
    'LD5-00\2026-08-27'
    'LD5-00\2026-08-26'
    'LD5-00\2026-08-25'
    'KN8-3L\2026-08-05'
    'KN8-3L\2026-08-07'
    'KW-2-1L\2026-08-04'
    'KW-2-1L\2026-08-05'
    'KW-2-1L\2026-08-07'
    'KW-2-1L\2026-08-03'
    'KN8-3L\2026-07-28'     %black walls
    'KN8-3L\2026-07-29'     %black walls
    }';

info.sound_type = repmat({'1000ms_sweeps_4'}, 1, numel(info.mouse_date));

info.mouseid = {1 1 1 2 3 3 3 4 4 5 5 5 5 4 4};
info.serverid = repmat({'W:'},1,numel(info.mouse_date));
params.info_updated = info;
% generate_mod_index_plots_datasets groups datasets by params.info.mouseid
params.info = info;

%% 2) Pool activity (or load the saved pooling outputs)
pooled_dir = 'W:\Connie\results\Bassi2025\data\supplemental_data\passive_corridor';
pooled_file = fullfile(pooled_dir, 'pooled_passive_corridor.mat');
repool = false; % true to rerun pooling from the original data

if repool || ~exist(pooled_file, 'file')
    if exist(pooled_file, 'file')
        error('Pooled file already exists: %s (rename or delete it to repool).', pooled_file);
    end
    [all_celltypes,active,passive,spont,passive_corridor] = pool_activity_sounds_vr_and_passive_corridor(params.info_updated.mouse_date,params.info_updated.serverid, [60,60]);

    params.info_updated.active_all_trial_info = active.all_trial_info;
    params.info_updated.passive_all_trial_info = passive.all_trial_info;
    params.info_updated.passive_corridor_all_trial_info = passive_corridor.all_trial_info;

    [num_cells, sorted_cells] = organize_pooled_celltypes(active.dff_st, all_celltypes); %gives index relative to all datasets
    [~,stim_trials_context,ctrl_trials_context] = organize_2context(active.dff_st,passive.dff_st,'extra_contexts',{spont.dff_st,passive_corridor.dff_st});
    [stim_info_combined,~] = combine_stim_info_dff_st(active.stim_info,passive.stim_info, active.dff_st,passive.dff_st,'extra_stim_info',{spont.stim_info,passive_corridor.stim_info},'extra_dff',{spont.dff_st,passive_corridor.dff_st});
    clear active passive spont passive_corridor

    pooled_info = params.info_updated;
    if ~exist(pooled_dir, 'dir'), mkdir(pooled_dir); end
    save(pooled_file, 'pooled_info', 'all_celltypes', 'num_cells', 'sorted_cells', ...
        'stim_trials_context', 'ctrl_trials_context', 'stim_info_combined', '-v7.3');
else
    load(pooled_file, 'pooled_info', 'all_celltypes', 'num_cells', 'sorted_cells', ...
        'stim_trials_context', 'ctrl_trials_context', 'stim_info_combined');
    assert(isequal(pooled_info.mouse_date, info.mouse_date), ...
        'Saved pooling outputs were generated from a different dataset list.');
    params.info_updated = pooled_info;
end

%% 3) Saved sound modulation indices (prepost_sound, separate, 0 threshold)
sound_mod_dir = 'W:\Connie\results\Bassi2025\fig3\reviews\0thres\passive_corridor\prepost_sound\separate';
sound = load(fullfile(sound_mod_dir, 'sound.mat')).sound;

n_datasets = numel(info.mouse_date);
n_cells_mod = cellfun(@numel, sound.mod(:,1))';
fprintf('Datasets: %d listed, %d pooled, %d in sound.mod; contexts in sound.mod: %d; trial contexts: %d\n', ...
    n_datasets, numel(all_celltypes), size(sound.mod,1), size(sound.mod,2), numel(stim_trials_context{1}));
fprintf('Mice: %d (%s)\n', numel(unique([info.mouseid{:}])), mat2str([info.mouseid{:}]));
fprintf('Neuron counts match sound.mod for all datasets: %d\n', isequal(num_cells(:)', n_cells_mod));
assert(size(sound.mod,1) == n_datasets && numel(all_celltypes) == n_datasets, 'Dataset count mismatch.');
assert(isequal(num_cells(:)', n_cells_mod), 'Neuron counts differ between pooled data and sound.mod.');
