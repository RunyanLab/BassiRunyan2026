%% RUNNING KINEMATICS: SOUND+PHOTOSTIM VS SOUND-ALONE TRIALS WITHIN EACH CONTEXT
% Question: are there systematic differences in running kinematics between
% sound+photostim and sound-alone trials within Active or Passive, and are
% those differences larger / structured differently in Passive than Active?
% (could they contribute to the weak Passive > Active photostim modulation in
% the running-only GLM predictions?)
%
% Velocity is aligned to the first sound exactly as in section 2 of
% run_speed_event_aligned_analysis.m (run_velocity_opto_code_using_sound):
%   both_opto*    -> sound+photostim trials (opto_output_all)
%   both_control* -> sound-alone trials     (sound_onsets_all)
% Rows of both_opto*/both_control* are Active trials followed by Passive
% trials, indexed by stim_trials_context / ctrl_trials_context.
% Pitch and roll are kept SIGNED. 'Both' is total speed (velocity_vector).

%% 0) SETUP
addpath(genpath('C:\Code\Github\BassiRunyan2025\Opto_sound_across_contexts\'))
load('V:\Connie\results\opto_2025\context\running\info.mat');

[speed_params,~] = get_speed_params(1); %control_or_opto
speed_params.chosen_mice = [1:25];

save_dir = 'W:/Connie/results/Bassi2025/fig3/running_updated/stim_vs_ctrl_behavior';
if ~isempty(save_dir) && ~exist(save_dir,'dir')
    mkdir(save_dir);
end

beh_params = struct();
beh_params.chosen_mice = speed_params.chosen_mice;
beh_params.contexts = speed_params.contexts; % {'Active','Passive'}
beh_params.contexts_colors = speed_params.contexts_colors; % sound-alone color per context (black/gray)
beh_params.stim_color = [0.9 0.6 0]; % yellow (opto color in get_speed_params(0))
beh_params.trial_type_labels = {'Sound alone','Sound+photostim'};
beh_params.movement_types  = {'Pitch','Roll','Both'};
beh_params.movement_fields = {'_pitch','_roll',''}; % suffix appended to both_opto / both_control
beh_params.movement_labels = {'Pitch','Roll','Total Speed'};
beh_params.stim_frame = speed_params.stim_frame; % last frame before the sound/photostim gap
beh_params.frames_before_stim = speed_params.frames_before_stim; % 15 frames (0.5 s)
beh_params.frames_after_stim = 30; % 30 frames (1 s) ~ length of neural MI post window; speed_params uses 15
beh_params.pre_window  = beh_params.stim_frame - beh_params.frames_before_stim : beh_params.stim_frame - 1;
beh_params.post_window = beh_params.stim_frame + 1 : beh_params.stim_frame + beh_params.frames_after_stim;
beh_params.windows = {'pre','post','change'}; % change = post - pre (within trial type)
beh_params.balance_sides = 1; % average left and right sound trials separately, then average (as process_aligned_vel_all_axis)
beh_params.min_trials = 3; % min valid trials per trial type, context and session
beh_params.n_permutations = 10000;
beh_params.max_n_exact = 12; % use exact paired permutation test when n <= this (e.g. mouse level)
beh_params.alpha = 0.05;
beh_params.xlabel = 'Time from 1st sound (s)';
win_tag = sprintf('pre%d-%d_post%d-%d', beh_params.pre_window(1), beh_params.pre_window(end), ...
    beh_params.post_window(1), beh_params.post_window(end));

%% 1) ALIGN VELOCITY TO SOUND (skipped if already in workspace from run_speed_event_aligned_analysis)
if ~exist('mouse_vel_aligned_sounds','var') || ~exist('stim_trials_context','var') || ~exist('ctrl_trials_context','var')
    [all_celltypes, sound_data, sound_context_data] = ...
        pool_activity_sounds(info.mouse_date, info.serverid, [60,60]);
    [context_data.dff,stim_trials_context,ctrl_trials_context] = organize_2context(sound_data.active.dff_st,sound_data.passive.dff_st);
    [stim_info_combined,dff_st_combined] = combine_stim_info_dff_st(sound_context_data.active, sound_context_data.passive, sound_data.active.dff_st,sound_data.passive.dff_st);
    mouse_vel_aligned_sounds = run_velocity_opto_code_using_sound(speed_params.chosen_mice,info.mouse_date,info.serverid,speed_params.frames_before_event, speed_params.frames_after_event,stim_info_combined);
end
[~, ~, ~, ~, ~, ~, left_stim_all, left_ctrl_all, right_stim_all, right_ctrl_all] = find_sound_trials(info,stim_trials_context,ctrl_trials_context);

% mouse ids from mouse_date (e.g. 'HA11-1R/2023-05-05' -> 'HA11-1R')
mouse_ids = local_mouse_ids_from_mouse_date(info.mouse_date(beh_params.chosen_mice));
fprintf('\n%d sessions from %d mice\n', numel(mouse_ids), numel(unique(mouse_ids)));

%% 2) SESSION-AVERAGED TRACES FOR SOUND+PHOTOSTIM AND SOUND-ALONE TRIALS
nSessions = numel(beh_params.chosen_mice);
nContexts = numel(beh_params.contexts);
nMov = numel(beh_params.movement_types);
has_vel = arrayfun(@(m) numel(mouse_vel_aligned_sounds) >= m && ~isempty(mouse_vel_aligned_sounds(m).both_control), beh_params.chosen_mice);
nFrames = size(mouse_vel_aligned_sounds(beh_params.chosen_mice(find(has_vel,1))).both_control, 2);

