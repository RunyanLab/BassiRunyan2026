function [acc] = run_classifier_glm_inputs_cluster_subsample_neurons(current_mouse , save_string_glm,all_celltypes,mdl_param, alignment,info)
possible_celltypes = fieldnames(all_celltypes{1,1});

% Requested population sizes for neuron-dropping curve
requested_sizes = mdl_param.requested_sizes;

acc = {};
shuff_acc = {};
mdl_results = {};
for m = current_mouse
%     ss = info.server(m);
%     ss = ss {1,1};
info.mouse_date{1,m} = strrep(info.mouse_date{1,m}, '\', '/');
    base = strcat('/ix/crunyan/cdb66/Data/',num2str(info.mouse_date{1,m}),'/',save_string_glm,'/');

if mdl_param.field_to_predict == 1
    field_string = 'outcome_14to169';
elseif mdl_param.field_to_predict == 2
    field_string = 'choice_14to169';
elseif mdl_param.field_to_predict == 3
    field_string = 'sound_category_14to169'; %# are frames used to define peaks
    if contains(save_string_glm,'passive')
        field_string = 'passive_sound_category_14to100'; %# are frames used to define peaks
    end
elseif mdl_param.field_to_predict == 4
    field_string = 'photostim';
end

%load GLM data!
for splits = 1:10
    dir_base = strcat(base,'/prepost trial cv 73 #', num2str(splits));
    base_testing = strcat(dir_base, '/test');
    % Process training and testing data
    load(strcat(dir_base, '/condition_array_trials.mat'));
    % Load imaging data
    if alignment.active_passive == 1
        base_imaging = strcat('/ix/crunyan/cdb66/Data/',num2str(info.mouse_date{1,m}),'/VR/');
    else
        base_imaging = strcat('/ix/crunyan/cdb66/Data/',num2str(info.mouse_date{1,m}),'/passive/');
    end
    load(strcat(base_imaging,'/imaging.mat'));
    train_imaging_spk = make_imaging_from_trials(condition_array_trials, imaging);
    
    %For some reason I saved them differently for active vs passive
    if alignment.active_passive == 1
        load(strcat(base_testing, '/condition_array_trials.mat'));
        test_imaging_spk = make_imaging_from_trials(condition_array_trials, imaging);
    else
        load(strcat(dir_base, '/condition_array_trials_test.mat'));
        test_imaging_spk = make_imaging_from_trials(condition_array_trials_test, imaging);
    end
    
    %load minimum # of trials!!
    if contains(dir_base, 'passive')
            % Replace "passive" with "pre"
        newDir = strrep(dir_base, 'passive', 'pre');
        load(strcat(newDir,'/sound_trials.mat'));
    else
        load(strcat(dir_base,'/sound_trials.mat'));
    end
    
    if contains(dir_base, 'passive')
        % Replace "passive" with "pre"
        newDir = strrep(dir_base, 'passive', 'pre');
        load(strcat(newDir,'/photostim_trials.mat'));
    else
        load(strcat(dir_base,'/photostim_trials.mat'));
    end
    
     %BALANCE TRIALS!!! THIS IS THE PART THAT MIGHT DIFFER FROM WHAT I HAD BEFORE (COPYING TO GLM DECODER CODE)            
    %load same trials used in glm!!!
    it = 1;
    if mdl_param.field_to_predict == 1
        load(strcat(base,'/decoding/',num2str(splits),'_1/decoder_results_regular_outcome.mat'));
        selected_trials = decoder_results.aligned.outcome(it).results.alignment.trials_used.train;
        selected_trials_test = decoder_results.aligned.outcome(it).results.alignment.trials_used.test;
        mdl_param.selected_trials = selected_trials;
        mdl_param.selected_trials_test = selected_trials_test;
    elseif mdl_param.field_to_predict == 2
        load(strcat(base,'/decoding/',num2str(splits),'_1/decoder_results_regular_choice.mat'));
        selected_trials = decoder_results.aligned.choice(it).results.alignment.trials_used.train;
        selected_trials_test = decoder_results.aligned.choice(it).results.alignment.trials_used.test;
        mdl_param.selected_trials = selected_trials;
        mdl_param.selected_trials_test = selected_trials_test;
    elseif mdl_param.field_to_predict == 3
        load(strcat(base,'/decoding/',num2str(splits),'_1/decoder_results_regular_sound_category.mat'));
        selected_trials = decoder_results.aligned.sound_category(it).results.alignment.trials_used.train;
        selected_trials_test = decoder_results.aligned.sound_category(it).results.alignment.trials_used.test;
        mdl_param.selected_trials = selected_trials;
        mdl_param.selected_trials_test = selected_trials_test;
    elseif mdl_param.field_to_predict == 4
        load(strcat(base,'/decoding/',num2str(splits),'_1/decoder_results_regular_photostim_updated.mat'));
        selected_trials = decoder_results.aligned.photostim(it).results.alignment.trials_used.train;
        selected_trials_test = decoder_results.aligned.photostim(it).results.alignment.trials_used.test;
        mdl_param.selected_trials = selected_trials;
        mdl_param.selected_trials_test = selected_trials_test;
    end
    
    selected_trials_id = find(mdl_param.selected_trials);
    rearraged_trials = selected_trials_id(randperm(length(selected_trials_id)));
    
    selected_trials_test_id = find(mdl_param.selected_trials_test);
    rearraged_trials_test = selected_trials_test_id(randperm(length(selected_trials_test_id)));
    

%load informative cells
data = load(strcat('/ix/crunyan/cdb66/Data/top_informative/sorted_peaks_',field_string,'.mat')); %putting it here so I dont have to do it per dataset 
celltypes_to_do = 1; %just doing pyr for right now
curr_mouse = strrep(info.mouse_date{1,m}, '/', '_');
curr_mouse = strrep(curr_mouse, '-', '_');
curr_mouse = [curr_mouse '_pyr'];

%could consider using the exact same trials as original decoder (but would
%not work for shuffled bc the trials ids are shuffled
%find(decoder_results.aligned.shuffled.photostim(1).cat_results.alignment.trials_used.train);
% disp(['Saving path: ' info.savepath '/SVM_' alignment.data_type '_' info.savestr]);
   
%         it
%     for m = 1:length(imaging_st)
        count = 0;
%         m
        for ce = 1:4 %4 will be the top pyramidal neurons! 
            count = count+1;
            mdl_param.mouse = m;
            %do current split
%             ex_imaging = imaging_st{1,m};
            imaging_train_input = train_imaging_spk; %imaging_st{1,m};
            imaging_test_input = test_imaging_spk;
            

            if alignment.active_passive == 2
                [align_info,alignment_frames,left_padding,right_padding] = find_align_info_updated (imaging_train_input,30,alignment.active_passive);
                [align_info_test,alignment_frames_test,left_padding_t,right_padding_t] = find_align_info_updated (imaging_test_input,30,alignment.active_passive);
            else
                [align_info,alignment_frames,left_padding,right_padding] = find_align_info_updated (imaging_train_input,30);
                [align_info_test,alignment_frames_test,left_padding_t,right_padding_t] = find_align_info_updated (imaging_test_input,30);
            end
            [aligned_imaging,imaging_array,align_info] = align_behavior_data (imaging_train_input,align_info,alignment_frames,left_padding,right_padding,alignment); % sample_data is n_trials x n_cells x n_frames
            [aligned_imaging_test,imaging_array_test,align_info_test] = align_behavior_data (imaging_test_input,align_info_test,alignment_frames_test,left_padding,right_padding,alignment); % sample_data is n_trials x n_cells x n_frames

                        
            % Get available/ranked cells
            if ce < 4
                % Standard cell types: randomly subsample neurons
                available_cells = all_celltypes{1,m}.(possible_celltypes{ce});
                available_cells = available_cells(:)';
            
                selection_type = 'random';
            
            else
                % Ranked pyramidal neurons, ordered best to worst
                available_cells = data.(curr_mouse) + 1;
                available_cells = available_cells(:)';
            
                selection_type = 'ranked';
            end
            
            nAvailable = numel(available_cells);
           
    
            %get X and Y ready for classifier
            fieldss = fieldnames(imaging_train_input(1).virmen_trial_info);
%             [~, condition_array] = divide_trials_updated (ex_imaging,{fieldss{mdl_param.field_to_predict}});
            [~, condition_array] = divide_trials_updated (imaging_train_input,{fieldss{mdl_param.field_to_predict}});
            %shuffle trial order before putting it into the matrix

            mdl_Y = condition_array(rearraged_trials,2);%condition_array_trials_t(find(mdl_param.selected_trials),2); %get trained Y labels
            mdl_X = aligned_imaging(rearraged_trials,:,:);

            %repeat for test trials!
            [~, condition_array_test] = divide_trials_updated (imaging_test_input,{fieldss{mdl_param.field_to_predict}});
            %shuffle trial order before putting it into the matrix
            mdl_Y_test = condition_array_test(rearraged_trials_test,2);%condition_array_trials_t(find(mdl_param.selected_trials),2); %get trained Y labels
            mdl_X_test = aligned_imaging_test(rearraged_trials_test,:,:);
            % Only use population sizes that are possible for this cell type
            population_sizes = requested_sizes(requested_sizes <= nAvailable);
            
            for pop_idx = 1:numel(population_sizes)

                nCells = population_sizes(pop_idx);
            
                % No need to repeat when every available neuron is selected
                if strcmp(selection_type, 'ranked')
                    % Deterministic ranked population: only one run per split
                    nIterationsCurrent = 1;
                
                elseif nCells == nAvailable
                    % Full population is also deterministic
                    nIterationsCurrent = 1;
                
                else
                    % Random neuron subsets
                    nIterationsCurrent = mdl_param.num_iterations;
                end
            
                for it = 1:nIterationsCurrent
            
                    if strcmp(selection_type, 'ranked')
                        % Add ranked neurons cumulatively
                        mdl_param.mdl_cells = available_cells(1:nCells);
                    else
                        % Randomly select neurons without replacement
                        mdl_param.mdl_cells = available_cells( ...
                            randperm(nAvailable, nCells));
                    end
            
                    % Save population information
                    mdl_param.population_size = nCells;
            
                    fprintf(['split #: ', num2str(splits), ...
                        ' || subsample #: ', num2str(it), ...
                        ' || mouse: ', num2str(info.mouse_date{1,m}), ...
                        ' || celltype: ', num2str(ce), ...
                        ' || #neurons: ', num2str(nCells), ...
                        ' || size Y: ', num2str(size(mdl_Y)), ...
                        ' || size X: ', num2str(size(mdl_X)), '\n']);
            
                    current_output = ...
                        classify_over_time_glm_inputs( ...
                            mdl_X, mdl_Y, mdl_param, mdl_X_test, mdl_Y_test);
            
                    % Accuracy
                    acc{splits,it,ce,pop_idx} = ...
                        current_output.accuracy;
            
                    shuff_acc{splits,it,ce,pop_idx} = ...
                        current_output.shuff_accuracy;
            
                    % Model results
                    mdl_results{splits,it,ce,pop_idx}.train_accuracy = ...
                        current_output.train_accuracy;
            
                    mdl_results{splits,it,ce,pop_idx}.shuffled_train_accuracy = ...
                        current_output.shuff_train_accuracy;
            
%                     mdl_results{splits,it,ce,pop_idx}.BoxConstraints = ...
%                         current_output.mdl{1,1}.BoxConstraints(1);
            
                    mdl_results{splits,it,ce,pop_idx}.population_size = nCells;
                    mdl_results{splits,it,ce,pop_idx}.selected_cells = ...
                        mdl_param.mdl_cells;
% %             deleted below to save memory            
%                     % Get betas for all-cell population
%                     if ce == 4
%                         for bin = 1:length(output{splits,it,ce,pop_idx}.mdl)
%             
%                             betas{splits,it,pop_idx,bin} = ...
%                                 output{splits,it,ce,pop_idx}.mdl{1,bin}.Beta;
% 
%                             mdl_results{splits,it,ce,pop_idx}.bin(bin).IsSupportVector = ...
%                                 output{splits,it,ce,pop_idx}.mdl{1,bin}.IsSupportVector;
%             
%                             mdl_results{splits,it,ce,pop_idx}.bin(bin).Alpha = ...
%                                 output{splits,it,ce,pop_idx}.mdl{1,bin}.Alpha;
%             
%                             mdl_results{splits,it,ce,pop_idx}.bin(bin).Bias = ...
%                                 output{splits,it,ce,pop_idx}.mdl{1,bin}.Bias;
%                         end
%                     end
            
                    if it == 1
                        all_model_outputs{splits,ce,pop_idx} = mdl_param;
                    end
                    clear current_output
            
                end %iteration for loop
            end %population size for loop
        end %cell type for loop
    end %split for loop
end %dataset for loop

%convert output to matrix form for easier indexing
%% Save the output

%save info variables
%output{1,1,1}.info = info; %save in the first one

% mkdir([info.savepath '/SVM_' alignment.data_type '_' info.savestr])
% cd([info.savepath '/SVM_' alignment.data_type '_' info.savestr])

mkdir(strcat(base,'/decoding/SVM_1/'));
cd(strcat(base,'/decoding/SVM_1/'));

if mdl_param.field_to_predict == 1
    save_string = 'outcome_subsampled';
elseif mdl_param.field_to_predict == 2
    save_string = 'choice_subsampled';
elseif mdl_param.field_to_predict == 3
    save_string = 'sound_category_subsampled';
elseif mdl_param.field_to_predict == 4
    save_string = 'photostim_subsampled';
end


svm_info = info;
save(strcat(save_string,'_svm_info'),'svm_info','-v7.3');
% save(strcat(save_string,'_betas'),'betas','-v7.3');
save(strcat(save_string,'_all_model_outputs'),'all_model_outputs','-v7.3');
save(strcat(save_string,'_acc'),'acc','-v7.3');
save(strcat(save_string,'_shuff_acc'),'shuff_acc','-v7.3');
save(strcat(save_string,'_mdl_results'),'mdl_results','-v7.3');


