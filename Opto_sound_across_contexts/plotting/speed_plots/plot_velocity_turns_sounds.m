function plot_velocity_turns_sounds(chosen_mice,info,mouse_vel_turns,mouse_vel_pass,turn_params,trial_event_info, save_data_directory)
% Make velocity heatmaps across trials for left/right sound turns,
% with separate ACTIVE and PASSIVE subplots and a single shared colorbar.
%
% Layout:
%   Row 1: Left sound trials   (col 1 = Active, col 2 = Passive)
%   Row 2: Right sound trials  (col 1 = Active, col 2 = Passive)

for m = chosen_mice

    mouse_date = info.mouse_date;
    mm = info.mouse_date(m); %#ok<NASGU>

    % -------------------------------------------------------------
    % 1) Get aligned running data (active & passive, no concatenation)
    % -------------------------------------------------------------
    num_filler_rows = 15; % not needed any more, kept only for compatibility
    intervals_y = 20;

    has_passive = ~isempty(mouse_vel_pass);

    switch lower(turn_params.vel_type)
        case 'roll'
            % active
            active_vel_left  = mouse_vel_turns(m).both_opto_roll;
            active_vel_right = mouse_vel_turns(m).both_control_roll;
            caxis_values = [-30,30];
            ylims        = [-25,25];

            if has_passive
                passive_vel_left  = mouse_vel_pass(m).both_opto_roll;
                passive_vel_right = mouse_vel_pass(m).both_control_roll;
                caxis_values = [-40,40];
                ylims        = [-35,35];
            end

        case 'pitch'
            active_vel_left  = mouse_vel_turns(m).both_opto_pitch;
            active_vel_right = mouse_vel_turns(m).both_control_pitch;
            caxis_values = [0,60];
            ylims        = [0,60];

            if has_passive
                passive_vel_left  = mouse_vel_pass(m).both_opto_pitch;
                passive_vel_right = mouse_vel_pass(m).both_control_pitch;
            end

        otherwise  % forward (speed) or generic
            active_vel_left  = mouse_vel_turns(m).both_opto;
            active_vel_right = mouse_vel_turns(m).both_control;
            caxis_values = [0,70];
            ylims        = [0,70];

            if has_passive
                passive_vel_left  = mouse_vel_pass(m).both_opto;
                passive_vel_right = mouse_vel_pass(m).both_control;
            end
    end

     % overrides (applies after passive/active logic)
    % ---- optional unified caxis mapping override ----
    if isfield(turn_params, 'caxis_map')
        
        vel = lower(turn_params.vel_type);
    
        if isfield(turn_params.caxis_map, vel)
            caxis_values = turn_params.caxis_map.(vel);
        end
    end

    % If no passive data, just make them empty
    if ~has_passive
        passive_vel_left  = [];
        passive_vel_right = [];
    end

    length_active_left  = size(active_vel_left,  1);
    length_active_right = size(active_vel_right, 1);

    % -------------------------------------------------------------
    % 2) Figure + tiledlayout: 2 (rows: left/right) x 2 (cols: active/passive)
    % -------------------------------------------------------------
    colorList = colormaps.slanCM(turn_params.colormap,100); % e.g. 'RdBu'

    % --------------------------
    %  Row 1: LEFT sound trials
    % --------------------------
% ---------- BEGIN PLOTTING BLOCK ----------

has_passive = ~isempty(mouse_vel_pass);  % true if you passed passive data
colorList   = colormaps.slanCM(turn_params.colormap,100);
colormap(colorList);

figure(111); clf;
set(gcf,'Units','inches','Position',[0.7 0.7 3.2 1.6]);

if turn_params.plot_avg == 1
    set(gcf,'Units','inches','Position',[0.7 0.7 3.4 2.6]);
    bottom      = 0.4; 
    rowGap      = 0.05;
    leftMargin  = 0.2;
