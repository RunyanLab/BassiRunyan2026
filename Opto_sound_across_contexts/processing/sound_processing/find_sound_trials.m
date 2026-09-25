function [sound_trials_stim_across_datasets, sound_trials_ctrl_across_datasets, ...
          left_trials_stim_across_datasets, left_trials_ctrl_across_datasets, ...
          right_trials_stim_across_datasets, right_trials_ctrl_across_datasets, ...
          left_trials_stim_all_across_datasets, left_trials_ctrl_all_across_datasets, ...
          right_trials_stim_all_across_datasets, right_trials_ctrl_all_across_datasets] = ...
    find_sound_trials(info,stim_trials_context, ctrl_trials_context, varargin)
% find_sound_trials_single selects and balances sound trials across mice and context.
%
%   Inputs:
%     stim_trials           - Vector of stimulation trial identifiers (or indices) for this context.
%     ctrl_trials           - Vector of control trial identifiers (or indices) for this context.
%   Outputs:
%     sound_trials_stim     - Combined balanced stimulation trial indices (left+right).
%     sound_trials_ctrl     - Combined balanced control trial indices.
%     left_trials_stim      - Balanced left-side stimulation trial indices.
%     left_trials_ctrl      - Balanced left-side control trial indices.
%     right_trials_stim     - Balanced right-side stimulation trial indices.
%     right_trials_ctrl     - Balanced right-side control trial indices.
%     left_trials_stim_all  - All left-side stimulation trial indices (unbalanced).
%     left_trials_ctrl_all  - All left-side control trial indices (unbalanced).
%     right_trials_stim_all - All right-side stimulation trial indices (unbalanced).
%     right_trials_ctrl_all - All right-side control trial indices (unbalanced).
%
%   Example usage:
%     [sound_trials_stim, sound_trials_ctrl, left_trials_stim, left_trials_ctrl, ...
%      right_trials_stim, right_trials_ctrl, left_trials_stim_all, left_trials_ctrl_all, ...
%      right_trials_stim_all, right_trials_ctrl_all] = ...
%          find_sound_trials_single(stim_trials, ctrl_trials, current_conditions, current_conditions_ctrl);
    %% Find left/right trials for stimulation.
current_context = [1,2];
if isfield(info,'active_all_trial_info')
    all_trial_info_sounds = info.active_all_trial_info;
    passive_all_trial_info_sounds = info.passive_all_trial_info;
    if nargin>3
        passive_all_trial_info_sounds = varargin{1,1};
        current_context = [1,4];
    end
else
    load('V:\Connie\results\opto_sound_2025\context\sound_info\active_all_trial_info_sounds.mat');
    passive_all_trial_info_sounds = load('V:\Connie\results\opto_sound_2025\context\sound_info\passive_all_trial_info_sounds.mat').all_trial_info_sounds;
end


