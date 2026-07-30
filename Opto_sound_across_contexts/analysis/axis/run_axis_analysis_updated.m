load('V:\Connie\results\opto_sound_2025\context\data_info\all_celltypes.mat');
load('V:\Connie\results\opto_sound_2025\context\data_info\context_data.mat');
plot_info = plotting_config(); %plotting params

keep context_data all_celltypes plot_info
%% define axis
% [proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm] = find_axis_updated(context_data.dff, [1:24], all_celltypes,[]); %,{50:59,63:73}

split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1:4; choose_params.chosen_datasets = 1:24;
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative,sound_concat,stim_concat] = ...
    find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,[],split_params); %,{50:59,63:73}

save_dir = 'W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\';%'V:\Connie\results\opto_sound_2025\context\axis_lme_plots_updated\dff';
save_dir2 = 'W:\Connie\results\Bassi2025\fig5\updated_4cv_combined_eng\';%'V:\Connie\results\opto_sound_2025\context\axis_lme_plots_updated\dff';

%% plot mean projection traces across datasets (finds means across splits first
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

%axis stability across folds
plot_mean_axis_stability_across_splits(weights,celltype,save_dir);
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

% % %sound(predicted) vs stim
[lm_sound_stim,tbl_sound_stim,proj_all_sound_stim,engagement_proj_all_sound_stim,context_all_sound_stim,corr_mean_sound_stim, corr_all_sound_stim,corr_stats_sound_stim] = ...
    linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[1],'Stim');

[lm_sound_stim_pass,tbl_sound_stim_pass,~,~,context_all_sound_stim_pass,corr_mean_sound_stim_pass, corr_all_sound_stim_pass,corr_stats_sound_stim_pass] = ...
    linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[2],'Stim');

%% scatter plots of trials and linear regression lines
% plot_linear_regression_lines(lme_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement',[corr_mean,corr_stats.p]);
plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');
plot_linear_regression_lines(lm_sound_stim,tbl_sound_stim,context_all_sound_stim,'Sound Projection',save_dir2,'Stim',[],[-2,4],[-4,4],'topright');
plot_linear_regression_lines(lm_sound_stim_pass,tbl_sound_stim_pass,context_all_sound_stim_pass,'Sound Projection',save_dir2,'Stim',[],[-2,4],[-4,4]);

%within context comparisons for engagement vs stim/sound
for ctx = 1:2
    [lm_sound,tbl_sound,~,~,context_all_sound,~, ~, ~] = ...
        linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[ctx]);
    [lm_stim,tbl_stim,~,~,context_all_stim,~, ~,~] = ...
        linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[ctx]);
    plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',strcat(save_dir,plot_info.behavioral_contexts{ctx}),'Engagement',[],[-4,4],[-4,4]);
    plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',strcat(save_dir,plot_info.behavioral_contexts{ctx}),'Engagement',[],[-4,4],[-4,4]);
end

