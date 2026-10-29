function [mean_all ,all_stats] = bar_plot_percent(percent1,percent2, save_dir,celltype_names,colors_celltypes,xlabels)
% expects array size dataset x celltypes
% plots mean+sem across datasets
all_stats = {};
string = 'Fraction Neurons';
mean_percent = [];
possible_tests = []; p_stim = [];

% celltype_names = plot_info.behavioral_contexts;
% colors_celltypes = plot_info.colors_celltypes;
numcells = size(percent1,2);
%1) calculate mean across datasets!
mean_percent(1,:,:) = percent1;
num_percents = 1;
if ~isempty(percent2)
    mean_percent(2,:,:) = percent2;%squeeze(mean(percent2,1,'omitnan'));
    num_percents = 2;
end

positions = utils.calculateFigurePositions(1,9,.2,[]);

figure(999);clf;
% t = tiledlayout(1,numcells);%,'TileSpacing','Compact','Padding','Compact' %need enough space to plot by celltypes not context!

for ce = 1:numcells
%     nexttile
    subplot(1,numcells,ce)
    bar_context =[];SEM_cells = [];
    for percentages = 1:num_percents
        mean_all(percentages,ce) = squeeze(mean(mean_percent(percentages,:,ce),2,'omitnan'));
        std_all = std(mean_all(percentages,ce), 0, 2);
        stats{percentages,ce} = get_basic_stats(squeeze(mean_percent(percentages,:,ce)));

        bar_context = [bar_context; mean_all(percentages,ce)];
        SEM = std(squeeze(mean_percent(percentages,:,ce)),'omitnan')/sqrt(length(mean_percent(percentages,:,ce)));
        SEM_cells = [SEM_cells; SEM];
        all_stats.stats(percentages,ce) = get_basic_stats(squeeze(mean_percent(percentages,:,ce)));

    end
     hold on
        for c = 1:num_percents %by context?
            b = bar([c],bar_context(c),'FaceColor',[1,1,1],'EdgeColor',colors_celltypes(ce,:),'LineWidth' , 1.);
            xtips = b.XEndPoints;
            ytips = b.YEndPoints;
            errorbar(xtips,ytips,SEM_cells(c),'color',colors_celltypes(ce,:),'LineWidth',1.);
    
        end 
        xticks([1:num_percents])


        if num_percents > 1
        [KW_Test.context_p_val,KW_Test.context_tbl, KW_Test.context_stats_cell] = kruskalwallis(squeeze(mean_percent(:,:,ce))',[1:num_percents],'off');
        possible_tests = nchoosek(1:num_percents,2);
        yl = ylim;    
        cct = 0;
            for t = 1:size(possible_tests,1)
                [p_stim(t,ce), observeddifference, effectsize_context] = permutationTest_updatedcb(mean_percent(possible_tests(t,1),:,ce), mean_percent(possible_tests(t,2),:,ce), 10000,'paired',1);
                name_field = strcat('test_',num2str(t),'_celltype_',num2str(ce));
                all_stats.(name_field).pval = p_stim(t,ce);
                all_stats.(name_field).observeddifference = observeddifference;
                all_stats.(name_field).effectsize_context = effectsize_context;
                if p_stim(t,ce) < 0.05/numcells && KW_Test.context_p_val < 0.05
                    xline_vars(1) = possible_tests(t,1); 
                    xline_vars(2) = possible_tests(t,2); 
                    xval = 0;  
                    utils.plot_pval_star(xval, (yl(2)+yl(2)*.05)+cct, p_stim(t,ce), xline_vars,0.01)
                    cct = cct+yl(2)*.2;%0.05;
                    
                end
            end
    
        end
    % Customize the plot
    set(gca, 'XTickLabel', xlabels,'XTickLabelRotation',45);
    if ce == 1
        ylabel(string);
    end
    utils.set_current_fig;
    xlim([0 length(xlabels)+.99])
%     all_stats.KW{ce} = KW_Test;
    pos = positions(ce, :);
    pos(2) = pos(2) - 0.25;       % move down by 0.25 inches
    set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', pos);
    title(celltype_names{ce},'FontWeight','normal','FontSize',7);

    ax = gca;
    ax.XLabel.FontSize = ax.FontSize;
    ax.YLabel.FontSize = ax.FontSize;
    ylim([0,0.45])
end


all_stats.ptest = 'paired permutation';
all_stats.possible_tests =possible_tests;
% set(gcf,'units','points','position',[10,100,(500/3*length(behavioral_contexts)),200])


if ~isempty(save_dir)
    mkdir(save_dir)
    cd(save_dir)
%     saveas(gcf,strcat(['bar_' string '_contexts.svg']));
    if size(celltype_names{1,1},1)  >1
        celltype_names = cellfun(@(x) x{1}, celltype_names, 'UniformOutput', false);
    end
    exportgraphics(gcf,strcat('bar_percents', strjoin(cellstr(celltype_names), ''),'_', strjoin(cellstr(xlabels), ''), '.pdf'), 'ContentType', 'vector');
    saveas(gcf,strcat('bar_percents', strjoin(cellstr(celltype_names), ''),'_', strjoin(cellstr(xlabels), ''),'.fig'));
    save(strcat('bar_percents', strjoin(cellstr(celltype_names), ''),'_all_stats'),'all_stats');
end