% data structures saved in 
cd("W:\Connie\results\Bassi2025\data")
%% Figure 1 -DYNAMICS AND DECODING
saved_decoding_dir = "W:\Connie\results\Bassi2025\data\Active_decoding\SVM\";
load('plot_info.mat'); load('info.mat');load('all_celltypes.mat');
load('imaging_st.mat'); load('alignment.mat');
savepath_fig1 = [];

% PERFORMANCE PLOT
performance = get_opto_performance_simple(imaging_st,[],alignment);
plot_performance_all(performance(1,1:25),savepath_fig1,[1:25]);

% DYNAMICS PLOTS
alignment.data_type = 'z_dff';

heatmaps_avg_combined_all_celltypes_separate_plots_refactored( ...
        imaging_st,plot_info,alignment,[],savepath_fig1,1)

dynamics_info.bin_size = 1;
dynamics_info.conditions = [];
alignment.data_type = 'dff';% 'dff', 'z_dff', else it's deconvolved
alignment.type = 'all'; %'reward','turn','stimulus','ITI'
% make bar plots using the peaks found
dynamics_info.bin_size = 1;
[dynamics_info.max_cel_avg,dynamics_info.new_onsets,dynamics_info.binss,dynamics_info.original_onsets] = peak_times_avg (imaging_st,alignment,dynamics_info,1);
cdf_peak_times_updated(dynamics_info.max_cel_avg,dynamics_info,all_celltypes,plot_info,savepath_fig1,1); %last number is number of nans wanted
clear imaging_st %clear bc it takes up memory

% DECODING PLOTS
stim_ctrl_labels = {};
event_names = {'sound_category','choice','outcome'};
do_passive = 0;
for event = 1:length(event_names)
    %full population plots
    if ~isempty(savepath_fig1)
        save_plot_directory = fullfile(savepath_fig1,'full_population',event_names{event});
    else
        save_plot_directory = [];
    end
    plot_final_svm_traces_boxplots_updated('full',event_names{event},do_passive,save_plot_directory,stim_ctrl_labels,info,saved_decoding_dir);
end

%% Figure 2 - MOD INDEX and POST RESPONSES
savepath_fig2 = ['W:\Connie\results\Bassi2025\fig2_nature\'];
% 1) LOAD THE DATA
load('context_data.mat'); load('sound.mat'); load('opto.mat');load('avg_responses.mat'); load('axis_results.mat')
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

%%%% using sig cells %%%%%%%%%%%
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

plot_info.y_lims = [-.2, .3];
plot_info.trace_ylims = [0.14,0.3];
params.plot_info = plot_info;
%avg traces
[~,~] = wrapper_avg_cell_type_traces(context_data_sounds.dff,all_celltypes,sound.mod,sound.sig_mod_boot_thr,mod_params,savepath_fig2,'sound_dff',plot_info,'param_sets',param_sets_traces);


% 3)Photostim Index plots
mod_params = params.mod;
mod_params.mod_threshold = .1;% 0 is no threshold applied
mod_params.chosen_mice = [1:24];
params.string = 'opto';
mod_params.min_cells = 0; %at least 1 neuron per dataset that is modulated! (>0 is the logic)
params.min_cells = mod_params.min_cells;
mod_params.results = opto.results;

% Set y-axis limits for the plots.
plot_info.y_lims = [-.4, .4];
params.info.chosen_mice = mod_params.chosen_mice;
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
plot_info.type = 'stim';
plot_info.trace_ylims = []; %different ylims
params.plot_info = plot_info;

