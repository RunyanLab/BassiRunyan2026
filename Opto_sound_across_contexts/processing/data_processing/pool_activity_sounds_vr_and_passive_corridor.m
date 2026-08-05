function [all_celltypes,active,passive,spont,passive_corridor] = pool_activity_sounds_vr_and_passive_corridor(mouse_date,server,before_after_frames)
dff_st = {};
allcells_st=[];
dff_st_active = {};
allcells_st_active=[];

passive_corridor = [];

for dataset = 1:length(mouse_date)
    mm = mouse_date(dataset)
    mm = mm{1,1};
    ss = server(dataset);
    ss = ss {1,1};
%     load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/bad_frames.mat'));
    deconv = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/deconv/deconv.mat'));
    load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/dff.mat'));
    deconv = deconv.deconv;

    %load trial stuff
    load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/VR/vr_sound_frames.mat'));
    load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/VR/imaging.mat')); %to get trials that actually have VR
    passive_imaging = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/passive/imaging.mat')).imaging; %to get trials that actually have VR
    passive_frames = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/passive/passive_frames.mat')).passive_frames;

    %load alignment info
    load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/alignment_info.mat'));
%     passive_temp_dir = cellfun(@(x) contains(x,'passive'),{alignment_info.sync_id},'UniformOutput',false);
%     passive_dir = find([passive_temp_dir{1,:}]);

    vr_sound_frames_updated = fix_vr_sound_frames(vr_sound_frames, imaging, alignment_info);
    


    frame_lengths = [];
    frame_lengths = cellfun(@length,{alignment_info.frame_times}); %across all imaged files 
    frame_lengths = [0,cumsum(frame_lengths)];
%     passive_to_add = frame_lengths(passive_dir(1));

    % passive.resp = resp_tr;
    passive.alignment_frames_all = passive_frames.corr_frames;%+passive_to_add;
    passive.trials =  passive_frames.trial_num;
    passive.condition = passive_frames.condition;
    [~,passive.trials_first_repeat] =  unique(passive_frames.trial_num);
    passive.loc_trial = find_trial_conditions(passive_frames.condition,'first_repeat',passive.trials_first_repeat);
    

    % active.resp = resp_tr;
    
    active.alignment_frames_all = vr_sound_frames_updated.corr_frames;
    active.trials =  vr_sound_frames_updated.trial_num; %using trials that have VR data
    [~,active.trials_first_repeat] =  unique(active.trials);
    active.loc_trial = find_trial_conditions(vr_sound_frames_updated.condition,'first_repeat',active.trials_first_repeat);
    


    %do dff first!
    %passive stim is sound 1, ctrl is sound 2! for pool activity sound
    %here I am using stim as sound+noise trial and ctrl as sound alone
