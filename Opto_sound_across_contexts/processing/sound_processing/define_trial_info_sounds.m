function trial_info_sound_only = define_trial_info_sounds(imaging, trials_to_include)
% good_trials = find(arrayfun(@(x) ~isempty(x.good_trial) && x.good_trial == 1, imaging));
good_trials = trials_to_include;
for count = 1:length(good_trials)
    trial = good_trials(count);
    trial_info_sound_only(count).correct = imaging(trial).virmen_trial_info.correct;
    trial_info_sound_only(count).left_turn = imaging(trial).virmen_trial_info.left_turn;
    trial_info_sound_only(count).condition = imaging(trial).virmen_trial_info.condition ;
    if trial_info_sound_only(count).condition > 2
        trial_info_sound_only(count).condition = trial_info_sound_only(count).condition - 2;
    end
%     trial_info_sound_only(count).is_stim_trial = imaging(trial).virmen_trial_info.is_stim_trial ;
    trial_info_sound_only(count).trial_id = trial;
%     trial_info_sound_only(count).frame_onset = imaging(trial).frame_id(1)+frames_to_add;
end



