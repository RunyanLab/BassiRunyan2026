function [lm, tbl, proj_all, engagement_proj_all, context_all, corr_mean, corr_all,corr_all_stats,lme,tbl2] = ...
    linear_regression_corr_model(proj, axis_type, celltype, frame_range_pre, frame_range_post, contexts, varargin)
% Initialize
proj_all = [];
engagement_proj_all = [];
context_all = [];
animal_id_all = [];
n_splits = size(proj,1);
n_datasets = size(proj,2);
corr_all = NaN(n_splits, n_datasets);
    for dataset = 1:n_datasets
        if ~isempty(proj{1, dataset, celltype(1), 1})
            for split = 1:n_splits
            s_proj_dataset = [];  % post
            e_proj_dataset = [];  % pre
            for ctx = contexts
                % Extract post-stim projections
                s_proj = mean(proj{split, dataset, celltype(1), ctx}.(lower(axis_type))(:, frame_range_post), 2);
                % Extract pre-stim projections
                if length(celltype) > 1
                    if nargin > 6
                        e_proj = mean(proj{split, dataset, celltype(2), ctx}.(lower(varargin{1}))(:, frame_range_pre), 2);
                    else
                        e_proj = mean(proj{split, dataset, celltype(2), ctx}.context(:, frame_range_pre), 2);
                    end
                else
                    if nargin > 6
                        e_proj = mean(proj{split, dataset, celltype, ctx}.(lower(varargin{1}))(:, frame_range_pre), 2);
                    else
                        e_proj = mean(proj{split, dataset, celltype, ctx}.context(:, frame_range_pre), 2);
                    end
                end
                % Accumulate
                proj_all = [proj_all; s_proj];
                engagement_proj_all = [engagement_proj_all; e_proj];
                context_all = [context_all; repmat(ctx-1, size(s_proj,1), 1)];
                animal_id_all = [animal_id_all; repmat(dataset, size(s_proj,1), 1)];
                % Collect for correlation per dataset
                s_proj_dataset = [s_proj_dataset; s_proj];
                e_proj_dataset = [e_proj_dataset; e_proj];
            end
            % Pearson correlation (assumes z-scored)
            if ~isempty(s_proj_dataset) && ~isempty(e_proj_dataset)
                r = corr(e_proj_dataset, s_proj_dataset, 'type', 'Pearson');
                corr_all(split, dataset) = r;
            end
            end
        end
end
% Build table
tbl = table(proj_all, engagement_proj_all, ...
    'VariableNames', {strcat(axis_type, 'Proj'), 'EngagementProj'});
% Run standard linear regression
response_var = strcat(axis_type, 'Proj');
formula = sprintf('%s ~ EngagementProj', response_var);
lm = fitlm(tbl, formula);
disp(lm)
% Average correlation
corr_mean = mean(corr_all(:), 'omitnan');
% p value using permutation test (each dataset)s correlation vs zero)
[corr_all_stats.p, corr_all_stats.obsDiff, corr_all_stats.effectSize] = permutationTest_updatedcb(mean(corr_all), zeros(size(mean(corr_all))), 10000, ...
                                                     'paired', 1, 'sidedness', 'both');



% convert to categorical
animal_id_all = categorical(animal_id_all);

response_var = strcat(axis_type, 'Proj');
tbl2 = table(proj_all, engagement_proj_all, animal_id_all, ...
    'VariableNames', {strcat(axis_type,'Proj'),'EngagementProj','AnimalID'});

formula2 = sprintf('%s ~ EngagementProj + (1|AnimalID)', response_var);

lme = fitlme(tbl2, formula2);
disp(lme)
end


