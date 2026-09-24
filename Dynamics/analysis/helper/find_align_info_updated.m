function [align_info,alignment_frames,left_padding,right_padding] = find_align_info (imaging,turn_frames,varargin)
empty_trials = find(cellfun(@isempty,{imaging.good_trial}));
good_trials =  setdiff(1:length(imaging),empty_trials); %only trials with all imaging data considered!

imaging_array = [imaging(good_trials).movement_in_imaging_time]; %convert to array for easier indexing
aligned_imaging =[]; %this is needed so there is an output if there are zero trials in the condition (happens w reward)

%get trial information inside imaging array
maze_length= cellfun(@length,{imaging_array.maze_frames}); %frame length of every trial

%get stimulus info
[~,stimulus_repeats_onsets] = cellfun(@(x) findpeaks(diff(x)),{imaging_array.stimulus},'UniformOutput',false);%finds stim onset but is one early (diff)
stimulus_repeats_onsets = cellfun(@(x) x+1,stimulus_repeats_onsets,'UniformOutput',false); %frame stimulus onsets on each trial
total_stimulus_repeats = cellfun(@(x) length(x)+1,stimulus_repeats_onsets);
stim_onset = cellfun(@min,stimulus_repeats_onsets,'UniformOutput',false); %find first one in stimulus to determine stimulus onset #1

shortest_maze_length = min(maze_length - [stim_onset{1,:}]); %smallest distance in front of stimulus during trial
min_length_stim = min([stim_onset{1,:}])-1; %min number of frames in front of stimulus onset during maze


if min_length_stim == 0 %sometimes weird trial not found bc it is the first of the file
    min_length_stim = min(setdiff([stim_onset{1,:}],min([stim_onset{1,:}])))-1;
    keyboard %probably some weird trial where sound is playing during iti
end

%find reward info
max_length_reward = min(cellfun(@length,{imaging_array.reward_frames})); %24/25 or 30 frames between maze and ITI
reward_onset = cellfun(@(x) find(x == 1),{imaging_array.is_reward},'UniformOutput',false); %reward onset based on all frames in trial
reward_trial = cellfun(@(x) ~isempty(x),reward_onset,'UniformOutput',false);
reward_trial = find([reward_trial{1,:}] == 1); %of good trials which ones have reward
min_length_reward = min([[reward_onset{1,:}] - cellfun(@min,{imaging_array(reward_trial).reward_frames})]); %min number of frames in front of reward before the end of maze
%pure tones
pure_onsets = cellfun(@(x) find(x==1),{imaging_array.pure_tones},'UniformOutput',false);%finds stim onset but is one early (diff)
pure_onsets = cellfun(@min,pure_onsets,'UniformOutput',false);


%for turns using 30 frames before and after
frames_around = turn_frames;
align_info.turn_onset = frames_around+1;
% align_info.stimulus_onsets = [stim_onset{1,:}];
align_info.maze_length = maze_length;
align_info.min_length = shortest_maze_length;
align_info.stimulus_onset = min_length_stim+1; %across trials
align_info.stimulus_repeats_onsets = stimulus_repeats_onsets;
align_info.total_stimulus_repeats = total_stimulus_repeats;
% align_info.stimulus_frames = cellfun(@(x) [x],stim_onset);

% align_info.reward_onsets = [reward_onset{1,:}];
align_info.max_length_reward = max_length_reward;
align_info.reward_onset = min_length_reward+1; %across trials

% align_info.reward_trials = reward_trial; 
align_info.pure_onsets = pure_onsets;

align_info.good_trials = good_trials;
%% align similar to Caroline
%event 1-3 are stimulus onsets
%event 4 is turn
%event 5 is reward
%event 6 is ITI
if nargin < 3
event = 1;
alignment_frames = cellfun(@(x) x(event),stimulus_repeats_onsets);
left_padding(event) = 6;%min_length_stim; %smallest # frames in front
right_padding(event) = 30;
align_info.first_stimulus = alignment_frames;

event = 2;
alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
left_padding(event) = 1;
right_padding(event) = 30;
align_info.second_stimulus = alignment_frames(event,:);

event = 3;
alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
left_padding(event) = 1;
right_padding(event) = 30;
align_info.third_stimulus = alignment_frames(event,:);

event = 4;
alignment_frames(event,:) = [imaging_array.turn_frame];
align_info.turn = alignment_frames(event,:);

left_padding(event) = 30;
right_padding(event) = 12; %used to be 30

