function [lm, tbl, proj_all, engagement_proj_all, movement_all, ...
          context_all, corr_mean, corr_all, corr_all_stats, ...
          lme, tbl2, lm_resid, lme_resid, tbl_resid] = ...
    linear_regression_corr_model_movement( ...
    proj, movement_splits, movement_names, axis_type, celltype, ...
    frame_range_pre, frame_range_post, contexts, varargin)

% movement_splits: cell array of movement variables
% e.g. {speed_split, pitch_split, roll_split}
%
% each movement_splits{i}: {split, dataset, ctx}
% or {dataset, split, ctx} depending on your structure.
%
% movement_names:
% e.g. {'Speed','Pitch','Roll'}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

proj_all = [];
engagement_proj_all = [];
movement_all = [];
context_all = [];
animal_id_all = [];

n_splits = size(proj,1);
n_datasets = size(proj,2);
n_movements = numel(movement_splits);

corr_all = NaN(n_splits, n_datasets);
response_var = strcat(axis_type, 'Proj');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for dataset = 1:n_datasets
    for split = 1:n_splits

        s_proj_dataset = [];
        e_proj_dataset = [];

        for ctx = contexts

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % RESPONSE PROJECTION
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            s_proj = mean( ...
                proj{split, dataset, celltype(1), ctx}.(lower(axis_type)) ...
                (:, frame_range_post), 2);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ENGAGEMENT PROJECTION
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if length(celltype) > 1
                if nargin > 8
                    e_proj = mean( ...
                        proj{split, dataset, celltype(2), ctx}.(lower(varargin{1})) ...
                        (:, frame_range_pre), 2);
                else
                    e_proj = mean( ...
                        proj{split, dataset, celltype(2), ctx}.context ...
                        (:, frame_range_pre), 2);
                end
            else
                if nargin > 8
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
            % MOVEMENT VARIABLES
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            movement_this = NaN(size(s_proj,1), n_movements);

            for m = 1:n_movements

                this_movement_split = movement_splits{m};
                movement_trace = this_movement_split{split, dataset, ctx};

                movement_this(:,m) = mean(movement_trace(:, frame_range_pre), 2);
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ACCUMULATE
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            proj_all = [proj_all; s_proj];
            engagement_proj_all = [engagement_proj_all; e_proj];
            movement_all = [movement_all; movement_this];

            context_all = [context_all; repmat(ctx-1, size(s_proj,1), 1)];
            animal_id_all = [animal_id_all; repmat(dataset, size(s_proj,1), 1)];

            s_proj_dataset = [s_proj_dataset; s_proj];
            e_proj_dataset = [e_proj_dataset; e_proj];

        end

        if ~isempty(s_proj_dataset) && ~isempty(e_proj_dataset)
            corr_all(split, dataset) = corr( ...
                e_proj_dataset, s_proj_dataset, ...
                'type', 'Pearson', ...
                'rows', 'complete');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TABLE SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tbl = table(proj_all, engagement_proj_all, ...
    'VariableNames', {response_var, 'EngagementProj'});

for m = 1:n_movements
    tbl.(movement_names{m}) = movement_all(:,m);
end

movement_formula = strjoin(movement_names, ' + ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINEAR MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_formula = sprintf('%s ~ EngagementProj + %s', ...
    response_var, movement_formula);

lm = fitlm(tbl, lm_formula);
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

tbl2 = tbl;
tbl2.AnimalID = animal_id_all;

lme_formula = sprintf('%s ~ EngagementProj + %s + (1|AnimalID)', ...
    response_var, movement_formula);

lme = fitlme(tbl2, lme_formula);
disp(lme)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESIDUALIZATION AGAINST MOVEMENT VARIABLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

resp_formula = sprintf('%s ~ %s', response_var, movement_formula);
lm_resp_movement = fitlm(tbl, resp_formula);
response_resid = lm_resp_movement.Residuals.Raw;

eng_tbl = tbl(:, [{'EngagementProj'}, movement_names]);
lm_eng_movement = fitlm(eng_tbl, ...
    sprintf('EngagementProj ~ %s', movement_formula));

engagement_resid = lm_eng_movement.Residuals.Raw;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESIDUAL TABLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tbl_resid = table( ...
    response_resid, ...
    engagement_resid, ...
    animal_id_all, ...
    'VariableNames', ...
    {response_var, 'EngagementProj', 'AnimalID'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINEAR MODEL ON RESIDUALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_resid = fitlm(tbl_resid, ...
    sprintf('%s ~ EngagementProj', response_var));

disp('Residualized linear model:')
disp(lm_resid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MIXED EFFECTS MODEL ON RESIDUALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lme_resid = fitlme(tbl_resid, ...
    sprintf('%s ~ EngagementProj + (1|AnimalID)', response_var));

disp('Residualized mixed-effects model:')
disp(lme_resid)

end