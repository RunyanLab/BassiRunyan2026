function plot_final_svm_traces_boxplots(version,event_type,do_passive,savepath,stim_ctrl_label,varargin)

if nargin > 5
    info = varargin{1};
else
    load('V:\Connie\results\opto_2024\context\data_info\info.mat');
end
info.task_event_type = event_type;
%code below to find these numbers although should be the same each time!
[current_mice,onset_id, active_events, passive_events,task_event_type] = default_data_info(info.task_event_type);
info.task_event_type = task_event_type;
plot_info = default_plot_info([]);

do_passive = do_passive;
if do_passive == 0
    acc_passive = [];
    shuff_acc_passive = [];
    beta_passive = [];
end
% 1) load data
version = version;
info.chosen_mice = current_mice;
% 'W:\Connie\results\Bassi2025\fig2\SVM_1\opto_ctrl'
savepath = savepath; %['W:\Connie\results\Bassi2025\fig2\SVM_1\full_population\' info.task_event_type '\']; %['V:\Connie\results\SVM_1_wtop\active_passive\' info.task_event_type '\'];%['V:\Connie\results\SVM_1\' info.task_event_type '\'];
[svm_mat, svm_mat2,svm_mat_pass, svm_mat_pass_ctrl,~, bins_to_include, event_onsets, mdl_param,  ~, ~,  ~, ~,  ~, ~] = wrapper_load_process_svm(current_mice, do_passive, info, active_events, 0, savepath,version, plot_info);

%2) plot all datasets together
if strcmp(version,'full') || strcmp(version,'nmatch') && do_passive == 0
    save_string = info.task_event_type;
    wrapper_plot_svm_acc_trace_all_datasets(svm_mat, mdl_param, save_string, savepath, [.44,.85],svm_mat2,event_onsets);
    
    % Boxplot of mean across datasets
    celltype_peak_comparison = 1; %which celltype max peak location to use (1 = pyr, 2 = som, 3 = pv, 4 = all, 5 = top pyr)
    wrapper_plot_accuracy_boxplots(svm_mat, svm_mat2,event_onsets, mdl_param, savepath, event_onsets(onset_id),bins_to_include,celltype_peak_comparison, [.45,.90]);
    wrapper_plot_svm_acc_trace_all_datasets(svm_mat, mdl_param, save_string, savepath, [.44,.85],svm_mat2,event_onsets);
elseif strcmp(version,'nmatch') && do_passive == 1
    celltypes_to_comp = [4]; 
    celltype_peak_comparison = 1;
    save_string = info.task_event_type;
    acc_peaks_stats = wrapper_plot_svm_acc_trace_and_boxplots_actpass(svm_mat, mdl_param, [save_string '_active_passive'],savepath, [.45,.85],svm_mat2,event_onsets, celltypes_to_comp,celltype_peak_comparison);

elseif strcmp(version,'stimctrl')
    save_string = info.task_event_type;
    wrapper_plot_svm_acc_trace_all_datasets(svm_mat, mdl_param, save_string, savepath, [.44,.85],svm_mat2,event_onsets);
    
    % Boxplot of mean across datasets
    celltypes_to_comp = [4,5]; %(1 = pyr, 2 = som, 3 = pv, 4 = all, 5 = top pyr)
    celltype_peak_comparison = 1; %[concatenated 1,concatenated 2,concatenated 1 passive,concatenated 2 passive];
    acc_peaks_stats = wrapper_plot_svm_acc_trace_and_boxplots_actpass(svm_mat, mdl_param, [save_string 'stimctrl_act'],savepath, [.45,.85],svm_mat2,event_onsets, celltypes_to_comp,celltype_peak_comparison, stim_ctrl_label);
    acc_peaks_stats = wrapper_plot_svm_acc_trace_and_boxplots_actpass(svm_mat_pass, mdl_param, [save_string 'stimctrl_pass'],savepath, [.45,.85],svm_mat_pass_ctrl,event_onsets, celltypes_to_comp,celltype_peak_comparison, stim_ctrl_label);
%     acc_peaks_stats = wrapper_plot_svm_acc_trace_and_boxplots_actpass(svm_mat, mdl_param, [save_string 'actpass_stim'],savepath, [.45,.85],svm_mat_pass,event_onsets, celltypes_to_comp,celltype_peak_comparison);
%     acc_peaks_stats = wrapper_plot_svm_acc_trace_and_boxplots_actpass(svm_mat2, mdl_param, [save_string 'actpass_ctrl'],savepath, [.45,.85],svm_mat_pass_ctrl,event_onsets, celltypes_to_comp,celltype_peak_comparison,{'Active Ctrl','Passive Ctrl'});

end

% % %% PLOT BETA WEIGHTS
% % load('V:\Connie\results\opto_2024\context\data_info\all_celltypes.mat');
% % all_celltypes_updated = all_celltypes(info.chosen_mice);
% % info.event_onsets = event_onsets;
% % 
% % [beta_mat,beta_mat_pass] = wrapper_mean_betas(info,beta_active,beta_passive); %mean across iterations
% % 
% % %
% % bin_id = event_onsets(onset_id); %time when to get betas from
% % wrapper_plot_betas_distributions(info,bin_id, beta_mat, all_celltypes_updated,  mdl_param, onset_id, [],[]);
% % 
% % % PLOT WEIGHT EVOLUTION OVER TIME
% % info.savestr = 'betas';
% % plot_weights_over_time([1:bins_to_include], event_onsets(onset_id), beta_mat,all_celltypes_updated,event_onsets,mdl_param.data_type,info,[1:3],mdl_param,savepath);
% % 
% % if do_passive == 1
% %     wrapper_plot_betas_distributions(info,bin_id, beta_mat_pass, all_celltypes_updated,  mdl_param, onset_id, [],[]);
% % 
% %     % PLOT WEIGHT EVOLUTION OVER TIME
% %     info.savestr = 'betas';
% %     plot_weights_over_time([1:bins_to_include], event_onsets(onset_id), beta_mat_pass,all_celltypes_updated,event_onsets,mdl_param.data_type,info,[1:3],mdl_param,[savepath '/passive']);
% % 
% % end

