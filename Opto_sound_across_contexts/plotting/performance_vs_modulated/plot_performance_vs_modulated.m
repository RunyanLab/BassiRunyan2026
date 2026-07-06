function plot_performance_vs_modulated(performance,percent_cells_per_dataset,plot_info,save_dir)
task_performance.task = [performance.correct_all];
plot_regression =1;

positions = utils.calculateFigurePositions(1, 5, .5, []);

figure(1);clf; hold on
task_data = task_performance.task(1:24)*100;
percent_modulated = percent_cells_per_dataset*100;
scatter(task_data,percent_modulated(:,1)', 20,'MarkerFaceColor',plot_info.pooled_colors(1,:), 'LineWidth',1,'MarkerEdgeColor', 'none','MarkerFaceAlpha', 0.5);
scatter(task_data,percent_modulated(:,2)', 20,'MarkerFaceColor',plot_info.pooled_colors(2,:), 'LineWidth',1,'MarkerEdgeColor', 'none','MarkerFaceAlpha', 0.5);


if plot_regression == 1
    %get text positions
    xl = xlim;
    yl = ylim;
    
    x_text = xl(1) + 0.05*range(xl);   % 5% from left edge
    y_text = yl(2) - 0.1*range(yl);   % 5% below top edge

    %fit linear model to sound responsive
    mdl = fitlm(task_data,percent_modulated(:,1));
    xvals = linspace(min(task_data), max(task_data), 100);
    yhat = predict(mdl, xvals');
    plot(xvals, yhat, 'Color',plot_info.pooled_colors(1,:), 'LineWidth', 1.5);
    text(x_text,y_text, ...
    sprintf('R = %.2f', mdl.Rsquared.Ordinary), 'FontSize', 6, 'Color',plot_info.pooled_colors(1,:));
%     text(x_text,y_text, ...
%     sprintf('P = %.3g\nR = %.2f', mdl.Coefficients.pValue(2), mdl.Rsquared.Ordinary), 'FontSize', 6);

    %fit linear model to opto responsive
    mdl = fitlm(task_data,percent_modulated(:,2));
    xvals = linspace(min(task_data), max(task_data), 100);
    yhat = predict(mdl, xvals');
    plot(xvals, yhat, 'Color',plot_info.pooled_colors(2,:), 'LineWidth', 1.5);
    text(x_text,yl(2) - 0.2*range(yl), ...
    sprintf('R = %.2f', mdl.Rsquared.Ordinary), 'FontSize', 6, 'Color',plot_info.pooled_colors(2,:));
%     text(x_text, y_text, ...
%     sprintf('P = %.3g\nR = %.2f', mdl.Coefficients.pValue(2), mdl.Rsquared.Ordinary), 'FontSize', 6);

end
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;


xlabel('% Correct'); 
ylabel('% Modulated');

if ~isempty(save_dir)
    mkdir([save_dir '/performance_plots/'])
    new_savedir = [save_dir '/performance_plots/'];
    saveas(1,fullfile(new_savedir, 'performance_vs_modulated_cells.fig'));
    exportgraphics(figure(1),fullfile(new_savedir,'performance_vs_modulated_cells.pdf'), 'ContentType', 'vector');
end