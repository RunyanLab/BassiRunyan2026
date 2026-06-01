[speed_params,speed_params_single] = get_speed_params(1); %control_or_opto
params = experiment_config(); 
load('V:\Connie\results\opto_sound_2025\context\data_info\stim_info.mat');
load('V:\Connie\results\opto_sound_2025\context\data_info\stim_trials_context.mat');
load('V:\Connie\results\opto_sound_2025\context\data_info\ctrl_trials_context.mat');
% load('V:\Connie\results\opto_sound_2025\context\data_info\all_celltypes.mat');
% load('V:\Connie\results\opto_sound_2025\context\data_info\context_data.mat');
% plot_info = plotting_config(); %plotting params
% 
% keep context_data all_celltypes plot_info
% % define axis
% % [proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm] = find_axis_updated(context_data.dff, [1:24], all_celltypes,[]); %,{50:59,63:73}
% 
% split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
% choose_params.chosen_celltypes = 1:4; choose_params.chosen_datasets = 1:24;
% [axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative] = ...
%     find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,[],split_params); %,{50:59,63:73}

%load axis data
%% Get aligned velocity
speed_params.frames_before_event = 60; %in previous iterations these numbers just refered to the total number of frames aligned to (not what was averaged)
speed_params.frames_after_event = 61;
mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound([1:24],params.info.mouse_date,params.info.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info); %using ctrl and sound only trials
[mouse_vel_context,mouse_vel_context_roll,mouse_vel_context_pitch,mouse_acc_context,general_stats] = speed_cdf_across_contexts([],mouse_vel_aligned_sounds,plot_info,stim_trials_context,ctrl_trials_context,[1:24],[1:122]); %50:60

[running_split,running_split_ctrl] = reorganize_running_by_split(mouse_vel_context_pitch, axis_results);

% use_abs = 1; %take the absolute value or not (needed for roll for example)
% %make nice cdf plots (code below combines stim and control trials!)
% avg_speed_axis_data = organize_speed_cdf_data( ...
%     mouse_vel_context, ...
%     mouse_acc_context, ...
%     mouse_vel_context_roll, ...
%     mouse_vel_context_pitch, ...
%     [1:length(mouse_vel_context)], ...
%     use_abs);
% 
% save_data_directory = 'W:\Connie\results\Bassi2025\fig3\running_updated';
% custom_bins.Pitch = 0:2:60;
% custom_bins.Roll = 0:2:40;
% custom_bins.Both = 20:2:60;
% custom_bins.Acceleration = 0:0.1:5;
% general_stats_speed = cdf_speed_avg_across_contexts(avg_speed_axis_data, speed_params,save_data_directory, 'movement_types',{'Pitch', 'Roll', 'Both', 'Acceleration'}, 'bin_struct', custom_bins);

%% compare axis linear models including running as a variable
celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound, running_all_sound,context_all_sound,corr_mean, corr_all, corr_stats,lme_sound,tabl_sound_lme, lm_resid_sound, lme_resid_sound, tbl_resid_sound] = ...
    linear_regression_corr_model_running(proj_norm_ctrl,running_split_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);

%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,running_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim,lme_stim,tabl_stim_lme, lm_resid_stim, lme_resid_stim, tbl_resid_stim] = ...
    linear_regression_corr_model_running(proj_norm,running_split, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

%% make plots
save_dir = 'W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\pitch_lm';
% [mdl_sound_resid, lme_sound_resid, figH] = plot_residualized_projection(tbl_resid_sound, 'SoundProj','TitleText', 'Sound response after removing running effects', 'YLabelText', 'Residualized sound projection');
plot_residualized_regression_lines(lm_resid_sound,lm_resid_sound,tbl_resid_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_residualized_regression_lines(lm_resid_stim,lm_resid_stim,tbl_resid_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');
% plot_linear_regression_lines_running(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');

%% include pitch and roll in the model together
[running_split_pitch,running_split_ctrl_pitch] = reorganize_running_by_split(mouse_vel_context_pitch, axis_results);
[running_split_roll,running_split_ctrl_roll] = reorganize_running_by_split(mouse_vel_context_roll, axis_results);

%% compare axis linear models including running as a variable
celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound, running_all_sound,context_all_sound,corr_mean, corr_all, corr_stats,lme_sound,tabl_sound_lme, lm_resid_sound, lme_resid_sound, tbl_resid_sound] = ...
    linear_regression_corr_model_movement(proj_norm_ctrl,{running_split_ctrl_pitch,running_split_ctrl_roll},{'Pitch','Roll'}, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);

%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,running_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim,lme_stim,tabl_stim_lme, lm_resid_stim, lme_resid_stim, tbl_resid_stim] = ...
    linear_regression_corr_model_movement(proj_norm,{running_split_pitch,running_split_roll},{'Pitch','Roll'}, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

save_dir = 'W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\pitch_roll_lm';
plot_residualized_regression_lines(lm_resid_sound,lm_resid_sound,tbl_resid_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_residualized_regression_lines(lm_resid_stim,lm_resid_stim,tbl_resid_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');

%% compare to S2/ or S3
load('W:\Connie\results\Bassi2025\fig3\multiple_sound_repeats\2\context_data.mat');
load('W:\Connie\results\Bassi2025\data\all_celltypes.mat');
[~,proj,proj_ctrl,proj_norm_soundrepeat,proj_norm_ctrl_soundrepeat, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative] = ...
    find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,[],split_params); %,{50:59,63:73}

celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound, running_all_sound,context_all_sound,corr_mean, corr_all, corr_stats,lme_sound,tabl_sound_lme, lm_resid_sound, lme_resid_sound, tbl_resid_sound] = ...
    linear_regression_corr_model_movement(proj_norm_ctrl_soundrepeat,{running_split_ctrl_pitch,running_split_ctrl_roll},{'Pitch','Roll'}, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);

%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,running_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim,lme_stim,tabl_stim_lme, lm_resid_stim, lme_resid_stim, tbl_resid_stim] = ...
    linear_regression_corr_model_movement(proj_norm_soundrepeat,{running_split_pitch,running_split_roll},{'Pitch','Roll'}, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

save_dir = 'W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\sound2\pitch_roll_lm';
plot_residualized_regression_lines(lm_resid_sound,lm_resid_sound,tbl_resid_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_residualized_regression_lines(lm_resid_stim,lm_resid_stim,tbl_resid_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');


