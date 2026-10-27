%% Neuron-dropping analysis for population-subsampled SVM outputs, all task events
% Same analysis as run_analysis_SVM_glm_inputs_final_subsampled_populations.m,
% run for sound_category, choice and outcome. Adds two population subsets of
% the dataset neuron-dropping figure (Pyr/SOM/PV only; Ranked Pyr only) and
% paired, matched-N comparisons of decoding accuracy between populations.
% Update the two site-specific paths below when running outside the original
% environment.

addpath(genpath('C:\Code\Github\BassiRunyan2025\Decoding_SVM'));

load('V:\Connie\results\opto_2024\context\data_info\info.mat');

event_types = {'sound_category', 'choice', 'outcome'};
model_type = 'GLM_3nmf_pre';
svm_suffix = '_1';
results_dir = 'W:\Connie\results\Bassi2025\fig2\SVM_1';

% Cell-type indices in acc_active: 1 Pyr, 2 SOM, 3 PV, 4 Ranked Pyr
subset_plots = struct( ...
    'name', {'celltypes', 'ranked_pyr'}, ...
    'celltype_ids', {1:3, 4});
population_pairs = [1 2; 1 3; 2 3; 4 1]; % Pyr-SOM, Pyr-PV, SOM-PV, Ranked Pyr-Pyr
min_paired_datasets = 6; % with <= 5 pairs, signrank cannot reach p < 0.05 (two-sided)

plot_defaults = default_plot_info([]);
celltype_colors = plot_defaults.colors_celltype([1:3,5],:); % wrapper_plot_svm_neuron_dropping default

all_population_stats = cell(numel(event_types), 1);

