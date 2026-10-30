%% Supplementary experimental controls
% 1) Passive corridor: sound modulation (active vs passive corridor) and
%    running velocity (active vs passive corridor).
% 2) Irrelevant sound: noise modulation index (active vs passive).
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
pooled_file = 'W:\Connie\results\Bassi2025\data\supplemental_data\passive_corridor\pooled_passive_corridor.mat';

if ~exist(pooled_file, 'file')
    [all_celltypes,active,passive,spont,passive_corridor] = pool_activity_sounds_vr_and_passive_corridor(params.info_updated.mouse_date,params.info_updated.serverid, [60,60]);

    params.info_updated.active_all_trial_info = active.all_trial_info;
    params.info_updated.passive_all_trial_info = passive.all_trial_info;
    params.info_updated.passive_corridor_all_trial_info = passive_corridor.all_trial_info;
    
    %use only pyramidal
    all_celltypes_og = all_celltypes;
    all_celltypes = {};
    for i = 1:length(params.info.mouse_date)
        all_celltypes{1, i}.pyr_cells = all_celltypes_og{1, i}.pyr_cells;
    end

    [num_cells, sorted_cells] = organize_pooled_celltypes(active.dff_st, all_celltypes); %gives index relative to all datasets
    [~,stim_trials_context,ctrl_trials_context] = organize_2context(active.dff_st,passive.dff_st,'extra_contexts',{spont.dff_st,passive_corridor.dff_st});
    [stim_info_combined,~] = combine_stim_info_dff_st(active.stim_info,passive.stim_info, active.dff_st,passive.dff_st,'extra_stim_info',{spont.stim_info,passive_corridor.stim_info},'extra_dff',{spont.dff_st,passive_corridor.dff_st});
    clear active passive spont passive_corridor

    pooled_info = params.info_updated;
    if ~exist(fileparts(pooled_file), 'dir'), mkdir(fileparts(pooled_file)); end
    save(pooled_file, 'pooled_info', 'all_celltypes', 'num_cells', 'sorted_cells', ...
        'stim_trials_context', 'ctrl_trials_context', 'stim_info_combined', '-v7.3');
else
    load(pooled_file, 'pooled_info', 'all_celltypes', 'num_cells', 'sorted_cells', ...
        'stim_trials_context', 'ctrl_trials_context', 'stim_info_combined');
    params.info_updated = pooled_info;
end

%% 3) Sound modulation index: active vs passive corridor
% saved prepost_sound MI (separate mode, 0 threshold) from the original script
sound = load('W:\Connie\results\Bassi2025\data\supplemental_data\passive_corridor\sound.mat').sound;
save_root = [];%'W:\Connie\results\Bassi2025\fig3\reviews\mod\supplemental_passive_corridor\';

chosen_mice = 1:15;
context_to_test = [1,4];
mod_params = params.mod_sounds;
mod_params.chosen_mice = chosen_mice;
mod_params.mod_threshold = 0.1;
mod_params.min_cells = 0;

% significant (bootstrap) neurons with |MI| > 0.1, per context
sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[]);

% A) union of active and passive corridor; B) union of active, passive and passive corridor
[sig_cells_active_passivecorridor, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,4)', sound.mod);
[sig_cells_active_passive_passivecorridor, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod, sig_mod_boot_thr(:,4)');
selections = {sig_cells_active_passivecorridor, sig_cells_active_passive_passivecorridor};
selection_dirs = {'sig_union_active_passivecorridor', 'sig_union_active_passive_passivecorridor'};

plot_info.y_lims = [-.4, .4];
plot_info.plot_labels = {'Sounds','Sounds'};
plot_info.type = 'sounds';
params.plot_info = plot_info;
params.string = 'Sounds';
params.plot_info.behavioral_contexts = {'Active','Passive Corridor'};
params.plot_info.celltype_names = plot_info.celltype_names(1); % Pyr only
params.min_cells = 0;
params.plot_info.y_lims = [-.1,.1];
params.info.chosen_mice = 1:length(chosen_mice);

for s = 1:numel(selections)
    if isempty(save_root)
        save_dir = [];
    else
        save_dir = [save_root selection_dirs{s}];
    end
    fprintf('%s: %d neurons\n', selection_dirs{s}, sum(cellfun(@numel, selections{s}(chosen_mice))));
    mod_index_stats_datasets = generate_mod_index_plots_datasets(1:length(chosen_mice) ,  sound.mod(chosen_mice,context_to_test),  selections{s}(chosen_mice), all_celltypes(1,chosen_mice), params, save_dir);
    if ~isempty(save_dir)
        save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
    end
end

%% 4) Running velocity: active vs passive corridor
[speed_params,~] = get_speed_params(1); %control_or_opto
speed_params.chosen_mice = chosen_mice;
if isempty(save_root)
    save_dir = [];
