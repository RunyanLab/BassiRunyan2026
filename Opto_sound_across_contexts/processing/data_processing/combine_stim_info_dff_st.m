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

addParameter(p,'stim_info3',[]);
addParameter(p,'dff3',[]);

parse(p,varargin{:});

stim_info3 = p.Results.stim_info3;
dff3 = p.Results.dff3;


stim_trials_combined = {};  % Initialize combined stimulus trials structure

for current_dataset = 1:size(stim_info1,1)

    % Number of trials in first and second contexts
    n1 = length(stim_info1{current_dataset,1});
    n2 = length(stim_info2{current_dataset,1});

    if isempty(stim_info3)

        % ============================================================
        % TWO CONTEXTS
        % ============================================================

        stim_trials_combined{current_dataset,1} = ...
            [stim_info1{current_dataset,1};
             stim_info2{current_dataset,1}];

        stim_trials_combined{current_dataset,2} = ...
            [stim_info1{current_dataset,2}, ...
             stim_info2{current_dataset,2} + n1];

        stim_trials_combined{current_dataset,3} = ...
            [stim_info1{current_dataset,3}, ...
             stim_info2{current_dataset,3} + n1];

        dff_combined{1,current_dataset}.stim = ...
            [dff1{1,current_dataset}.stim;
             dff2{1,current_dataset}.stim];

        dff_combined{1,current_dataset}.ctrl = ...
            [dff1{1,current_dataset}.ctrl;
             dff2{1,current_dataset}.ctrl];

        if isfield(dff1{1,current_dataset},'z_stim') && ...
           isfield(dff2{1,current_dataset},'z_stim')

            dff_combined{1,current_dataset}.z_stim = ...
                [dff1{1,current_dataset}.z_stim;
                 dff2{1,current_dataset}.z_stim];

            dff_combined{1,current_dataset}.z_ctrl = ...
                [dff1{1,current_dataset}.z_ctrl;
                 dff2{1,current_dataset}.z_ctrl];
        end

    else

        % ============================================================
        % THREE CONTEXTS
        % ============================================================

        n3 = length(stim_info3{current_dataset,1});

        stim_trials_combined{current_dataset,1} = ...
            [stim_info1{current_dataset,1};
             stim_info2{current_dataset,1};
             stim_info3{current_dataset,1}];

        stim_trials_combined{current_dataset,2} = ...
            [stim_info1{current_dataset,2}, ...
             stim_info2{current_dataset,2} + n1, ...
             stim_info3{current_dataset,2} + n1 + n2];

        stim_trials_combined{current_dataset,3} = ...
            [stim_info1{current_dataset,3}, ...
             stim_info2{current_dataset,3} + n1, ...
             stim_info3{current_dataset,3} + n1 + n2];

        dff_combined{1,current_dataset}.stim = ...
            [dff1{1,current_dataset}.stim;
             dff2{1,current_dataset}.stim;
             dff3{1,current_dataset}.stim];

        dff_combined{1,current_dataset}.ctrl = ...
            [dff1{1,current_dataset}.ctrl;
             dff2{1,current_dataset}.ctrl;
             dff3{1,current_dataset}.ctrl];

        if isfield(dff1{1,current_dataset},'z_stim') && ...
           isfield(dff2{1,current_dataset},'z_stim') && ...
           isfield(dff3{1,current_dataset},'z_stim')

            dff_combined{1,current_dataset}.z_stim = ...
                [dff1{1,current_dataset}.z_stim;
                 dff2{1,current_dataset}.z_stim;
                 dff3{1,current_dataset}.z_stim];

            dff_combined{1,current_dataset}.z_ctrl = ...
                [dff1{1,current_dataset}.z_ctrl;
                 dff2{1,current_dataset}.z_ctrl;
                 dff3{1,current_dataset}.z_ctrl];
        end

    end

end

end
