function all_stats = generate_engagement_index_plots_datasets(chosen_dataset, mod_index, sig_mod_boot_thr, all_celltypes, params, save_dir,celltypes_ids,varargin)
    % Generate all modulation index plots separated by dataset/mice

    %save all stats
    all_stats = {};

    if nargin > 6
        heatmap_ylims = varargin{1,1};
    else
        heatmap_ylims = [-.4,.4];
    end

    %unpack mod index across datasets
    [mod_index_by_dataset,~] = unpack_modindexm(mod_index,sig_mod_boot_thr,all_celltypes,chosen_dataset);

    [context_mod_all, ~, ~, ~, celltypes_ids] = organize_sig_mod_index_contexts_celltypes(...
        chosen_dataset, mod_index, sig_mod_boot_thr, all_celltypes,params.plot_info.celltype_names);
    mod_index_heatmap(save_dir, context_mod_all, params.plot_info, ...
        chosen_dataset, heatmap_ylims);
        
    %     % Violin and Box plots (non abs) - can result in values closer to
    %     zero because we are taking means across + and - mod indices
    [all_stats.box_stats_datasets] = mod_index_violin_across_celltypes_datasets(save_dir, mod_index_by_dataset, params.plot_info, (params.plot_info.y_lims),1);
    if ~isempty(celltypes_ids)
        if size(celltypes_ids{2,1},2) > 1 && ismember('Photostim',{celltypes_ids{2,:}})
             celltypes_ids_updated = cellfun(@(x) ...
                [x; repmat({'modulated'}, ~any(strcmpi(x,"Unmodulated")), 1)], ...
                {celltypes_ids{2,:}}, 'UniformOutput', false);
             celltypes_ids(2,:) =  celltypes_ids_updated;
        end
        if size(celltypes_ids{2,1},2) > 1
            [all_stats.box_stats_allcells] = mod_index_violin_across_celltypes(save_dir,context_mod_all,1,params.plot_info.colors_celltypes,1,celltypes_ids,chosen_dataset);
        end
    end
    
    y_lim_ratio = 1;
    if isfield(params.plot_info,'y_lim_ratio')
        y_lim_ratio = params.plot_info.y_lim_ratio;
    end
%     % Scatter Plot of abs(mod index)
%     scatter_abs_mean_mod_by_dataset(save_dir, mod_index_by_dataset,...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio]);
% 
%      % create plots dividing by dataset and by mouse
%      %by mouse
%      scatter_abs_mean_mod_by_mouse(save_dir, mod_index_by_dataset, [params.info.mouseid{chosen_dataset}],...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio],1);

%      %by dataset
%      scatter_abs_mean_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio],1);

     %by mouse
      all_stats.abs_mod_stats_celltypes_mice = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, [params.info.mouseid{chosen_dataset}],...
          params.plot_info, [0,params.plot_info.y_lims(2)/y_lim_ratio]);

      %by dataset
      all_stats.abs_mod_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
          params.plot_info, [0,params.plot_info.y_lims(2)/y_lim_ratio],1,{'|Engagement Index|'});

      all_stats.abs_mod_stats_celltypes_dataset_no_abs = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
          params.plot_info, [-params.plot_info.y_lims(2)/y_lim_ratio,params.plot_info.y_lims(2)/y_lim_ratio],0,'Engagement Index'); %no abs

%             %by dataset
%       all_stats.abs_mod_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
%           params.plot_info, [-params.plot_info.y_lims(2),params.plot_info.y_lims(2)],0);

end