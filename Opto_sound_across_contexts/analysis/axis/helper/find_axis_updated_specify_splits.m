function [axis_results,proj,proj_ctrl,proj_norm,proj_ctrl_norm, weights,trial_corr_context,percent_correct,real_activity_all,real_activity_all_ctrl,real_activity_all_norm,percent_correct_concat,proj_concat,proj_concat_norm,engagement_concat,test_trials,test_trials_relative] = find_axis_updated_specify_splits(dff_st,choose_params, all_celltypes,sig_mod_boot,split_params,varargin)
        total_trials = {};
        possible_celltypes = fieldnames(all_celltypes{1,1});

        %LOAD VIRMEN TRIAL INFO
        all_trial_info = load('V:\Connie\results\opto_sound_2025\context\sound_info\active_all_trial_info_sounds.mat').all_trial_info_sounds; %all_trial_info
%         all_trial_info = load('W:\Connie\results\Bassi2025\fig3\sound_info\active_all_trial_info.mat').all_trial_info; %all_trial_info

        rng(5);
        bframes2 = [];
        % Define the frames for after and before stimulus
        if nargin > 5
            aframes = varargin{1,1}{2};  % After stimulus
            bframes = varargin{1,1}{1};   % Before stimulus
            if length(varargin{1,1})> 2
                bframes2 = varargin{1,1}{3}; %second frames to test
            end
        else
            aframes = 63:93;  % After stimulus
            bframes = 50:59;   % Before stimulus
        end

        %save test trials for other analysis
        test_trials = {};
        test_stim_trials_relative_to_alignment = {};
   
        %separate into folds
        divisions = split_params.divisions; %4;
        random_or_not = split_params.random_or_not; %0;
        splits = split_params.splits; %10;

        chosen_mice = choose_params.chosen_datasets;
        chosen_celltypes = choose_params.chosen_celltypes;
        for current_dataset = chosen_mice
            % Example: Randomly split trials into train (80%) and test (20%)
            total_trials_stim = [size(dff_st{1, current_dataset}.stim,1),size(dff_st{2, current_dataset}.stim,1)]; %get total # trials across contexts
            total_trials_ctrl = [size(dff_st{1, current_dataset}.ctrl,1),size(dff_st{2, current_dataset}.ctrl,1)]; %get total # trials across contexts

            [stim_splits_ds, ctrl_splits_ds, ~, ~] = make_cv_splits(total_trials_stim, total_trials_ctrl,splits,divisions,random_or_not);
            for ctx = 1:2
                stim_splits{current_dataset, ctx} = stim_splits_ds{ctx};
                ctrl_splits{current_dataset, ctx} = ctrl_splits_ds{ctx};
            end

        end

    proj = {}; proj_ctrl = {}; proj_norm = {}; proj_ctrl_norm = {};
    target = []; target_norm = [];

   for split = 1:splits
       split
        % Loop through the selected mice datasets
        for current_dataset = chosen_mice
            current_dataset

            % Combine across contexts if needed
            trainA_stim_all = [stim_splits{current_dataset,1}(split).trainA,stim_splits{current_dataset,2}(split).trainA];
            test_stim_all   = [stim_splits{current_dataset,1}(split).test,stim_splits{current_dataset,2}(split).test];
    
            trainA_ctrl_all = [ctrl_splits{current_dataset,1}(split).trainA,ctrl_splits{current_dataset,2}(split).trainA];
            test_ctrl_all   = [ctrl_splits{current_dataset,1}(split).test,ctrl_splits{current_dataset,2}(split).test];
    
    
            for celltype = chosen_celltypes
    
                if celltype == chosen_celltypes(end)
                    mod_cells = 1:size(dff_st{1, current_dataset}.stim,2);
                    if ~isempty(sig_mod_boot)
                        mod_cells = sig_mod_boot{current_dataset};
                    end
                else
                    mod_cells = all_celltypes{1,current_dataset}.(possible_celltypes{celltype});
                    if ~isempty(sig_mod_boot)
                        mod_cells = mod_cells(find(ismember(mod_cells,sig_mod_boot{ current_dataset})));
                    end
                end
                if isempty(mod_cells)
                    continue;
                end
                % Get the data for the stim and control contexts
                stim_matrix = [dff_st{1, current_dataset}.stim(:,mod_cells,:); dff_st{2, current_dataset}.stim(:,mod_cells,:)]; % stim + sound (active and passive)
                ctrl_matrix = [dff_st{1, current_dataset}.ctrl(:,mod_cells,:); dff_st{2, current_dataset}.ctrl(:,mod_cells,:)]; % sound only (active and passive)
                [~, n_neurons, frames] = size(stim_matrix);
    %             [trials_ctrl] = size(ctrl_matrix, 1);
        
                % --- 1) Calculate Sound Axis (pre-post sound) ---
                data_matrix = ctrl_matrix;  % Use the control matrix for the sound axis calculation
                prepost_trial = [];
                tr_ct = 0;
 
                for tr = trainA_ctrl_all;%train_trials_ctr %1:trials_ctrl
                    tr_ct = tr_ct +1;
                    prepost_trial(tr,:,:) = [nanmean(data_matrix(tr, :, aframes), [3]);
                                           nanmean(data_matrix(tr, :, bframes), [3])]; % [post, pre]
                end
                sound_diff = mean((squeeze(prepost_trial(:, 1,:))) -squeeze(prepost_trial(:, 2,:)),[1]);%mean((squeeze(prepost_trial(:, 1,:))));% -squeeze(prepost_trial(:, 2,:)),[1]); %difference size is neurons
                norm_sound_diff = sound_diff ./ sqrt(sum(sound_diff.^2)); % Normalize sound axis

                stim_matrix = [dff_st{1, current_dataset}.stim(:,mod_cells,:); dff_st{2, current_dataset}.stim(:,mod_cells,:)]; % stim + sound (active and passive)
                ctrl_matrix = [dff_st{1, current_dataset}.ctrl(:,mod_cells,:); dff_st{2, current_dataset}.ctrl(:,mod_cells,:)]; % sound only (active and passive)
                
                %calculate post and pre (not sure why)
                post_sound = mean((squeeze(prepost_trial(:, 1,:))),[1]);%mean((squeeze(prepost_trial(:, 1,:))));% -squeeze(prepost_trial(:, 2,:)),[1]); %difference size is neurons
                norm_sound_post = post_sound ./ sqrt(sum(post_sound.^2)); % Normalize sound axis
                pre_sound = mean(squeeze(prepost_trial(:, 2,:)),[1]);%mean((squeeze(prepost_trial(:, 1,:))));% -squeeze(prepost_trial(:, 2,:)),[1]); %difference size is neurons
                norm_sound_pre = pre_sound ./ sqrt(sum(pre_sound.^2)); % Normalize sound axis

                % --- 2) Calculate Stimulus + Sound Axis (stim + sound - sound) ---
                stim_sound_mean = mean(stim_matrix(trainA_stim_all,:, aframes), [1, 3]);
                sound_mean = mean(ctrl_matrix(trainA_ctrl_all, :, aframes), [1, 3]);
                stim_axis = stim_sound_mean - sound_mean; % Difference between stim + sound and sound
                norm_stim_diff = stim_axis ./ sqrt(sum(stim_axis.^2)); % Normalize stimulus axis
    
                %get just pre and post axis
                stim_post =  mean(stim_matrix(trainA_stim_all,:, aframes), [1, 3]) - mean(ctrl_matrix(trainA_ctrl_all, :, aframes), [1, 3]); %post response alone
                norm_stim_post = stim_post ./ sqrt(sum(stim_post.^2)); % Normalize sound axis
                stim_pre =  mean(stim_matrix(trainA_stim_all,:, bframes), [1, 3]) - mean(ctrl_matrix(trainA_ctrl_all, :, bframes), [1, 3]); %pre response alone
                norm_stim_pre = stim_pre ./ sqrt(sum(stim_pre.^2)); % Normalize sound axis
                   
                % --- 2) Calculate Stimulus + Sound Axis (stim + sound - sound) USING ALL NEURONS ---
                stim_sound_mean_new = mean(stim_matrix(trainA_stim_all,:, aframes), [1, 3]);
                sound_mean_new = mean(ctrl_matrix(trainA_ctrl_all, :, aframes), [1, 3]);
                stim_axis_new = stim_sound_mean_new - sound_mean_new; % Difference between stim + sound and sound
                norm_stim_diff_new = stim_axis_new ./ sqrt(sum(stim_axis_new.^2)); % Normalize stimulus axis
            
                % --- 3) Calculate Active-Passive Axis (active - passive) ---
                stim_matrix = [dff_st{1, current_dataset}.stim(:,mod_cells,:); dff_st{2, current_dataset}.stim(:,mod_cells,:)]; % stim + sound (active and passive)
                ctrl_matrix = [dff_st{1, current_dataset}.ctrl(:,mod_cells,:); dff_st{2, current_dataset}.ctrl(:,mod_cells,:)]; % sound only (active and passive)
    
                %CONCATENATE TRIALS ACROSS CONTROL AND STIM CONDITIONS
                if ~isempty(bframes2)
                    active_passive_sound_mean = [
                    nanmean([ctrl_matrix(ctrl_splits{current_dataset,1}(split).trainA, :, bframes2);stim_matrix(stim_splits{current_dataset,1}(split).trainA, :, bframes2)], [1, 3]); % active sound total_trials{current_dataset, 1, 2}
                    nanmean([ctrl_matrix(ctrl_splits{current_dataset,2}(split).trainA, :, bframes2);stim_matrix(stim_splits{current_dataset,2}(split).trainA, :, bframes2)], [1, 3])]; % passive sound total_trials{current_dataset, 2, 2}
                else
                    active_passive_sound_mean = [
                    nanmean([ctrl_matrix(ctrl_splits{current_dataset,1}(split).trainA, :, bframes);stim_matrix(stim_splits{current_dataset,1}(split).trainA, :, bframes)], [1, 3]); % active sound total_trials{current_dataset, 1, 2}
                    nanmean([ctrl_matrix(ctrl_splits{current_dataset,2}(split).trainA, :, bframes);stim_matrix(stim_splits{current_dataset,2}(split).trainA, :, bframes)], [1, 3])]; % passive sound total_trials{current_dataset, 2, 2}
                end
                context_axis = active_passive_sound_mean(1,:) - active_passive_sound_mean(2,:); % active - passive
                norm_context_diff = context_axis ./ sqrt(sum(context_axis.^2)); % Normalize context axis
                norm_context_diff_stim = norm_context_diff;

