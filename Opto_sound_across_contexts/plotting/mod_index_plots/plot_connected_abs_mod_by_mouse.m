function mod_stats = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, mouseID, plot_info, varargin)
    % Plot modulation index with connected lines for each mouse/dataset
    % Inputs:
    %   save_dir            - Directory to save figures and stats (string, can be empty).
    %   mod_index_by_dataset - Cell array {dataset x context x celltype} of modulation values.
    %   mouseID             - Numeric array mapping each dataset to a mouse ID.
    %   plot_info           - Struct with plotting info (fields: behavioral_contexts, colors_celltypes, celltype_names, etc.).
    %   varargin            - Optional:
    %                           {1}: y-axis limits, e.g. [0 0.4]
    %                           {2}: abs_logic flag (1 = absolute values, 0 = signed)
    %                           {3}: custom save string for figure names


    figure(700);clf
    positions = utils.calculateFigurePositions(1, 5, .5, []);
    if size( mod_index_by_dataset,2) == 3
        num_contexts = 2;
    else
        num_contexts = size( mod_index_by_dataset,2);
    end
    unique_mice = unique(mouseID);
    n_mice = length(unique_mice);
    n_celltypes =  size( mod_index_by_dataset,3);
    count = 0;
    x_lines = 0:num_contexts*n_celltypes+1;
    p_val_mod = [];diff =[];effectsize=[];
    lme_stats = struct;
    lme_stats_v2 = struct;

    if nargin > 4
        ylims = varargin{1,1};
    end
    abs_logic = 1;
    if nargin > 5
        abs_logic = varargin{1,2};
    end
    mean_cell_all2 = []
    for celltype = 1:n_celltypes
        mean_cell_all = [];

        % Build table for mixed effects model
        lme_table = table;
        lme_table_v2 = table;
        
        % Get x positions for this celltype
        x_pos = x_lines((celltype-1)*num_contexts+2:celltype*num_contexts+1);
        
        % Calculate and plot individual mouse lines
        for m = 1:n_mice
            curr_mouse = unique_mice(m);
            mouse_datasets = find(mouseID == curr_mouse);
            
            % Get mean for each context
            mouse_means = zeros(1, num_contexts);
            for context = 1:num_contexts
                % Average across datasets for this mouse
                mouse_data = [];
                for d = mouse_datasets
                    if abs_logic == 1
                        curr_data = abs(mod_index_by_dataset{d,context,celltype});
                    else
                        curr_data = (mod_index_by_dataset{d,context,celltype});
                    end
                    mouse_data = [mouse_data; curr_data(:)];

                    % ---------------------------------------------------------
                    % Session-level LME table (NO averaging across sessions)
                    % ---------------------------------------------------------
                    valid_vals = curr_data(~isnan(curr_data));                
                    if ~isempty(valid_vals)
                    
                        temp_tbl2 = table;
    
%                         temp_tbl2.Mouse = repmat(curr_mouse,length(valid_vals),1);
%                         temp_tbl2.Dataset = repmat(d,length(valid_vals),1);
%                         temp_tbl2.Context = repmat(context,length(valid_vals),1);
%                         temp_tbl2.Modulation = valid_vals(:);
                        temp_tbl2.Mouse = curr_mouse;
                        temp_tbl2.Dataset = d;
                        temp_tbl2.Context = context;
                        temp_tbl2.Modulation = mean(valid_vals(:));
                        lme_table_v2 = [lme_table_v2; temp_tbl2];
                    
                    end
                end
                mouse_means(context) = nanmean(mouse_data);

                for context = 1:num_contexts
                    temp_tbl = table;
                
                    temp_tbl.Mouse = curr_mouse;
                    temp_tbl.Context = context;
                    temp_tbl.Modulation = mouse_means(context);
                
                    lme_table = [lme_table; temp_tbl];
                end

                

            end
            
            % Plot connected line for this mouse
            if num_contexts > 1 && ~isfield(plot_info,'zero_star') || num_contexts > 1 && isfield(plot_info,'zero_star') && plot_info.zero_star == 0
                for c = 1:(num_contexts - 1)
                    plot([x_pos(c) + 0.2, x_pos(c+1) - 0.2], ...
                         [mouse_means(c), mouse_means(c+1)], ...
                         '-', 'Color', [plot_info.colors_celltypes(celltype,:), 0.3], ...
                         'LineWidth', 1);
                end
