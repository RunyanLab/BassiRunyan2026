function plot_performance_vs_engagement_axis_updated(percent_correct_concat,engagement_concat,window_bins,save_dir,edge_input,varargin)
%% collect correctness across mice
correct_all_ctrl = []; animal_id_all=[]; engagement_active = [];

for dataset = 1:24
    correct = percent_correct_concat{dataset}';
    engagement = engagement_concat{dataset}';

    % Keep only trials with valid engagement values
    valid_idx = ~isnan(engagement);

    correct = correct(valid_idx);
    engagement = engagement(valid_idx);

    correct_all_ctrl = [correct_all_ctrl; correct];
    engagement_active = [engagement_active; engagement];
    animal_id_all = [animal_id_all; repmat(dataset, sum(valid_idx), 1)];
end

% engagement_active = [engagement_proj_all_sound(active_trials);engagement_proj_all_stim(context_all_stim == 0)];
performance_active =  correct_all_ctrl;
%%
% Parameters
window_size = window_bins(1);
% Defaults
plot_sessions = 0;
label_str = 'Fraction Correct';

% Handle optional inputs
label_str = "Fraction Correct";
save_str = "engagement";
plot_sessions = [];
edges = [];

for i = 1:2:numel(varargin)
    switch lower(varargin{i})
        case 'label'
            label_str = varargin{i+1};
        case 'save'
            save_str = varargin{i+1};
        case 'plotsessions'
            plot_sessions = varargin{i+1};
        case 'edges'
            edges = varargin{i+1};
    end
end
% Unique animals/sessions
animal_ids = unique(animal_id_all);
% Initialize pooled vectors
all_success = [];
all_engagement = [];
session_success = {};
session_engagement = {};
session_success_nooverlap = {};
session_engagement_nonoverlap = {};
for a = 1:length(animal_ids)
    idx = animal_id_all == animal_ids(a);
    perf = performance_active(idx);         % Binary performance (0/1)
    engagement = engagement_active(idx);    % Continuous engagement projection

    % Sort trials by engagement
    [sorted_eng, sort_idx] = sort(engagement);
    sorted_perf = perf(sort_idx);
    n = length(sorted_eng);
    if n < window_size
        continue
    end
    temp_e = [];
    temp_s = [];
    % Sliding window
    for i = 1:(n - window_size + 1)
        win_eng = sorted_eng(i:i + window_size - 1);
        win_perf = sorted_perf(i:i + window_size - 1);
        % Store mean per window
        all_engagement(end+1,1) = mean(win_eng);
        all_success(end+1,1) = mean(win_perf);
        temp_e = [temp_e, mean(win_eng)];
        temp_s = [temp_s, mean(win_perf)];
    end
    session_success{a} = temp_s;
    session_engagement{a} = temp_e;
    % ----- Non-overlapping window -----
    temp_e_nonoverlap = [];
    temp_s_nonoverlap = [];
    nonoverlap_window = 10;
    for i = 1:nonoverlap_window:n-nonoverlap_window+1
        win_eng = sorted_eng(i:i + nonoverlap_window - 1);
        win_perf = sorted_perf(i:i + nonoverlap_window - 1);
        temp_e_nonoverlap = [temp_e_nonoverlap, mean(win_eng)];
        temp_s_nonoverlap = [temp_s_nonoverlap, mean(win_perf)];
    end
    session_success_nooverlap{a} = temp_s_nonoverlap;
    session_engagement_nonoverlap{a} = temp_e_nonoverlap;
end

positions = utils.calculateFigurePositions(1, 5, .5, []);

% ─────────────────────────────────────────────
% Scatter plot of sliding window means
figure(401); clf;
scatter(all_engagement, all_success, 8, 'filled', ...
    'MarkerFaceAlpha', 0.1, 'MarkerEdgeAlpha', 0.05);
