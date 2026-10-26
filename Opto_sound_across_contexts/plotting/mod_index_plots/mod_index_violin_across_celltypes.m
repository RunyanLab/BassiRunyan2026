function [stats] = mod_index_violin_across_celltypes(save_dir,stim_mod,behavioral_contexts,colors,violin_version,celltypes_ids,chosen_mice,varargin)

figure(97);clf
% t = tiledlayout(1,length(celltypes_ids),'TileSpacing','Compact','Padding','Compact');
positions = utils.calculateFigurePositions(1, 7, .3, []);
if 1 == length(behavioral_contexts)
    %increase height
    positions = utils.calculateFigurePositions(1, 9, .2, []);
    positions(:,2) = positions(:,2) -0.5;  % width is 3rd element
    positions(:,4) = positions(:,4) * 1.5;  % width is 3rd element
end
p_stim = [];
for cel_type = 1:length(celltypes_ids)
    %     nexttile
    subplot(1,length(celltypes_ids),cel_type)
    title(celltypes_ids{2,cel_type},'FontSize',7,'FontName','arial','FontWeight','normal');
    for context = 1:length(behavioral_contexts)

        stats.stats{cel_type,context} = get_basic_stats(stim_mod(celltypes_ids{1,cel_type},context));
        stats.stats{cel_type,context}.median = median(stim_mod(celltypes_ids{1,cel_type},context));
        %make plots
        hold on
    if violin_version == 1
        a(context) = Violin({stim_mod(celltypes_ids{1,cel_type},context)},context,'ViolinColor',[{colors(cel_type,:)}],'EdgeColor',colors(cel_type,:),'QuartileStyle','shadow','ViolinAlpha',{0.0}); %,'ViolinAlpha',{0.0, 0.8}
    else
        a(context) = Violin({stim_mod(celltypes_ids{1,cel_type},context)},context,'ViolinColor',[{colors(cel_type,:)}],'EdgeColor',colors(cel_type,:),'QuartileStyle','boxplot'); %,'ViolinAlpha',{0.0, 0.8}
    end
    
        
        if cel_type == 1 && length(behavioral_contexts) > 1
            ylabel('Modulation Index')
        elseif cel_type == 1 && length(behavioral_contexts) == 1
            ylabel('Engagement Index')
%         elseif cel_type == 2
%             xlabel('Modulation Index')
        end

        stim_contexts{context} = stim_mod(celltypes_ids{1,cel_type},context);
    end

    %permutation test
    if length(behavioral_contexts)>1
        possible_tests = nchoosek(1:length(behavioral_contexts),2);
        
        ct = 0;
        
        for t = 1:size(possible_tests,1)
            [p_stim(t), observeddifference, effectsize] = permutationTest_updatedcb(stim_mod(celltypes_ids{1,cel_type},possible_tests(t,1)), stim_mod(celltypes_ids{1,cel_type},possible_tests(t,2)), 10000,'paired',1);

            if p_stim(t) < 0.05/length(celltypes_ids)
                xline_vars(1) = possible_tests(t,1); 
                xline_vars(2) = possible_tests(t,2); 
                xval = 0;  
                utils.plot_pval_star(xval, 1+ct, p_stim(t), xline_vars,0.01)
                ct = ct+0.1;
            end

        end
    end

    if nargin >7
        ylim(varargin{1,1});
    else
        ylim([-1 1]);
    end
    xticks([1:length(behavioral_contexts)])
    if length(behavioral_contexts) == 1
        xticklabels(celltypes_ids{2,cel_type})
        title('')
    else
        xticklabels(behavioral_contexts)
    end

    set(gca,'fontsize',7,'Units','Inches','Position',positions(cel_type,:));
    ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
    stats.p_all{cel_type} = p_stim;
%     utils.set_current_fig;
end

hold off
% set(gcf,'units','points','position',[10,100,400,200])


%make boxplot!
w = 0.5
figure(98);clf
% t = tiledlayout(1,length(celltypes_ids),'TileSpacing','Compact','Padding','Compact');
for cel_type = 1:length(celltypes_ids)
%     nexttile
    subplot(1,length(celltypes_ids),cel_type)
    title(celltypes_ids{2,cel_type},'FontSize',7,'FontName','arial','FontWeight','normal');
    for context = 1:length(behavioral_contexts)

        %make plots
        hold on
%         yline(.1,'--','color',[0.6 0.6 0.6])
%         yline(-.1,'--','color',[0.6 0.6 0.6])
        h = boxplot(stim_mod(celltypes_ids{1,cel_type},context), 'position', context, 'width', w, 'colors', colors(cel_type,:),'symbol', 'o');
        %set line width
        out_line = findobj(h, 'Tag', 'Outliers');
        set(out_line, 'Visible', 'off');
        hh = findobj('LineStyle','--','LineWidth',1); 
        set(h(1:6), 'LineStyle','-','LineWidth',1.5);
        
        if cel_type == 1 && length(behavioral_contexts) > 1
            ylabel('Modulation Index')
        elseif cel_type == 1 && length(behavioral_contexts) == 1
            ylabel('Engagement Index')
