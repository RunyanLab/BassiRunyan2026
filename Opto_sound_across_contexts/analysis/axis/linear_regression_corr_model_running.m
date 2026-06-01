function [lm, tbl, proj_all, engagement_proj_all, running_all, ...
          context_all, corr_mean, corr_all, corr_all_stats, lme, tbl2, lm_resid, lme_resid, tbl_resid] = ...
    linear_regression_corr_model_running( ...
    proj, running_split, axis_type, celltype, ...
    frame_range_pre, frame_range_post, contexts, varargin)

% proj: {split, dataset, celltype, ctx}.(axis)
% running_split: {dataset, split} -> trial-level running (already aligned)
%
% axis_type: e.g. 'context', 'stim', etc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

proj_all = [];
engagement_proj_all = [];
running_all = [];
context_all = [];
animal_id_all = [];

n_splits = size(proj,1);
n_datasets = size(proj,2);

corr_all = NaN(n_splits, n_datasets);

response_var = strcat(axis_type, 'Proj');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for dataset = 1:n_datasets

    for split = 1:n_splits

        s_proj_dataset = [];
        e_proj_dataset = [];
        r_dataset = [];

        for ctx = contexts

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % STIM (post)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            s_proj = mean( ...
                proj{split, dataset, celltype(1), ctx}.(lower(axis_type)) ...
                (:, frame_range_post), 2);

            r_mean = mean(running_split{split, dataset, ctx}(:, frame_range_pre), 2);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ENGAGEMENT (pre / second celltype)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if length(celltype) > 1
                if nargin > 7
                    e_proj = mean( ...
                        proj{split, dataset, celltype(2), ctx}.(lower(varargin{1})) ...
                        (:, frame_range_pre), 2);
                else
                    e_proj = mean( ...
                        proj{split, dataset, celltype(2), ctx}.context ...
                        (:, frame_range_pre), 2);
                end
            else
                if nargin > 7
                    e_proj = mean( ...
                        proj{split, dataset, celltype, ctx}.(lower(varargin{1})) ...
                        (:, frame_range_pre), 2);
                else
                    e_proj = mean( ...
                        proj{split, dataset, celltype, ctx}.context ...
                        (:, frame_range_pre), 2);
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ACCUMULATE GLOBAL VECTORS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            proj_all = [proj_all; s_proj];
            engagement_proj_all = [engagement_proj_all; e_proj];
            running_all = [running_all; r_mean];

            context_all = [context_all; repmat(ctx-1, size(s_proj,1), 1)];
            animal_id_all = [animal_id_all; repmat(dataset, size(s_proj,1), 1)];

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % WITHIN-DATASET CORRELATION
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            s_proj_dataset = [s_proj_dataset; s_proj];
            e_proj_dataset = [e_proj_dataset; e_proj];
            r_dataset = [r_dataset;r_mean];

        end

        if ~isempty(s_proj_dataset) && ~isempty(e_proj_dataset)
            corr_all(split, dataset) = corr( ...
                e_proj_dataset, s_proj_dataset, ...
                'type', 'Pearson');
        end

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINEAR MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tbl = table( ...
    proj_all, engagement_proj_all, running_all, ...
    'VariableNames', ...
    {response_var, 'EngagementProj', 'Running'});

lm = fitlm(tbl, ...
    sprintf('%s ~ EngagementProj + Running', response_var));

disp(lm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUMMARY CORRELATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

corr_mean = mean(corr_all(:), 'omitnan');

[corr_all_stats.p, corr_all_stats.obsDiff, corr_all_stats.effectSize] = ...
    permutationTest_updatedcb( ...
    mean(corr_all), ...
    zeros(size(mean(corr_all))), ...
    10000, 'paired', 1, 'sidedness', 'both');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MIXED EFFECTS MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

animal_id_all = categorical(animal_id_all);

tbl2 = table( ...
    proj_all, engagement_proj_all, running_all, animal_id_all, ...
    'VariableNames', ...
    {response_var, 'EngagementProj', 'Running', 'AnimalID'});

lme = fitlme(tbl2, ...
    sprintf('%s ~ EngagementProj + Running + (1|AnimalID)', response_var));

disp(lme)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARTIAL REGRESSION ANALYSIS
% REMOVE RUNNING FROM BOTH VARIABLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Residualize response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_resp_running = fitlm( ...
    table(proj_all, running_all, ...
    'VariableNames',{response_var,'Running'}), ...
    sprintf('%s ~ Running', response_var));

response_resid = lm_resp_running.Residuals.Raw;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Residualize engagement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_eng_running = fitlm( ...
    table(engagement_proj_all, running_all, ...
    'VariableNames',{'EngagementProj','Running'}), ...
    'EngagementProj ~ Running');

engagement_resid = lm_eng_running.Residuals.Raw;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Table of residuals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tbl_resid = table( ...
    response_resid, ...
    engagement_resid, ...
    animal_id_all, ...
    'VariableNames', ...
    {response_var,'EngagementProj','AnimalID'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linear model on residuals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_resid = fitlm( ...
    tbl_resid, ...
    sprintf('%s ~ EngagementProj', response_var));

disp('Residualized linear model:')
disp(lm_resid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mixed effects model on residuals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lme_resid = fitlme( ...
    tbl_resid, ...
    sprintf('%s ~ EngagementProj + (1|AnimalID)', ...
    response_var));

disp('Residualized mixed-effects model:')
disp(lme_resid)

end