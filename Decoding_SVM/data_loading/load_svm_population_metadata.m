function metadata = load_svm_population_metadata( ...
    info, model_type, task_event_type, svm_suffix, accuracy)
%LOAD_SVM_POPULATION_METADATA Read true neuron counts from saved SVM models.
%
% The saved all_model_outputs entries contain mdl_param.population_size and
% mdl_param.requested_sizes. The latter is the mapping from population
% index to true neuron count; indices must never be used as neuron counts.

if nargin < 4
    svm_suffix = '';
end
if nargin < 5
    accuracy = [];
end

all_model_outputs = load_SVM_results( ...
    info, model_type, task_event_type, 'all_model_outputs', svm_suffix);

n_datasets = numel(all_model_outputs);
requested_sizes = [];
n_celltypes = 0;
n_populations = 0;
actual_sizes_by_dataset = cell(n_datasets, 1);

for dataset_id = 1:n_datasets
    models = all_model_outputs{dataset_id};
    n_celltypes = max(n_celltypes, size(models, 2));
    n_populations = max(n_populations, size(models, 3));
    actual_sizes = nan(size(models, 2), size(models, 3));

    for split_id = 1:size(models, 1)
        for celltype_id = 1:size(models, 2)
            for population_id = 1:size(models, 3)
                model = models{split_id, celltype_id, population_id};
                if isempty(model)
                    continue
                end
                if isempty(requested_sizes) && isfield(model, 'requested_sizes')
                    requested_sizes = model.requested_sizes(:)';
                end
                if isfield(model, 'population_size')
                    actual_sizes(celltype_id, population_id) = model.population_size;
                end
            end
        end
    end
    actual_sizes_by_dataset{dataset_id} = actual_sizes;
end

if isempty(requested_sizes)
    requested_sizes = infer_requested_sizes(actual_sizes_by_dataset, n_populations);
end
if numel(requested_sizes) < n_populations
    error('load_svm_population_metadata:IncompleteMetadata', ...
        'Saved metadata do not map every population index to a neuron count.');
end

valid_by_dataset = false(n_datasets, n_celltypes, numel(requested_sizes));
for dataset_id = 1:n_datasets
    actual_sizes = actual_sizes_by_dataset{dataset_id};
    for celltype_id = 1:size(actual_sizes, 1)
        for population_id = 1:size(actual_sizes, 2)
            value = actual_sizes(celltype_id, population_id);
            if isfinite(value)
                mapped_id = find(requested_sizes == value, 1);
                if ~isempty(mapped_id)
                    valid_by_dataset(dataset_id, celltype_id, mapped_id) = true;
                end
            end
        end
    end
end

n_iterations_by_dataset = [];
if ~isempty(accuracy)
    [valid_from_accuracy, n_iterations_by_dataset] = inspect_accuracy( ...
        accuracy, n_celltypes, numel(requested_sizes));
    valid_by_dataset = valid_by_dataset | valid_from_accuracy;
end

valid_population_sizes_by_celltype = cell(n_celltypes, 1);
for celltype_id = 1:n_celltypes
    valid_ids = reshape(any(valid_by_dataset(:, celltype_id, :), 1), 1, []);
    valid_population_sizes_by_celltype{celltype_id} = requested_sizes(valid_ids);
end

metadata.population_sizes = requested_sizes;
metadata.requested_population_sizes = requested_sizes;
metadata.valid_population_mask_by_dataset = valid_by_dataset;
metadata.valid_population_sizes_by_celltype = valid_population_sizes_by_celltype;
metadata.n_iterations_by_dataset = n_iterations_by_dataset;
metadata.n_iterations_by_celltype = collapse_iteration_counts(n_iterations_by_dataset);
metadata.actual_population_sizes_by_dataset = actual_sizes_by_dataset;
metadata.all_model_outputs = all_model_outputs;
metadata.celltype_labels = {'Pyr', 'SOM', 'PV', 'Ranked Pyr'};
metadata.deterministic_celltypes = 4;
metadata.population_index_is_neuron_count = false;
end

function requested_sizes = infer_requested_sizes(actual_sizes_by_dataset, n_populations)
requested_sizes = nan(1, n_populations);
for dataset_id = 1:numel(actual_sizes_by_dataset)
    values = actual_sizes_by_dataset{dataset_id};
    for population_id = 1:size(values, 2)
        candidate = values(:, population_id);
        candidate = candidate(isfinite(candidate));
        if ~isempty(candidate)
            requested_sizes(population_id) = candidate(1);
        end
    end
end
if any(~isfinite(requested_sizes))
    error('load_svm_population_metadata:MissingPopulationSizes', ...
        'Could not recover all population-index mappings from saved results.');
end
end

function [valid_mask, iteration_counts] = inspect_accuracy(accuracy, n_celltypes, n_populations)
if iscell(accuracy) && ~isempty(accuracy) && iscell(accuracy{1})
    datasets = accuracy(:);
else
    datasets = {accuracy};
end
n_datasets = numel(datasets);
valid_mask = false(n_datasets, n_celltypes, n_populations);
iteration_counts = zeros(n_datasets, n_celltypes, n_populations);

for dataset_id = 1:n_datasets
    data = datasets{dataset_id};
    for celltype_id = 1:min(n_celltypes, size(data, 3))
        for population_id = 1:min(n_populations, size(data, 4))
            valid_iterations = false(1, size(data, 2));
            for iteration_id = 1:size(data, 2)
                entries = data(:, iteration_id, celltype_id, population_id);
                valid_iterations(iteration_id) = any(cellfun( ...
                    @(x) isnumeric(x) && any(isfinite(x(:))), entries));
            end
            valid_mask(dataset_id, celltype_id, population_id) = any(valid_iterations);
            iteration_counts(dataset_id, celltype_id, population_id) = sum(valid_iterations);
        end
    end
end
end

function counts = collapse_iteration_counts(iteration_counts)
if isempty(iteration_counts)
    counts = [];
else
    counts = zeros(1, size(iteration_counts, 2));
    for celltype_id = 1:size(iteration_counts, 2)
        values = reshape(iteration_counts(:, celltype_id, :), [], 1);
        counts(celltype_id) = max(values);
    end
end
end
