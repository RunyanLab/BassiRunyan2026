function all_frames = frames_relative2general(info,imaging_st, saveorno,varargin)

for m = 1:length(imaging_st)
    good_trials = [];
    imaging = imaging_st{1,m};
    info.mouse_date{1,m}
    empty_trials = find(cellfun(@isempty,{imaging.good_trial}));
    good_trials =  setdiff(1:length(imaging),empty_trials); %only trials with all imaging data considered!
    
    load(strcat(num2str(info.server{1,m}),'/Connie/ProcessedData/',num2str(info.mouse_date{1,m}),'/alignment_info.mat'));
    p = inputParser;
    addParameter(p,'dir_string','passive',@(x) ischar(x) || isstring(x));
    parse(p,varargin{:});
    
    dir_string = char(p.Results.dir_string);
    
    passive_temp_dir = cellfun(@(x) contains(x,dir_string),{alignment_info.sync_id},'UniformOutput',false);
    passive_dir = find([passive_temp_dir{1,:}]); %gives the dir IDs of directory with passive in their name
    
    %add up all frames in the prior alignment structures (so things line up
    %with suite2p where all frames are concatenated together)
    frame_lengths = cellfun(@length,{alignment_info.frame_times});
    all_frame_lengths = [0,cumsum(frame_lengths)];

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
        if strcmpi(dir_string,'passive_01')
            previous_frames_sum = all_frame_lengths(passive_dir(imaging(good_trials(trial)).file_num));
        end
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