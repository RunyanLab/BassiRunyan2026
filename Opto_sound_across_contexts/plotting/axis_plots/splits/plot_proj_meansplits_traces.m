function plot_proj_meansplits_traces(chosen_datasets,proj, axis_type, celltype,stim_frame,colorss,legend_string,save_dir, varargin)
positions = utils.calculateFigurePositions(1, 5, .5, []);

xlab = 'Time (s)';   % default

idx = find(strcmpi(varargin, 'xlabel'));
contexts = 2;        % default

for v = 1:length(varargin)-1
    key = varargin{v};

    if isstring(key) || ischar(key)
        switch lower(key)
            case 'xlabel'
                xlab = varargin{v+1};

            case 'contexts'
                contexts = varargin{v+1};
        end
    end
end

figure(801);clf;
hold on;

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
            temp = [temp;mean(data,'omitnan') - baseline]; %mean per split
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

    
end
xlimss = [31 91];
xlim(xlimss );
xticks([31 60 91]);
xticklabels([-1 0 1]);

xlabel(xlab);
ylabel('Mean Projection');
% legend({'Context 1', 'Context 2'});
% title('Mean ± SEM of Sound Projection by Context');
% Get current axis limits
if strcmpi(axis_type,'context')
    utils.place_text_labels(fliplr(legend_string), colorss([2 1], :),0.3, 6,'bottomright', 0.2, 0.1); %,'bottomright', [], 0.2
else
    utils.place_text_labels(fliplr(legend_string), colorss([2 1], :),0.15, 6,'bottomright', 0.2, 0.1); %,'bottomright', [], 0.2
end
% % x_range = xlim;
% % y_range = ylim;
% % y_offset_base = .1;
% % % Calculate base text position
% % text_x = x_range(2) -.09 * diff(x_range);
% % text_y = y_range(1) + .2 * diff(y_range);
% % 
% % % Auto-calculate evenly spaced y-offsets
% % num_labels = 2;
% % y_offsets = linspace(0, 0.1 * (num_labels - 1), num_labels); % Adjusted scaling
% % % Place text labels
% % for i = 1:num_labels
% %     text(text_x, text_y - y_offsets(i) * diff(y_range), legend_string{i}, ...
% %          'Color',colorss(i,:), 'FontSize', 6);
% % end

set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
utils.set_current_fig;

%add onset rectangle after figure limits are set (can change with
%readjustments)
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

% Save results
if ~isempty(save_dir)
    mkdir(save_dir)
    saveas(801,strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.svg'));
    saveas(801,strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.fig'));
    exportgraphics(figure(801),fullfile(save_dir,strcat('meansplit_proj_traces_axis_',num2str(axis_type),'_n_',num2str(length(chosen_datasets)),'.pdf')), 'ContentType', 'vector');
end