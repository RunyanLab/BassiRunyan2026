function aggregate = aggregate_svm_accuracy_by_population(accuracy, shuffled_accuracy, population_sizes, event_indices)
%AGGREGATE_SVM_ACCURACY_BY_POPULATION Preserve dataset and iteration levels.
%
% Input data may be a single split-by-iteration-by-celltype-by-population
% cell array, or the outer dataset cell array returned by
% wrapper_load_all_svm_data. Each inner cell contains one accuracy trace.
% Legacy 3-D inputs are treated as having one population size.
%
% Aggregation order:
%   1. Average cross-validation splits within each subsampling iteration,
%      producing one full time trace per iteration.
%   2. Average the requested event-window bins within each iteration
%      trace for the event-window scalar summaries.
%   3. Average iterations within each dataset.
% Dataset values are deliberately retained; splits, bins, and iterations
% are not pooled as independent biological replicates.

if nargin < 4 || isempty(event_indices)
    error('aggregate_svm_accuracy_by_population:MissingEventIndices', ...
        'event_indices must contain at least one time-bin index.');
end

validateattributes(population_sizes, {'numeric'}, {'vector', 'positive', 'finite'});
validateattributes(event_indices, {'numeric'}, {'vector', 'integer', 'positive'});
population_sizes = population_sizes(:)';
event_indices = event_indices(:)';

observed_datasets = normalize_dataset_input(accuracy, 'accuracy');
shuffled_datasets = normalize_dataset_input(shuffled_accuracy, 'shuffled_accuracy');
if numel(observed_datasets) ~= numel(shuffled_datasets)
    error('aggregate_svm_accuracy_by_population:DatasetMismatch', ...
        'Observed and shuffled inputs contain different numbers of datasets.');
end

n_datasets = numel(observed_datasets);
[n_celltypes, n_populations, n_time] = infer_common_shape( ...
    observed_datasets, shuffled_datasets, population_sizes);

if max(event_indices) > n_time
    error('aggregate_svm_accuracy_by_population:EventIndexOutOfRange', ...
        'event_indices extend beyond the %d available time bins.', n_time);
end

observed_iteration_values = cell(n_datasets, n_celltypes, n_populations);
shuffled_iteration_values = cell(n_datasets, n_celltypes, n_populations);
observed_iteration_traces = cell(n_datasets, n_celltypes, n_populations);
shuffled_iteration_traces = cell(n_datasets, n_celltypes, n_populations);
observed_dataset_values = nan(n_datasets, n_celltypes, n_populations);
shuffled_dataset_values = nan(n_datasets, n_celltypes, n_populations);
observed_dataset_traces = nan(n_datasets, n_celltypes, n_populations, n_time);
shuffled_dataset_traces = nan(n_datasets, n_celltypes, n_populations, n_time);
n_iterations_by_dataset = zeros(n_datasets, n_celltypes, n_populations);

for dataset_id = 1:n_datasets
    observed = observed_datasets{dataset_id};
    shuffled = shuffled_datasets{dataset_id};
    n_splits = size(observed, 1);
    n_iterations = size(observed, 2);

    for celltype_id = 1:n_celltypes
        for population_id = 1:n_populations
            observed_split_traces = nan(n_splits, n_iterations, n_time);
            shuffled_split_traces = nan(n_splits, n_iterations, n_time);

            for split_id = 1:n_splits
                for iteration_id = 1:n_iterations
                    observed_split_traces(split_id, iteration_id, :) = ...
                        get_trace(observed, split_id, iteration_id, ...
                        celltype_id, population_id, n_time);
                    shuffled_split_traces(split_id, iteration_id, :) = ...
                        get_trace(shuffled, split_id, iteration_id, ...
                        celltype_id, population_id, n_time);
                end
            end

            observed_traces = reshape(mean(observed_split_traces, 1, 'omitnan'), ...
                n_iterations, n_time);
            shuffled_traces = reshape(mean(shuffled_split_traces, 1, 'omitnan'), ...
                n_iterations, n_time);

            observed_values = mean(observed_traces(:, event_indices), 2, 'omitnan');
            shuffled_values = mean(shuffled_traces(:, event_indices), 2, 'omitnan');
            observed_values(all(isnan(observed_traces(:, event_indices)), 2)) = NaN;
            shuffled_values(all(isnan(shuffled_traces(:, event_indices)), 2)) = NaN;

            valid_observed = any(isfinite(observed_traces), 2);
            valid_shuffled = any(isfinite(shuffled_traces), 2);
            observed_traces = observed_traces(valid_observed, :);
            shuffled_traces = shuffled_traces(valid_shuffled, :);
            observed_values = observed_values(valid_observed);
            shuffled_values = shuffled_values(valid_shuffled);

            observed_iteration_values{dataset_id, celltype_id, population_id} = observed_values;
            shuffled_iteration_values{dataset_id, celltype_id, population_id} = shuffled_values;
            observed_iteration_traces{dataset_id, celltype_id, population_id} = observed_traces;
            shuffled_iteration_traces{dataset_id, celltype_id, population_id} = shuffled_traces;
            n_iterations_by_dataset(dataset_id, celltype_id, population_id) = numel(observed_values);

            if ~isempty(observed_values)
                observed_dataset_values(dataset_id, celltype_id, population_id) = ...
                    mean(observed_values, 'omitnan');
                observed_dataset_traces(dataset_id, celltype_id, population_id, :) = ...
                    mean(observed_traces, 1, 'omitnan');
            end
            if ~isempty(shuffled_values)
                shuffled_dataset_values(dataset_id, celltype_id, population_id) = ...
                    mean(shuffled_values, 'omitnan');
                shuffled_dataset_traces(dataset_id, celltype_id, population_id, :) = ...
                    mean(shuffled_traces, 1, 'omitnan');
            end
        end
    end
end

aggregate.population_sizes = population_sizes(1:n_populations);
aggregate.event_indices = event_indices;
aggregate.observed_iteration_values_by_dataset = observed_iteration_values;
aggregate.shuffled_iteration_values_by_dataset = shuffled_iteration_values;
aggregate.observed_iteration_traces_by_dataset = observed_iteration_traces;
aggregate.shuffled_iteration_traces_by_dataset = shuffled_iteration_traces;
aggregate.observed_dataset_values = observed_dataset_values;
aggregate.shuffled_dataset_values = shuffled_dataset_values;
aggregate.observed_dataset_traces = observed_dataset_traces;
aggregate.shuffled_dataset_traces = shuffled_dataset_traces;
aggregate.n_iterations_by_dataset = n_iterations_by_dataset;
aggregate.n_datasets = n_datasets;
aggregate.n_celltypes = n_celltypes;
aggregate.n_populations = n_populations;
aggregate.n_time_bins = n_time;
end

function datasets = normalize_dataset_input(input_data, input_name)
if ~iscell(input_data) || isempty(input_data)
    error('aggregate_svm_accuracy_by_population:InvalidInput', ...
        '%s must be a nonempty cell array.', input_name);
end

first_id = find(~cellfun(@isempty, input_data), 1, 'first');
if isempty(first_id)
    error('aggregate_svm_accuracy_by_population:EmptyInput', ...
        '%s contains no accuracy traces.', input_name);
end

if iscell(input_data{first_id})
    datasets = input_data(:);
else
    datasets = {input_data};
end
end

function [n_celltypes, n_populations, n_time] = infer_common_shape(observed, shuffled, population_sizes)
n_celltypes = 0;
n_populations = 0;
n_time = [];

for dataset_id = 1:numel(observed)
    obs = observed{dataset_id};
    shuff = shuffled{dataset_id};
    if ~iscell(obs) || ~iscell(shuff)
        error('aggregate_svm_accuracy_by_population:InvalidDataset', ...
            'Each dataset must be a cell array of accuracy traces.');
    end

    obs_shape = [size(obs, 1), size(obs, 2), size(obs, 3), size(obs, 4)];
    shuff_shape = [size(shuff, 1), size(shuff, 2), size(shuff, 3), size(shuff, 4)];
    if ~isequal(obs_shape, shuff_shape)
        error('aggregate_svm_accuracy_by_population:DimensionMismatch', ...
            'Observed and shuffled dimensions differ in dataset %d.', dataset_id);
    end

    n_celltypes = max(n_celltypes, obs_shape(3));
    n_populations = max(n_populations, obs_shape(4));
    traces = [obs(:); shuff(:)];
    for trace_id = 1:numel(traces)
        if isempty(traces{trace_id})
            continue
        end
        if ~isnumeric(traces{trace_id}) || ~isvector(traces{trace_id})
            error('aggregate_svm_accuracy_by_population:InvalidTrace', ...
                'Every populated result cell must contain a numeric vector.');
        end
        if isempty(n_time)
            n_time = numel(traces{trace_id});
        elseif numel(traces{trace_id}) ~= n_time
            error('aggregate_svm_accuracy_by_population:TraceLengthMismatch', ...
                'All observed and shuffled traces must have the same length.');
        end
    end
end

if isempty(n_time)
    error('aggregate_svm_accuracy_by_population:EmptyInput', ...
        'No numeric accuracy traces were found.');
end
if n_populations > numel(population_sizes)
    error('aggregate_svm_accuracy_by_population:PopulationMetadataMismatch', ...
        ['The data contain %d population indices, but only %d true neuron ' ...
        'counts were supplied.'], n_populations, numel(population_sizes));
end
end

function trace = get_trace(data, split_id, iteration_id, celltype_id, population_id, n_time)
trace = nan(1, 1, n_time);
if celltype_id > size(data, 3) || population_id > size(data, 4)
    return
end
value = data{split_id, iteration_id, celltype_id, population_id};
if isempty(value)
    return
end
trace(1, 1, :) = reshape(double(value), 1, 1, n_time);
end