%         elseif cel_type == 2
%             xlabel('Modulation Index')
        end

        stim_contexts{context} = stim_mod(celltypes_ids{1,cel_type},context);
    end

    %permutation test
    if length(behavioral_contexts)>1
        possible_tests = nchoosek(1:length(behavioral_contexts),2);
        
        ct = 0;
        
        for t = 1:size(possible_tests,1)
            [p_stim(t), observeddifference, effectsize] = permutationTest_updatedcb(stim_mod(celltypes_ids{1,possible_tests(t,1)}), stim_mod(celltypes_ids{1,possible_tests(t,2)}), 10000);

            if p_stim(t) < 0.05/length(celltypes_ids)
                xline_vars(1) = possible_tests(t,1); 
                xline_vars(2) = possible_tests(t,2); 
                xval = 0;  
                utils.plot_pval_star(xval, .7+ct, p_stim(t), xline_vars,0.01)
                ct = ct+0.1;
            end

        end
    elseif length(behavioral_contexts) == 1 && size(celltypes_ids,2) > 1
        possible_tests = nchoosek(1:size(celltypes_ids,2),2);
        
        ct = 0;
        
        for t = 1:size(possible_tests,1)
            [p_stim(t), observeddifference, effectsize] = permutationTest_updatedcb(stim_mod(celltypes_ids{1,possible_tests(t,1)}), stim_mod(celltypes_ids{1,possible_tests(t,2)}), 10000);

        end
    end

    if nargin >7
        ylim(varargin{1,1});
    else
        ylim([-1 1]);
    end
    xticks([1:length(behavioral_contexts)])
    if length(behavioral_contexts) == 1
        if size(celltypes_ids{2,cel_type},1)>1
            xtlabs = cellfun(@(x) strjoin(x, '\n'), celltypes_ids(2,:), 'UniformOutput', false);
        else
            xtlabs = celltypes_ids{2,cel_type};
        end
        xticklabels(xtlabs)
        title('')
    else
        xticklabels(behavioral_contexts)
    end
    xlim([0 length(behavioral_contexts)+1])
    set(gca,'fontsize',7,'box','off','Units','Inches','Position',positions(cel_type,:));
    ax = gca;
ax.XLabel.FontSize = ax.FontSize;
ax.YLabel.FontSize = ax.FontSize;
    stats.p_all_box{cel_type} = p_stim;
%     utils.set_current_fig;
end

hold off
% set(gcf,'units','points','position',[10,100,400,200])
% % figure(98);clf
% % t = tiledlayout(1,length(behavioral_contexts),'TileSpacing','Compact','Padding','Compact');
% % for cel = 1:length(celltypes_ids)
% %     nexttile
% %     title(celltypes_ids{2,cel},'FontSize',8,'FontName','arial','FontWeight','normal');
% %     for c = 1:length(behavioral_contexts)
% % 
% %         %make plots
% %         hold on
% % %         yline(.1,'--','color',[0.6 0.6 0.6])
% % %         yline(-.1,'--','color',[0.6 0.6 0.6])
% %         h = histogram(stim_mod(celltypes_ids{1,cel},c), 'BinWidth',0.1,'FaceColor',colors(cel,:),'Normalization','probability'); 
% %         %set line width
% % %         out_line = findobj(h, 'Tag', 'Outliers');
% % %         set(out_line, 'Visible', 'off');
% % %         hh = findobj('LineStyle','--','LineWidth',1); 
% % %         set(h(1:6), 'LineStyle','-','LineWidth',1.5);
% %         
% %         if cel == 1
% %             ylabel('Modulation Index')
% %         elseif cel == 2
% %             %xlabel('Modulation Index')
% %         end
% %     end
% % end
%%
%%

if ~isempty(save_dir)
    mkdir(save_dir)
    cd(save_dir)
    saveas(97,strcat('mod_index_violin_across_celltypes_',num2str(length(chosen_mice)),'_datasets.svg'));
    saveas(97,strcat('mod_index_violin_across_celltypes_',num2str(length(chosen_mice)),'_datasets.fig'));
    exportgraphics(figure(97),[strcat('mod_index_violin_across_celltypes_',num2str(length(chosen_mice)),'_datasets.pdf')], 'ContentType', 'vector');
    
    saveas(98,strcat('mod_index_boxplot_across_celltypes_',num2str(length(chosen_mice)),'_datasets.svg'));
    saveas(98,strcat('mod_index_boxplot_across_celltypes_',num2str(length(chosen_mice)),'_datasets.fig'));
    exportgraphics(figure(98),strcat('mod_index_boxplot_across_celltypes_',num2str(length(chosen_mice)),'_datasets.pdf'), 'ContentType', 'vector');

    
    save('mod_index_contexts_distribution_stats','stats')
end
