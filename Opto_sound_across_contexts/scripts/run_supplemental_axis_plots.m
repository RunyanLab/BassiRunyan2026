% Code to make figures related to S9
save_dir = [];

celltype = 4; %4 = all
%plot sound and stim axis
plot_proj_meansplits_traces([1:24],axis_results.proj_norm_ctrl, 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from sound onset (s)');
plot_proj_meansplits_traces([1:24],axis_results.proj_norm, 'stim',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stim onset (s)');

frames_to_avg = 50:59;
bin_edges = [-2:0.4:2];%
hist_stats =  histogram_axis_across_contexts_splits([1:24],axis_results.proj_norm_ctrl, 'context',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

%axis stability across folds
plot_mean_axis_stability_across_splits(axis_results.weights,celltype,save_dir);
%% comparison across cell types- to define engagement axis
celltype_of_predicted_var = 4;
frame_range_pre= 50:59;
frame_range_post = 63:93;
lm_sound_celltypes = {}; lm_stim_celltypes = {};
for celltype = 1:3 %celltype of variable used to make predictions
    if ~isempty(save_dir)
        save_dir_celltype = strcat(save_dir,upper(plot_info.celltype_names{celltype}),'_engagement');
    else
        save_dir_celltype = [];
    end
    
    [lm_sound,tbl_sound,~,~,context_all_sound,corr_mean, ~, ~] = ...
    linear_regression_corr_model(axis_results.proj_norm_ctrl, 'Sound',[celltype_of_predicted_var,celltype],frame_range_pre,frame_range_post,[1:2]);
    %stim(predicted) vs engagement axis
    [lm_stim,tbl_stim,~,~,context_all_stim,~, ~,~] = ...
        linear_regression_corr_model(axis_results.proj_norm, 'Stim',[celltype_of_predicted_var,celltype],frame_range_pre,frame_range_post,[1:2]);
    %save across celltypes
    lm_sound_celltypes{celltype} = lm_sound;
    lm_stim_celltypes{celltype} = lm_stim;
    %make plots across celltypes
    plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir_celltype,'Engagement');
    plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir_celltype,'Engagement');

end

bar_plot_coefficients({lm_sound_celltypes{2};lm_stim_celltypes{2}}, {lm_sound_celltypes{3};lm_stim_celltypes{3}}, save_dir, plot_info.colors_celltypes(2:3,:), "Slope",{'Sound','Photostim'},'SOMPV');
bar_plot_coefficients({lm_sound_celltypes{1};lm_stim_celltypes{1}},{lm_sound_celltypes{2};lm_stim_celltypes{2}}, {lm_sound_celltypes{3};lm_stim_celltypes{3}}, save_dir, plot_info.colors_celltypes(1:3,:), "Slope",{'Sound','Photostim'},'PyrSOMPV');
