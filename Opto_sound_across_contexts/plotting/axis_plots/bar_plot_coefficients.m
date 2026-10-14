function bar_plot_coefficients(lme, lme2, save_dir, colors, labels, xlabels, save_string, varargin)
% bar_plot_coefficients(lme, lme2, save_dir, colors, labels, xlabels, save_string)
%
% Supports any number of model groups.
%
% Original two-model calls remain compatible.
%
% Additional models:
%   ..., 'AdditionalModels', {lme3, lme4}
%
% Each model can be an LME or a cell array of LMEs.
% For a cell array, fixed effects are concatenated, excluding intercepts.
%
% X-labels repeat independently within each model group.
% Example:
%   xlabels = {'Sound','Photostim'};
%   Model 1: Sound, Photostim
%   Model 2: Sound, Photostim
%   Model 3: Sound, Photostim
%
% Colors specify one RGB row per model group.
% Optional y-limits can be supplied as [-0.5 0.5].

%% Parse optional arguments
ylim_values = [];
additional_models = {};

iarg = 1;

while iarg <= numel(varargin)

    arg = varargin{iarg};

    if isnumeric(arg) && numel(arg) == 2

        ylim_values = arg;

    elseif (ischar(arg) || isstring(arg)) && ...
            strcmpi(arg, 'AdditionalModels')

        if iarg == numel(varargin)
            error('Provide models after ''AdditionalModels''.');
        end

        additional_models = varargin{iarg + 1};

        if ~iscell(additional_models)
            additional_models = {additional_models};
        end

        additional_models = additional_models(:)';

        iarg = iarg + 1;

    else
        error('Unrecognized optional argument.');
    end

    iarg = iarg + 1;
end

%% Normalize xlabels
if ischar(xlabels)
    xlabels = {xlabels};
elseif isstring(xlabels)
    xlabels = cellstr(xlabels(:))';
else
    xlabels = xlabels(:)';
end

if isempty(xlabels)
    error('xlabels must contain at least one label.');
end

%% Collect model groups
models = {lme};

if nargin >= 2 && ~isempty(lme2)
    models{end + 1} = lme2;
end

models = [models, additional_models];

n_models = numel(models);

if size(colors, 1) < n_models || size(colors, 2) ~= 3
    error('Provide an N-by-3 RGB color matrix for all %d models.', ...
        n_models);
end

%% Extract fixed effects from each model group
all_fe = cell(1, n_models);

for k = 1:n_models

    all_fe{k} = extract_fixed_effects(models{k});

    if isempty(all_fe{k})
        error('Model group %d has no fixed effects.', k);
    end

end

n_coeffs = cellfun(@height, all_fe);
total_bars = sum(n_coeffs);

%% Determine bar positions and labels
x_positions = cell(1, n_models);
xticklabels_tracker = {};

next_x = 1;

for k = 1:n_models

    % Sequential positions for this model group
    x_positions{k} = next_x:(next_x + n_coeffs(k) - 1);

    % Repeat xlabels within EACH model group.
    % If there are more coefficients than labels, cycle through labels.
    group_labels = repmat(xlabels, 1, ...
        ceil(n_coeffs(k) / numel(xlabels)));

    group_labels = group_labels(1:n_coeffs(k));

    xticklabels_tracker = [xticklabels_tracker, group_labels];

    next_x = next_x + n_coeffs(k);

end

%% Plot
figure(107);
clf;
hold on;

xticks_tracker = [];

if n_models == 1
    bar_width = 0.5;
    offset = 0;
else
    bar_width = 0.35;
    offset = 0.2;
end

bar_stats = struct();

