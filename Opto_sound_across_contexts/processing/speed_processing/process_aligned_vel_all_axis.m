function [deltaLeft,deltaRight,avg_speed_axis_data, stats,stats_specified_frames,general_stats] = process_aligned_vel_all_axis(chosen_mice, mouse_vel, trials, function_params)
% process_aligned_vel_all_axis - Process velocity data for multiple mice across active and passive contexts.
%
%   STATS = process_aligned_vel_all_axis(CHOSEN_MICE, MOUSE_VEL, TRIALS, FUNCTION_PARAMS)
%   processes velocity data from the specified mice by aligning it to a stimulus event,
%   computing differences (deltas) and average speeds for left and right trials, and separating
%   the data into active and passive contexts. The function returns a structure STATS that
%   contains the mean and standard error (SEM) of speeds for each axis (Roll, Pitch, Both) for
%   both active and passive conditions.
%
%   Inputs:
%       CHOSEN_MICE     - Array of indices representing the selected mice.
%       MOUSE_VEL       - Structure array containing velocity data for each mouse with fields:
%                           field_name_roll
%                           field_name_pitch
%                           field_name (combo or roll and pitch)
%       TRIALS          - Cell array containing trial information for active and passive contexts.
%       FUNCTION_PARAMS - Structure containing processing parameters, including:
%                           stim_frame          : The frame corresponding to the stimulus.
%                           frames_before_stim  : Number of frames to include before the stimulus.
%                           frames_after_stim   : Number of frames to include after the stimulus.
%                           abs                 : Flag indicating whether to take the absolute value of speeds.
%
%   Outputs:
%       STATS           - Structure with fields for the 'Active' and 'Passive' contexts. Each field
%                         contains subfields for each axis (Roll, Pitch, Both) with the computed mean
%                         and SEM values.
%
%   See also: compute_deltas_and_speeds, compute_mean_sem.

%% Initialize variables

    frames_before = function_params.frames_before_stim;
    frames_after = function_params.frames_after_stim;

    %% Process Active and Passive Contexts
    contexts = function_params.contexts ;%{'Active', 'Passive'};

    % Define number of contexts
    numContexts = length(contexts);
    % Preallocate structure arrays correctly
    deltaLeft(numContexts) = struct('Roll', [], 'Pitch', [], 'Both', []);
    deltaRight(numContexts) = struct('Roll', [], 'Pitch', [], 'Both', []);
    % Ensure each field is initialized properly
    for contextIdx = 1:numContexts
        deltaLeft(contextIdx).Roll = [];
        deltaRight(contextIdx).Roll = [];
        deltaLeft(contextIdx).Pitch = [];
        deltaRight(contextIdx).Pitch = [];
        deltaLeft(contextIdx).Both = [];
        deltaRight(contextIdx).Both = [];
    end


    for contextIdx = 1:length(contexts)
%         context = contexts{contextIdx};
        
        for m = chosen_mice
            % Get trials based on context
%             trialIdx  % 1 for Active, 2 for Passive
            trials_left = trials{1,1}{1,m}{1,contextIdx};
            trials_right = trials{2,1}{1,m}{1,contextIdx};

            %get field names for each velocity type
            field_name_roll = [function_params.field_name_vel '_roll'];
            field_name_pitch = [function_params.field_name_vel '_pitch'];
            field_name = function_params.field_name_vel;
            
            % Extract velocity data
            vel = struct(...
                'Pitch', {mouse_vel(m).(field_name_pitch)}, ...
                'Roll', {mouse_vel(m).(field_name_roll)}, ...
                'Both', {mouse_vel(m).(field_name)} ...
            );
            
            
            % Compute deltas (difference after - before) and speeds
            [deltaL, deltaR, avg_speeds] = compute_deltas_and_speeds(vel, trials_left, trials_right, function_params);
            
            % Store results
            % Append data for each context
            deltaLeft(contextIdx).Pitch  = [deltaLeft(contextIdx).Pitch;  deltaL.Pitch];
            deltaRight(contextIdx).Pitch = [deltaRight(contextIdx).Pitch; deltaR.Pitch];
            deltaLeft(contextIdx).Roll  = [deltaLeft(contextIdx).Roll;  deltaL.Roll];
            deltaRight(contextIdx).Roll = [deltaRight(contextIdx).Roll; deltaR.Roll];
            deltaLeft(contextIdx).Both  = [deltaLeft(contextIdx).Both;  deltaL.Both];
            deltaRight(contextIdx).Both = [deltaRight(contextIdx).Both; deltaR.Both];
            % Store average speeds across context
            average_speeds_across_all(contextIdx, m, :, :) = avg_speeds;

        end

        pitch_indices = [1, 2];
        roll_indices = [3, 4];
        both_indices = [5, 6];
        avg_speed_axis_data{contextIdx,1} = squeeze(mean(average_speeds_across_all(contextIdx,:, pitch_indices, :), [3,4]));   % mice x 1 PITCH
        avg_speed_axis_data{contextIdx,2} =  squeeze(mean(average_speeds_across_all(contextIdx,:, roll_indices, :), [3,4]));   % mice x 1 ROLL
        avg_speed_axis_data{contextIdx,3} = squeeze(mean(average_speeds_across_all(contextIdx,:, both_indices, :), [3,4]));   % mice x 1 BOTH

        %FIND MEAN AT SOUND ONSET?
        frames_for_mean = function_params.specified_frames;
        avg_speeds_axis_data_specified_frames{contextIdx,1} = squeeze(mean(average_speeds_across_all(contextIdx,:, pitch_indices, frames_for_mean), [3,4]));   % mice x 1 PITCH
        avg_speeds_axis_data_specified_frames{contextIdx,2} =  squeeze(mean(average_speeds_across_all(contextIdx,:, roll_indices, frames_for_mean), [3,4]));   % mice x 1 ROLL
        avg_speeds_axis_data_specified_frames{contextIdx,3} = squeeze(mean(average_speeds_across_all(contextIdx,:, both_indices, frames_for_mean), [3,4]));   % mice x 1 BOTH
    
    end

    %% Compute Mean and SEM for CDF plots
    [stats,general_stats] = compute_mean_sem(function_params,average_speeds_across_all);
    stats_specified_frames = compute_mean_sem(function_params,average_speeds_across_all(:,:, :, frames_for_mean));