%                 plot([x_pos(1)+.2,x_pos(2)-.2], mouse_means, '-', 'Color', ...
%                     [plot_info.colors_celltypes(celltype,:), 0.3], 'LineWidth', 1)
            end
            hold on
            
            % Store mouse means for statistics
            for context = 1:num_contexts
                mod_stats.stats(celltype,context).mouse_means(m) = mouse_means(context);
            end
        end
        
        % Calculate and plot mean ± SEM across mice for each context
        for context = 1:num_contexts
            count = count + 1;
            curr_means = mod_stats.stats(celltype,context).mouse_means;
%             mean_cel = nanmean(curr_means);
%             err = std(curr_means, 'omitnan') / sqrt(sum(~isnan(curr_means)));

            valid_data = curr_means(~isnan(curr_means));
            if ~isempty(valid_data)
                mean_cel = mean(valid_data);
                err = std(valid_data) / sqrt(length(valid_data));
                
                % Store stats with number of valid datasets
                mod_stats.stats(celltype,context).valid_means = valid_data;
                mod_stats.stats(celltype,context).mean = mean_cel;
                mod_stats.stats(celltype,context).sem = err;
                mod_stats.stats(celltype,context).n_valid_datasets = length(valid_data);
                mod_stats.stats(celltype,context).valid_datasets = find(~isnan(curr_means));
                 % Calculate 95% CI using bootstrapping
                mod_stats.stats(celltype,context).basic_stats =  get_basic_stats(valid_data);
                
                % Plot error bar (SEM)
                errorbar(x_pos(context), mean_cel, err, 'o', ...
                'Color', plot_info.colors_celltypes(celltype,:), ...
                'LineWidth', 1, 'MarkerSize', 2,'MarkerFaceColor', plot_info.colors_celltypes(celltype,:))
            
                mean_cell_all = [mean_cell_all, mean_cel];

                % One-sample permutation test vs zero
                n_perm = 10000;
                observed_mean = mean(valid_data);
                null_distribution = zeros(1, n_perm);
                for p = 1:n_perm
                    signs = randi([0 1], size(valid_data)) * 2 - 1;  % random +1/-1
                    null_distribution(p) = mean(valid_data .* signs);
                end
                p_val_vs_zero = mean(abs(null_distribution) >= abs(observed_mean));
                if p_val_vs_zero == 0
                    p_val_vs_zero = 1/n_perm;
                end
                mod_stats.stats(celltype,context).p_val_vs_zero = p_val_vs_zero;
    
                if isfield(plot_info,'zero_star') && plot_info.zero_star == 1%only plot if requested
                    yline(0,'color',[0.5,0.5,0.5],'LineStyle','--')
                    if p_val_vs_zero < 0.05/(n_celltypes*num_contexts) %correct for multiple comparisons
    %                     text(x_pos(context), mean_cel + err + 0.02, '*', ...
    %                         'Color', plot_info.colors_celltypes(celltype,:), ...
    %                         'FontSize', 7, 'HorizontalAlignment', 'center');
                                utils.plot_pval_star(x_pos(context),mean_cel + err + 0.02,p_val_vs_zero,[0,0],0,[0,0,0]);%plot_info.colors_celltypes(celltype,:)
                    end
                end
            else
                valid_means = [];
                mod_stats.stats(celltype,1).valid_means = valid_means
            end