traces = struct();
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    traces.(mov).stim = nan(nSessions, nFrames, nContexts);
    traces.(mov).ctrl = nan(nSessions, nFrames, nContexts);
end
n_trials.stim = nan(nSessions, nContexts);
n_trials.ctrl = nan(nSessions, nContexts);

for s = 1:nSessions
    m = beh_params.chosen_mice(s);
    if ~has_vel(s)
        fprintf('Dataset %d has no aligned velocity, skipping\n', m);
        continue
    end
    for c = 1:nContexts
        stim_idx = {left_stim_all{1,m}{1,c}, right_stim_all{1,m}{1,c}};
        ctrl_idx = {left_ctrl_all{1,m}{1,c}, right_ctrl_all{1,m}{1,c}};
        for mv = 1:nMov
            mov = beh_params.movement_types{mv};
            suffix = beh_params.movement_fields{mv};
            vel_stim = mouse_vel_aligned_sounds(m).(['both_opto' suffix]);
            vel_ctrl = mouse_vel_aligned_sounds(m).(['both_control' suffix]);
            [traces.(mov).stim(s,:,c), n_trials.stim(s,c)] = local_session_trace(vel_stim, stim_idx, beh_params);
            [traces.(mov).ctrl(s,:,c), n_trials.ctrl(s,c)] = local_session_trace(vel_ctrl, ctrl_idx, beh_params);
        end
    end
end

% window values (sessions x contexts) and stim - ctrl differences
vals = struct();
diffs = struct();
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    for tt = {'stim','ctrl'}
        tr = traces.(mov).(tt{1});
        pre  = reshape(mean(tr(:, beh_params.pre_window, :), 2, 'omitnan'), nSessions, nContexts);
        post = reshape(mean(tr(:, beh_params.post_window, :), 2, 'omitnan'), nSessions, nContexts);
        vals.(mov).(tt{1}).pre = pre;
        vals.(mov).(tt{1}).post = post;
        vals.(mov).(tt{1}).change = post - pre;
    end
    for w = 1:numel(beh_params.windows)
        win = beh_params.windows{w};
        diffs.(mov).(win) = vals.(mov).stim.(win) - vals.(mov).ctrl.(win);
    end
end

fprintf('\nValid trials per session (median [min max]):\n');
for c = 1:nContexts
    fprintf('  %-8s sound+stim %s | sound alone %s\n', beh_params.contexts{c}, ...
        local_median_range_str(n_trials.stim(:,c)), local_median_range_str(n_trials.ctrl(:,c)));
end

%% 3) PAIRED STATISTICS (SESSION AND MOUSE LEVEL)
% within context: sound+stim vs sound alone (paired across units)
% across contexts: (stim - ctrl) Passive vs Active, signed and magnitude (|stim - ctrl|)
levels = {'session','mouse'};
alpha_within = beh_params.alpha / (nMov * nContexts); % Bonferroni over movements x contexts (per window)
alpha_across = beh_params.alpha / nMov;               % Bonferroni over movements (per window, per measure)
stats = struct();
stat_rows = {};
for lv = 1:numel(levels)
    level = levels{lv};
    for mv = 1:nMov
        mov = beh_params.movement_types{mv};
        for w = 1:numel(beh_params.windows)
            win = beh_params.windows{w};
            for c = 1:nContexts
                ctx = beh_params.contexts{c};
                M = local_to_level([vals.(mov).stim.(win)(:,c), vals.(mov).ctrl.(win)(:,c)], mouse_ids, level);
                st = local_paired_test(M(:,1), M(:,2), beh_params);
                stats.(level).within.(mov).(win).(ctx) = st;
                stat_rows(end+1,:) = {level, mov, win, 'stim_minus_ctrl', ctx, st.n, st.mean_a, st.mean_b, ...
                    st.mean_diff, st.sem_diff, st.dz, st.p_perm, st.p_signrank, alpha_within, st.p_perm < alpha_within};
            end
            D = local_to_level(diffs.(mov).(win), mouse_ids, level); % [Active, Passive]
            measures = {'signed','magnitude'};
            for ms = 1:numel(measures)
                if strcmp(measures{ms},'signed')
                    st = local_paired_test(D(:,2), D(:,1), beh_params);
                else
                    st = local_paired_test(abs(D(:,2)), abs(D(:,1)), beh_params);
                end
                stats.(level).across.(measures{ms}).(mov).(win) = st;
                stat_rows(end+1,:) = {level, mov, win, ['passive_minus_active_' measures{ms}], 'Passive-Active', st.n, st.mean_a, st.mean_b, ...
                    st.mean_diff, st.sem_diff, st.dz, st.p_perm, st.p_signrank, alpha_across, st.p_perm < alpha_across};
            end
        end
    end
end
stats_table = cell2table(stat_rows, 'VariableNames', {'level','movement','window','comparison','context','n', ...
    'mean_a','mean_b','mean_diff','sem_diff','cohens_dz','p_perm','p_signrank','alpha_bonferroni','significant'});
stats.alpha_within = alpha_within;
stats.alpha_across = alpha_across;
stats.test = 'paired permutation test (sign flip; exact when n <= max_n_exact) + Wilcoxon signed rank';
stats.beh_params = beh_params;
stats.mouse_ids = mouse_ids;
stats.n_trials = n_trials;

