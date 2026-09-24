function all_frames = frames_relative2general(info,imaging_st, saveorno)
for m = 1:length(imaging_st)
    good_trials = [];
    imaging = imaging_st{1,m};
    info.mouse_date{1,m}
    empty_trials = find(cellfun(@isempty,{imaging.good_trial}));
    good_trials =  setdiff(1:length(imaging),empty_trials); %only trials with all imaging data considered!
    
    load(strcat(num2str(info.server{1,m}),'/Connie/ProcessedData/',num2str(info.mouse_date{1,m}),'/alignment_info.mat'));
    previous_frames_sum = 0;  previous_frames = 0;

    frame_sums = cellfun(@(x) length(x),{alignment_info.frame_times});
    vr=[];
    for trial = 1:length(good_trials)
        if imaging(good_trials(trial)).file_num == 1
            previous_frames_temp = 0;
        else
            previous_frames_temp = sum(frame_sums(1:imaging(good_trials(trial)).file_num-1));
        end
        
        previous_frames_sum = sum(previous_frames_temp);
        vr(trial).maze = (imaging(good_trials(trial)).movement_in_imaging_time.maze_frames(1) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum: (imaging(good_trials(trial)).movement_in_imaging_time.maze_frames(end) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum;
        if ~isempty(imaging(good_trials(trial)).movement_in_imaging_time.reward_frames)
            vr(trial).reward = (imaging(good_trials(trial)).movement_in_imaging_time.reward_frames(1) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum: (imaging(good_trials(trial)).movement_in_imaging_time.reward_frames(end) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum;
        end
            vr(trial).turn = imaging(good_trials(trial)).frame_id(1) -1 + previous_frames_sum + imaging(good_trials(trial)).movement_in_imaging_time.turn_frame;
        vr(trial).ITI = (imaging(good_trials(trial)).movement_in_imaging_time.iti_frames(1) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum: (imaging(good_trials(trial)).movement_in_imaging_time.iti_frames(end) + imaging(good_trials(trial)).frame_id -1)+previous_frames_sum;
    end
    all_frames{m} = vr;
end
if saveorno == 1
mkdir([info.savepath '\data_info'])
cd([info.savepath '\data_info'])
save('all_frames','all_frames');
end

% info.mouse_date = {'HA11-1R/2023-05-05'};info.server ={'V:'};imaging_st{1,1} = imaging;info.savepath = 'V:\Connie\ProcessedData\HA11-1R\2023-05-05\VR';all_frames = frames_relative2general(info,imaging_st);