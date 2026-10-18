function active_irrelevant_first = pool_active_irrelevant_first(mouse_date, server, before_after_frames)
% Align active trials whose first sound is condition 5 (irrelevant alone).
%
% .stim is aligned to that first-repeat onset.
% .ctrl uses the passive spont control: condition-1 first repeats, with the
% alignment frame shifted by +100 (pool_activity_sounds_simple.m, lines 171-175).
% The shift value is not changed. ctrl_overlap records whether another
% active sound overlaps the shifted window.

ctrl_shift_frames = 100;

active_irrelevant_first = struct();
active_irrelevant_first.ctrl_shift_frames = ctrl_shift_frames;
active_irrelevant_first.ctrl_shift_reference = 'condition_1_first_repeat';

for dataset = 1:length(mouse_date)
    mm = mouse_date(dataset);
    mm = mm{1,1};
    ss = server(dataset);
    ss = ss{1,1};

    deconv = load(strcat(num2str(ss), '/Connie/ProcessedData/', num2str(mm), '/deconv/deconv.mat'));
    load(strcat(num2str(ss), '/Connie/ProcessedData/', num2str(mm), '/dff.mat'));
    deconv = deconv.deconv;

    load(strcat(num2str(ss), '/Connie/ProcessedData/', num2str(mm), '/VR/vr_sound_frames.mat'));
    load(strcat(num2str(ss), '/Connie/ProcessedData/', num2str(mm), '/VR/imaging.mat'));
    load(strcat(num2str(ss), '/Connie/ProcessedData/', num2str(mm), '/alignment_info.mat'));

    vr_sound_frames_updated = fix_vr_sound_frames(vr_sound_frames, imaging, alignment_info, 'dir_string', 'VR');

    alignment_frames_all = vr_sound_frames_updated.corr_frames;
    trials = vr_sound_frames_updated.trial_num;
    condition = vr_sound_frames_updated.condition;
    [~, trials_first_repeat] = unique(trials);
    trials_first_repeat = trials_first_repeat(:);

    first_condition = condition(trials_first_repeat);
    irrelevant_rows = trials_first_repeat(first_condition == 5);
    ctrl_rows = trials_first_repeat(first_condition == 1);
    irrelevant_rows = irrelevant_rows(:)';
    ctrl_rows = ctrl_rows(:)';

    if isempty(irrelevant_rows)
        error('pool_active_irrelevant_first:NoCondition5', ...
            'Dataset %s has no active first repeat with condition 5.', mm);
    end
    if isempty(ctrl_rows)
        error('pool_active_irrelevant_first:NoCondition1', ...
            'Dataset %s has no active first repeat with condition 1 for the shifted control.', mm);
    end

    ctrl_overlap = count_shifted_control_overlap( ...
        alignment_frames_all, trials, ctrl_rows, ctrl_shift_frames, before_after_frames);
    if ctrl_overlap.n_windows_with_sound > 0
        warning('pool_active_irrelevant_first:ShiftOverlapsSound', ...
            ['Dataset %s: %d of %d shifted condition-1 control windows overlap another active sound. ' ...
             'The +%d frame spont shift was not changed.'], ...
            mm, ctrl_overlap.n_windows_with_sound, ctrl_overlap.n_ctrl, ctrl_shift_frames);
    end

    shifted_alignment = alignment_frames_all(:, 1);
    shifted_alignment(ctrl_rows) = alignment_frames_all(ctrl_rows, 1) + ctrl_shift_frames;

    [allcells, allcells_nogap, ~, valid_trials] = optoalign_function( ...
        irrelevant_rows, ctrl_rows, [shifted_alignment, shifted_alignment], ...
        dff, deconv, before_after_frames(1), before_after_frames(2), [0, 0]);
    [stim_matrix, ctrl_matrix, z_stim_matrix, z_ctrl_matrix] = make_tr_cel_time(allcells, 1);

    active_irrelevant_first.dff_st{dataset}.stim = stim_matrix;
    active_irrelevant_first.dff_st{dataset}.ctrl = ctrl_matrix;
    active_irrelevant_first.dff_st{dataset}.z_stim = z_stim_matrix;
    active_irrelevant_first.dff_st{dataset}.z_ctrl = z_ctrl_matrix;
    valid_stim_rows = irrelevant_rows(ismember(irrelevant_rows, valid_trials));
    valid_ctrl_rows = ctrl_rows(ismember(ctrl_rows, valid_trials));
    active_irrelevant_first.stim_info{dataset, 1} = alignment_frames_all;
    active_irrelevant_first.stim_info{dataset, 2} = intersect(valid_trials, irrelevant_rows);
    active_irrelevant_first.stim_info{dataset, 3} = intersect(valid_trials, ctrl_rows);

    [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap, 0);
    active_irrelevant_first.deconv_st_nogap{dataset}.stim = deconv_stim;
    active_irrelevant_first.deconv_st_nogap{dataset}.ctrl = deconv_control;

    [deconv_stim2, deconv_control2] = make_tr_cel_time(allcells, 0);
    active_irrelevant_first.deconv_st{dataset}.stim = deconv_stim2;
    active_irrelevant_first.deconv_st{dataset}.ctrl = deconv_control2;

    active_irrelevant_first.all_trial_info(dataset).mouse_date = mm;
    active_irrelevant_first.all_trial_info(dataset).serverid = server;
    active_irrelevant_first.all_trial_info(dataset).trial_num = trials(valid_stim_rows);
    active_irrelevant_first.all_trial_info(dataset).condition = condition(valid_stim_rows);

    active_irrelevant_first.qc(dataset).mouse_date = mm;
    active_irrelevant_first.qc(dataset).condition5_rows = irrelevant_rows;
    active_irrelevant_first.qc(dataset).condition5_codes = condition(irrelevant_rows);
    active_irrelevant_first.qc(dataset).valid_condition5_rows = active_irrelevant_first.stim_info{dataset, 2};
    active_irrelevant_first.qc(dataset).ctrl_rows = ctrl_rows;
    active_irrelevant_first.qc(dataset).valid_ctrl_rows = active_irrelevant_first.stim_info{dataset, 3};
    active_irrelevant_first.qc(dataset).n_neurons = size(stim_matrix, 2);
    active_irrelevant_first.qc(dataset).n_frames = size(stim_matrix, 3);
    active_irrelevant_first.qc(dataset).n_stim_trials = size(stim_matrix, 1);
    active_irrelevant_first.qc(dataset).n_ctrl_trials = size(ctrl_matrix, 1);
    active_irrelevant_first.qc(dataset).ctrl_overlap = ctrl_overlap;