if ~isempty(save_dir)
    save(fullfile(save_dir, ['stats_stim_vs_ctrl_behavior_' win_tag '.mat']), 'stats', 'stats_table', 'vals', 'diffs', 'traces');
    writetable(stats_table, fullfile(save_dir, ['stats_stim_vs_ctrl_behavior_' win_tag '.csv']));
end

%% 4) PLOTS
% trial-averaged time courses: sound+stim vs sound alone, per context
local_plot_timecourses(traces, beh_params, 671, save_dir, win_tag);
% stim - ctrl difference time course, Active vs Passive overlaid
local_plot_diff_traces(traces, beh_params, 672, save_dir, win_tag);
for lv = 1:numel(levels)
    level = levels{lv};
    % paired sound alone vs sound+stim per context, window and movement
    local_plot_paired_stim_ctrl(vals, stats.(level).within, mouse_ids, level, beh_params, alpha_within, 673 + 10*(lv-1), save_dir, win_tag);
    % Active vs Passive comparison of stim - ctrl difference (signed and magnitude)
    local_plot_context_comparison(diffs, stats.(level).across, mouse_ids, level, beh_params, alpha_across, 674 + 10*(lv-1), save_dir, win_tag);
end

%% 5) CONCISE NUMERICAL SUMMARY
for lv = 1:numel(levels)
    local_print_summary(stats.(levels{lv}), levels{lv}, beh_params, alpha_within, alpha_across);
end

%% 6) CORRELATE GLM-PREDICTED PHOTOSTIM MODULATION WITH BEHAVIORAL STIM - SOUND DIFFERENCE
% pred_ctrl_celltype_modulation_index.csv (GLM-analysis, running-only model predictions):
%   one row per dataset x context x cell_type; columns dataset ('HA11-1R_2023-05-05'),
%   context, cell_type, mean_abs_ctrl_mi, n_neurons
% Pooled = n_neurons-weighted mean across cell types (= mean |ctrl MI| over all neurons).
% Correlations are across sessions (Spearman primary, Pearson also reported), within Active,
% within Passive, and for the Passive - Active difference of both variables.
corr_params = struct();
corr_params.csv_path = fullfile(save_dir, 'pred_ctrl_celltype_modulation_index.csv'); % set to where the CSV was saved
corr_params.window = 'post'; % ctrl MI compares sound+stim vs sound alone in the post window
corr_params.cell_types = {'PYR','SOM','PV'};
corr_params.cell_type_colors = [0.37 0.75 0.49; 0.17 0.35 0.8; 0.82 0.04 0.04]; % plotting_config colors_celltypes
corr_params.groups = [{'Pooled'}, corr_params.cell_types];
corr_params.comparisons = [beh_params.contexts, {'Passive-Active'}];
corr_params.behavior_measures = {'signed','magnitude'}; % stim - sound and |stim - sound|
corr_params.min_n = 5;
corr_params.alpha = beh_params.alpha / nMov; % Bonferroni over movements (per group, comparison, measure)

if ~exist(corr_params.csv_path, 'file')
    warning('Predicted MI CSV not found (%s); skipping correlation analysis.', corr_params.csv_path);
else
    mi_tbl = readtable(corr_params.csv_path, 'TextType', 'string');
    session_keys = regexprep(string(info.mouse_date(beh_params.chosen_mice)), '[\\/]', '_');
    session_keys = session_keys(:);
    pred_mi = local_pred_mi_by_session(mi_tbl, session_keys, beh_params.contexts, corr_params.cell_types);

    corr_rows = {};
    corr_stats = struct();
    for g = 1:numel(corr_params.groups)
        grp = corr_params.groups{g};
        for cc = 1:numel(corr_params.comparisons)
            comp = corr_params.comparisons{cc};
            comp_field = matlab.lang.makeValidName(comp);
            for mv = 1:nMov
                mov = beh_params.movement_types{mv};
                for bm = 1:numel(corr_params.behavior_measures)
                    measure = corr_params.behavior_measures{bm};
                    [x, y] = local_corr_xy(diffs.(mov).(corr_params.window), pred_mi.(grp), comp, measure, beh_params.contexts);
                    st = local_corr(x, y, corr_params.min_n);
                    corr_stats.(grp).(comp_field).(mov).(measure) = st;
                    corr_rows(end+1,:) = {grp, comp, mov, measure, corr_params.window, st.n, ...
                        st.rho, st.p_spearman, st.r, st.p_pearson, corr_params.alpha, st.p_spearman < corr_params.alpha};
                end
            end
        end
    end
    corr_table = cell2table(corr_rows, 'VariableNames', {'group','comparison','movement','behavior_measure','window','n', ...
        'spearman_rho','p_spearman','pearson_r','p_pearson','alpha_bonferroni','significant'});

    % per-session merged values (predicted MI + behavioral stim - sound difference)
    merged_rows = {};
    for s = 1:nSessions
        for c = 1:nContexts
            row = {session_keys(s), mouse_ids(s), beh_params.contexts{c}};
            for g = 1:numel(corr_params.groups)
                row{end+1} = pred_mi.(corr_params.groups{g})(s,c); %#ok<SAGROW>
            end
            for mv = 1:nMov
                row{end+1} = diffs.(beh_params.movement_types{mv}).(corr_params.window)(s,c); %#ok<SAGROW>
            end
            merged_rows(end+1,:) = row; %#ok<SAGROW>
        end
    end
    merged_table = cell2table(merged_rows, 'VariableNames', [{'dataset','mouse','context'}, ...
        strcat('pred_abs_ctrl_mi_', corr_params.groups), strcat('stim_minus_sound_', beh_params.movement_types)]);

    local_plot_pred_mi_corr(diffs, pred_mi, corr_stats, beh_params, corr_params, {'Pooled'}, 691, save_dir, win_tag);
    local_plot_pred_mi_corr(diffs, pred_mi, corr_stats, beh_params, corr_params, corr_params.cell_types, 692, save_dir, win_tag);
    local_print_corr_summary(corr_stats, beh_params, corr_params);

    if ~isempty(save_dir)
        save(fullfile(save_dir, ['corr_pred_mi_vs_behavior_' win_tag '.mat']), 'corr_stats', 'corr_table', 'merged_table', 'pred_mi', 'corr_params');
        writetable(corr_table, fullfile(save_dir, ['corr_pred_mi_vs_behavior_' win_tag '.csv']));
        writetable(merged_table, fullfile(save_dir, ['merged_pred_mi_behavior_' win_tag '.csv']));
    end