% Loop through datasets.
for current_dataset = 1:length(info.mouse_date)
    fprintf('Processing dataset %d/%d...\n', current_dataset, length(info.mouse_date));

    if isfield(info,'active_all_trial_info')
        for contexts = 1:2
            context = current_context(contexts);
            fprintf('Current context %d...\n', context);

            % Get condition labels from trial info 
            if context == 1
                    current_conditions = [all_trial_info_sounds(current_dataset).opto.condition];
                    current_conditions_ctrl = [all_trial_info_sounds(current_dataset).sound_only.condition];
            elseif context == 2 || context == 4
                    current_conditions = [passive_all_trial_info_sounds(current_dataset).opto.condition];
                    current_conditions_ctrl = [passive_all_trial_info_sounds(current_dataset).sound_only.condition];
            end
             % Get trial indices for the current context.
        stim_trials = stim_trials_context{1, current_dataset}{1, context};
        ctrl_trials = ctrl_trials_context{1, current_dataset}{1, context};


    if ~isempty(current_conditions)
        %validate lengths to make sure we can use this trial info
        %structure!
        if length(stim_trials) ~= length(current_conditions) 
            error('Length mismatch: stim_trials and current_conditions must have the same length.');
        end
        if length(ctrl_trials) ~= length(current_conditions_ctrl)
            error('Length mismatch: ctrl_trials and current_conditions_ctrl must have the same length.');
        end

        % Find left/right trials for opto.
        sound_left_trials = stim_trials(current_conditions == 1);
        sound_right_trials = stim_trials(current_conditions == 2);
        % Find left/right trials for control.
        sound_left_trials_ctrl = ctrl_trials(current_conditions_ctrl == 1);
        sound_right_trials_ctrl = ctrl_trials(current_conditions_ctrl == 2);
    else %using all trials in the spontaneous context since there are no left or right sounds!
        sound_left_trials = stim_trials;
        sound_right_trials = stim_trials;
        % Find left/right trials for control.
        sound_left_trials_ctrl = ctrl_trials;
        sound_right_trials_ctrl = ctrl_trials;

    end
    % Balance the number of trials for stimulation and control.
    num_trials_stim = min(length(sound_left_trials), length(sound_right_trials));
    num_trials_ctrl = min(length(sound_left_trials_ctrl), length(sound_right_trials_ctrl));

    % Randomly sample balanced trials.
    balanced_left_trials_stim = randsample(sound_left_trials, num_trials_stim, false);
    balanced_right_trials_stim = randsample(sound_right_trials, num_trials_stim, false);
    balanced_left_trials_ctrl = randsample(sound_left_trials_ctrl, num_trials_ctrl, false);
    balanced_right_trials_ctrl = randsample(sound_right_trials_ctrl, num_trials_ctrl, false);

    % Combine balanced trials.
    sound_trials_stim = [balanced_left_trials_stim, balanced_right_trials_stim];
    sound_trials_ctrl = [balanced_left_trials_ctrl, balanced_right_trials_ctrl];

    % Output the balanced trials separately.
    left_trials_stim  = balanced_left_trials_stim;
    left_trials_ctrl  = balanced_left_trials_ctrl;
    right_trials_stim = balanced_right_trials_stim;
    right_trials_ctrl = balanced_right_trials_ctrl;
    
    % Also output the full (unbalanced) left/right trial sets.
    left_trials_stim_all  = sound_left_trials;
    left_trials_ctrl_all  = sound_left_trials_ctrl;
    right_trials_stim_all = sound_right_trials;
    right_trials_ctrl_all = sound_right_trials_ctrl;

    % Save into structure that includes the dataset index and context
    left_trials_stim_across_datasets{1, current_dataset}{1, context} = left_trials_stim;
    left_trials_ctrl_across_datasets{1, current_dataset}{1, context} = left_trials_ctrl;
    right_trials_stim_across_datasets{1, current_dataset}{1, context} = right_trials_stim;
    right_trials_ctrl_across_datasets{1, current_dataset}{1, context} = right_trials_ctrl;

    left_trials_stim_all_across_datasets{1, current_dataset}{1, context} = left_trials_stim_all;
    left_trials_ctrl_all_across_datasets{1, current_dataset}{1, context} = left_trials_ctrl_all;
    right_trials_stim_all_across_datasets{1, current_dataset}{1, context} = right_trials_stim_all;
    right_trials_ctrl_all_across_datasets{1, current_dataset}{1, context} = right_trials_ctrl_all;

    sound_trials_stim_across_datasets{1, current_dataset}{1, context} = sound_trials_stim;
    sound_trials_ctrl_across_datasets{1, current_dataset}{1, context} = sound_trials_ctrl;
        end
    else

        for context = 1:2  % Assuming context 1: active, context 2: passive, context 3: spontaneous.
            fprintf('Current context %d...\n', context);
            % Get condition labels from trial info 
            if context == 1
    %             if strcmpi(mod_type,'prepost_sound') || strcmpi(mode,'selectivity') %for sound alignment I included [control, sound_only trials] so I need to concatenate trial types here)
                    current_conditions = [all_trial_info_sounds(current_dataset).opto.condition];
                    current_conditions_ctrl = [all_trial_info_sounds(current_dataset).ctrl.condition,all_trial_info_sounds(current_dataset).sound_only.condition];
    %             else
    %                 current_conditions = [all_trial_info_sounds(current_dataset).opto.condition];
    %                 current_conditions_ctrl = [all_trial_info_sounds(current_dataset).ctrl.condition];
    %             end
            elseif context == 2
    %             if strcmpi(mod_type,'prepost_sound') || strcmpi(mode,'selectivity')%for sound alignment I included [control, sound_only trials] so I need to concatenate trial types here)
                    current_conditions = [passive_all_trial_info_sounds(current_dataset).opto.condition];
                    current_conditions_ctrl = [passive_all_trial_info_sounds(current_dataset).ctrl.condition,passive_all_trial_info_sounds(current_dataset).sound_only.condition];
    %             else
    %                 current_conditions = [passive_all_trial_info_sounds(current_dataset).opto.condition];
    %                 current_conditions_ctrl = [passive_all_trial_info_sounds(current_dataset).ctrl.condition];
    %             end
            else %spont has no conditions
                current_conditions = [];
                current_conditions_ctrl = [];
            end

         % Get trial indices for the current context.
        stim_trials = stim_trials_context{1, current_dataset}{1, context};
        ctrl_trials = ctrl_trials_context{1, current_dataset}{1, context};


    if ~isempty(current_conditions)
        %validate lengths to make sure we can use this trial info
        %structure!
        if length(stim_trials) ~= length(current_conditions) 
            error('Length mismatch: stim_trials and current_conditions must have the same length.');
        end
        if length(ctrl_trials) ~= length(current_conditions_ctrl)
            error('Length mismatch: ctrl_trials and current_conditions_ctrl must have the same length.');
        end

        % Find left/right trials for opto.
        sound_left_trials = stim_trials(current_conditions == 1);
        sound_right_trials = stim_trials(current_conditions == 2);
        % Find left/right trials for control.
        sound_left_trials_ctrl = ctrl_trials(current_conditions_ctrl == 1);
        sound_right_trials_ctrl = ctrl_trials(current_conditions_ctrl == 2);
    else %using all trials in the spontaneous context since there are no left or right sounds!
        sound_left_trials = stim_trials;
        sound_right_trials = stim_trials;
        % Find left/right trials for control.
        sound_left_trials_ctrl = ctrl_trials;
        sound_right_trials_ctrl = ctrl_trials;

    end
    % Balance the number of trials for stimulation and control.
    num_trials_stim = min(length(sound_left_trials), length(sound_right_trials));
    num_trials_ctrl = min(length(sound_left_trials_ctrl), length(sound_right_trials_ctrl));

    % Randomly sample balanced trials.
    balanced_left_trials_stim = randsample(sound_left_trials, num_trials_stim, false);
    balanced_right_trials_stim = randsample(sound_right_trials, num_trials_stim, false);
    balanced_left_trials_ctrl = randsample(sound_left_trials_ctrl, num_trials_ctrl, false);
    balanced_right_trials_ctrl = randsample(sound_right_trials_ctrl, num_trials_ctrl, false);

    % Combine balanced trials.
    sound_trials_stim = [balanced_left_trials_stim, balanced_right_trials_stim];
    sound_trials_ctrl = [balanced_left_trials_ctrl, balanced_right_trials_ctrl];

    % Output the balanced trials separately.
    left_trials_stim  = balanced_left_trials_stim;
    left_trials_ctrl  = balanced_left_trials_ctrl;
    right_trials_stim = balanced_right_trials_stim;
    right_trials_ctrl = balanced_right_trials_ctrl;
    
    % Also output the full (unbalanced) left/right trial sets.
    left_trials_stim_all  = sound_left_trials;
    left_trials_ctrl_all  = sound_left_trials_ctrl;
    right_trials_stim_all = sound_right_trials;
    right_trials_ctrl_all = sound_right_trials_ctrl;

    % Save into structure that includes the dataset index and context
    left_trials_stim_across_datasets{1, current_dataset}{1, context} = left_trials_stim;
    left_trials_ctrl_across_datasets{1, current_dataset}{1, context} = left_trials_ctrl;
    right_trials_stim_across_datasets{1, current_dataset}{1, context} = right_trials_stim;
    right_trials_ctrl_across_datasets{1, current_dataset}{1, context} = right_trials_ctrl;

    left_trials_stim_all_across_datasets{1, current_dataset}{1, context} = left_trials_stim_all;
    left_trials_ctrl_all_across_datasets{1, current_dataset}{1, context} = left_trials_ctrl_all;
    right_trials_stim_all_across_datasets{1, current_dataset}{1, context} = right_trials_stim_all;
    right_trials_ctrl_all_across_datasets{1, current_dataset}{1, context} = right_trials_ctrl_all;

    sound_trials_stim_across_datasets{1, current_dataset}{1, context} = sound_trials_stim;
    sound_trials_ctrl_across_datasets{1, current_dataset}{1, context} = sound_trials_ctrl;
    end

    end
    end
end