function [spike_context_matrix,spike_context_matrix_ctrl] = into_mod_structure(spike_trial_cel_mouse,all_celltypes)
spike_context_matrix = cell(size(spike_trial_cel_mouse, 2), size(spike_trial_cel_mouse, 1));       % [mouse x context]
spike_context_matrix_ctrl = cell(size(spike_trial_cel_mouse, 2), size(spike_trial_cel_mouse, 1));  % same size
fieldss = fields(spike_trial_cel_mouse{1,1,1});
if ismember('stim_avg',fieldss)
    fieldss = {'stim_avg','ctrl_avg'};
end

celltype_fields = fieldnames(all_celltypes{1});
for mouse = 1:size(spike_trial_cel_mouse, 2)
    for context = 1:size(spike_trial_cel_mouse, 1)
        % Get all original neuron indices
        all_ids = [];
        for i = 1:numel(celltype_fields)
            all_ids = [all_ids; all_celltypes{mouse}.(celltype_fields{i})];
        end
        
        neuron_count = max(all_ids);

        % Initialize arrays with NaNs to preserve indexing
        stim_vector = nan(1, neuron_count);
        ctrl_vector = nan(1, neuron_count);

        for celtype = 1:numel(celltype_fields)
            field = celltype_fields{celtype};
            ids = all_celltypes{mouse}.(field);

            stim = spike_trial_cel_mouse{context, mouse, celtype}.(fieldss{1});  % [1 x N]- AVERAGE ACROSS TRIALS
            ctrl = spike_trial_cel_mouse{context, mouse, celtype}.(fieldss{2}); 

            for i = 1:length(ids)
                stim_vector(ids(i)) = stim(i);
                ctrl_vector(ids(i)) = ctrl(i);
            end
        end

        % Assign ordered vectors
        spike_context_matrix{mouse, context} = stim_vector;
        spike_context_matrix_ctrl{mouse, context} = ctrl_vector;
    end
end