end


%% ===================== LOCAL FUNCTIONS =====================
function mouse_ids = local_mouse_ids_from_mouse_date(mouse_date)
mouse_ids = strings(numel(mouse_date),1);
for d = 1:numel(mouse_date)
    parts = regexp(mouse_date{d}, '[\\/]', 'split');
    mouse_ids(d) = string(parts{1});
end
end

function [mean_trace, n_valid] = local_session_trace(vel, trial_idx_lr, beh_params)
% mean trace across trials (left/right sides averaged separately if balance_sides)
nFrames = size(vel,2);
mean_trace = nan(1,nFrames);
all_idx = [trial_idx_lr{:}];
if ~isempty(all_idx) && max(all_idx) > size(vel,1)
    error('Trial index (%d) exceeds number of aligned velocity trials (%d).', max(all_idx), size(vel,1));
end
if beh_params.balance_sides
    side_traces = nan(numel(trial_idx_lr), nFrames);
    n_valid = 0;
    for side = 1:numel(trial_idx_lr)
        rows = vel(trial_idx_lr{side}, :);
        rows = rows(~all(isnan(rows),2), :);
        n_valid = n_valid + size(rows,1);
        if ~isempty(rows)
            side_traces(side,:) = mean(rows, 1, 'omitnan');
        end
    end
    if n_valid >= beh_params.min_trials && ~any(all(isnan(side_traces),2))
        mean_trace = mean(side_traces, 1, 'omitnan');
    end
else
    rows = vel(all_idx, :);
    rows = rows(~all(isnan(rows),2), :);
    n_valid = size(rows,1);
    if n_valid >= beh_params.min_trials
        mean_trace = mean(rows, 1, 'omitnan');
    end
end
end

function M = local_to_level(session_matrix, mouse_ids, level)
% drop sessions missing any paired value; average sessions per mouse if level = 'mouse'
session_matrix(any(isnan(session_matrix),2), :) = NaN;
switch lower(level)
    case 'session'
        M = session_matrix;
    case 'mouse'
        unique_mice = unique(mouse_ids, 'stable');
        M = nan(numel(unique_mice), size(session_matrix,2));
        for i = 1:numel(unique_mice)
            M(i,:) = mean(session_matrix(mouse_ids == unique_mice(i), :), 1, 'omitnan');
        end
    otherwise
        error('level must be ''session'' or ''mouse''.');
end
end

function st = local_paired_test(a, b, beh_params)
% paired comparison a vs b (difference = a - b)
a = a(:); b = b(:);
good = ~isnan(a) & ~isnan(b);
a = a(good); b = b(good);
d = a - b;
st.n = numel(d);
st.mean_a = mean(a);
st.mean_b = mean(b);
st.mean_diff = mean(d);
st.sem_diff = std(d) / sqrt(max(st.n,1));
st.dz = mean(d) / std(d);
st.p_perm = NaN;
st.p_signrank = NaN;
if st.n < 3
    return
end
if st.n <= beh_params.max_n_exact
    st.p_perm = permutationTest_updatedcb(a, b, beh_params.n_permutations, 'paired', 1, 'exact', 1);
else
    st.p_perm = permutationTest_updatedcb(a, b, beh_params.n_permutations, 'paired', 1);
end
st.p_signrank = signrank(a, b);
end

function [m, sem] = local_mean_sem_rows(X)
m = mean(X, 1, 'omitnan');
sem = std(X, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(X), 1));
end

function lab = local_ylabel(mov)
if strcmpi(mov,'Both')
    lab = 'Speed (cm/s)';
else
    lab = 'Velocity (cm/s)';
end
end

function s = local_p_string(p, alpha)
if isnan(p)
    s = 'n/a';
elseif p < alpha
    s = sprintf('p=%.2g*', p);
else
    s = sprintf('p=%.2g', p);
end
end

function s = local_median_range_str(x)
x = x(~isnan(x));
if isempty(x)
    s = 'n/a';
else
    s = sprintf('%g [%g %g]', median(x), min(x), max(x));
end
end

function local_save_fig(fig_num, save_dir, name)
if isempty(save_dir)
    return
end
exportgraphics(figure(fig_num), fullfile(save_dir, [name '.pdf']), 'ContentType', 'vector');
saveas(figure(fig_num), fullfile(save_dir, [name '.fig']));
end

