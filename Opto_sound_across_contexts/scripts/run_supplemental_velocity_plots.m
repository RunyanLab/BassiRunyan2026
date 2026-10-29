%% PLOT ALIGNED TO SOUNDS!!
[speed_params,speed_params_single] = get_speed_params(1); %control_or_opto

%% 1) PLOT EXAMPLE TRIALS HEATMAPS ALIGNED TO SOUNDS ACROSS CONTEXTS
save_data_directory = [];
chosen_mice = [1:25];

% load aligned data
load('mouse_vel_active.mat');load('mouse_vel_pass.mat'); load('trial_event_info.mat');load('trial_event_info_pass.mat');

speed_params_single.xlabel = 'Time from first sound (s)';
%make plots aligned to first sound!
speed_params_single.vel_type = 'roll'; %'pitch/'both'/'roll'
speed_params_single.colormap = 'RdBu';
speed_params_single.plot_avg = 0;
plot_velocity_turns_sounds([1:9,11:24],info,mouse_vel_active,mouse_vel_pass,speed_params_single,trial_event_info,save_data_directory); %uses trial_event_info from active to plot where turns happen

%make plots aligned to first sound!
speed_params_single.vel_type = 'pitch'; %'pitch/'both'/'roll'
speed_params_single.colormap = 'Blues'; %choose sequential heatmap %bilbao/ tempo/ binary/'BuPu'
speed_params_single.plot_avg = 0;
plot_velocity_turns_sounds([1:9,11:24],info,mouse_vel_active,mouse_vel_pass,speed_params_single,trial_event_info,save_data_directory); %uses trial_event_info from active to plot where turns happen

%make plots aligned to first sound!
speed_params_single.vel_type = 'both'; %'pitch/'both'/'roll'
speed_params_single.colormap = 'Blues'; %choose sequential heatmap %bilbao/ tempo/ binary/'BuPu'
speed_params_single.plot_avg = 0;
plot_velocity_turns_sounds([1:9,11:24],info,mouse_vel_active,mouse_vel_pass,speed_params_single,trial_event_info,save_data_directory); %uses trial_event_info from active to plot where turns happen

%% 2) ALIGN DATA 2 SEC BEFORE AND 2 SEC AFTER SOUND
%load aligned data
load('mouse_vel_aligned_sounds');load('left_ctrl_all');load('right_ctrl_all')
speed_params.chosen_mice = [1:25];
%% 3) Make plots of average speed across contexts
speed_params.trials_to_use =  {left_ctrl_all;right_ctrl_all};
speed_params.specified_frames = speed_params.stim_frame; %whichever frames to take average off (to write numbers down on paper)

%plot average trace of runnning speeds across contexts
speed_params.xlabel = 'Time from 1st sound (s)';
plot_speed_avg_trace_across_contexts(speeds_mean_sem, speed_params,save_dir);

%plot cdf of averaged running speeds across contexts// takes sign rank comparisons (comparison across datasets from one context to next)
general_stats.speed_cdf = cdf_speed_avg_across_contexts(avg_speed_axis_data, speed_params,save_dir);

supplementary_table_2 = struct2table_recursive(general_stats,'',{'bootstat','ci'});
save(fullfile(save_dir, 'supplementary_table_2.mat'), 'supplementary_table_2');
writetable(supplementary_table_2, fullfile(save_dir, 'supplementary_table_2.csv'));
%% 3.5) ADD more analysis across animals
%specify what to avg over
speed_params.specified_frames =61;% 61-10:61+10;%for avg at onset 61
[deltaLeft,deltaRight,avg_speed_axis_data,speeds_mean_sem,speeds_mean_sem_specified_frames,general_stats,avg_speeds_axis_data_specified_frames] = process_aligned_vel_all_axis([1:25], mouse_vel_aligned_sounds, speed_params.trials_to_use, speed_params);

mouse_ids = [...
    1 1 2 2 3 3 4 4 5 5 5 1 1 1 2 2 3 3 3 4 4 4 4 5 6];
stats_mouse = plot_speed_at_onset_by_mouse( ...
    avg_speeds_axis_data_specified_frames, ...
    mouse_ids, ...
    speed_params, ...
    save_dir, ...
    'aggregate_by','mouse');

stats_mouse.frames_before_after_avg = [speed_params.specified_frames(1) ,speed_params.specified_frames(end)];
supplementary_table_mousespeed_2 = struct2table_recursive(stats_mouse,'',{'bootstat','ci'});
save(fullfile(save_dir, 'supplementary_table_mousespeed_2.mat'), 'supplementary_table_mousespeed_2');
writetable(supplementary_table_2, fullfile(save_dir, 'supplementary_table_mousespeed_2.csv'));

stats_session = plot_speed_at_onset_by_mouse( ...
    avg_speeds_axis_data_specified_frames, ...
    mouse_ids, ...
    speed_params, ...
    save_dir, ...
    'aggregate_by','session');