for event_id = 1:numel(event_types)
    clear acc_active shuff_acc_active beta_active acc_active_top shuff_acc_active_top ...
        svm_metadata first_dataset_models mdl_param all_model_outputs event_onsets ...
        event_window_indices savepath neuron_dropping_summary neuron_dropping_figure ...
        dataset_plot_summary population_stats

    info.task_event_type = event_types{event_id};
    [current_mice, onset_id, active_events] = default_data_info(info.task_event_type);
    info.chosen_mice = current_mice;

    %% Load accuracies and true population-size metadata
    % Beta files are intentionally absent for these fits; beta_active is [].
    [acc_active, shuff_acc_active, beta_active, ...
        acc_active_top, shuff_acc_active_top, svm_metadata] = ...
        wrapper_load_all_svm_data( ...
            info, ...
            model_type, ...
            [info.task_event_type '_subsampled'], ...
            [], ...
            svm_suffix);

    assert(isempty(beta_active), ...
        'Population-subsampled SVM analyses should not depend on beta outputs.');

    % load_SVM_results keeps only datasets whose result file exists, so
    % dataset d of acc_active is the d-th loaded dataset, not chosen_mice(d).
    loaded_mouse_dates = loaded_svm_datasets(info, model_type, ...
        [info.task_event_type '_subsampled'], 'acc', svm_suffix);
    assert(numel(loaded_mouse_dates) == numel(acc_active), ...
        'Could not match loaded SVM datasets to info.mouse_date.');
    dataset_mouse_ids = cellfun(@(x) strtok(x, '/\'), loaded_mouse_dates, ...
        'UniformOutput', false);

    % acc_active_top/shuff_acc_active_top are empty because top_suffix is empty.
    % In these population fits, cell type 4 inside acc_active is already the
    % deterministic cumulative ranked-pyramidal analysis.

    %% Reconstruct event indices exactly as in the existing plotting workflow
    first_dataset_models = svm_metadata.all_model_outputs{1};
    mdl_param = first_dataset_models{1, 1, 1};
    event_onsets = find(histcounts( ...
        active_events, mdl_param.binns + active_events(1)));

    % wrapper_plot_accuracy_boxplots passes event_onsets(onset_id) and
    % plot_svm_across_datasets_barplots uses onset:(onset+4), inclusive.
    info.chosen_mice = 2;
    all_model_outputs = load_SVM_results(info,'GLM_3nmf_pre','sound_category','all_model_outputs','_1');
    event_onsets = find(histcounts(active_events,all_model_outputs{1,1}{1}.binns+active_events(1)));%find(histcounts(all_model_outputs{1,1}{1}.event_onset,all_model_outputs{1,1}{1}.binns+mdl_param.event_onset(1)));
    event_window_indices = event_onsets(onset_id):(event_onsets(onset_id) + 4);
    info.chosen_mice = current_mice;
    fprintf('%s: onset_id %d, event window bins %s, %d datasets\n', ...
        info.task_event_type, onset_id, mat2str(event_window_indices), numel(acc_active));

    savepath = fullfile(results_dir, [info.task_event_type '_neuron_dropping']);

    %% Primary reviewer-facing figure: raw accuracy and observed-minus-shuffled
    [neuron_dropping_summary, neuron_dropping_figure] = ...
        wrapper_plot_svm_neuron_dropping_final( ...
            acc_active, shuff_acc_active, ...
            svm_metadata.population_sizes, event_window_indices, ...
            savepath, [info.task_event_type '_neuron_dropping'], ...
            'CellTypeLabels', svm_metadata.celltype_labels, ...
            'DeterministicCellTypes', svm_metadata.deterministic_celltypes, ...
            'ReplicationUnit', 'datasets', ...
            'ShowIndividualDatasets', false,'xScale','log','MaxPopulation', [100 10 20 100]); %pyr, som, pv, ranked pyr

    %% Optional dataset overlays and normalized saturation-rate figure
    % All four populations (unchanged figure)
    dataset_plot_summary = wrapper_plot_svm_neuron_dropping( ...
        acc_active, shuff_acc_active, ...
        svm_metadata.population_sizes, event_window_indices, ...
        savepath, [info.task_event_type '_neuron_dropping_datasets'], ...
        'CellTypeLabels', svm_metadata.celltype_labels, ...
        'DeterministicCellTypes', svm_metadata.deterministic_celltypes, ...
        'ShowIndividualDatasets', true);

    % Same results and formatting, restricted to a subset of populations
    for subset_id = 1:numel(subset_plots)
        celltype_ids = subset_plots(subset_id).celltype_ids;
        wrapper_plot_svm_neuron_dropping( ...
            select_celltypes(acc_active, celltype_ids), ...
            select_celltypes(shuff_acc_active, celltype_ids), ...
            svm_metadata.population_sizes, event_window_indices, ...
            savepath, [info.task_event_type '_neuron_dropping_' subset_plots(subset_id).name], ...
            'CellTypeLabels', svm_metadata.celltype_labels(celltype_ids), ...
            'Colors', celltype_colors(celltype_ids, :), ...
            'DeterministicCellTypes', find(ismember(celltype_ids, svm_metadata.deterministic_celltypes)), ...
            'ShowIndividualDatasets', true);
    end

    wrapper_plot_svm_neuron_dropping( ...
        acc_active, shuff_acc_active, ...
        svm_metadata.population_sizes, event_window_indices, ...
        savepath, [info.task_event_type '_neuron_dropping_normalized'], ...
        'CellTypeLabels', svm_metadata.celltype_labels, ...
        'DeterministicCellTypes', svm_metadata.deterministic_celltypes, ...
        'Representation', 'normalized_to_largest');

    %% Selected-population time courses for a randomly sampled cell type
    selected_population_sizes = [1, 3, 5, 7, 10, 20, 50];
    for celltype_id = 1:4 % Pyr
        celltype_string = svm_metadata.celltype_labels{celltype_id};
        wrapper_plot_svm_acc_trace_by_population( ...
            acc_active, shuff_acc_active, svm_metadata.population_sizes, ...
            selected_population_sizes, celltype_id, mdl_param, event_onsets, ...
            savepath, [info.task_event_type '_population_traces' celltype_string], ...
            'ShowShuffled', true, 'YLimits', [0.45, 0.9]);
    end

    %% Optional observed-minus-shuffled time-by-population heatmap
    plot_svm_population_time_heatmap( ...
        acc_active, shuff_acc_active, svm_metadata.population_sizes, ...
        celltype_id, event_onsets, savepath, ...
        [info.task_event_type '_population_heatmap'], ...
        'Mode', 'observed-minus-shuffled');

    %% Matched-N population comparisons (paired across datasets)
    % Inputs are the dataset-level event-window accuracies plotted in the
    % *_neuron_dropping_datasets figure (CV splits -> event bins -> subsampling
    % iterations averaged within each dataset).
    population_stats = compare_populations_matched_n(dataset_plot_summary, ...
        population_pairs, info.task_event_type, dataset_mouse_ids, min_paired_datasets);
    writetable(population_stats, fullfile(savepath, ...
        [info.task_event_type '_neuron_dropping_population_stats.csv']));
    save(fullfile(savepath, [info.task_event_type '_neuron_dropping_population_stats.mat']), ...
        'population_stats');
    disp(population_stats);
    all_population_stats{event_id} = population_stats;
end

all_population_stats = vertcat(all_population_stats{~cellfun(@isempty, all_population_stats)});
writetable(all_population_stats, fullfile(results_dir, ...
    'neuron_dropping_population_stats_all_events.csv'));

%% Local functions
function out = select_celltypes(accuracy, celltype_ids)
% Keep the requested cell types (3rd dimension) of each dataset's
% {split, iteration, celltype, population} result cell.
out = accuracy;
for dataset_id = 1:numel(accuracy)
    data = accuracy{dataset_id};
    if isempty(data)
        continue
    end
    selected = cell(size(data, 1), size(data, 2), numel(celltype_ids), size(data, 4));
    present = celltype_ids <= size(data, 3);
    selected(:, :, present, :) = data(:, :, celltype_ids(present), :);
    out{dataset_id} = selected;
end
end

function mouse_dates = loaded_svm_datasets(info, model_type, task_event_type, result_name, svm_suffix)
% Dataset order and file-existence rule of load_SVM_results (server layout).
mouse_dates = {};
for n = 1:numel(info.chosen_mice)
    mm = info.mouse_date{info.chosen_mice(n)};
    ss = info.serverid{info.chosen_mice(n)};
    filepath = fullfile(num2str(ss), 'Connie', 'ProcessedData', mm, model_type, ...
        'decoding', ['SVM' svm_suffix], sprintf('%s_%s.mat', task_event_type, result_name));
    if exist(filepath, 'file')
        mouse_dates{end + 1} = mm; %#ok<AGROW>
    end
end
end

function stats = compare_populations_matched_n(summary, pairs, event_type, mouse_ids, min_n)
% Paired Wilcoxon signed-rank tests across datasets at each shared neuron
% count, BH-FDR corrected across all tests of this event type. Accuracies
% are reported in percent (the plotted units).
values = summary.observed_dataset_values; % datasets x celltypes x populations
labels = summary.celltype_labels;

% statistical inputs are the values behind the plotted means
for celltype_id = 1:size(values, 2)
    for population_id = 1:size(values, 3)
        x = values(:, celltype_id, population_id);
        x = x(isfinite(x));
        if ~isempty(x)
            assert(abs(mean(x) - summary.observed_mean(celltype_id, population_id)) < 1e-10);
        end
    end
end

rows = {};
for pair_id = 1:size(pairs, 1)
    a = pairs(pair_id, 1);
    b = pairs(pair_id, 2);
    for population_id = 1:numel(summary.population_sizes)
        if ~(summary.valid_population_mask(a, population_id) && ...
                summary.valid_population_mask(b, population_id))
            continue
        end
        value_a = values(:, a, population_id);
        value_b = values(:, b, population_id);
        paired = isfinite(value_a) & isfinite(value_b);
        n_paired = sum(paired);
        if n_paired == 0
            continue
        end
        difference = value_a(paired) - value_b(paired);
        p_value = NaN;
        if n_paired >= min_n && any(difference ~= 0)
            p_value = signrank(value_a(paired), value_b(paired));
        end
        rows(end + 1, :) = {event_type, labels{a}, labels{b}, ...
            summary.population_sizes(population_id), n_paired, ...
            numel(unique(mouse_ids(paired))), ...
            100 * median(value_a(paired)), 100 * median(value_b(paired)), ...
            100 * median(difference), p_value}; %#ok<AGROW>
    end
end

variable_names = {'event_type', 'population_A', 'population_B', 'n_neurons', ...
    'n_paired_datasets', 'n_mice', 'accuracy_A_median_pct', ...
    'accuracy_B_median_pct', 'difference_median_pct', 'p_value'};
if isempty(rows)
    stats = cell2table(cell(0, numel(variable_names)), 'VariableNames', variable_names);
    stats.fdr_p = zeros(0, 1);
    return
end
stats = cell2table(rows, 'VariableNames', variable_names);
stats.fdr_p = bh_fdr(stats.p_value);
end

function q = bh_fdr(p)
% Benjamini-Hochberg adjusted p-values; NaN p-values are left as NaN and
% are not counted as tests.
q = nan(size(p));
tested = isfinite(p);
m = sum(tested);
if m == 0
    return
end
[p_sorted, order] = sort(p(tested));
q_sorted = p_sorted(:) .* m ./ (1:m)';
q_sorted = min(1, flipud(cummin(flipud(q_sorted))));
q_tested = nan(m, 1);
q_tested(order) = q_sorted;
q(tested) = q_tested;
end
