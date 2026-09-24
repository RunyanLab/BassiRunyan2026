 [sound_mod, ~, ~, ~, ~] = organize_sig_mod_index_contexts_celltypes(...
        [1:25], sound.mod, sound.sig_mod_boot_thr, all_celltypes,params.plot_info.celltype_names);
 [stim_mod, ~, ~, ~, ~] = organize_sig_mod_index_contexts_celltypes(...
        [1:24], opto.mod, opto.sig_mod_boot_thr, all_celltypes,params.plot_info.celltype_names);

[~, ~, ~, ~, celltypes_ids,~] = ...
    organize_sig_mod_index_contexts_celltypes([1:25], sound.mod, sound.sig_mod_boot_thr, all_celltypes,{'Pyr','SOM','PV'});
[~, ~, ~, ~, celltypes_ids2,~] = ...
    organize_sig_mod_index_contexts_celltypes([1:24], opto.mod, opto.sig_mod_boot_thr, all_celltypes,{'Pyr','SOM','PV'});

%% plots
save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\neuron_level_plots\sound\'];
[stats] = mod_index_violin_across_celltypes(save_dir,abs(sound_mod),{'Active','Passive'},plot_info.colors_celltype  ,2,celltypes_ids,[1:25],[0,1])

save_dir = ['W:\Connie\results\Bassi2025\fig3\reviews\neuron_level_plots\opto\'];
[stats] = mod_index_violin_across_celltypes(save_dir,abs(stim_mod),{'Active','Passive'},plot_info.colors_celltype  ,2,celltypes_ids2,[1:24],[0,1])
