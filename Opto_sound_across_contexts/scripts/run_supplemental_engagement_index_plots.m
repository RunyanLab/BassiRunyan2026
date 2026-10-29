%% Engagement Index Plots
% 1) load data
% from main data
load('all_celltypes.mat'); load('sound.mat');load('opto.mat');load('plot_info')
%from supplemental data
load('engagement.mat'); 
params = experiment_config(); 

contexts_to_compare = [1]; 
overlap_labels = {'Act - Pass'}; 
mod_params.mod_threshold = .1;% 
mod_params.chosen_mice = [1:24];
mod_params.min_cells = 0;
savepath = [];

params.info.chosen_mice = mod_params.chosen_mice;
plot_info.y_lims = [-.4, .4];
plot_info.behavioral_contexts = {'Engagement Index'}; %decide which contexts to plot
plot_info.type = 'engagement'; %make lines gray instead of yellow

[engagement_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], engagement.mod', engagement.sig_mod_boot_thr, all_celltypes,plot_info.celltype_names);
%% cell type comparisons
%neuron-level
[stats] = mod_index_violin_across_celltypes(savepath,engagement_mod_all,{''},plot_info.colors_celltypes  ,2,celltypes_ids,[1:24],[-1,1]);

%datasets (scatter error bar plot and heatmap)
%%%%%% sig cells (celltypes) %%%%%
plot_info.y_lim_ratio = 2;
params.plot_info = plot_info;
mod_index_stats_datasets_all = generate_engagement_index_plots_datasets([1:24], engagement.mod', engagement.sig_mod_boot_thr, all_celltypes, params, savepath , celltypes_ids,plot_info.y_lims);

% %%%%%% all cells (celltypes) %%%%%%%%
% %plot all neurons including not engaged ones
% plot_info.y_lim_ratio = 2;
% params.plot_info = plot_info;
% mod_index_stats_datasets_all = generate_engagement_index_plots_datasets([1:24], engagement.mod', [], all_celltypes, params, savepath , celltypes_ids,plot_info.y_lims);

%% functional comparisons! %%%%%%%%
plot_info = plotting_config(); %plotting params
plot_info.y_lims = [-.4, .4];
plot_info.behavioral_contexts = {'Engagement Index'}; %decide which contexts to plot
plot_info.type = 'engagement'; %make lines gray instead of yellow
plot_info.y_lim_ratio = .8;
params.plot_info = plot_info;
% sig cells (including unmodulated)
[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);
params.plot_info = plot_info;
params.info.chosen_mice = [1:24]; %because last dataset is control and should not be considered with photostim
mod_pooled_index_stats_datasets = generate_engagement_index_plots_datasets(params.info.chosen_mice, engagement.mod',  engagement.sig_mod_boot_thr, pooled_cell_types, params, savepath, celltypes_ids,plot_info.y_lims);

% sig cells (not including unmodulated)
%dataset plots
[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both'},[1:24],plot_info, 1);
params.plot_info = plot_info;
params.info.chosen_mice = [1:24]; %because last dataset is control and should not be considered with photostim
mod_pooled_index_stats_datasets = generate_engagement_index_plots_datasets(params.info.chosen_mice, engagement.mod',  engagement.sig_mod_boot_thr, pooled_cell_types, params, savepath, celltypes_ids,plot_info.y_lims);
%neuron-level violin
[engagement_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], engagement.mod', engagement.sig_mod_boot_thr, pooled_cell_types,{'Sound', 'Photostim', 'S&P'});
[stats] = mod_index_violin_across_celltypes(savepath,engagement_mod_all,{''},plot_info.colors_celltypes  ,2,celltypes_ids,[1:24],[-1,1]);

% plot fraction + and - modulated per functional group
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both'},[1:24],plot_info, 1); %,'unmodulated'
%separate by positive and negative modulation
param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
mod_params.chosen_mice = 1:24;
%get percent signficantly engaged neurons per functional type
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'engagement';
        %get the significant neurons (positive, negative, both);
        [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params_plot, engagement.mod', engagement.sig_mod_boot'); %using mod_indexm2 because using prepost instead of ctrl for opto
        percent_cells_signed{i} = calculate_sig_celltype_percentages(current_sig_cells(1:24), pooled_cell_types, []);
end
% bar plot of percent engaged neurons
plot_info.functional_names = {{'Sound';'modulated'},{'Photostim';'modulated'},{'S & P';'modulated'}};%,'Unmodulated'}
[~,percent_bar_stats] = bar_plot_percent(percent_cells_signed{1},percent_cells_signed{2}, savepath,plot_info.functional_names,plot_info.functional_colors,{'Positive','Negative'});

%% REDO PLOTS BUT NOW SEPARATE INTO + AND - SOUND MODULATED NEURONS!
% separate out + and - sound neurons
mod_params.chosen_mice = 1:24;
mod_params.mod_threshold = 0.1;
%separate by positive and negative modulation
param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
%get percent signficantly engaged neurons per functional type
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'sounds';
        [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params_plot, sound.mod, sound.sig_mod_boot);
        sig_cells_sounds{i} = get_significant_neurons(current_sig_cells, sound.mod, 'union'); %union of active and passive

        %below to do intesect (must be significant + or - in both contexts)
%         [sig_cells, ~] = intersect_sig_cells(current_sig_cells(:,1)', current_sig_cells(:,2)', sound.mod);
%         sig_cells_sounds{i} = sig_cells;

end

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:24,:), {'sound','sound_neg','opto','both','unmodulated'},[1:24],plot_info, 1,sig_cells_sounds{2});

params.plot_info = plot_info;
mod_pooled_index_stats_datasets = generate_engagement_index_plots_datasets(params.info.chosen_mice, engagement.mod',  engagement.sig_mod_boot_thr, pooled_cell_types, params, savepath, celltypes_ids,plot_info.y_lims);
%neuron-level violin
[engagement_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], engagement.mod', engagement.sig_mod_boot_thr, pooled_cell_types,{'Sound Pos.', 'Sound Neg.', 'Photostim', 'S&P','Unmod.'});
[stats] = mod_index_violin_across_celltypes(savepath,engagement_mod_all,{''},plot_info.colors_celltypes  ,2,celltypes_ids,[1:24],[-1,1]);

% plot fraction + and - modulated per functional group
%separate by positive and negative modulation
param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
mod_params.chosen_mice = 1:24;
%get percent signficantly engaged neurons per functional type
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'engagement';
        %get the significant neurons (positive, negative, both);
        [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params_plot, engagement.mod', engagement.sig_mod_boot'); %using mod_indexm2 because using prepost instead of ctrl for opto
        percent_cells_signed{i} = calculate_sig_celltype_percentages(current_sig_cells(1:24), pooled_cell_types, []);
end
% bar plot of percent engaged neurons
plot_info.functional_names = {{'Sound Pos.';'modulated'},{'Sound Neg.';'modulated'},{'Photostim';'modulated'},{'S & P';'modulated'},'Unmodulated'};%,'Unmodulated'}
[~,percent_bar_stats] = bar_plot_percent(percent_cells_signed{1},percent_cells_signed{2}, savepath,plot_info.functional_names,plot_info.functional_colors,{'Positive','Negative'});

% %%%%stats
% S_mod_celltypes = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\mod_index_stats_datasets.mat').mod_index_stats_datasets);
% S_mod_celltypes_all_datasets = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\all\mod_index_contexts_distribution_stats.mat').stats);
% S_mod_celltypes_all = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\mod_index_cdf_acrosscelltypes_all.mat').all_stats);
% S_mod_celltypes_sig = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\mod_index_cdf_acrosscelltypes_sig.mat').all_stats);
% 
% S_mod_functional = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\functional_pools\mod_pooled_index_stats_datasets.mat').mod_pooled_index_stats_datasets);
% S_mod_functional_all = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\functional_pools\mod_index_cdf_acrosscelltypes_all.mat').all_stats);
% S_mod_functional_sig = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\functional_pools\mod_index_cdf_acrosscelltypes_sig.mat').all_stats);
% percent_mod_functional = unwrap_cells_in_struct(load('W:\Connie\results\Bassi2025\fig3\mod\pre_engagement\simple\functional_pools\bar_percentsSoundPhotostimS & P_all_stats.mat').all_stats);
% 
% table_1 = struct2table_recursive(S_mod_celltypes,'celltypes',{'bootstat'});
% table_15 = struct2table_recursive(S_mod_celltypes_all_datasets,'celltypes_all',{'bootstat'});
% table_2 = struct2table_recursive(S_mod_functional,'functional',{'bootstat'});
% table_3 = struct2table_recursive(S_mod_celltypes_all,'celltypes_all',{'bootstat','values'});
% table_4 = struct2table_recursive(S_mod_celltypes_sig,'celltypes_sig',{'bootstat','values'});
% table_5 = struct2table_recursive(S_mod_functional_all,'functional_all',{'bootstat','values'});
% table_6 = struct2table_recursive(S_mod_functional_sig,'functional_sig',{'bootstat','values'});
% table_7 = struct2table_recursive(percent_mod_functional,'functional_sig_percent',{'bootstat','values'});
% 
% 
% table_fig4_engagement = [table_1;table_15; table_2;table_3; table_4;table_5; table_6;table_7];
% save(fullfile(savepath, strcat('table_fig4_engagement.mat')), 'table_fig4_engagement');
% writetable(table_fig4_engagement, fullfile(savepath, strcat('table_fig4_engagement.csv')));
% % 