else
    save_dir = [save_root 'velocity_active_passivecorridor'];
    if ~exist(save_dir, 'dir'), mkdir(save_dir); end
end

velocity_file = 'W:\Connie\results\Bassi2025\data\supplemental_data\passive_corridor\velocity_active_passivecorridor.mat';
if exist(velocity_file, 'file')
    load(velocity_file, 'mouse_vel_aligned_sounds', 'left_stim_all', 'left_ctrl_all', 'right_stim_all', 'right_ctrl_all');
else
    %align velocity 2 sec before and 2 sec after sound
    mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound(speed_params.chosen_mice,params.info_updated.mouse_date,params.info_updated.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info_combined); %using ctrl and sound only trials
    % passing the passive corridor trial info makes find_sound_trials use contexts [1,4]
    [~, ~, ~, ~, ~, ~, left_stim_all, left_ctrl_all,  right_stim_all, right_ctrl_all] = find_sound_trials(params.info_updated,stim_trials_context,ctrl_trials_context,params.info_updated.passive_corridor_all_trial_info);
    save(velocity_file, 'mouse_vel_aligned_sounds', 'left_stim_all', 'left_ctrl_all', 'right_stim_all', 'right_ctrl_all', '-v7.3');
end

speed_params.trials_to_use =  {left_ctrl_all;right_ctrl_all};
speed_params.specified_frames = speed_params.stim_frame; %whichever frames to take average off (to write numbers down on paper)

%calculate deltas and means for aligned velocity/speed
[deltaLeft,deltaRight,avg_speed_axis_data,speeds_mean_sem,speeds_mean_sem_specified_frames,general_stats] = process_aligned_vel_all_axis(chosen_mice, mouse_vel_aligned_sounds, speed_params.trials_to_use, speed_params);
if ~isempty(save_dir)
    save(fullfile(save_dir,'stats_avg_trace_speed_acrosscontext_60-60_abs_1.mat'),'general_stats');
end
% plot cdf of changes for function_params.frames_before_stim function_params.frames_after_stim across contexts// takes rank sum comparisons (comparison across all trials from one context to next)
delta_speeds_p_vals = cdf_speed_delta_across_contexts(deltaLeft,deltaRight,speed_params,save_dir);

%plot cdf of averaged running speeds across contexts// takes sign rank comparisons (comparison across datasets from one context to next)
general_stats.speed_cdf = cdf_speed_avg_across_contexts(avg_speed_axis_data, speed_params,save_dir);
%plot average trace of runnning speeds across contexts
speed_params.xlabel = 'Time from 1st sound (s)';
plot_speed_avg_trace_across_contexts(speeds_mean_sem, speed_params,save_dir);

if ~isempty(save_dir)
    supplementary_table_2 = struct2table_recursive(general_stats,'',{'bootstat','ci'});
    save(fullfile(save_dir, 'supplementary_table_2.mat'), 'supplementary_table_2');
    writetable(supplementary_table_2, fullfile(save_dir, 'supplementary_table_2.csv'));
end

%% IRRELEVANT SOUND
% Noise modulation index (100 ms sAM datasets); follows
% scripts/mod_index/run_sounds_analysis_main_w_noise_100ms_sam.m.
% Contexts: 1 = active, 2 = passive, 3 = spont (irrelevant sound alone).
clear all
%% 1) Irrelevant sound datasets
params = experiment_config();
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;
% generate_mod_index_plots_datasets groups datasets by params.info.mouseid
params.info = params.info_sAM;
sAM_dir = 'W:\Connie\results\Bassi2025\data\supplemental_data\irrelevant_sound\100ms_sAM';