else
    bottom      = 0.18;
    rowGap      = 0.1; %vertical distance between plots 
    leftMargin  = 0.1;
end
% trial counts
nA_L = size(active_vel_left,  1);
nA_R = size(active_vel_right, 1);
if has_passive
    nP_L = size(passive_vel_left,  1);
    nP_R = size(passive_vel_right, 1);
else
    nP_L = 0;
    nP_R = 0;
end

% use the max across left/right so row heights match between columns
nA = max([nA_L nA_R 1]);
nP = max([nP_L nP_R 1]);

% layout (normalized)
% leftMargin  = 0.1; %move to the left a bit, was 0.12
rightMargin = 0.15; %was 0.12
midGap      = 0.12;
% bottom      = 0.18; 
top         = 0.18; %was 0.06
% rowGap      = 0.1; %vertical distance between plots 

totalH = 1 - top - bottom;
effH   = totalH - rowGap;
fracA  = nA / (nA + nP);
fracP  = nP / (nA + nP);
H_A    = effH * fracA;
H_P    = effH * fracP;

yP = bottom;
yA = bottom + H_P + rowGap;

totalW = 1 - leftMargin - rightMargin - midGap;
W      = totalW / 2;
xL     = leftMargin;
xR     = leftMargin + W + midGap;



% create axes
axLA = axes('Position',[xL yA W H_A]);  % Left Active
axLP = axes('Position',[xL yP W H_P]);  % Left Passive
axRA = axes('Position',[xR yA W H_A]);  % Right Active
axRP = axes('Position',[xR yP W H_P]);  % Right Passive

%get x labels ready!
if isfield(turn_params,'xlabel')
    x_label = turn_params.xlabel;
else
    x_label = 'Time (s)';
end

%% ----- LEFT ACTIVE -----
axes(axLA); cla;
if ~isempty(active_vel_left)
    hold on
    imagesc(active_vel_left);
    set(axLA,'YDir','reverse','CLim',caxis_values,'FontSize',7,'FontName','Arial');
    title(axLA, {'Left Sound Trials'; 'Active'}, 'FontWeight','normal','FontSize',7);

    % stim markers
    if ~isempty(trial_event_info)
        for t = 1:nA_L
            plot(trial_event_info(m).stimulus_rel(t), t, 'ok', 'MarkerSize', 1, 'MarkerFaceColor', 'k');%'k.', 'MarkerSize',2);
        end
    end

    xline(turn_params.onset_frame,'--','Color',[0.2 0.2 0.2],'LineWidth',2);
    ylabel('Trials', 'Fontsize',7,'FontName','Arial');

    [xt, xl] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(active_vel_left,2),2);
    set(axLA,'XLim',[1 size(active_vel_left,2)],'XTick',xt,'XTickLabel',[]);

    if nA_L >= intervals_y, yidx = 1:intervals_y:nA_L; else, yidx = 1:nA_L; end
    set(axLA,'YTick',yidx,'YTickLabel',yidx);
    hold off
else
    axis(axLA,'off');
end

%% ----- LEFT PASSIVE -----
axes(axLP); cla;
if has_passive && ~isempty(passive_vel_left)
    imagesc(passive_vel_left);
    set(axLP,'YDir','reverse','CLim',caxis_values,'FontSize',7,'FontName','Arial');
    title(axLP,'Passive','FontWeight','normal','FontSize',7);

    xline(turn_params.onset_frame,'--','Color',[0.2 0.2 0.2],'LineWidth',2);
    [xt, xl] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(passive_vel_left,2),2);
    set(axLP,'XLim',[1 size(passive_vel_left,2)],'XTick',xt,'XTickLabel',xl);

    ylabel('Trials', 'Fontsize',7,'FontName','Arial');

    nP_L = size(passive_vel_left,1);
    if nP_L >= intervals_y, yidx = 1:intervals_y:nP_L; else, yidx = 1:nP_L; end
    set(axLP,'YTick',yidx,'YTickLabel',yidx);
    box off
