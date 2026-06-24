%% compare relationships between EI and modulation index!


cd("W:\Connie\results\Bassi2025\data")
savepath_fig2 = ['W:\Connie\results\Bassi2025\fig3\engagement_vs_mod_index'];
% 1) LOAD THE DATA
load('plot_info.mat'); load('info.mat');load('all_celltypes.mat');
load('context_data.mat'); load('sound.mat'); load('opto.mat');load('avg_responses.mat'); load('axis_results.mat')
%from supplemental data
load('engagement.mat'); 
params = experiment_config(); 

%% plot relationships
savepath_fig2 = [];%['W:\Connie\results\Bassi2025\fig3\engagement_vs_mod_index'];
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional([], all_celltypes, [{sound.mod{:,1}}',{opto.mod{:,1}}'], plot_info, savepath_fig2, 'Active Sound', 'Active Opto',0,1,[-.6,2]);

%using significant engaged neurons
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes, [{engagement.mod{1,:}}',{opto.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'PMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes, [{engagement.mod{1,:}}',{opto.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'PMI (Passive)',0,2,[-1,1]);

%plot only PV
all_celltypes_updated ={};
for dataset = 1:size(all_celltypes,2)
    all_celltypes_updated{1,dataset}.pv_cells = all_celltypes{1,dataset}.pv_cells;
end
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes_updated, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes_updated, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);
%plot only SOM
all_celltypes_updated ={};
for dataset = 1:size(all_celltypes,2)
    all_celltypes_updated{1,dataset}.som_cells = all_celltypes{1,dataset}.som_cells;
end
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes_updated, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, all_celltypes_updated, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);

%%
%make scatter plots and save them!
[pooled_cell_types,plot_info.celltype_names,plot_info.colors_celltypes] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'unmodulated','sound','both','opto'},[1:24],plot_info, 1);
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'unmodulated','sound','both','opto'},[1:24],plot_info, 1);

[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);

[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'PMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'PMI (Passive)',0,2,[-1,1]);

%% separate sounds into plus and minus
mod_params.chosen_mice = 1:24;
mod_params.mod_threshold = 0.1;
param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'sounds';
        [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params_plot, sound.mod, sound.sig_mod_boot);
        sig_cells_sounds{i} = get_significant_neurons(current_sig_cells, engagement.mod, 'union'); %union of active and passive
end
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:24,:), {'sound','sound_neg','opto','both','unmodulated'},[1:24],plot_info, 1,sig_cells_sounds{2});

[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sig_cells_sounds{1}, opto.sig_cells, opto.mod(1:24,:), {'sound','sound_neg'},[1:24],plot_info, 1,sig_cells_sounds{2});

[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);

[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'PMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'PMI (Passive)',0,2,[-1,1]);


%just sound engaged neurons rpobably want to do the opposite here
% all_celltypes_updated ={};
% for dataset = 1:size(all_celltypes,2)
%     all_celltypes_updated{1,dataset}.som_cells = all_celltypes{1,dataset}.sound;
% end
cdf_data = unpack_modindexm(sound.mod,engagement.sig_mod_boot_thr,pooled_cell_types,[1:24]);
plot_info.colors= plot_info.functional_colors;
plot_info.lineStyles_contexts= {'-','--'};
plot_cdf_celltypes([], cdf_data, 1:24, plot_info,'SMI',[-1,1],0); %{dataset,context,celltype}

%% separate sounds into plus and minus based on engagement index!!!
mod_params.chosen_mice = 1:24;
mod_params.mod_threshold = 0.1;
param_sets = { 
    struct('mod_threshold', mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'positive_modulated'],'chosen_mice', mod_params.chosen_mice),
    struct('mod_threshold', -1 * mod_params.mod_threshold, 'threshold_single_side', 1, 'savestring', [ 'negative_modulated'],'chosen_mice', mod_params.chosen_mice),
};
for i = 1:length(param_sets)
        mod_params_plot = param_sets{i};
        mod_params_plot.data_type = 'sounds';
        sig_cells{i} = get_thresholded_sig_cells_simple( mod_params_plot, engagement.mod', engagement.sig_mod_boot');
