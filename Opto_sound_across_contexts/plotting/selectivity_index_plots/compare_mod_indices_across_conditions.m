function mod_stats = compare_mod_indices_across_conditions(save_dir, ...
    mod_index_by_dataset1, mod_index_by_dataset2, ...
    mouseID1, mouseID2, plot_info, varargin)
% Compare modulation indices across two dataset groups (unpaired).
%
% If avg_context = 1, each neuron's indices across contexts are averaged
% first, so each neuron contributes one mean value total.

% --- Optional inputs ---
if nargin > 6, ylims = varargin{1}; else, ylims = []; end
if nargin > 7, abs_logic = varargin{2}; else, abs_logic = 1; end
if nargin > 8, avg_context = varargin{3}; else, avg_context = 0; end

figure(700); clf
positions = utils.calculateFigurePositions(1, 5, .5, []);

num_contexts = size(mod_index_by_dataset1, 2);
n_celltypes = size(mod_index_by_dataset1, 3);
unique_mice1 = unique(mouseID1);
unique_mice2 = unique(mouseID2);
x_lines = 0:(num_contexts * n_celltypes + 1);

for celltype = 1:n_celltypes
    x_pos = x_lines((celltype - 1)*num_contexts + 2 : celltype*num_contexts + 1);

    if avg_context
        % ----- Average across contexts per neuron -----
        data1 = collect_avg_context_data(mod_index_by_dataset1, mouseID1, abs_logic, celltype);
        data2 = collect_avg_context_data(mod_index_by_dataset2, mouseID2, abs_logic, celltype);

        % Convert to one vector per mouse
        valid1 = cell2mat(data1(:));
        valid2 = cell2mat(data2(:));

        % Compute stats
        m1 = mean(valid1,'omitnan'); s1 = std(valid1,'omitnan')/sqrt(length(valid1));
        m2 = mean(valid2,'omitnan'); s2 = std(valid2,'omitnan')/sqrt(length(valid2));

        hold on
        errorbar(celltype - 0.15, m1, s1, 'o', ...
            'Color', plot_info.colors_celltypes(celltype,:), ...
            'MarkerFaceColor', plot_info.colors_celltypes(celltype,:), 'MarkerSize', 3)
        errorbar(celltype + 0.15, m2, s2, 'o', ...
            'Color', plot_info.colors_celltypes(celltype,:), 'MarkerFaceColor', plot_info.colors_celltypes(celltype,:), 'MarkerSize', 3)

        [p,~,effectsize] = permutationTest_updatedcb(valid1, valid2, 10000, 'paired', 0);
        mod_stats.stats(celltype).means = [m1, m2];
        mod_stats.stats(celltype).sems = [s1, s2];
        mod_stats.stats(celltype).p_val = p;
        mod_stats.stats(celltype).effectsize = effectsize;

        if p < 0.05 / n_celltypes
            utils.plot_pval_star(celltype, max([m1+s1, m2+s2]) + 0.02, p, [0,0], 0, [0,0,0]);
        end
