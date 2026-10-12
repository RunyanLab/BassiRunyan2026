addpath(genpath('C:\Code\Github\BassiRunyan2025'))
% Setup analysis parameters
%includes all datasets being analyzed, frame parameters, mod index
%parameters
params = experiment_config(); 
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;

%% Pool activity across mice
[all_celltypes, dff_st, deconv_st, stim_info, ...
 mouse_context_tr, deconv_st_interp, alignment_frames] = ...
    pool_activity(params.info.mouse_date, params.info.serverid, params.info.path_string, true, [60,60],1);

% Save basic information
% Save variables with consistent paths
filename = fullfile(params.info.savepath, 'data_info');
save(fullfile(filename, 'info.mat'), 'params');
save(fullfile(filename, 'alignment_frames.mat'), 'alignment_frames');
save(fullfile(filename, 'mouse_context_tr.mat'), 'mouse_context_tr');
save(fullfile(filename, 'stim_info.mat'), 'stim_info');

% Process cell types
[num_cells, sorted_cells] = organize_pooled_celltypes(dff_st, all_celltypes); %gives index relative to all datasets
save(fullfile(filename, 'sorted_cells.mat'), 'sorted_cells');

% Separate neural data into contexts (organizes original _st into cell arrays separated by
% context using mouse_context_trials)
%organized context.dff{context,mouse};
[context_data.dff,stim_trials_context,ctrl_trials_context] = separate_structure_2context(dff_st,mouse_context_tr,stim_info);%  context.dff{context,mouse}
[context_data.deconv] = separate_structure_2context(deconv_st,mouse_context_tr,stim_info);%  context.dff{context,mouse}
[context_data.deconv_interp] = separate_structure_2context(deconv_st_interp,mouse_context_tr,stim_info);%  context.dff{context,mouse}
save(fullfile(filename, "ctrl_trials_context.mat"),"ctrl_trials_context");
save(fullfile(filename, "stim_trials_context.mat"),"stim_trials_context");
save(fullfile(filename, "context_data.mat"),"context_data",'-v7.3');
%% Get average responses
% Setup parameters
avg_params = struct(...
    'response_window', 1:122, ...
    'trial_type', 'stim', ...
    'mode', 'separate');

% Get averages
[avg_results_stim ,avg_results_by_dataset_stim,avg_results_ctrl, avg_results_by_dataset_ctrl] = wrapper_trial_averaging(params.info, dff_st,stim_trials_context,ctrl_trials_context, avg_params, [params.info.savepath '/avg/']);
% generate_heatmaps(context_data, sorted_cells, info);
generate_neural_heatmaps(dff_st, stim_trials_context, ctrl_trials_context,[],[1:24], params, 'opto');


%% Calculate modulation indices
mod_params = params.mod;
mod_params.data_type_dff = 'dff';
mod_params.savepath = fullfile(params.info.savepath, 'mod', mod_params.mod_type, mod_params.mode)

[mod_index_results, sig_mod_boot, mod_indexm] = ...
    wrapper_mod_index_calculation(params.info, dff_st, mod_params.response_range, mod_params.mod_type, mod_params.mode, stim_trials_context, ctrl_trials_context,mod_params.nShuffles, mod_params.savepath, mod_params.data_type_dff);
%% Generate single cell plots
dataset_to_plot = 9;
context_to_plot = [1:2];
sig_neurons_to_plot = [];
modulation_type = 1; %positive or negative
 plot_info = params.plot_info;
 plot_info.plot_mode = 'both';% stim ctrl or both
 plot_info.plot_avg = 0;
 plot_info.caxis = 0;

 wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,modulation_type, 'opto',plot_info);
 %single trial plots
 dataset_to_plot = 9;
context_to_plot = [3]; %spont
modulation_type = 1; %positive or negative
plot_info.plot_mode = 'stim';% stim ctrl or both
plot_info.avg_traces = 1;

 wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,modulation_type, 'opto',plot_info);

 modulation_type = -1;
  wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,modulation_type, 'opto',plot_info);

plot_info.line_colors = [0.3,0.2,0.6 ; 1,0.7,0];
plot_info.plot_mode = 'both';% stim ctrl or both
context_to_plot = [1];
 wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,1, 'opto',plot_info);

%% Compare modulation indices across contexts and cell types
mod_params.mod_threshold = .1;% 0 is no threshold applied
mod_params.chosen_mice = [1:24];
mod_params.min_cells = 1; %one more than this


