function plot_proj_meansplits_traces(chosen_datasets,proj, axis_type, celltype,stim_frame,colorss,legend_string,save_dir,varargin)
positions = utils.calculateFigurePositions(1, 5, .5, []);

figure(801);clf;
hold on;

% -------------------------------------------------------------------------
% Optional inputs
% -------------------------------------------------------------------------

p = inputParser;

addParameter(p, 'xlabel', 'Time (s)', @ischar);
addParameter(p, 'ylabel', 'Mean Projection', @ischar);
addParameter(p, 'xlim', [31 91]);
addParameter(p, 'xticks', [31 61 91]);
addParameter(p, 'xticklabels', {-1 0 1});
addParameter(p, 'contexts', 2);

parse(p, varargin{:});

xlabel_text = p.Results.xlabel;
ylabel_text = p.Results.ylabel;
xlimss = p.Results.xlim;
xtickss = p.Results.xticks;
xticklabelss = p.Results.xticklabels;

% Initialize
num_timepoints = 122;
% num_datasets = 24;
num_datasets = length(chosen_datasets);
% contexts = 2;
n_splits = size(proj,1);

% Preallocate
all_data = cell(contexts, 1);

for ctx = 1:contexts
    ctx_data = zeros(num_datasets, num_timepoints);
    for dataset = chosen_datasets
        temp =[];
        for splits = 1:n_splits
            data = proj{splits,dataset, celltype, ctx}.(axis_type); %data = proj{dataset,celltype,ctx}.stim;%proj{dataset,celltype,ctx}.stim;%proj_ctrl{dataset, celltype, ctx}.sound; %proj{dataset,celltype,ctx}.stim;%proj{dataset,celltype,ctx}.stim%proj_ctrl{dataset, celltype, ctx}.sound;
            baseline = 0; %mean(data(:,1:59), 'all');
            temp = [temp;mean(data) - baseline]; %mean per split
        end
        ctx_data(dataset, :) = mean(temp,1); %mean across splits
    end
    all_data{ctx} = ctx_data;
end

% Plot with mean and SEM
for ctx = 1:contexts
    data = all_data{ctx};
    m = mean(data, 1);
    s = std(data, [], 1) / sqrt(size(data,1)); % SEM

    % Plot shaded error bar or mean with error bars
    fill([1:num_timepoints, fliplr(1:num_timepoints)], ...
         [m + s, fliplr(m - s)], ...
         colorss(ctx,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    plot(1:num_timepoints, m, 'Color', colorss(ctx,:), 'LineWidth', 2);

    yli = ylim;
    for f = 1:size(stim_frame,1)
        if contains(axis_type,'stim')
            color_onset = [1 0.8 0.3];
        else
            color_onset = [.5 .5 .5];
        end

        rectangle('Position', [stim_frame(f,1), yli(1), stim_frame(f,2)-stim_frame(f,1), ...
            yli(2)-yli(1)], 'FaceColor', color_onset, 'EdgeColor', 'none');
    end
end

% -------------------------------------------------------------------------
% Axes formatting
% -------------------------------------------------------------------------

xlim(xlimss);
xticks(xtickss);
xticklabels(xticklabelss);

xlabel(xlabel_text);
ylabel(ylabel_text);

% -------------------------------------------------------------------------
% Legend text
% -------------------------------------------------------------------------

x_range = xlim;
y_range = ylim;

% legend({'Context 1', 'Context 2'});
% title('Mean ± SEM of Sound Projection by Context');
% Get current axis limits
x_range = xlim;
y_range = ylim;
y_offset_base = .1;
% Calculate base text position
text_x = x_range(2) -.09 * diff(x_range);
text_y = y_range(1) + .2 * diff(y_range);

% Auto-calculate evenly spaced y-offsets
num_labels = 2;
y_offsets = linspace(0, 0.1 * (num_labels - 1), num_labels); % Adjusted scaling
% Place text labels
for i = 1:num_labels
    text(text_x, text_y - y_offsets(i) * diff(y_range), legend_string{i}, ...
         'Color',colorss(i,:), 'FontSize', 7);
end

set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
utils.set_current_fig;

% Save results
if ~isempty(save_dir)
    mkdir(save_dir)
    cd(save_dir)
    saveas(801,strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.svg'));
    saveas(801,strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.fig'));
    exportgraphics(figure(801),strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.pdf'), 'ContentType', 'vector');
end