else
    axis(axLP,'off');
    title(axLP,'Passive','FontWeight','normal');
end

xlabel(axLP,x_label,'FontSize',7,'FontName','Arial');

%% ----- RIGHT ACTIVE -----
axes(axRA); cla;
if ~isempty(active_vel_right)
    hold on
    imagesc(active_vel_right);
    set(axRA,'YDir','reverse','CLim',caxis_values,'FontSize',7,'FontName','Arial');
    title(axRA, {'Right Sound Trials'; 'Active'}, 'FontWeight','normal','FontSize',7);

    if ~isempty(trial_event_info)
        for t = 1:nA_R
            % adjust index offset if needed for your trial_event_info
            plot(trial_event_info(m).stimulus_rel(t + nA_L), t,  'ok', 'MarkerSize', 1, 'MarkerFaceColor', 'k');%'k.', 'MarkerSize',2);
        end
    end

    xline(turn_params.onset_frame,'--','Color',[0.2 0.2 0.2],'LineWidth',2);

    [xt, xl] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(active_vel_right,2),2);
    set(axRA,'XLim',[1 size(active_vel_right,2)],'XTick',xt,'XTickLabel',[]);

    if nA_R >= intervals_y, yidx = 1:intervals_y:nA_R; else, yidx = 1:nA_R; end
    set(axRA,'YTick',yidx,'YTickLabel',yidx);
    hold off
else
    axis(axRA,'off');
end

%% ----- RIGHT PASSIVE -----
axes(axRP); cla;
if has_passive && ~isempty(passive_vel_right)
    imagesc(passive_vel_right);
    set(axRP,'YDir','reverse','CLim',caxis_values,'FontSize',7,'FontName','Arial');
    title(axRP,'Passive','FontWeight','normal','FontSize',7);

    xline(turn_params.onset_frame,'--','Color',[0.2 0.2 0.2],'LineWidth',2);
    [xt, xl] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(passive_vel_right,2),2);
    set(axRP,'XLim',[1 size(passive_vel_right,2)],'XTick',xt,'XTickLabel',xl);

    nP_R = size(passive_vel_right,1);
    if nP_R >= intervals_y, yidx = 1:intervals_y:nP_R; else, yidx = 1:nP_R; end
    set(axRP,'YTick',yidx,'YTickLabel',yidx);
    box off
else
    axis(axRP,'off');
    title(axRP,'Passive','FontWeight','normal');
end


xlabel(axRP,x_label,'FontSize',7,'FontName','Arial');

% shared color limits & colorbar
set([axLA axLP axRA axRP],'CLim',caxis_values);
cbW = 0.02;
cbX = xR + W + 0.01;
cbY = yP;
cbH = totalH;
cb = colorbar('Position',[cbX cbY cbW cbH]);
switch lower(turn_params.vel_type)   % input_str = 'roll', 'pitch', or 'both'
    case 'roll'
        out_str = 'Roll Velocity (cm/s)';
    case 'pitch'
        out_str = 'Pitch Velocity (cm/s)';
    case 'both'
        out_str = 'Velocity (cm/s)';
    otherwise
        error('Unknown input: %s', input_str);
end

cb.Label.String = out_str;
cb.Label.Rotation = 270;
cb.FontSize = 7;
curr = cb.Label.Position;
shift = 2;
cb.Label.Position = [curr(1)+shift, curr(2:3)];

% ---------- END PLOTTING BLOCK ----------

%----------------------------------
    % 3) (Optional) Average traces, using the separated matrices
    %     – you can keep your shadedErrorBar code here if desired,
    %       either in a second figure or below these plots.
    % -------------------------------------------------------------
    if turn_params.plot_avg == 1
        %clear previous labels
        xlabel(axRP,'');
        xlabel(axLP,'');
