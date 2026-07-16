function [summary, figure_handle] = wrapper_plot_svm_neuron_dropping_final( ...
    accuracy, shuffled_accuracy, population_sizes, event_indices, savepath, save_string, varargin)
%WRAPPER_PLOT_SVM_NEURON_DROPPING Plot event-window accuracy vs neuron count.
%
% Panel 1 shows observed accuracy (solid) and empirical shuffled accuracy
% (light dashed).Group uncertainty defaults to datasets, the replication unit used by the existing boxplot.

if nargin < 5
    savepath = '';
end
if nargin < 6 || isempty(save_string)
    save_string = 'svm_neuron_dropping';
end

p = inputParser;
plot_defaults = default_plot_info([]);
addParameter(p, 'CellTypeLabels', {'Pyr', 'SOM', 'PV', 'Ranked Pyr'});
addParameter(p, 'Colors', plot_defaults.colors_celltype([1:3,5],:), @isnumeric);
addParameter(p, 'DeterministicCellTypes', 4, @isnumeric);
addParameter(p, 'ReplicationUnit', 'datasets', ...
    @(x) any(strcmpi(x, {'datasets', 'iterations'})));
addParameter(p, 'ShowIndividualDatasets', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'Representation', 'raw', ...
    @(x) any(strcmpi(x, {'raw', 'normalized_to_largest'})));
addParameter(p, 'YLimits', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
addParameter(p, 'Visible', 'on', @(x) any(strcmpi(x, {'on', 'off'})));
parse(p, varargin{:});

summary = summarize_svm_accuracy_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, event_indices, ...
    'DeterministicCellTypes', p.Results.DeterministicCellTypes, ...
    'ReplicationUnit', p.Results.ReplicationUnit, ...
    'CellTypeLabels', p.Results.CellTypeLabels);

colors = p.Results.Colors;
if size(colors, 1) < size(summary.observed_mean, 1)
    error('wrapper_plot_svm_neuron_dropping:InsufficientColors', ...
        'One color is required for each cell type.');
end

[observed_mean, shuffled_mean, observed_sem, shuffled_sem, ...
    observed_datasets, shuffled_datasets, panel1_label] = ...
    apply_representation(summary, p.Results.Representation);
difference_datasets = observed_datasets - shuffled_datasets;
if strcmpi(p.Results.Representation, 'raw')
    difference_mean = summary.difference_mean;
    difference_sem = summary.difference_sem;
else
    difference_mean = observed_mean - shuffled_mean;
    difference_sem = sem_across_first_dimension(difference_datasets, ...
        p.Results.DeterministicCellTypes);
end

scale = 100;
figure_handle = figure('Color', 'w', 'Visible', p.Results.Visible);
set(figure_handle, 'Position', [100, 100, 480, 190]);
layout = tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(layout, 1);
hold(ax1, 'on');
plot_population_panel(ax1, summary.population_sizes, observed_mean, shuffled_mean, ...
    observed_sem, shuffled_sem, observed_datasets, shuffled_datasets, ...
    summary.valid_population_mask, colors, summary.celltype_labels, ...
    logical(p.Results.ShowIndividualDatasets), scale);
ylabel(ax1, panel1_label);
xlabel(ax1, 'Number of neurons');
% title(ax1, 'Event-window accuracy');
if strcmpi(p.Results.Representation, 'raw')
    h = yline(ax1, 50, '--k', 'LineWidth', 0.7);
    h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end
if ~isempty(p.Results.YLimits)
    ylim(ax1, p.Results.YLimits * scale);
end

% for ax = [ax1]
%     box(ax, 'off');
%     set(ax, 'FontSize', 7, 'XTick', summary.population_sizes);
%     xtickangle(ax, 45);
% end


for ax = [ax1]
    box(ax, 'off');
    set(ax, 'FontSize', 7, 'XTick', [1 3 5 7 10 15 20 25 50 100]);
    xtickangle(ax, 45);
end

% for ax = ax1
%     box(ax, 'off');
%     set(ax, ...
%         'FontSize', 7, ...
%         'XScale', 'log', ...
%         'XTick', [1 2 3 5 7 10 15 25 50 100], ...
%         'XTickLabel', {'1','2','3','5','7','10','15','25','50','100'});
% 
%     xlim(ax, [0.9 110]);
%     xtickangle(ax, 0);
% end

summary.plotted_observed_mean = observed_mean;
summary.plotted_shuffled_mean = shuffled_mean;
summary.plotted_difference_mean = difference_mean;
summary.representation = lower(p.Results.Representation);

if ~isempty(savepath)
    if ~exist(savepath, 'dir')
        mkdir(savepath);
    end
    filename = sprintf('%s_%s.pdf', save_string, lower(p.Results.Representation));
    exportgraphics(figure_handle, fullfile(savepath, filename), 'ContentType', 'vector');
    save(fullfile(savepath, sprintf('%s_%s_summary.mat', ...
        save_string, lower(p.Results.Representation))), 'summary');
end
end

function plot_population_panel(ax, population_sizes, observed_mean, shuffled_mean, ...
    observed_sem, shuffled_sem, observed_datasets, shuffled_datasets, ...
    valid_mask, colors, labels, show_datasets, scale)
