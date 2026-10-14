function [modl_fit, index_updated,index2_updated,stats] = scatter_index_sigcells_histogram_optional(sig_mod_boot, all_celltypes, index, plot_info, save_path, string1, string2,historno,unity_line, varargin)
index_updated = {};
index2_updated = {};
positions = utils.calculateFigurePositions(1, 5, .5, []);
if nargin > 9
        minmax = varargin{1,1};
    else
        minmax = [-1, 1];
end

% ---- NEW: normalize limits ----
if size(minmax,1) == 1
    xlim_vals = minmax;
    ylim_vals = minmax;
elseif size(minmax,1) == 2
    xlim_vals = minmax(1,:);
    ylim_vals = minmax(2,:);
else
    error('minmax must be [1x2] or [2x2]');
end

    % Create figure
    figure(2324); clf;
    
    % Define main axes
    mainAx = axes('Position', [0.22 0.25 0.60 0.60]);
    hold(mainAx, 'on');
    if unity_line == 1
        plot(mainAx, xlim_vals, ylim_vals, '--', 'Color', [0.5 0.5 0.5]);
    elseif unity_line == -1
        plot(mainAx, xlim_vals, [0 0], '--', 'Color', [0.5 0.5 0.5]);
        plot(mainAx, [0,0], ylim_vals, '--', 'Color', [0.5 0.5 0.5]);
    else
        plot(mainAx, xlim_vals, [0 0], '--', 'Color', [0.5 0.5 0.5]);
        plot(mainAx, xlim_vals, -xlim_vals, '--', 'Color', [0.5 0.5 0.5]);
    end
%     xline(0.1,'--k')
%         xline(-0.1,'--k')
%         yline(0.1,'--k')
%         yline(-0.1,'--k')

    % Axes for histograms
    topAx = axes('Position', [0.15 0.81 0.65 0.15]); % X-axis histogram
    rightAx = axes('Position', [0.81 0.15 0.15 0.65]); % Y-axis histogram
    % Adjust histogram axes accordingly
    topAx.Position = [mainAx.Position(1), ...
                      mainAx.Position(2) + mainAx.Position(4) + 0.01, ...
                      mainAx.Position(3), 0.13];
    
    rightAx.Position = [mainAx.Position(1) + mainAx.Position(3) + 0.01, ...
                        mainAx.Position(2), ...
                        0.13, mainAx.Position(4)];

    hold(topAx, 'on'); hold(rightAx, 'on');
    axis(topAx, 'tight'); axis(rightAx, 'tight');
    topAx.XTick = []; rightAx.YTick = [];
    set(topAx,   'XLim', xlim_vals, 'YTick', []);
    set(rightAx,'YLim', ylim_vals, 'XTick', []);

    modl_fit = cell(1, 3);
    celltype_fields = fields(all_celltypes{1});
    n_celltypes = length(celltype_fields);

    all_x_across_celltypes = [];
    all_y_across_celltypes = [];
    for cell_type = 1:n_celltypes
        all_x = []; all_y = [];
        for dataset_index = 1:length(all_celltypes)
            if ~isempty(sig_mod_boot)
                selected_cells = sig_mod_boot{dataset_index}(ismember(sig_mod_boot{dataset_index}, ...
                    all_celltypes{dataset_index}.(celltype_fields{cell_type})));
            else
                if size(all_celltypes,1) > 1 %assumes it is separated by context!
                    selected_cells = all_celltypes{ctx,dataset_index}.(celltype_fields{cell_type});
                else
                    selected_cells = all_celltypes{dataset_index}.(celltype_fields{cell_type});
                end
            end
            x = index{dataset_index,1}(selected_cells);
            y = index{dataset_index,2}(selected_cells);

            

            % Scatter plot
            scatter(mainAx, x, y, 'MarkerEdgeColor', plot_info.colors_celltypes(cell_type, :), ...
                'MarkerEdgeAlpha', .7, 'LineWidth', 1, 'SizeData',10);
%             scatter(mainAx, x, y, 'MarkerEdgeColor', plot_info.colors_celltypes(cell_type, :), ...
%                 'MarkerEdgeAlpha', .3, 'LineWidth', 1, 'SizeData',5);

            % Collect data for fitting and histograms
            all_x = [all_x; x(:)];
            all_y = [all_y; y(:)];

        end


        if ~isempty(all_x)
            modl_fit{cell_type} = fitlm(all_x, all_y);
            % Replace spaces and invalid characters with underscores
            field_name = regexprep(string1, ' ', '');
            field_name2 = regexprep(string2, ' ', '');
            field_name = regexprep(field_name, '[^a-zA-Z0-9]', '_');
            field_name2 = regexprep(field_name2, '[^a-zA-Z0-9]', '_');
            field_name = regexprep(field_name, '_+', '_');
            field_name2 = regexprep(field_name2, '_+', '_');
            field_name = regexprep(field_name,  '^_|_$', '');
            field_name2 = regexprep(field_name2,  '^_|_$', '');
            field_name = regexprep(field_name,  'Δ', '');
            field_name2 = regexprep(field_name2,  'Δ', '');
            
            
            % Ensure it doesn’t start with a number
            if ~isletter(field_name(1))
                field_name = ['f_' field_name];
            end
            if ~isletter(field_name2(1))
                field_name2 = ['f_' field_name2];
            end
            all_field_names = strcat(field_name,field_name2);
            %get stats!
            stats.(celltype_fields{cell_type}).(field_name) = get_basic_stats(all_x);
            stats.(celltype_fields{cell_type}).(field_name2) = get_basic_stats(all_y);

