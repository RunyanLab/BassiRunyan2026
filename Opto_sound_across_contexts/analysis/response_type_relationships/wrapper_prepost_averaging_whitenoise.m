function [avg_results,avg_pre,avg_ctrl_pre, avg_post,avg_ctrl_post,avg_pre_left,avg_ctrl_pre_left,avg_post_left,avg_ctrl_post_left,avg_pre_right,avg_ctrl_pre_right,avg_post_right,avg_ctrl_post_right]  = wrapper_prepost_averaging_whitenoise(info, neural_structure,stim_trials_context,ctrl_trials_context, all_celltypes, params, savepath)
% Wrapper function to compute trial-averaged responses across datasets and
% contexts separating trials according to params 
% NOTE: if doing stim mode, the 3rd context is spont meaning there are no
% left or right trials so it will compute averages using all available stim
% and control trials
%
% Inputs:
%   info            - Structure with dataset information (e.g., info.mouse_date)
%   neural_structure- Cell array of neural data for each dataset
%   trial_info      - Structure with trial information for each context
%   params         - Structure with fields:
%                    .data_type     -'dff' or 'deconv' (necessary to
%                    determine how to calculate avg vs est. spike rate)
%                    .pre_frames
%                    .post_frames
%                    .trial_types    - 'stim', 'sounds'
%                    .mode          - 'pooled' or 'separate'
%                    .savepath      - Where to save results
%
% Outputs:
%   avg_results          - Combined results across datasets
%   avg_results_by_dataset - Cell array of results for each dataset

% Initialize storage
nDatasets = length(info.mouse_date);
nContexts = 2;
if strcmpi(params.trial_type,'stim')
    nContexts = 3;
end

% Load context-specific trial info
all_trial_info_sounds = info.active_all_trial_info;
passive_all_trial_info_sounds = info.passive_all_trial_info;

% Loop through datasets
for current_dataset = 1:nDatasets
    fprintf('Processing dataset %d/%d...\n', current_dataset, nDatasets);
    
    % Loop through contexts
    for context = 1:nContexts
        fprintf('Current context %d...\n', context);
        
        % Get condition labels from trial info 
         if context == 1
            current_conditions = [all_trial_info_sounds(current_dataset).opto.condition]; 
            current_conditions_ctrl = [all_trial_info_sounds(current_dataset).sound_only.condition];
        elseif context == 2
            current_conditions = [passive_all_trial_info_sounds(current_dataset).opto.condition];
            current_conditions_ctrl = [passive_all_trial_info_sounds(current_dataset).sound_only.condition];
        else %spont has no conditions
            current_conditions = [];
            current_conditions_ctrl = [];
        end
        
        % Get neural data
        % Extract neural data for the current dataset.
        stim_data = neural_structure{1,current_dataset}.stim;  % [trials x neurons x frames]
        ctrl_data = neural_structure{1,current_dataset}.ctrl;  % [trials x neurons x frames]

%         % Get trial indices for the current context.
        stim_trials = stim_trials_context{1, current_dataset}{1, context};
        ctrl_trials = ctrl_trials_context{1, current_dataset}{1, context};

        [stim_trials_updated,ctr_trials_updated,stim_left,stim_right,ctrl_left,ctrl_right] = separate_trial_types(stim_trials,ctrl_trials, current_conditions, current_conditions_ctrl, params);
        stim_trials_context_updated{1, current_dataset}{1, context} = stim_trials_updated;
        ctrl_trials_context_updated{1, current_dataset}{1, context} = ctr_trials_updated;
        
        %separate into left and right
        stim_trials_context_updated_left{1, current_dataset}{1, context} = stim_left;
        stim_trials_context_updated_right{1, current_dataset}{1, context} = stim_right;
        ctrl_trials_context_updated_left{1, current_dataset}{1, context} = ctrl_left;
        ctrl_trials_context_updated_right{1, current_dataset}{1, context} = ctrl_right;
        
    end
end