legend_handles = gobjects(0);
legend_labels = {};
for celltype_id = 1:size(observed_mean, 1)
    valid = valid_mask(celltype_id, :) & isfinite(observed_mean(celltype_id, :));
    if ~any(valid)
        continue
    end
    x = population_sizes(valid);
    color = colors(celltype_id, :);
    light_color = color + 0.65 * (1 - color);

    if show_datasets
        overlay_color = color + 0.78 * (1 - color);
        for dataset_id = 1:size(observed_datasets, 1)
            y = reshape(observed_datasets(dataset_id, celltype_id, valid), 1, []);
            plot(ax, x, y * scale, '-', 'Color', overlay_color, 'LineWidth', 0.5);
        end
    end

    h = plot_mean_and_sem(ax, x, observed_mean(celltype_id, valid) * scale, ...
        observed_sem(celltype_id, valid) * scale, color, '-o', ...
        'Color', color, 'MarkerFaceColor', color, 'MarkerSize', 3, ...
        'LineWidth', 1.2);
    plot_mean_and_sem(ax, x, shuffled_mean(celltype_id, valid) * scale, ...
        shuffled_sem(celltype_id, valid) * scale, light_color, '--o', ...
        'Color', light_color, 'MarkerFaceColor', 'w', 'MarkerSize', 2.5, ...
        'LineWidth', 0.8);
    if show_datasets
        shuffled_overlay_color = light_color + 0.55 * (1 - light_color);
        for dataset_id = 1:size(shuffled_datasets, 1)
            y = reshape(shuffled_datasets(dataset_id, celltype_id, valid), 1, []);
            plot(ax, x, y * scale, '--', 'Color', shuffled_overlay_color, 'LineWidth', 0.4);
        end
    end
    legend_handles(end + 1) = h; %#ok<AGROW>
    legend_labels{end + 1} = labels{celltype_id}; %#ok<AGROW>
end
if ~isempty(legend_handles)
    legend(ax, legend_handles, legend_labels, 'Location', 'eastoutside', 'Box', 'off');
end
end

function plot_difference_panel(ax, population_sizes, difference_mean, ...
    difference_sem, difference_datasets, valid_mask, colors, show_datasets, scale)
for celltype_id = 1:size(difference_mean, 1)
    valid = valid_mask(celltype_id, :) & isfinite(difference_mean(celltype_id, :));
    if ~any(valid)
        continue
    end
    x = population_sizes(valid);
    color = colors(celltype_id, :);
    if show_datasets
        overlay_color = color + 0.78 * (1 - color);
        for dataset_id = 1:size(difference_datasets, 1)
            y = reshape(difference_datasets(dataset_id, celltype_id, valid), 1, []);
            plot(ax, x, y * scale, '-', 'Color', overlay_color, 'LineWidth', 0.5);
        end
    end
    plot_mean_and_sem(ax, x, difference_mean(celltype_id, valid) * scale, ...
        difference_sem(celltype_id, valid) * scale, color, '-o', ...
        'Color', color, 'MarkerFaceColor', color, 'MarkerSize', 3, ...
        'LineWidth', 1.2);
end
end

function [observed_mean, shuffled_mean, observed_sem, shuffled_sem, ...
    observed_datasets, shuffled_datasets, label] = apply_representation(summary, representation)
observed_mean = summary.observed_mean;
shuffled_mean = summary.shuffled_mean;
observed_sem = summary.observed_sem;
shuffled_sem = summary.shuffled_sem;
observed_datasets = summary.observed_dataset_values;
shuffled_datasets = summary.shuffled_dataset_values;

if strcmpi(representation, 'raw')
    label = '% Accuracy';
    return
end

for celltype_id = 1:size(observed_mean, 1)
    valid = find(summary.valid_population_mask(celltype_id, :), 1, 'last');
    if isempty(valid)
        continue
    end
    denominator = observed_mean(celltype_id, valid);
    observed_mean(celltype_id, :) = observed_mean(celltype_id, :) / denominator;
    shuffled_mean(celltype_id, :) = shuffled_mean(celltype_id, :) / denominator;
    observed_sem(celltype_id, :) = observed_sem(celltype_id, :) / denominator;
    shuffled_sem(celltype_id, :) = shuffled_sem(celltype_id, :) / denominator;

    for dataset_id = 1:size(observed_datasets, 1)
        dataset_valid = find(isfinite(observed_datasets(dataset_id, celltype_id, :)), ...
            1, 'last');
        if isempty(dataset_valid)
            continue
        end
        dataset_denominator = observed_datasets(dataset_id, celltype_id, dataset_valid);
        observed_datasets(dataset_id, celltype_id, :) = ...
            observed_datasets(dataset_id, celltype_id, :) / dataset_denominator;
        shuffled_datasets(dataset_id, celltype_id, :) = ...
            shuffled_datasets(dataset_id, celltype_id, :) / dataset_denominator;
    end
end
if strcmp(summary.replication_unit, 'datasets')
    observed_sem = sem_across_first_dimension( ...
        observed_datasets, summary.deterministic_celltypes);
    shuffled_sem = sem_across_first_dimension( ...
        shuffled_datasets, summary.deterministic_celltypes);
end
label = 'Accuracy / accuracy at largest population (%)';
end

function handle = plot_mean_and_sem(ax, x, y, sem, color, line_style, varargin)
handle = plot(ax, x, y, line_style, varargin{:});
has_sem = isfinite(sem);
if any(has_sem)
    errorbar(ax, x(has_sem), y(has_sem), sem(has_sem), 'LineStyle', 'none', ...
        'Color', color, 'CapSize', 3, 'HandleVisibility', 'off');
end
end

function sem = sem_across_first_dimension(values, ~)
% Deterministic cell types are not specially suppressed here: when values
% are already dataset means, ranked-pyr SEM across animals is valid.
sem = nan(size(values, 2), size(values, 3));
for celltype_id = 1:size(values, 2)
    for population_id = 1:size(values, 3)
        x = reshape(values(:, celltype_id, population_id), [], 1);
        x = x(isfinite(x));
        if numel(x) > 1
            sem(celltype_id, population_id) = std(x) / sqrt(numel(x));
        end
    end
end
end