%                 %SEPARATED BY CONTROL AND STIM TRIALS TO DEFINE THE AXIS
%                 active_passive_sound_mean = [
%                 nanmean(ctrl_matrix(ctrl_splits{current_dataset,1}(split).trainA, :, bframes), [1, 3]); % active sound total_trials{current_dataset, 1, 2}
%                 nanmean(ctrl_matrix(ctrl_splits{current_dataset,2}(split).trainA, :, bframes), [1, 3])]; % passive sound total_trials{current_dataset, 2, 2}
%                 context_axis = active_passive_sound_mean(1,:) - active_passive_sound_mean(2,:); % active - passive
%                 norm_context_diff = context_axis ./ sqrt(sum(context_axis.^2)); % Normalize context axis
% 
%                 % do pre of stim trials also (to increase number of trials for
%                 % behavioral performance plots)
%                 active_passive_sound_mean_stim = [
%                 nanmean(stim_matrix(stim_splits{current_dataset,1}(split).trainA, :, bframes), [1, 3]); % active sound total_trials{current_dataset, 1, 2}
%                 nanmean(stim_matrix(stim_splits{current_dataset,2}(split).trainA, :, bframes), [1, 3])]; % passive sound total_trials{current_dataset, 2, 2}
%                 context_axis_stim = active_passive_sound_mean_stim(1,:) - active_passive_sound_mean_stim(2,:); % active - passive
%                 norm_context_diff_stim = context_axis_stim ./ sqrt(sum(context_axis_stim.^2)); % Normalize context axis
    
                % --- 4) Calculate NOISE Axis ---
                stim_matrix = [dff_st{1, current_dataset}.stim(:,mod_cells,:); dff_st{2, current_dataset}.stim(:,mod_cells,:)]; % stim + sound (active and passive)
                ctrl_matrix = [dff_st{1, current_dataset}.ctrl(:,mod_cells,:); dff_st{2, current_dataset}.ctrl(:,mod_cells,:)]; % sound only (active and passive)
                % (a) extract time window and reshape into trials x neurons
                stim_trial_neurons = squeeze(mean(stim_matrix(trainA_stim_all,:,aframes),3)); %mean across time
                ctrl_trial_neurons = squeeze(mean(ctrl_matrix(trainA_ctrl_all,:,aframes),3)); %mean across time
                % (b) subtract mean to center the data
                stim_demeaned = stim_trial_neurons - mean(stim_trial_neurons,1);
                ctrl_demeaned = ctrl_trial_neurons - mean(ctrl_trial_neurons,1);
                % (c) compute noise axis using PCA?
                [coeff_stim,~,~] = pca(stim_demeaned);
                [coeff_ctrl,~,~] = pca(ctrl_demeaned);
                %repeat for test
                stim_trial_neurons_test = squeeze(mean(stim_matrix(test_stim_all,:,aframes),3)); %mean across time
                ctrl_trial_neurons_test = squeeze(mean(ctrl_matrix(test_ctrl_all,:,aframes),3)); %mean across time
                stim_demeaned_test = stim_trial_neurons_test - mean(stim_trial_neurons,1);
                ctrl_demeaned_test = ctrl_trial_neurons_test - mean(ctrl_trial_neurons,1);
    
                %5) PROJECT THE DATA! onto test trials!!
                %also save real activity in case we want to look at it
                
                % --- Compute noise axis using training data (already done above) ---
                % coeff_ctrl(:,1) is your noise axis from PCA on ctrl_demeaned
                % --- Preallocate time-resolved projection arrays ---
                n_test_trials = length(test_ctrl_all);
                n_timepoints = size(ctrl_matrix, 3);
                noise_timeseries_proj_ctrl = zeros(n_test_trials, n_timepoints);
                % --- Compute training set means per neuron per time ---
                ctrl_train_mean = squeeze(mean(ctrl_matrix(trainA_ctrl_all, :, :), 1));  % [neurons x time]
                stim_train_mean = squeeze(mean(stim_matrix(trainA_stim_all, :, :), 1));  % [neurons x time]
                % --- Loop through test trials and project each timepoint ---
                %CTRL TRIALS
                for tr = 1:n_test_trials
                    ctrl_trial = test_ctrl_all(tr);
                    for t = 1:n_timepoints
                        % Get trial activity at this timepoint (1 x neurons)
                        ctrl_vec = squeeze(ctrl_matrix(ctrl_trial,:,t));  % [1 x neurons]
                        % Demean using training set mean at that timepoint
                        ctrl_vec_demeaned = ctrl_vec - ctrl_train_mean(:,t)';
                        % Project onto noise axis
                        noise_timeseries_proj_ctrl(tr, t) = ctrl_vec_demeaned * coeff_ctrl(:,1);
                    end
                end
                %STIM TRIALS
                n_test_trials = length(test_stim_all);
                n_timepoints = size(stim_matrix, 3);
                noise_timeseries_proj_stim = zeros(n_test_trials, n_timepoints);
                % --- Compute training set means per neuron per time ---
                stim_train_mean = squeeze(mean(stim_matrix(trainA_stim_all, :, :), 1));  % [neurons x time]
                % --- Loop through test trials and project each timepoint ---
                %CTRL TRIALS
                for tr = 1:n_test_trials
                    stim_trial = test_stim_all(tr);
                    for t = 1:n_timepoints
                        % Get trial activity at this timepoint (1 x neurons)
                        stim_vec = squeeze(stim_matrix(stim_trial,:,t));  % [1 x neurons]
                        % Demean using training set mean at that timepoint
                        stim_vec_demeaned = stim_vec - stim_train_mean(:,t)';
                        % Project onto noise axis
                        noise_timeseries_proj_stim(tr, t) = stim_vec_demeaned * coeff_stim(:,1);
                    end
                end
                
                %PROJECT ACTIVITY!
                tr = 0;
                for trial = test_ctrl_all 
                    tr = tr+1;
                    sound_proj_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_sound_diff';
                    stim_proj_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_stim_diff';
                    sound_post_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_sound_post';
                    sound_pre_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_sound_pre';
                    stim_post_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_stim_post';
                    stim_pre_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_stim_pre';
    %                 context_proj_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_context_diff';
                    real_activity_ctrl(tr,:) = squeeze(mean(ctrl_matrix(trial,:,:),2))'; %find mean across cells
                    noise_proj_ctrl(tr,:) = ctrl_demeaned_test(tr,:)*coeff_ctrl(:,1);
                    context_proj_ctrl(tr,:) = squeeze(ctrl_matrix(trial,:,:))'*norm_context_diff';
                end
    
                tr = 0;
                for trial = test_stim_all%1: trials_stim
                    tr = tr+1;
                    sound_proj_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_sound_diff';
                    stim_proj_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_stim_diff';
                    sound_post_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_sound_post'; 
                    sound_pre_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_sound_pre'; 
                    stim_post_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_stim_post';
                    stim_pre_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_stim_pre';
    %                 context_proj_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_context_diff';
                    real_activity_stim(tr,:) = squeeze(mean(stim_matrix(trial,:,:),2))'; %find mean across cells
                    noise_proj_stim(tr,:) = stim_demeaned_test(tr,:)*coeff_stim(:,1);
                    context_proj_stim(tr,:) = squeeze(stim_matrix(trial,:,:))'*norm_context_diff_stim';
    
                end
    
                %axis save into a structure?
                weights{split,current_dataset,celltype}.sound = norm_sound_diff;
                weights{split,current_dataset,celltype}.stim = norm_stim_diff;
                weights{split,current_dataset,celltype}.context = norm_context_diff;
                weights{split,current_dataset,celltype}.sound_post = norm_sound_post;
                weights{split,current_dataset,celltype}.sound_pre = norm_sound_pre;
                weights{split,current_dataset,celltype}.noise_ctrl = coeff_ctrl(:,1)';
                weights{split,current_dataset,celltype}.noise_stim = coeff_stim(:,1)';
    
                %projections
                %stim    
    %             %save data concatenating across contexts
                % --- Step 1: Normalize sources BEFORE trial selection ---
                stim_sources = {sound_proj_stim, sound_post_stim, sound_pre_stim, stim_pre_stim, stim_post_stim, ...
                                stim_proj_stim, context_proj_stim, noise_timeseries_proj_stim, noise_proj_stim};
                
                ctrl_sources = {sound_proj_ctrl, sound_post_ctrl, sound_pre_ctrl, stim_pre_ctrl, stim_post_ctrl, ...
                                stim_proj_ctrl, context_proj_ctrl, noise_timeseries_proj_ctrl, noise_proj_ctrl};
                
                stim_sources_norm = cellfun(@(x) normalize_aligned_data_2d(x,'zscore',[]), stim_sources, 'UniformOutput', false);
                ctrl_sources_norm = cellfun(@(x) normalize_aligned_data_2d(x,'zscore',[]), ctrl_sources, 'UniformOutput', false);
                
                field_names = {'sound','sound_post','sound_pre','stim_pre','stim_post', ...
                               'stim','context','noise_timeseries'};%,'noise'

                for cond = ["stim","ctrl"]
                    % Assign all fields (raw and normalized versions)
                    for f = 1:numel(field_names)
                        if strcmp(cond,'stim')
                            data = stim_sources{f};
                            data_norm = stim_sources_norm{f};
                        else
                            data = ctrl_sources{f};
                            data_norm = ctrl_sources_norm{f};
                        end
                
                        if strcmp(field_names{f}, 'noise')  % 1D special case
                            target{split,current_dataset,celltype}.(field_names{f}) = data;
                            target_norm{split,current_dataset,celltype}.(field_names{f}) = data_norm;
                        end
                    end
                
                    % Write back into the right variable
                    if cond == "stim"
                        proj_concat = target;
                        proj_concat_norm = target_norm;
                    else
                        proj_concat_ctrl = target;
                        proj_concat_ctrl_norm = target_norm;
                    end
                end

    
                real_activity_all_norm{split,current_dataset,celltype,1}.sound = normalize_aligned_data_2d(real_activity_ctrl,'zscore',[]);
                real_activity_all_norm{split,current_dataset,celltype,1}.stim = normalize_aligned_data_2d(real_activity_stim,'zscore',[]);
                real_activity_all_norm{split,current_dataset,celltype,1}.context_sound = normalize_aligned_data_2d(real_activity_ctrl,'zscore',[]);
                real_activity_all_norm{split,current_dataset,celltype,1}.context_stim = normalize_aligned_data_2d(real_activity_stim,'zscore',[]);
    