for k = 1:n_models

    fe = all_fe{k};

    estimates = fe.Estimate;
    ses = fe.SE;
    pvals = fe.pValue;

    x = x_positions{k};

    % Preserve original offsets for the first two model groups.
    % Additional groups are centered at their own positions.
    if k == 1 && n_models > 1
        x_plot = x - offset;
    elseif k == 2 && n_models > 1
        x_plot = x + offset;
    else
        x_plot = x;
    end

    % Use a model-level DisplayName, not xlabels{k}.
    % xlabels may contain fewer labels than there are models.
    b = bar(x_plot, estimates, bar_width, ...
        'FaceColor', 'w', ...
        'EdgeColor', colors(k, :), ...
        'LineWidth', 1, ...
        'DisplayName', sprintf('Model %d', k));

    xtips = b.XEndPoints;

    % Error bars
    for j = 1:numel(estimates)

        errorbar(xtips(j), estimates(j), ses(j), ...
            'Color', colors(k, :), ...
            'LineWidth', 1, ...
            'CapSize', 2);

    end

    % Significance stars
    for j = 1:numel(estimates)

        if ~isempty(pvals) && isfinite(pvals(j))

            if estimates(j) >= 0
                star_y = estimates(j) + ses(j) + 0.02;
            else
                star_y = estimates(j) - ses(j) - 0.06;
            end

            utils.plot_pval_star( ...
                xtips(j), star_y, pvals(j), [0, 0], 0, colors(k, :));

        end

    end

    % Save statistics using unique model/label/coefficient names
    group_labels = repmat(xlabels, 1, ...
        ceil(n_coeffs(k) / numel(xlabels)));
    group_labels = group_labels(1:n_coeffs(k));

    for j = 1:n_coeffs(k)

        stats_name = matlab.lang.makeValidName( ...
            sprintf('Model%d_%s_%d', k, group_labels{j}, j));

        bar_stats.(stats_name).p_val = pvals(j);
        bar_stats.(stats_name).est = estimates(j);
        bar_stats.(stats_name).se = ses(j);

    end

    xticks_tracker = [xticks_tracker, x_plot];

end

%% Formatting
ylabel(labels);
yline(0, '--k');

if ~isempty(ylim_values)
    ylim(ylim_values);
end

set(gca, ...
    'XTick', xticks_tracker, ...
    'XTickLabel', xticklabels_tracker, ...
    'XTickLabelRotation', 45);

positions = utils.calculateFigurePositions(1, 5, .5, []);

set(gca, 'FontSize', 7, ...
    'Units', 'inches', ...
    'Position', positions(1, :));

if total_bars == 1

    old_center = positions(1, 1) + positions(1, 3) / 2;

    positions(1, 3) = positions(1, 3) * 0.5;
    positions(1, 1) = old_center - positions(1, 3) / 2;

    set(gca, 'FontSize', 7, ...
        'Units', 'inches', ...
        'Position', positions(1, :));

else
    utils.set_current_fig;
end

%% Save
if ~isempty(save_dir)

    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    saveas(107, fullfile(save_dir, ...
        ['bar_coefficients_', save_string, '_vs_engagement_axis.fig']));

    exportgraphics(figure(107), fullfile(save_dir, ...
        ['bar_coefficients_', save_string, '_vs_engagement_axis.pdf']), ...
        'ContentType', 'vector');

    save(fullfile(save_dir, ...
        ['stats_bar_coefficients_', save_string, '_vs_engagement_axis.mat']), ...
        'bar_stats');

end

end


function fe = extract_fixed_effects(model)
% Extract fixed effects excluding intercepts.
% Cell arrays of LME objects are concatenated.

if iscell(model)

    all_coeffs = cell(size(model));

    for j = 1:numel(model)

        t = model{j}.Coefficients(2:end, :);
        t.Properties.RowNames = {};

        all_coeffs{j} = t;

    end

    fe = vertcat(all_coeffs{:});

else

    fe = model.Coefficients(2:end, :);

end

end