%%%% using sig cells %%%%%%%%%%%
%datasets
plot_info.y_lims = [-.2, .4]; params.plot_info = plot_info;params.min_cells = mod_params.min_cells;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, opto.mod,  opto.sig_mod_boot_thr(:,3)', all_celltypes, params,savepath_fig2);
%stim+sound - sound avg (difference)
[~,~] = wrapper_avg_cell_type_traces_stim_minus_ctrl(context_data.dff,all_celltypes,opto.mod,opto.sig_mod_boot,mod_params,savepath_fig2,'opto_dff',plot_info,opto.mod_prepost,'param_sets',param_sets_traces);
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,opto.mod,opto.sig_mod_boot,mod_params, savepath_fig2,'sound_opto_dff',plot_info,opto.mod_prepost,'param_sets',param_sets_traces);

% 4) FUNCTIONAL TYPE PLOTS - POST RESPONSES
contexts_to_compare = [1,2]; %[1:3];%[1,2]; %[1,2]; %[1:3];
overlap_labels = {'Sound Only','Photostim Only', 'Sound & Photostim','Unmodulated'}; 
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_cells(1:24),opto.sig_cells(1:24,:), opto.mod, contexts_to_compare);
plot_sig_overlap_pie(mean(percent_cells_per_dataset)*100, overlap_labels, savepath_fig2, contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',flipud(plot_info.pooled_colors(1:4,:)));

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'both','opto','sound'},[1:24],plot_info, 1);
[~,~] = wrapper_scatter_index_contexts([],avg_responses.avg_ctrl_post, avg_responses.diff_stim, pooled_cell_types, plot_info, savepath_fig2, 'Post (Sound)', 'Post (Δ Stim)',0,0,[-1,2]);

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both'},[1:24],plot_info, 1);
[~,~] = wrapper_plot_corr_means([],pooled_cell_types, avg_responses.avg_ctrl_post, avg_responses.diff_stim, avg_responses.avg_post, savepath_fig2, plot_info, [-.5,.5], 'Corr (Sound vs Δ Stim)', [1:24], [1:3]) %1:4 is functional subtimes from pooled


%% Figure 3- PRE AND AXIS PLOTS
% 1) PRE STIMULUS PLOTS
plot_info.type = 'engagement'; %'sound'
savepath_fig3 = ['W:\Connie\results\Bassi2025\fig3_nature\'];

[pooled_cell_types,plot_info.pooled_names,plot_info.pooled_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);
plot_info.pooled_names = {{'Sound';'modulated'},{'Photostim';'modulated'},{'S & P';'modulated'},'Unmodulated'}
plot_info.trace_ylims = [0.16,0.22];
[~,~] = wrapper_avg_pooled_type_traces(context_data.dff,pooled_cell_types,[],[1:24],savepath_fig3,'sound_dff_functional_types_-2to0_',plot_info,[1:10]);

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);
[preavg_index_by_dataset,~] = unpack_modindexm(avg_responses.avg_pre,[],pooled_cell_types,[1:24]);
params.plot_info = plot_info;
preavg_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(savepath_fig3, preavg_index_by_dataset, [1:24],...
          params.plot_info, [.075,.4],0,'Pre Mean (\DeltaF/F)');

% 2) AXIS PLOTS
celltype = 4; %4 = using all neurons (1=pyr,2=som,3=pv)
plot_proj_meansplits_traces([1:24],axis_results.proj_norm_ctrl, 'context',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},savepath_fig3,'xlabel','Time from stimulus onset (s)');

colors_medium = [0.37 0.75 0.49 %green
                0.17 0.35 0.8  %blue
                0.82 0.04 0.04];
edges_values_weights = [-.1,.1];
num_bins_weights = 20;
[~,~] = histogram_weights_celltypes_vs_axis_splits([1:24],axis_results.weights, 'Context' ,all_celltypes, edges_values_weights,num_bins_weights,colors_medium,savepath_fig3);

frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,~,~,context_all_sound,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,~,~,context_all_stim,~,~,~] = ...
    linear_regression_corr_model(axis_results.proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',savepath_fig3,'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',savepath_fig3,'Engagement');

plot_performance_vs_engagement_axis_updated(percent_correct_all,axis_results.engagement_all,[20,5],savepath_fig3,[0,2]);