%                 real_activity_all{split,current_dataset,celltype,1}.sound = real_activity_ctrl;
%                 real_activity_all{split,current_dataset,celltype,1}.stim = real_activity_stim;
%                 real_activity_all{split,current_dataset,celltype,1}.context_sound = real_activity_ctrl;
%                 real_activity_all{split,current_dataset,celltype,1}.context_stim = real_activity_stim;
    
                
                %separate projection data into contexts
                for context = 1:2

                    % --- Step 1: Normalize sources BEFORE trial selection ---
                    stim_sources = {sound_proj_stim, sound_post_stim, sound_pre_stim, stim_pre_stim, stim_post_stim, ...
                                    stim_proj_stim, context_proj_stim, noise_timeseries_proj_stim, noise_proj_stim};
                    
                    ctrl_sources = {sound_proj_ctrl, sound_post_ctrl, sound_pre_ctrl, stim_pre_ctrl, stim_post_ctrl, ...
                                    stim_proj_ctrl, context_proj_ctrl, noise_timeseries_proj_ctrl, noise_proj_ctrl};
                    
                    stim_sources_norm = cellfun(@(x) normalize_aligned_data_2d(x,'zscore',[]), stim_sources, 'UniformOutput', false);
                    ctrl_sources_norm = cellfun(@(x) normalize_aligned_data_2d(x,'zscore',[]), ctrl_sources, 'UniformOutput', false);
                    
                    field_names = {'sound','sound_post','sound_pre','stim_pre','stim_post', ...
                                   'stim','context','noise_timeseries'}; %,'noise'
                    
                    % --- Step 2: Loop over conditions (stim/ctrl), context, etc. ---
                    for cond = ["stim","ctrl"]
                        if cond == "stim"
                            current_trials = ismember(test_stim_all, stim_splits{current_dataset,context}(split).test);
                            sources = stim_sources;
                            sources_norm = stim_sources_norm;
                            target = proj;
                            target_norm = proj_norm;
                        else
                            current_trials = ismember(test_ctrl_all, ctrl_splits{current_dataset,context}(split).test);
                            sources = ctrl_sources;
                            sources_norm = ctrl_sources_norm;
                            target = proj_ctrl;
                            target_norm = proj_ctrl_norm;
                        end
                    
                        % Assign all fields (raw and normalized versions)
                        for f = 1:numel(field_names)
                            data = sources{f};
                            data_norm = sources_norm{f};
                    
                            if strcmp(field_names{f}, 'noise')  % 1D special case
                                target{split,current_dataset,celltype,context}.(field_names{f}) = data(current_trials);
                                target_norm{split,current_dataset,celltype,context}.(field_names{f}) = data_norm(current_trials);
                            else
                                target{split,current_dataset,celltype,context}.(field_names{f}) = data(current_trials,:);
                                target_norm{split,current_dataset,celltype,context}.(field_names{f}) = data_norm(current_trials,:);
                            end
                        end
                    
                        % Write back into the right variable
                        if cond == "stim"
                            proj = target;
                            proj_norm = target_norm;
                        else
                            proj_ctrl = target;
                            proj_ctrl_norm = target_norm;
                        end
                    end


    
                    % find correlations before and after
                    trial_corr_context{split,current_dataset,celltype,context}.sound =  corr(nanmean(sound_proj_ctrl(ismember(test_ctrl_all,ctrl_splits{current_dataset,context}(split).test),aframes),2),nanmean(context_proj_ctrl(ismember(test_ctrl_all,ctrl_splits{current_dataset,context}(split).test),bframes),2),'Type','Pearson');% corr(nanmean(sound_proj_ctrl(total_trials{current_dataset, context, 2},:),2),nanmean(context_proj_ctrl(total_trials{current_dataset, context, 2},:),2),'Type','Pearson');
                    trial_corr_context{split,current_dataset,celltype,context}.stim = corr(nanmean(stim_proj_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),aframes),2),nanmean(context_proj_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),bframes),2),'Type','Pearson');
                    trial_corr_context{split,current_dataset,celltype,context}.stim_sound = corr(nanmean(stim_proj_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),aframes),2),nanmean(sound_proj_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),aframes),2),'Type','Pearson');
                    trial_corr_context{split,current_dataset,celltype,context}.stim_sound_post = corr(nanmean(stim_proj_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),aframes),2),nanmean(sound_post_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),aframes),2),'Type','Pearson');
    
    
                    %concat stim and ctrl for more trials
                    proj_concat_norm{split,current_dataset,celltype,context}.context = [proj_norm{split,current_dataset,celltype,context}.context;proj_ctrl_norm{split,current_dataset,celltype,context}.context];
                    proj_concat{split,current_dataset,celltype,context}.context = [proj{split,current_dataset,celltype,context}.context;proj_ctrl{split,current_dataset,celltype,context}.context];
    
    
                    %also save real actity
                    real_activity_all_ctrl{split,current_dataset,celltype,context}.sound = real_activity_all_norm{split,current_dataset,celltype,1}.sound(ismember(test_ctrl_all,ctrl_splits{current_dataset,context}(split).test),:);
                    real_activity_all_ctrl{split,current_dataset,celltype,context}.context = real_activity_all_norm{split,current_dataset,celltype,1}.sound(ismember(test_ctrl_all,ctrl_splits{current_dataset,context}(split).test),:);
                    real_activity_all_norm{split,current_dataset,celltype,context}.stim = real_activity_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),:);
                    real_activity_all_norm{split,current_dataset,celltype,context}.context = real_activity_stim(ismember(test_stim_all,stim_splits{current_dataset,context}(split).test),:);
    
                end
    
                %save correct trials
                %get from control trials first
                all_correct_trials = [all_trial_info(current_dataset).ctrl(:).correct];
                percent_correct{split,current_dataset} = all_correct_trials(ctrl_splits{current_dataset,1}(split).test);
    
                %concatenate ctrl and stim to have more trials (performance
                %only)
                all_correct_trials_stim = [all_trial_info(current_dataset).opto(:).correct];
                percent_correct_concat{split,current_dataset} = [percent_correct{split,current_dataset},all_correct_trials_stim(stim_splits{current_dataset,1}(split).test)];
                z_real_activity_stim = normalize_aligned_data_2d(real_activity_stim,'zscore',[]);
                z_real_activity_ctrl = normalize_aligned_data_2d(real_activity_ctrl,'zscore',[]);
                real_activity_all{split,current_dataset,celltype,1} = [z_real_activity_ctrl(ismember(test_ctrl_all,ctrl_splits{current_dataset,1}(split).test),:);z_real_activity_stim(ismember(test_stim_all,stim_splits{current_dataset,1}(split).test),:)];
                engagement_concat{split,current_dataset,celltype} = [proj_ctrl_norm{split,current_dataset,celltype,1}.context;proj_norm{split,current_dataset,celltype,1}.context];
    
                
            end %celltypes
            %save test trials (relative to imaging virmen trials?)
            all_ctrl_trials = [all_trial_info(current_dataset).ctrl(:).trial_id];
            all_stim_trials = [all_trial_info(current_dataset).opto(:).trial_id];
            test_trials{split,current_dataset} = [all_ctrl_trials(ctrl_splits{current_dataset,1}(split).test),all_stim_trials(stim_splits{current_dataset,1}(split).test)];

            all_ctrl_trials_relative = [all_trial_info(current_dataset).ctrl(:).matched_id];
            all_stim_trials_relative = [all_trial_info(current_dataset).opto(:).matched_id];
            test_trials_relative{split,current_dataset} = [all_ctrl_trials_relative(ctrl_splits{current_dataset,1}(split).test),all_stim_trials_relative(stim_splits{current_dataset,1}(split).test)];
            test_stim_trials_relative_to_alignment{split,current_dataset} = test_stim_all;
            test_ctrl_trials_relative_to_alignment{split,current_dataset} = test_ctrl_all;

        end %datasets
   end %splits

   axis_results = struct();
    
    axis_results.proj                     = proj;
    axis_results.proj_ctrl                = proj_ctrl;
    axis_results.proj_norm                = proj_norm;
    axis_results.proj_norm_ctrl           = proj_ctrl_norm;
    
    axis_results.weights                  = weights;
    
    axis_results.trial_corr_context       = trial_corr_context;
    axis_results.percent_correct          = percent_correct;
    
    axis_results.real_activity_all        = real_activity_all;
    axis_results.real_activity_all_ctrl   = real_activity_all_ctrl;
    axis_results.real_activity_all_norm   = real_activity_all_norm;
    
    axis_results.percent_correct_concat   = percent_correct_concat;
    axis_results.proj_concat              = proj_concat;
    axis_results.proj_concat_norm         = proj_concat_norm;
    
    axis_results.engagement_concat        = engagement_concat;
    axis_results.test_trials              = test_trials; %relative to virmen trials in active
    axis_results.test_trials_relative     = test_trials_relative;

    %the trials are based on the aligned stim or ctrl matrices
    axis_results.stim_split_trials = test_stim_trials_relative_to_alignment;
    axis_results.ctrl_split_trials = test_ctrl_trials_relative_to_alignment;


end