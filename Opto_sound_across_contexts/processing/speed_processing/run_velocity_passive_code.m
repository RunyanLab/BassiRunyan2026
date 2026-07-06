function [mouse_vel,trial_info_stats] = run_velocity_passive_code(chosen_mice,mouse_date,server,frames_before_event, frames_after_event,trials_to_use,align_to,varargin)
addpath(genpath('C:\Code\Github\behavior-analysis2'));
mouse_vel ={}; trial_info_stats = {};
extra_args = varargin;
for m = chosen_mice
    mm = mouse_date(m)
    mm = mm{1,1};
    ss = server(m);
    ss = ss {1,1};


    info2.server = {ss};
    info2.mouse_date = {mm};
    load([ss, '\Connie\ProcessedData\' mm '\passive\imaging.mat']);

    imaging_st2{1,1} = imaging;
    
    all_frames = frames_relative2general(info2,imaging_st2,0);
    [~, condition_array] = divide_trials_updated (imaging,{"left_turn","condition"});%,"is_stim_trial"});
    [~,alignment_frames,~,~] = find_align_info_updated (imaging,30,2);

    onset_frames = [];
    for t = 1:length(alignment_frames)
        onset_frames(t) = alignment_frames(1,t)+all_frames{1,1}(t).maze(1)-1;
    end
    turn_info(m,1) = {[onset_frames',onset_frames']};
    

    if trials_to_use ==1 %use all turns (correct/incorrect/opto or not)
        turn_info(m,2) = {[find(condition_array(:,2)==0)]'}; %left
        turn_info(m,3) = {[find(condition_array(:,2)==0)]'}; %right turns
        trials = [find(condition_array(:,2))',find(condition_array(:,2)==0)'];
    elseif trials_to_use ==2%correct only (opto and control)
        turn_info(m,2) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 1)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 1 & condition_array(:,3) == 1)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0)'];
    elseif trials_to_use ==3%correct only & control
        turn_info(m,2) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 1 & condition_array(:,4) == 0)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 0)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 0 & condition_array(:,3) == 1 & condition_array(:,4) == 0)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 0)'];
    elseif trials_to_use ==4%correct only & opto
        turn_info(m,2) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 1 & condition_array(:,4) == 1)]'}; %correct left
        turn_info(m,3) = {[find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 1)]'}; %correct right turns
        trials = [find(condition_array(:,2) == 0 & condition_array(:,3) == 1 & condition_array(:,4) == 1)',find(condition_array(:,2) == 0 & condition_array(:,3) == 0 & condition_array(:,4) == 1)'];

    end


%1) find velocity and align to frame times
%[frames, v,velocity_cat,blockedges] = find_frames_velocity_v3(mouse,date,serverid); %v4 for specific dataset
load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/corrected_velocity.mat')); %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
corrected_velocity = corrected_velocity;
%[velocity_vector] = calculate_velocity_vector(mouse, date,corrected_velocity); %vector using pitch/roll of concatenated velocity
v = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/velocity_vector.mat'));
%2) align velocity to bad_frames intervals and find velocity before trial
try
    [vel_before, vel_before_opto, vel_before_control,vel_both_opto,vel_both_control] = align_velocitiy_opto(v.velocity_vector, frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:),extra_args{:});
    
    %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
    [vel_before2, vel_before_opto2, vel_before_control2,vel_both_opto2,vel_both_control2] = align_velocitiy_opto(corrected_velocity(2,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:),extra_args{:});
    
    %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
    [vel_before3, vel_before_opto3, vel_before_control3,vel_both_opto3,vel_both_control3] = align_velocitiy_opto(corrected_velocity(1,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),turn_info(m,:),extra_args{:});
    
    mouse_vel(m).both_opto = vel_both_opto;
    mouse_vel(m).both_control = vel_both_control;
    
    mouse_vel(m).both_opto_roll = vel_both_opto2;
    mouse_vel(m).both_control_roll = vel_both_control2;
    
    mouse_vel(m).both_opto_pitch = vel_both_opto3;
    mouse_vel(m).both_control_pitch = vel_both_control3;
end

trial_info_stats(m).avg_turn_frames = mean(alignment_frames(4,:));
trial_info_stats(m).avg_stimuli_frames = mean(alignment_frames(1,:));
trial_info_stats(m).turn_frames = alignment_frames(4,:);
trial_info_stats(m).stimuli_frames = alignment_frames(1,:);
trial_info_stats(m).stimulus_rel = nan;%frames_before_event + [alignment_frames(4,trials)-alignment_frames(1,trials)];%define stimulus relative to turn onset

trial_info_stats(m).trials = trials;
end