% function bar_plot_coefficients(lme, lme2, save_dir, colors, labels,xlabels, save_string,varargin)
% % bar_plot_coefficients(lme, lme2, save_dir, colors, labels, save_string)
% % Handles one or multiple LMEs (in cell array form).
% % If multiple LMEs are passed (e.g., {lme1, lme2}), they will be concatenated.
% 
% % If lme is a cell array, handle accordingly
% if iscell(lme)
%     if numel(lme) > 1
%         % Concatenate all fixed effects from provided models
%         all_coeffs = cell(size(lme));
%         for k = 1:numel(lme)
%             t = lme{k}.Coefficients(2:end,:);        % ignore intercept
%             % put the rownames into a column so they are preserved
%             t.Feature = t.Properties.RowNames;
%             % optionally label which model each row came from
%             t.Model = repmat({sprintf('model%d',k)}, height(t), 1);
%             % clear row names so vertcat won't complain
%             t.Properties.RowNames = {};
%             all_coeffs{k} = t;
%         end
%         fe1 = vertcat(all_coeffs{:});
%     else
%         % Single model inside a cell array
%         fe1 = lme{1}.Coefficients(2:end,:);
%     end
% else
%     % lme is a single model (not in a cell)
%     fe1 = lme.Coefficients(2:end,:);
% end
% 
% % Do the same for lme2
% if nargin >= 2 && ~isempty(lme2)
%     if iscell(lme2)
%         if numel(lme2) > 1
%             all_coeffs = cell(size(lme2));
%         for k = 1:numel(lme2)
%             t = lme2{k}.Coefficients(2:end,:);        % ignore intercept
%             % put the rownames into a column so they are preserved
%             t.Feature = t.Properties.RowNames;
%             % optionally label which model each row came from
%             t.Model = repmat({sprintf('model%d',k)}, height(t), 1);
%             % clear row names so vertcat won't complain
%             t.Properties.RowNames = {};
%             all_coeffs{k} = t;
%         end
%         fe2 = vertcat(all_coeffs{:});
%         else
%             fe2 = lme2{1}.Coefficients(2:end,:);
%         end
%     else
%         fe2 = lme2.Coefficients(2:end,:);
%     end
% else
%     fe2 = [];
% end
% 
% % % Extract fixed effects from both models
% % fe1 = lme.Coefficients(2,:); %ignore the first one which is the intercept
% % fe2 = lme2.Coefficients(2,:); %ignore the first one which is the intercept
% 
% % Ensure they have the same fixed effect names
% if ~isempty(labels)
%     ylabels = labels;
% end
% % Extract estimates and SEs
% fe_est1 = fe1.Estimate;
% fe_se1  = fe1.SE;
% fe_est2 = fe2.Estimate;
% fe_se2  = fe2.SE;
% 
% % Bar width and group offset
% n_bars = length(fe_est1);%+length(fe_est2);
% x = 1:n_bars;
% if size(colors,1) > 1
%     bar_width = 0.35;
%     offset = 0.2;
% else
%     bar_width = 0.5;
%     offset = 0;
% end
% 
% 
% xticks_tracker = [];
% % Plot
% figure(107); clf; hold on;
% 
%     % Bars for model 1
%     b1 = bar(x - offset, fe_est1, bar_width, 'FaceColor', 'w','EdgeColor', colors(1,:),'LineWidth',1, 'DisplayName', 'Model 1');
%     
%     % Error bars
%     % errorbar(x - offset, fe_est1, fe_se1, 'k.', 'CapSize', 2);
%     xtips = b1.XEndPoints;
%     ytips = b1.YEndPoints;
%     for i = 1:length(xtips)
%         errorbar(xtips(i), ytips(i), fe_se1(i), 'color', colors(1,:), 'LineWidth', 1, 'CapSize', 2);
%     end
% 
%     %add pvalue stars
%     % Extract p-values
%     pvals1 = fe1.pValue;
%     bar_stats.(xlabels{1}).p_val = pvals1;
%     bar_stats.(xlabels{1}).est = fe_est1;
%     bar_stats.(xlabels{1}).se = fe_se1;
%     % Add significance stars
%     for i = 1:length(x)
%         % Model 1
%     %     star1 = getStar(pvals1(i));
%         if ~isempty(pvals1(i))
%             if ytips(i) > 0
%                 utils.plot_pval_star(xtips(i),ytips(i) + fe_se1(i) + 0.02,pvals1(i),[0,0],0,colors(1,:));
%             else
%                 utils.plot_pval_star(xtips(i),ytips(i) - fe_se1(i) - 0.06,pvals1(i),[0,0],0,colors(1,:));
%             end
%         end
%     
%     end
%     xticks_tracker = [xticks_tracker,x - offset];
% 
% 
% 
% if ~isempty(fe2 )
% nbars2 = length(fe_est2);
% %do model 2
% x = [1:nbars2]+n_bars;
%     % Bars for model 2
%     b2 = bar(x + offset, fe_est2, bar_width, 'FaceColor', 'w','EdgeColor',colors(2,:),'LineWidth',1, 'DisplayName', 'Model 2');
%     %     errorbar(x + offset, fe_est2, fe_se2, 'k.', 'CapSize', 2);
%     xtips2 = b2.XEndPoints;
%     ytips2 = b2.YEndPoints;
%     for i = 1:length(xtips2)
%         errorbar(xtips2(i), ytips2(i), fe_se2(i), 'color', colors(2,:), 'LineWidth', 1, 'CapSize', 2);
%     end
%     
%     
%     %add pvalue stars
%     % Extract p-values
%     pvals2 = fe2.pValue;
%     bar_stats.(xlabels{2}).p_val = pvals2;
%     bar_stats.(xlabels{2}).est2 = fe_est2;
%     bar_stats.(xlabels{2}).se2 = fe_se2;
%     % Add significance stars
%     for i = 1:length(x)
%         % Model 2 (if used)
%     
%         if ~isempty(pvals2)
%             if ytips2(i) > 0
%                 utils.plot_pval_star(xtips2(i),ytips2(i) + fe_se2(i) + 0.02,pvals2(i),[0,0],0,colors(2,:));
%             else
%                 utils.plot_pval_star(xtips2(i),ytips2(i) - fe_se2(i) - 0.06,pvals2(i),[0,0],0,colors(2,:));
%             end
%     
%         end
%         
%     end
%     xticks_tracker = [xticks_tracker,x + offset];
% end
% % Formatting
% ylabel(ylabels)
% yline(0, '--k')
% if nargin > 7
%     ylim(varargin{1,1})
% end
% set(gca, 'XTick', xticks_tracker, 'XTickLabel', repmat(xlabels,1,length(x)), 'XTickLabelRotation', 45)
% 
% % legend([b1 b2], {'Model 1', 'Model 2'}, 'Location', 'Best')
% % Layout
% positions = utils.calculateFigurePositions(1, 5, .5, []);
% set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
% if n_bars == 1 %if only two bars make it half width
%     % Keep center constant
%     old_center = positions(1,1) + positions(1,3)/2;
%     positions(1,3) = positions(1,3) * 0.5;
%     positions(1,1) = old_center - positions(1,3)/2;
%     set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
% else
%     utils.set_current_fig;
% end
% 
% % Save
% if ~isempty(save_dir)
%     mkdir(save_dir)
%     cd(save_dir)
%     saveas(107, strcat('bar_coefficients_',save_string,'_vs_engagement_axis.fig'));
%     exportgraphics(figure(107), strcat('bar_coefficients_',save_string,'_vs_engagement_axis.pdf'), 'ContentType', 'vector');
%     save(strcat('stats_bar_coefficients_',save_string,'_vs_engagement_axis'),'bar_stats');
% end

