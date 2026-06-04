function updated_context_data = update_context_info(context_data)

% LOAD TRIAL INFO
all_trial_info = load('W:\Connie\results\Bassi2025\fig3\sound_info\active_all_trial_info.mat').all_trial_info;
all_trial_info_pass = load('W:\Connie\results\Bassi2025\fig3\sound_info\passive_all_trial_info.mat').all_trial_info;

% initialize as copy
updated_context_data = context_data;

nDatasets = size(context_data.dff, 2);

for current_dataset = 1:nDatasets

    active_trials = 1:length(all_trial_info(current_dataset).ctrl);
    passive_trials = 1:length(all_trial_info_pass(current_dataset).ctrl);

    for context = 1:2

        if context == 1
            idx = active_trials;
        else
            idx = passive_trials;
        end

        updated_context_data.dff{context,current_dataset}.ctrl = ...
            context_data.dff{context,current_dataset}.ctrl(idx,:,:);

        updated_context_data.deconv{context,current_dataset}.ctrl = ...
            context_data.deconv{context,current_dataset}.ctrl(idx,:,:);

    end
end

end