function [sig_mod_boot_thr,switching_cells] = get_thresholded_sig_cells_simple(mod_params, mod_indexm, sig_mod_boot)
% plot_pie_thresholded_mod_index organizes modulation indices across contexts, applies a threshold,
% and produces plots. It then saves the thresholded significant modulation indices.
%
%   Inputs:
%     mod_params    - Structure with modulation parameters, such as:
%                     .mod_type       - (e.g., 'influence', 'ctrl', or 'prepost')
%                     .mod_threshold  - Numeric threshold to apply to the modulation index (0 means no threshold)
%                     .chosen_mice    - Vector of dataset indices to include (e.g., 1:24)
%                     .current_context- (Will be updated within the function; see below)
%     mod_indexm    - Cell array of modulation indices, organized as {dataset x context}.
%                     For example, mod_indexm{m, context} is a vector of modulation indices for dataset m.
%     sig_mod_boot  - Cell array of significant cell indices (from bootstrap), {dataset x context}.
%
%   Output:
%     sig_mod_boot_thr - Cell array {dataset x context} containing the thresholded significant
%                        modulation indices (global indices).
%
%   The function does the following for each context:
%     1. Sets the current context (and threshold) in mod_params.
%     5. Applies the modulation threshold by keeping only those indices for which the modulation
%        index exceeds the threshold.
%
% Loop over each context (for example, context 1: active, 2: passive, 3: spontaneous).
numContexts = min(size(sig_mod_boot));
numDatasets = length(mod_params.chosen_mice);
switching_cells = cell(numDatasets, 1);
all_sig_cells = cell(numDatasets, 1);
all_signs = cell(numDatasets, numContexts); % will store sign for each neuron per context

for context = 1:numContexts
    context
    % Set current context and threshold parameters.
    mod_params.current_context = context;  % update current context
    % mod_params.mod_threshold should already be set (e.g., 0.1). If set to 0, no threshold is applied.

    % Extract the significant indices and the modulation indices for the current context.
    current_sig = sig_mod_boot(mod_params.chosen_mice, context);
    current_mod_index = mod_indexm(mod_params.chosen_mice, context);

    % Now, for each dataset, apply the modulation threshold.
    for dataset_index = 1:numDatasets
        %dataset_index = mod_params.chosen_mice(dataset_id);
        % Get the significant cell indices and the modulation indices for the current dataset.
        current_sig_single_dataset = current_sig{dataset_index, 1};  % local indices
        current_mod_index_single_dataset = current_mod_index{dataset_index, 1};

        % Apply the threshold: retain only those cells whose modulation index (for that dataset)
        % exceeds the threshold. (Assumes that higher modulation means more significant.)
        if mod_params.threshold_single_side == 1

            thr = mod_params.mod_threshold;

%             % --- POS / NEG (unified logic) ---
%             pos = current_mod_index_single_dataset >= thr;
%             neg = current_mod_index_single_dataset < thr;
%             all_signs{dataset_index, context} = pos - neg;    % +1 or -1
%             
%             % --- Significant positive values ---
%             sig_mod_boot_thr{dataset_index, context} = ...
%                 current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) >= thr );
            if ~isempty(current_mod_index_single_dataset)
                 if strcmpi('positive_modulated',mod_params.savestring)
                        if mod_params.mod_threshold >= 0
                            sig_mod_boot_thr{dataset_index, context} = [current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) > mod_params.mod_threshold )];
                            all_signs{dataset_index,context} = [current_mod_index_single_dataset > mod_params.mod_threshold;(current_mod_index_single_dataset < -mod_params.mod_threshold)*-1];
                        else
                            sig_mod_boot_thr{dataset_index, context} = [current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) < (mod_params.mod_threshold) )];
                            all_signs{dataset_index,context} = [(current_mod_index_single_dataset < mod_params.mod_threshold);(current_mod_index_single_dataset > -mod_params.mod_threshold)*-1];
                        end
                else
                    if mod_params.mod_threshold > 0
                        sig_mod_boot_thr{dataset_index, context} = [current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) > mod_params.mod_threshold )];
                        all_signs{dataset_index,context} = [current_mod_index_single_dataset > mod_params.mod_threshold;(current_mod_index_single_dataset < -mod_params.mod_threshold)*-1];
                    else
                        sig_mod_boot_thr{dataset_index, context} = [current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) < (mod_params.mod_threshold) )];
                        all_signs{dataset_index,context} = [(current_mod_index_single_dataset < mod_params.mod_threshold);(current_mod_index_single_dataset > -mod_params.mod_threshold)*-1];
                    end
                 end
            else
                sig_mod_boot_thr{dataset_index, context} = [];
            end

        else
            if ~isempty(current_mod_index_single_dataset)
                    sig_mod_boot_thr{dataset_index, context} = [current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) > mod_params.mod_threshold ),...
            current_sig_single_dataset( current_mod_index_single_dataset(current_sig_single_dataset) < (mod_params.mod_threshold*-1) )];
                    all_signs{dataset_index,context} = [current_mod_index_single_dataset > mod_params.mod_threshold;(current_mod_index_single_dataset < -mod_params.mod_threshold)*-1];
            else
                sig_mod_boot_thr{dataset_index, context} = [];
            end
        end

        %all siginifncant neurons per dataset across all contexts accumualted
        all_sig_cells{dataset_index} = union(all_sig_cells{dataset_index},current_sig_single_dataset);
    end


end
% 
% % Identify and remove switching cells
if strcmp(mod_params.data_type,'sounds')
    %doing this for sounds since I consider active and passive
    for dataset_index = 1:numDatasets
        all_sigs = all_sig_cells{dataset_index}; % list of all sig neuron indices
        all_signs_across_contexts = vertcat(all_signs{dataset_index,:}); %array of 2*numcontexts x neurons
    
        sign_matrix = all_signs_across_contexts(:,all_sig_cells{dataset_index});
        %look at all sig cells to see if any have 1s AND -1s
        % A switching neuron has both +1 and -1 across contexts
        has_pos = any(sign_matrix == 1, 1);
        has_neg = any(sign_matrix == -1, 1);
        is_switching = has_pos & has_neg;
        switching_cells{dataset_index} = all_sigs(is_switching)'; % neuron indices that switch
    %     switching_cells{dataset_index} = all_signs_across_contexts(all_sigs) > 0 & all_signs_across_contexts(all_sigs) < 0 %find neurons that have both 1s and -1s across signs
    
        %eliminate switching cells from array if mode is single_side
        if mod_params.threshold_single_side == 1
            for context = 1:numContexts
                sig_list = sig_mod_boot_thr{dataset_index, context};
                % Remove any that are switching
                sig_mod_boot_thr{dataset_index, context} = setdiff(sig_list, switching_cells{dataset_index});
            end
        end
    end
else
    %skip if doing opto since I only consider one context so no need to
    %worry about double counting
    switching_cells = [];
end
% % Save the thresholded significance results.
% save(fullfile(mod_savepath, 'sig_mod_boot_thr.mat'), 'sig_mod_boot_thr');
end