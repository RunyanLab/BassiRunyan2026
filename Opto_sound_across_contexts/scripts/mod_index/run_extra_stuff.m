contexts_to_compare = [1,2];
overlap_labels = {'Active', 'Passive','Both'}; %{'Active', 'Passive','Both'}; % {'Active', 'Passive','Both'}; %{'Active', 'Passive','Spont','Both'}; %
%% engagement session LME
plot_info.type = 'engagement'; %'sound'
savepath_fig3 = ['W:\Connie\results\Bassi2025\fig3_nature\reviews\'];
params.info.chosen_mice = [1:24];

[pooled_cell_types,plot_info.pooled_names,plot_info.pooled_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);
plot_info.pooled_names = {'Sound','Photostim','S & P','Unmodulated'}
plot_info.trace_ylims = [0.16,0.22];
% [~,~] = wrapper_avg_pooled_type_traces(context_data.dff,pooled_cell_types,[],[1:24],savepath_fig3,'sound_dff_functional_types_-2to0_',plot_info,[1:10]);

[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);
plot_info.colors_celltypes = [0.3000    0.2000    0.6000
    1.0000    0.7000         0
    0.3,0.8,1
    0.5000    0.5000    0.5000];
[preavg_index_by_dataset,~] = unpack_modindexm(avg_responses.avg_pre,[],pooled_cell_types,[1:24]);
params.plot_info = plot_info;
preavg_stats_celltypes_dataset = plot_connected_abs_mod_by_mouse(savepath_fig3, preavg_index_by_dataset, [params.info.mouseid{1:24}],...
          params.plot_info, [.075,.4],0,'Pre Mean (\DeltaF/F)');

params.plot_info.cdf_colors= [
    0.30 0.20 0.60
    0.72 0.68 0.84
    1.00 0.70 0.00
    1.00 0.88 0.60
    0.30 0.80 1.00
    0.72 0.92 1.00
    0.00 0.00 0.00
    0.70 0.70 0.70
    0.20 0.00 0.60
    0.62 0.58 0.84
];
params.plot_info.colors_celltypes = plot_info.colors_celltypes;
params.string = 'Pre Mean (\DeltaF/F)';
%single neuron stats
mod_index_stats_pre= plot_context_comparisons(contexts_to_compare,{overlap_labels{1:2}}, avg_responses.avg_pre, [],pooled_cell_types, params,savepath_fig3);
save(fullfile([savepath_fig3, 'single_neuron_stats_pre.mat']),'mod_index_stats_pre');
table_fig_single_cells = struct2table_recursive(mod_index_stats_pre,'single_cells_sound',{'bootstat'});
save(fullfile(savepath_fig3, strcat('table_fig_single_cells.mat')), 'table_fig_single_cells');
writetable(table_fig_single_cells, fullfile(savepath_fig3, strcat('table_fig_single_cells.csv')));


%% single neuron plots/stats
save_dir = ['W:\Connie\results\Bassi2025\fig2_nature\reviews\'];
% Pool all neurons

params.plot_info.cdf_colors= [
            0.16 0.40 0.24
            0.54 0.82 0.64
            0.13 0.24 0.51
            0.55 0.65 0.89
            0.50 0.06 0.10
            0.92 0.36 0.41
        ];
%PHOTOSTIM

params.string = '|Modulation Index|';
params.info.chosen_mice = [1:24];
mod_index_stats_stim = plot_context_comparisons(contexts_to_compare,{overlap_labels{1:2}}, opto.mod, opto.sig_cells, all_celltypes, params,save_dir);
save(fullfile([save_dir, 'single_neuron_stats_photostim.mat']),'mod_index_stats_stim');
params.info.chosen_mice = [1:25];
mod_index_stats = plot_context_comparisons(contexts_to_compare,{overlap_labels{1:2}}, sound.mod, sound.sig_cells', all_celltypes, params,save_dir);
save(fullfile([save_dir, 'single_neuron_stats_sounds.mat']),'mod_index_stats');

%save stats into table
table_1 = struct2table_recursive(mod_index_stats_stim,'single_cells_stim',{'bootstat'});
table_2 = struct2table_recursive(mod_index_stats,'single_cells_sound',{'bootstat'});
table_fig2_single_cells = [table_1; table_2];
save(fullfile(save_dir, strcat('table_fig2_single_cells.mat')), 'table_fig2_single_cells');
writetable(table_fig2_single_cells, fullfile(save_dir, strcat('table_fig2_single_cells.csv')));
%% stim+ sound responses (similar to model...)



