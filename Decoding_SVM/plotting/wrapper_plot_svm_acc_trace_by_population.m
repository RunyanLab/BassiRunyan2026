function [trace_summary, figure_handle] = wrapper_plot_svm_acc_trace_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, selected_population_sizes, ...
    celltype_id, mdl_param, event_onsets, savepath, save_string, varargin)
%WRAPPER_PLOT_SVM_ACC_TRACE_BY_POPULATION Time courses for selected sizes.

if nargin < 8
    savepath = '';
end
if nargin < 9 || isempty(save_string)
    save_string = 'svm_trace_by_population';
end

p = inputParser;
addParameter(p, 'ShowShuffled', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'YLimits', [], @(x) isempty(x) || numel(x) == 2);
addParameter(p, 'Visible', 'on', @(x) any(strcmpi(x, {'on', 'off'})));
parse(p, varargin{:});

aggregate = aggregate_svm_accuracy_by_population( ...
    accuracy, shuffled_accuracy, population_sizes, 1);
if celltype_id > aggregate.n_celltypes
    error('wrapper_plot_svm_acc_trace_by_population:InvalidCellType', ...
        'celltype_id %d exceeds the %d available cell types.', ...
        celltype_id, aggregate.n_celltypes);
end

requested_ids = arrayfun(@(x) find(aggregate.population_sizes == x, 1), ...
    selected_population_sizes, 'UniformOutput', false);
available = ~cellfun(@isempty, requested_ids);
if any(~available)
    warning('wrapper_plot_svm_acc_trace_by_population:UnavailablePopulation', ...
        'Skipping unavailable requested sizes: %s', ...
        mat2str(selected_population_sizes(~available)));
end
requested_ids = cell2mat(requested_ids(available));
selected_population_sizes = selected_population_sizes(available);

valid_ids = false(size(requested_ids));
for id = 1:numel(requested_ids)
    traces = reshape(aggregate.observed_dataset_traces( ...
        :, celltype_id, requested_ids(id), :), aggregate.n_datasets, []);
    valid_ids(id) = any(isfinite(traces(:)));
end
if any(~valid_ids)
    warning('wrapper_plot_svm_acc_trace_by_population:MissingPopulationData', ...
        'Skipping sizes with no data for cell type %d: %s', ...
        celltype_id, mat2str(selected_population_sizes(~valid_ids)));
end
requested_ids = requested_ids(valid_ids);
selected_population_sizes = selected_population_sizes(valid_ids);
if isempty(requested_ids)
    error('wrapper_plot_svm_acc_trace_by_population:NoAvailablePopulations', ...
        'None of the selected population sizes is available for this cell type.');
end

colors = parula(numel(requested_ids));
figure_handle = figure('Color', 'w', 'Visible', p.Results.Visible);
set(figure_handle, 'Position', [100, 100, 260, 155]);
ax = axes(figure_handle);
hold(ax, 'on');
legend_handles = gobjects(1, numel(requested_ids));

trace_summary.population_sizes = selected_population_sizes;
trace_summary.observed_dataset_traces = cell(1, numel(requested_ids));
trace_summary.shuffled_dataset_traces = cell(1, numel(requested_ids));

for id = 1:numel(requested_ids)
    population_id = requested_ids(id);
    observed = reshape(aggregate.observed_dataset_traces( ...
        :, celltype_id, population_id, :), aggregate.n_datasets, []);
    shuffled = reshape(aggregate.shuffled_dataset_traces( ...
        :, celltype_id, population_id, :), aggregate.n_datasets, []);
    trace_summary.observed_dataset_traces{id} = observed;
    trace_summary.shuffled_dataset_traces{id} = shuffled;

    observed_mean = mean(observed, 1, 'omitnan');
    observed_sem = trace_sem(observed);
    if all(isnan(observed_sem))
        legend_handles(id) = plot(ax, observed_mean, '-', ...
            'Color', colors(id, :), 'LineWidth', 1.2);
    else
        h = shadedErrorBar(1:aggregate.n_time_bins, observed_mean, observed_sem, ...
            'lineProps', {'Color', colors(id, :), 'LineWidth', 1.2});
        legend_handles(id) = h.mainLine;
    end

    if p.Results.ShowShuffled
        shuffled_mean = mean(shuffled, 1, 'omitnan');
        plot(ax, shuffled_mean, '--', ...
            'Color', colors(id, :) + 0.55 * (1 - colors(id, :)), ...
            'LineWidth', 0.7);
    end
end

for event_id = 1:numel(event_onsets)
    xline(ax, event_onsets(event_id), '--k', 'LineWidth', 0.7);
end
yline(ax, 0.5, '--k', 'LineWidth', 0.7);
xlim(ax, [1, aggregate.n_time_bins]);
if ~isempty(p.Results.YLimits)
    ylim(ax, p.Results.YLimits);
end

event_labels = {'S1', 'S2', 'S3', 'T', 'R'};
event_labels = event_labels(1:min(numel(event_labels), numel(event_onsets)));
set(ax, 'XTick', event_onsets(1:numel(event_labels)), ...
    'XTickLabel', event_labels, 'FontSize', 7, 'Box', 'off');
xtickangle(ax, 45);
ytick_values = get(ax, 'YTick');
set(ax, 'YTickLabel', ytick_values * 100);
ylabel(ax, '% Accuracy');
legend(ax, legend_handles, compose('%d neurons', selected_population_sizes), ...
    'Location', 'best', 'Box', 'off');

if exist('addScaleBar', 'file') == 2 && isfield(mdl_param, 'bin')
    addScaleBar(ax, 30 / mdl_param.bin, "1 s", [], [], ...
        'LabelAlignment', 'right', 'XOffsetFrac', -0.1, 'LabelOffsetFrac', -0.05);
end

trace_summary.celltype_id = celltype_id;
trace_summary.event_onsets = event_onsets;
trace_summary.n_datasets = aggregate.n_datasets;

if ~isempty(savepath)
    if ~exist(savepath, 'dir')
        mkdir(savepath);
    end
    exportgraphics(figure_handle, fullfile(savepath, ...
        sprintf('%s_celltype%d.pdf', save_string, celltype_id)), ...
        'ContentType', 'vector');
end
end

function sem = trace_sem(values)
sem = nan(1, size(values, 2));
for time_id = 1:size(values, 2)
    x = values(:, time_id);
    x = x(isfinite(x));
    if numel(x) > 1
        sem(time_id) = std(x) / sqrt(numel(x));
    end
end
end
