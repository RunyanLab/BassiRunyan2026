function wrapper_plot_svm_acc_trace_all_datasets(svm_mat, mdl_param, save_string,savepath, ylims,svm_mat2,event_onsets,stim_ctrl_labels)
%create time series plots of svm accuracy across celltypes    
input_param{1,1}{1} = mdl_param;
plot_info = default_plot_info(input_param);
plot_info.event_onsets =  event_onsets;

plot_info.labels = {'Pyr','SOM','PV','All','Top'}; %{'Active'};

    if ~isempty(svm_mat2)
        bins_to_include = 32;
        plot_info.xlims = [1,bins_to_include];
        plot_svm_across_datasets(svm_mat2,plot_info,plot_info.event_onsets,mdl_param,[save_string '_passive'],savepath,ylims,bins_to_include);
        movegui(gcf,'center');%

        plot_svm_across_datasets(svm_mat,plot_info,plot_info.event_onsets,mdl_param,[save_string],savepath,ylims,bins_to_include);
        movegui(gcf,'center');%
    else
        bins_to_include = 55;
        plot_info.xlims = [1,bins_to_include];
        if size(svm_mat,2) == 3
            plot_info.labels = {'Pyr','SOM','PV','Shuff'};
        end
        
        plot_svm_across_datasets(svm_mat,plot_info,plot_info.event_onsets,mdl_param,[save_string],savepath,ylims,bins_to_include);
        movegui(gcf,'center');%
    end
end

