function plot_cdf_weights_pooled(bin_id, betas, all_celltypes, plot_info, ...
    data_type, svm_info, celtype, savepath, varargin)

possible_celltypes = fieldnames(all_celltypes{1,1});

if nargin > 8
    string_to_use = varargin{1};
else
    string_to_use = '';
end

%% Pooled CDF

figure(575); clf;
hold on;

x1 = -1:0.01:1;

for ce = celtype

    % Pool neuron-level beta values across ALL datasets
    pooled_data = [];

    for m = 1:size(betas,2)

        if isempty(betas{1,m,bin_id})
            continue;
        end

        % Neurons x iterations
        all_data = [betas{:,m,bin_id}];

        if isempty(all_data)
            continue;
        end

        % Cells belonging to this cell type
        cell_inds = all_celltypes{1,m}.(possible_celltypes{ce});

        if isempty(cell_inds)
            continue;
        end

        % Mean beta across iterations for each neuron
        mean_data = mean(all_data(cell_inds,:), 2);

        % Pool neurons across datasets
        pooled_data = [pooled_data; mean_data];

    end

    if isempty(pooled_data)
        continue;
    end

    % CDF of pooled neuron distribution
    [cdf, ~] = make_cdf(pooled_data, x1);

    % Plot all cell types on same axes
    plot(x1, cdf, ...
        'Color', plot_info.colors_celltype(ce,:), ...
        'LineWidth', 2);

end

xlabel('Classifier Weight');
ylabel('Cumulative Probability');

xlim([x1(1) x1(end)]);
ylim([0 1]);

% Labels
x_range = xlim;
y_range = ylim;

text_x = x_range(2) - 0.2 * diff(x_range);
text_y = y_range(2) - 0.2 * diff(y_range);

num_labels = length(celtype);
y_offsets = linspace(0, 0.1 * (num_labels - 1), num_labels);

for i = 1:num_labels

    ce = celtype(i);

    text(text_x, ...
        text_y - y_offsets(i) * diff(y_range), ...
        plot_info.labels{ce}, ...
        'Color', plot_info.colors_celltype(ce,:), ...
        'FontSize', 7);

end

set(gca,'fontsize',10);
set(gcf,'position',[100,100,150,150]);

%% Save

if ~isempty(savepath)

    save_dir = [savepath '\SVM_' data_type '_' svm_info.savestr];

    if ~exist(save_dir,'dir')
        mkdir(save_dir);
    end

    exportgraphics(gcf, ...
        fullfile(save_dir, ...
        ['Pooled_SVM_weights_CDF_bin' num2str(bin_id) string_to_use '.pdf']), ...
        'ContentType','vector');

end

end