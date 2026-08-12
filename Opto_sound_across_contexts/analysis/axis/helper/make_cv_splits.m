function [stim_splits, ctrl_splits, stim_splits_all, ctrl_splits_all] = make_cv_splits(total_trials_stim, total_trials_ctrl, splits,divisions,random_or_not, varargin)
% Create splits for stim and ctrl across 2 contexts
% Outputs:
%   stim_splits{ctx}(f)  -> per-context splits (ctx=1:2, f=1:3)
%   ctrl_splits{ctx}(f)  -> per-context splits
%   stim_splits_all(f)   -> combined across both contexts
%   ctrl_splits_all(f)   -> combined across both contexts

% Parse optional inputs
p = inputParser;
addParameter(p, 'contexts', 1:2, @(x) isnumeric(x) && isvector(x) && all(x >= 1));
parse(p, varargin{:});

contexts = p.Results.contexts;

    ctx_count_stim = 0;
    ctx_count_ctrl = 0;

    stim_splits = cell(1,length(contexts));
    ctrl_splits = cell(1,length(contexts));

    for i = 1:length(contexts)
        ctx = contexts(i);
        % Stim trials
        stim_splits{ctx} =  get_splits_cv(total_trials_stim(ctx),divisions,random_or_not,splits);
        for f = 1:size(stim_splits{ctx},2)
            stim_splits{ctx}(f).trainA = stim_splits{ctx}(f).train + ctx_count_stim;
            stim_splits{ctx}(f).test   = stim_splits{ctx}(f).test   + ctx_count_stim;
        end

        % Ctrl trials
        ctrl_splits{ctx} = get_splits_cv(total_trials_ctrl(ctx),divisions,random_or_not,splits);
        for f = 1:size(ctrl_splits{ctx},2)
            ctrl_splits{ctx}(f).trainA = ctrl_splits{ctx}(f).train + ctx_count_ctrl;
            ctrl_splits{ctx}(f).test   = ctrl_splits{ctx}(f).test   + ctx_count_ctrl;
        end

        % Update offsets
        ctx_count_stim = ctx_count_stim + total_trials_stim(ctx);
        ctx_count_ctrl = ctx_count_ctrl + total_trials_ctrl(ctx);
    end

    % --- Combine across selected contexts ---
    for f = 1:size(stim_splits{contexts(1)}, 2)
    
        stim_splits_all(f).trainA = [];
        stim_splits_all(f).test = [];
    
        ctrl_splits_all(f).trainA = [];
        ctrl_splits_all(f).test = [];
    
        for ctx = contexts
    
            stim_splits_all(f).trainA = [ ...
                stim_splits_all(f).trainA, ...
                stim_splits{ctx}(f).trainA];
    
            stim_splits_all(f).test = [ ...
                stim_splits_all(f).test, ...
                stim_splits{ctx}(f).test];
    
            ctrl_splits_all(f).trainA = [ ...
                ctrl_splits_all(f).trainA, ...
                ctrl_splits{ctx}(f).trainA];
    
            ctrl_splits_all(f).test = [ ...
                ctrl_splits_all(f).test, ...
                ctrl_splits{ctx}(f).test];
        end
    end
end