if strcmpi(params.data_type,'dff')
    if strcmpi(params.mode, 'separate')
        [pre_left,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context_updated_left, ctrl_trials_context_updated_left);
        [post_left,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context_updated_left, ctrl_trials_context_updated_left);
        
        [pre_right,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context_updated_right, ctrl_trials_context_updated_right);
        [post_right,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context_updated_right, ctrl_trials_context_updated_right);

    else
        [neural_avg_trial_cel_mouse_pre,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context, ctrl_trials_context);
        [neural_avg_trial_cel_mouse_post,~] = calc_avg_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context, ctrl_trials_context);
    end
else
    if strcmpi(params.mode, 'separate')
        [pre_left,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context_updated_left, ctrl_trials_context_updated_left);
        [post_left,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context_updated_left, ctrl_trials_context_updated_left);
        
        [pre_right,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context_updated_right, ctrl_trials_context_updated_right);
        [post_right,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context_updated_right, ctrl_trials_context_updated_right);

    else
        [neural_avg_trial_cel_mouse_pre,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.pre_frames,stim_trials_context, ctrl_trials_context);
        [neural_avg_trial_cel_mouse_post,~] = calc_spike_rate_across_context_celltype_choosetrials(neural_structure,params.post_frames,stim_trials_context, ctrl_trials_context);

    end
end

avg_pre = [];avg_ctrl_pre = []; avg_post = [];avg_ctrl_post = [];avg_pre_left = [];avg_ctrl_pre_left = [];avg_post_left = [];avg_ctrl_post_left = [];avg_pre_right = [];avg_ctrl_pre_right = [];avg_post_right = [];avg_ctrl_post_right = [];

%organize into mod structure ({context, mouse}) putting cell types together
if strcmpi(params.mode, 'separate')
    [avg_pre_left,avg_ctrl_pre_left] = into_mod_structure(pre_left,all_celltypes); %same as mod structure for easy plotting!
    [avg_post_left,avg_ctrl_post_left] = into_mod_structure(post_left,all_celltypes); %same as mod structure for easy plotting!

    [avg_pre_right,avg_ctrl_pre_right] = into_mod_structure(pre_right,all_celltypes); %same as mod structure for easy plotting!
    [avg_post_right,avg_ctrl_post_right] = into_mod_structure(post_right,all_celltypes); %same as mod structure for easy plotting!

    %for right now just putting left into this
    avg_pre = avg_pre_left;
    avg_ctrl_pre = avg_ctrl_pre_left;
    avg_post = avg_post_left;
    avg_ctrl_post = avg_ctrl_post_left;
else
    [avg_pre,avg_ctrl_pre] = into_mod_structure(neural_avg_trial_cel_mouse_pre,all_celltypes); %same as mod structure for easy plotting!
    [avg_post,avg_ctrl_post] = into_mod_structure(neural_avg_trial_cel_mouse_post,all_celltypes); %same as mod structure for easy plotting!
end

avg_results = struct();

avg_results.avg_pre            = avg_pre;
avg_results.avg_ctrl_pre       = avg_ctrl_pre;
avg_results.avg_post           = avg_post;
avg_results.avg_ctrl_post      = avg_ctrl_post;

avg_results.avg_pre_left       = avg_pre_left;
avg_results.avg_ctrl_pre_left  = avg_ctrl_pre_left;
avg_results.avg_post_left      = avg_post_left;
avg_results.avg_ctrl_post_left = avg_ctrl_post_left;

avg_results.avg_pre_right      = avg_pre_right;
avg_results.avg_ctrl_pre_right = avg_ctrl_pre_right;
avg_results.avg_post_right     = avg_post_right;
avg_results.avg_ctrl_post_right= avg_ctrl_post_right;
% % Save results
% if ~isempty(savepath)
%     outdir =savepath;
%     if ~exist(outdir, 'dir')
%         mkdir(outdir);
%     end
%     save(fullfile(outdir, 'trial_averaged_results.mat'), 'avg_results');
%     save(fullfile(outdir, 'trial_averaged_results_by_dataset.mat'), 'avg_results_by_dataset');
% 
% end

end
