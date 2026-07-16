addpath(genpath('C:\Code\Github\BassiRunyan2025\Decoding_SVM'));


load('V:\Connie\results\opto_2024\context\data_info\info.mat');
info.task_event_type = 'outcome';
%code below to find these numbers although should be the same each time!
[current_mice,onset_id, active_events, passive_events] = default_data_info(info.task_event_type);

do_passive = 0;
if do_passive == 0
    acc_passive = [];
    shuff_acc_passive = [];
    beta_passive = [];
end
%% 1) load data
info.chosen_mice = current_mice;
[acc_active, shuff_acc_active, beta_active, acc_active_top, shuff_acc_active_top] = wrapper_load_all_svm_data(info, 'GLM_3nmf_pre', [info.task_event_type '_all'], [], '_1');
celltype_to_delete = 4; %all
[acc_active, shuff_acc_active] = remove_specific_celltype(acc_active, shuff_acc_active, celltype_to_delete);

info.chosen_mice = 2;
all_model_outputs = load_SVM_results(info,'GLM_3nmf_pre','sound_category','all_model_outputs','_1');
if do_passive == 1
    [acc_passive, shuff_acc_passive, beta_passive, acc_passive_top, shuff_acc_passive_top] = wrapper_load_all_svm_data(info, 'GLM_3nmf_passive', info.task_event_type, '_all', '_1')
    all_model_outputs = load_SVM_results(info,'GLM_3nmf_passive','sound_category','all_model_outputs');
    bins_to_include = 32;
else
    bins_to_include = 55;
end
info.chosen_mice = current_mice;
event_onsets = find(histcounts(active_events,all_model_outputs{1,1}{1}.binns+active_events(1)));%find(histcounts(all_model_outputs{1,1}{1}.event_onset,all_model_outputs{1,1}{1}.binns+mdl_param.event_onset(1)));

%% plot individual datasets and find means across shuffles
doplot = 0;

savepath = ['W:\Connie\results\Bassi2025\fig2\SVM_1\full_population\' info.task_event_type '\']; %['V:\Connie\results\SVM_1_wtop\active_passive\' info.task_event_type '\'];%['V:\Connie\results\SVM_1\' info.task_event_type '\'];
info.savepath = savepath;

[svm_mat, svm_mat2] = wrapper_plot_svm_acc_trace_individual_datasets(info, acc_active, shuff_acc_active, acc_passive, shuff_acc_passive, all_model_outputs, savepath, doplot, event_onsets);

%% plot all datasets together

mdl_param = all_model_outputs{1,1}{1};
save_string = info.task_event_type;

wrapper_plot_svm_acc_trace_all_datasets(svm_mat, mdl_param, save_string, savepath, [.45,.85],svm_mat2,event_onsets);
%% Boxplot of mean across datasets
celltype_peak_comparison = 1; %which celltype max peak location to use (1 = pyr, 2 = som, 3 = pv, 4 = all, 5 = top pyr)
wrapper_plot_accuracy_boxplots(svm_mat, svm_mat2,event_onsets, mdl_param, savepath, event_onsets(onset_id),bins_to_include,celltype_peak_comparison, [.45,.90]);

%% PLOT BETA WEIGHTS
load('V:\Connie\results\opto_2024\context\data_info\all_celltypes.mat');
all_celltypes_updated = all_celltypes(info.chosen_mice);
info.event_onsets = event_onsets;

[beta_mat,beta_mat_pass] = wrapper_mean_betas(info,beta_active,beta_passive); %mean across iterations

%
bin_id = event_onsets(onset_id); %time when to get betas from
wrapper_plot_betas_distributions(info,bin_id, beta_mat, all_celltypes_updated,  mdl_param, onset_id, [],[]);

% PLOT WEIGHT EVOLUTION OVER TIME
info.savestr = 'betas';
plot_weights_over_time([1:bins_to_include], event_onsets(onset_id), beta_mat,all_celltypes_updated,event_onsets,mdl_param.data_type,info,[1:3],mdl_param,savepath);

if do_passive == 1
    wrapper_plot_betas_distributions(info,bin_id, beta_mat_pass, all_celltypes_updated,  mdl_param, onset_id, [],[]);

    % PLOT WEIGHT EVOLUTION OVER TIME
    info.savestr = 'betas';
    plot_weights_over_time([1:bins_to_include], event_onsets(onset_id), beta_mat_pass,all_celltypes_updated,event_onsets,mdl_param.data_type,info,[1:3],mdl_param,[savepath '/passive']);

end