xlabel({[save_str 'Projection'];'(z-scored)'});
ylabel(label_str);
% title(sprintf('Sliding window (n = %d trials per window)', window_size));
% % Optional: Linear regression overlay
% mdl = fitlm(all_engagement, all_success);
% hold on;
% xfit = linspace(min(all_engagement), max(all_engagement), 100);
% yfit = predict(mdl, xfit');
% plot(xfit, yfit, 'k-', 'LineWidth', 1.2);
% % text(mean(xfit), max(yfit), sprintf('R = %.2f, p = %.3g', mdl.Correlation, mdl.Coefficients.pValue(2)), ...
% %     'FontSize', 7);
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

% Bin data based on engagement quantiles
edges = linspace(edge_input(1),edge_input(2), window_bins(2)+1);%prctile(engagement_active, linspace(0, 100, 6));%linspace(0,2, 6); %prctile(engagement_active, linspace(0, 100, 6));  % 5 bins
bin_centers = movmean(edges, 2, 'Endpoints','discard');
n_bins = length(bin_centers);

n_per_sess = NaN(length(animal_ids),n_bins);
%separate per session
% Initialize per-animal matrix [animal x bins]
animal_success_by_bin = NaN(length(animal_ids), n_bins);
% Loop through animals/sessions
for a = 1:length(animal_ids)
    e = session_engagement{a};
    s = session_success{a};
    if isempty(e)
        continue
    end
    % Bin this session's engagement values
    [n, ~, bin_idx] = histcounts(e, edges);
    n_per_sess(a,:) = n;
    % For each bin, compute mean success
    for b = 1:n_bins
        bin_trials = s(bin_idx == b);
        if ~isempty(bin_trials)
            animal_success_by_bin(a, b) = mean(bin_trials);
        end
    end
end
% Compute across-animal mean and SEM
mean_success_per_bin = nanmean(animal_success_by_bin, 1);
sem_success_per_bin = nanstd(animal_success_by_bin, [], 1) ./ sqrt(sum(~isnan(animal_success_by_bin),1));
% Plot
figure(404);clf;
hold on;
% Individual animal traces (light gray lines)
if plot_sessions == 1
    for a = 1:size(animal_success_by_bin,1)
        plot(bin_centers, animal_success_by_bin(a,:), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);
    end
end
% Group mean with error bars (black line)
errorbar(bin_centers, mean_success_per_bin, sem_success_per_bin,  '-ok', 'MarkerFaceColor', 'k', 'LineWidth', 1,'MarkerSize',3,'CapSize',2);
xlabel({[save_str 'Projection'];'(z-scored)'});
ylabel(label_str);
ylims = ylim;
ylim([ylims(1)-(ylims(1)*.03),ylims(2)+(ylims(2)*.03)])
xli = xlim;
xlim([xli(1)- xli(2)*.3,xli(2) + xli(2)*.3]); %adjust axis
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
box off

figure(804);clf; colormap gray;
imagesc(n_per_sess); 
c = colorbar; 
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :)); 
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
% utils.set_current_fig; 
c.Label.String = {'Number of Avg. Windows'}; %'Prestimulus "engagement"'; 
c.Label.Rotation = 270; % Rotate the ylabel by 270 degrees'Rotation',270; 
c.Label.Position = [3.958666563034058,21.152173096718997,0]; 
xlabel({'Prestimulus'; '"engagement" Bin'}); 
ylabel('Dataset ID')
% Create a red mask where values < 5
mask = n_per_sess < 5;

% % Overlay mask with transparency
% h = imagesc(mask);
% set(h, 'AlphaData', mask*0.4);   % 0.4 transparency
% colormap(gca, gray);             % keep gray colormap for background
% h.CData = cat(3, mask, zeros(size(mask)), zeros(size(mask))); % red overlay

