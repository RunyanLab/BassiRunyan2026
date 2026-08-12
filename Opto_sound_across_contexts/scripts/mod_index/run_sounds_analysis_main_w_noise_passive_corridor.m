addpath(genpath('C:\Code\Github\BassiRunyan2025'))
% Setup analysis parameters
%includes all datasets being analyzed, frame parameters, mod index
%parameters
params = experiment_config(); 
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;
%%
[all_celltypes,active,passive,spont,passive_corridor] =pool_activity_sounds_vr_and_passive_corridor(params.info_updated.mouse_date,params.info_updated.serverid, [60,60]);

params.info_updated.active_all_trial_info = active.all_trial_info;
params.info_updated.passive_all_trial_info = passive.all_trial_info;
params.info_updated.passive_corridor_all_trial_info = passive_corridor.all_trial_info;

[num_cells, sorted_cells] = organize_pooled_celltypes(active.dff_st, all_celltypes); %gives index relative to all datasets
% save(fullfile(filename, 'sorted_cells.mat'), 'sorted_cells');

% Separate neural data into contexts (organizes original _st into cell arrays separated by
% context using mouse_context_trials)
%organized context_data.dff{context,mouse};
[context_data.dff,stim_trials_context,ctrl_trials_context] = organize_2context(active.dff_st,passive.dff_st,'extra_contexts',{spont.dff_st,passive_corridor.dff_st});
[stim_info_combined,dff_st_combined] = combine_stim_info_dff_st(active.stim_info,passive.stim_info, active.dff_st,passive.dff_st,'extra_stim_info',{spont.stim_info,passive_corridor.stim_info},'extra_dff',{spont.dff_st,passive_corridor.dff_st});%(sound_context_data.active, sound_context_data.passive, sound_data.active.dff_st,sound_data.passive.dff_st);
%%
% mod index!
base_dir = 'W:\Connie\results\Bassi2025\fig3\reviews\0thres\passive_corridor\';%'W:\Connie\results\Bassi2025\fig3\reviews\0thres\';
params.info_updated.data_type = 'dff';
mod_params_all = {'mod_sounds','mod_sounds','mod'};

for i = 1:3
mod_params = params.(mod_params_all{i}); %use 'prespose'/'separate'?
mod_params.mod_threshold = 0;
if i == 2
    mod_params.mod_type = 'prepost';
end
mod_params.savepath = fullfile(base_dir, 'mod', mod_params.mod_type, mod_params.mode); %params.info_updated.savepath_sounds

[mod_index_results, sig_mod_boot, mod_indexm] = ...
    wrapper_mod_index_calculation_white_noise(params.info_updated, dff_st_combined, mod_params.response_range, mod_params.mod_type, mod_params.mode, stim_trials_context, ctrl_trials_context,mod_params.nShuffles,  mod_params.savepath);

% get sig cells

mod_params.chosen_mice = 1:size(mod_indexm,1);

    if strcmp(mod_params.mod_type,'prepost_sound')
        
        sound.sig_mod_boot = sig_mod_boot;
        sound.results = mod_index_results;
        sound.mod = mod_indexm;
        sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[base_dir 'prepost_sound\separate']);
    
        [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod);
        sound.sig_cells = combined_sig_cells;
        save(fullfile([base_dir 'prepost_sound\separate'], 'sound.mat'), 'sound');
    elseif strcmp(mod_params.mod_type,'prepost')
        prepost.sig_mod_boot = sig_mod_boot;
        prepost.results = mod_index_results;
        prepost.mod = mod_indexm;
        sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod, prepost.sig_mod_boot,sorted_cells,all_celltypes,[base_dir 'prepost\separate']);
    
        [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', prepost.mod);
        prepost.sig_cells = combined_sig_cells;
        save(fullfile([base_dir 'prepost\separate'], 'prepost.mat'), 'prepost');
    
    
    else %stim (or white noise+ sound) vs control (sound)
        noise.sig_mod_boot = sig_mod_boot;
        noise.results = mod_index_results;
        noise.mod = mod_indexm;
        sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells,all_celltypes,[base_dir 'ctrl\separate']);
        noise.sig_mod_boot_thr = sig_mod_boot_thr_spont; %get white noise neurons from pre-post
        noise.sig_cells = sig_mod_boot_thr_spont; 
        save(fullfile([base_dir 'ctrl\separate'], 'noise.mat'), 'noise');

    end