%             % Plot error bar (CI)
%             errorbar(x_pos(context), mean_cel, err_low, err_up, 'o', ...
%                 'Color', plot_info.colors_celltypes(celltype,:), ...
%                 'LineWidth', 1.3, 'MarkerSize', 3,'MarkerFaceColor', plot_info.colors_celltypes(celltype,:))
           
        end

        % Statistical testing for this cell type
        if num_contexts > 1
            ct = 0;
            possible_tests = nchoosek(1:num_contexts,2);
            if max(mean_cell_all) > 0.1
                y_val = max(mean_cell_all) + 0.03;
            else
                y_val = max(mean_cell_all);
            end
        
            for t = 1:size(possible_tests,1)
                ctx1 = possible_tests(t,1);
                    ctx2 = possible_tests(t,2);
    
                    % Get data for statistical test
                    % Skip if this celltype has no data for either context
                    if isempty(mod_stats.stats) || ...
                       celltype > size(mod_stats.stats,1) || ...
                       isempty(mod_stats.stats(celltype,ctx1).valid_means) || ...
                       isempty(mod_stats.stats(celltype,ctx2).valid_means)
                        continue;
                    end
    
                    % Extract data
                    data1 = mod_stats.stats(celltype,ctx1).valid_means;
                    data2 = mod_stats.stats(celltype,ctx2).valid_means;
    
                    % Align datasets if lengths differ (use intersection of valid datasets if available)
                    if length(data1) ~= length(data2)
                        if isfield(mod_stats.stats(celltype,ctx1), 'valid_datasets') && ...
                           isfield(mod_stats.stats(celltype,ctx2), 'valid_datasets')
                           
                           % Intersect dataset indices from both contexts
                           common_datasets = intersect(mod_stats.stats(celltype,ctx1).valid_datasets, ...
                                                       mod_stats.stats(celltype,ctx2).valid_datasets);
                
                           [~, idx1] = ismember(common_datasets, mod_stats.stats(celltype,ctx1).valid_datasets);
                           [~, idx2] = ismember(common_datasets, mod_stats.stats(celltype,ctx2).valid_datasets);
                
                           data1 = data1(idx1);
                           data2 = data2(idx2);
                        else
                           % Skip if we can't align data
                           continue;
                        end
                    end
                
                if ~isempty(data1)
                [p_val_mod(t,celltype), diff(t,celltype), effectsize(t,celltype)] = permutationTest_updatedcb(...
                    data1, data2, 10000, 'paired', 1);
                else
                    p_val_mod(t,celltype) = 1;
                end
    
                if size(possible_tests,1) == 1 && size(mod_stats.stats,1) == 1 && celltype > 1%assume only pyr has valid stuff
                        p_val_mod(t,celltype) = 1;
                end
                
                if p_val_mod(t,celltype) < 0.05/n_celltypes
                    xline_vars = possible_tests(t,:) + ((celltype-1)*num_contexts);
                    ct = ct + y_val*0.3;
                    utils.plot_pval_star(0, y_val+ct, p_val_mod(t,celltype), xline_vars, ...
                        0.01, plot_info.colors_celltypes(celltype,:))
                end

                % -------------------------------------------------------------------------
                % Linear mixed effects model
                % -------------------------------------------------------------------------
                
                if num_contexts > 1 
                    % remove NaNs
                    valid_idx = ~isnan(lme_table.Modulation);
                
                    lme_table_valid = lme_table(valid_idx,:);
                
                    % categorical variables
                    lme_table_valid.Mouse = categorical(lme_table_valid.Mouse);
                    lme_table_valid.Context = categorical(lme_table_valid.Context);
                    try
                
                        % random intercept for mouse
                        lme = fitlme( ...
                            lme_table_valid, ...
                            'Modulation ~ Context + (1|Mouse)');
                
                        coef_tbl = lme.Coefficients;
                
                        % context term is second row
                        if height(coef_tbl) > 1
                            lme_stats(celltype).p_context = coef_tbl.pValue(2);
                            lme_stats(celltype).t_context = coef_tbl.tStat(2);
                            lme_stats(celltype).beta_context = coef_tbl.Estimate(2);
                
                        else
                            lme_stats(celltype).p_context = NaN;
                            lme_stats(celltype).t_context = NaN;
                            lme_stats(celltype).beta_context = NaN;
                
                        end
                        % pseudo-R
                        fitted_vals = fitted(lme);
                        observed_vals = lme_table_valid.Modulation;
                
                        r_val = corr(fitted_vals,observed_vals,'rows','complete');
                
                        lme_stats(celltype).r = r_val;
                        lme_stats(celltype).lme = lme;
                
                    catch
                        lme_stats(celltype).p_context = NaN;
                        lme_stats(celltype).t_context = NaN;
                        lme_stats(celltype).beta_context = NaN;
                        lme_stats(celltype).r = NaN;
                        lme_stats(celltype).lme = [];
                    end
                end

                % -------------------------------------------------------------------------
                % Linear mixed effects model v2
                % Session-level values with mouse random effect
                % -------------------------------------------------------------------------
                
                valid_idx2 = ~isnan(lme_table_v2.Modulation);
                
                lme_table_v2_valid = lme_table_v2(valid_idx2,:);
                
                lme_table_v2_valid.Mouse = categorical(lme_table_v2_valid.Mouse);
                lme_table_v2_valid.Context = categorical(lme_table_v2_valid.Context);
                lme_table_v2_valid.Dataset = categorical(lme_table_v2_valid.Dataset);
                
                try
                
                    lme2 = fitlme( ...
                        lme_table_v2_valid, ...
                        'Modulation ~ Context + (1|Mouse)');
                
                    coef_tbl2 = lme2.Coefficients;
                
                    if height(coef_tbl2) > 1
                
                        lme_stats_v2(celltype).p_context = coef_tbl2.pValue(2);
                        lme_stats_v2(celltype).t_context = coef_tbl2.tStat(2);
                        lme_stats_v2(celltype).beta_context = coef_tbl2.Estimate(2);
                
                    else
                
                        lme_stats_v2(celltype).p_context = NaN;
                        lme_stats_v2(celltype).t_context = NaN;
                        lme_stats_v2(celltype).beta_context = NaN;
                
                    end
                
                    fitted_vals2 = fitted(lme2);
                    observed_vals2 = lme_table_v2_valid.Modulation;
                
                    r_val2 = corr(fitted_vals2,observed_vals2,'rows','complete');
                
                    lme_stats_v2(celltype).r = r_val2;
                    lme_stats_v2(celltype).lme = lme2;
                
                    lme_stats_v2(celltype).n_sessions = ...
                        length(unique(lme_table_v2_valid.Dataset));
                
                    lme_stats_v2(celltype).n_mice = ...
                        length(unique(lme_table_v2_valid.Mouse));
                
                catch
                
                    lme_stats_v2(celltype).p_context = NaN;
                    lme_stats_v2(celltype).t_context = NaN;
                    lme_stats_v2(celltype).beta_context = NaN;
                    lme_stats_v2(celltype).r = NaN;
                    lme_stats_v2(celltype).lme = [];
                
                end

        end
        mean_cell_all2 = [mean_cell_all2, mean_cell_all];
    end
    
    % Format plot
    xlim([x_lines(1) x_lines(end)])
    xticks(x_lines(2:end-1))
    xticklabels(repmat(plot_info.behavioral_contexts, 1, n_celltypes))

    %do statsitical testing across celltypes if only one context present!
    if num_contexts == 1 && n_celltypes > 2
        possible_tests = nchoosek(1:n_celltypes,2);
        % Suppose mod_stats.stats is a structure array
        nStats = numel(mod_stats.stats);
        maxLen = max(arrayfun(@(s) numel(s.valid_means), mod_stats.stats));

        data_padded = NaN(maxLen, nStats);
        
        for i = 1:nStats
            vals = mod_stats.stats(i).valid_means(:);
            data_padded(1:numel(vals), i) = vals;
        end
        
        % Flatten into vector form
        Y = data_padded(:);
        group = repelem(1:nStats, maxLen)';
        
        % Remove NaNs before running test
        valid_idx = ~isnan(Y);
        Y = Y(valid_idx);
        group = group(valid_idx);
        
        % Run Kruskal–Wallis test without plotting
        [KW.p_val,KW.tbl, KW.stats_cell] = kruskalwallis(Y, group,  'off');

        ct = 0;
        for t = 1:size(possible_tests,1)
            data1 = mod_stats.stats(possible_tests(t,1)).valid_means;
            data2 = mod_stats.stats(possible_tests(t,2)).valid_means;
            
            % Align datasets if lengths differ (use intersection of valid datasets if available)
                    if length(data1) ~= length(data2)
                        if isfield(mod_stats.stats(possible_tests(t,1)), 'valid_datasets') && ...
                           isfield(mod_stats.stats(possible_tests(t,2)), 'valid_datasets')
                           
                           % Intersect dataset indices from both contexts
                           common_datasets = intersect(mod_stats.stats(possible_tests(t,1)).valid_datasets, ...
                                                       mod_stats.stats(possible_tests(t,2)).valid_datasets);
                
                           [~, idx1] = ismember(common_datasets, mod_stats.stats(possible_tests(t,1)).valid_datasets);
                           [~, idx2] = ismember(common_datasets, mod_stats.stats(possible_tests(t,2)).valid_datasets);
                
                           data1 = data1(idx1);
                           data2 = data2(idx2);
                        else
                           % Skip if we can't align data
                           continue;
                        end
                    end

            if ~isempty(data1)
