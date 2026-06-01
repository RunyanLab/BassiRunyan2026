addpath(genpath('C:\Code\Github\BassiRunyan2025'))
% Setup analysis parameters
%includes all datasets being analyzed, frame parameters, mod index
%parameters
params = experiment_config(); 
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;

current_data = 'opto'; %or 'sound
%% Pool activity across mice
% neural data will be sound + ctrl or sound only trials!!!
if strcmp(current_data,'sound') 
    mod_params = params.mod_sounds; 
    [all_celltypes, sound_data, sound_context_data, sound2_context_data, sound3_context_data]  = ...
    pool_activity_sounds(params.info.mouse_date, params.info.serverid, [60,60]); %last number is which sound repeat to align to
    string = 'sounds/';
    [context_data.dff,stim_trials_context,ctrl_trials_context] = organize_2context(sound_data.active.dff_st,sound_data.passive.dff_st);
    [stim_info_combined,dff_st_combined] = combine_stim_info_dff_st(sound_context_data.active, sound_context_data.passive, sound_data.active.dff_st,sound_data.passive.dff_st);
    [context_data.deconv,~,~] = organize_2context(sound_data.active.deconv_st_interp,sound_data.passive.deconv_st_interp);
    [~,deconv_st_combined] = combine_stim_info_dff_st(sound_context_data.active, sound_context_data.passive, sound_data.active.deconv_st_interp,sound_data.passive.deconv_st_interp);

else
    mod_params = params.mod; 
    [all_celltypes, dff_st, deconv_st, stim_info, ...
     mouse_context_tr, deconv_st_interp, alignment_frames] = ...
        pool_activity(params.info.mouse_date, params.info.serverid, params.info.path_string, true, [60,60],1);
    string = 'opto/';

    [context_data.dff,stim_trials_context,ctrl_trials_context] = separate_structure_2context(dff_st,mouse_context_tr,stim_info);%  context.dff{context,mouse}
    [context_data.deconv] = separate_structure_2context(deconv_st,mouse_context_tr,stim_info);%  context.dff{context,mouse}
    [context_data.deconv_interp] = separate_structure_2context(deconv_st_interp,mouse_context_tr,stim_info);%  context.dff{context,mouse}

end
% Process cell types
[num_cells, sorted_cells] = organize_pooled_celltypes(dff_st, all_celltypes); %gives index relative to all datasets


filename = fullfile('W:\Connie\results\Bassi2025\fig3', ['/data_info/' string] )
mkdir(filename)
save(fullfile(filename, "ctrl_trials_context.mat"),"ctrl_trials_context");
save(fullfile(filename, "stim_trials_context.mat"),"stim_trials_context");
save(fullfile(filename, "context_data.mat"),"context_data",'-v7.3');
save(fullfile(filename, "dff_st.mat"),"dff_st",'-v7.3');

%% Calculate modulation indices
%use 'prespose'/'separate'?
mod_params.savepath = fullfile('W:\Connie\results\Bassi2025\fig3\',string,'\', 'mod', [mod_params.mod_type '_60before\'], mod_params.mode)

% mod_params.savepath = 'W:\Connie\results\Bassi2025\fig3\multiple_sound_repeats\3\mod\prepost_sound\separate';
params.info.data_type = 'dff';
%{[63:93];[55:59]} %mod_params.response_range
[mod_index_results, sig_mod_boot, mod_indexm] = ...
    wrapper_mod_index_calculation(params.info, dff_st,{[63:93];[1:59]} , mod_params.mod_type, mod_params.mode, stim_trials_context, ctrl_trials_context,mod_params.nShuffles,  mod_params.savepath);
% tested [1:59] and [30:59]
%% using own repeat's sig cells
%2) Mod Index Plots
mod_params.min_cells = 0; % >0 so at least 1 modulated neuron per dataset
params.min_cells = 0;
savepath_fig2 = mod_params.savepath
mod_params.results = mod_index_results;

% get sig cells
mod_params.mod_threshold = 0.1;
plot_info.trace_ylims = [0.14,.3];
plot_info.type = string;
param_sets_traces{1,1}.mod_threshold = mod_params.mod_threshold;


sig_mod_boot_thr = plot_pie_thresholded_mod_index(params.info, mod_params, mod_indexm, sig_mod_boot, sorted_cells,all_celltypes, mod_params.savepath);
if strcmp('sound',current_data)
    [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot_thr(:,1)', sig_mod_boot_thr(:,2)', mod_indexm);
    [~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,mod_indexm,sig_mod_boot_thr,mod_params,savepath_fig2,[string '_dff'],plot_info);

else
    load('W:\Connie\results\Bassi2025\data\opto.mat')
    combined_sig_cells = opto.sig_cells';
%     [~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,mod_indexm,sig_mod_boot_thr,mod_params,savepath_fig2,[string '_dff'],plot_info,opto.mod_prepost);

end



plot_info.y_lims = [-.2, .35];
params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(mod_params.chosen_mice, mod_indexm, combined_sig_cells, all_celltypes, params, savepath_fig2);

%%
%%%% using all cells %%%%%%%%%%%
savepath_fig2 = [mod_params.savepath '\all_cells\'];

%datasets
plot_info.y_lims = [-.2, .2];params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(params.info.chosen_mice, mod_indexm, [], all_celltypes, params, savepath_fig2);
%avg traces
plot_info.y_lims = [-.2, .3];
plot_info.trace_ylims = [0.14,0.3];
params.plot_info = plot_info;
mod_params.mod_threshold =0;
mod_params.threshold_single_side =1;
[num_cells, ~] = organize_pooled_celltypes(context_data.dff, all_celltypes);
all_cells =  repmat(arrayfun(@(n) 1:n, num_cells, 'UniformOutput', false),2,1)';
%avg traces
[~,~] = wrapper_avg_cell_type_traces(context_data.dff,all_celltypes,mod_indexm,all_cells,mod_params,savepath_fig2,[string '_dff']',plot_info);