%
% % Plot
% figure(107); clf; hold on;
% for plts = 1:n_bars
% % Bars for model 1
% b1 = bar(x - offset, fe_est1, bar_width, 'FaceColor', 'w','EdgeColor', colors(plts,:),'LineWidth',1, 'DisplayName', 'Model 1');
% 
% % Error bars
% % errorbar(x - offset, fe_est1, fe_se1, 'k.', 'CapSize', 2);
% xtips = b1.XEndPoints;
% ytips = b1.YEndPoints;
% for i = 1:length(xtips)
%     errorbar(xtips(i), ytips(i), fe_se1(i), 'color', colors(plts,:), 'LineWidth', 1, 'CapSize', 2);
% end
% 
% % Bars for model 2
% b2 = bar(x + offset, fe_est2, bar_width, 'FaceColor', 'w','EdgeColor',colors(plts,:),'LineWidth',1, 'DisplayName', 'Model 2');
% %     errorbar(x + offset, fe_est2, fe_se2, 'k.', 'CapSize', 2);
% xtips2 = b2.XEndPoints;
% ytips2 = b2.YEndPoints;
% for i = 1:length(xtips2)
%     errorbar(xtips2(i), ytips2(i), fe_se2(i), 'color', colors(plts,:), 'LineWidth', 1, 'CapSize', 2);
% end
% 
% 
% %add pvalue stars
% % Extract p-values
% pvals1 = fe1.pValue;
% pvals2 = fe2.pValue;
% % Add significance stars
% for i = 1:length(x)
%     % Model 1
% %     star1 = getStar(pvals1(i));
%     if ~isempty(pvals1(i))
%         if ytips(i) > 0
%             utils.plot_pval_star(xtips(i),ytips(i) + fe_se1(i) + 0.02,pvals1(i),[0,0],0,colors(plts,:));
%         else
%             utils.plot_pval_star(xtips(i),ytips(i) - fe_se1(i) - 0.06,pvals1(i),[0,0],0,colors(plts,:));
%         end
%     end
% 
%     % Model 2 (if used)
% 
%     if ~isempty(pvals2)
%         if ytips2(i) > 0
%             utils.plot_pval_star(xtips2(i),ytips2(i) + fe_se2(i) + 0.02,pvals2(i),[0,0],0,colors(plts,:));
%         else
%             utils.plot_pval_star(xtips2(i),ytips2(i) - fe_se2(i) - 0.06,pvals2(i),[0,0],0,colors(plts,:));
%         end
% 
%     end
% set(gca, 'XTick', [x - offset*2,x + offset], 'XTickLabel', repmat(xlabels,1,length(x)), 'XTickLabelRotation', 45)
% 
% end