%                 [KW.p_val{t},KW.tbl{t}, KW.stats_cell{t}] = kruskalwallis(T(:,:),[1:nStats],'off');
                [p_val_mod_cells(t), diff_cells(t,celltype), effectsize_cells(t)] = permutationTest_updatedcb(...
                    data1, data2, 10000, 'paired', 1); %paired since Im comparing values from each dataset to each other
            else
                p_val_mod_cells(t) = 1;
            end
                
%             get y values
            if max(mean_cell_all2) > 0.1
                y_val = max(mean_cell_all2) + 0.03;
            else
                y_val = max(mean_cell_all2);
            end
% y_val = 0.15;
            if p_val_mod_cells(t) < 0.05 && KW.p_val < 0.05
                xline_vars = possible_tests(t,:);
                ct = ct + y_val*0.3;
                utils.plot_pval_star(0, y_val+ct, p_val_mod_cells(t), xline_vars, ...
                    0.01, [0,0,0])
            end
        end

    end

    if abs_logic == 1;
        ylabel({'|Modulation Index|'},'FontSize',7)
    else
        ylabel({'Modulation Index'},'FontSize',7)
    end

    if nargin > 6
        ylabel(varargin{1,3});
    end
    
    % Set axis limits
    if nargin > 4
        yli = ylim;
        if yli(2) < ylims(2)
            ylim(ylims);
        elseif yli(2) > ylims(2) 
            ylim([ylims(1),yli(2)])
        end
    else
        yli = ylim;
        ylim([0,yli(2)]);
    end
    
    % Set figure properties

    set(gcf,'Color','w')