plot_corr_matrix_projections(proj_norm,celltype,frame_range_pre,frame_range_post,save_dir);%concatenates across contexts
plot_scatter_pred_vs_obs(lm_sound,'Sound',save_dir);
plot_scatter_pred_vs_obs(lm_stim,'Stim',save_dir);
% % %% compare to lme!
% % [~,~,~,~,context_all_sound,~, ~,~,lme_sound,tbl_sound_lme] = ...
% %     linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
% % %stim(predicted) vs engagement axis
% % [~,~,~,~,context_all_stim,~, ~,~,lme_stim,tbl_stim_lme] = ...
% %     linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);
% % 
% % % % %sound(predicted) vs stim
% % [~,~,~,~,context_all_sound_stim,~, ~,~,lme_sound_stim,tbl_sound_stim_lme] = ...
% %     linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[1],'Stim');
% % 
% % [~,~,~,~,context_all_sound_stim_pass,~, ~,~,lme_sound_stim_pass,tbl_sound_stim_pass_lme] = ...
% %     linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[2],'Stim');
% % 
% % plot_linear_regression_lines(lme_sound,tbl_sound_lme,context_all_sound,'Sound Projection',strcat(save_dir,'lme'),'Engagement');
% % plot_linear_regression_lines(lme_stim,tbl_stim_lme,context_all_stim,'Stim Projection',strcat(save_dir,'lme'),'Engagement');
% % plot_linear_regression_lines(lme_sound_stim,tbl_sound_stim_lme,context_all_sound_stim,'Sound Projection',strcat(save_dir2,'lme'),'Stim',[],[-2,4],[-4,4],'topright');
% % plot_linear_regression_lines(lme_sound_stim_pass,tbl_sound_stim_pass_lme,context_all_sound_stim_pass,'Sound Projection',strcat(save_dir2,'lme'),'Stim',[],[-2,4],[-4,4]);
% % 
% % for ctx = 1:2
% %     [~,~,~,~,context_all_sound,~, ~,~,lme_sound,tbl_sound_lme] = ...
% %         linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[ctx]);
% %     [~,~,~,~,context_all_stim,~, ~,~,lme_stim,tbl_stim_lme] = ...
% %         linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[ctx]);
% %     plot_linear_regression_lines(lme_sound,tbl_sound_lme,context_all_sound,'Sound Projection',strcat(save_dir,'lme\',plot_info.behavioral_contexts{ctx}),'Engagement',[],[-4,4],[-4,4]);
% %     plot_linear_regression_lines(lme_stim,tbl_stim_lme,context_all_stim,'Stim Projection',strcat(save_dir,'lme\',plot_info.behavioral_contexts{ctx}),'Engagement',[],[-4,4],[-4,4]);
% % end
%% performance vs engagment!
nDatasets = 24;
for d = 1:nDatasets
    percent_correct_all{d} = horzcat(percent_correct_concat{:,d});   % concatenate across splits
    %find mean across neurons
    concat_activity{d} = vertcat(act{:,d,4}); %trials x neurons
    mean_act = mean(concat_activity{d}(:,50:59),2);
    activity_all{d} = mean_act';

    %do the same for the engagement axis
    concat_engagement{d} = vertcat(engagement_concat{:,d,4}); %trials x neurons
    mean_engagement = mean(concat_engagement{d}(:,50:59),2);
    engagement_all{d} = mean_engagement';
    test_trials_all{d} = horzcat(test_trials{:,d}); 
    test_trials_all_relative{d} = horzcat(test_trials_relative{:,d}); 

    % Control
    concat_sound = vertcat(sound_concat{:,d,4});
    sound_mat = vertcat(concat_sound);      % trials x frames
    sound_all{d} = mean(sound_mat(:,63:93),2)';

    % Stim
    concat_stim = vertcat(stim_concat{:,d,4});
    stim_mat = vertcat(concat_stim);         % trials x frames
    stim_all{d} = mean(stim_mat(:,63:93),2)';
end
% plot_performance_vs_engagement_axis_updated(percent_correct_all,engagement_all,[20,5],save_dir,[0,2]);
plot_performance_vs_engagement_axis_updated(percent_correct_all,engagement_all,[20,5],save_dir,[0,2]);

plot_performance_vs_activity(percent_correct_all,activity_all,[20,5],[save_dir '/performance_plots/activity/'],[-1,1.5]);

%save for pupil comparisons
engagement_proj_all = engagement_all;
save(fullfile('W:\Connie\Analysis\engagement\','engagement_proj_all.mat'),'engagement_proj_all');
save(fullfile('W:\Connie\Analysis\engagement\','test_trials_all.mat'),'test_trials_all');
selected_frames = save_alignment_frames_across_contexts(50:59, test_trials_all,'W:\Connie\Analysis\engagement\');



plot_performance_vs_engagement_axis_updated(percent_correct_all,stim_all,[20,5],'W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\performance_plots\stim',[-2,2],'save','Stim');

plot_performance_vs_engagement_axis_updated(percent_correct_all,sound_all,[20,5],'W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\performance_plots\sound',[-2,2],'save','Sound');

%% plot weights across cell types
colors_medium = [0.37 0.75 0.49 %green
                0.17 0.35 0.8  %blue
                0.82 0.04 0.04];
edges_values_weights = [-.1,.1];
num_bins_weights = 20;
[weight_all_celltype,weight_ct_stats] = histogram_weights_celltypes_vs_axis_splits([1:24],weights, 'Context' ,all_celltypes, edges_values_weights,num_bins_weights,colors_medium,save_dir);

%% save stats into single table
load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\stats_lm_contexts1  2Stim ProjectionEngagement.mat');
lm_stats2 = load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\stats_lm_contexts1  2Sound ProjectionEngagement.mat').lm_stats;
load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\performance_plots\performance_vs_engagement_stats.mat');
Sweightsabs = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\errorbar_weights_celltypes_vs_axis_Context_stats_n24_edges_-0.1         0.1.mat').errorbar_weight_datasets_ct_stats);  
Sweight_nosabs = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\errorbar_noabs_weights_celltypes_vs_axis_Context_stats_n24_edges_-0.1         0.1').errorbar_weight_datasets_ct_stats_noabs);  
Scontext = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\hist_splits_axis_contextstats_n24.mat').hist_stats);
Sstim = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\hist_splits_axis_Stimstats_n24.mat').hist_stats);
Ssound = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\hist_splits_axis_Soundstats_n24.mat').hist_stats);
Sbar = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\stats_bar_coefficients_SOMPV_vs_engagement_axis.mat').bar_stats);
Sstability = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\stats_mean_axis_stability_celltype4.mat').stats);

% S = unwrap_cells_in_struct(mod_index_stats_datasets);
% S2 = unwrap_cells_in_struct(mod_index_stats);
table_1 = struct2table_recursive(lm_stats,'stim_eng',{'bootstat'});
table_2 = struct2table_recursive(lm_stats2,'sound_eng',{'bootstat'});
table_3 = struct2table_recursive(performance_vs_engagement_stats,'performance_vs_eng',{'bootstat'});
table_4 = struct2table_recursive(Sweightsabs,'weights',{'bootstat'});
table_5 = struct2table_recursive(Sweight_nosabs,'weights_noabs',{'bootstat'});
table_6 = struct2table_recursive(Scontext,'hist_context',{'bootstat'});
table_7 = struct2table_recursive(Sstim,'hist_stim',{'bootstat'});
table_8 = struct2table_recursive(Ssound,'hist_sound',{'bootstat'});
table_9 = struct2table_recursive(Sbar,'SOMPV',{'bootstat'});
table_10 = struct2table_recursive(Sbar,'stability_axis_splits',{'bootstat'});


table_fig4 = [table_1; table_2;table_3; table_4;table_5;table_6;table_7;table_8;table_9;table_10];
save(fullfile(save_dir, strcat('table_fig4.mat')), 'table_fig4');
writetable(table_fig4, fullfile(save_dir, strcat('table_fig4.csv')));
%% using random splits (choose first one to show)
% model correlations across splits
celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[~,~,~,~,~,corr_mean, corr_all, corr_stats] = ...
    linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[~,~,~,~,~,corr_mean_stim, corr_all_stim, corr_stats_stim] = ...
    linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

% % %sound(predicted) vs stim
[~,~,~,~,~,corr_mean_sound_stim, corr_all_sound_stim, corr_stats_sound_stim] = ...
    linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[1],'Stim');

[~,~,~,~,~,corr_mean_sound_stim_pass, corr_all_sound_stim_pass, corr_stats_sound_stim_pass] = linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[2],'Stim');
%% comparison across cell types- to define engagement axis
celltype_of_predicted_var = 4;
lm_sound_celltypes = {}; lm_stim_celltypes = {};
for celltype = 1:3 %celltype of variable used to make predictions
    save_dir_celltype = strcat(save_dir,upper(plot_info.celltype_names{celltype}),'_engagement')
    
    [lm_sound,tbl_sound,~,~,context_all_sound,corr_mean, ~, ~] = ...
    linear_regression_corr_model(proj_norm_ctrl, 'Sound',[celltype_of_predicted_var,celltype],frame_range_pre,frame_range_post,[1:2]);
    %stim(predicted) vs engagement axis
    [lm_stim,tbl_stim,~,~,context_all_stim,~, ~,~] = ...
        linear_regression_corr_model(proj_norm, 'Stim',[celltype_of_predicted_var,celltype],frame_range_pre,frame_range_post,[1:2]);
    %save across celltypes
    lm_sound_celltypes{celltype} = lm_sound;
    lm_stim_celltypes{celltype} = lm_stim;
    %make plots across celltypes
    plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir_celltype,'Engagement');
    plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir_celltype,'Engagement');

end

bar_plot_coefficients({lm_sound_celltypes{2};lm_stim_celltypes{2}}, {lm_sound_celltypes{3};lm_stim_celltypes{3}}, save_dir, plot_info.colors_celltypes(2:3,:), "Slope",{'Sound','Photostim'},'SOMPV');
%% timecouse
time_to_test = [63:10:123];

celltype = 4;
% frame_range_pre= 50:59;
for times = 1:length(time_to_test)-1
    frames_to_test_post = time_to_test(times):time_to_test(times+1)-1
%     frame_to_test_post= 63:93;
    [lm_sound_stim,~,~,~,~,~, ~,~] = ...
        linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_to_test_post,frames_to_test_post,[1],'Stim');
    
    [lm_sound_stim_pass,~,~,~,~,~, ~,~] = ...
        linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_to_test_post,frames_to_test_post,[2],'Stim');

    save_dir3 = strcat(save_dir2, num2str(frames_to_test_post(1)),'to',num2str(frames_to_test_post(end)),'/');
%     plot_linear_regression_lines(lm_sound_stim,tbl_sound_stim,context_all_sound_stim,'Sound Projection',save_dir3,'Stim',[],[-2,4],[-4,4],'topright');
%     plot_linear_regression_lines(lm_sound_stim_pass,tbl_sound_stim_pass,context_all_sound_stim_pass,'Sound Projection',save_dir3,'Stim',[],[-2,4],[-4,4]);
    bar_plot_coefficients({lm_sound_stim}, {lm_sound_stim_pass}, save_dir3, [0,0,0;0.5,0.5,0.5], "Slope",{'Active','Passive'},'act_pass',[-.2,.2]);

end
%% from random have to choose example split
celltype = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
example_split = 1;

%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound,context_all_sound] = ...
    linear_regression_corr_model(proj_norm_ctrl(example_split,:,:,:), 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,context_all_stim,corr_mean_stim] = ...
    linear_regression_corr_model(proj_norm(example_split,:,:,:), 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

% % %sound(predicted) vs stim
[lm_sound_stim,tbl_sound_stim,proj_all_sound_stim,engagement_proj_all_sound_stim,context_all_sound_stim] = ...
    linear_regression_corr_model(proj_norm(example_split,:,:,:),'Sound' ,celltype,frame_range_post,frame_range_post,[1],'Stim');

[lm_sound_stim_pass,tbl_sound_stim_pass,~,~,context_all_sound_stim_pass,corr_mean_sound_stim_pass] = linear_regression_corr_model(proj_norm(example_split,:,:,:),'Sound' ,celltype,frame_range_post,frame_range_post,[2],'Stim');

% scatter plots of trials and linear regression lines for example session
plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir);
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir);
plot_linear_regression_lines(lm_sound_stim,tbl_sound_stim,context_all_sound_stim,'Sound Projection',save_dir2,'Stim');
plot_linear_regression_lines(lm_sound_stim_pass,tbl_sound_stim_pass,context_all_sound_stim_pass,'Sound Projection',save_dir2,'Stim');

colors_medium = [0.37 0.75 0.49 %green
                0.17 0.35 0.8  %blue
                0.82 0.04 0.04];
edges_values_weights = [-.1,.1];
num_bins_weights = 20;
[weight_all_celltype,weight_ct_stats] = histogram_weights_celltypes_vs_axis_splits([1:24],weights, 'Context' ,all_celltypes, edges_values_weights,num_bins_weights,colors_medium,save_dir);
