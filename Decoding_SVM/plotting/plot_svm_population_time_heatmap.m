function [heatmap_data, figure_handle] = plot_svm_population_time_heatmap( ...
    accuracy, shuffled_accuracy, population_sizes, celltype_id, ...
    event_onsets, savepath, save_string, varargin)
%PLOT_SVM_POPULATION_TIME_HEATMAP Time-by-population decoding heatmap.
%
% Rows are categorical tested populations (no interpolation); y tick labels
% contain the true, nonuniform neuron counts.

if nargin < 6
    savepath = '';
end
if nargin < 7 || isempty(save_string)
    save_string = 'svm_population_time_heatmap';
end

p = inputParser;
addParameter(p, 'Mode', 'observed', ...
    @(x) any(strcmpi(x, {'observed', 'observed-minus-shuffled'})));
addParameter(p, 'Visible', 'on', @(x) any(strcmpi(x, {'on', 'off'})));
addParameter(p, 'ColorLimits', [], @(x) isempty(x) || numel(x) == 2);
parse(p, varargin{:});

aggregate = aggregate_svm_accuracy_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, 1);
if celltype_id > aggregate.n_celltypes
    error('plot_svm_population_time_heatmap:InvalidCellType', ...
        'celltype_id %d exceeds the %d available cell types.', ...
        celltype_id, aggregate.n_celltypes);
end

observed = reshape(aggregate.observed_dataset_traces(:, celltype_id, :, :), ...
    aggregate.n_datasets, aggregate.n_populations, aggregate.n_time_bins);
shuffled = reshape(aggregate.shuffled_dataset_traces(:, celltype_id, :, :), ...
    aggregate.n_datasets, aggregate.n_populations, aggregate.n_time_bins);
observed = reshape(mean(observed, 1, 'omitnan'), ...
    aggregate.n_populations, aggregate.n_time_bins);
shuffled = reshape(mean(shuffled, 1, 'omitnan'), ...
    aggregate.n_populations, aggregate.n_time_bins);

valid = any(isfinite(observed), 2);
if strcmpi(p.Results.Mode, 'observed')
    heatmap_data = observed(valid, :) * 100;
    color_label = '% Accuracy';
else
    heatmap_data = (observed(valid, :) - shuffled(valid, :)) * 100;
    color_label = 'Observed - shuffled (percentage points)';
end
valid_population_sizes = aggregate.population_sizes(valid);

figure_handle = figure('Color', 'w', 'Visible', p.Results.Visible);
set(figure_handle, 'Position', [100, 100, 275, 175]);
ax = axes(figure_handle);
imagesc(ax, 1:aggregate.n_time_bins, 1:numel(valid_population_sizes), heatmap_data);
set(ax, 'YDir', 'normal', 'YTick', 1:numel(valid_population_sizes), ...
    'YTickLabel', valid_population_sizes, 'FontSize', 7, 'Box', 'off');
ylabel(ax, 'Number of neurons');
colorbar_handle = colorbar(ax);
colorbar_handle.Label.String = color_label;
colormap(ax, parula);
if ~isempty(p.Results.ColorLimits)
    caxis(ax, p.Results.ColorLimits);
end

for event_id = 1:numel(event_onsets)
    xline(ax, event_onsets(event_id), '--w', 'LineWidth', 0.7);
end
event_labels = {'S1', 'S2', 'S3', 'T', 'R'};
event_labels = event_labels(1:min(numel(event_labels), numel(event_onsets)));
set(ax, 'XTick', event_onsets(1:numel(event_labels)), ...
    'XTickLabel', event_labels);
xtickangle(ax, 45);
xlabel(ax, 'Event-aligned time');
title(ax, sprintf('Cell type %d: %s', celltype_id, p.Results.Mode));

if ~isempty(savepath)
    if ~exist(savepath, 'dir')
        mkdir(savepath);
    end
    exportgraphics(figure_handle, fullfile(savepath, sprintf('%s_celltype%d_%s.pdf', ...
        save_string, celltype_id, lower(p.Results.Mode))), 'ContentType', 'vector');
end
end