%% 3.6) SPEED-MATCHED MOD INDEX (saved results from run_mod_specified_speed.m)
% Trials with speed (pre-period frames 50:60) within the 20th-80th percentile
% range (35-57); MI recomputed in 'simple' mode. Neurons are the original
% significant neurons. Figures are written to a new subfolder so the saved
% results are not overwritten.
params = experiment_config();
plot_info = plotting_config();
plot_info.behavioral_contexts = {'Active','Passive'};
plot_info.y_lims = [-.2, .5];
params.plot_info = plot_info;
params.min_cells = 0;
results_dir = 'W:\Connie\results\Bassi2025';
all_celltypes = load(fullfile(results_dir, 'data', 'all_celltypes.mat')).all_celltypes;

%% 3.6a) Photostim: ctrl MI, neurons significant for spont photostim
speed_mod_dir_opto = fullfile(results_dir, 'fig3', 'mod', 'ctrl', 'simple', 'speed35to57');
mod_indexm_speed_opto = load(fullfile(speed_mod_dir_opto, 'mod_indexm.mat')).mod_indexm;
opto = load(fullfile(results_dir, 'data', 'opto.mat')).opto;
sig_cells_opto = opto.sig_cells';
good_datasets_opto = 1:24;
params.info.chosen_mice = good_datasets_opto;
save_dir_speed_opto = fullfile(speed_mod_dir_opto, 'supplemental_replot');
if ~exist(save_dir_speed_opto, 'dir'), mkdir(save_dir_speed_opto); end

mod_index_stats_speed_opto = generate_mod_index_plots_datasets(good_datasets_opto, mod_indexm_speed_opto, sig_cells_opto, all_celltypes, params, save_dir_speed_opto);
table_speed = struct2table_recursive(unwrap_cells_in_struct(mod_index_stats_speed_opto),'datasets',{'bootstat','ci'});
save(fullfile(save_dir_speed_opto, 'table_speed.mat'), 'table_speed');
writetable(table_speed, fullfile(save_dir_speed_opto, 'table_speed.csv'));

saved_table = load(fullfile(speed_mod_dir_opto, 'table_speed.mat')).table_speed;
fprintf('Photostim: %d datasets, %d significant neurons, table matches saved table_speed.mat: %d\n', ...
    numel(good_datasets_opto), sum(cellfun(@numel, sig_cells_opto(good_datasets_opto))), isequaln(table_speed, saved_table));

%% 3.6b) Sound: prepost_sound MI, neurons significant for sound (active/passive union)
speed_mod_dir_sound = fullfile(results_dir, 'fig3', 'sounds', 'mod', 'prepost_sound', 'simple', 'speed35to57');
mod_indexm_speed_sound = load(fullfile(speed_mod_dir_sound, 'mod_indexm.mat')).mod_indexm;
sound = load(fullfile(results_dir, 'data', 'sound.mat')).sound;
sig_cells_sound = sound.sig_cells;
good_datasets_sound = 1:25;
params.info.chosen_mice = good_datasets_sound;
save_dir_speed_sound = fullfile(speed_mod_dir_sound, 'supplemental_replot');
if ~exist(save_dir_speed_sound, 'dir'), mkdir(save_dir_speed_sound); end

mod_index_stats_speed_sound = generate_mod_index_plots_datasets(good_datasets_sound, mod_indexm_speed_sound, sig_cells_sound, all_celltypes, params, save_dir_speed_sound);
table_speed = struct2table_recursive(unwrap_cells_in_struct(mod_index_stats_speed_sound),'datasets',{'bootstat','ci'});
save(fullfile(save_dir_speed_sound, 'table_speed.mat'), 'table_speed');
writetable(table_speed, fullfile(save_dir_speed_sound, 'table_speed.csv'));

saved_table = load(fullfile(speed_mod_dir_sound, 'table_speed.mat')).table_speed;
fprintf('Sound: %d datasets, %d significant neurons, table matches saved table_speed.mat: %d\n', ...
    numel(good_datasets_sound), sum(cellfun(@numel, sig_cells_sound(good_datasets_sound))), isequaln(table_speed, saved_table));

%% 4) find trial matched mod index!
[mouse_vel_context,mouse_vel_context_roll,mouse_vel_context_pitch,mouse_acc_context,general_stats] = speed_cdf_across_contexts([],mouse_vel_aligned_sounds,plot_info,stim_trials_context,ctrl_trials_context,speed_params.chosen_mice,speed_params.frames_before_event:speed_params.frames_after_event); %50:60
%20/80 percentiles
global_ranges.both = get_percentile_speeds(mouse_vel_context,[1:25], 20,80);
global_ranges.pitch = get_percentile_speeds(mouse_vel_context_pitch,[1:25], 20,80);
global_ranges.roll = get_percentile_speeds(mouse_vel_context_roll,[1:25], 20,80);

%% 5) use specified speed ranges
[speed_trials_stim,speed_trials_ctrl,bad_datasets] = find_speed_trials(mouse_vel_context,speed_range,stim_trials_context,ctrl_trials_context); %finds trials within certain speed range

