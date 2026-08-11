function [final_data_means,final_mouse_ids_used] = wrapper_avg_pooled_type_traces(context_data,all_celltypes,sig_cells,chosen_mice,savepath,data_type,plot_info,baseline,varargin)

p = inputParser;

addOptional(p,'contexts_to_plot',[1 2],@(x) isnumeric(x) && isvector(x));

parse(p,varargin{:});

contexts_to_plot = p.Results.contexts_to_plot;

% %get distinct pools
% sig_cells = [];

%get context,mouse,celltype responses (across all trials (not
%separated by left or rigth)- so overall avg)
min_cells = 0;
[neural_response,~] = unpack_context_mouse_celltypes(context_data,sig_cells,all_celltypes,min_cells,chosen_mice); %context_data.deconv_interp

%plot avg traces (plotting active and passive)
avg_across_neurons = 0; %SEM across all neurons vs across datasets

%plot can include baseline subtraction but right now took it out
plot_info.trace_modes = {'raw'}; %{'raw', 'bs'}
[final_data_means{1},final_mouse_ids_used{1}] = plot_avg_traces_baseline_subtracted(neural_response(contexts_to_plot,:,:),plot_info.colors_pooled_3contexts,{'-','-'},plot_info.pooled_names,1:122,[60,63],savepath,avg_across_neurons,[data_type num2str(baseline(1)) 'to' num2str(baseline(end))],plot_info,baseline);

% plot_avg_traces_zscored(neural_response(contexts_to_plot,:,:), plot_info.colors_pooled_3contexts,{'-','-'}, ...
%     plot_info.pooled_names,1:60,[60,63], savepath, [data_type num2str(baseline(1)) 'to' num2str(baseline(end))],plot_info);