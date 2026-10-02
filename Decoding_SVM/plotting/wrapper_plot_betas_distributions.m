function wrapper_plot_betas_distributions(info,bin_id,beta_mat,all_celltypes,mdl_param,onset_id,save_path,beta_mat_pass,varargin)

% Parse optional inputs
p = inputParser;

addParameter(p,'celltype_ids',1:3);
addParameter(p,'labels',{'Pyr','SOM','PV','All','Top Pyr'});

parse(p,varargin{:});

celltype_ids = p.Results.celltype_ids;
labels = p.Results.labels;

% Plot info
input_param{1,1}{1} = mdl_param;
plot_info = default_plot_info(input_param);
plot_info.labels = labels;

for offset = bin_id

    plot_dist_weights(offset, beta_mat, all_celltypes, ...
        plot_info, mdl_param, info, celltype_ids, save_path);

    if ~isempty(beta_mat_pass)
        plot_dist_weights(offset, beta_mat_pass, all_celltypes, ...
            plot_info, mdl_param, onset_id, save_path, '_passive');
    end

end

end