end
%% general plots
plot_info.line_colors = [0.3,0.2,0.6 ; 1,0.7,0];
plot_info.plot_mode = 'stim';% stim ctrl or both
plot_info.avg_traces = 1;
plot_info.plot_avg = 1;
context_to_plot = [3];
dataset = 1;
 wrapper_mod_index_single_plots_noise(params.info_updated, dff_st_combined, stim_trials_context, ctrl_trials_context, sound.results,...
     [dataset], context_to_plot,noise.sig_cells{dataset},1, 'opto',plot_info); %noise.sig_cells{dataset}


% plot_info.line_colors = [0.3,0.2,0.6 ; 1,0.7,0];
% plot_info.plot_mode = 'ctrl';% stim ctrl or both
% plot_info.avg_traces = 1;
% plot_info.plot_avg = 1;
% context_to_plot = [2];
% dataset = 6;
% 
% params.info_updated.savepath = [params.info_updated.savepath '\original_datasets\'];
%  wrapper_mod_index_single_plots_noise(params.info_updated, dff_st_combined, stim_trials_context, ctrl_trials_context,og_sound.results,...
%      [dataset], context_to_plot,og_sound.sig_cells{dataset},1, 'sound',plot_info); %noise.sig_cells{dataset}
%% decide what dataset to use

mod_params.chosen_mice = 1:8;
mod_params.mod_threshold = 0;
sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells,all_celltypes,[]);
noise.sig_cells = sig_mod_boot_thr_spont;
sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[]);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod);
sound.sig_cells = combined_sig_cells;
plot_info.behavioral_contexts = {'Active','Passive','Spont','Passive Corridor'};
for sound_to_plot = 1%:2
    sound_to_plot
all_sounds = unique(params.info_updated.sound_type);
if sound_to_plot == 8
    base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\passive_corridor\' strrep(num2str(mod_params.mod_threshold), '.', '') 'thres_all_sounds_combined\']
    chosen_mice = mod_params.chosen_mice;
    params.info.chosen_mice = mod_params.chosen_mice;
else
        
    chosen_mice = 1:8;%find(strcmp(all_sounds{sound_to_plot},params.info_updated.sound_type)); %actually plotted!
    params.info.chosen_mice = 1:length(chosen_mice);
    base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\passive_corridor\' strrep(num2str(mod_params.mod_threshold), '.', '') 'thres_' all_sounds{sound_to_plot} '\']
end
% base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\01thres_all_sounds_combined\']

% get overlap of sig cells

% ORGANIZE MODULATION INDICES AND CELL TYPE INDICES ACROSS DATASETS
% [~, ~, ~, ~, celltypes_ids] = ...
%     organize_sig_mod_index_contexts_celltypes(mod_params.chosen_mice , mod_indexm', sig_mod_boot_thr, all_celltypes,plot_info.celltype_names);


contexts_to_compare = [1,2]; 
overlap_labels = {'Sound Only','White Noise Only', 'Both','Unmodulated'}; 
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_cells(chosen_mice),noise.sig_cells(chosen_mice),sound.mod(chosen_mice,:), contexts_to_compare);
sound_repeat_colors = [0.5 0.5 0.5
                       [173 185 227] / 255
                        [163 121 201] / 255
                            0.3,0.2,0.6];
savepath_fig2 = base_dir;
if size(percent_cells_per_dataset,1) ==1
    plot_sig_overlap_pie(percent_cells_per_dataset*100, overlap_labels, savepath_fig2, contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',sound_repeat_colors);
else
    plot_sig_overlap_pie(mean(percent_cells_per_dataset)*100, overlap_labels, savepath_fig2, contexts_to_compare,'save_string','sd_color','SD',[percent_stats.sig1.sd,percent_stats.sig2.sd,percent_stats.both.sd,percent_stats.unmod.sd],'Color',sound_repeat_colors);
end
% make plots

%Compare white noise+sound vs sound alone
mod_params.min_cells = 0;
plot_info.y_lims = [-.3, .3];
params.plot_info = plot_info;
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
% plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
params.plot_info = plot_info;
save_dir = [base_dir 'ctrl\separate'];
plot_info.type = 'opto';
mod_params.results = noise.results;
mod_params.chosen_mice = chosen_mice;

%generate average plots
savepath = params.info_updated.savepath;
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,noise.mod,prepost.sig_mod_boot,mod_params, [base_dir 'ctrl\separate\sig_cells'],'opto_dff',plot_info,prepost.mod);
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),3,1)';
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,noise.mod,all_cells,mod_params, [base_dir 'ctrl\separate'],'opto_dff',plot_info,prepost.mod);

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
%all neurons
params.min_cells = 0;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice ,  noise.mod(chosen_mice,:),  [], all_celltypes(1,chosen_mice), params, [base_dir 'ctrl\separate']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');