%         x_lines = 0:(1 * n_celltypes + 1)
        xlim([x_lines(1) x_lines(end)])
        xticks(sort([x_lines(2:end-1)-.25,x_lines(2:end-1)+.25]));
        xticklabels(repmat({'Sound Neurons', 'Photostim Neurons'}, 1, n_celltypes))
    else
        % ----- Keep contexts separate -----
        for context = 1:num_contexts
            data1 = collect_mod_data(mod_index_by_dataset1, mouseID1, abs_logic, celltype, context);
            data2 = collect_mod_data(mod_index_by_dataset2, mouseID2, abs_logic, celltype, context);

            valid1 = cell2mat(data1(:));
            valid2 = cell2mat(data2(:));

            m1 = mean(valid1,'omitnan'); s1 = std(valid1,'omitnan')/sqrt(length(valid1));
            m2 = mean(valid2,'omitnan'); s2 = std(valid2,'omitnan')/sqrt(length(valid2));

            hold on
            errorbar(x_pos(context) - 0.15, m1, s1, 'o', ...
                'Color', plot_info.colors_celltypes(celltype,:), ...
                'MarkerFaceColor', plot_info.colors_celltypes(celltype,:), 'MarkerSize', 3)
            errorbar(x_pos(context) + 0.15, m2, s2, 'o', ...
                'Color', plot_info.colors_celltypes(celltype,:), 'MarkerFaceColor', plot_info.colors_celltypes(celltype,:), 'MarkerSize', 3)

            [p,~,effectsize] = permutationTest_updatedcb(valid1, valid2, 10000, 'paired', 0);

            mod_stats.stats(celltype,context).means = [m1, m2];
            mod_stats.stats(celltype,context).sems = [s1, s2];
            mod_stats.stats(celltype,context).p_val = p;
            mod_stats.stats(celltype,context).effectsize = effectsize;

            if p < 0.05 / (n_celltypes * num_contexts)
                utils.plot_pval_star(mean(x_pos(context) + [-0.15 0.15]), ...
                    max([m1+s1, m2+s2]) + 0.02, p, [0,0], 0, [0,0,0]);
            end
        end

        xlim([x_lines(1) x_lines(end)])
        xticks(x_lines(2:end-1))
        xticklabels(repmat(plot_info.behavioral_contexts, 1, n_celltypes))
    end
end

if avg_context
    x_lines = 0:(1 * n_celltypes + 1)
    xlim([x_lines(1) x_lines(end)])
end
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
utils.set_current_fig;
% Formatting
xlim([x_lines(1) x_lines(end)])
if abs_logic == 1
    ylabel({'|Selectivity Index|'})
else
    ylabel('Selectivity Index')
end
set(gca, 'FontSize', 7, 'FontName', 'Arial', 'Color', 'w')
box off; xtickangle(45)
utils.set_current_fig
if ~isempty(ylims), ylim(ylims); end

% Save
if ~isempty(save_dir)
    mkdir(save_dir)
    filename = strcat('abs',num2str(abs_logic), '_selectivity_index_n',num2str(mouseID1(end)),'_avgcontext',num2str(avg_context));
    saveas(700, fullfile(save_dir, [filename '.fig']));
    exportgraphics(figure(700), fullfile(save_dir, [filename '.pdf']), 'ContentType', 'vector');
    save(fullfile(save_dir, 'unpaired_selectivity_index_stats.mat'), 'mod_stats');
end
end


%% Helper: per-mouse aggregation
function mouse_data = collect_mod_data(mod_index_by_dataset, mouseID, abs_logic, celltype, context)
unique_mice = unique(mouseID);
mouse_data = cell(length(unique_mice), 1);

for m = 1:length(unique_mice)
    datasets = find(mouseID == unique_mice(m));
    combined = [];
    for d = datasets
        curr_data = mod_index_by_dataset{d,context,celltype};
        if abs_logic, curr_data = abs(curr_data); end
        combined = [combined; curr_data(:)];
    end
    mouse_data{m} = nanmean(combined);
end
end

%% Helper: average across contexts per neuron
function mouse_data = collect_avg_context_data(mod_index_by_dataset, mouseID, abs_logic, celltype)
unique_mice = unique(mouseID);
mouse_data = cell(length(unique_mice), 1);

for m = 1:length(unique_mice)
    datasets = find(mouseID == unique_mice(m));
    combined = [];
    for d = datasets
        context_data = [];
        for context = 1:size(mod_index_by_dataset,2)
            curr = mod_index_by_dataset{d,context,celltype};
            if abs_logic, curr = abs(curr); end
            context_data = pad_or_truncate(context_data, curr);
        end
        % Average across contexts per neuron
        neuron_avg = mean(context_data, 2, 'omitnan');
        combined = [combined; neuron_avg(:)];
    end
    mouse_data{m} = nanmean(combined);
end
end

%% Helper: align context arrays by neuron
function out = pad_or_truncate(existing, new)
if isempty(existing)
    out = new(:);
else
    minlen = min(size(existing,1), numel(new));
    existing =  reshape(existing(1:minlen,:), 1, []);
    out = mean([existing, new(1:minlen)],2);
end
end