end
end

function ctrl_overlap = count_shifted_control_overlap(corr_frames, trials, ctrl_rows, shift_frames, before_after_frames)
% Window matches optoalign_function with padding [0, 0]:
% shifted onset - before_frames through shifted onset + after_frames.

onsets = corr_frames(:, 1);
offsets = corr_frames(:, 2);
win_start = onsets(ctrl_rows) + shift_frames - before_after_frames(1);
win_end = onsets(ctrl_rows) + shift_frames + before_after_frames(2);

n_ctrl = numel(ctrl_rows);
windows_with_sound = false(1, n_ctrl);
n_overlapping_onsets = zeros(1, n_ctrl);
n_same_trial_overlaps = zeros(1, n_ctrl);

for t = 1:n_ctrl
    other = true(size(onsets));
    other(ctrl_rows(t)) = false;
    overlaps = other & onsets <= win_end(t) & offsets >= win_start(t);
    n_overlapping_onsets(t) = nnz(overlaps);
    windows_with_sound(t) = n_overlapping_onsets(t) > 0;
    same_trial = overlaps & trials == trials(ctrl_rows(t));
    n_same_trial_overlaps(t) = nnz(same_trial);
end

ctrl_overlap.n_ctrl = n_ctrl;
ctrl_overlap.n_windows_with_sound = nnz(windows_with_sound);
ctrl_overlap.n_windows_with_same_trial_sound = nnz(n_same_trial_overlaps > 0);
ctrl_overlap.n_overlapping_onsets = n_overlapping_onsets;
ctrl_overlap.n_same_trial_overlaps = n_same_trial_overlaps;
ctrl_overlap.window_start = win_start;
ctrl_overlap.window_end = win_end;
end