%sig neurons!
params.min_cells = 0;
if ~isempty([noise.sig_cells{chosen_mice}])
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice ,  noise.mod(chosen_mice,:),  noise.sig_cells(chosen_mice)', all_celltypes(1,chosen_mice), params, [base_dir 'ctrl\separate\sig_cells']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
end
% make plots

% 2) Sound Index Plots
mod_params.min_cells = 0; % >0 so at least 1 modulated neuron per dataset

%%%% sig cells %%%%%%%%%%%
plot_info.y_lims = [-.4, .4];
% Set labels for plots.
plot_info.plot_labels = {'Sounds','Sounds'}; % Alternative could be {'Left Sounds','Right Sounds'}
% plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
plot_info.type = 'sounds';
params.plot_info = plot_info;
params.string = 'Sounds';
save_dir = [base_dir 'prepost_sound\separate'];
mod_params.results = sound.results;


savepath = params.info_updated.savepath;
mod_params.results = mod_index_results;
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,sound.mod,sound.sig_mod_boot,mod_params, [base_dir 'prepost_sound\separate\sig_cells'],'sound_dff',plot_info);
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),3,1)';
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,sound.mod,all_cells,mod_params, [base_dir 'prepost_sound\separate'],'sound_dff',plot_info);

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
%all neurons
params.min_cells = 0;
params.plot_info.y_lims = [-.1,.1];
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice,  sound.mod(chosen_mice,:),  [], all_celltypes(1,chosen_mice), params, [base_dir 'prepost_sound\separate']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');

%sig neurons!
params.min_cells = 0;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice,  sound.mod(chosen_mice,:),  sound.sig_cells(chosen_mice), all_celltypes(1,chosen_mice), params, [base_dir 'prepost_sound\separate\sig_cells']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
end

%% compare active and passive corridor only!
mod_params.chosen_mice = 1:4;
mod_params.mod_threshold = 0.1;
save_string = 'passive_corridor_passive_KN8';
context_to_test = [1,2];
passive_string = 'Passive';
% add colors:
plot_info.colors_celltypes_3contexts = [0.1600    0.4000    0.2400
0.5400    0.8200    0.6400
0.4590    0.6970    0.5440    % slightly darker repeat

0.1300    0.2400    0.5100
0.5500    0.6500    0.8900
0.4675    0.5525    0.7565    % slightly darker repeat

0.5000    0.0600    0.1000
0.9200    0.3600    0.4100
0.7820    0.3060    0.3485]    % slightly darker repeat]

sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells,all_celltypes,[]);
noise.sig_cells = sig_mod_boot_thr_spont;
sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[]);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod);
sound.sig_cells = combined_sig_cells;
plot_info.behavioral_contexts = {'Active','Passive','Spont','Passive Corridor'};
for sound_to_plot = 1%:2
    sound_to_plot
all_sounds = unique(params.info_updated.sound_type);
if sound_to_plot == 8
    base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\' save_string '\' strrep(num2str(mod_params.mod_threshold), '.', '') 'thres_all_sounds_combined\']
    chosen_mice = mod_params.chosen_mice;
    params.info.chosen_mice = mod_params.chosen_mice;
else
        
    chosen_mice = mod_params.chosen_mice;%1:8;%find(strcmp(all_sounds{sound_to_plot},params.info_updated.sound_type)); %actually plotted!
    params.info.chosen_mice = 1:length(chosen_mice);
    base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\' save_string '\' strrep(num2str(mod_params.mod_threshold), '.', '') 'thres_' all_sounds{sound_to_plot} '\']
