function [num_cells, sorted_cells] = organize_pooled_celltypes(dff_st, all_celltypes)

num_cells = [];
sorted_cells = struct();

nDatasets = numel(dff_st);

% ---- find all cell type fields dynamically ----
all_fields = fieldnames(all_celltypes{1});
celltype_fields = all_fields(contains(all_fields, '_cells'));

% initialize containers (KEEP full field name)
for f = 1:numel(celltype_fields)
    sorted_cells.(celltype_fields{f}) = [];
end

% ---- loop over datasets ----
for dataset_index = 1:nDatasets

    % number of cells in dataset
    if isfield(dff_st{dataset_index}, 'stim')
        num_cells(dataset_index) = size(dff_st{dataset_index}.stim, 2);
    else
        tmp_sum = 0;
        for f = 1:numel(celltype_fields)
            tmp_sum = tmp_sum + numel(all_celltypes{dataset_index}.(celltype_fields{f}));
        end
        num_cells(dataset_index) = tmp_sum;
    end

    offset = sum(num_cells(1:dataset_index-1));

    % ---- loop over cell types ----
    for f = 1:numel(celltype_fields)

        field = celltype_fields{f};   % e.g. 'pyr_cells'

        if ~isfield(all_celltypes{dataset_index}, field) || ...
                isempty(all_celltypes{dataset_index}.(field))
            continue
        end

        idx = all_celltypes{dataset_index}.(field);

        % add offset indexing
        if dataset_index == 1
            sorted_cells.(field) = [sorted_cells.(field), idx];
        else
            sorted_cells.(field) = [sorted_cells.(field), idx + offset];
        end
    end
end

end
% %% organizing pv, mchery, pyr cells
% function [num_cells,sorted_cells,sorted_pv,sorted_som,sorted_pyr] = organize_pooled_celltypes(dff_st,all_celltypes)
% %organizes cell types to have indices relative to all pooled datasets
% 
% sorted_pv = [];
% sorted_som = [];
% sorted_pyr = [];
% num_cells = [];
% sorted_cells = {};
% %sorted_sig_cells_wilcoxon = [];
% 
% %get total cell nums per dataset
% all_data_cell_num = [cellfun(@(x) length(x.pyr_cells),all_celltypes,'UniformOutput',false);cellfun(@(x) length(x.som_cells),all_celltypes,'UniformOutput',false);cellfun(@(x) length(x.pv_cells),all_celltypes,'UniformOutput',false)];
% 
% 
% for dataset_index = 1:length(dff_st)
%     if isfield(all_celltypes, 'stim')
%         num_cells = [num_cells, size(dff_st{1,dataset_index}.stim,2)];
%     else
%         num_cells = [num_cells, sum([all_data_cell_num{:,dataset_index}])];
%     end
%     if dataset_index ==1
%         sorted_som = [sorted_som ; all_celltypes{1,dataset_index}.som_cells];
%         sorted_pyr = [sorted_pyr ; [all_celltypes{1,dataset_index}.pyr_cells]];
%         sorted_pv = [sorted_pv ; all_celltypes{1,dataset_index}.pv_cells];
%     else %add cellcount from previously to make sure they numbers make sense
%         temp = sum(num_cells(1:dataset_index-1));
%         sorted_som = [sorted_som ; (all_celltypes{1,dataset_index}.som_cells+temp)];
%         sorted_pv = [sorted_pv ; (all_celltypes{1,dataset_index}.pv_cells+temp)];
%         sorted_pyr = [sorted_pyr ; ([all_celltypes{1,dataset_index}.pyr_cells]+temp)];
%     end
% end
% sorted_cells.pyr = sorted_pyr;
% sorted_cells.som = sorted_som;
% sorted_cells.pv = sorted_pv;