function positions = local_grid_positions(rows, extra_row_spacing)
% calculateFigurePositions(rows,7,.3) with extra vertical room for rotated tick labels + titles
positions = utils.calculateFigurePositions(rows, 7, .3, []);
for r = 2:rows
    idx = (r-1)*7 + (1:7);
    positions(idx,2) = positions(idx,2) - (r-1)*extra_row_spacing;
end
end

function local_zero_line_if_visible()
yl = ylim;
if yl(1) < 0 && yl(2) > 0
    yline(0, ':k');
end
end

function local_paired_panel(values_matrix, colors, xlabels)
% paired lines per unit + mean +/- SEM (style of plot_speed_at_onset_by_mouse)
values_matrix(any(isnan(values_matrix),2), :) = [];
hold on;
for u = 1:size(values_matrix,1)
    plot(1:2, values_matrix(u,:), '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.75);
end
for k = 1:2
    curr_values = values_matrix(:,k);
    curr_mean = mean(curr_values, 'omitnan');
    curr_sem = std(curr_values, 'omitnan') / sqrt(sum(~isnan(curr_values)));
    errorbar(k, curr_mean, curr_sem, 'o', ...
        'Color', colors(k,:), 'MarkerFaceColor', colors(k,:), 'MarkerEdgeColor', colors(k,:), ...
        'LineWidth', 1.0, 'MarkerSize', 3, 'CapSize', 6);
end
xlim([0.5 2.5]);
xticks(1:2);
xticklabels(xlabels);
xtickangle(45);
local_zero_line_if_visible();
end

function local_plot_timecourses(traces, beh_params, fig_num, save_dir, win_tag)
positions = utils.calculateFigurePositions(3, 7, .3, []);
nMov = numel(beh_params.movement_types);
nCtx = numel(beh_params.contexts);
figure(fig_num); clf;
ax = gobjects(nMov, nCtx);
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    for c = 1:nCtx
        ax(mv,c) = axes('Units', 'inches', 'Position', positions((mv-1)*7 + c, :));
        hold on;
        [ctrl_m, ctrl_s] = local_mean_sem_rows(traces.(mov).ctrl(:,:,c));
        [stim_m, stim_s] = local_mean_sem_rows(traces.(mov).stim(:,:,c));
        x = 1:numel(ctrl_m);
        shadedErrorBar(x, ctrl_m, ctrl_s, 'lineprops', {'Color', beh_params.contexts_colors(c,:), 'LineWidth', 1.5});
        shadedErrorBar(x, stim_m, stim_s, 'lineprops', {'Color', beh_params.stim_color, 'LineWidth', 1.5});
        xline(beh_params.stim_frame, '--k', 'LineWidth', 1);
        xline(beh_params.pre_window(1), ':', 'Color', [0.5 0.5 0.5]);
        xline(beh_params.post_window(end), ':', 'Color', [0.5 0.5 0.5]);
        [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(beh_params.stim_frame, numel(x));
        xticks(xticks_in);
        xticklabels(xticks_lab);
        if mv == 1
            title(sprintf('%s\n%s', beh_params.contexts{c}, beh_params.movement_labels{mv}), 'FontWeight', 'normal');
        else
            title(beh_params.movement_labels{mv}, 'FontWeight', 'normal');
        end
        if mv == nMov
            xlabel(beh_params.xlabel);
        end
        if c == 1
            ylabel(local_ylabel(mov));
        end
        set(gca, 'XTickLabelRotation', 0, 'FontSize', 7, 'Units', 'inches', 'Position', positions((mv-1)*7 + c, :));
        utils.set_current_fig;
        hold off;
    end
    yl = cell2mat(arrayfun(@(a) ylim(a), ax(mv,:), 'UniformOutput', false)');
    set(ax(mv,:), 'YLim', [min(yl(:,1)) max(yl(:,2))]);
    for c = 1:nCtx
        axes(ax(mv,c)); %#ok<LAXES>
        local_zero_line_if_visible();
        if mv == 1
            utils.place_text_labels(beh_params.trial_type_labels, [beh_params.contexts_colors(c,:); beh_params.stim_color], 0.3, 6, 'bottomleft', 0.05);
        end
    end
end
local_save_fig(fig_num, save_dir, ['stim_vs_ctrl_timecourses_' win_tag]);
end

function local_plot_diff_traces(traces, beh_params, fig_num, save_dir, win_tag)
positions = utils.calculateFigurePositions(1, 7, .3, []);
nMov = numel(beh_params.movement_types);
nCtx = numel(beh_params.contexts);
figure(fig_num); clf;
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    axes('Units', 'inches', 'Position', positions(mv, :));
    hold on;
    for c = 1:nCtx
        [m, sem] = local_mean_sem_rows(traces.(mov).stim(:,:,c) - traces.(mov).ctrl(:,:,c));
        shadedErrorBar(1:numel(m), m, sem, 'lineprops', ...
            {'Color', beh_params.contexts_colors(c,:), 'LineWidth', 1.5, 'LineStyle', '-'});
    end
    yline(0, ':k');
    xline(beh_params.stim_frame, '--k', 'LineWidth', 1);
    xline(beh_params.pre_window(1), ':', 'Color', [0.5 0.5 0.5]);
    xline(beh_params.post_window(end), ':', 'Color', [0.5 0.5 0.5]);
    [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(beh_params.stim_frame, size(traces.(mov).stim,2));
    xticks(xticks_in);
    xticklabels(xticks_lab);
    title(beh_params.movement_labels{mv}, 'FontWeight', 'normal');
    xlabel(beh_params.xlabel);
    if mv == 1
        ylabel({'Sound+photostim -', 'sound alone (cm/s)'});
    end
    if mv == nMov
        utils.place_text_labels(beh_params.contexts, beh_params.contexts_colors, 0.4, 6);
    end
    set(gca, 'XTickLabelRotation', 0, 'FontSize', 7, 'Units', 'inches', 'Position', positions(mv, :));
    utils.set_current_fig;
    hold off;
end
local_save_fig(fig_num, save_dir, ['stim_minus_ctrl_diff_traces_' win_tag]);
end

function local_plot_paired_stim_ctrl(vals, stats_within, mouse_ids, level, beh_params, alpha, fig_num, save_dir, win_tag)
% rows = windows, columns = movement x context
positions = local_grid_positions(3, 0.45);
nMov = numel(beh_params.movement_types);
nCtx = numel(beh_params.contexts);
nWin = numel(beh_params.windows);
figure(fig_num); clf;
for w = 1:nWin
    win = beh_params.windows{w};
    for mv = 1:nMov
        mov = beh_params.movement_types{mv};
        for c = 1:nCtx
            ctx = beh_params.contexts{c};
            col = (mv-1)*nCtx + c;
            axes('Units', 'inches', 'Position', positions((w-1)*7 + col, :));
            M = local_to_level([vals.(mov).ctrl.(win)(:,c), vals.(mov).stim.(win)(:,c)], mouse_ids, level);
            local_paired_panel(M, [beh_params.contexts_colors(c,:); beh_params.stim_color], {'Sound','Sound+stim'});
            p_str = local_p_string(stats_within.(mov).(win).(ctx).p_perm, alpha);
            if w == 1
                title(sprintf('%s\n%s\n%s', ctx, beh_params.movement_labels{mv}, p_str), 'FontWeight', 'normal');
            else
                title(p_str, 'FontWeight', 'normal');
            end
            if col == 1
                ylabel(sprintf('%s (cm/s)', win));
            end
            set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions((w-1)*7 + col, :));
            utils.set_current_fig;
            hold off;
        end
    end
end
local_save_fig(fig_num, save_dir, ['stim_vs_ctrl_paired_' level '_' win_tag]);
end

function local_plot_context_comparison(diffs, stats_across, mouse_ids, level, beh_params, alpha, fig_num, save_dir, win_tag)
% rows = windows; columns 1-3 = signed (stim - ctrl), columns 4-6 = |stim - ctrl|
positions = local_grid_positions(3, 0.45);
nMov = numel(beh_params.movement_types);
nWin = numel(beh_params.windows);
measures = {'signed','magnitude'};
figure(fig_num); clf;
for w = 1:nWin
    win = beh_params.windows{w};
    for ms = 1:numel(measures)
        for mv = 1:nMov
            mov = beh_params.movement_types{mv};
            col = (ms-1)*nMov + mv;
            axes('Units', 'inches', 'Position', positions((w-1)*7 + col, :));
            D = local_to_level(diffs.(mov).(win), mouse_ids, level); % [Active, Passive]
            if strcmp(measures{ms},'magnitude')
                D = abs(D);
            end
            local_paired_panel(D, beh_params.contexts_colors, beh_params.contexts);
            p_str = local_p_string(stats_across.(measures{ms}).(mov).(win).p_perm, alpha);
            if w == 1
                if strcmp(measures{ms},'signed')
                    title(sprintf('%s\nstim - sound\n%s', beh_params.movement_labels{mv}, p_str), 'FontWeight', 'normal');
                else
                    title(sprintf('%s\n|stim - sound|\n%s', beh_params.movement_labels{mv}, p_str), 'FontWeight', 'normal');
                end
            else
                title(p_str, 'FontWeight', 'normal');
            end
            if col == 1
                ylabel(sprintf('%s (cm/s)', win));
            end
            set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions((w-1)*7 + col, :));
            utils.set_current_fig;
            hold off;
        end
    end
end
local_save_fig(fig_num, save_dir, ['stim_vs_ctrl_context_comparison_' level '_' win_tag]);
end

function local_print_summary(stats_level, level, beh_params, alpha_within, alpha_across)
nMov = numel(beh_params.movement_types);
fprintf('\n================ %s LEVEL ================\n', upper(level));
fprintf('Windows: pre = frames %d-%d, post = frames %d-%d, change = post - pre\n', ...
    beh_params.pre_window(1), beh_params.pre_window(end), beh_params.post_window(1), beh_params.post_window(end));
fprintf('Sound+photostim minus sound alone (cm/s); * = p_perm < %.4f (Bonferroni)\n', alpha_within);
fprintf('%-11s %-8s %-7s %3s %10s %20s %6s %9s %9s\n', 'Movement', 'Context', 'Window', 'n', 'sound', 'stim-sound +/- SEM', 'dz', 'p_perm', 'p_srank');
any_within = false;
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    for w = 1:numel(beh_params.windows)
        win = beh_params.windows{w};
        for c = 1:numel(beh_params.contexts)
            ctx = beh_params.contexts{c};
            st = stats_level.within.(mov).(win).(ctx);
            sig = st.p_perm < alpha_within;
            any_within = any_within || sig;
            fprintf('%-11s %-8s %-7s %3d %10.3f %11.3f +/- %5.3f %6.2f %9.4f %9.4f %s\n', ...
                beh_params.movement_labels{mv}, ctx, win, st.n, st.mean_b, st.mean_diff, st.sem_diff, ...
                st.dz, st.p_perm, st.p_signrank, repmat('*', 1, sig));
        end
    end
end

fprintf('\nPassive vs Active (stim - sound); * = p_perm < %.4f (Bonferroni)\n', alpha_across);
fprintf('%-11s %-7s %3s %22s %9s %22s %9s\n', 'Movement', 'Window', 'n', 'signed P-A +/- SEM', 'p_perm', '|P|-|A| +/- SEM', 'p_perm');
any_across = false;
for mv = 1:nMov
    mov = beh_params.movement_types{mv};
    for w = 1:numel(beh_params.windows)
        win = beh_params.windows{w};
        s1 = stats_level.across.signed.(mov).(win);
        s2 = stats_level.across.magnitude.(mov).(win);
        sig1 = s1.p_perm < alpha_across;
        sig2 = s2.p_perm < alpha_across;
        any_across = any_across || sig1 || sig2;
        fprintf('%-11s %-7s %3d %12.3f +/- %5.3f %8.4f%s %12.3f +/- %5.3f %8.4f%s\n', ...
            beh_params.movement_labels{mv}, win, s1.n, s1.mean_diff, s1.sem_diff, s1.p_perm, repmat('*',1,sig1), ...
            s2.mean_diff, s2.sem_diff, s2.p_perm, repmat('*',1,sig2));
    end
end

if ~any_within
    fprintf('-> No Bonferroni-significant sound+photostim vs sound-alone difference in any context/movement/window.\n');
end
if ~any_across
    fprintf('-> No Bonferroni-significant Passive vs Active difference in the stim - sound effect.\n');
end
end

function pred_mi = local_pred_mi_by_session(mi_tbl, session_keys, contexts, cell_types)
% sessions x contexts matrices of predicted mean |ctrl MI| per cell type and pooled (n_neurons-weighted)
nS = numel(session_keys);
nC = numel(contexts);
for k = 1:numel(cell_types)
    pred_mi.(cell_types{k}) = nan(nS, nC);
end
w_sum = zeros(nS, nC);
wmi_sum = zeros(nS, nC);
has_n = ismember('n_neurons', mi_tbl.Properties.VariableNames);
datasets = string(mi_tbl.dataset);
unmatched = setdiff(unique(datasets), session_keys);
for r = 1:height(mi_tbl)
    s = find(session_keys == datasets(r));
    c = find(strcmpi(contexts, string(mi_tbl.context(r))));
    k = find(strcmpi(cell_types, string(mi_tbl.cell_type(r))));
    mi_val = mi_tbl.mean_abs_ctrl_mi(r);
    if isempty(s) || isempty(c) || isempty(k) || isnan(mi_val)
        continue
    end
    pred_mi.(cell_types{k})(s,c) = mi_val;
    if has_n
        w = mi_tbl.n_neurons(r);
    else
        w = 1;
    end
    w_sum(s,c) = w_sum(s,c) + w;
    wmi_sum(s,c) = wmi_sum(s,c) + w * mi_val;
end
pred_mi.Pooled = wmi_sum ./ w_sum;
pred_mi.Pooled(w_sum == 0) = NaN;
fprintf('\nPredicted MI CSV: %d datasets matched to sessions', sum(any(~isnan(pred_mi.Pooled),2)));
if ~isempty(unmatched)
    fprintf('; unmatched CSV datasets: %s', strjoin(unmatched, ', '));
end
fprintf('\n');
end

function [x, y] = local_corr_xy(diff_mat, mi_mat, comp, measure, contexts)
% x = behavioral stim - sound difference, y = predicted |ctrl MI| (sessions)
if strcmp(comp, 'Passive-Active')
    ia = find(strcmp(contexts, 'Active'));
    ip = find(strcmp(contexts, 'Passive'));
    if strcmp(measure, 'magnitude')
        x = abs(diff_mat(:,ip)) - abs(diff_mat(:,ia));
    else
        x = diff_mat(:,ip) - diff_mat(:,ia);
    end
    y = mi_mat(:,ip) - mi_mat(:,ia);
else
    c = find(strcmp(contexts, comp));
    x = diff_mat(:,c);
    if strcmp(measure, 'magnitude')
        x = abs(x);
    end
    y = mi_mat(:,c);
end
end

function st = local_corr(x, y, min_n)
good = ~isnan(x) & ~isnan(y);
x = x(good);
y = y(good);
st.n = numel(x);
st.rho = NaN; st.p_spearman = NaN;
st.r = NaN; st.p_pearson = NaN;
if st.n < min_n
    return
end
[st.rho, st.p_spearman] = corr(x, y, 'type', 'Spearman');
[st.r, st.p_pearson] = corr(x, y, 'type', 'Pearson');
end

function local_plot_pred_mi_corr(diffs, pred_mi, corr_stats, beh_params, corr_params, groups, fig_num, save_dir, win_tag)
% rows = Active / Passive / Passive - Active; columns = movements (signed stim - sound)
positions = local_grid_positions(3, 0.5);
nMov = numel(beh_params.movement_types);
comps = corr_params.comparisons;
pooled_only = numel(groups) == 1;
figure(fig_num); clf;
for cc = 1:numel(comps)
    comp = comps{cc};
    comp_field = matlab.lang.makeValidName(comp);
    is_diff = strcmp(comp, 'Passive-Active');
    for mv = 1:nMov
        mov = beh_params.movement_types{mv};
        pos = positions((cc-1)*7 + mv, :);
        pos(1) = pos(1) + (mv-1)*0.3; % room for y tick labels
        axes('Units', 'inches', 'Position', pos);
        hold on;
        labels = cell(1, numel(groups));
        label_colors = zeros(numel(groups), 3);
        for g = 1:numel(groups)
            grp = groups{g};
            if pooled_only && ~is_diff
                col = beh_params.contexts_colors(strcmp(beh_params.contexts, comp), :);
            elseif pooled_only
                col = [0 0 0];
            else
                col = corr_params.cell_type_colors(strcmp(corr_params.cell_types, grp), :);
            end
            [x, y] = local_corr_xy(diffs.(mov).(corr_params.window), pred_mi.(grp), comp, 'signed', beh_params.contexts);
            good = ~isnan(x) & ~isnan(y);
            scatter(x(good), y(good), 8, col, 'filled', 'MarkerFaceAlpha', 0.7);
            if sum(good) >= corr_params.min_n
                pf = polyfit(x(good), y(good), 1);
                xx = [min(x(good)) max(x(good))];
                plot(xx, polyval(pf, xx), '-', 'Color', col, 'LineWidth', 1);
            end
            st = corr_stats.(grp).(comp_field).(mov).signed;
            if pooled_only
                labels{g} = sprintf('\\rho=%.2f, %s', st.rho, local_p_string(st.p_spearman, corr_params.alpha));
            else
                labels{g} = sprintf('%s \\rho=%.2f, %s', grp, st.rho, local_p_string(st.p_spearman, corr_params.alpha));
            end
            label_colors(g,:) = col;
        end
        xline(0, ':k');
        if is_diff
            yline(0, ':k');
        end
        ax = gca;
        ax.YAxis.Exponent = 0;
        if pooled_only
            title(sprintf('%s\n%s\n%s', comp, beh_params.movement_labels{mv}, labels{1}), 'FontWeight', 'normal');
        else
            title(sprintf('%s\n%s', comp, beh_params.movement_labels{mv}), 'FontWeight', 'normal');
            utils.place_text_labels(labels, label_colors, 0.05, 5, 'topleft', 0.03, 0.1);
        end
        if is_diff
            xlabel({'stim - sound', 'P - A (cm/s)'});
        else
            xlabel('stim - sound (cm/s)');
        end
        if mv == 1
            if is_diff
                ylabel('Pred. |ctrl MI|, P - A');
            else
                ylabel('Pred. |ctrl MI|');
            end
        end
        set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', pos);
        utils.set_current_fig;
        hold off;
    end
end
if pooled_only
    name = 'corr_pred_mi_vs_behavior_pooled_';
else
    name = 'corr_pred_mi_vs_behavior_celltypes_';
end
local_save_fig(fig_num, save_dir, [name win_tag]);
end

function local_print_corr_summary(corr_stats, beh_params, corr_params)
fprintf('\n======== GLM-predicted |ctrl MI| vs behavioral stim - sound (%s window), across sessions ========\n', corr_params.window);
fprintf('Spearman rho (p); * = p < %.4f (Bonferroni over movements). |diff| uses |stim - sound| (P - A: |P| - |A|)\n', corr_params.alpha);
fprintf('%-7s %-15s %-11s %3s %22s %22s %10s\n', 'Group', 'Comparison', 'Movement', 'n', 'signed rho (p)', '|diff| rho (p)', 'Pearson r');
sig_list = {};
for g = 1:numel(corr_params.groups)
    grp = corr_params.groups{g};
    for cc = 1:numel(corr_params.comparisons)
        comp = corr_params.comparisons{cc};
        comp_field = matlab.lang.makeValidName(comp);
        for mv = 1:numel(beh_params.movement_types)
            mov = beh_params.movement_types{mv};
            s1 = corr_stats.(grp).(comp_field).(mov).signed;
            s2 = corr_stats.(grp).(comp_field).(mov).magnitude;
            sig1 = s1.p_spearman < corr_params.alpha;
            sig2 = s2.p_spearman < corr_params.alpha;
            fprintf('%-7s %-15s %-11s %3d %10.2f (%7.4f)%-2s %10.2f (%7.4f)%-2s %8.2f\n', ...
                grp, comp, beh_params.movement_labels{mv}, s1.n, s1.rho, s1.p_spearman, repmat('*',1,sig1), ...
                s2.rho, s2.p_spearman, repmat('*',1,sig2), s1.r);
            if sig1
                sig_list{end+1} = sprintf('%s %s %s signed (rho=%.2f)', grp, comp, beh_params.movement_labels{mv}, s1.rho); %#ok<AGROW>
            end
            if sig2
                sig_list{end+1} = sprintf('%s %s %s |diff| (rho=%.2f)', grp, comp, beh_params.movement_labels{mv}, s2.rho); %#ok<AGROW>
            end
        end
    end
end
if isempty(sig_list)
    fprintf('-> No Bonferroni-significant correlation between predicted |ctrl MI| and behavioral stim - sound difference.\n');
else
    fprintf('-> Significant: %s\n', strjoin(sig_list, '; '));
end
end