end
[pooled_cell_types,plot_info.functional_names,plot_info.functional_colors] = organize_functional_groups(all_celltypes, sound.sig_cells, opto.sig_cells, opto.mod(1:24,:), {'sound','opto','both','unmodulated'},[1:24],plot_info, 1);

%check plus first
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'SMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{sound.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'SMI (Passive)',0,2,[-1,1]);

[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,1}}'], plot_info, savepath_fig2, 'EI', 'PMI (Active)',0,2,[-1,1]);
[modl_fit,~,~,stats1] = scatter_index_sigcells_histogram_optional(engagement.sig_mod_boot_thr, pooled_cell_types, [{engagement.mod{1,:}}',{opto.mod{:,2}}'], plot_info, savepath_fig2, 'EI', 'PMI (Passive)',0,2,[-1,1]);


%just sound engaged neurons rpobably want to do the opposite here
% all_celltypes_updated ={};
% for dataset = 1:size(all_celltypes,2)
%     all_celltypes_updated{1,dataset}.som_cells = all_celltypes{1,dataset}.sound;
% end
cdf_data = unpack_modindexm(sound.mod,sig_cells{2},pooled_cell_types,[1:24]);
plot_info.colors= plot_info.functional_colors;
plot_info.lineStyles_contexts= {'-','--'};
plot_cdf_celltypes([], cdf_data, 1:24, plot_info,'SMI',[-1,1],0); %{dataset,context,celltype}

%% across functional types
savepath_fig2 = ['W:\Connie\results\Bassi2025\fig3\engagement_vs_mod_index'];
plot_info.lineStyles_contexts= {'-','--'};
num_datasets = 1:24;
for index = 1:2
    if index == 1
        mod_index_to_use = sound.mod;
        index_string = 'SMI';
    else
        mod_index_to_use = opto.mod;
        index_string = 'PMI';
    end
    for signed_mod = 1:2
        fieldss = fields(pooled_cell_types{1,1});
            for fld = 1:length(fieldss)
            all_celltypes_updated = {}; 
                for dataset = num_datasets
                    all_celltypes_updated{1,dataset}.(fieldss{fld}) = pooled_cell_types{1,dataset}.(fieldss{fld});
                    plot_info.colors_updated = plot_info.functional_colors(fld,:);
                end
                cdf_data = unpack_modindexm(mod_index_to_use,sig_cells{signed_mod},all_celltypes_updated,num_datasets);
                plot_info.colors= plot_info.colors_updated;
            
                if signed_mod == 1
                    signed_string = 'positive_EI';
                else
                    signed_string = 'negative_EI';
                end
                plot_cdf_celltypes([savepath_fig2 '\' fieldss{fld} '_' signed_string] , cdf_data, 1:24, plot_info,index_string, [-1,1],0); %{dataset,context,celltype}
            end
    end
end

%% across cell types
savepath_fig2 = ['W:\Connie\results\Bassi2025\fig3\engagement_vs_mod_index'];
plot_info.lineStyles_contexts= {'-','--'};
num_datasets = 1:24;
for index = 1:2
    if index == 1
        mod_index_to_use = sound.mod;
        index_string = 'SMI';
    else
        mod_index_to_use = opto.mod;
        index_string = 'PMI';
    end
    for signed_mod = 1:2
        fieldss = fields(all_celltypes{1,1});
            for fld = 1:length(fieldss)
            all_celltypes_updated = {}; 
                for dataset = num_datasets
                    all_celltypes_updated{1,dataset}.(fieldss{fld}) = all_celltypes{1,dataset}.(fieldss{fld});
                    plot_info.colors_updated = plot_info.colors_celltype(fld,:);
                end
                cdf_data = unpack_modindexm(mod_index_to_use,sig_cells{signed_mod},all_celltypes_updated,num_datasets);
                plot_info.colors= plot_info.colors_updated;
            
                if signed_mod == 1
                    signed_string = 'positive_EI';
                else
                    signed_string = 'negative_EI';
                end
                plot_cdf_celltypes([savepath_fig2 '\' fieldss{fld} '_' signed_string] , cdf_data, 1:24, plot_info,index_string, [-1,1],0); %{dataset,context,celltype}
            end
    end
end
