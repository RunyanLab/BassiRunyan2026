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
split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1:4; choose_params.chosen_datasets = 1:24;
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative] = ...
    find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,[],split_params); %,{50:59,63:73}

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

%% compare to S2 or S3
sound_number = 3;
load(['W:\Connie\results\Bassi2025\fig3\multiple_sound_repeats\' num2str(sound_number) '\context_data.mat']);
updated_context_data = update_context_info(context_data);
load('W:\Connie\results\Bassi2025\data\all_celltypes.mat');

save_dir = ['W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\sound' num2str(sound_number) '\pitch_roll_lm'];

[~,~,~,proj_norm_soundrepeat,proj_norm_ctrl_soundrepeat, ~,~,~,~,~,~,~,~,~, ~,~,~] = ...
    find_axis_updated_specify_splits(updated_context_data.dff, choose_params, all_celltypes,[],split_params); %,{50:59,63:73}
%use original engagement axis
proj_out_sound = replace_proj_field(proj_norm_ctrl_soundrepeat, proj_norm_ctrl, 'context');
proj_out_stim = replace_proj_field(proj_norm_soundrepeat, proj_norm, 'context');

celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
plot_proj_meansplits_traces([1:24],proj_out_sound, 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from sound onset (s)');
plot_proj_meansplits_traces([1:24],proj_out_sound, 'context',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stimulus onset (s)');
plot_proj_meansplits_traces([1:24],proj_out_stim, 'stim',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stim onset (s)');


%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound, running_all_sound,context_all_sound,corr_mean, corr_all, corr_stats,lme_sound,tabl_sound_lme, lm_resid_sound, lme_resid_sound, tbl_resid_sound] = ...
    linear_regression_corr_model_movement(proj_out_sound ,{running_split_ctrl_pitch,running_split_ctrl_roll},{'Pitch','Roll'}, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);

%stim(predicted) vs engagement axis
% [lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,running_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim,lme_stim,tabl_stim_lme, lm_resid_stim, lme_resid_stim, tbl_resid_stim] = ...
%     linear_regression_corr_model_movement(proj_out_stim,{running_split_pitch,running_split_roll},{'Pitch','Roll'}, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

plot_residualized_regression_lines(lm_resid_sound,lm_resid_sound,tbl_resid_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
% plot_residualized_regression_lines(lm_resid_stim,lm_resid_stim,tbl_resid_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');


save_dir = ['W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\sound' num2str(sound_number)];

%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound,context_all_sound,corr_mean, corr_all, corr_stats] = ...
    linear_regression_corr_model(proj_out_sound, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
% %stim(predicted) vs engagement axis
% [lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim] = ...
%     linear_regression_corr_model(proj_out_stim, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);
plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
% plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');

%%
load('V:\Connie\results\opto_sound_2025\context\data_info\all_celltypes.mat');
load('V:\Connie\results\opto_sound_2025\context\data_info\context_data.mat');
plot_info = plotting_config(); %plotting params

% keep context_data all_celltypes plot_info

%%
speed_params.frames_before_event = 60; %in previous iterations these numbers just refered to the total number of frames aligned to (not what was averaged)
speed_params.frames_after_event = 60;
mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound([1:24],params.info.mouse_date,params.info.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info); %using ctrl and sound only trials
[mouse_vel_context,mouse_vel_context_roll,mouse_vel_context_pitch,mouse_acc_context,general_stats] = speed_cdf_across_contexts([],mouse_vel_aligned_sounds,plot_info,stim_trials_context,ctrl_trials_context,[1:24],[1:122]); %50:60

[running_split,running_split_ctrl] = reorganize_running_by_split(mouse_vel_context_pitch, axis_results);

%% define axis
% [proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm] = find_axis_updated(context_data.dff, [1:24], all_celltypes,[]); %,{50:59,63:73}

run_params.use_behavior_regression = true;
run_params.behavior_vars = {'pitch','roll'}; %{'speed'}; 
% options: {'speed'}, {'speed','accel'}, {'speed','accel','pitch','roll'}

run_params.behavior.speed = mouse_vel_context;
run_params.behavior.pitch = mouse_vel_context_pitch;
run_params.behavior.roll  = mouse_vel_context_roll;
run_params.avg_frames  = 1;

split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1:4; choose_params.chosen_datasets = 1:24;
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative] = ...
    find_axis_updated_specify_splits_regress_running(context_data.dff, choose_params, all_celltypes,[],split_params, {50:59,63:93},run_params); %,{50:59,63:73}

% save_dir = 'W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\';%'V:\Connie\results\opto_sound_2025\context\axis_lme_plots_updated\dff';

%% plot mean projection traces across datasets (finds means across splits first
save_dir = 'W:\Connie\results\Bassi2025\fig4\reviews\running_vs_axis\regressed_pitch_roll';

celltype = 4; %4 = all
plot_proj_meansplits_traces([1:24],proj_norm_ctrl, 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from sound onset (s)');
plot_proj_meansplits_traces([1:24],proj_norm_ctrl, 'context',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stimulus onset (s)');
plot_proj_meansplits_traces([1:24],proj_norm, 'stim',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stim onset (s)');

% plot_proj_mean_traces([1:24],squeeze(proj_ctrl(1,:,:,:)), 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 50:59;
bin_edges = [-2:0.4:2];%
hist_stats =  histogram_axis_across_contexts_splits([1:24],proj_norm_ctrl, 'context',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 63:93;
bin_edges = [-2:0.4:2];%
hist_stats =  histogram_axis_across_contexts_splits([1:24],proj_norm_ctrl, 'Sound',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 63:93;
bin_edges = [-1.5:0.4:2.5];%
hist_stats =  histogram_axis_across_contexts_splits([1:24],proj_norm, 'Stim',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);


%% model
celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound,context_all_sound,corr_mean, corr_all, corr_stats] = ...
    linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim] = ...
    linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

% scatter plots of trials and linear regression lines
% plot_linear_regression_lines(lme_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement',[corr_mean,corr_stats.p]);
plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');