%% 2) Pool activity (or load the saved pooling outputs)
pooled_file_sAM = fullfile(sAM_dir, 'pooled_irrelevant_sound.mat');
if ~exist(pooled_file_sAM, 'file')
    [all_celltypes_sAM,active,~,~] = pool_activity_sounds_simple(params.info_sAM.mouse_date,params.info_sAM.serverid, [60,60]);
    % focusing on pyr only because not all datasets have dual labeling
    all_celltypes_og = all_celltypes_sAM;
    all_celltypes_sAM = {};
    for i = 1:length(params.info_sAM.mouse_date)
        all_celltypes_sAM{1,i}.pyr_cells = all_celltypes_og{1,i}.pyr_cells;
    end
    [num_cells_sAM, sorted_cells_sAM] = organize_pooled_celltypes(active.dff_st, all_celltypes_sAM); %gives index relative to all datasets
    clear active
    save(pooled_file_sAM, 'all_celltypes_sAM', 'num_cells_sAM', 'sorted_cells_sAM');
else
    load(pooled_file_sAM, 'all_celltypes_sAM', 'num_cells_sAM', 'sorted_cells_sAM');
end

%% 3) Noise modulation index: active vs passive
% saved MI (separate mode, 0 threshold) from the original script:
% noise = irrelevant + relevant sound vs relevant sound alone (ctrl MI); prepost = pre vs post
noise = load(fullfile(sAM_dir, 'noise.mat')).noise;
prepost = load(fullfile(sAM_dir, 'prepost.mat')).prepost;
sound = load(fullfile(sAM_dir, 'sound.mat')).sound;

save_root_sAM = [];%'W:\Connie\results\Bassi2025\fig3\reviews\mod\supplemental_irrelevant_sound\';

chosen_mice_sAM = 1:6;
mod_params_sAM = params.mod;
mod_params_sAM.chosen_mice = chosen_mice_sAM;
mod_params_sAM.mod_threshold = 0.1;
mod_params_sAM.min_cells = 0;

% neurons significantly modulated by the irrelevant sound alone (spont prepost, |MI| > 0.1)
noise_sig_cells = plot_pie_thresholded_mod_index(params.info_sAM, mod_params_sAM, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells_sAM,all_celltypes_sAM,[]);

plot_info.y_lims = [-.3, .3];
plot_info.plot_labels = {'Stim','Ctrl'};
plot_info.behavioral_contexts = {'Active','Passive'};
params.plot_info = plot_info;
params.plot_info.celltype_names = plot_info.celltype_names(1); % Pyr only
params.min_cells = 0;
params.info.chosen_mice = chosen_mice_sAM;

if isempty(save_root_sAM)
    save_dir = [];
else
    save_dir = [save_root_sAM 'sig_noise_spont_prepost'];
end

contexts_to_compare = [1,2]; 
overlap_labels = {'Relevant Sound','Irrelevant Sound', 'Both','Unmodulated'}; 
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_cells(chosen_mice_sAM),noise_sig_cells(chosen_mice_sAM),sound.mod(chosen_mice_sAM,:), contexts_to_compare);
sound_repeat_colors = [0.5 0.5 0.5
                       [173 185 227] / 255
                        [163 121 201] / 255
                            0.3,0.2,0.6];
plot_sig_overlap_pie(mean(percent_cells_per_dataset)*100, overlap_labels, save_dir, contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',sound_repeat_colors,'FigureWidth',9);


fprintf('irrelevant sound (spont prepost) significant: %d neurons\n', sum(cellfun(@numel, noise_sig_cells(chosen_mice_sAM))));
mod_index_stats_datasets_sAM = generate_mod_index_plots_datasets(chosen_mice_sAM, noise.mod(chosen_mice_sAM,:), noise_sig_cells', all_celltypes_sAM(1,chosen_mice_sAM), params, save_dir);
if ~isempty(save_dir)
    save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets_sAM');
end
