function [stim_trials_combined, dff_combined] = combine_stim_info_dff_st(stim_info1, stim_info2, dff1, dff2,varargin)
% COMBINE_STIM_INFO_DFF_ST vertically stacks two contexts together 
% and keeps track of trial indices while combining dF/F data.
%
% Inputs:
%   stim_info1 - Cell array containing stimulus info for the first context.
%   stim_info2 - Cell array containing stimulus info for the second context.
%   dff1       - Cell array containing dF/F data for the first context.
%   dff2       - Cell array containing dF/F data for the second context.
%
% Outputs:
%   stim_trials_combined - Cell array with combined stimulus trial indices.
%   dff_combined         - Structure array with merged dF/F data.
%
% Author: CB 03/04/2025

p = inputParser;

addParameter(p,'extra_stim_info',{});
addParameter(p,'extra_dff',{});

parse(p,varargin{:});

stim_infos = [{stim_info1, stim_info2}, p.Results.extra_stim_info];
dffs       = [{dff1, dff2}, p.Results.extra_dff];

num_contexts = numel(stim_infos);

stim_trials_combined = {};

for current_dataset = 1:size(stim_info1,1)

    stim_labels = [];
    stim_idx2 = [];
    stim_idx3 = [];

    stim_all = [];
    ctrl_all = [];

    z_stim_all = [];
    z_ctrl_all = [];
    has_z = true;

    offset = 0;

    for current_context = 1:num_contexts

        stim_info = stim_infos{current_context};
        dff = dffs{current_context};

        n_trials = length(stim_info{current_dataset,1});

        % Combine stim info
        stim_labels = [stim_labels;
                       stim_info{current_dataset,1}];

        stim_idx2 = [stim_idx2, ...
                     stim_info{current_dataset,2} + offset];

        stim_idx3 = [stim_idx3, ...
                     stim_info{current_dataset,3} + offset];

        offset = offset + n_trials;

        % Combine dff
        stim_all = [stim_all;
                    dff{1,current_dataset}.stim];

        ctrl_all = [ctrl_all;
                    dff{1,current_dataset}.ctrl];

        % Combine z-scored data if available
        if has_z && isfield(dff{1,current_dataset},'z_stim')

            z_stim_all = [z_stim_all;
                          dff{1,current_dataset}.z_stim];

            z_ctrl_all = [z_ctrl_all;
                          dff{1,current_dataset}.z_ctrl];

        else
            has_z = false;
        end
    end

    stim_trials_combined{current_dataset,1} = stim_labels;
    stim_trials_combined{current_dataset,2} = stim_idx2;
    stim_trials_combined{current_dataset,3} = stim_idx3;

    dff_combined{1,current_dataset}.stim = stim_all;
    dff_combined{1,current_dataset}.ctrl = ctrl_all;

    if has_z
        dff_combined{1,current_dataset}.z_stim = z_stim_all;
        dff_combined{1,current_dataset}.z_ctrl = z_ctrl_all;
    end

end