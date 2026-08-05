function [dff_context, stim_trials_context, ctrl_trials_context] = organize_2context(context_st, context2_st, varargin)
% ORGANIZE_2CONTEXT organizes neural activity data for two different contexts.
% It extracts and structures stimulus (stim) and control (ctrl) trial data 
% from two context structures and ensures trial indices are managed properly.
%
% Inputs:
%   context_st  - Cell array containing neural data for the first context.
%   context2_st - Cell array containing neural data for the second context.
%   varargin    - Optional additional contexts (not currently used but allows extension).
%
% Outputs:
%   dff_context         - Structure array with organized neural data.
%   stim_trials_context - Cell array of stimulus trial indices for each dataset.
%   ctrl_trials_context - Cell array of control trial indices for each dataset.
%
% Author: CB 03/04/2025
% if nargin > 2
%     mouse_context_tr = varargin{1,1}
% end
p = inputParser;

addParameter(p,'mouse_context_tr',[]);
addParameter(p,'context3_st',[]);

p = inputParser;

addParameter(p,'mouse_context_tr',[]);
addParameter(p,'extra_contexts',{});

parse(p,varargin{:});

mouse_context_tr = p.Results.mouse_context_tr;

% Combine all contexts into one cell array
contexts = [{context_st, context2_st}, p.Results.extra_contexts];
num_context = numel(contexts);

% num_context = 2;

for current_dataset = 1:length(context_st)
    condition1_trials_all = [];
    condition2_trials_all = [];
    
    for current_context = 1:num_context
        current_context_data = contexts{current_context};

        % Determine trial indices
        if current_context == 1
            stim_trials = 1:size(current_context_data{1,current_dataset}.stim,1);
            ctrl_trials = 1:size(current_context_data{1,current_dataset}.ctrl,1);
        else
            stim_trials = stim_trials(end) + ...
                (1:size(current_context_data{1,current_dataset}.stim,1));
            ctrl_trials = ctrl_trials(end) + ...
                (1:size(current_context_data{1,current_dataset}.ctrl,1));
        end
        
        % Override trial indices if provided
        if ~isempty(mouse_context_tr)
            if current_context == 1
                stim_trials = 1:length(mouse_context_tr{1,current_dataset}{1,1});
                ctrl_trials = 1:length(mouse_context_tr{1,current_dataset}{1,2});
            else
                stim_trials = ...
                    sum(cellfun(@length,mouse_context_tr{1,current_dataset}(1:current_context-1,1))) + ...
                    (1:length(mouse_context_tr{1,current_dataset}{current_context,1}));
        
                ctrl_trials = ...
                    sum(cellfun(@length,mouse_context_tr{1,current_dataset}(1:current_context-1,2))) + ...
                    (1:length(mouse_context_tr{1,current_dataset}{current_context,2}));
            end
        end
        
        % Store data
        dff_context{current_context,current_dataset}.stim = ...
            current_context_data{1,current_dataset}.stim;
        
        dff_context{current_context,current_dataset}.ctrl = ...
            current_context_data{1,current_dataset}.ctrl;
        
        condition1_trials_all{current_context} = stim_trials;
        condition2_trials_all{current_context} = ctrl_trials;
        
        % Store z-scored data if present
        if isfield(current_context_data{1,current_dataset},'z_stim')
            dff_context{current_context,current_dataset}.z_stim = ...
                current_context_data{1,current_dataset}.z_stim;
            dff_context{current_context,current_dataset}.z_ctrl = ...
                current_context_data{1,current_dataset}.z_ctrl;
        end
    end
    
    % Store trial indices for both conditions
    stim_trials_context{current_dataset} = condition1_trials_all;
    ctrl_trials_context{current_dataset} = condition2_trials_all;
end