%             text(mainAx, minmax(1)+0.05, minmax(2) +0.1 - 0.2 * cell_type, ...
%                 sprintf('R² = %.3f', modl_fit{cell_type}.Rsquared.Ordinary), ...
%                 'Color', plot_info.colors_celltypes(cell_type, :), 'FontSize', 6);
            [r,p_val] = corr(all_x,all_y);
            text(mainAx, xlim_vals(1)+0.05, ylim_vals(2)+0.1 - 0.2*cell_type,...
                sprintf('R = %.3f', r), ...
                'Color', plot_info.colors_celltypes(cell_type, :), 'FontSize', 6);
            stats.(celltype_fields{cell_type}).(all_field_names).r = r;
            stats.(celltype_fields{cell_type}).(all_field_names).p_val = p_val;

            % Plot histograms
%             histogram(topAx, all_x,'Normalization','probability','BinWidth', 0.05, 'BinLimits', minmax, 'FaceColor', plot_info.colors_celltypes(cell_type, :), ...
%                 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'Orientation', 'vertical');
% 
%             histogram(rightAx, all_y,'Normalization','probability','BinWidth', 0.05, 'BinLimits', minmax, 'FaceColor', plot_info.colors_celltypes(cell_type, :), ...
%                 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'Orientation', 'horizontal');

            if historno == 1
                histogram(topAx, all_x, 'Normalization','probability','BinWidth', 0.1,'BinWidth', 0.05,'BinLimits', minmax, 'EdgeColor', plot_info.colors_celltypes(cell_type, :), ...
                    'Orientation', 'vertical','DisplayStyle','stairs', 'LineWidth',1.2);
                histogram(rightAx, all_y,'Normalization','probability','BinWidth', 0.1, 'BinWidth', 0.05,'BinLimits', minmax, 'EdgeColor', plot_info.colors_celltypes(cell_type, :), ...
                    'Orientation', 'horizontal','DisplayStyle','stairs', 'LineWidth',1.2);
            end
        end
        all_x_across_celltypes{cell_type} = all_x'; %[all_x_across_celltypes;all_x];
        all_y_across_celltypes{cell_type} = all_y'; %[all_y_across_celltypes;all_y];
    end
    index_updated = all_x_across_celltypes;
    index2_updated = all_y_across_celltypes;

    % Finalize plot
    xlabel(mainAx, string1, 'Interpreter', 'tex');
    ylabel(mainAx, string2, 'Interpreter', 'tex');
    xlim(mainAx, xlim_vals);
    ylim(mainAx, ylim_vals);

    box(mainAx, 'off');
    % Remove x and y axis for topAx (X-axis histogram)
    topAx.XTick = [];
    topAx.YTick = [];
    topAx.Visible = 'off';
    % Remove x and y axis for rightAx (Y-axis histogram)
    rightAx.XTick = [];
    rightAx.YTick = [];
    rightAx.Visible = 'off';

    box(rightAx, 'off');
    set(mainAx, 'FontSize', 7)

    % Use painters renderer (vector-safe)
    set(gcf, 'Renderer', 'painters');
    
%     set(gcf, 'Position', [100, 100, 200, 200]);  % [left bottom width height]
    set(mainAx, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
    set(groot, 'defaultAxesFontName', 'Arial');
    utils.set_current_fig;


    % Save figure
    sig_cel_string = ~isempty(sig_mod_boot);
    if ~isempty(save_path)
        if ~exist(save_path, 'dir')
            mkdir(save_path);
        end
        string1 = strrep(string1, '\Delta', 'Δ');
        string2 = strrep(string2, '\Delta', 'Δ');

        string2 = strrep(string2, '\', '');
        string1 = strrep(string1, '\', '');
        saveas(gcf, fullfile(save_path, ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.png']));
        saveas(gcf, fullfile(save_path, ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.svg']));
        exportgraphics(gcf, fullfile(save_path, ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.pdf']), 'ContentType', 'vector');
        %save_stats!
        save(fullfile(save_path,['stats_scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.mat']),'stats');


% %         set(gcf, 'Renderer', 'opengl');
% %         print(gcf, '-dpdf', '-opengl', fullfile(save_path, ...
% %             ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.pdf']));
%         exportgraphics(gcf, fullfile(save_path, ...
%             ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.pdf']), ...
%             'ContentType', 'vector', ...
%             'FontMode', 'fixed', ... % prevents font substitution
%             'BackgroundColor', 'none', ...
%             'BoundingBox', 'tight');

%         set(gcf, 'Units', 'inches');
%         pos = get(gcf, 'Position');
%         set(gcf, 'PaperPositionMode', 'Auto', 'PaperUnits', 'inches', ...
%             'PaperSize', [pos(3), pos(4)]);
%         print(gcf, fullfile(save_path, ...
%             ['scatter_index_sigcells_histogram' num2str(sig_cel_string) '_' string1 '_' string2 '.pdf']), ...
%             '-dpdf', '-painters');



    end
end
