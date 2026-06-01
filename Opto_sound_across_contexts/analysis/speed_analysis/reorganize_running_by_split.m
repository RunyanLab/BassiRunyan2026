function [running_split, running_split_ctrl] = reorganize_running_by_split( ...
    mouse_vel_context, axis_results)

nDatasets = size(mouse_vel_context,1);
nContexts = 2; % context 1 = active, context 2 = passive
nSplits = size(axis_results.stim_split_trials,1);

running_split = cell(nSplits, nDatasets, nContexts);
running_split_ctrl = cell(nSplits, nDatasets, nContexts);

for dataset = 1:nDatasets
dataset
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ACTIVE TRIAL COUNT (GLOBAL INDEX BREAKPOINT)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    nActive = size(mouse_vel_context{dataset,1}.stim,1);
    nActivectrl = size(mouse_vel_context{dataset,1}.ctrl,1);

    for context = 1:nContexts
        stim_all = mouse_vel_context{dataset,context}.stim;
        ctrl_all = mouse_vel_context{dataset,context}.ctrl;

        for split = 1:nSplits
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % GLOBAL INDICES (ACTIVE + PASSIVE CONCATENATED)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            stim_idx = axis_results.stim_split_trials{split,dataset};
            ctrl_idx = axis_results.ctrl_split_trials{split,dataset};

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % SEPARATE BY CONTEXT (NO RECOMBINATION)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if context == 1
                % ACTIVE CONTEXT ONLY

                stim_ctx_idx = stim_idx(stim_idx <= nActive);
                ctrl_ctx_idx = ctrl_idx(ctrl_idx <= nActivectrl);

            else
                % PASSIVE CONTEXT ONLY (shift indices)

                stim_ctx_idx = stim_idx(stim_idx > nActive) - nActive;
                ctrl_ctx_idx = ctrl_idx(ctrl_idx > nActivectrl) - nActivectrl;
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ASSIGN
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            running_split{split,dataset,context} = ...
                stim_all(stim_ctx_idx,:);

            running_split_ctrl{split,dataset,context} = ...
                ctrl_all(ctrl_ctx_idx,:);
        end
    end
end
% function [running_split,running_split_ctrl] = reorganize_running_by_split( ...
%     mouse_vel_context, axis_results)
% 
% nDatasets = size(mouse_vel_context,1);
% nContexts = 2;%size(mouse_vel_context,2);
% nSplits = size(axis_results.stim_split_trials,1);
% 
% running_split = cell(nSplits, nDatasets);
% running_split_ctrl = cell(nSplits, nDatasets);
% for dataset = 1:nDatasets
%     dataset
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % CONCATENATE ACROSS CONTEXTS FIRST
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%     stim_all = [];
%     ctrl_all = [];
% 
%     for context = 1:nContexts
%         stim_all = [stim_all;mouse_vel_context{dataset,context}.stim];
% 
%         ctrl_all = [ctrl_all;mouse_vel_context{dataset,context}.ctrl];
% 
% %         stim_all = [stim_all;
% %             mean(mouse_vel_context{dataset,context}.stim, 2, 'omitnan')];
% % 
% %         ctrl_all = [ctrl_all;
% %             mean(mouse_vel_context{dataset,context}.ctrl, 2, 'omitnan')];
% 
%     end
% 
%     % initialize output
%     for split = 1:nSplits
%         running_split{split,dataset} = [];
%         running_split_ctrl{split,dataset} = [];
%     end
% 
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % ASSIGN USING GLOBAL INDICES
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%     for split = 1:nSplits
%         stim_idx = axis_results.stim_split_trials{split,dataset};
%         ctrl_idx = axis_results.ctrl_split_trials{split,dataset};
% 
%         running_split{split,dataset} = [stim_all(stim_idx,:)];
% 
%         running_split_ctrl{split,dataset} = [
%             ctrl_all(ctrl_idx,:)];
% 
%     end
% end