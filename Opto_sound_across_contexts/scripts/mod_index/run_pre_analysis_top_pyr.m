% to address concerns related to the pre-stimulus activity in pyr neurons
cd('W:\Connie\results\Bassi2025\data')
load('context_data.mat');load('context_data_sounds.mat'); load('sound.mat'); load('opto.mat');load('avg_responses.mat'); load('axis_results.mat');load('all_celltypes.mat');load('plot_info.mat')

%% organize sound and top neurons
savepath_fig = ['W:\Connie\results\Bassi2025\fig3\reviews\top_pyr_neurons\'];

sound = get_top_informative_neurons(sound,'pyr');

updated_all_celltypes = {}; %delete other cell types for plotting purposes
top_neurons = {}; %top encoding (only pyr)
top_neurons_sig = {}; %top encoding (only pyr)
sound_neurons = {}; %sound responsive (could be multiple cell types)
sound_neurons_pyr = {}; %sound responsive (only pyr)
for d = 1:25
    updated_all_celltypes{d}.pyr_cells = all_celltypes{d}.pyr_cells;
    top_neurons{d}.pyr_cells = sound.sig_cells_top{1, d};
    top_neurons_sig{d} = sound.sig_cells_top{1, d};
    sound_neurons{d}.pyr_cells = sound.sig_cells{1, d};
    sound_neurons_pyr{d}.pyr_cells = intersect(sound.sig_cells{1, d},all_celltypes{d}.pyr_cells);

end

%% correlate pre vs post activity of sound responsive neurons
current_save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\pre_stim_pyr'];

%Sound responsive (many cell types)
%during sound only trials!!!
plot_info.colors_celltypes =[ 0.300000000000000	0.200000000000000	0.600000000000000]; %purple
[modl_fit_prepost_active,~,~,prepost_active] = scatter_index_sigcells_histogram_optional([], sound_neurons, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_post{:,1}}'], plot_info, current_save_dir, 'Active Pre Mean (ΔF\F)', 'Active Post Mean (ΔF\F)',0,1,[-0.05,1.8]);
[modl_fit_prepost_passive,~,~,prepost_passive] = scatter_index_sigcells_histogram_optional([], sound_neurons, [{avg_responses.avg_ctrl_pre{:,2}}',{avg_responses.avg_ctrl_post{:,2}}'], plot_info, current_save_dir, 'Passive Pre Mean (ΔF\F)', 'Passive Post Mean (ΔF\F)',0,1,[-0.05,1.8]);

stats = {prepost_active,prepost_passive};
table_fig3_prepost = [];labels = {'active','passive'};
for i = 1:numel(stats)
    S = unwrap_cells_in_struct(stats{i});
    table = struct2table_recursive(S,labels{i},{'bootstat','ci'});
    table_fig3_prepost = [ table_fig3_prepost;table];
end
save(fullfile(current_save_dir, strcat('table_fig3_prepost.mat')), 'table_fig3_prepost');
writetable(table_fig3_prepost, fullfile(current_save_dir, strcat('table_fig3_prepost.csv')));

% Sound responsive AND Pyr!
current_save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\pre_stim_pyr\sound_responsive_and_pyr\'];
plot_info.colors_celltypes =[ 0.300000000000000	0.200000000000000	0.600000000000000]; %purple
[modl_fit_prepost_active,~,~,prepost_active] = scatter_index_sigcells_histogram_optional([], sound_neurons_pyr, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_post{:,1}}'], plot_info, current_save_dir, 'Active Pre Mean (ΔF\F)', 'Active Post Mean (ΔF\F)',0,1,[-0.05,1.8]);
[modl_fit_prepost_passive,~,~,prepost_passive] = scatter_index_sigcells_histogram_optional([], sound_neurons_pyr, [{avg_responses.avg_ctrl_pre{:,2}}',{avg_responses.avg_ctrl_post{:,2}}'], plot_info, current_save_dir, 'Passive Pre Mean (ΔF\F)', 'Passive Post Mean (ΔF\F)',0,1,[-0.05,1.8]);

stats = {prepost_active,prepost_passive};
table_fig3_prepost = [];labels = {'active','passive'};
for i = 1:numel(stats)
    S = unwrap_cells_in_struct(stats{i});
    table = struct2table_recursive(S,labels{i},{'bootstat','ci'});
    table_fig3_prepost = [ table_fig3_prepost;table];
end
save(fullfile(current_save_dir, strcat('table_fig3_prepost.mat')), 'table_fig3_prepost');
writetable(table_fig3_prepost, fullfile(current_save_dir, strcat('table_fig3_prepost.csv')));

% % relate negative modulated sound neurons to engagement index
% current_save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\pre_stim_pyr\engagement_vs_mod'];
% 
% %during sound only trials!!!
% plot_info.colors_celltypes =[ 0.300000000000000	0.200000000000000	0.600000000000000]; %purple
% [modl_fit_prepost_active,~,~,prepost_active] = scatter_index_sigcells_histogram_optional([], sound_neurons, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_post{:,1}}'], plot_info, current_save_dir, 'Active Pre Mean (ΔF\F)', 'Active Post Mean (ΔF\F)',0,1,[-0.05,1.8]);
% [modl_fit_prepost_passive,~,~,prepost_passive] = scatter_index_sigcells_histogram_optional([], sound_neurons, [{avg_responses.avg_ctrl_pre{:,2}}',{avg_responses.avg_ctrl_post{:,2}}'], plot_info, current_save_dir, 'Passive Pre Mean (ΔF\F)', 'Passive Post Mean (ΔF\F)',0,1,[-0.05,1.8]);
% 
% stats = {prepost_active,prepost_passive};
% table_fig3_prepost = [];labels = {'active','passive'};
% for i = 1:numel(stats)
%     S = unwrap_cells_in_struct(stats{i});
%     table = struct2table_recursive(S,labels{i},{'bootstat','ci'});
%     table_fig3_prepost = [ table_fig3_prepost;table];
% end
% save(fullfile(current_save_dir, strcat('table_fig3_prepost.mat')), 'table_fig3_prepost');
% writetable(table_fig3_prepost, fullfile(current_save_dir, strcat('table_fig3_prepost.csv')));
%%
mod_params.chosen_mice = 1:25;
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
% [pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:25,:), {'sound','sound_neg','opto','both','unmodulated'},[1:25],plot_info, 1,sig_cells_sounds{2});
opto.sig_cells{1,25} = [];
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:25,:), {'sound_neg'},[1:25],plot_info, 1,sig_cells_sounds{2});
plot_info.colors_celltypes = [0.3,0.2,0.6];
scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'EI', 'SMI (Active)',0,-1,[-1,1]);
scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'EI', 'SMI (Passive)',0,-1,[-1,1]);
scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{avg_responses.avg_ctrl_pre{:,1}}',{sound.mod{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'Active Pre Mean (ΔF\F)', 'SMI (Active)',0,-1,[-1,1]);
scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_pre{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'Active Pre Mean (ΔF\F)','Passive Pre Mean (ΔF\F)',0,1,[0,1]);
plot_info.colors_celltypes = [0.3 0.2 0.6];
histogram_diff_index_sig_cells(sig_cells_sounds{2}, sound_neurons, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_pre{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'Active - Passive Pre Mean (ΔF\F)',1, 'absValue', false, 'binWidth', 0.1,'xLimits', [-0.5 0.5]);
%positive sound nuerons
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:25,:), {'sound'},[1:25],plot_info, 1,sig_cells_sounds{2});
plot_info.colors_celltypes = [0.3,0.2,0.6];
scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_pre{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\positive_sound_mod\'], 'Active Pre Mean (ΔF\F)','Passive Pre Mean (ΔF\F)',0,1,[0,1]);
plot_info.colors_celltypes = [0.3 0.2 0.6];
histogram_diff_index_sig_cells(sig_cells_sounds{1}, sound_neurons, [{avg_responses.avg_ctrl_pre{:,1}}',{avg_responses.avg_ctrl_pre{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\positive_sound_mod\'], 'Active - Passive Pre Mean (ΔF\F)',1, 'absValue', false, 'binWidth', 0.1,'xLimits', [-0.5 0.5]);

[diff_stim, diff_pre_stim, diff_pre_ctrl, diff_sounds,diff_sounds_post] = calculate_avg_differences(avg_responses.avg_pre,avg_responses.avg_ctrl_pre,avg_responses.avg_post,avg_responses.avg_ctrl_post);
plot_info.colors_celltypes = [0.3 0.2 0.6];
%plot post - pre vs pre
scatter_index_sigcells_histogram_optional([],sound_neurons_pyr, [{avg_responses.avg_ctrl_pre{:,1}}',{diff_sounds{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\'], 'Pre Mean ΔF\F (Active)', 'Post - Pre Mean ΔF\F (Active)',0,1,[-.1,1;-1,1]);
scatter_index_sigcells_histogram_optional([],sound_neurons_pyr, [{avg_responses.avg_ctrl_pre{:,2}}',{diff_sounds{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\'], 'Pre Mean ΔF\F (Passive)', 'Post - Pre Mean ΔF\F (Passive)',0,1,[-.1,1;-1,1]);
% post sound vs pre difference
scatter_index_sigcells_histogram_optional([],sound_neurons_pyr, [{diff_pre_ctrl{:,1}}',{avg_responses.avg_ctrl_post{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\'], 'Active - Passive Pre Mean (ΔF\F)', 'Post Sound ΔF\F (Active)',0,1,[-1,1]);
scatter_index_sigcells_histogram_optional([],sound_neurons_pyr, [{diff_pre_ctrl{:,1}}',{avg_responses.avg_ctrl_post{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\'], 'Active - Passive Pre Mean (ΔF\F)', 'Post Sound ΔF\F (Passive)',0,1,[-1,1]);
% post difference vs pre difference
scatter_index_sigcells_histogram_optional([],sound_neurons_pyr, [{diff_pre_ctrl{:,1}}',{diff_sounds_post{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\'], 'Active - Passive Pre (ΔF\F)', 'Active - Passive Post (ΔF\F)',0,1,[-0.6,1]);
%negative sound modulated neurons
scatter_index_sigcells_histogram_optional(sig_cells_sounds{2},sound_neurons_pyr, [{diff_pre_ctrl{:,1}}',{diff_sounds_post{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\negative_sound_mod\'], 'Active - Passive Pre (ΔF\F)', 'Active - Passive Post (ΔF\F)',0,1,[-0.6,1]);
%postiive sound modulated neurons
scatter_index_sigcells_histogram_optional(sig_cells_sounds{1},sound_neurons_pyr, [{diff_pre_ctrl{:,1}}',{diff_sounds_post{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\positive_sound_mod\'], 'Active - Passive Pre (ΔF\F)', 'Active - Passive Post (ΔF\F)',0,1,[-0.6,1]);


param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
mod_params.chosen_mice = 1:25;

[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:25,:), {'sound','sound_neg','opto','both','unmodulated'},[1:25],plot_info, 1,sig_cells_sounds{2});
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'engagement';
        %get the significant neurons (positive, negative, both);
        [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params_plot, engagement.mod', engagement.sig_mod_boot'); %using mod_indexm2 because using prepost instead of ctrl for opto
        percent_cells_signed{i} = calculate_sig_celltype_percentages(current_sig_cells(1:25),pooled_cell_types, []);
end
plot_info.functional_names{1} = 'Sound Positive';
plot_info.functional_names{4} = 'S & P';
bar_plot_percent(percent_cells_signed{1},percent_cells_signed{2}, [current_save_dir '\engagement_vs_mod\'],plot_info.functional_names,plot_info.functional_colors,{'Positive','Negative'});



% [pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{2}, opto.sig_cells, opto.mod(1:25,:), {'sound_neg'},[1:25],plot_info, 1,sig_cells_sounds{1});
% plot_info.colors_celltypes = [0.3,0.2,0.6];
% scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, [current_save_dir '\engagement_vs_mod\possitive_sound_mod\'], 'EI', 'SMI (Active)',0,-1,[-1,1]);
% scatter_index_sigcells_histogram_optional([], pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, [current_save_dir '\engagement_vs_mod\possitive_sound_mod\'], 'EI', 'SMI (Passive)',0,-1,[-1,1]);


%just sound engaged neurons rpobably want to do the opposite here
% all_celltypes_updated ={};
% for dataset = 1:size(all_celltypes,2)
%     all_celltypes_updated{1,dataset}.som_cells = all_celltypes{1,dataset}.sound;
% end
% cdf_data = unpack_modindexm(sound.mod,engagement.sig_mod_boot_thr,pooled_cell_types,[1:24]);
% plot_info.colors= plot_info.functional_colors;
% plot_info.lineStyles_contexts= {'-','--'};
% plot_cdf_celltypes([], cdf_data, 1:24, plot_info,'SMI',[-1,1],0); %{dataset,context,celltype}

%% Examine the top pyramidal neurons
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;
contexts_to_compare = [1,2];
params = experiment_config(); 
params.plot_info = plot_info;

% 2) Sound Index Plots
mod_params = params.mod_sounds;
mod_params.mod_threshold = .1;% 0 is no threshold applied
mod_params.chosen_mice = [1:25];
mod_params.min_cells = 0; % >0 so at least 1 modulated neuron per dataset



%%%% sig cells %%%%%%%%%%%
plot_info.y_lims = [-.4, .4];
% Set labels for plots.
plot_info.plot_labels = {'Sounds','Sounds'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
plot_info.type = 'sounds';
params.plot_info = plot_info;
params.info.chosen_mice = [1:25];
params.string = 'Sounds';
mod_params.results = sound.results;
params.plot_info.celltype_names

%%%% using sig cells %%%%%%%%%%%
top_sig_cells = sound.sig_cells_top;
%datasets
plot_info.y_lims = [-.2, .3];params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, sound.mod, top_sig_cells, updated_all_celltypes, params, savepath_fig);


[combined_sig_cells, ~] = union_sig_cells(sound.sig_mod_boot_thr(:,1)', sound.sig_mod_boot_thr(:,2)', sound.mod);
%datasets
plot_info.y_lims = [-.2, .3];params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, sound.mod, combined_sig_cells, all_celltypes, params, savepath_fig2);

%avg traces
param_sets_traces = { ...
            struct('mod_threshold',  .1, ...
                   'threshold_single_side', 1, ...
                   'savestring', 'positive_modulated', ...
                   'chosen_mice', mod_params.chosen_mice)};

plot_info.trace_ylims = [0.1,0.35];
mod_params.data_type = 'top';
params.plot_info = plot_info;
sound.sig_mod_boot_thr_w_top = sound.sig_cells_top';
%avg traces
[~,~] = wrapper_avg_cell_type_traces(context_data_sounds.dff,updated_all_celltypes,sound.mod,sound.sig_mod_boot_thr_w_top',mod_params,savepath_fig,'top_dff',plot_info,'param_sets',param_sets_traces);

%% pre-stimulus period

[preavg_index_by_dataset,~] = unpack_modindexm(avg_responses.avg_pre,[],top_neurons,[1:25]);
params.plot_info = plot_info;
preavg_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(savepath_fig, preavg_index_by_dataset, [1:25],...
          params.plot_info, [.075,.4],0,'Pre Mean (\DeltaF/F)');
%traces
plot_info.pooled_names = {'Top Pyr'};
plot_info.trace_ylims = [0.16,0.22];
plot_info.colors_pooled_3contexts = [0.160000000000000	0.400000000000000	0.240000000000000
0.540000000000000	0.820000000000000	0.640000000000000%0.300000000000000	0.580000000000000	0.400000000000000
0.540000000000000	0.820000000000000	0.640000000000000]% for trace colors
[~,~] = wrapper_avg_pooled_type_traces(context_data_sounds.dff,top_neurons,[],[1:25],savepath_fig,'sound_dff_functional_types_-2to0_',plot_info,[1:10]);


%% engagement index
cd('W:\Connie\results\Bassi2025\data\supplemental_data\engagement_index');
load('engagement.mat'); 

%neuron level plots!
[top_pyr_mod_neurons, ~, ~, ~, ~] = organize_sig_mod_index_contexts_celltypes(...
        [1:25], engagement.mod', top_neurons_sig', all_celltypes,plot_info.celltype_names);

[~, ~, ~, ~, celltypes_ids,~] = ...
    organize_sig_mod_index_contexts_celltypes([1:25],  engagement.mod', top_neurons_sig', all_celltypes,{'Top Pyr'});
% plots
[stats] = mod_index_violin_across_celltypes([savepath_fig '\neuron_level\'],top_pyr_mod_neurons,{''},plot_info.colors_celltype  ,2,celltypes_ids(:,1),[1:25],[-1,1])


contexts_to_compare = [1]; 
overlap_labels = {'Act - Pass'}; 
mod_params.mod_threshold = .1;% 
mod_params.chosen_mice = [1:25];
mod_params.min_cells = 0;

params.info.chosen_mice = mod_params.chosen_mice;
plot_info.y_lims = [-.3, .3];
plot_info.behavioral_contexts = {'Engagement Index'}; %decide which contexts to plot
plot_info.type = 'engagement'; %make lines gray instead of yellow

[context_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:25], engagement.mod', sound.sig_mod_boot_thr_w_top, updated_all_celltypes,plot_info.celltype_names);
% cell type comparisons
%%%%%% sig cells (celltypes) %%%%%
plot_info.y_lim_ratio = 2;
% plot_info.celltype_names = {'Top Pyr','SOM','PV'};
params.plot_info = plot_info;
mod_index_stats_datasets_all = generate_engagement_index_plots_datasets([1:25], engagement.mod', sound.sig_mod_boot_thr_w_top, updated_all_celltypes, params, [savepath_fig '\engagement_mod\'], celltypes_ids,plot_info.y_lims);


%% axis?
split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1:4; choose_params.chosen_datasets = 1:25;
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative,sound_concat,stim_concat] = ...
    find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,sound.sig_mod_boot_thr_w_top,split_params); %,{50:59,63:73}

celltype = 1; %since all top neurons were by definition pyr
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,~,~,context_all_sound,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,~,~,context_all_stim,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',[savepath_fig '/axis/'],'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',[savepath_fig '/axis/'],'Engagement');

%%
split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1; choose_params.chosen_datasets = 1:25;
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative,sound_concat,stim_concat] = ...
    find_axis_updated_specify_splits(context_data.dff, choose_params, all_celltypes,sound.sig_cells,split_params); %,{50:59,63:73}

celltype = 1; %since all top neurons were by definition pyr
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,~,~,context_all_sound,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,~,~,context_all_stim,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',['W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\sound_modulated_pyr_neuron_axis'],'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',['W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\sound_modulated_pyr_neuron_axis'],'Engagement');
