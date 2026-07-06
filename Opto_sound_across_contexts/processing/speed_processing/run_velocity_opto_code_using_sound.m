function mouse_vel = run_velocity_opto_code_using_sound(chosen_mice,mouse_date,server,frames_before_event, frames_after_event,stim_info,varargin)

% optional argument passed to align_velocitiy_opto
extra_args = varargin;
%align velocity data (separated into pitch, roll and both)
%using sound means that stim = loc1 and ctrl = loc2!!! REALLY IMPORTANT!!
%different than run_velocity_opto_code beacuse I vertically concatenate left then right sounds into control velocity so I dont have to change previous plotting code (where stim and control actually meant stim andcontrol)
mouse_vel ={};
for current_dataset = chosen_mice
    mm = mouse_date(current_dataset)
    mm = mm{1,1};
    ss = server(current_dataset);
    ss = ss {1,1};
    %1) find velocity and align to frame times
    %[frames, v,velocity_cat,blockedges] = find_frames_velocity_v3(mouse,date,serverid); %v4 for specific dataset
    load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/corrected_velocity.mat')); %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
    %[velocity_vector] = calculate_velocity_vector(mouse, date,corrected_velocity); %vector using pitch/roll of concatenated velocity
    v = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/velocity_vector.mat'));
    %2) align velocity to bad_frames intervals and find velocity before trial
    [vel_before, vel_before_opto, vel_before_control,vel_both_opto,vel_both_control] = align_velocitiy_opto(v.velocity_vector, frames_before_event,frames_after_event, num2str(mm), num2str(ss),stim_info(current_dataset,:),extra_args{:});
    
    %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
    [vel_before2, vel_before_opto2, vel_before_control2,vel_both_opto2,vel_both_control2] = align_velocitiy_opto(corrected_velocity(2,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),stim_info(current_dataset,:),extra_args{:});
    
    %pitch is corrected_velocity(1,:); roll is corrected_velocity(2,:)
    [vel_before3, vel_before_opto3, vel_before_control3,vel_both_opto3,vel_both_control3] = align_velocitiy_opto(corrected_velocity(1,:), frames_before_event,frames_after_event, num2str(mm), num2str(ss),stim_info(current_dataset,:),extra_args{:});
    
    %[vel_before, vel_before_opto, vel_before_control,vel_both_opto,vel_both_control] = align_velocitiy_opto(velocity_cat, before_frames,after_frames, mouse, date, serverid);
    %cd(strcat(server,'/Connie/ProcessedData/',num2str(mouse),'/',num2str(date),'/'));
    
    %save structures across datasets
    mouse_vel(current_dataset).vel_cat = v.velocity_vector; %velocity_cat;
    mouse_vel(current_dataset).both_control = [vel_both_control];
    mouse_vel(current_dataset).both_opto = [vel_both_opto];
    
    
    mouse_vel(current_dataset).vel_cat_roll = corrected_velocity(2,:); %velocity_cat;
    mouse_vel(current_dataset).both_control_roll = [vel_both_control2];
    mouse_vel(current_dataset).both_opto_roll = [vel_both_opto2];
    
    
    mouse_vel(current_dataset).vel_cat_pitch = corrected_velocity(1,:); %velocity_cat;
    mouse_vel(current_dataset).both_control_pitch = [vel_both_control3];
    mouse_vel(current_dataset).both_opto_pitch = [vel_both_opto3];

end