end
% base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\01thres_all_sounds_combined\']

% get overlap of sig cells
% ORGANIZE MODULATION INDICES AND CELL TYPE INDICES ACROSS DATASETS
% [~, ~, ~, ~, celltypes_ids] = ...
%     organize_sig_mod_index_contexts_celltypes(mod_params.chosen_mice , mod_indexm', sig_mod_boot_thr, all_celltypes,plot_info.celltype_names);


contexts_to_compare = [1,2]; 
overlap_labels = {'Sound Only','White Noise Only', 'Both','Unmodulated'}; 
[percent_cells, percent_cells_per_dataset,percent_stats] = calculate_sig1_vs_sig2_overlap(sound.sig_cells(1:length(chosen_mice)),noise.sig_cells(1:length(chosen_mice)),sound.mod(chosen_mice,:), contexts_to_compare);
sound_repeat_colors = [0.5 0.5 0.5
                       [173 185 227] / 255
                        [163 121 201] / 255
                            0.3,0.2,0.6];
savepath_fig2 = base_dir;
% make plots

%Compare white noise+sound vs sound alone
mod_params.min_cells = 0;
plot_info.y_lims = [-.3, .3];
params.plot_info = plot_info;
% Set labels for plots.
plot_info.plot_labels = {'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
% plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
params.plot_info = plot_info;
save_dir = [base_dir 'ctrl\separate'];
plot_info.type = 'opto';
mod_params.results = noise.results;
mod_params.chosen_mice = chosen_mice;

%generate average plots
savepath = params.info_updated.savepath;
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,noise.mod,prepost.sig_mod_boot,mod_params, [base_dir 'ctrl\separate\sig_cells'],'opto_dff',plot_info,prepost.mod,context_to_test);
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),3,1)';
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,noise.mod,all_cells,mod_params, [base_dir 'ctrl\separate'],'opto_dff',plot_info,prepost.mod,context_to_test);

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
%all neurons
params.plot_info.behavioral_contexts = {'Active',passive_string};
params.min_cells = 0;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice ,  noise.mod(chosen_mice,context_to_test),  [], all_celltypes(1,chosen_mice), params, [base_dir 'ctrl\separate']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');


%sig neurons!
params.min_cells = 0;
if ~isempty([noise.sig_cells{1:length(chosen_mice)}])
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice ,  noise.mod(chosen_mice,context_to_test),  noise.sig_cells(1:length(chosen_mice))', all_celltypes(1,chosen_mice), params, [base_dir 'ctrl\separate\sig_cells']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
end
% make plots

% 2) Sound Index Plots
mod_params.min_cells = 0; % >0 so at least 1 modulated neuron per dataset
plot_info.behavioral_contexts = {'Active','Passive','Spont','Passive Corridor'};

%%%% sig cells %%%%%%%%%%%
plot_info.y_lims = [-.4, .4];
% Set labels for plots.
plot_info.plot_labels = {'Sounds','Sounds'}; % Alternative could be {'Left Sounds','Right Sounds'}
% plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
plot_info.type = 'sounds';
params.plot_info = plot_info;
params.string = 'Sounds';
save_dir = [base_dir 'prepost_sound\separate'];
mod_params.results = sound.results;


savepath = params.info_updated.savepath;
mod_params.results = mod_index_results;
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,sound.mod,sound.sig_mod_boot,mod_params, [base_dir 'prepost_sound\separate\sig_cells'],'sound_dff',plot_info,context_to_test);
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),3,1)';
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,sound.mod,all_cells,mod_params, [base_dir 'prepost_sound\separate'],'sound_dff',plot_info,context_to_test);

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
%all neurons
params.plot_info.behavioral_contexts = {'Active',passive_string};
params.min_cells = 0;
params.plot_info.y_lims = [-.1,.1];
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice,  sound.mod(chosen_mice,context_to_test),  [], all_celltypes(1,chosen_mice), params, [base_dir 'prepost_sound\separate']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');

%sig neurons!
params.min_cells = 0;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice,  sound.mod(chosen_mice,context_to_test),  sound.sig_cells(1:length(chosen_mice)), all_celltypes(1,chosen_mice), params, [base_dir 'prepost_sound\separate\sig_cells']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');
end


