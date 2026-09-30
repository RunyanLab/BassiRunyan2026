function [spike_trial_cel_mouse,spike_context_celltype] = calc_avg_rate_across_context_celltype_choosetrials(deconv_response,frame_window,stim_trials,ctrl_trials)


for context = 1:size(deconv_response,1) 
    stim_mean =[];
    ctrl_mean =[];

    for mouse = 1:size(deconv_response,2)
        mean_across_cells = [];
        mean_across_cells_ctrl =[];
        t = 0; 

        % Determine number of cell types for this dataset
        if size(deconv_response{context,mouse}, 2) == 1
            num_celtypes = 1;
        else
            num_celtypes = size(deconv_response{context,mouse}, 2);
        end

        for celtype = 1:num_celtypes%size(deconv_response,3)
            if ~isempty(deconv_response{1,mouse,1}.stim) && size(deconv_response{context,mouse,celtype}.stim,2) > 0

                for trial = 1:length(stim_trials{1,mouse}{1,context});%1:size(deconv_response{context,mouse,celtype}.stim,1)
                    t = trial; %stim_trials{1,mouse}{1,context}(trial);
                    for cel = 1:size(deconv_response{context,mouse,celtype}.stim,2)
                        mean_across_cells(trial,cel) = mean(deconv_response{context,mouse,celtype}.stim(t,cel,frame_window));
                    end
                end
                t = 0;
                if ~isempty(deconv_response{1,mouse,1}.ctrl) && size(deconv_response{context,mouse,celtype}.ctrl,2) > 0
                    for trial = 1:length(ctrl_trials{1,mouse}{1,context});% 1:size(deconv_response{context,mouse,celtype}.ctrl,1)
                        t = trial; %ctrl_trials{1,mouse}{1,context}(trial);
                        for cel = 1:size(deconv_response{context,mouse,celtype}.ctrl,2)
                            mean_across_cells_ctrl(trial,cel) = mean(deconv_response{context,mouse,celtype}.ctrl(t,cel,frame_window));
                        end
                    end
                end
            end
            spike_trial_cel_mouse{context,mouse,celtype}.stim = mean_across_cells;
            spike_trial_cel_mouse{context,mouse,celtype}.stim_avg = mean(mean_across_cells,1); %mean across trials, gives cells
            spike_trial_cel_mouse{context,mouse,celtype}.ctrl = mean_across_cells_ctrl;
            spike_trial_cel_mouse{context,mouse,celtype}.ctrl_avg = mean(mean_across_cells_ctrl,1); %mean across trials, gives cells
            stim_mean = [stim_mean,spike_trial_cel_mouse{context,mouse,celtype}.stim_avg];
            ctrl_mean = [ctrl_mean,spike_trial_cel_mouse{context,mouse,celtype}.ctrl_avg];
            
        end
        spike_context_celltype{context,celtype}.stim = stim_mean;
        spike_context_celltype{context,celtype}.ctrl = ctrl_mean;
    end
end
