function all_stats = generate_mod_index_plots_datasets(chosen_dataset, mod_index, sig_mod_boot_thr, all_celltypes, params, save_dir,varargin)
    % Generate all modulation index plots separated by dataset/mice
%     if ~isempty(sig_mod_boot_thr) && size(sig_mod_boot,2) > 1
%         % Here we assume union_sig_cells is a function that returns, for each dataset,
%         % the union of significant cell indices (based on p-values <= 0.05) from contexts 1 and 2.
%         % We replace mod_indexm with mod_index.
%         [combined_sig_cells, ~] = union_sig_cells(sig_mod_boot(:,1)', sig_mod_boot(:,2)', mod_index);
%     %     [combined_sig_cells, ~] = intersect_sig_cells(sig_mod_boot(:,1)', sig_mod_boot(:,2)', mod_index);
%     elseif ~isempty(sig_mod_boot)
%         combined_sig_cells = sig_mod_boot;
%     end

    %save all stats
    all_stats = {};

    if nargin > 6
        heatmap_ylims = varargin{1,1};
    else
        heatmap_ylims = [-.4,.4];
    end

    %unpack mod index across datasets
    [mod_index_by_dataset,~] = unpack_modindexm(mod_index,sig_mod_boot_thr,all_celltypes,chosen_dataset,params.min_cells);

    [context_mod_all, ~, ~, ~, ~] = organize_sig_mod_index_contexts_celltypes(...
        chosen_dataset, mod_index, sig_mod_boot_thr', all_celltypes,params.plot_info.celltype_names);
    mod_index_heatmap(save_dir, context_mod_all, params.plot_info, ...
        chosen_dataset, heatmap_ylims,[5,.5]);
        
    %     % Violin and Box plots (non abs) - can result in values closer to
    %     zero because we are taking means across + and - mod indices
    [all_stats.box_stats_datasets] = mod_index_violin_across_celltypes_datasets(save_dir, mod_index_by_dataset, params.plot_info, (params.plot_info.y_lims));

    y_lim_ratio = 1;
%     % Scatter Plot of abs(mod index)
%     scatter_abs_mean_mod_by_dataset(save_dir, mod_index_by_dataset,...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio]);

     % create plots dividing by dataset and by mouse
     %plots commented out are bigger than for manuscript
%      %by mouse
%      scatter_abs_mean_mod_by_mouse(save_dir, mod_index_by_dataset, [params.info.mouseid{chosen_dataset}],...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio]);
% 
%      %by dataset
%      scatter_abs_mean_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
%          params.plot_info, 2, [0,params.plot_info.y_lims(2)/y_lim_ratio]);

     %by mouse
      all_stats.abs_mod_stats_celltypes_mice = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, [params.info.mouseid{chosen_dataset}],...
          params.plot_info, [0,params.plot_info.y_lims(2)/y_lim_ratio]);

      %by dataset
      all_stats.abs_mod_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
          params.plot_info, [0,params.plot_info.y_lims(2)/y_lim_ratio]);

%             %by dataset
%       all_stats.abs_mod_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(save_dir, mod_index_by_dataset, chosen_dataset,...
%           params.plot_info, [-params.plot_info.y_lims(2),params.plot_info.y_lims(2)],0);

end