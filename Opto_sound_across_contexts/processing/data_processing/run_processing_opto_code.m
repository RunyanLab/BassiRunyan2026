addpath(genpath('C:\Code\Github\Opto-analysis'));
mouse= 'LD2-1L';
date='2026-08-13';
server='w:'; %\\runyan-fs-01\runyan2';%'\\136.142.49.178\runyan5';
Runyan5 = 'V:';
rerun = 0;% reload data to redo dff etc
%mouse_date = {'HA10-1L\2023-03-27-session2\session2','HA10-1L\2023-02-21','HA10-1L\2023-04-02','HA11-1R\2023-03-27','HA11-1R\2023-04-05'}
%done: mouse_date = {'GE4-1L\2022-10-18','GE4-1L\2022-10-20','GE4-1L\2022-10-25','GE7-1L1R\2022-10-20','GE7-1L1R\2022-12-20','GS8-00\2022-11-01','GS8-00\2022-11-23'};

directory= strcat(server,'\Connie\RawData\',num2str(mouse),'\',num2str(date),'\suite2p\plane0\Fall.mat');
load(directory,'F','Fneu','iscell','stat');
cd(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\'));

if rerun == 1
    load( strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\bad_frames_dff.mat'));
    load( strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\dff.mat'));
    save('dff_old_outputs','bad_frames','dff');
end
%% find bad frames using raw F from suite2p cells
min_threshold = 50; %has to be below this number to be detected as bad frame
baselineF = 200;
[bad_frames,bad_frames_all,cel_pos] = find_bad_frames_v2(server,[mouse '\' date],min_threshold,baselineF,F,stat,0);
% save('bad_frames_outputs','bad_frames','bad_frames_all','cel_pos');
% save('bad_frames_dff','bad_frames'); %save original bad frames used for dff
% save('bad_frames_inputs','min_threshold','baselineF');%,'F','Fneu')

%% dff!
%(mouse_date,server,F,Fneu,iscell,bad_frames)
edge_interpolate  = [1,2];%[1,3]; %how much to add on either side of bad_frames for interpolation! (first one will be negative)
% as of 1/7/24 [1,3] was last used
[dff,fpreprocessed] = pydff_optov2([mouse '\' date],server,F,Fneu,iscell,bad_frames,edge_interpolate);
save('dff_outputs','dff','bad_frames','edge_interpolate') %save outputs inside dff_outputs

%% determine opto vs control trials!
imaging_base_path=[server '\Connie\RawData\' mouse '\' date '\'];
sync_base_path = strcat(server,'\Connie\RawData\',num2str(mouse),'\wavesurfer\',num2str(date),'\'); 

addpath(genpath('C:\Code\Align_signals_imaging'))
[alignment_info] = get_frame_times(imaging_base_path, sync_base_path, [], 7,1,[],[]); %7 is res galvo channel in investigator
%[alignment_info] = get_frame_times(imaging_base_path, sync_base_path, microscope_id, channel_number,plot_on,correction_info,skip_file)

d1 = datetime(date);
d2 = datetime('2023-05-23'); %when sensors where changed in the investigator
if d1 > d2
    load(strcat(Runyan5,'\Connie\ball_calibration_summer2023\calibration_info.mat'));% may to sept 2023
    calibration_info.pitchoffset = calibration_info.pitchoffset*-1;
else
    load('Y:\Connie\ball_calibration_digidata\calibration_info.mat'); % april to sept 2022
end
raw_velocity=get_velocity(alignment_info,calibration_info,sync_base_path); 

corrected_velocity=correct_velocity(raw_velocity,calibration_info); 

mkdir(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date)))
cd(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date)));
save ('alignment_info','alignment_info');
save ('corrected_velocity','corrected_velocity');

[velocity_vector,velocity_smooth] = calculate_velocity_vector(mouse, date,corrected_velocity,server);

fprintf(['\nNumber of total frames in F vs in sync data: ' num2str(length(F)-sum(cellfun(@length,{alignment_info.frame_times}))) '\n'])
%% if suite2p frames do not match sync frames
% due to data overrun error for example
if sum(cellfun(@length,{alignment_info.frame_times})) < length(F)
    cd(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date)));
    save ('unadjusted_data','dff','F');
    dff = adjust_data_to_sync(dff,alignment_info); %shortens data to match number of frames in sync
    F = adjust_data_to_sync(F,alignment_info);
    save ('dff','dff');
    z_dff=zscore(dff,0,2);
    save('z_dff','z_dff');
    [bad_frames,bad_frames_all,cel_pos] = find_bad_frames_v2(server,[mouse '\' date],min_threshold,baselineF,F,stat,0);
end


%% find bad_frames using sync data
LED_channel = 8;
[led, exp, nonexp] = finding_led(sync_base_path, LED_channel,alignment_info,bad_frames)
cd(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date)));

save ('exp','exp');
save ('nonexp','nonexp');

%%
before_frames = 60;
after_frames = 60;
stim_frame = before_frames+1;
session = 'spont_stim/60';%'spont_stim/60'; %60 or 30_10 ambientLED_6 %VR_stimsound; %spont_stim %WHERE FIGURES AND VARIABLES GET SAVED TO
string = '200power_amber'; %for saving figure '-25power_amber' FOR saving into photostim folder

% 1)Align datasets
[dff,deconv, bad_frames,exp,nonexp] = load_data ([mouse '/' date], server);

if bad_frames(1,1) < before_frames
    nonexp(1)=[]; %happens during the task
end

[allcells] = optoalign_function(exp, nonexp, bad_frames,dff,deconv, before_frames,after_frames); %+/-1 on either side of bad_frames
%[allcells,allcells_nogap] = optoalign_function(exp(find(ismember(exp,short_bad_frames))), nonexp(find(ismember(nonexp,short_bad_frames))), bad_frames,dff,deconv, before_frames,after_frames);
[allcells,allcells_nogap] = optoalign_function(exp, nonexp, bad_frames,dff,deconv, before_frames,after_frames);
% no_gap means I include interpolation period

%2) make heatmap of z-scored trial avg data
population_heatmap(allcells,stim_frame);

%3) find signficantly modulated cells comparing avg before and after
%(Wilcoxon signed ranked test with bonferoni correction)
[sig_opto_cells] = sig_cells(allcells, stim_frame); % compares avg 10 frames before to avg 30 frames after

%4) compare trials before and after (signed-ranked test)
before_after_avgtrials(allcells,stim_frame);

%5) save opto variables in ProcessedData and figures in results
save_opto_variables; %not a function (saves exp/nonexp/bad_frames/allcells
save_opto_figs(mouse,date,session,string,server);
% 
% server='\\136.142.49.216\runyan2';
% population_heatmap_v2(allcells,stim_frame,-0.6,1.5);
% save_opto_figs_v2(mouse, date,session,string,server)

%% for 60 do 
% load(strcat('\\136.142.49.216\',server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\bad_frames.mat')); 
% load(strcat('\\136.142.49.216\',server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\dff\deconv.mat')); 
% load(strcat('\\136.142.49.216\',server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\exp.mat')); 
% load(strcat('\\136.142.49.216\',server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\nonexp.mat'));
% [deconv_stim, deconv_control] = make_tr_cel_time_deconv(exp, nonexp, bad_frames, deconv,60,60);
% directory= strcat('\\136.142.49.216\',server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\');
% mkdir(directory);
% cd(directory);
% save('deconv_stim','deconv_stim');
% save('deconv_control','deconv_control');
%%
%FIGURES FOR CELL #n
plot_ex_cel(67,allcells,stim_frame);