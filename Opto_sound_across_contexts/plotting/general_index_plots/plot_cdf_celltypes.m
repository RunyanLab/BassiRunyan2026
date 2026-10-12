function mod_stats = plot_cdf_celltypes(save_dir, index_to_plot, mouseID, plot_info,save_string, varargin)
    % Plot modulation index with connected lines for each mouse
    % Inputs:
    %   save_dir - directory to save results
    %   mod_index_by_dataset - cell array {dataset, context, celltype}
    %   mouseID - array indicating mouse ID for each dataset
    %   plot_info - structure with plotting parameters
    
    figure(750);clf
    hold on;
    positions = utils.calculateFigurePositions(1, 6, .3, []);
    if size( index_to_plot,2) > 2
        num_contexts = 2;
    else
        num_contexts = size( index_to_plot,2);
    end
    unique_mice = unique(mouseID);
    n_mice = length(unique_mice);
    n_celltypes =  size( index_to_plot,3);
    count = 0;
    x_lines = 0:num_contexts*n_celltypes+1;
    
    if nargin < 6
        binss = -.1:0.01:0.3;
    else
        bin = varargin{1};
        binss = bin(1):0.01:bin(2);
    end

    
for celltype = 1:n_celltypes
    mean_cell_all = [];
    
    % Get x positions for this celltype
    x_pos = x_lines((celltype-1)*num_contexts+2:celltype*num_contexts+1);
    
    % Calculate and plot individual mouse lines
   
        % Get mean for each context
        all_cells_data = {};
        for context = 1:num_contexts
            % get all cells
            all_cell_data = [];
            for dataset = mouseID
                curr_data = (index_to_plot{dataset,context,celltype});
                if size(curr_data,1) == 1
                    curr_data = curr_data';
                end
                all_cell_data = [all_cell_data;curr_data];
            end
            
            if nargin <7
            subplot(n_celltypes,1,celltype);
            end
            hold on

            % Plot cdf across all neurons
                [cdf_data{context}, ~] = make_cdf(all_cell_data, binss);
            
            a(context) = plot(binss, cdf_data{context}, 'LineWidth', 1.5, ...
                'LineStyle', plot_info.lineStyles_contexts{context}, 'Color', plot_info.colors(celltype, :));
            mod_stats.stats(celltype,context).basic_stats =  get_basic_stats(all_cell_data);
            
            %save data
            all_cells_data{celltype,context} = all_cell_data;
        end
            
        
        % Statistical testing for this cell type
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

                % Extract data
                data1 = all_cells_data{celltype,ctx1};
                data2 = all_cells_data{celltype,ctx2};
            
            [p_val_mod(t,celltype), ~, effectsize(t,celltype)] = permutationTest_updatedcb(...
                data1, data2, 10000, 'paired', 1);
            ct2 = 0;
            if p_val_mod(t,celltype) < 0.05/n_celltypes
%                 xline_vars = possible_tests(t,:) + ((celltype-1)*num_contexts);
%                 
%                 utils.plot_pval_star(0, y_val+ct, p_val_mod(t,celltype), xline_vars, ...
%                     0.01, plot_info.colors_celltypes(celltype,:))

                xline_vars = [binss(find(cdf_data{ctx1} > 0.8 + ct2, 1, 'first')), ...
              binss(find(cdf_data{ctx2} > 0.8 + ct2, 1, 'first'))];
            utils.plot_pval_star(0, 0.81 + ct2, p_val_mod(t,celltype), xline_vars, 0.01);
            ct2 = ct2 + 0.03;

            end
        end
        
        if celltype == 1
            ylabel({'CDF'})
        end

        if celltype == 2
            xlabel(save_string)
        end

        if n_celltypes == 1
            xlabel(save_string)
        end

        % Set figure properties
%     set(gcf,'units','points','position',[10,100,(400/n_celltypes*num_contexts),170]);
    set(gca, 'FontSize', 8, 'FontName','Arial','Units', 'inches', 'Position', positions(celltype, :));
    utils.set_current_fig;
    box(gca, 'off');
    grid on
    end

    
    
    
    
    
    % Store statistics
    mod_stats.tests = possible_tests;
    mod_stats.p_test = 'paired permutation across mice';
    mod_stats.p_val_mod = p_val_mod;
    mod_stats.effectsize = effectsize;
    mod_stats.n_mice = n_mice;
    
    % Save results
    if ~isempty(save_dir)
        mkdir(save_dir)
        cd(save_dir)
        save_string = strrep(save_string, '\', '');
            save_string = strrep(save_string, '/', '');
            save_string = strrep(save_string, '(', '');
            save_string = strrep(save_string, ')', '');
        saveas(750,strcat(save_string,'_cdf_n',num2str(n_mice),'.fig'));
        exportgraphics(figure(750),strcat(save_string,'_cdf_n',num2str(n_mice),'_datasets.pdf'), 'ContentType', 'vector');
        save(strcat(save_string,'_cdf_n',num2str(n_mice)),'mod_stats');
    end
end