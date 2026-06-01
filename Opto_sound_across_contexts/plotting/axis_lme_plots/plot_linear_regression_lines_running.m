function lm_stats = plot_linear_regression_lines_running(lme,tbl,context_all,ylabel_string,save_dir,varargin)

% extract table variables
var_names = tbl.Properties.VariableNames;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND ENGAGEMENT COEFFICIENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

eng_idx = strcmp(lme.CoefficientNames,'EngagementProj');

slope = lme.Coefficients.Estimate(eng_idx);
pval_slope = lme.Coefficients.pValue(eng_idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SEPARATE INTO CONTEXTS FOR PLOTTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tbl_active = tbl(context_all == 0,var_names);
tbl_passive = tbl(context_all == 1,var_names);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICTIONS FOR PLOTTING
% HOLD RUNNING CONSTANT AT ITS MEAN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xvals = linspace( ...
    min(tbl{:,var_names{2}}), ...
    max(tbl{:,var_names{2}}), ...
    100)';

if any(strcmp(tbl.Properties.VariableNames,'Running'))

    running_mean = mean(tbl.Running,'omitnan');

    pred_tbl = table( ...
        xvals,...
        repmat(running_mean,length(xvals),1),...
        'VariableNames',{'EngagementProj','Running'});

else

    pred_tbl = table( ...
        xvals,...
        'VariableNames',{'EngagementProj'});

end

[yhat_active,yci_active] = predict(lme,pred_tbl);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE OUT WHICH CONTEXTS WERE PLOTTED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if all(context_all == 1)
    contexts_to_plot = 2;
elseif all(context_all == 0)
    contexts_to_plot = 1;
else
    contexts_to_plot = [1,2];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAKE SCATTER PLOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

positions = utils.calculateFigurePositions(1, 5, .5, []);

figure(103); clf; hold on;

if isequal(contexts_to_plot,[1,2]) || isequal(contexts_to_plot,2)

    scatter(tbl{context_all==0,var_names{2}}, ...
            tbl{context_all==0,var_names{1}}, ...
            5,...
            'MarkerEdgeColor',[0.2 0.2 0.2], ...
            'MarkerEdgeAlpha',.6)

    scatter(tbl{context_all==1,var_names{2}}, ...
            tbl{context_all==1,var_names{1}}, ...
            5,...
            'MarkerEdgeColor',[0.8 0.8 0.8], ...
            'MarkerEdgeAlpha',.6)

else

    scatter(tbl{context_all==0,var_names{2}}, ...
            tbl{context_all==0,var_names{1}}, ...
            5,...
            'MarkerEdgeColor',[0.4 0.4 0.4], ...
            'MarkerEdgeAlpha',.6)

end

plot(xvals, yhat_active, 'k', 'LineWidth', 2.2)

ylabel({ylabel_string;'(z-scored)'});

if nargin > 5
    xlabel({strcat(varargin{1,1},' Projection');'(z-scored)'})
    ylabel_string_updated = [ylabel_string varargin{1,1}];
else
    xlabel({'Engagement Projection';'(z-scored)'})
    ylabel_string_updated = ylabel_string;
end

set(gca, ...
    'FontSize', 7, ...
    'Units', 'inches', ...
    'Position', positions(1,:));

utils.set_current_fig;

if nargin > 7 && ~isempty(varargin{1,3}) && ~isempty(varargin{1,4})
    xlim(varargin{1,3})
    ylim(varargin{1,4})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STATS TEXT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

n_total = size(tbl,1);

beta = slope;
p_val = pval_slope;

default_position = 'topleft';

if nargin > 9
    default_position = varargin{1,5};
end

utils.place_text_labels({['n = ', num2str(n_total)]}, ...
    'k',0,5,default_position,0.05)

utils.place_text_labels({['\beta = ', num2str(round(beta,2))]}, ...
    'k',0.1,5,default_position,0.05)

utils.place_text_labels({['p = ', num2str(p_val,'%.1e')]}, ...
    'k',0.2,5,default_position,0.05)

if nargin > 6 && ~isempty(varargin{1,2})
    utils.place_text_labels( ...
        {['r = ', num2str(round(varargin{1,2}(1),2)), ...
        ' p=', num2str(round(varargin{1,2}(2)))]}, ...
        'k',0.1,5,'bottomleft',0.05)
end

utils.set_current_fig;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE STATS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_stats.n = n_total;
lm_stats.beta = beta;
lm_stats.p_val = p_val;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECOND PLOT (LINE + CI ONLY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1003); clf; hold on;

x_active_sorted = xvals;
yhat_active_sorted = yhat_active;
yci_active_sorted = yci_active;

if ismember(1,contexts_to_plot)

    fill([x_active_sorted; flipud(x_active_sorted)], ...
         [yci_active_sorted(:,1); flipud(yci_active_sorted(:,2))], ...
         [0.3 0.3 0.3], ...
         'EdgeColor', 'none', ...
         'FaceAlpha', 0.3);

    plot(x_active_sorted, ...
         yhat_active_sorted, ...
         'k', ...
         'LineWidth', 2);

else

    fill([x_active_sorted; flipud(x_active_sorted)], ...
         [yci_active_sorted(:,1); flipud(yci_active_sorted(:,2))], ...
         [0.8 0.8 0.8], ...
         'EdgeColor', 'none', ...
         'FaceAlpha', 0.4);

    plot(x_active_sorted, ...
         yhat_active_sorted, ...
         'Color', [0.6 0.6 0.6], ...
         'LineWidth', 2);

end

ylabel({ylabel_string;'(z-scored)'});

if nargin > 5
    xlabel({strcat(varargin{1,1},' Projection');'(z-scored)'})
else
    xlabel({'Engagement Projection';'(z-scored)'})
end

set(gca, ...
    'FontSize', 7, ...
    'Units', 'inches', ...
    'Position', positions(1,:));

ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(save_dir)

    mkdir(save_dir)
    cd(save_dir)

    saveas(103, ...
        strcat('scatter_linear_regression_contexts', ...
        num2str(contexts_to_plot), ...
        num2str(ylabel_string_updated), ...
        '.fig'));

    exportgraphics(figure(103), ...
        strcat('scatter_linear_regression_contexts', ...
        num2str(contexts_to_plot), ...
        num2str(ylabel_string_updated), ...
        '.pdf'), ...
        'ContentType', 'vector');

    saveas(1003, ...
        strcat('linear_lineonly_regression_contexts', ...
        num2str(contexts_to_plot), ...
        num2str(ylabel_string_updated), ...
        '.fig'));

    exportgraphics(figure(1003), ...
        strcat('linear_lineonly_regression_contexts', ...
        num2str(contexts_to_plot), ...
        num2str(ylabel_string_updated), ...
        '.pdf'), ...
        'ContentType', 'vector');

    save(strcat('stats_lm_contexts', ...
        num2str(contexts_to_plot), ...
        num2str(ylabel_string_updated)), ...
        'lm_stats');

end

end