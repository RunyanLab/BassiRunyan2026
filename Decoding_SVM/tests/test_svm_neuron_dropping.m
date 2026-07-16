function tests_passed = test_svm_neuron_dropping()
%TEST_SVM_NEURON_DROPPING Synthetic validation for population summaries.

warning_state = warning('query', ...
    'summarize_svm_accuracy_by_population:DeterministicCellType');
cleanup = onCleanup(@() warning(warning_state.state, warning_state.identifier)); %#ok<NASGU>
warning('off', 'summarize_svm_accuracy_by_population:DeterministicCellType');

population_sizes = [1:7, 10, 15, 20, 25, 50, 100];
n_splits = 2;
n_iterations = 3;
n_celltypes = 4;
n_populations = numel(population_sizes);
n_time = 5;
accuracy = cell(n_splits, n_iterations, n_celltypes, n_populations);
shuffled = cell(size(accuracy));

max_population_id = [13, 8, 10, 5];
for celltype_id = 1:n_celltypes
    for population_id = 1:max_population_id(celltype_id)
        if celltype_id == 3 && population_id == 4
            continue % Explicitly missing nontrailing population.
        end
        iteration_ids = 1:n_iterations;
        if celltype_id == 4
            iteration_ids = 1; % Deterministic ranked-neuron population.
        end
        for iteration_id = iteration_ids
            for split_id = 1:n_splits
                base = celltype_id * 0.1 + population_id * 0.01 + ...
                    iteration_id * 0.001 + split_id * 0.0001;
                accuracy{split_id, iteration_id, celltype_id, population_id} = ...
                    base + (0:(n_time - 1)) * 0.01;
                shuffled{split_id, iteration_id, celltype_id, population_id} = ...
                    0.5 + split_id * 0.0001 + (0:(n_time - 1)) * 0.001;
            end
        end
    end
end

% Trailing NaN entries are invalid rather than real populations.
accuracy{1, 1, 2, 9} = nan(1, n_time);
shuffled{1, 1, 2, 9} = nan(1, n_time);

summary = summarize_svm_accuracy_by_population( ...
    accuracy, shuffled, population_sizes, [2, 3], ...
    'ReplicationUnit', 'iterations');

% Known event-window mean: split mean after averaging bins 2 and 3.
expected = 0.1 + 0.01 + 0.001 + mean([1, 2]) * 0.0001 + mean([0.01, 0.02]);
actual = summary.observed_iteration_values{1, 1}(1, 1);
assert(abs(actual - expected) < 1e-12, ...
    'Known event-window mean was not reproduced.');

assert(summary.population_sizes(8) == 10, ...
    'Population index 8 must map to 10 neurons.');
assert(abs(summary.gain_per_added_neuron(1, 8) - (0.01 / 3)) < 1e-12, ...
    'Incremental gain must use the true nonuniform neuron-count step.');
assert(summary.valid_population_mask(1, 13), ...
    'The largest valid population for cell type 1 was lost.');
assert(~summary.valid_population_mask(2, 9), ...
    'A trailing all-NaN population was treated as valid.');
assert(~summary.valid_population_mask(3, 4), ...
    'A missing nonconsecutive population was treated as valid.');
assert(summary.valid_population_mask(3, 5), ...
    'A valid population after a missing index was incorrectly removed.');
assert(summary.n_iterations_by_dataset(1, 4, 1) == 1, ...
    'Cell type 4 must retain its singleton deterministic iteration.');
assert(isnan(summary.observed_sem(4, 1)), ...
    'SEM must be NaN for deterministic cell type 4 under iteration replication.');
assert(~summary.inference_available(4, 1), ...
    'Inference must be disabled for deterministic cell type 4 under iteration replication.');
assert(summary.observed_sem(1, 1) > 0, ...
    'Repeated random iterations should produce descriptive uncertainty.');

% Multiple outer datasets must remain inspectable.
summary_two_datasets = summarize_svm_accuracy_by_population( ...
    {accuracy, accuracy}, {shuffled, shuffled}, population_sizes, [2, 3]);
assert(size(summary_two_datasets.observed_dataset_values, 1) == 2, ...
    'The outer dataset dimension was not retained.');
assert(summary_two_datasets.n_observed(1, 1) == 2, ...
    'Dataset-level replication count is incorrect.');
assert(isfinite(summary_two_datasets.observed_sem(4, 1)), ...
    'Dataset-level SEM should be available for ranked-pyr when n_datasets > 1.');
assert(summary_two_datasets.inference_available(4, 1), ...
    'Dataset-level inference should be available for ranked-pyr when n_datasets > 1.');

% Legacy 3-D data are interpreted as one population.
legacy_accuracy = accuracy(:, :, :, 1);
legacy_shuffled = shuffled(:, :, :, 1);
legacy_summary = summarize_svm_accuracy_by_population( ...
    legacy_accuracy, legacy_shuffled, 7, [2, 3], ...
    'DeterministicCellTypes', 4);
assert(isequal(size(legacy_summary.observed_mean), [4, 1]), ...
    'Legacy 3-D input was not treated as one population.');
assert(legacy_summary.population_sizes == 7);

% Singleton iteration/cell-type/population dimensions must not collapse.
singleton_accuracy = cell(2, 1, 1, 1);
singleton_shuffled = cell(2, 1, 1, 1);
singleton_accuracy(:, 1, 1, 1) = {[0.6, 0.7]; [0.8, 0.9]};
singleton_shuffled(:, 1, 1, 1) = {[0.5, 0.5]; [0.5, 0.5]};
singleton_summary = summarize_svm_accuracy_by_population( ...
    singleton_accuracy, singleton_shuffled, 1, 1:2, ...
    'DeterministicCellTypes', []);
assert(abs(singleton_summary.observed_mean - 0.75) < 1e-12);
assert(isnan(singleton_summary.observed_sem), ...
    'SEM must be NaN when only one replicate is available.');

% Mismatched observed/shuffled dimensions must fail clearly.
dimension_error_thrown = false;
try
    summarize_svm_accuracy_by_population( ...
        accuracy, shuffled(:, 1:2, :, :), population_sizes, [2, 3]);
catch exception
    dimension_error_thrown = strcmp(exception.identifier, ...
        'aggregate_svm_accuracy_by_population:DimensionMismatch');
end
assert(dimension_error_thrown, ...
    'Mismatched observed/shuffled dimensions did not raise the expected error.');

tests_passed = true;
fprintf('test_svm_neuron_dropping: all synthetic tests passed.\n');
end
