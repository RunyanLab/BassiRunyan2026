[speed_params,speed_params_single] = get_speed_params(1); %control_or_opto
params = experiment_config(); 
plot_info = plotting_config(); %plotting params
params.plot_info = plot_info;
speed_params.chosen_mice = [1:25];
plot_info.plot_labels = {'Stim','Ctrl'};%{'Sounds','Sounds'}; %{'Stim','Ctrl'}; % Alternative could be {'Left Sounds','Right Sounds'}
mod_params.mod_type = 'simple';

if contains(plot_info.plot_labels,'Stim')
    stim_info_to_use = stim_info; %stim_info_combined or stim_info
    neural_data_to_use = dff_st; %dff_st_combined or dff_st
    mod_to_use = 'mod'; %'mod_sounds' or 'mod'
    mod_params = params.(mod_to_use); %use 'prespose'/'separate'?
    save_to_use = params.info.savepath; %params.info.savepath or savepath_sounds
    %load previous significant neurons to compare the exact neruons
    load('W:\Connie\results\Bassi2025\data\opto.mat');
    sig_mod_boot_thr_specified = opto.sig_cells'; % sig_mod_boot_thr_spont = plot_pie_thresholded_mod_index(info, mod_params, mod_indexm(:,3), sig_mod_boot(:,3), sorted_cells,fullfile(mod_params.savepath,'spont_sig'));
    speed_params.chosen_mice = [1:24];
else
    stim_info_to_use = stim_info_combined; %stim_info_combined or stim_info
    neural_data_to_use = dff_st_combined; %dff_st_combined or dff_st
    mod_to_use = 'mod_sounds'; %'mod_sounds' or 'mod'
    mod_params = params.(mod_to_use); %use 'prespose'/'separate'?
    save_to_use = params.info.savepath_sounds; %params.info.savepath or savepath_sounds
    %load previous significant neurons to compare the exact neruons
    load('W:\Connie\results\Bassi2025\data\sound.mat');
    sig_mod_boot_thr_specified = sound.sig_cells;
    speed_params.chosen_mice = [1:25];
end

%% Get aligned velocity
speed_params.frames_before_event = 50; %in previous iterations these numbers just refered to the total number of frames aligned to (not what was averaged)
speed_params.frames_after_event = 60;
mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound(speed_params.chosen_mice,params.info.mouse_date,params.info.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info_to_use); %using ctrl and sound only trials
[mouse_vel_context,mouse_vel_context_roll,mouse_vel_context_pitch,mouse_acc_context,general_stats] = speed_cdf_across_contexts([],mouse_vel_aligned_sounds,plot_info,stim_trials_context,ctrl_trials_context,speed_params.chosen_mice,speed_params.frames_before_event:speed_params.frames_after_event); %50:60

use_abs = 1; %take the absolute value or not (needed for roll for example)
%make nice cdf plots
avg_speed_axis_data = organize_speed_cdf_data( ...
    mouse_vel_context, ...
    mouse_acc_context, ...
    mouse_vel_context_roll, ...
    mouse_vel_context_pitch, ...
    [1:length(mouse_vel_context)], ...
    use_abs);

save_data_directory = 'W:\Connie\results\Bassi2025\fig3\running_updated';
custom_bins.Pitch = 0:2:60;
custom_bins.Roll = 0:2:40;
custom_bins.Both = 20:2:60;
custom_bins.Acceleration = 0:0.1:5;
general_stats_speed = cdf_speed_avg_across_contexts(avg_speed_axis_data, speed_params,save_data_directory, 'movement_types',{'Pitch', 'Roll', 'Both', 'Acceleration'}, 'bin_struct', custom_bins);
%% find trials within specified speed_range (can use roll or pitch if given
%as inputs
speed_range = [0,10];
[speed_trials_stim,speed_trials_ctrl,bad_datasets] = find_speed_trials(mouse_vel_context,speed_range,stim_trials_context,ctrl_trials_context); %finds trials within certain speed range
if ~isempty(bad_datasets)
    good_datasets = setdiff(speed_params.chosen_mice,bad_datasets);
    
else
    good_datasets = speed_params.chosen_mice;
end
%% FIND MOD INDEX USING SPECIFIC TRIALS
mod_params = params.(mod_to_use); %use 'prespose'/'separate'?
mod_params.mode = 'simple';
params.info.data_type = 'dff';
mod_params.savepath = fullfile(save_to_use, 'mod', mod_params.mod_type, mod_params.mode, 'roll0to10')

[mod_index_results_specified, sig_mod_boot_specified, mod_indexm_specified] = ...
    wrapper_mod_index_calculation(params.info, neural_data_to_use, mod_params.response_range, mod_params.mod_type, mod_params.mode, stim_trials_context, ctrl_trials_context,mod_params.nShuffles,mod_params.savepath, speed_trials_stim, speed_trials_ctrl);
%% MAKE PLOTS USING NEW MOD INDEX
mod_params.mod_threshold = .1;% 0 is no threshold applied
% Make plots of modulation index across contexts/cell types
% Set y-axis limits for the plots.
plot_info.y_lims = [-.4, .4];
% Set labels for plots.
params.plot_info = plot_info;
params.info.chosen_mice = good_datasets;
%save directory
save_dir = [mod_params.savepath];% '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.

% generate plots
plot_info.y_lims = [-.2, .5];
% Set labels for plots.
plot_info.behavioral_contexts = {'Active','Passive'}; %decide which contexts to plot
params.plot_info = plot_info;
params.info.chosen_mice = good_datasets;
params.min_cells = 0;

%save directory
save_dir = [mod_params.savepath];% '/spont_sig'];% '/spont_sig']; %[info.savepath '/mod/' mod_params.mod_type '/spont_sig']; % Set directory to save figures.

% mod_index = cell(25,2);
% 
% mod_index(good_datasets,:) = mod_indexm_specified;

%generates heatmaps, cdf, box plots, scatter of abs(mod _index)
mod_index_stats_datasets = generate_mod_index_plots_datasets(good_datasets,mod_indexm_specified, sig_mod_boot_thr_specified, all_celltypes, params, save_dir);
S = unwrap_cells_in_struct(mod_index_stats_datasets);
table_speed = struct2table_recursive(S,'datasets',{'bootstat','ci'});
save(fullfile(save_dir, strcat('table_speed.mat')), 'table_speed');
writetable(table_speed, fullfile(save_dir, strcat('table_speed.csv')));

%%%% using all cells %%%%%%%%%%%
savedir2 = [save_dir '\all_cells\'];
plot_info.y_lims = [-.2, .2];params.plot_info = plot_info;
mod_index_stats_datasets = generate_mod_index_plots_datasets(good_datasets, mod_indexm_specified, [], all_celltypes, params, savedir2);
S = unwrap_cells_in_struct(mod_index_stats_datasets);
table_speed = struct2table_recursive(S,'datasets',{'bootstat','ci'});
save(fullfile(savedir2, strcat('table_speed.mat')), 'table_speed');
writetable(table_speed, fullfile(savedir2, strcat('table_speed.csv')));

