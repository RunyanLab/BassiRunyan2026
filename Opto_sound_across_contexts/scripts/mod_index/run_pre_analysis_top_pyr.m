% to address concerns related to the pre-stimulus activity in pyr neurons
cd('W:\Connie\results\Bassi2025\data')
load('context_data.mat');load('context_data_sounds.mat'); load('sound.mat'); load('opto.mat');load('avg_responses.mat'); load('axis_results.mat')

%% organize sound and top neurons
savepath_fig = ['W:\Connie\results\Bassi2025\fig3\reviews\top_pyr_neurons\'];

sound = get_top_informative_neurons(sound,'pyr');

updated_all_celltypes = {}; %delete other cell types for plotting purposes
top_neurons = {};
sound_neurons = {};
for d = 1:25
    updated_all_celltypes{d}.pyr_cells = all_celltypes{d}.pyr_cells;
    top_neurons{d}.pyr_cells = sound.sig_cells_top{1, d};
    sound_neurons{d}.pyr_cells = sound.sig_cells{1, d};

end

%% correlate pre vs post activity of sound responsive neurons
current_save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\pre_stim_pyr'];

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

% % --- Defaults for responses --- DURING SOUND ONLY TRIALS (avg_ctrl_post).
% % avg_post contains sound+stim responses
% response_types_info = { ...
%     struct('name','pre',       'data', avg_responses.avg_ctrl_pre,   'range', [0.1,0.4], 'label', 'Pre Mean (ΔF/F)'), ... 
%     struct('name','post',      'data', avg_responses.avg_ctrl_post, 'range', [0,0.8],   'label', 'Pre Mean (ΔF/F)') ...
% };
% [stats_all, responses_by_dataset] = wrapper_plot_response_means({avg_responses.avg_ctrl_pre,avg_responses.avg_ctrl_post},response_types_info, sound_neurons, [1:25], current_save_dir, plot_info, []);
%%
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
[~,~] = wrapper_avg_pooled_type_traces(context_data_sounds.dff,top_neurons,[],[1:25],savepath_fig,'sound_dff_functional_types_-2to0_',plot_info,[1:10]);

%% engagement index
cd('W:\Connie\results\Bassi2025\data\supplemental_data\engagement_index');
load('engagement.mat'); 

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

