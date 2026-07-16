addpath(genpath('C:\Code\Github\BassiRunyan2025'))
% Setup analysis parameters
%includes all datasets being analyzed, frame parameters, mod index
%parameters
params = experiment_config(); 
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;

%% Pool activity across mice
% neural data will be sound + ctrl or sound only trials!!!
[all_celltypes,active,passive,spont] =pool_activity_sounds_simple(params.info_updated.mouse_date,params.info_updated.serverid, [60,60]);
params.info_updated.active_all_trial_info = active.all_trial_info;
params.info_updated.passive_all_trial_info = passive.all_trial_info;

[num_cells, sorted_cells] = organize_pooled_celltypes(active.dff_st, all_celltypes); %gives index relative to all datasets
% save(fullfile(filename, 'sorted_cells.mat'), 'sorted_cells');

% Separate neural data into contexts (organizes original _st into cell arrays separated by
% context using mouse_context_trials)
%organized context_data.dff{context,mouse};
[context_data.dff,stim_trials_context,ctrl_trials_context] = organize_2context(active.dff_st,passive.dff_st,'context3_st',spont.dff_st);
[stim_info_combined,dff_st_combined] = combine_stim_info_dff_st(active.stim_info,passive.stim_info, active.dff_st,passive.dff_st,'stim_info3',spont.stim_info,'dff3',spont.dff_st);%(sound_context_data.active, sound_context_data.passive, sound_data.active.dff_st,sound_data.passive.dff_st);

[context_data.deconv,~,~] = organize_2context(active.deconv_st_nogap  ,passive.deconv_st_nogap  );
[~,deconv_st_combined] = combine_stim_info_dff_st(active, passive, active.deconv_st_nogap,passive.deconv_st_nogap);

filename = fullfile(params.info_updated.savepath_sounds, 'data_info')
save(fullfile(filename, "ctrl_trials_context.mat"),"ctrl_trials_context");
save(fullfile(filename, "stim_trials_context.mat"),"stim_trials_context");
save(fullfile(filename, "context_data.mat"),"context_data",'-v7.3');
save(fullfile(filename, "stim_info_combined.mat"),"stim_info_combined");

%% calculate mod index and get sig cells
base_dir = 'W:\Connie\results\Bassi2025\fig3\reviews\0thres\';
params.info_updated.data_type = 'dff';
mod_params_all = {'mod_sounds','mod_sounds','mod'};

for i = 1:3
mod_params = params.(mod_params_all{i}); %use 'prespose'/'separate'?
mod_params.mod_threshold = 0;
if i == 2
    mod_params.mod_type = 'prepost';
end
mod_params.savepath = fullfile(params.info_updated.savepath_sounds, 'mod', mod_params.mod_type, mod_params.mode)

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
mod_params.chosen_mice = 1:14
mod_params.mod_threshold = .1;%.1;
sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(params.info_updated, mod_params, prepost.mod(:,3), prepost.sig_mod_boot(:,3),sorted_cells,all_celltypes,[]);
noise.sig_cells = sig_mod_boot_thr_spont;
sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info_updated, mod_params, sound.mod, sound.sig_mod_boot,sorted_cells,all_celltypes,[]);
[combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', sound.mod);
sound.sig_cells = combined_sig_cells;

sound_to_plot = 1:6;
for sound_to_plot = 1
all_sounds = unique(params.info_updated.sound_type);
chosen_mice = find(strcmp(all_sounds{sound_to_plot},params.info_updated.sound_type)); %actually plotted!
params.info.chosen_mice = 1:length(chosen_mice);
base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\01thres_' all_sounds{sound_to_plot} '\']
% base_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\mod\01thres_all_sounds_combined\']

% get overlap of sig cells
contexts_to_compare = [1,2]; %[1:3];%[1,2]; %[1,2]; %[1:3];
overlap_labels = {'Active', 'Passive'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %

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
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
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
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice ,  noise.mod(chosen_mice,:),  noise.sig_cells(chosen_mice)', all_celltypes(1,chosen_mice), params, [base_dir 'ctrl\separate\sig_cells']);
save(fullfile(save_dir, 'mod_index_stats_datasets.mat'), 'mod_index_stats_datasets');

% make plots

% 2) Sound Index Plots
mod_params.min_cells = 0; % >0 so at least 1 modulated neuron per dataset

%%%% sig cells %%%%%%%%%%%
plot_info.y_lims = [-.4, .4];
% Set labels for plots.
plot_info.plot_labels = {'Sounds','Sounds'}; % Alternative could be {'Left Sounds','Right Sounds'}
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
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