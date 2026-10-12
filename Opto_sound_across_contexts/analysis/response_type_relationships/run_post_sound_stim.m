% 4) FUNCTIONAL TYPE PLOTS - POST RESPONSES

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'both','opto','sound'},[1:24],plot_info, 1);
[~,~] = wrapper_scatter_index_contexts([],avg_responses.avg_ctrl_post, avg_responses.diff_stim, pooled_cell_types, plot_info, savepath_fig2, 'Post (Sound)', 'Post (Δ Stim)',0,0,[-1,2]);

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both'},[1:24],plot_info, 1);
[~,~] = wrapper_plot_corr_means([],pooled_cell_types, avg_responses.avg_ctrl_post, avg_responses.diff_stim, avg_responses.avg_post, savepath_fig2, plot_info, [-.5,.5], 'Corr (Sound vs Δ Stim)', [1:24], [1:3]) %1:4 is functional subtimes from pooled
%%
savepath_fig2 = ['W:\Connie\results\Bassi2025\fig3\reviews\avg_post_sound_and_stim'];
[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'both','opto','sound'},[1:24],plot_info, 1);
updated_pooled_cell_types = {};
for d = 1:24
    updated_pooled_cell_types{1, d}.opto = pooled_cell_types{1, d}.opto;
end
plot_info.colors_celltypes = [1.0000    0.7000         0];
[~,~] = wrapper_scatter_index_contexts([],avg_responses.avg_post(:,1), avg_responses.avg_post(:,2), updated_pooled_cell_types, plot_info, savepath_fig2, 'Active Post (Sound+Stim)', 'Passive Post (Sound+Stim)',0,1,[-.1,2.2]);

% index_to_plot{dataset,context,celltype}
cdf_data = {};%squeeze(corr_results_across_ctx.data_datasets(:,:,1:3,3));%using all cell types (4th # 1 = sound,2 sound+3, 3 delta stim)
cdf_data(:,1,1) = avg_responses.avg_post(:,1);
cdf_data(:,2,1) = avg_responses.avg_post(:,2);
plot_info.colors =  [1.0000    0.7000         0];
plot_info.lineStyles_contexts = {'-',':'}
plot_cdf_celltypes(savepath_fig2, cdf_data, 1:24, plot_info,'Post ΔF/F (Sound+Stim)',[0,0.25],0); %Δ Stim

[postavg_index_by_dataset,~] = unpack_modindexm(avg_responses.avg_post,[],updated_pooled_cell_types,[1:24]);
params.plot_info = plot_info;
preavg_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(savepath_fig2, postavg_index_by_dataset, [1:24],...
          params.plot_info, [.075,.4],0,'Post Mean (\DeltaF/F)');

% [pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both'},[1:24],plot_info, 1);
% [~,~] = wrapper_plot_corr_means([],pooled_cell_types, avg_responses.avg_ctrl_post, avg_responses.diff_stim, avg_responses.avg_post, savepath_fig2, plot_info, [-.5,.5], 'Corr (Sound vs Δ Stim)', [1:24], [1:3]) %1:4 is functional subtimes from pooled
