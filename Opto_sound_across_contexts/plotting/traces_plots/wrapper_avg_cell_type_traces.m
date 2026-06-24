function [traces_mean,dataset_ids] = wrapper_avg_cell_type_traces(context_data,all_celltypes,mod_indexm,sig_mod_boot,mod_params,savepath,data_type,plot_info,varargin)

    %% ---------------- Parse varargin ----------------
    param_sets = {};   % default empty → use internal defaults

    for v = 1:length(varargin)-1
        key = varargin{v};
        if isstring(key) || ischar(key)
            switch lower(varargin{v})
                case 'param_sets'
                    param_sets = varargin{v+1};
            end
        end
    end

    %% ---------------- Default parameter sets ----------------
    if isempty(param_sets)
        param_sets = { ...
            struct('mod_threshold',  mod_params.mod_threshold, ...
                   'threshold_single_side', 1, ...
                   'savestring', 'positive_modulated', ...
                   'chosen_mice', mod_params.chosen_mice), ...
            struct('mod_threshold', -mod_params.mod_threshold, ...
                   'threshold_single_side', 1, ...
                   'savestring', 'negative_modulated', ...
                   'chosen_mice', mod_params.chosen_mice), ...
            struct('mod_threshold',  mod_params.mod_threshold, ...
                   'threshold_single_side', 0, ...
                   'savestring', 'all_modulated', ...
                   'chosen_mice', mod_params.chosen_mice)
        };
    end
    min_cells = mod_params.min_cells;

results = mod_params.results;
for i = 1:length(param_sets)
        mod_params = param_sets{i};
        mod_params.results = results;
%         mod_params.chosen_mice = mod_params.chosen_mice;

        %get the significant neurons (positive, negative, both);
        if contains(data_type, 'sound')
            mod_params.data_type = 'sounds';
            %separate sig cells based on threshold (and single side or not)
            [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params, mod_indexm, sig_mod_boot);
            sig_cells = get_significant_neurons(current_sig_cells, mod_indexm, 'union'); %union of active and passive
        elseif contains(data_type, 'opto')
            mod_params.data_type = 'opto';
            mod_indexm2 = varargin{1,1};
            %separate sig cells based on threshold (and single side or not)
            [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params, mod_indexm2, sig_mod_boot); %using mod_indexm2 because using prepost instead of ctrl for opto
            sig_cells = get_significant_neurons(current_sig_cells, mod_indexm2, 'spont');
        elseif contains(data_type, 'top') || contains(data_type, 'intersect')
            mod_params.data_type = 'top_sounds';
            [current_sig_cells] = get_thresholded_sig_cells_simple( mod_params, mod_indexm, sig_mod_boot');
            sig_cells = current_sig_cells;
        end 
        
        %get context,mouse,celltype responses (across all trials (not
        %separated by left or rigth)- so overall avg)
        [neural_response,chosen_cells] = unpack_context_mouse_celltypes(context_data,sig_cells,all_celltypes,min_cells, mod_params.chosen_mice); %context_data.deconv_interp

        %plot avg traces (plotting active and passive)
            avg_across_neurons = 0; %SEM across all neurons vs across datasets
        contexts_to_plot = [1,2]; %

        %plot can include baseline subtraction but right now took it out
        plot_info.trace_modes = {'raw'}; %{'raw', 'bs'}
        [traces_mean{i},dataset_ids{i}] = plot_avg_traces_baseline_subtracted(neural_response(contexts_to_plot,:,:),plot_info.colors_celltypes_3contexts,{'-','-'},plot_info.celltype_names,1:122,[60,63],savepath,avg_across_neurons,[data_type '_' mod_params.savestring ],plot_info);
%         plot_avg_traces_baseline_subtracted_nosem(neural_response(contexts_to_plot,:,:),plot_info.colors_celltypes_4contexts,{'-','--'},plot_info.celltype_names,1:122,[60,63],savepath,avg_across_neurons,[data_type '_' mod_params.savestring ],plot_info);
        

        %separate into left and right side trials
                %separate into left and right side trials
%         neural_response_sided = get_side_trials_neural_response(neural_response,mod_params,chosen_cells);
% 
%         %plot max side (found for each neuron)
%         plot_avg_traces_baseline_subtracted(squeeze(neural_response_sided(3,contexts_to_plot,:,:)) ,plot_info.colors_celltypes_3contexts,{'-','-'},plot_info.celltype_names,1:122,[60,63],[savepath '/max_side/'],avg_across_neurons,[data_type '_' mod_params.savestring ],plot_info);
% 
%         %repeat and separate into sided!
%         sides = {'Left','Right'};
%         for side = 1:2 %1 = left, 2 = right
%             if ~isempty(savepath)
%                 savepath_updated = fullfile(savepath,sides{side},'\');
%             else
%                 savepath_updated = [];
%             end
%            neural_data_to_plot = squeeze(neural_response_sided(side,contexts_to_plot,:,:));
%            plot_avg_traces_baseline_subtracted(neural_data_to_plot ,plot_info.colors_celltypes_3contexts,{'-','-'},plot_info.celltype_names,1:122,[60,63],savepath_updated,avg_across_neurons,[data_type '_' mod_params.savestring ],plot_info);
%         end
% %         %avg over nuerons
% %         avg_across_neurons = 1;
% %         [traces_mean{i},dataset_ids{i}] = plot_avg_traces_baseline_subtracted(neural_response(contexts_to_plot,:,:),plot_info.colors_celltypes_3contexts,{'-','-'},plot_info.celltype_names,1:122,[60,63],savepath,avg_across_neurons,[data_type '_' mod_params.savestring ],plot_info);

end
