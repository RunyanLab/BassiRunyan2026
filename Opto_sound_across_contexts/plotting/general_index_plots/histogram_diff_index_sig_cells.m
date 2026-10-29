function [p_val_mod, stats] = histogram_diff_index_sig_cells( ...
    chosen_cells, all_celltypes, index, plot_info, save_path, ...
    string, horizontalmode, varargin)

    % Generate histograms of index differences for each cell type.
    % Perform permutation tests to determine whether differences differ
    % significantly from zero.
    %
    % Name-value options:
    %   'absValue' : true  -> abs(index1) - abs(index2)
    %                false -> index1 - index2
    %   'binWidth' : Histogram bin width (default = 0.05)
    %   'xLimits'  : X-axis limits (default = [-1 1])
    %
    % Example:
    % histogram_diff_index_sig_cells(..., 'absValue', false, ...
    %     'binWidth', 0.02, 'xLimits', [-0.5 0.5])

    % Defaults
    absValue = true;
    binWidth = 0.05;
    xLimits = [-1 1];

    % Maintain compatibility with the original optional positional xLimits.
    if ~isempty(varargin) && isnumeric(varargin{1})
        xLimits = varargin{1};
        varargin(1) = [];
    end

    % Parse name-value options
    p = inputParser;
    addParameter(p, 'absValue', absValue, ...
        @(x) islogical(x) && isscalar(x));
    addParameter(p, 'binWidth', binWidth, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'xLimits', xLimits, ...
        @(x) isnumeric(x) && numel(x) == 2 && x(1) < x(2));

    parse(p, varargin{:});

    absValue = p.Results.absValue;
    binWidth = p.Results.binWidth;
    xLimits = p.Results.xLimits;

    figure(2325);
    clf;

    p_val_mod = [];
    stats = struct();

    celltype_fields = fields(all_celltypes{1});
    fieldss = fields(all_celltypes{1});

    nCellTypes = length(fieldss);
    nDatasets = length(all_celltypes);

    % Determine subplot positions
    if horizontalmode == 1
        positions = utils.calculateFigurePositions(1, 5, 0.5, []);
    else
        positions = utils.calculateFigurePositions(5, 1, 0.5, []);
    end

    for cell_type = 1:nCellTypes

        difference = [];

        % Loop through datasets
        for dataset_index = 1:nDatasets

            % Select cells belonging to this cell type
            if ~isempty(chosen_cells)
                selected = chosen_cells{1, dataset_index};

                selected = selected(ismember( ...
                    selected, ...
                    all_celltypes{1, dataset_index}.(fieldss{cell_type})));
            else
                selected = all_celltypes{1, dataset_index}.(fieldss{cell_type});
            end

            % Extract index values for the two conditions
            index1 = index{dataset_index, 1}(selected);
            index2 = index{dataset_index, 2}(selected);

            % Calculate differences
            if absValue
                diff_this_dataset = abs(index1) - abs(index2);
            else
                diff_this_dataset = index1 - index2;
            end

            difference = [difference, diff_this_dataset(:)'];
        end

        % Remove NaN values before plotting and statistical testing
        difference = difference(~isnan(difference));

        % Create subplot
        if horizontalmode == 1
            subplot(1, nCellTypes, cell_type);
        else
            subplot(nCellTypes, 1, cell_type);
        end

        hold on;

        % Plot histogram
        histogram(difference, ...
            'BinWidth', binWidth, ...
            'Normalization', 'probability', ...
            'FaceColor', plot_info.colors_celltypes(cell_type, :), ...
            'EdgeColor', plot_info.colors_celltypes(cell_type, :), ...
            'FaceAlpha', 0.9);

        xline(0, '--k', 'LineWidth', 2);

        % Plot mean difference
        mean_diff = mean(difference, 'omitnan');
        y_limits = ylim;

        plot(mean_diff, y_limits(2) * 1.05, 'v', ...
            'MarkerSize', 6, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', 'k');

        xlim(xLimits);

        set(gca, ...
            'FontSize', 7, ...
            'Units', 'inches', ...
            'Position', positions(cell_type, :));

        if cell_type == 1
            % Add x-label to the bottom subplot or first subplot
            if horizontalmode == 1
                if nCellTypes == 1
                    xlabel(string, 'FontSize', 7);
                end
            else
                if nCellTypes == 1
                    xlabel(string, 'FontSize', 7);
                end
            end
        end

        if horizontalmode == 1 && cell_type == 2
            xlabel(string, 'FontSize', 7);
        elseif horizontalmode ~= 1 && cell_type == nCellTypes
            xlabel(string, 'FontSize', 7);
        end

        utils.set_current_fig;
        box off;

        % Permutation test against zero
        if ~isempty(difference)
            [p_raw, ~, ~] = permutationTest_updatedcb( ...
                difference, zeros(size(difference)), ...
                10000, 'paired', 1);
        else
            p_raw = NaN;
        end

        % Preserve the original Bonferroni correction behavior
        if nCellTypes > 1 && p_raw >= 0.05 / nchoosek(nCellTypes, 2)
            p_raw = 1;
        end

        p_val_mod(cell_type) = p_raw;

        stats.(celltype_fields{cell_type}).pval = p_raw;
        stats.(celltype_fields{cell_type}).stats = ...
            get_basic_stats(difference);
        stats.(celltype_fields{cell_type}).mean_diff = mean_diff;
        stats.(celltype_fields{cell_type}).binWidth = binWidth;
        stats.(celltype_fields{cell_type}).absValue = absValue;
        stats.(celltype_fields{cell_type}).n = length(difference);
        % Test whether the mean of the distribution differs from zero
        % Test both directions: greater than zero and less than zero
        % Bonferroni correction for two directional tests: alpha = 0.05 / 2
        
        alpha_corrected = 0.025;
        n_permutations = 10000;
        
        %One-sample t-tests
        
        % Right-sided: mean difference > 0
        [h, p, ci, stats_t] = ttest(difference, 0, ...
            'Tail', 'right', 'Alpha', alpha_corrected);
        
        stats.(celltype_fields{cell_type}).distribution_ttest_right.h = h;
        stats.(celltype_fields{cell_type}).distribution_ttest_right.p = p;
        stats.(celltype_fields{cell_type}).distribution_ttest_right.ci = ci;
        stats.(celltype_fields{cell_type}).distribution_ttest_right.stats_t = stats_t;
        
        % Left-sided: mean difference < 0
        [h, p, ci, stats_t] = ttest(difference, 0, ...
            'Tail', 'left', 'Alpha', alpha_corrected);
        
        stats.(celltype_fields{cell_type}).distribution_ttest_left.h = h;
        stats.(celltype_fields{cell_type}).distribution_ttest_left.p = p;
        stats.(celltype_fields{cell_type}).distribution_ttest_left.ci = ci;
        stats.(celltype_fields{cell_type}).distribution_ttest_left.stats_t = stats_t;
        
        
        %One-sided permutation tests
        
        % Right-sided: mean difference > 0
        [p, observed_difference, effectsize] = ...
            permutationTest_updatedcb( ...
                difference, zeros(size(difference)), ...
                n_permutations, 'paired', 1, 'sidedness', 'larger');
        
        stats.(celltype_fields{cell_type}).distribution_perm_right.p = p;
        stats.(celltype_fields{cell_type}).distribution_perm_right.h = ...
            p < alpha_corrected;
        stats.(celltype_fields{cell_type}).distribution_perm_right.observed_difference = observed_difference;
        stats.(celltype_fields{cell_type}).distribution_perm_right.effectsize = effectsize;
        
        % Left-sided: mean difference < 0
        [p, observed_difference, effectsize] = ...
            permutationTest_updatedcb( ...
                difference, zeros(size(difference)), ...
                n_permutations, 'paired', 1, 'sidedness', 'smaller');
        
        stats.(celltype_fields{cell_type}).distribution_perm_left.p = p;
        stats.(celltype_fields{cell_type}).distribution_perm_left.h = ...
            p < alpha_corrected;
        stats.(celltype_fields{cell_type}).distribution_perm_left.observed_difference = observed_difference;
        stats.(celltype_fields{cell_type}).distribution_perm_left.effectsize = effectsize;

    end

    ylabel('Probability');
    hold off;

    % Save figure and statistics
    if ~isempty(save_path)

        if ~exist(save_path, 'dir')
            mkdir(save_path);
        end

        safe_string = regexprep(string, '[^\w\d_-]', '_');

        % Include settings in the filename to distinguish analyses
        if absValue
            value_label = 'absolute';
        else
            value_label = 'signed';
        end

        filename = sprintf( ...
            'histogram_diff_index_sig_cells_%s_%s_bw%s', ...
            safe_string, value_label, ...
            strrep(num2str(binWidth), '.', 'p'));


        exportgraphics(gcf, ...
            fullfile(save_path, [filename '.pdf']), ...
            'ContentType', 'vector');

        save(fullfile(save_path, ['stats_' filename '.mat']), 'stats');
    end
end
% function [p_val_mod,stats] = histogram_diff_index_sig_cells(chosen_cells, all_celltypes, index, plot_info, save_path, string,horizontalmode, varargin)
%     % originally called histogram_mod_opto_cells
%     % This function generates histograms of the absolute differences in index values 
%     % for different cell types. It also performs a permutation test to determine
%     % the significance of the observed differences.
% 
% 
%     figure(2325); clf; % Create and clear figure
%     p_val_mod = [];
% celltype_fields = fields(all_celltypes{1});
%     if ~isempty(chosen_cells) % Check if chosen_cells is not empty
%         fieldss = fields(all_celltypes{1,1}); % Extract field names from first cell type structure
%         for cell_type = 1:length(fieldss) % Loop over all cell types
%             difference = []; % Initialize difference array
%             if horizontalmode == 1
%                 positions = utils.calculateFigurePositions(1, 5, .5, []);
%                 subplot(1, length(fieldss),  cell_type) % Create subplot for each cell type
%             else
%                 positions = utils.calculateFigurePositions(5,1 , .5, []);
%                 subplot(length(fieldss), 1, cell_type) % Create subplot for each cell type
%             end
%             
%             for dataset_index = 1:length(chosen_cells)
%                 % Find cells belonging to the current cell type
%                 chosen_cells2{cell_type} = chosen_cells{1,dataset_index}(ismember(chosen_cells{1,dataset_index}, all_celltypes{1,dataset_index}.(fieldss{cell_type})));
%                 
%                 % Compute absolute difference in index values
%                 difference = [difference, abs(index{dataset_index,1}(chosen_cells2{cell_type})) - abs(index{dataset_index,2}(chosen_cells2{cell_type}))];
%                 difference = [difference, (index{dataset_index,1}(chosen_cells2{cell_type})) - (index{dataset_index,2}(chosen_cells2{cell_type}))];
% 
%             end
%             
%             hold on
%             % Plot histogram of differences
%             histogram(difference, 'BinWidth', 0.05, 'normalization', 'probability', 'FaceColor', plot_info.colors_celltypes(cell_type,:), ...
%                 'EdgeColor', plot_info.colors_celltypes(cell_type,:), 'FaceAlpha', 0.9, 'Normalization','probability');
%             xline(0, '--k', 'LineWidth', 2);
%             
%             % Calculate and plot the mean difference as an inverted triangle
%             mean_diff = mean(difference, 'omitnan');
%             y_limits = ylim;
%             if nargin > 7
%                 xlim(varargin{1,1});
%             else
%                 xlim([-1 1]);
%             end
%             plot(mean_diff, y_limits(2)*1.05, 'v', 'MarkerSize', 6, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
%             set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(cell_type, :));
%             if length(fieldss) > 1 && cell_type == 2
%                 xlabel(string,'FontSize',7);
%             elseif length(fieldss) == 1
%                 xlabel(string,'FontSize',7);
%             end
%             utils.set_current_fig; % Apply figure settings
%             box off;
%             
%             % Perform a permutation test to compare differences against zero
%             if length(fieldss) > 1
%                 possible_tests = nchoosek(1:length(fieldss), 2);
%                 [p_val_mod(cell_type), ~, ~] = permutationTest_updatedcb(difference, zeros(length(difference), 1), 10000, 'paired', 1);
%                 
%                 % Apply Bonferroni correction
%                 if p_val_mod(cell_type) >= 0.05 / size(possible_tests, 1)
%                     p_val_mod(cell_type) = 1;
%                 end
%                 stats.(celltype_fields{cell_type}).pval = p_val_mod(cell_type);
%             else
%                 [p_val_mod, ~, ~] = permutationTest_updatedcb(difference, zeros(length(difference), 1), 10000, 'paired', 1);
%                 stats.(celltype_fields{cell_type}).pval = p_val_mod;
%             end
%             stats.(celltype_fields{cell_type}).stats = get_basic_stats(difference);
%             
%         end
%     else % If chosen_cells is empty, process all cells
%         fieldss = fields(all_celltypes{1,1});
%         for cell_type = 1:length(fieldss)
%             if horizontalmode == 1
%                 positions = utils.calculateFigurePositions(1, 5, .5, []);
%                 subplot(1, length(fieldss),  cell_type) % Create subplot for each cell type
%             else
%                 positions = utils.calculateFigurePositions(5,1 , .5, []);
%                 subplot(length(fieldss), 1, cell_type) % Create subplot for each cell type
%             end
%             difference = [];
%             
%             for dataset_index = 1:length(all_celltypes)
%                 difference = [difference, abs(index{dataset_index,1}(all_celltypes{1,dataset_index}.(fieldss{cell_type}))) - abs(index{dataset_index,2}(all_celltypes{1,dataset_index}.(fieldss{cell_type})))];
%             end
%             
%             hold on
%             histogram(difference, 'BinWidth', 0.1, 'normalization', 'probability', 'FaceColor', plot_info.colors_celltypes(cell_type,:), ...
%                 'EdgeColor', plot_info.colors_celltypes(cell_type,:), 'FaceAlpha', 0.9, 'Normalization', 'count');
%             xline(0, '--k', 'LineWidth', 2);
%             
%             % Calculate and plot the mean difference
%             mean_diff = mean(difference);
%             y_limits = ylim;
%             plot(mean_diff, y_limits(2)*1.05, 'v', 'MarkerSize', 6, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
%             set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(cell_type, :));
%             if length(fieldss) > 1 && cell_type == 2
%                 xlabel(string,'FontSize',7);
%             elseif length(fieldss) == 1
%                 xlabel(string,'FontSize',7);
%             end
%             utils.set_current_fig;
%             if nargin > 7
%                 xlim(varargin{1,1});
%             else
%                 xlim([-1 1]);
%             end
%             box off;
%             
%             % Perform statistical test
%             if length(fieldss) > 1
%                 possible_tests = nchoosek(1:length(fieldss), 2);
%                 [p_val_mod(cell_type), ~, ~] = permutationTest_updatedcb(difference, zeros(length(difference), 1), 10000, 'paired', 1);
%                 
%                 % Apply Bonferroni correction
%                 if p_val_mod(cell_type) >= 0.05 / size(possible_tests, 1)
%                     p_val_mod(cell_type) = 1;
%                 end
%                 stats.(celltype_fields{cell_type}).pval = p_val_mod(cell_type);
%             else
%                 [p_val_mod, ~, ~] = permutationTest_updatedcb(difference, zeros(length(difference), 1), 10000, 'paired', 1);
%                 stats.(celltype_fields{cell_type}).pval = p_val_mod;
%             end
%             stats.(celltype_fields{cell_type}).stats = get_basic_stats(difference);
%             
%         end
%     end
%     
%     
%     hold off;
%     
% %     % Set figure size
% %     if horizontalmode == 1
% %         % Create invisible axes for shared label
% % %         % Set figure height higher to leave space for label
% % %         set(gcf, 'units', 'points', 'position', [10, 100, 400, 320]);
% % %         
% % %         % Create invisible axes for global x-label
% % %         han = axes('units', 'points', 'Position', [10, 30, 400, 100], 'Visible', 'off');
% % %         han.XLabel.Visible = 'on';
% % %         xlabel(han, string, 'FontSize', 7);
% % 
% % 
% %     else
% % %         set(gcf, 'units', 'points', 'position', [15, 100, 176, 400]);
% % %         han = axes('units', 'points', 'Position',[15, 40, 138, 400],'Visible','off');
% % %           xlabel(han, string, 'FontSize', 7);
% %     end
%     ylabel ('Probability')
%     % Save figure if save_path is provided
%     if ~isempty(save_path)
%         mkdir(save_path); % Create directory if it doesn't exist
%         cd(save_path);
%         safe_string = regexprep(string, '[^\w\d_-]', '_');
% 
%         saveas(gcf, ['histogram_diff_index_sig_cells_' safe_string '.png']);
% %         saveas(gcf, ['histogram_diff_index_sig_cells_' safe_string '.svg']);
%         exportgraphics(gcf, ['histogram_diff_index_sig_cells_' safe_string '.pdf'], 'ContentType', 'vector'); % Save as PDF
%         save(['stats_histogram_diff_index_sig_cells_' safe_string '.mat'],'stats')
%     end
% end