%     [allcells,allcells_nogap,alignment_frames] = optoalign_function(passive.sound_onsets_all{1,m}(passive.loc_trial{m,1})', passive.sound_onsets_all{1,m}(passive.loc_trial{m,2})', passive.alignment_frames_all,dff,deconv, before_after_frames(1),before_after_frames(2));
    white_noise_trials = [passive.loc_trial{3}',passive.loc_trial{4}'];
    sound_trials = [passive.loc_trial{1}',passive.loc_trial{2}'];
    [allcells,allcells_nogap,alignment_frames,valid_trials] = optoalign_function(white_noise_trials, sound_trials, [passive.alignment_frames_all(:,1),passive.alignment_frames_all(:,1)],dff,deconv, before_after_frames(1),before_after_frames(2),[0,0]);
    [stim_matrix, ctrl_matrix,z_stim_matrix, z_ctrl_matrix] = make_tr_cel_time(allcells,1); %1 is dff

    passive.dff_st{dataset}.stim = stim_matrix;
    passive.dff_st{dataset}.ctrl = ctrl_matrix; 
    passive.dff_st{dataset}.z_stim = z_stim_matrix;
    passive.dff_st{dataset}.z_ctrl =  z_ctrl_matrix;
    passive.stim_info{dataset,1} = passive.alignment_frames_all; %bad_frames
    passive.stim_info{dataset,2} = intersect(valid_trials,white_noise_trials); %exp
    passive.stim_info{dataset,3} = intersect(valid_trials,sound_trials); %nonexp
    passive.allcells_st= [allcells_st,allcells];
    [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap,0);

    passive.deconv_st_nogap{dataset}.stim = deconv_stim;
    passive.deconv_st_nogap{dataset}.ctrl = deconv_control;

    %do the same but now interpolate?
    [deconv_stim2, deconv_control2] = make_tr_cel_time(allcells,0);
    passive.deconv_st{dataset}.stim = deconv_stim2;
    passive.deconv_st{dataset}.ctrl = deconv_control2;

    % Store the collected trial info into all_trial_info
    trial_info_opto = define_trial_info_sounds(passive_imaging,passive.trials(intersect(valid_trials,white_noise_trials))); %stim/noise
    trial_info_sound_only = define_trial_info_sounds(passive_imaging,passive.trials(intersect(valid_trials,sound_trials))); %stim/noise

    passive.all_trial_info(dataset).mouse_date = mm;
    passive.all_trial_info(dataset).serverid = server;
    passive.all_trial_info(dataset).opto = trial_info_opto;
    passive.all_trial_info(dataset).sound_only = trial_info_sound_only;

    %active! stim is sound 1, ctrl is sound 2!
    white_noise_trials = [active.loc_trial{3}',active.loc_trial{4}'];
    sound_trials = [active.loc_trial{1}',active.loc_trial{2}'];
    [allcells,allcells_nogap,alignment_frames,valid_trials] = optoalign_function(white_noise_trials, sound_trials, [active.alignment_frames_all(:,1),active.alignment_frames_all(:,1)],dff,deconv, before_after_frames(1),before_after_frames(2),[0,0]);
    [stim_matrix, ctrl_matrix,z_stim_matrix, z_ctrl_matrix] = make_tr_cel_time(allcells,1); %1 is dff

    active.dff_st{dataset}.stim = stim_matrix;
    active.dff_st{dataset}.ctrl = ctrl_matrix; 
    active.dff_st{dataset}.z_stim = z_stim_matrix;
    active.dff_st{dataset}.z_ctrl =  z_ctrl_matrix;
    active.stim_info{dataset,1} = active.alignment_frames_all; %bad_frames
    active.stim_info{dataset,2} = intersect(valid_trials,white_noise_trials); %exp
    active.stim_info{dataset,3} =intersect(valid_trials,sound_trials); %nonexp
    allcells_st= [allcells_st_active,allcells];

    [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap,0);

    active.deconv_st_nogap{dataset}.stim = deconv_stim;
    active.deconv_st_nogap{dataset}.ctrl = deconv_control;

    %do the same but now interpolate?
    [deconv_stim2, deconv_control2] = make_tr_cel_time(allcells,0);
    deconv_st2{dataset}.stim = deconv_stim2;
    deconv_st2{dataset}.ctrl = deconv_control2;

    all_celltypes{dataset}.pyr_cells = 1:size(dff,1);

    % Store the collected trial info into all_trial_info
    trial_info_opto = define_trial_info_sounds(imaging,active.trials(intersect(valid_trials,white_noise_trials))); %stim/noise
    trial_info_sound_only = define_trial_info_sounds(imaging,active.trials(intersect(valid_trials,sound_trials))); %stim/noise

    active.all_trial_info(dataset).mouse_date = mm;
    active.all_trial_info(dataset).serverid = server;
    active.all_trial_info(dataset).opto = trial_info_opto;
    active.all_trial_info(dataset).sound_only = trial_info_sound_only;


    %get noise only trials
    white_noise_trials =[passive.loc_trial{5}'];
    ctrl_trials = [passive.loc_trial{1}'];
    spont_alignment = passive.alignment_frames_all(:,1);
    spont_alignment(passive.loc_trial{1}) = passive.alignment_frames_all(passive.loc_trial{1},1)+100; %align to nothing (no sound)
    [allcells_noise,allcells_nogap_noise,alignment_frames_noise,valid_trials] = optoalign_function(white_noise_trials, ctrl_trials, [spont_alignment,spont_alignment],dff,deconv, before_after_frames(1),before_after_frames(2),[0,0]);
    [stim_matrix_noise, ctrl_matrix_noise,z_stim_matrix_noise, z_ctrl_matrix_noise] = make_tr_cel_time(allcells_noise,1); %1 is dff


    spont.dff_st{dataset}.stim = stim_matrix_noise;
    spont.dff_st{dataset}.ctrl = ctrl_matrix_noise; 
    spont.dff_st{dataset}.z_stim = z_stim_matrix_noise;
    spont.dff_st{dataset}.z_ctrl =  z_ctrl_matrix_noise;
    spont.stim_info{dataset,1} = passive.alignment_frames_all; %bad_frames
    spont.stim_info{dataset,2} = intersect(valid_trials,white_noise_trials); %exp
    spont.stim_info{dataset,3} = intersect(valid_trials,ctrl_trials); %nonexp
    allcells_st= [allcells_st,allcells_noise];
    [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap_noise,0);

    spont.deconv_st_nogap{dataset}.stim = deconv_stim;
    spont.deconv_st_nogap{dataset}.ctrl = deconv_control;

    %do the same but now interpolate?
    [deconv_stim2, deconv_control2] = make_tr_cel_time(allcells_noise,0);
    spont.deconv_st{dataset}.stim = deconv_stim2;
    spont.deconv_st{dataset}.ctrl = deconv_control2;


    % add corridor stuff  (as a fourth context)
    passive_corridor_imaging = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/passive_corridor/imaging.mat')).imaging; %to get trials that actually have VR
    passive_corridor_frames = load(strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/passive_corridor/passive_corridor_sound_frames.mat')).passive_corridor_sound_frames;
    passive_corridor.alignment_frames_all = passive_corridor_frames.corr_frames;%+passive_to_add;
    passive_corridor.trials =  passive_corridor_frames.trial_num;
    passive_corridor.condition = passive_corridor_frames.condition;
    [~,passive_corridor.trials_first_repeat] =  unique(passive_corridor_frames.trial_num);
    passive_corridor.loc_trial = find_trial_conditions(passive_corridor_frames.condition,'first_repeat',passive_corridor.trials_first_repeat);


    white_noise_trials = [passive_corridor.loc_trial{3}',passive_corridor.loc_trial{4}'];
    sound_trials = [passive_corridor.loc_trial{1}',passive_corridor.loc_trial{2}'];
    [allcells,allcells_nogap,alignment_frames,valid_trials] = optoalign_function(white_noise_trials, sound_trials, [passive_corridor.alignment_frames_all(:,1),passive_corridor.alignment_frames_all(:,1)],dff,deconv, before_after_frames(1),before_after_frames(2),[0,0]);
    [stim_matrix, ctrl_matrix,z_stim_matrix, z_ctrl_matrix] = make_tr_cel_time(allcells,1); %1 is dff

    passive_corridor.dff_st{dataset}.stim = stim_matrix;
    passive_corridor.dff_st{dataset}.ctrl = ctrl_matrix; 
    passive_corridor.dff_st{dataset}.z_stim = z_stim_matrix;
    passive_corridor.dff_st{dataset}.z_ctrl =  z_ctrl_matrix;
    passive_corridor.stim_info{dataset,1} = passive_corridor.alignment_frames_all; %bad_frames
    passive_corridor.stim_info{dataset,2} = intersect(valid_trials,white_noise_trials); %exp
    passive_corridor.stim_info{dataset,3} = intersect(valid_trials,sound_trials); %nonexp
    passive_corridor.allcells_st= [allcells_st,allcells];
    [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap,0);

    passive_corridor.deconv_st_nogap{dataset}.stim = deconv_stim;
    passive_corridor.deconv_st_nogap{dataset}.ctrl = deconv_control;

    %do the same but now interpolate?
    [deconv_stim2, deconv_control2] = make_tr_cel_time(allcells,0);
    passive_corridor.deconv_st{dataset}.stim = deconv_stim2;
    passive_corridor.deconv_st{dataset}.ctrl = deconv_control2;

    % Store the collected trial info into all_trial_info
    trial_info_opto = define_trial_info_sounds(passive_corridor_imaging,passive_corridor.trials(intersect(valid_trials,white_noise_trials))); %stim/noise
    trial_info_sound_only = define_trial_info_sounds(passive_corridor_imaging,passive_corridor.trials(intersect(valid_trials,sound_trials))); %stim/noise

    passive_corridor.all_trial_info(dataset).mouse_date = mm;
    passive_corridor.all_trial_info(dataset).serverid = server;
    passive_corridor.all_trial_info(dataset).opto = trial_info_opto;
    passive_corridor.all_trial_info(dataset).sound_only = trial_info_sound_only;

end