%% check pre-stim activity
chosen_mice = [1:8];
mod_params.chosen_mice = [1:11];
mod_params.mod_threshold = 0.1;
sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells,all_celltypes,[]);
noise.sig_cells = sig_mod_boot_thr_spont;
sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[]);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod);
sound.sig_cells = combined_sig_cells;
savepath = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\passive_corridor_passive\' strrep(num2str(mod_params.mod_threshold), '.', '') '\pre_activity\'];%'W:\Connie\results\Bassi2025\fig4\functional_pre_traces\';% '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.


min_cells = 0;
[dff_response,~] = unpack_context_mouse_celltypes(context_data.dff,[],all_celltypes,min_cells,[1:11]); %context_data.deconv_interp

% Setup parameters
avg_prepost_params = struct(...
    'pre_frames', 51:60, ...
    'post_frames',63:93, ...
    'trial_type', 'stim', ...
    'mode', 'all',...
    'data_type', 'dff'); %separate, pooled or all (to separate or pool left vs right trials)

% NAMING CONVENTION - avg_post_ctrl = post sound only response;avg_pre_ctrl = pre sound only response;
%avg_post = post stim+sound response, avg_pre = pre stim+sound response

[~,avg_pre,avg_ctrl_pre, avg_post,avg_ctrl_post,~,~,~,~,~,~,~,~]  = ...
    wrapper_prepost_averaging_whitenoise(params.info_updated, dff_response,stim_trials_context,ctrl_trials_context, all_celltypes, avg_prepost_params, []);

% [diff_stim, diff_pre_stim, diff_pre_ctrl] = calculate_avg_differences(avg_pre,avg_ctrl_pre,avg_post,avg_ctrl_post);

% make plots
% 1) traces
plot_info.type = 'engagement'; %'sound'

