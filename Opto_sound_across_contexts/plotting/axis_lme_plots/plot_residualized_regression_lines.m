function lm_stats = plot_residualized_regression_lines( ...
    lme_resid, lm_resid, tbl_resid, context_all, ...
    ylabel_string, save_dir, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract table variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

var_names = tbl_resid.Properties.VariableNames;

response_var = var_names{1};
predictor_var = var_names{2};

beta = lme_resid.Coefficients.Estimate(2);
pval_slope = lme_resid.Coefficients.pValue(2);

if ~isempty(lm_resid)
    r2_val = lm_resid.Rsquared.Ordinary;
else
    r2_val = NaN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep only valid rows (IMPORTANT: keep alignment consistent)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x_all = tbl_resid{:, predictor_var};
y_all = tbl_resid{:, response_var};

valid_idx = ~isnan(x_all) & ~isnan(y_all);

tbl_resid = tbl_resid(valid_idx, :);
context_all = context_all(valid_idx);

x_all = tbl_resid{:, predictor_var};
y_all = tbl_resid{:, response_var};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Context logic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if all(context_all == 1)
    contexts_to_plot = 2;
elseif all(context_all == 0)
    contexts_to_plot = 1;
else
    contexts_to_plot = [1,2];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prediction line (fixed-effects)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xvals = linspace(min(x_all), max(x_all), 100);

pred_line = lme_resid.Coefficients.Estimate(1) + ...
            lme_resid.Coefficients.Estimate(2) .* xvals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

positions = utils.calculateFigurePositions(1, 5, .5, []);

figure(103); clf; hold on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCATTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isequal(contexts_to_plot,[1,2]) || isequal(contexts_to_plot,2)

    scatter(tbl_resid{context_all==0, predictor_var}, ...
            tbl_resid{context_all==0, response_var}, ...
            5, ...
            'MarkerEdgeColor',[0.2 0.2 0.2], ...
            'MarkerEdgeAlpha',0.6);

    scatter(tbl_resid{context_all==1, predictor_var}, ...
            tbl_resid{context_all==1, response_var}, ...
            5, ...
            'MarkerEdgeColor',[0.8 0.8 0.8], ...
            'MarkerEdgeAlpha',0.6);

else

    scatter(tbl_resid{context_all==0, predictor_var}, ...
            tbl_resid{context_all==0, response_var}, ...
            5, ...
            'MarkerEdgeColor',[0.4 0.4 0.4], ...
            'MarkerEdgeAlpha',0.6);

end

plot(xvals, pred_line, 'k', 'LineWidth', 2.2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Axis labels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin > 6 && ~isempty(varargin{1})
    xlabel({[varargin{1}, ' Projection']; '(running residual)'});
    xlabel_string = varargin{1};
else
    xlabel({'Engagement Projection';'running residual)'});
    xlabel_string = 'Engagement';
end

ylabel({ylabel_string; '(running residual)'});

set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1,:));
utils.set_current_fig;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Text stats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

n_total = size(tbl_resid,1);

default_position = 'topleft';
if nargin > 10
    default_position = varargin{5};
end

utils.place_text_labels({['n = ', num2str(n_total)]}, ...
    'k',0,5,default_position,0.05);

utils.place_text_labels({['\beta = ', num2str(round(beta,3))]}, ...
    'k',0.1,5,default_position,0.05);

utils.place_text_labels({['R^2 = ', num2str(round(r2_val,3))]}, ...
    'k',0.2,5,default_position,0.05);

utils.place_text_labels({['p = ', num2str(pval_slope,'%.1e')]}, ...
    'k',0.3,5,default_position,0.05);

if nargin > 7 && ~isempty(varargin{2})
    utils.place_text_labels({['r = ', num2str(round(varargin{2}(1),2)), ...
        ' p = ', num2str(varargin{2}(2),'%.1e')]}, ...
        'k',0.1,5,'bottomleft',0.05);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE STATS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lm_stats.n = n_total;
lm_stats.beta = beta;
lm_stats.r2 = r2_val;
lm_stats.p_val = pval_slope;
lm_stats.response_var = response_var;
lm_stats.predictor_var = predictor_var;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECOND PLOT (LINE + CI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1003); clf; hold on;

[x_sorted, idx_sort] = sort(x_all);
tbl_pred = tbl_resid(idx_sort,:);

[yhat_sorted, yci_sorted] = predict(lme_resid, tbl_pred);

fill([x_sorted; flipud(x_sorted)], ...
     [yci_sorted(:,1); flipud(yci_sorted(:,2))], ...
     [0.3 0.3 0.3], ...
     'EdgeColor','none', ...
     'FaceAlpha',0.3);

plot(x_sorted, yhat_sorted, 'k', 'LineWidth', 2);

ylabel([ylabel_string ' (running residual)']);

if nargin > 6 && ~isempty(varargin{1})
    xlabel([varargin{1}, ' Projection ((running residual)']);
else
    xlabel('Engagement Projection ((running residual)');
end

set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1,:));

ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;

utils.set_current_fig;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE FIGURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(save_dir)

    mkdir(save_dir);
    cd(save_dir);

    saveas(103, strcat('scatter_resid_reg_', num2str(contexts_to_plot), ...
        ylabel_string, '.fig'));

    exportgraphics(figure(103), strcat('scatter_resid_reg_', ...
        num2str(contexts_to_plot), ylabel_string, '.pdf'), ...
        'ContentType','vector');

    saveas(1003, strcat('line_resid_reg_', num2str(contexts_to_plot), ...
        ylabel_string, '.fig'));

    exportgraphics(figure(1003), strcat('line_resid_reg_', ...
        num2str(contexts_to_plot), ylabel_string, '.pdf'), ...
        'ContentType','vector');

    save(strcat('stats_resid_lm_', num2str(contexts_to_plot), ...
        ylabel_string), 'lm_stats');
end

end