% % correect (xaxis) vs engagemnt (yaxis)
% Correlation
[r, p] = corr(all_success, all_engagement);
% Plot
figure(405);clf; hold on;
scatter(all_success, all_engagement, 20, ...
    'MarkerFaceColor', [0.3 0.6 0.9], ...
    'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.1);

% Linear regression
mdl = fitlm(all_success, all_engagement);
xvals = linspace(min(all_success), max(all_success), 100);
yhat = predict(mdl, xvals');
plot(xvals, yhat, 'b-', 'LineWidth', 1.5);

% Annotations
text(0.43, max(all_engagement)*0.95, ...
    sprintf('P = %.3g\nR = %.2f', p, r), 'FontSize', 6);

xlabel(label_str);
ylabel({[save_str 'Projection'];'(z-scored)'});
% title('Correlation: engagement vs Performance (sliding window)');
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
box off

%-------non overlaping window----------------
% Initialize per-animal matrix [animal x bins]
animal_success_by_bin = NaN(length(animal_ids), n_bins);
% Loop through animals/sessions
for a = 1:length(animal_ids)
    e = session_engagement_nonoverlap{a};
    s = session_success_nooverlap{a};
    if isempty(e)
        continue
    end
    % Bin this session's engagement values
    [n, ~, bin_idx] = histcounts(e, edges);
    n_per_sess(a,:) = n;
    % For each bin, compute mean success
    for b = 1:n_bins
        bin_trials = s(bin_idx == b);
        if ~isempty(bin_trials)
            animal_success_by_bin(a, b) = mean(bin_trials);
        end
    end
end
% Compute across-animal mean and SEM
mean_success_per_bin = nanmean(animal_success_by_bin, 1);
sem_success_per_bin = nanstd(animal_success_by_bin, [], 1) ./ sqrt(sum(~isnan(animal_success_by_bin),1));
% Plot
figure(406);clf;
hold on;
% Individual animal traces (light gray lines)
if plot_sessions == 1
    for a = 1:size(animal_success_by_bin,1)
        plot(bin_centers, animal_success_by_bin(a,:), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);
    end
end
% Group mean with error bars (black line)
errorbar(bin_centers, mean_success_per_bin, sem_success_per_bin,  '-ok', 'MarkerFaceColor', 'k', 'LineWidth', 1,'MarkerSize',3,'CapSize',2);
xlabel({[save_str 'Projection'];'(z-scored)'});
ylabel(label_str);
ylims = ylim;
ylim([ylims(1)-(ylims(1)*.03),ylims(2)+(ylims(2)*.03)])
xli = xlim;
xlim([xli(1)- xli(2)*.3,xli(2) + xli(2)*.3]); %adjust axis
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
box off

all_engagement = [session_engagement_nonoverlap{1,:}];
all_success = [session_success_nooverlap{1,:}];
[r, p] = corr(all_success', all_engagement');
% Plot
figure(407);clf; hold on;
scatter(all_success, all_engagement, 20, ...
    'MarkerFaceColor', [0.6 0.6 0.6], ... % [0.3 0.6 0.9]
    'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.1);

% Linear regression
mdl = fitlm(all_success, all_engagement);
xvals = linspace(min(all_success), max(all_success), 100);
yhat = predict(mdl, xvals');
plot(xvals, yhat, 'k-', 'LineWidth', 1.5);

% --- Mean dots per bin ---
bin_edges = min(all_success):0.1:1; % adjust bin size as needed
bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2;

for b = 1:length(bin_edges)-1
    idx = all_success > bin_edges(b) & all_success <= bin_edges(b+1);
    % Bin this session's engagement values
%     [n, ~, bin_idx] = histcounts(e, bin_edges);
    if any(idx)
        mean_success = mean(all_success(idx));
        mean_engagement = mean(all_engagement(idx));
        plot(mean_success, mean_engagement, 'o', ...
            'MarkerFaceColor', [0.3 0.3 0.3], ... %[0 0.2 0.6]
            'MarkerEdgeColor', 'none', ...
            'MarkerSize', 3);
    end
end

% Annotations
text(0.43, max(all_engagement)*0.95, ...
    sprintf('P = %.3g\nR = %.2f', p, r), 'FontSize', 6);

xlabel(label_str);
ylabel({[save_str 'Projection'];'(z-scored)'});
% title('Correlation: engagement vs Performance (sliding window)');
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
if min(all_success)-0.05 < 1.05
    xlim([min(all_success)-0.05,1.05])
end
box off


%%
all_success = [session_success_nooverlap{1,:}];
[r2, p2] = corr(all_engagement',all_success');
% Plot
figure(408);clf; hold on;
scatter(all_engagement, all_success,  20, ...
    'MarkerFaceColor', [0.6 0.6 0.6], ... % [0.3 0.6 0.9]
    'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.1);

% Linear regression
mdl2 = fitlm(all_engagement, all_success);
xvals = linspace(min(all_engagement), max(all_engagement), 100);
yhat = predict(mdl2, xvals');
plot(xvals, yhat, 'k-', 'LineWidth', 1.5);

bin_edges = linspace(edge_input(1),edge_input(2), window_bins(2)+1);%prctile(engagement_active, linspace(0, 100, 6));%linspace(0,2, 6); %prctile(engagement_active, linspace(0, 100, 6));  % 5 bins
bin_centers = movmean(edges, 2, 'Endpoints','discard');


% for b = 1:length(bin_edges)-1
%     idx = all_success > bin_edges(b) & all_success <= bin_edges(b+1);
%     % Bin this session's engagement values
% %     [n, ~, bin_idx] = histcounts(e, bin_edges);
%     if any(idx)
%         mean_success = mean(all_success(idx));
%         mean_engagement = mean(all_engagement(idx));
%         plot(mean_engagement, mean_success,  'o', ...
%             'MarkerFaceColor', [0.3 0.3 0.3], ... %[0 0.2 0.6]
%             'MarkerEdgeColor', 'none', ...
%             'MarkerSize', 3);
%     end
% end

% Annotations
text(-1.8, 0.2, ...
    sprintf('P = %.3g\nR = %.2f', p2, r2), 'FontSize', 6);

ylabel(label_str);
xlabel({[save_str 'Projection'];'(z-scored)'});
% title('Correlation: engagement vs Performance (sliding window)');
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

box off
%% plot based on engagement bins (no overlap!)
% Unique animals/sessions
animal_ids = unique(animal_id_all);

% Initialize pooled vectors
all_success = [];
all_engagement = [];
session_success = {};
session_engagement = {};

% Define engagement bins (you can change number of bins)
n_bins = 6;

if ~isempty(edges)
    edges = edges;
else
    edges = linspace(-1, 2, n_bins + 1); % assumes engagement is normalized [0,1]
end
bin_centers = movmean(edges, 2, 'Endpoints', 'discard');
animal_success_by_bin_nooverlap = NaN(length(animal_ids), n_bins);
animal_eng_by_bin_nooverlap = NaN(length(animal_ids), n_bins);

for a = 1:length(animal_ids)
    idx = animal_id_all == animal_ids(a);
    perf = performance_active(idx);         % Binary performance (0/1)
    engagement = engagement_active(idx);    % Continuous engagement projection

    if isempty(engagement)
        continue
    end

    % Bin by engagement
    [~, ~, bin_idx] = histcounts(engagement, edges);
    temp_e = [];
    temp_s = [];

    for b = 1:n_bins
        bin_trials = bin_idx == b;
        if sum(bin_trials) < 5
            continue
        end
        mean_eng = mean(engagement(bin_trials));
        mean_perf = mean(perf(bin_trials));

        % Store per session
        temp_e = [temp_e, mean_eng];
        temp_s = [temp_s, mean_perf];

        % Store pooled
        all_engagement(end+1,1) = mean_eng;
        all_success(end+1,1) = mean_perf;
        animal_success_by_bin_nooverlap(a, b) = mean_perf;
        animal_eng_by_bin_nooverlap(a,b) = mean_eng;
    end

    session_engagement{a} = temp_e;
    session_success{a} = temp_s;
end

all_success = [session_success{1,:}];
[r2, p2] = corr(all_engagement,all_success');
%get stats1
for b = 1:n_bins
    bin_name = strcat('bin',num2str(b));
    performance_vs_engagement_stats.performance.(bin_name) = get_basic_stats(animal_success_by_bin_nooverlap(:,b));
    performance_vs_engagement_stats.engagement_proj.(bin_name) = get_basic_stats(animal_eng_by_bin_nooverlap(:,b));
end
performance_vs_engagement_stats.r = r2;
performance_vs_engagement_stats.p = p2;
performance_vs_engagement_stats.edges = edges;

% Plot
figure(408);clf; hold on;
scatter(all_engagement, all_success,  20, ...
    'MarkerFaceColor', [0.5 0.5 0.5], ... % [0.3 0.6 0.9]
    'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.1);

% Linear regression
mdl2 = fitlm(all_engagement, all_success);
xvals = linspace(min(all_engagement), max(all_engagement), 100);
yhat = predict(mdl2, xvals');
plot(xvals, yhat, 'k-', 'LineWidth', 1.5);

bin_edges = linspace(edge_input(1),edge_input(2), window_bins(2)+1);%prctile(engagement_active, linspace(0, 100, 6));%linspace(0,2, 6); %prctile(engagement_active, linspace(0, 100, 6));  % 5 bins
bin_centers = movmean(edges, 2, 'Endpoints','discard');

for b = 1:length(bin_centers)
    plot(bin_centers(b), mean(animal_success_by_bin_nooverlap(:, b),'omitnan') ,  'o', ...
        'MarkerFaceColor', [0.3 0.3 0.3], ... %[0 0.2 0.6]
        'MarkerEdgeColor', 'none', ...
        'MarkerSize', 3);

end

% Annotations
text(.5, 0.5, ...
    sprintf('P = %.3g\nR = %.2f', p2, r2), 'FontSize', 6);


ylabel(label_str);
xlabel({[save_str 'Projection'];'(z-scored)'});
% title('Correlation: engagement vs Performance (sliding window)');
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

box off


%% overlaping engagemnt bins
% Unique animals/sessions
animal_ids = unique(animal_id_all);

% Initialize pooled vectors
all_success = [];
all_engagement = [];
session_success = {};
session_engagement = {};

% Define overlapping engagement bins
bins =  -1:0.5:2; %-1:0.2:2;     % centers min(engagement_active):0.5:max(engagement_active); %
window = 0.5;       % bin width (overlapping)

animal_success_by_bin = NaN(length(animal_ids), length(bins)-1);

for a = 1:length(animal_ids)
    idx = animal_id_all == animal_ids(a);
    engagement = engagement_active(idx);  % engagement projection
    performance = performance_active(idx);                         % binary performance (0/1)
    
    if isempty(engagement)
        continue
    end

    % Initialize per-session storage
    temp_e = [];
    temp_s = [];

    % Loop over overlapping bins
    for b = 2:length(bins)
%         inds = find(engagement >= (bins(b) - window/2) & engagement < (bins(b) + window/2));
        inds = find(engagement >= (bins(b-1)) & engagement < (bins(b) + window));

        if isempty(inds) || length(inds) < 5%10 %at least 10 trials
            continue
        end

        % Compute bin-wise means
        mean_eng = mean(engagement(inds));
        mean_perf = mean(performance(inds));

        % Store in per-session arrays
        temp_e = [temp_e, mean_eng];
        temp_s = [temp_s, mean_perf];

        % Store in pooled arrays
        all_engagement(end+1, 1) = mean_eng;
        all_success(end+1, 1) = mean_perf;

        % Bin this session's engagement values
        % For each bin, compute mean success
        animal_success_by_bin(a, b-1) = mean_perf;
    end

    % Save per-session
    session_engagement{a} = temp_e;
    session_success{a} = temp_s;

    
end
all_success = [session_success{1,:}];
[r2, p2] = corr(all_engagement,all_success');
% Plot
figure(409);clf; hold on;
scatter(all_engagement, all_success,  20, ...
    'MarkerFaceColor', [0.6 0.6 0.6], ... % [0.3 0.6 0.9]
    'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.1);

% Linear regression
mdl2 = fitlm(all_engagement, all_success);
xvals = linspace(min(all_engagement), max(all_engagement), 100);
yhat = predict(mdl2, xvals');
plot(xvals, yhat, 'k-', 'LineWidth', 1.5);

bin_edges = linspace(edge_input(1),edge_input(2), window_bins(2)+1);%prctile(engagement_active, linspace(0, 100, 6));%linspace(0,2, 6); %prctile(engagement_active, linspace(0, 100, 6));  % 5 bins
bin_centers = movmean(edges, 2, 'Endpoints','discard');


% % Annotations
% text(.5, 0.45, ...
%     sprintf('P = %.3g\nR = %.2f', p2, r2), 'FontSize', 6);

ylabel(label_str);
xlabel({[save_str 'Projection'];'(z-scored)'});
% title('Correlation: engagement vs Performance (sliding window)');
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

box off

%-------error plots for 

% Compute across-animal mean and SEM
mean_success_per_bin = nanmean(animal_success_by_bin, 1);
sem_success_per_bin = nanstd(animal_success_by_bin, [], 1) ./ sqrt(sum(~isnan(animal_success_by_bin),1));
bin_centers = movmean(bins, 2, 'Endpoints','discard');
% Plot
figure(106);clf;
hold on;
% Individual animal traces (light gray lines)
if plot_sessions == 1
    for a = 1:size(animal_success_by_bin,1)
        plot(bin_centers, animal_success_by_bin(a,:), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);
    end
end
% Group mean with error bars (black line)
errorbar(bin_centers, mean_success_per_bin, sem_success_per_bin,  '-ok', 'MarkerFaceColor', 'k', 'LineWidth', 1,'MarkerSize',3,'CapSize',2);
xlabel({[save_str 'Projection'];'(z-scored)'});
ylabel(label_str);
ylims = ylim;
ylim([ylims(1)-(ylims(1)*.03),ylims(2)+(ylims(2)*.03)])
xli = xlim;
xlim([xli(1)- xli(2)*.3,xli(2) + xli(2)*.3]); %adjust axis
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
box off


if ~isempty(save_dir)
    mkdir([save_dir '/performance_plots/'])
    new_savedir = [save_dir '/performance_plots/'];
    saveas(404,fullfile(new_savedir,strcat('errorbar_performance_vs_' , save_str, '_axis_windownbin',num2str(window_bins),'edges',num2str(edges(1)),num2str(edges(end)),'.fig')));
    exportgraphics(figure(404),fullfile(new_savedir,strcat('errorbar_performance_vs_' , save_str, '_axis_windownbin',num2str(window_bins),'edges',num2str(edges(1)),num2str(edges(end)),'.pdf')), 'ContentType', 'vector');
    exportgraphics(figure(405),fullfile(new_savedir,strcat('scatter_performance_vs_' , save_str, '_axis_windownbin',num2str(window_bins),'edges',num2str(edges(1)),num2str(edges(end)),'.pdf')), 'ContentType', 'vector');
    %408 is currently used in the paper
    exportgraphics(figure(407),fullfile(new_savedir,strcat('scatter_nonoverlap_performance_vs_' , save_str, '_axis_windownbin',num2str(window_bins),'edges',num2str(edges(1)),num2str(edges(end)),'.pdf')), 'ContentType', 'vector');
    
    exportgraphics(figure(408),fullfile(new_savedir,strcat('scatter_nonoverlap_' , save_str, '_vs_performance_axis_windownbin',num2str(window),'edges',num2str(performance_vs_engagement_stats.edges(1)),num2str(performance_vs_engagement_stats.edges(end)),'.pdf')), 'ContentType', 'vector');
    
    exportgraphics(figure(409),fullfile(new_savedir,strcat('scatter_binned_' , save_str, '_vs_performance_axis_windownbin',num2str(window),'edges',num2str(bins(1)),num2str(bins(end)),'.pdf')), 'ContentType', 'vector');
    exportgraphics(figure(106),fullfile(new_savedir,strcat('errorbar_performance_vs_' , save_str, '_axis_windownbin',num2str(window),'edges',num2str(bins(1)),num2str(bins(end)),'.pdf')), 'ContentType', 'vector');

    exportgraphics(figure(804),fullfile(new_savedir,strcat('heatmap_ntrials_performance_vs_' , save_str, '_axis_windownbin',num2str(window_bins),'edges',num2str(edges(1)),num2str(edges(end)),'.pdf')), 'ContentType', 'vector');
    save(fullfile(new_savedir,['performance_vs_'  save_str '_stats.mat']),'performance_vs_engagement_stats');

end