[pooled_cell_types,plot_info.pooled_names,plot_info.pooled_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, noise.sig_cells', noise.mod, {'sound','opto','both','unmodulated'},chosen_mice,plot_info, 1);
plot_info.pooled_names = {{'Sound';'modulated'},{'White Noise';'modulated'},{'S & WN';'modulated'},'Unmodulated'}
plot_info.trace_ylims = [0.1,0.5];
[traces_mean,dataset_ids] = wrapper_avg_pooled_type_traces(context_data.dff,pooled_cell_types,[],chosen_mice,savepath,'sound_dff_functional_types_-2to0_',plot_info,mod_params.chosen_mice,[1,4]);
% table_fig3_evoked = make_stats_tables_evoked(traces_mean,[], 'avg_traces', {'Sound', 'White Noise', 'S & WN','S & WN'},51:60, savepath); %save stats table

%2) scatter with lines avg
plot_info = plotting_config(); %plotting params
[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, noise.sig_cells', noise.mod, {'sound','opto','both','unmodulated'},chosen_mice,plot_info, 1);
[preavg_index_by_dataset,~] = unpack_modindexm(avg_pre,[],pooled_cell_types,chosen_mice);
params.plot_info = plot_info;
params.plot_info.behavioral_contexts = {'Active','Passive Corridor'};
preavg_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(savepath, preavg_index_by_dataset(:,[1,4],:),chosen_mice,...
          params.plot_info, [.075,.4],0,'Pre Mean (\DeltaF/F)');

%reset plot info
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;

%% redo axis plots

split_params.divisions = 4; split_params.random_or_not = 0; split_params.splits = 4;
choose_params.chosen_celltypes = 1; choose_params.chosen_datasets = 1:8;
params.info_updated.active_all_trial_info = active.all_trial_info;
testing = [1:8];
dd = 0;
for d = 1:8; %choose_params.chosen_datasets
    dd =dd+1;
    params.info_updated.active_all_trial_info(dd).ctrl = params.info_updated.active_all_trial_info(d).sound_only;
end
split_params.active_trial_info = params.info_updated.active_all_trial_info(testing); 
[axis_results,proj,proj_ctrl,proj_norm,proj_norm_ctrl, weights,trial_corr_context,percent_correct,act,act_norm_ctrl,act_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative,sound_concat,stim_concat] = ...
    find_axis_updated_specify_splits(context_data.dff(:,testing ), choose_params, all_celltypes(testing),[],split_params); %,{50:59,63:73}

save_dir = 'W:\Connie\results\Bassi2025\fig4\updated_4cv_combined_eng\reviews\1000ms_4sweeps\';%'V:\Connie\results\opto_sound_2025\context\axis_lme_plots_updated\dff';

%% plot mean projection traces across datasets (finds means across splits first
celltype = 1; %4 = all
plot_proj_meansplits_traces([choose_params.chosen_datasets],proj_norm, 'spont_true',celltype, [61:62],[0,0,0;.5,.5,.5],{'Irrelevant Only'},save_dir,'xlabel','Time from sound onset (s)','contexts',1);
plot_proj_meansplits_traces([choose_params.chosen_datasets],proj_norm_ctrl, 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from sound onset (s)');
plot_proj_meansplits_traces([choose_params.chosen_datasets],proj_norm_ctrl, 'context',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stimulus onset (s)');
plot_proj_meansplits_traces([choose_params.chosen_datasets],proj_norm, 'stim',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir,'xlabel','Time from stim onset (s)');

% plot_proj_mean_traces([1:24],squeeze(proj_ctrl(1,:,:,:)), 'sound',celltype, [61:62],[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 50:59;
bin_edges = [-2:0.4:2];%
hist_stats =  histogram_axis_across_contexts_splits([choose_params.chosen_datasets],proj_norm_ctrl, 'context',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 63:93;
bin_edges = [-2:0.4:2];%
hist_stats =  histogram_axis_across_contexts_splits([choose_params.chosen_datasets],proj_norm_ctrl, 'Sound',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

frames_to_avg = 63:93;
bin_edges = [-1.5:0.4:2.5];%
hist_stats =  histogram_axis_across_contexts_splits([choose_params.chosen_datasets],proj_norm, 'Stim',celltype, bin_edges,frames_to_avg,[0,0,0;.5,.5,.5],{'Active','Passive'},save_dir);

% model
frame_range_pre= 50:59;
frame_range_post = 63:93;
%sound (predicted) vs engagement axis
[lm_sound,tbl_sound,proj_all_sound,engagement_proj_all_sound,context_all_sound,corr_mean, corr_all, corr_stats] = ...
    linear_regression_corr_model(proj_norm_ctrl, 'Sound',celltype,frame_range_pre,frame_range_post,[1:2]);
%stim(predicted) vs engagement axis
[lm_stim,tbl_stim,proj_all_stim,engagement_proj_all_stim,context_all_stim,corr_mean_stim, corr_all_stim,corr_stats_stim] = ...
    linear_regression_corr_model(proj_norm, 'Stim',celltype,frame_range_pre,frame_range_post,[1:2]);

%irrelevant only axis
[lm_irrelevant_only,tbl_irrelevant_only,proj_all_irrelevant_only,engagement_proj_all_irrelevant_only,context_all_irrelevant_only,corr_mean_irrelevant_only, corr_all_stim,corr_stats_irrelevant_only] = ...
    linear_regression_corr_model(proj_norm, 'Spont',celltype,frame_range_pre,frame_range_post,[1:2]);

% % % %sound(predicted) vs stim
% [lm_sound_stim,tbl_sound_stim,proj_all_sound_stim,engagement_proj_all_sound_stim,context_all_sound_stim,corr_mean_sound_stim, corr_all_sound_stim,corr_stats_sound_stim] = ...
%     linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[1],'Stim');
% 
% [lm_sound_stim_pass,tbl_sound_stim_pass,~,~,context_all_sound_stim_pass,corr_mean_sound_stim_pass, corr_all_sound_stim_pass,corr_stats_sound_stim_pass] = ...
%     linear_regression_corr_model(proj_norm,'Sound' ,celltype,frame_range_post,frame_range_post,[2],'Stim');

% scatter plots of trials and linear regression lines
% plot_linear_regression_lines(lme_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement',[corr_mean,corr_stats.p]);
plot_linear_regression_lines(lm_sound,tbl_sound,context_all_sound,'Sound Projection',save_dir,'Engagement');
plot_linear_regression_lines(lm_stim,tbl_stim,context_all_stim,'Stim Projection',save_dir,'Engagement');
plot_linear_regression_lines(lm_irrelevant_only,tbl_irrelevant_only,context_all_irrelevant_only,'Irrelevant Only Projection',save_dir,'Engagement');
