%% PLOT ALIGNED TO SOUNDS!!
addpath(genpath('C:\Code\Github\BassiRunyan2025\Opto_sound_across_contexts\'))
load('V:\Connie\results\opto_2025\context\running\info.mat');

[speed_params,speed_params_single] = get_speed_params(1); %control_or_opto

%% 1) PLOT EXAMPLE TRIALS HEATMAPS ALIGNED TO SOUNDS ACROSS CONTEXTS
save_data_directory = ['W:/Connie/results/Bassi2025/fig3/running_updated/example_running_trials'];%['V:/Connie/results/opto_2025/context/running_updated/example_running_trials'];
chosen_mice = [1:25];

% align to stimulus
speed_params_single.trial_types = 3; %1 = all turns, 2 = all correct turns, 3 = all correct turns without opto!,4 = all correct turns with opto!
speed_params_single.event_to_align = 'stimulus';
[mouse_vel_active, trial_event_info] = run_velocity_turn_code(chosen_mice,info.mouse_date,info.serverid,speed_params_single.frames_before_event, speed_params_single.frames_after_event,speed_params_single.trial_types,speed_params_single.event_to_align);
speed_params_single.event_to_align = 'stimulus';
[mouse_vel_pass, trial_event_info_pass] = run_velocity_passive_code(chosen_mice,info.mouse_date,info.serverid,speed_params_single.frames_before_event, speed_params_single.frames_after_event,speed_params_single.trial_types,speed_params_single.event_to_align);

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
speed_params.chosen_mice = [1:25];

%1) POOL AND ALIGN NEURAL ACTIVITY
% stim_info{dataset,1} = bad_frames (relative to all); stim_info{dataset,2} = stim; stim_info{dataset,3} = ctrl; 
% stim_info_combined (combined active/passive) {dataset,1} = bad_frames (relative to all); stim_info{dataset,2} = loc 1 ctrol; stim_info{dataset,3} = loc 2 ctrl; 
[all_celltypes, sound_data, sound_context_data]  = ...
    pool_activity_sounds(info.mouse_date, info.serverid, [60,60]);

% Separate neural data into contexts 
[context_data.dff,stim_trials_context,ctrl_trials_context] = organize_2context(sound_data.active.dff_st,sound_data.passive.dff_st);
[stim_info_combined,dff_st_combined] = combine_stim_info_dff_st(sound_context_data.active, sound_context_data.passive, sound_data.active.dff_st,sound_data.passive.dff_st);

[context_data.deconv,~,~] = organize_2context(sound_data.active.deconv_st_interp,sound_data.passive.deconv_st_interp);
[~,deconv_st_combined] = combine_stim_info_dff_st(sound_context_data.active, sound_context_data.passive, sound_data.active.deconv_st_interp,sound_data.passive.deconv_st_interp);

%2) POOL AND ALIGN VELOCITY TO SOUND!
mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound(speed_params.chosen_mice,info.mouse_date,info.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info_combined); %using ctrl and sound only trials
% balance sounds into left and right ('_all' includes all left and right unbalanced)- make sure to use in the context of opto trials!!
% [sound_trials_contexts,left_sounds_balanced,right_sounds_balanced,left_sounds_all,right_sounds_all]  = find_sound_trials_using_sounds(sound_left_trials_context,sound_right_trials_context);
[~, ~, ~, ~, ~, ~, left_stim_all, left_ctrl_all,  right_stim_all, right_ctrl_all] = find_sound_trials(info,stim_trials_context,ctrl_trials_context);
%% 3) Make plots of average speed across contexts
speed_params.trials_to_use =  {left_ctrl_all;right_ctrl_all};
save_dir = ['W:/Connie/results/Bassi2025/fig3/running_updated/avg_traces'];%['V:\Connie\results\opto_sound_2025\context\running_updated\avg_traces';]; %'V:\Connie\results\opto_2025\context\running_updated\avg_traces';
speed_params.specified_frames = speed_params.stim_frame; %whichever frames to take average off (to write numbers down on paper)

%calculate deltas and means for aligned velocity/speed
[deltaLeft,deltaRight,avg_speed_axis_data,speeds_mean_sem,speeds_mean_sem_specified_frames,general_stats] = process_aligned_vel_all_axis([1:25], mouse_vel_aligned_sounds, speed_params.trials_to_use, speed_params);
save(fullfile(save_dir,'stats_avg_trace_speed_acrosscontext_60-60_abs_1.mat'),'general_stats');
% plot cdf of changes for function_params.frames_before_stim function_params.frames_after_stim across contexts// takes rank sum comparisons (comparison across all trials from one context to next)
delta_speeds_p_vals = cdf_speed_delta_across_contexts(deltaLeft,deltaRight,speed_params,save_dir);

%plot cdf of averaged running speeds across contexts// takes sign rank comparisons (comparison across datasets from one context to next)
general_stats.speed_cdf = cdf_speed_avg_across_contexts(avg_speed_axis_data, speed_params,save_dir);
%plot average trace of runnning speeds across contexts
speed_params.xlabel = 'Time from 1st sound (s)';
plot_speed_avg_trace_across_contexts(speeds_mean_sem, speed_params,save_dir);

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
%% 4) MAKE PLOTS OF SPEED VS NEURAL CHANGES
%set neural parameters
speed_params.neural_abs = 1; %take the absolute value of neural change or not
speed_params.chosen_cells = 'sig'; % 'all', 'sig', 'som', 'pv', 'pyr'%if all uses all else will use sig mod cells from sounds
speed_params.neural_type = 'dff';

vel_types_id = {'roll','roll','pitch','pitch'};
contexts_id = [1,2,1,2];
for contexts = 1
    speed_params.vel_type = vel_types_id{contexts};%'roll'; %'pitch'
    speed_params.save_run_directory = [];%['V:/Connie/results/opto_2025/context/running_updated/velocity_vs_sound_' speed_params.neural_type];
%     close all %close all plots 
    speed_params.context = contexts_id(contexts); %1 = active, 2 = passive, 3 spont (no sound so uses all trials), 'all' will use all available trials!
    [mouse_trial_stats, trial_indices_right_all, trial_indices_left_all] = velocity_vs_neural_changes_contexts_acrossmice([1:25],info.mouse_date,info.serverid, mouse_vel_aligned_sounds,dff_st_combined,speed_params.frames_before_stim,speed_params.frames_after_stim,speed_params.stim_frame,speed_params.save_run_directory,speed_params.trials_to_use, speed_params);
end

%% BONUS! SHOW THAT PHOTOSTIM DOESN'T AFFECT SPEED 
speed_params = get_speed_params(1); 
speed_params.trials_to_use = {left_stim_all;right_stim_all};

vel_types_id = {'roll','pitch','both'};
contexts_id = [1,1,1];
for contexts = 1%:length(vel_types_id)
    speed_params.vel_type = vel_types_id{contexts};%'roll'; %'pitch'
    speed_params.save_run_directory = [];%['V:/Connie/results/opto_2025/context/running_updated/velocity_vs_sound_' speed_params.neural_type];
%     close all %close all plots 
    speed_params.context = contexts_id(contexts); %1 = active, 2 = passive, 3 spont (no sound so uses all trials), 'all' will use all available trials!
    [mouse_trial_stats, trial_indices_right_all, trial_indices_left_all] = velocity_vs_neural_changes_contexts_acrossmice([1:24],info.mouse_date,info.serverid, mouse_vel_aligned_sounds,dff_st_combined,speed_params.frames_before_stim,speed_params.frames_after_stim,speed_params.stim_frame,speed_params.save_run_directory,speed_params.trials_to_use, speed_params);
end