%using previously calculated mod index from prepost (looking at spont to
%find the thresholded cells!)
load('V:\Connie\results\opto_sound_2025\context\mod\prepost\separate\sig_mod_boot.mat');
load('V:\Connie\results\opto_sound_2025\context\mod\prepost\separate\mod_indexm.mat');
%plot % modulated cells per context
mod_params.threshold_single_side = 0;
sig_mod_boot_thr = get_thresholded_sig_cells(params.info, mod_params, mod_indexm, sig_mod_boot, sorted_cells, all_celltypes, [],0);

%PLOT MODULATED NEURONS in the spontaneous context
context_num = 3;
[percentage_stats] = plot_sig_mod_pie(mod_params, mod_indexm, sig_mod_boot_thr, context_num, 'W:\Connie\results\Bassi2025\fig3\mod\', 'horizontal',all_celltypes);
table_percentages1= struct2table_recursive(unwrap_cells_in_struct(percentage_stats),'spont',{'bootstat','ci'});
table_percentages = [table_percentages1];
save(fullfile('W:\Connie\results\Bassi2025\fig3\mod\', strcat('table_percentages.mat')), 'table_percentages');
writetable(table_percentages, fullfile('W:\Connie\results\Bassi2025\fig3\mod\', strcat('table_percentages.csv')));

cell_indices = arrayfun(@(x) struct('all_cells', 1:x), num_cells(:)', 'UniformOutput', false); %;
cell_indices_like_sig = arrayfun(@(x) 1:x, num_cells(:)', 'UniformOutput', false)'; %to plot ALL neurons (not just sig mod boot)
wrapper_avg_cell_type_traces_single_context(context_data.dff(context_num,:),cell_indices,1,mod_indexm(:,context_num),sig_mod_boot_thr(:,context_num),mod_params,'W:\Connie\results\Bassi2025\fig3\celltype_traces\spont\','opto_dff',plot_info,mod_indexm);
wrapper_avg_cell_type_traces_single_context(context_data.dff(context_num,:),cell_indices,1,mod_indexm(:,context_num),cell_indices_like_sig,mod_params,'W:\Connie\results\Bassi2025\fig3\celltype_traces\spont\all_cells\','opto_dff',plot_info,mod_indexm);

%heatmap of mean
generate_neural_heatmaps_simple(dff_st, stim_trials_context, ctrl_trials_context,sig_mod_boot_thr(:,context_num )',[1:24], params, 'opto',context_num);
% MAKE AVG PLOTS OF TRACES (DOES NOT SEPARATE LEFT VS RIGHT AVG ACROSS ALL)
savepath = 'W:\Connie\results\Bassi2025\fig3\celltype_traces\';
wrapper_avg_cell_type_traces(context_data.deconv_interp,all_celltypes,mod_indexm,sig_mod_boot,mod_params,savepath,'opto_deconv',plot_info,mod_indexm);
[traces_mean,dataset_ids] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,mod_indexm,sig_mod_boot,mod_params,savepath,'opto_dff',plot_info,mod_indexm);
mod_params.mod_threshold = 0;
mod_params.threshold_single_side =1;
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),3,1)';
wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,mod_indexm,all_cells,mod_params,[savepath '/all_cells/'],'opto_dff',plot_info,mod_indexm);

% plot_info.trace_ylims = [-.01, .03];
[traces_mean2,dataset_ids2] = wrapper_avg_cell_type_traces_stim_minus_ctrl(context_data.dff,all_celltypes,mod_indexm,sig_mod_boot,mod_params,savepath,'opto_dff',plot_info,mod_indexm);

% evoked_stats = run_stats_on_traces(traces_mean, [], 63:92,{'PYR', 'SOM', 'PV'},[]);
% evoked_stats_diff = run_stats_on_traces(traces_mean2, [], 63:92,{'PYR', 'SOM', 'PV'},[]);
% table_ = struct2table_recursive(unwrap_cells_in_struct(evoked_stats),'',{'bootstat'});
% table_2 = struct2table_recursive(unwrap_cells_in_struct(evoked_stats_diff),'',{'bootstat'});
% 
% table_fig3_evoked = [table_;table_2];
% save(fullfile(mod_params.savepath,'\sig_neurons\evoked_stats.mat'),'evoked_stats');
% save(fullfile(mod_params.savepath,'\sig_neurons\evoked_stats_diff.mat'),'evoked_stats_diff');
% save(fullfile([mod_params.savepath '\sig_neurons\'], strcat('table_fig3_evoked.mat')), 'table_fig3_evoked');
% writetable(table_fig3_evoked, fullfile([mod_params.savepath '\sig_neurons\'], strcat('table_fig3_evoked.csv')));
table_fig3_evoked = make_stats_tables_evoked(traces_mean, traces_mean2, '\sig_neurons\', {'PYR', 'SOM', 'PV'},63:92, mod_params.savepath);


% taking the differences
context_num = [1,2];
difference_params.type = 'stim_sub_ctrl_post'; % options: 'stim_sub_ctrl_all','stim_sub_ctrl_post','stim_sub_pre','ctrl_sub_pre'
difference_params.pre_frames = params.frames.before;
difference_params.post_frames = params.frames.after;
generate_neural_heatmaps_difference(dff_st, stim_trials_context, ctrl_trials_context,sig_mod_boot_thr(:,3 )',[1:24], params, 'opto',context_num,difference_params);

%%
load('V:\Connie\results\opto_sound_2025\context\mod\ctrl\separate\mod_indexm.mat');

% sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info, mod_params, mod_indexm, sig_mod_boot, sorted_cells,mod_params.savepath);
% % sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(info, mod_params, mod_indexm(:,3), sig_mod_boot(:,3), sorted_cells,fullfile(mod_params.savepath,'spont_sig'));

%plot % overlap of modulated cells across contexts!
contexts_to_compare = [1,2]; %[1:3];%[1,2]; %[1,2]; %[1:3];
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
percent_cells = calculate_sig_overlap_percentages(sig_mod_boot_thr(mod_params.chosen_mice,:), mod_indexm, contexts_to_compare);
plot_sig_overlap_pie(percent_cells, overlap_labels, mod_params.savepath, contexts_to_compare);

% ORGANIZE MODULATION INDICES AND CELL TYPE INDICES ACROSS DATASETS
[context_mod_all, chosen_pyr, chosen_mcherry, chosen_tdtom, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], mod_indexm, sig_mod_boot_thr, all_celltypes,plot_info.celltype_names);

%% Make plots of modulation index across contexts/cell types (separating into datasets or mice) 
%USING ALL CELLS
% Set y-axis limits for the plots.
params.info.chosen_mice = mod_params.chosen_mice;
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
plot_info.y_lims = [-.2, .25];
params.plot_info = plot_info;
params.string = 'opto';
save_dir = 'W:\Connie\results\Bassi2025\fig3\mod\ctrl\separate';

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm,  [], all_celltypes, params, save_dir);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
mod_index_stats = plot_context_comparisons([1,2],overlap_labels, mod_indexm, [], all_celltypes, params,save_dir);
save(fullfile(save_dir, 'mod_index_stats.mat'), 'mod_index_stats');

S = unwrap_cells_in_struct(mod_index_stats_datasets);
% S2 = unwrap_cells_in_struct(mod_index_stats);
table_1 = struct2table_recursive(mod_index_stats,'single_cells',{'bootstat','ci'});
% table_2 = struct2table_recursive(mod_index_stats_datasets,'datasets',{'bootstat','ci'});
table_2 = struct2table_recursive(S,'datasets',{'bootstat','ci'});
table_fig3 = [table_1; table_2];
save(fullfile(save_dir, strcat('table_fig3.mat')), 'table_fig3');
writetable(table_fig3, fullfile(save_dir, strcat('table_fig3.csv')));

%% Make plots of modulation index across contexts/cell types
%load significant neurosn from prepost index
load('V:\Connie\results\opto_sound_2025\context\mod\prepost\separate\sig_mod_boot_thr.mat')
% Set y-axis limits for the plots.
plot_info.y_lims = [-.4, .4];
params.info.chosen_mice = mod_params.chosen_mice;
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
params.plot_info = plot_info;

%save directory
save_dir = ['W:\Connie\results\Bassi2025\fig3\mod\ctrl\separate\sig_neurons'];%[mod_params.savepath]; %[mod_params.savepath '/prepost_spont_sig_cells'];% '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
mod_index_stats = plot_context_comparisons(contexts_to_compare,overlap_labels, mod_indexm, sig_mod_boot_thr(:,3), all_celltypes, params,save_dir);

% %scatter plot of modulated cells
% [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', mod_indexm);
% modl_fit = scatter_index_sigcells(combined_sig_cells, all_celltypes, [{mod_indexm{:,1}}',{mod_indexm{:,2}}'], plot_info, [], 'Active Mod', 'Passive Mod')

%% Save Results- save your modulation index data.
save(fullfile(save_dir, 'mod_index_data.mat'), 'context_mod_all', 'chosen_pyr', 'chosen_mcherry', 'chosen_tdtom', 'celltypes_ids');
save(fullfile(save_dir, 'mod_index_stats.mat'), 'mod_index_stats');

%% Make plots of modulation index across contexts/cell types (separating into datasets or mice)
% Set y-axis limits for the plots.
plot_info.y_lims = [-.2, .4];
params.plot_info = plot_info;

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm,  sig_mod_boot_thr(:,3)', all_celltypes, params, save_dir);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
% anova_stats = run_stats_on_mod_index(mod_index_stats_datasets.stats, [], {'Pyr','SOM','PV'},[],'mouse_means')
S = unwrap_cells_in_struct(mod_index_stats_datasets);
% S2 = unwrap_cells_in_struct(mod_index_stats);
table_1 = struct2table_recursive(mod_index_stats,'single_cells',{'bootstat'});
% table_2 = struct2table_recursive(mod_index_stats_datasets,'datasets',{'bootstat','ci'});
table_2 = struct2table_recursive(S,'datasets',{'bootstat'});
table_fig3 = [table_1; table_2];
save(fullfile(save_dir, strcat('table_fig3.mat')), 'table_fig3');
writetable(table_fig3, fullfile(save_dir, strcat('table_fig3.csv')));

%% look at pre stimulus period?
% find the mean of the significant cells (in sig_mod_boot) during the
% after_frame periods for each trial
after_frames_short = 62:72;
before_frames = 49:59; %usually I do 50:60
example_mouse = 10;
neural_data_to_use = dff_st; %dff_st or deconv_st
%[avg_mod_mouse,avg_mod_mouse_ctrl] = aftermeasure_trials_sigcells_new(chosen_mice, after_frames_short,sig_mod_boot_thr,dff_st,example_mouse);

%define trial modulation-this one uses dot product of trial vs stim axis (difference post-pre of modulated neurons)
% can look at dot product of pre trial or post trial mean vs stim axis
[avg_mod_mouse,avg_mod_mouse_ctrl] = aftermeasure_trials_sigcells_stimaxis(chosen_mice, after_frames_short,before_frames,sig_mod_boot_thr,neural_data_to_use,example_mouse,info.savepath)

% get post stim measure (here is the mean), z-score all the measures for
% each mouse, does not use sig_cells for post_stim measure if given
% sig_mod_boot ([] if want to use all of them)
bframes= before_frames; %[48:58] ;
[premean_activity_cells,premean_activity_cells_ctrl,cell_types_names,postmetric_all,postmetric_all_ctrl] = prestimmean_nosig(chosen_mice,bframes,neural_data_to_use,all_celltypes,sig_mod_boot_thr,avg_mod_mouse,avg_mod_mouse_ctrl);
% [premean_activity_cells,premean_activity_cells_ctrl,cell_types_names,postmetric_all,postmetric_all_ctrl] = prestimratio_nosig(chosen_mice,bframes,dff_st,all_celltypes,sig_mod_boot_thr,avg_mod_mouse,avg_mod_mouse_ctrl);
%make figures
%scatter_aftermetric_mean_var_corr_nosig_new; was code that calculated and
%plotted things

% Create percentile divisions for premean_activity_cells for binning
prtiles = [0 25 50 75 100];
modl_fit = scatter_prestimmean_posttrialmeasure(premean_activity_cells,premean_activity_cells_ctrl,cell_types_names,postmetric_all,postmetric_all_ctrl,plot_info.colors_stimctrl(1,:),plot_info.colors_stimctrl(2,:),prtiles,info.savepath);

%% COMPARE OPTO SOUND NEURONS
sound_sig = load('V:\Connie\results\opto_sound_2025\context\sounds\mod\prepost_sound\separate\sig_mod_boot_thr.mat').sig_mod_boot_thr;

%get union of active and passive significant across contexts
[combined_sound_cells, ~] = union_sig_cells(sound_sig(:,1)', sound_sig(:,2)', mod_indexm);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(1:24,1)', sig_mod_boot_thr(1:24,2)', mod_indexm);

opto_sound_cells = intersect_sig_cells(combined_sig_cells,combined_sound_cells,mod_indexm);


[context_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], mod_indexm, opto_sound_cells', all_celltypes,plot_info.celltype_names);

% Make plots of modulation index across contexts/cell types
% Set y-axis limits for the plots.
plot_info.y_lims = [-.5, .5];
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
params.plot_info = plot_info;
params.info.chosen_mice = [1:24];

%save directory
save_dir = [params.info.savepath '/mod/opto_sound/']; % '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.

% Generate visualization suite
[mod_index_stats] = generate_mod_index_plots(context_mod_all, celltypes_ids, params, save_dir);


for d = 1:24
dataset_to_plot = [d];
context_to_plot = [1:3];
sig_neurons_to_plot = opto_sound_cells{dataset_to_plot};
modulation_type = -1; %positive or negative
 wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,modulation_type, 'opto_sound');
end

%%

sound_sig = load('V:\Connie\results\opto_sound_2025\context\sounds\mod\prepost_sound\separate\sig_mod_boot_thr.mat').sig_mod_boot_thr;

%get union of active and passive significant across contexts
[combined_sound_cells, ~] = union_sig_cells(sound_sig(:,1)', sound_sig(:,2)', mod_indexm);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(1:24,1)', sig_mod_boot_thr(1:24,2)', mod_indexm);

opto_only_cells = setdiff_sig_cells(combined_sig_cells,combined_sound_cells,mod_indexm);


[context_mod_all, ~, ~, ~, celltypes_ids] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], mod_indexm, opto_only_cells', all_celltypes,plot_info.celltype_names);

% Make plots of modulation index across contexts/cell types
% Set y-axis limits for the plots.
plot_info.y_lims = [-.5, .5];
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
params.plot_info = plot_info;
params.info.chosen_mice = [1:24];

%save directory
save_dir = [params.info.savepath '/mod/opto_only/']; % '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.

% Generate visualization suite
[mod_index_stats] = generate_mod_index_plots(context_mod_all, celltypes_ids, params, save_dir);


for d = 1:5
dataset_to_plot = [d];
context_to_plot = [1:3];
sig_neurons_to_plot = opto_sound_cells{dataset_to_plot};
modulation_type = 1; %positive or negative
 wrapper_mod_index_single_plots(params.info, dff_st, stim_trials_context, ctrl_trials_context, mod_index_results,...
     dataset_to_plot, context_to_plot,sig_neurons_to_plot,modulation_type, 'opto_only');
end

%%
curr_savepath = 'V:\Connie\results\opto_sound_2025\context\mod\selectivity\opto_sound';
% [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', mod_indexm);
modl_fit = scatter_index_sigcells(opto_sound_cells, all_celltypes, [{selectivity_indexm{:,1}}',{selectivity_indexm{:,2}}'], plot_info, curr_savepath, 'Active Selectivity', 'Passive Selectivity')
[p_val_mod] = histogram_diff_index_sig_cells(opto_sound_cells, all_celltypes,  [{selectivity_indexm{:,1}}',{selectivity_indexm{:,2}}'], plot_info, curr_savepath, 'Abs(active) - Abs(passive')

%%
curr_savepath = 'V:\Connie\results\opto_sound_2025\context\mod_index_opto_sounds_sound_only';
sound_only_cells = setdiff_sig_cells(combined_sound_cells(1:24),combined_sig_cells,mod_indexm);

cells_to_test = sound_only_cells;
modl_fit = scatter_index_sigcells(cells_to_test, all_celltypes, [{mod_indexm{:,2}}',{sound_indexm{:,2}}'], plot_info, curr_savepath, 'Passive Opto', 'Passive Sound')
[p_val_mod] = histogram_diff_index_sig_cells(cells_to_test, all_celltypes,  [{selectivity_indexm{:,1}}',{selectivity_indexm{:,2}}'], plot_info, curr_savepath, 'Abs(pass opto) - Abs(pass sound)')

%% look at correct vs incorrect avg trials

% stim_trials_context, ctrl_trials_context,fields, number to get, true or
% false to get all passive/spont trials
[update_stim_trials_context,update_ctrl_trials_context, updated_mouse_tr_context] = find_specified_VR_trials_in_context_trials(stim_trials_context, ctrl_trials_context, {'correct'},{1},true);
[context_data_updated.deconv] = separate_structure_w_matrix(deconv_st,updated_mouse_tr_context);%  context.dff{context,mouse}
[context_data_updated.dff] = separate_structure_w_matrix(dff_st,updated_mouse_tr_context);%  context.dff{context,mouse}
[context_data_updated.deconv_interp] = separate_structure_w_matrix(deconv_st_interp,updated_mouse_tr_context);%  context.dff{context,mouse}

mod_params.chosen_mice = 1:24;
savepath = 'V:\Connie\results\opto_sound_2025\context\dynamics\correct_only';
wrapper_avg_cell_type_traces(context_data_updated.deconv_interp,all_celltypes,mod_indexm,sig_mod_boot,mod_params.chosen_mice,savepath,'opto_deconv',plot_info);
wrapper_avg_cell_type_traces(context_data_updated.dff,all_celltypes,mod_indexm,sig_mod_boot,mod_params.chosen_mice,savepath,'opto_dff',plot_info);

%now plot incorrect trials
[update_stim_trials_context,update_ctrl_trials_context, updated_mouse_tr_context] = find_specified_VR_trials_in_context_trials(stim_trials_context, ctrl_trials_context, {'correct'},{0},true);
[context_data_updated.deconv] = separate_structure_w_matrix(deconv_st,updated_mouse_tr_context);%  context.dff{context,mouse}
[context_data_updated.dff] = separate_structure_w_matrix(dff_st,updated_mouse_tr_context);%  context.dff{context,mouse}
[context_data_updated.deconv_interp] = separate_structure_2context(deconv_st_interp,updated_mouse_tr_context,stim_info);%  context.dff{context,mouse}
savepath = 'V:\Connie\results\opto_sound_2025\context\dynamics\incorrect_only';
wrapper_avg_cell_type_traces(context_data_updated.deconv_interp,all_celltypes,mod_indexm,sig_mod_boot,mod_params.chosen_mice,savepath,'opto_deconv',plot_info);
wrapper_avg_cell_type_traces(context_data_updated.dff,all_celltypes,mod_indexm,sig_mod_boot,mod_params.chosen_mice,savepath,'opto_dff',plot_info);

%% calculate modulation index separatly for correct vs incorrect trials
mod_params = params.mod;
mod_params.mode = 'simple';
mod_params.savepath = fullfile(params.info.savepath, 'mod', mod_params.mod_type, mod_params.mode,'correct_only')

[mod_index_results_correct, sig_mod_boot_correct, mod_indexm_correct] = ...
    wrapper_mod_index_calculation(params.info, dff_st, mod_params.response_range, mod_params.mod_type, mod_params.mode, update_stim_trials_context,update_ctrl_trials_context,mod_params.nShuffles, mod_params.savepath);

mod_params.threshold_single_side = 0; mod_params.chosen_mice = 1:24;
sig_mod_boot_thr_corr = get_thresholded_sig_cells(params.info, mod_params, mod_indexm_correct, sig_mod_boot_correct, sorted_cells, all_celltypes, [],0);


mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm_correct,  sig_mod_boot_thr(:,3)', all_celltypes, params, mod_params.savepath);
save(fullfile( mod_params.savepath, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');

%repeat using incorrect trials
[update_stim_trials_context,update_ctrl_trials_context, updated_mouse_tr_context] = find_specified_VR_trials_in_context_trials(stim_trials_context, ctrl_trials_context, {'correct'},{0},true);
mod_params.savepath = fullfile(params.info.savepath, 'mod', mod_params.mod_type, mod_params.mode,'incorrect_only')

[mod_index_results_incorrect, sig_mod_boot_incorrect, mod_indexm_incorrect] = ...
    wrapper_mod_index_calculation(params.info, dff_st, mod_params.response_range, mod_params.mod_type, mod_params.mode, update_stim_trials_context,update_ctrl_trials_context,mod_params.nShuffles, mod_params.savepath);

mod_params.threshold_single_side = 0; mod_params.chosen_mice = 1:24;
sig_mod_boot_thr_incorr = get_thresholded_sig_cells(params.info, mod_params, mod_indexm_incorrect, sig_mod_boot_incorrect, sorted_cells, all_celltypes, [],0);


mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm_incorrect,  sig_mod_boot_thr(:,3)', all_celltypes, params, mod_params.savepath);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats');