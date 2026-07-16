function summary = summarize_svm_accuracy_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, event_indices, varargin)
%SUMMARIZE_SVM_ACCURACY_BY_POPULATION Event-window neuron-dropping summary.
%
% By default, uncertainty uses datasets/animals, matching the existing
% boxplot workflow: splits -> event-window bins -> iterations are averaged
% before datasets are compared. Set 'ReplicationUnit' to 'iterations' only
% for a descriptive view of random-subsampling variability; those
% iterations are not independent biological replicates. Deterministic
% ranked-neuron cell types suppress iteration-level SEM, but retain
% dataset-level SEM when ReplicationUnit=datasets.

p = inputParser;
addParameter(p, 'DeterministicCellTypes', 4, ...
    @(x) isnumeric(x) && (isempty(x) || isvector(x)));
addParameter(p, 'ReplicationUnit', 'datasets', ...
    @(x) any(strcmpi(x, {'datasets', 'iterations'})));
addParameter(p, 'CellTypeLabels', {}, ...
    @(x) isempty(x) || iscellstr(x) || isstring(x)); %#ok<ISCLSTR>
parse(p, varargin{:});

aggregate = aggregate_svm_accuracy_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, event_indices);

n_celltypes = aggregate.n_celltypes;
n_populations = aggregate.n_populations;
n_datasets = aggregate.n_datasets;
deterministic_celltypes = p.Results.DeterministicCellTypes(:)';
replication_unit = lower(p.Results.ReplicationUnit);

observed_iteration_values = cell(n_celltypes, n_populations);
shuffled_iteration_values = cell(n_celltypes, n_populations);
observed_mean = nan(n_celltypes, n_populations);
shuffled_mean = nan(n_celltypes, n_populations);
observed_sem = nan(n_celltypes, n_populations);
shuffled_sem = nan(n_celltypes, n_populations);
n_observed = zeros(n_celltypes, n_populations);
n_shuffled = zeros(n_celltypes, n_populations);
valid_population_mask = false(n_celltypes, n_populations);
inference_available = false(n_celltypes, n_populations);
status = repmat({''}, n_celltypes, n_populations);

for celltype_id = 1:n_celltypes
    for population_id = 1:n_populations
        observed_matrix = iteration_matrix( ...
            aggregate.observed_iteration_values_by_dataset(:, celltype_id, population_id));
        shuffled_matrix = iteration_matrix( ...
            aggregate.shuffled_iteration_values_by_dataset(:, celltype_id, population_id));
        observed_iteration_values{celltype_id, population_id} = observed_matrix;
        shuffled_iteration_values{celltype_id, population_id} = shuffled_matrix;

        if strcmp(replication_unit, 'datasets')
            observed_replicates = reshape( ...
                aggregate.observed_dataset_values(:, celltype_id, population_id), [], 1);
            shuffled_replicates = reshape( ...
                aggregate.shuffled_dataset_values(:, celltype_id, population_id), [], 1);
        else
            observed_replicates = observed_matrix(:);
            shuffled_replicates = shuffled_matrix(:);
        end
        observed_replicates = observed_replicates(isfinite(observed_replicates));
        shuffled_replicates = shuffled_replicates(isfinite(shuffled_replicates));

        n_observed(celltype_id, population_id) = numel(observed_replicates);
        n_shuffled(celltype_id, population_id) = numel(shuffled_replicates);
        valid_population_mask(celltype_id, population_id) = ...
            ~isempty(observed_replicates) && ~isempty(shuffled_replicates);

        if ~isempty(observed_replicates)
            observed_mean(celltype_id, population_id) = mean(observed_replicates);
        end
        if ~isempty(shuffled_replicates)
            shuffled_mean(celltype_id, population_id) = mean(shuffled_replicates);
        end

        is_deterministic = ismember(celltype_id, deterministic_celltypes);
        % Deterministic cell types have only one subsampling iteration, so
        % iteration-level SEM/inference is unavailable. Dataset-level SEM
        % remains valid because each dataset still contributes one value.
        suppress_iteration_uncertainty = is_deterministic && ...
            strcmp(replication_unit, 'iterations');
        if suppress_iteration_uncertainty
            status{celltype_id, population_id} = ...
                ['deterministic selection with ReplicationUnit=iterations: ' ...
                'descriptive summary only; SEM unavailable'];
        else
            observed_sem(celltype_id, population_id) = sem_or_nan(observed_replicates);
            shuffled_sem(celltype_id, population_id) = sem_or_nan(shuffled_replicates);
            inference_available(celltype_id, population_id) = ...
                numel(observed_replicates) > 1 && numel(shuffled_replicates) > 1;
            if is_deterministic && strcmp(replication_unit, 'datasets')
                status{celltype_id, population_id} = ...
                    ['deterministic selection: SEM/inference use dataset ' ...
                    'replication, not neuron-subset iterations'];
            elseif ~inference_available(celltype_id, population_id)
                status{celltype_id, population_id} = ...
                    'fewer than two valid replicates: SEM and inference unavailable';
            end
        end
    end
end

difference_dataset_values = aggregate.observed_dataset_values - ...
    aggregate.shuffled_dataset_values;
difference_mean = nan(n_celltypes, n_populations);
difference_sem = nan(n_celltypes, n_populations);
for celltype_id = 1:n_celltypes
    for population_id = 1:n_populations
        if strcmp(replication_unit, 'datasets')
            values = reshape(difference_dataset_values(:, celltype_id, population_id), [], 1);
        else
            observed_values = observed_iteration_values{celltype_id, population_id};
            shuffled_values = shuffled_iteration_values{celltype_id, population_id};
            [observed_values, shuffled_values] = pad_to_same_size( ...
                observed_values, shuffled_values);
            values = observed_values - shuffled_values;
            values = values(:);
        end
        values = values(isfinite(values));
        if ~isempty(values)
            difference_mean(celltype_id, population_id) = mean(values);
        end
        suppress_iteration_uncertainty = ismember(celltype_id, deterministic_celltypes) && ...
            strcmp(replication_unit, 'iterations');
        if ~suppress_iteration_uncertainty
            difference_sem(celltype_id, population_id) = sem_or_nan(values);
        end
    end
end

population_step = [NaN, diff(aggregate.population_sizes)];
incremental_gain = [nan(n_celltypes, 1), diff(observed_mean, 1, 2)];
gain_per_added_neuron = incremental_gain ./ population_step;
incremental_gain(~valid_population_mask) = NaN;
gain_per_added_neuron(~valid_population_mask) = NaN;

summary.population_sizes = aggregate.population_sizes;
summary.event_indices = aggregate.event_indices;
summary.observed_iteration_values = observed_iteration_values;
summary.shuffled_iteration_values = shuffled_iteration_values;
summary.observed_iteration_values_by_dataset = ...
    aggregate.observed_iteration_values_by_dataset;
summary.shuffled_iteration_values_by_dataset = ...
    aggregate.shuffled_iteration_values_by_dataset;
summary.observed_dataset_values = aggregate.observed_dataset_values;
summary.shuffled_dataset_values = aggregate.shuffled_dataset_values;
summary.difference_dataset_values = difference_dataset_values;
summary.observed_mean = observed_mean;
summary.shuffled_mean = shuffled_mean;
summary.difference_mean = difference_mean;
summary.observed_sem = observed_sem;
summary.shuffled_sem = shuffled_sem;
summary.difference_sem = difference_sem;
summary.n_observed = n_observed;
summary.n_shuffled = n_shuffled;
summary.valid_population_mask = valid_population_mask;
summary.inference_available = inference_available;
summary.status = status;
summary.n_iterations_by_dataset = aggregate.n_iterations_by_dataset;
summary.replication_unit = replication_unit;
summary.deterministic_celltypes = deterministic_celltypes;
summary.incremental_gain = incremental_gain;
summary.gain_per_added_neuron = gain_per_added_neuron;
summary.aggregate = aggregate;
summary.celltype_labels = make_labels(p.Results.CellTypeLabels, n_celltypes);
summary.n_datasets = n_datasets;
summary.matched_celltype_comparisons = make_matched_comparisons( ...
    observed_mean, aggregate.observed_dataset_values, valid_population_mask);

if any(deterministic_celltypes <= n_celltypes) && strcmp(replication_unit, 'iterations')
    warning('summarize_svm_accuracy_by_population:DeterministicCellType', ...
        ['Deterministic cell type(s) %s have a single neuron-selection ' ...
        'iteration. With ReplicationUnit=iterations, SEM and inference ' ...
        'are unavailable for those cell types.'], ...
        mat2str(deterministic_celltypes(deterministic_celltypes <= n_celltypes)));
end
end

function matrix = iteration_matrix(values_by_dataset)
n_datasets = numel(values_by_dataset);
n_iterations = 0;
for dataset_id = 1:n_datasets
    n_iterations = max(n_iterations, numel(values_by_dataset{dataset_id}));
end
matrix = nan(n_datasets, n_iterations);
for dataset_id = 1:n_datasets
    values = values_by_dataset{dataset_id};
    if ~isempty(values)
        matrix(dataset_id, 1:numel(values)) = values(:)';
    end
end
end

function value = sem_or_nan(values)
if numel(values) < 2
    value = NaN;
else
    value = std(values, 0, 'omitnan') / sqrt(numel(values));
end
end

function [a, b] = pad_to_same_size(a, b)
n_rows = max(size(a, 1), size(b, 1));
n_columns = max(size(a, 2), size(b, 2));
a_padded = nan(n_rows, n_columns);
b_padded = nan(n_rows, n_columns);
a_padded(1:size(a, 1), 1:size(a, 2)) = a;
b_padded(1:size(b, 1), 1:size(b, 2)) = b;
a = a_padded;
b = b_padded;
end

function labels = make_labels(input_labels, n_celltypes)
default_labels = {'Pyr', 'SOM', 'PV', 'Ranked Pyr'};
if isempty(input_labels)
    labels = default_labels;
elseif isstring(input_labels)
    labels = cellstr(input_labels);
else
    labels = input_labels;
end
if numel(labels) < n_celltypes
    for celltype_id = (numel(labels) + 1):n_celltypes
        labels{celltype_id} = sprintf('Cell type %d', celltype_id); %#ok<AGROW>
    end
end
labels = labels(1:n_celltypes);
end

function comparisons = make_matched_comparisons(means, dataset_values, valid_mask)
if size(means, 1) < 2
    comparisons = struct('celltype_pairs', [], 'matched_population_mask', [], ...
        'descriptive_mean_difference', [], 'paired_dataset_differences', {{}});
    return
end
pairs = nchoosek(1:size(means, 1), 2);
matched_mask = false(size(pairs, 1), size(means, 2));
mean_difference = nan(size(pairs, 1), size(means, 2));
paired_dataset_differences = cell(size(pairs, 1), size(means, 2));
for pair_id = 1:size(pairs, 1)
    first = pairs(pair_id, 1);
    second = pairs(pair_id, 2);
    matched_mask(pair_id, :) = valid_mask(first, :) & valid_mask(second, :);
    mean_difference(pair_id, matched_mask(pair_id, :)) = ...
        means(first, matched_mask(pair_id, :)) - ...
        means(second, matched_mask(pair_id, :));
    for population_id = find(matched_mask(pair_id, :))
        paired_dataset_differences{pair_id, population_id} = ...
            reshape(dataset_values(:, first, population_id) - ...
            dataset_values(:, second, population_id), [], 1);
    end
end
comparisons.celltype_pairs = pairs;
comparisons.matched_population_mask = matched_mask;
comparisons.descriptive_mean_difference = mean_difference;
comparisons.paired_dataset_differences = paired_dataset_differences;
comparisons.inferential_tests_performed = false;
comparisons.note = ['Matched population sizes only. No inferential tests are ' ...
    'performed automatically; dataset values are retained for justified tests.'];
end
