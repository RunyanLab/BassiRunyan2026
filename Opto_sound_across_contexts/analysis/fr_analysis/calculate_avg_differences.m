function [diff_stim, diff_pre_stim, diff_pre_ctrl, diff_sounds,diff_sounds_post] = calculate_avg_differences(dff_context_matrix_stim,dff_context_matrix_ctrl,dff_context_matrix_stim_post,dff_context_matrix_ctrl_post)

%find stim differences stim+sound - sound
%find pre stim differences active - passive
diff_stim = cell(size(dff_context_matrix_stim,1),2);
diff_sounds = cell(size(dff_context_matrix_stim,1),2);
diff_sounds_post = cell(size(dff_context_matrix_stim,1),2);

diff_pre_stim = cell(size(dff_context_matrix_stim,1),1);
diff_pre_ctrl = cell(size(dff_context_matrix_stim,1),1);

for current_dataset = 1:size(dff_context_matrix_stim,1)
    %photostim difference
    diff_stim{current_dataset,1} = dff_context_matrix_stim_post{current_dataset,1} - dff_context_matrix_ctrl_post{current_dataset,1}; %stim +sound - sound (active)
    diff_stim{current_dataset,2} = dff_context_matrix_stim_post{current_dataset,2} - dff_context_matrix_ctrl_post{current_dataset,2};%stim +sound - sound (passive)

    %do pre stim difference
    diff_pre_stim{current_dataset,1} = dff_context_matrix_stim{current_dataset,1} -dff_context_matrix_stim{current_dataset,2}; %pre (active) - pre (passive)
    diff_pre_ctrl{current_dataset,1} = dff_context_matrix_ctrl{current_dataset,1} -dff_context_matrix_ctrl{current_dataset,2}; %pre (active) - pre (passive)

    %sound difference
    diff_sounds{current_dataset,1} = dff_context_matrix_ctrl_post{current_dataset,1} - dff_context_matrix_ctrl{current_dataset,1}; %sound post - sound pre (active)
    diff_sounds{current_dataset,2} = dff_context_matrix_ctrl_post{current_dataset,2} - dff_context_matrix_ctrl{current_dataset,2}; %sound post - sound pre (passive)

    %do post difference
    diff_sounds_post{current_dataset,1} = dff_context_matrix_ctrl_post{current_dataset,1} - dff_context_matrix_ctrl_post{current_dataset,2}; %sound post (Active) - sound post (Passive)

end