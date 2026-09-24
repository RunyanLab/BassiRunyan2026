function [mouse_vel,trial_info_stats] = run_velocity_turn_code(chosen_mice,mouse_date,server,frames_before_event, frames_after_event,trials_to_use,align_to,varargin)
mouse_vel ={}; trial_info_stats = {};
% Default: include is_stim_trial
if isempty(varargin)
    trial_fields = {"left_turn","condition","is_stim_trial"};
else
    % If optional inputs are provided, exclude is_stim_trial
    trial_fields = {"left_turn","condition"};
end
for m = chosen_mice
    mm = mouse_date(m)
    mm = mm{1,1};
    ss = server(m);
    ss = ss {1,1};


    info2.server = {ss};
    info2.mouse_date = {mm};
    load([ss, '\Connie\ProcessedData\' mm '\VR\imaging.mat']);

    imaging_st2{1,1} = imaging;
    
    all_frames = frames_relative2general(info2,imaging_st2,0);
    [~, condition_array] = divide_trials_updated (imaging,trial_fields);
    [~,alignment_frames,~,~] = find_align_info_updated (imaging,30);

    if strcmp(align_to,'turn')
        turn_info(m,1) = {[[all_frames{1,1}.turn]',[all_frames{1,1}.turn]']}; %same value for alignment - could add 2 or 3 to make it more comparable to frames lost bc of photostim
    else
        onset_frames = [];
        for t = 1:length(alignment_frames)
            onset_frames(t) = alignment_frames(1,t)+all_frames{1,1}(t).maze(1)-1;
        end
        turn_info(m,1) = {[onset_frames',onset_frames']};
    end
    if trials_to_use ==1 %use all turns (correct/incorrect/opto or not)
        turn_info(m,2) = {[find(condition_array(:,2))]'}; %left
        turn_info(m,3) = {[find(condition_array(:,2)==0)]'}; %right turns
        trials = [find(condition_array(:,2))',find(condition_array(:,2)==0)'];
    elseif trials_to_use ==2%correct only (opto and control)
        turn_info(m,2) = {[find(condition_array(:,2) == 1 & condition_array(:,3) == 1)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 1 & condition_array(:,3) == 1)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0)'];
    elseif trials_to_use ==3%correct only & control
        turn_info(m,2) = {[find(condition_array(:,2) == 1 & condition_array(:,3) == 1 & condition_array(:,4) == 0)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 0)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 1 & condition_array(:,3) == 1 & condition_array(:,4) == 0)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 0)'];
    elseif trials_to_use ==4%correct only & opto
        turn_info(m,2) = {[find(condition_array(:,2) == 1 & condition_array(:,3) == 1 & condition_array(:,4) == 1)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 1)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 1 & condition_array(:,3) == 1 & condition_array(:,4) == 1)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 1)'];

    end


%1) find velocity and align to frame times
%[frames, v,velocity_cat,blockedges] = find_frames_velocity_v3(mouse,date,serverid); %v4 for specific dataset
load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/corrected_velocity.mat')); %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
%[velocity_vector] = calculate_velocity_vector(mouse, date,corrected_velocity); %vector using pitch/roll of concatenated velocity
v = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/velocity_vector.mat'));
%2) align velocity to bad_frames intervals and find velocity before trial
[vel_before, vel_before_opto, vel_before_control,vel_both_opto,vel_both_control] = align_velocitiy_opto(v.velocity_vector, frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:));

%pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
[vel_before2, vel_before_opto2, vel_before_control2,vel_both_opto2,vel_both_control2] = align_velocitiy_opto(corrected_velocity(2,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:));

%pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
[vel_before3, vel_before_opto3, vel_before_control3,vel_both_opto3,vel_both_control3] = align_velocitiy_opto(corrected_velocity(1,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:));

mouse_vel(m).both_opto = vel_both_opto;
mouse_vel(m).both_control = vel_both_control;

mouse_vel(m).both_opto_roll = vel_both_opto2;
mouse_vel(m).both_control_roll = vel_both_control2;

mouse_vel(m).both_opto_pitch = vel_both_opto3;
mouse_vel(m).both_control_pitch = vel_both_control3;

trial_info_stats(m).avg_turn_frames = mean(alignment_frames(4,:));
trial_info_stats(m).avg_stimuli_frames = mean(alignment_frames(1,:));
trial_info_stats(m).turn_frames = alignment_frames(4,:);
trial_info_stats(m).stimuli_frames = alignment_frames(1,:);
if strcmp(align_to,'turn')
    trial_info_stats(m).stimulus_rel = frames_before_event - [alignment_frames(4,trials)-alignment_frames(1,trials)];%define stimulus relative to turn onset
else
    trial_info_stats(m).stimulus_rel = frames_before_event + [alignment_frames(4,trials)-alignment_frames(1,trials)];%define stimulus relative to turn onset
end
trial_info_stats(m).trials = trials;
end