%     set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
    box off
    xtickangle(45)
%     set(gcf,'units','points','position',[10,100,(400/n_celltypes*num_contexts),170]);
    set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
    utils.set_current_fig;
    
    % Store statistics
    if num_contexts > 1
        mod_stats.tests = possible_tests;
        mod_stats.p_test = 'paired permutation across mice';
        mod_stats.p_val_mod = p_val_mod;
        mod_stats.difference = diff;
        mod_stats.effectsize = effectsize;
        mod_stats.n_mice = n_mice;
        mod_stats.lme_stats = lme_stats;
        mod_stats.lme_stats_v2 = lme_stats_v2;
    end

    if num_contexts == 1 && n_celltypes > 2
        mod_stats.tests = possible_tests;
        mod_stats.p_test = 'paired permutation across mice';
        mod_stats.p_val_mod = p_val_mod_cells;
        mod_stats.difference = diff_cells;
        mod_stats.effectsize = effectsize_cells;
        mod_stats.n_mice = n_mice;
        mod_stats.KW = KW;
        mod_stats.lme_stats = lme_stats;
        mod_stats.lme_stats_v2 = lme_stats_v2;
        axis normal
        positions(:,3) = positions(:,3)*(2/3);
        positions(:,4) = positions(:,4)*1;
        positions(:,2) = positions(:,2) - 1;
        set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(1, :));
        ax = gca;
        ax.XLabel.FontSize = 7;
        ax.YLabel.FontSize = 7;
        xticklabels(repmat(plot_info.celltype_names, 1, n_celltypes))
        
    end
    
    % Save results
    if ~isempty(save_dir)
        mkdir(save_dir)
        cd(save_dir)
        
        if nargin > 6
            save_string = varargin{1,3};
            save_string = strrep(save_string, '\', '');
            save_string = strrep(save_string, '/', '');
            save_string = strrep(save_string, '(', '');
            save_string = strrep(save_string, ')', '');
            save_string = strrep(save_string, '|', '');
            if iscell(save_string)
                save_string = strjoin(save_string, '_'); %convert cell to string
            end
            if any(contains(save_string,'Δ')) || any(contains(save_string,'elta'))
                save_string = [save_string 'deltastim']
            end
            if isfield(plot_info,'zero_star') && plot_info.zero_star == 1
                save_string = [save_string 'vszero'];
            end
%             save_string = strjoin(save_string);
            saveas(700,strcat(save_string,'_abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'.svg'));
            saveas(700,strcat(save_string,'_abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'.fig'));
            exportgraphics(figure(700),strcat(save_string,'_abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'_datasets.pdf'), 'ContentType', 'vector');
            save(strcat(save_string,'_abs',num2str(abs_logic), '_mod_index_stats_connected_lines_n',num2str(n_mice)),'mod_stats');

        else
            saveas(700,strcat('abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'.svg'));
            saveas(700,strcat('abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'.fig'));
            exportgraphics(figure(700),strcat('abs',num2str(abs_logic), '_mod_index_connected_lines_n',num2str(n_mice),'_datasets.pdf'), 'ContentType', 'vector');
            save(strcat('abs',num2str(abs_logic), '_mod_index_stats_connected_lines_n',num2str(n_mice)),'mod_stats');
        end
    end
end