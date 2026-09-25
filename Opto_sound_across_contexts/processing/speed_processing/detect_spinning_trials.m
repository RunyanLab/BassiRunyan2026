function spinning_trials = detect_spinning_trials(imaging_array, opts)

% Returns logical vector indicating whether each trial contains substantial
% spinning / disoriented behavior.
%
% Primary criterion:
%   Large backward movement after the mouse has already progressed
%   substantially through the corridor.
%
% Secondary criterion:
%   Large angular excursion while making very little progress.

    if nargin < 2
        opts = struct();
    end

    % ============================================================
    % Adjustable thresholds
    % ============================================================

    % Ignore behavior near the very beginning of the maze
    if ~isfield(opts,'min_progress_before_check')
        opts.min_progress_before_check = 75;
    end

    % How far the mouse must move backward from its furthest point
    if ~isfield(opts,'min_backtrack')
        opts.min_backtrack = 100;
    end

    % Window for detecting spinning-in-place
    if ~isfield(opts,'spin_window_frames')
        opts.spin_window_frames = 60;
    end

    % Angular excursion within window required for spinning-in-place
    if ~isfield(opts,'min_angle_excursion')
        opts.min_angle_excursion = pi;
    end

    % Maximum amount of y movement allowed for spinning-in-place
    if ~isfield(opts,'max_y_range')
        opts.max_y_range = 20;
    end


    % ============================================================
    % Loop through trials
    % ============================================================

    spinning_trials = false(numel(imaging_array),1);

    for t = 1:numel(imaging_array)

        y = imaging_array(t).y_position(:);
        a = imaging_array(t).view_angle(:);

        if isempty(y) || isempty(a) || numel(y) ~= numel(a)
            continue
        end

        % Make angle continuous if it wraps at +/- pi
        a = unwrap(a);

        % --------------------------------------------------------
        % 1. LARGE BACKTRACKING
        % --------------------------------------------------------

        % Furthest y-position reached up to every frame
        running_max_y = cummax(y);

        % Distance mouse has moved backward from furthest point
        backtrack = running_max_y - y;

        % Only examine behavior after meaningful forward progress
        valid = running_max_y >= opts.min_progress_before_check;

        big_backtrack = any( ...
            backtrack(valid) >= opts.min_backtrack ...
        );


        % --------------------------------------------------------
        % 2. SPINNING IN PLACE
        % --------------------------------------------------------

        W = opts.spin_window_frames;

        spin_in_place = false;

        if numel(y) >= W

            % Range rather than summed derivative:
            % avoids accumulating lots of tiny angular jitter
            angle_range = ...
                movmax(a,[W-1 0]) - movmin(a,[W-1 0]);

            y_range = ...
                movmax(y,[W-1 0]) - movmin(y,[W-1 0]);

            stationary_rotation = ...
                angle_range >= opts.min_angle_excursion & ...
                y_range <= opts.max_y_range & ...
                running_max_y >= opts.min_progress_before_check;

            spin_in_place = any(stationary_rotation);

        end


        % --------------------------------------------------------
        % Final classification
        % --------------------------------------------------------

        spinning_trials(t) = big_backtrack || spin_in_place;

    end

end
% function spinning_trials = detect_spinning_trials(imaging_array, opts)
% % Returns logical vector indicating whether each trial contains spinning.
% 
%     if nargin < 2
%         opts = struct();
%     end
% 
%     % Adjustable thresholds
%     if ~isfield(opts,'window_frames'), opts.window_frames = 30; end
%     if ~isfield(opts,'min_angle_change'), opts.min_angle_change = 2; end
%     if ~isfield(opts,'max_forward_progress'), opts.max_forward_progress = 1; end
%     if ~isfield(opts,'min_angle_step'), opts.min_angle_step = 0.03; end
% 
%     W = opts.window_frames;
%     spinning_trials = false(numel(imaging_array),1);
% 
%     for t = 1:numel(imaging_array)
% 
%         y = imaging_array(t).y_position(:);
%         a = imaging_array(t).view_angle(:);
% 
%         if numel(y) < W || numel(a) ~= numel(y)
%             continue
%         end
% 
%         % Unwrapped angle (radians); ignore tiny changes
%         da = abs(diff(a));
%         da(da < opts.min_angle_step) = 0;
% 
%         % Cumulative angular movement over sliding windows
%         angle_sum = movsum([0; da], [W-1 0]);
% 
%         % Forward progress over each window
%         dy = y - [nan(W,1); y(1:end-W)];
% 
%         % Spinning: substantial rotation with little forward progress
%         idx = (W+1):numel(y);
% 
%         if any(angle_sum(idx) >= opts.min_angle_change & ...
%                dy(idx) <= opts.max_forward_progress)
%             spinning_trials(t) = true;
%         end
%     end
% end