%         set(gcf,'Units','inches','Position',[0.7 0.7 3.2 2]);

            % ==== 1) Create new axes UNDER the heatmap layout ====
            avgH = 0.16;            % height of avg-trace row
            avgGap = 0.06;          % spacing between heatmaps and avg-traces
            avgY = bottom - avgH - avgGap;   % below the bottom heatmaps
            avgW = W;               % same width as heatmap columns
            axLA_avg = axes('Position',[xL avgY avgW avgH]);  % Left avg
            axRA_avg = axes('Position',[xR avgY avgW avgH]);  % Right avg
            % ==== 2) LEFT AVG TRACE ====
            axes(axLA_avg); hold on
            if ~isempty(active_vel_left)
                SEM = std(active_vel_left,[],1)/sqrt(size(active_vel_left,1));
                shadedErrorBar(1:size(active_vel_left,2), ...
                               mean(active_vel_left,1), SEM, ...
                               'lineProps',{'color',turn_params.left_color_active});
            end
            if has_passive && ~isempty(passive_vel_left)
                SEM = std(passive_vel_left,[],1)/sqrt(size(passive_vel_left,1));
                shadedErrorBar(1:size(passive_vel_left,2), ...
                               mean(passive_vel_left,1), SEM, ...
                               'lineProps',{'color',turn_params.left_color_passive});
            end
            xline(turn_params.onset_frame,'--k','LineWidth',2);
            ylim(ylims)
            
            set(axLA_avg,'FontSize',7,'FontName','Arial')
            ylabel([{'Avg. Velocity'}; {'(cm/s)'}],'FontSize',7,'FontName','Arial')
            [xt,xlab] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(active_vel_left,2),2);
            set(axLA_avg,'XTick',xt,'XTickLabel',xlab)
            xlabel(x_label,'FontSize',7,'FontName','Arial');
            % ==== 3) RIGHT AVG TRACE ====
            axes(axRA_avg); hold on
            if ~isempty(active_vel_right)
                SEM = std(active_vel_right,[],1)/sqrt(size(active_vel_right,1));
                shadedErrorBar(1:size(active_vel_right,2), ...
                               mean(active_vel_right,1), SEM, ...
                               'lineProps',{'color',turn_params.right_color_active});
            end
            if has_passive && ~isempty(passive_vel_right)
                SEM = std(passive_vel_right,[],1)/sqrt(size(passive_vel_right,1));
                shadedErrorBar(1:size(passive_vel_right,2), ...
                               mean(passive_vel_right,1), SEM, ...
                               'lineProps',{'color',turn_params.right_color_passive});
            end
            xline(turn_params.onset_frame,'--k','LineWidth',2);
            ylim(ylims)
            set(axRA_avg,'FontSize',7,'FontName','Arial')
            [xt,xlab] = utils.x_axis_sec_aligned(turn_params.onset_frame,size(active_vel_right,2),2);
            set(axRA_avg,'XTick',xt,'XTickLabel',xlab)
            xlabel(x_label,'FontSize',7,'FontName','Arial');
    end

    

    % -------------------------------------------------------------
    % 4) Save figures
    % -------------------------------------------------------------
    temp = strfind(mouse_date{1,m},'/');
    if isempty(temp)
        temp = strfind(mouse_date{1,m},'\');
    end
    mouse_title = [mouse_date{1,m}(1:temp-1) '-' mouse_date{1,m}(temp+1:end)];

    if ~isempty(save_data_directory)
        if ~exist(save_data_directory,'dir')
            mkdir(save_data_directory);
        end

        if turn_params.plot_avg == 0
        % heatmap figure
        exportgraphics(figure(111), fullfile(save_data_directory, ...
            sprintf('%s_velocity_%s_example_trials_abs_%d_avg_%d_heatmaps.pdf', ...
                    mouse_title, turn_params.vel_type, turn_params.abs, turn_params.plot_avg)), ...
            'ContentType','vector');
        saveas(figure(111), fullfile(save_data_directory, ...
            sprintf('%s_velocity_%s_example_trials_abs_%d_avg_%d_heatmaps.fig', ...
                    mouse_title, turn_params.vel_type, turn_params.abs, turn_params.plot_avg)));

        % average traces figure (if plotted)
        else
            exportgraphics(figure(111), fullfile(save_data_directory, ...
                sprintf('%s_velocity_%s_example_trials_abs_%d_avg_%d_heatmaps_traces.pdf', ...
                        mouse_title, turn_params.vel_type, turn_params.abs, turn_params.plot_avg)), ...
                'ContentType','vector');
            saveas(figure(111), fullfile(save_data_directory, ...
                sprintf('%s_velocity_%s_example_trials_abs_%d_avg_%d_heatmaps_traces.fig', ...
                        mouse_title, turn_params.vel_type, turn_params.abs, turn_params.plot_avg)));
        end
    end
end
end

% function plot_velocity_turns_sounds(chosen_mice,info,mouse_vel_turns,mouse_vel_pass,turn_params,trial_event_info, save_data_directory)
% % Make heatmaps across trials (if two mouse_vel matrices given will concatenate)
% % will plot aligned velocity and trial event (stimulus_rel which is
% % actually turn relative to stimulus)
% 
% vel_aligned_right_all= {};
% vel_aligned_left_all = {};
% for m = chosen_mice %pos roll mice: [1,3,7,8,13,14,15,21,22,23]; %neg roll mice: [5,6,10,24,25] -25 has outlier points
%     mm = info.mouse_date(m)
%     mouse_date = info.mouse_date;
% 
%     vel_aligned_left = [];
%     vel_aligned_right = [];
%     num_filler_rows = 15;
%     intervals_y = 20;
%     %GET ALIGNED RUNNING DATA
%     if strcmp(turn_params.vel_type,'roll')
%         vel_aligned_left = mouse_vel_turns(m).both_opto_roll; %trials_left [varargin{1,1}{1,1}{1,m}{1,:}]
%         vel_aligned_right = mouse_vel_turns(m).both_control_roll; %trials_right [varargin{1,1}{2,1}{1,m}{1,:}]
%         caxis_values = [-30,30];
%         ylims = [-25,25];
% 
%         if ~isempty(mouse_vel_pass)
%             
%             active_vel_left = mouse_vel_turns(m).both_opto_roll; %trials_left [varargin{1,1}{1,1}{1,m}{1,:}]
%             active_vel_right = mouse_vel_turns(m).both_control_roll; %trials_right [varargin{1,1}{2,1}{1,m}{1,:}]
%             zero_mat = zeros(num_filler_rows,size(active_vel_left,2));
% 
%             length_active_left = size(active_vel_left,1);
%             length_active_right = size(active_vel_right,1);
%             passive_vel_left =  mouse_vel_pass(m).both_opto_roll;
%             passive_vel_right =  mouse_vel_pass(m).both_control_roll;
%             vel_aligned_left = [vel_aligned_left;zero_mat;passive_vel_left];
%             vel_aligned_right = [vel_aligned_right;zero_mat;passive_vel_right];
%             caxis_values = [-40,40];
%             ylims = [-35,35];
%         end
%     elseif strcmp(turn_params.vel_type,'pitch') %use pitch
%         vel_aligned_left = mouse_vel_turns(m).both_opto_pitch;
%         vel_aligned_right = mouse_vel_turns(m).both_control_pitch;
%         caxis_values = [0,60];
%         ylims = [0,60];
% 
%         if ~isempty(mouse_vel_pass)
%             active_vel_left = mouse_vel_turns(m).both_opto_pitch; %trials_left [varargin{1,1}{1,1}{1,m}{1,:}]
%             active_vel_right = mouse_vel_turns(m).both_control_pitch; %trials_right [varargin{1,1}{2,1}{1,m}{1,:}]
%             median_num = median([caxis_values(1):caxis_values(2)]);
% 
%             zero_mat = zeros(num_filler_rows,size(active_vel_left,2)); %ones(num_filler_rows,size(active_vel_left,2)) *median_num;
% 
% 
%             length_active_left = size(active_vel_left,1);
%             length_active_right = size(active_vel_right,1);
%             passive_vel_left =  mouse_vel_pass(m).both_opto_pitch;
%             passive_vel_right =  mouse_vel_pass(m).both_control_pitch;
%             vel_aligned_left = [vel_aligned_left;zero_mat;passive_vel_left];
%             vel_aligned_right = [vel_aligned_right;zero_mat;passive_vel_right];
%         end
%     else
%         vel_aligned_left = mouse_vel_turns(m).both_opto;
%         vel_aligned_right = mouse_vel_turns(m).both_control;
%         caxis_values = [0,70];
%         ylims = [0,70];
% 
%         if ~isempty(mouse_vel_pass)
%             active_vel_left = mouse_vel_turns(m).both_opto; %trials_left [varargin{1,1}{1,1}{1,m}{1,:}]
%             active_vel_right = mouse_vel_turns(m).both_control; %trials_right [varargin{1,1}{2,1}{1,m}{1,:}]
%             median_num = median([caxis_values(1):caxis_values(2)]);
% 
%             zero_mat = zeros(num_filler_rows,size(active_vel_left,2)); %ones(num_filler_rows,size(active_vel_left,2)) *median_num;
% 
%             length_active_left = size(active_vel_left,1);
%             length_active_right = size(active_vel_right,1);
%             passive_vel_left =  mouse_vel_pass(m).both_opto;
%             passive_vel_right =  mouse_vel_pass(m).both_control;
%             vel_aligned_left = [vel_aligned_left;zero_mat;passive_vel_left];
%             vel_aligned_right = [vel_aligned_right;zero_mat;passive_vel_right];
%         end
%     end
% 
%     
%     colorList= colormaps.slanCM(turn_params.colormap,100); %'RdBu'
%     vel_to_plot = vel_aligned_left;
%     figure(111); clf;
%     set(gcf, 'Units', 'inches', 'Position', [0.7, 0.7, 6, 6]); % Increase size slightly
%     colormap(colorList)
%     % Top-left plot (Roll Left Trials)
%     subplot(2,2,1)
%     hold on
%     title('Left Sound Trials','FontWeight','normal','FontName','Arial');
%     imagesc(vel_to_plot);
%     if ~isempty(mouse_vel_pass)
%         for t = 1:length_active_left
%             plot(trial_event_info(m).stimulus_rel(t), t, 'ok', 'MarkerSize', 1, 'MarkerFaceColor', 'k');
%         end
%     end
%     xline(turn_params.onset_frame, '--k','LineWidth',2); % Add vertical line
% 
%     [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(turn_params.onset_frame, size(vel_to_plot, 2), 2);
%     xticks(xticks_in);
%     xticklabels(xticks_lab);
%     xlim([1 size(vel_to_plot, 2)])
%     ylim([1 size(vel_to_plot, 1)])
%     if ~isempty(mouse_vel_pass)
%         % Adjust Y-axis to exclude filler
%         all_trials = [1:size(vel_aligned_left,1)];
%         trials_used = [1:length_active_left, (length_active_left + num_filler_rows + 1):size(vel_aligned_left,1)];
%         mod_trials = trials_used(mod(trials_used, intervals_y) == 0);
%         ytick_positions = all_trials(mod_trials);
%     %     ytick_positions = round((linspace(trials_used(1),trials_used(end),4)));
%         yticks(mod_trials);
%         yticklabels(ytick_positions); % Active + Passive only
%     end
% 
%     caxis(caxis_values);
%     ylabel('Trials')
%     % Adjust position for the top-left plot (square)
%     set(gca, 'Units', 'inches', 'Position', [0.6, 4, 1.0, 1.0],'YDir', 'reverse'); %flip Y axis to start trials from top to bottom!
%     utils.set_current_fig(7);
%     drawnow;
% %     set(gca, 'Units', 'inches', 'Position', [1, 1, 2, 2]); % Subplot centered at (2,3) with 2x2 size
% %     set(gca, 'Position', [0.05, 0.55, 0.25, 0.25]); % [left, bottom, width, height]
%     % Top-right plot (Roll Right Trials)
%     vel_to_plot = vel_aligned_right;
%     subplot(2,2,2)
%     hold on
%     title('Right Sound Trials','FontWeight','normal','FontName','Arial');
%     imagesc(vel_to_plot);
%     if ~isempty(mouse_vel_pass)
%         for t = 1:length_active_right
%             plot(trial_event_info(m).stimulus_rel(t+length_active_left), t , 'ok', 'MarkerSize', 1, 'MarkerFaceColor', 'k');
%         end
%     end
% 
%     xline(turn_params.onset_frame, '--k','LineWidth',2); % Add vertical line
% 
%     [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(turn_params.onset_frame, size(vel_to_plot, 2), 2);
%     xticks(xticks_in);
%     xticklabels(xticks_lab);
%     xlim([1 size(vel_to_plot, 2)])
%     ylim([1 size(vel_to_plot, 1)])
%     if ~isempty(mouse_vel_pass)
%         % Adjust Y-axis to exclude filler
%         all_trials = [1:size(vel_aligned_right,1)];
%         trials_used = [1:length_active_right, (length_active_right + num_filler_rows + 1):size(vel_aligned_right,1)];
%         mod_trials = trials_used(mod(trials_used, intervals_y) == 0);
%         ytick_positions = all_trials(mod_trials);
%         yticks(mod_trials);
%     %     ytick_positions = round((linspace(trials_used(1),trials_used(end),4)));
%         yticklabels(ytick_positions); % Active + Passive only
%     end
%     caxis(caxis_values);
% %     ylabel('Trials')
%     set(gca, 'FontSize', 7)
%     % Adjust position for the top-right plot (square)
%     set(gca, 'Units', 'inches', 'Position', [2.0, 4, 1.0, 1.0],'YDir', 'reverse'); % [left, bottom, width, height] top = 6-0.5-height// width 1 + width first plot
%     % Add colorbar and adjust its position
%     cb = colorbar;
%     set(cb, 'Units', 'inches', 'Position', [3.1, 4, .1, 1.0]); %'Position', [.96, 0.55, 0.02, 0.3]); % Adjust colorbar position to the right
%     drawnow;
% 
%     if turn_params.plot_avg == 1;
%         % Bottom-left plot (Roll Left Speed)
%         subplot(2,2,3)
%         vel_to_plot = vel_aligned_left;
%         hold on
%         
%         if ~isempty(mouse_vel_pass)
%             SEM = std(active_vel_left) / sqrt(size(active_vel_left, 1)); % Calculate SEM
%         shadedErrorBar(1:size(active_vel_left, 2), mean(active_vel_left), SEM, ...
%             'lineProps', {'color', turn_params.left_color_active});
%         SEM = std(passive_vel_left) / sqrt(size(passive_vel_left, 1)); % Calculate SEM
%         shadedErrorBar(1:size(passive_vel_left, 2), mean(passive_vel_left), SEM, ...
%             'lineProps', {'color', turn_params.left_color_passive});
%         else
%             SEM = std(vel_to_plot) / sqrt(size(vel_to_plot, 1)); % Calculate SEM
%         shadedErrorBar(1:size(vel_to_plot, 2), mean(vel_to_plot), SEM, ...
%             'lineProps', {'color', turn_params.left_color});
%         end
%         hold off
%         xline(turn_params.onset_frame, '--k','LineWidth',2); % Add vertical line
%         xlim([1 size(vel_to_plot, 2)])
%         [xticks_in, xticks_lab] = x_axis_sec_aligned(turn_params.onset_frame, size(vel_to_plot, 2), 2);
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
%         xlabel('Time (s)')
%         ylabel('Average Velocity')
%         ylim(ylims)
%         set(gca, 'FontSize', 7)
%         % Adjust position for the bottom-left plot (rectangular)
%         set(gca, 'Units', 'inches', 'Position', [0.6, 2.75, 1.0, .75]); % [left, bottom, width, height]
%         % Bottom-right plot (Roll Right Speed)
%         subplot(2,2,4)
%         vel_to_plot = vel_aligned_right;
%         hold on
%     
%         
%         if ~isempty(mouse_vel_pass)
%             SEM = std(active_vel_right) / sqrt(size(active_vel_right, 1)); % Calculate SEM
%         shadedErrorBar(1:size(active_vel_right, 2), mean(active_vel_right), SEM, ...
%             'lineProps', {'color', turn_params.right_color_active});
%         SEM = std(passive_vel_right) / sqrt(size(passive_vel_right, 1)); % Calculate SEM
%         shadedErrorBar(1:size(passive_vel_right, 2), mean(passive_vel_right), SEM, ...
%             'lineProps', {'color', turn_params.right_color_passive});
%         else
%             SEM = std(vel_to_plot) / sqrt(size(vel_to_plot, 1)); % Calculate SEM
%         shadedErrorBar(1:size(vel_to_plot, 2), mean(vel_to_plot), SEM, ...
%             'lineProps', {'color', turn_params.right_color});
%         end
%     
%         xline(turn_params.onset_frame, '--k','LineWidth',2); % Add vertical line
%         xlim([1 size(vel_to_plot, 2)])
%         [xticks_in, xticks_lab] = x_axis_sec_aligned(turn_params.onset_frame, size(vel_to_plot, 2), 2);
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
%         xlabel('Time (s)')
%     %     ylabel('Average Speed')
%         ylim(ylims)
%         set(gca, 'FontSize', 7)
%         % Adjust position for the bottom-right plot (rectangular)
%         set(gca, 'Units', 'inches', 'Position', [2.0, 2.75, 1.0, .75]);% [left, bottom, width, height]
%     end
% 
%     temp = strfind(mouse_date{1,m},'/');
%     if isempty(temp)
%         temp = strfind(mouse_date{1,m},'\');
%     end
%     mouse_title = [mouse_date{1,m}(1:temp-1) '-' mouse_date{1,m}(temp+1:end)]
%     
%     if ~isempty(save_data_directory)
%         
%         mkdir(save_data_directory);
%         cd (save_data_directory);
%         
%         
%         exportgraphics(figure(111),strcat(mouse_title,'_velocity_',num2str(turn_params.vel_type),'_example_trials_abs_',num2str(turn_params.abs),'_avg_',num2str(turn_params.plot_avg),'.pdf'), 'ContentType', 'vector');
%         saveas(figure(111),strcat(mouse_title,'_velocity_',num2str(turn_params.vel_type),'_example_trials_abs_',num2str(turn_params.abs),'_avg_',num2str(turn_params.plot_avg),'.fig'));
%     %     exportgraphics(figure(601),strcat(mouse_title,'_speed_v_neural_trials_right_difference',strcat(num2str(frames_before_left),'-', num2str(frames_after_left)),'context',num2str(function_params.context),'_sig_cells.pdf'), 'ContentType', 'vector');
%     %     saveas(figure(601),strcat(mouse_title,'_speed_v_neural_trials_right_difference',strcat(num2str(frames_before_left),'-', num2str(frames_after_left)),'context',num2str(function_params.context),'_sig_cells.fig'));
%     end
% 
% 
% 
% end