event = 5; 
if all(cellfun(@isempty, reward_onset)) && ~all(cellfun(@isempty, pure_onsets))%use ITI tone for incorrect trials
    alignment_frames(event,:) = [pure_onsets{1,:}];
    left_padding(event) = 1; %used to be 4 %smallest # frames in front during reward period
    right_padding(event) = max_length_reward-1; %used to be 4%larger # frames after reward during reward period
    align_info.reward = alignment_frames(event,:);
elseif ~all(cellfun(@isempty, reward_onset))
    alignment_frames(event,reward_trial) = [reward_onset{1,:}];
    incorrect_trials = setdiff(1:length(good_trials),reward_trial);
    alignment_frames(event,incorrect_trials) = [pure_onsets{1,incorrect_trials}];
    left_padding(event) = 1;%used to be 4%min_length_reward; %smallest # frames in front during reward period
    right_padding(event) = 23;%max_length_reward-min_length_reward; %larger # frames after reward during reward period
    align_info.reward = alignment_frames(event,:);
end

event = 6; %ITI time
alignment_frames(event,:) = cellfun(@(x) x(1), {imaging_array.iti_frames});
left_padding(event) = 1;
right_padding(event) = 80;
align_info.iti = alignment_frames(event,:);

elseif varargin{1,1} == 1 %do alternative alignment! for task
    event = 1;
    alignment_frames = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 6;%min_length_stim; %smallest # frames in front
    right_padding(event) = 30;
    align_info.first_stimulus = alignment_frames;
    
    event = 2;
    alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 1;
    right_padding(event) = 30;
    align_info.second_stimulus = alignment_frames(event,:);
    
    event = 3;
    alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 1;
    right_padding(event) = 30;
    align_info.third_stimulus = alignment_frames(event,:);
    
    event = 4;
    alignment_frames(event,:) = [imaging_array.turn_frame];
    left_padding(event) = 90;
    right_padding(event) = 60; %used to be 30
    align_info.turn = alignment_frames(event,:);
    
    event = 5; 
    if all(cellfun(@isempty, reward_onset)) %use ITI tone for incorrect trials
        alignment_frames(event,:) = [pure_onsets{1,:}];
        left_padding(event) = 60; %used to be 4 %smallest # frames in front during reward period
        right_padding(event) = 60; %used to be 4%larger # frames after reward during reward period
        align_info.reward = alignment_frames(event,:);
    else
        alignment_frames(event,reward_trial) = [reward_onset{1,:}];
        incorrect_trials = setdiff(1:length(good_trials),reward_trial);
        alignment_frames(event,incorrect_trials) = [pure_onsets{1,incorrect_trials}];
        left_padding(event) = 60;%used to be 4%min_length_reward; %smallest # frames in front during reward period
        right_padding(event) = 60;%max_length_reward-min_length_reward; %larger # frames after reward during reward period
        align_info.reward = alignment_frames(event,:);
    end
    
    event = 6; %ITI time
    alignment_frames(event,:) = cellfun(@(x) x(1), {imaging_array.iti_frames});
    left_padding(event) = 60;
    right_padding(event) = 60;
    align_info.iti = alignment_frames(event,:);

elseif varargin{1,1} == 2 %do alternative alignment! for task
    event = 1;
    alignment_frames = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 6;%min_length_stim; %smallest # frames in front
    right_padding(event) = 30;
    align_info.first_stimulus = alignment_frames;
    
    event = 2;
    alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 1;
    right_padding(event) = 30;
    align_info.second_stimulus = alignment_frames(event,:);
    
    event = 3;
    alignment_frames(event,:) = cellfun(@(x) x(event),stimulus_repeats_onsets);
    left_padding(event) = 1;
    right_padding(event) = 30;
    align_info.second_stimulus = alignment_frames(event,:);
    
    % IMPORTANT!! PUTTING SOUND ONSETS FOR TURN/REWARD FOR PASSIVE!! JUST
    % TO HAVE A NUMBER - DO NOT USE EVENT 4 OR 5!!!
    %--------------------------------------------------------------------
    event = 4;
    alignment_frames(event,:) = cellfun(@(x) x(3),stimulus_repeats_onsets);
    left_padding(event) = 90;
    right_padding(event) = 60; %used to be 30
    align_info.turn = alignment_frames(event,:);
    
    event = 5; 
    alignment_frames(event,:) = cellfun(@(x) x(3),stimulus_repeats_onsets);
    left_padding(event) = 60; %used to be 4 %smallest # frames in front during reward period
    right_padding(event) = 60; %used to be 4%larger # frames after reward during reward period
    align_info.reward = alignment_frames(event,:);
    
    event = 6; %ITI time
    alignment_frames(event,:) = cellfun(@(x) x(3)+30,stimulus_repeats_onsets);
    left_padding(event) = 60;
    right_padding(event) = 60;
    align_info.iti = alignment_frames(event,:);

end