%% Helper Function: Compute deltas and speeds
function [deltaL, deltaR, avg_speeds] = compute_deltas_and_speeds(vel, trials_left, trials_right, function_params)
    stim_frame = function_params.stim_frame;
    frames_before = function_params.frames_before_stim;
    frames_after = function_params.frames_after_stim;
    
    deltaL = struct();
    deltaR = struct();
    avg_speeds = zeros(6, size(vel.Roll, 2));

    fields = fieldnames(vel);
    for i = 1:length(fields)
        field = fields{i};
        vel_left = vel.(field)(trials_left, :);
        vel_right = vel.(field)(trials_right, :);

        [speedL, speedR] = difference_2event(vel_left, vel_right, stim_frame, frames_before, frames_after);
            
        if function_params.abs
            deltaL.(field) = abs(speedL(:));
            deltaR.(field) = abs(speedR(:));
        else
            deltaL.(field) = speedL(:);
            deltaR.(field) = speedR(:);
        end

        if function_params.abs
            avg_speeds(2*i-1, :) = abs(mean(vel_left, 1));
            avg_speeds(2*i, :) = abs(mean(vel_right, 1));
        else
            avg_speeds(2*i-1, :) = (mean(vel_left, 1));
            avg_speeds(2*i, :) = (mean(vel_right, 1));
        end
    end
end

%% Helper Function: Compute Mean and SEM
function [stats,general_stats] = compute_mean_sem(function_params,avg_speeds_all)
    num_datasets = size(avg_speeds_all, 2);
    contexts = function_params.contexts;

    indices = struct('Pitch', [1, 2],'Roll', [3, 4], 'Both', [5, 6]);    
    stats = struct();
    for ctxIdx = 1:length(contexts)
        ctx = contexts{ctxIdx};
        speeds = squeeze(avg_speeds_all(ctxIdx,:, :, :));%eval([lower(ctx), '_speeds']);
        
        for field = fieldnames(indices)'
            fieldName = field{1};
            idx = indices.(fieldName);
            if length(size(speeds)) < 3
                values = squeeze(mean(speeds(:, idx), 2,'omitnan')); % Average left & right
            else
                values = squeeze(mean(speeds(:, idx, :), 2,'omitnan')); % Average left & right
            end
            stats.(ctx).(fieldName).mean = mean(values, 1);
            stats.(ctx).(fieldName).sem = std(values, 0, 1) / sqrt(num_datasets);
            field_name = strcat('speed_context',num2str(ctx),'_movement',fieldName);
            general_stats.(field_name) = get_basic_stats(mean(values,2));
        end
    end

    % Compute overall mean and SEM across all frames
    for ctxIdx = 1:length(contexts)
        ctx = contexts{ctxIdx};
        for field = fieldnames(indices)'
            fieldName = field{1};
            overall_mean = mean(stats.(ctx).(fieldName).mean, 'all'); % Mean across frames
            overall_sem = std(stats.(ctx).(fieldName).mean, 0, 'all') / sqrt(length(stats.(ctx).(fieldName).mean)); % Correct SEM calculation
            % Store the overall mean and SEM
            stats.(ctx).(fieldName).overall_mean = overall_mean;
            stats.(ctx).(fieldName).overall_sem = overall_sem;
            
        end
    end
end

end