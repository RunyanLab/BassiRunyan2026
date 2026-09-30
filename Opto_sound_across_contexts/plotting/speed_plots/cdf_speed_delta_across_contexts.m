function p_values = cdf_speed_delta_across_contexts(deltaLeft,deltaRight,function_params,save_data_directory)

%set bins for cdf
if function_params.abs == 1
    binss = 0:2:40;
else
    binss = -40:10:40;
end

%1) separate varibles based on contexts
for contextIdx = 1:length(function_params.contexts)
    % Assign delta variables for plotting (indexed by context)
    deltaRoll_left   = deltaLeft(contextIdx).Roll;
    deltaRoll_right  = deltaRight(contextIdx).Roll;
    deltaPitch_left  = deltaLeft(contextIdx).Pitch;
    deltaPitch_right = deltaRight(contextIdx).Pitch;
    deltaBoth_left   = deltaLeft(contextIdx).Both;
    deltaBoth_right  = deltaRight(contextIdx).Both;
    
    
    % Compute CDFs based on context
    [right_cdf{contextIdx}, ~]         = make_cdf(deltaRoll_right, binss);
    [left_cdf{contextIdx}, ~]          = make_cdf(deltaRoll_left, binss);
    [pitch_right_cdf{contextIdx}, ~]   = make_cdf(deltaPitch_right, binss);
    [pitch_left_cdf{contextIdx}, ~]    = make_cdf(deltaPitch_left, binss);

    speed_delta_axis_data(contextIdx,:) = {deltaRoll_left, deltaRoll_right, deltaPitch_left, deltaPitch_right, deltaBoth_left, deltaBoth_right};    

end

%% MAKE CDF PLOTS OF CHANGES ACROSS SPEED AXIS
% CDF plots of changes (delta) in roll and pitch across contexts! 
colors_right = function_params.right_color;%[0 0 0]; % Black for right
colors_left = function_params.left_color;%[0.5 0.5 0.5]; % Gray for left
possible_intervals = [ 20, 25]; %used for x axis labels

figure(622);clf;
set(622, 'Units', 'inches', 'Position', [0.7, 0.7, 8, 3]);
%Pitch first!
subplot(1,2,1)
hold on
for context = 1:length(function_params.contexts)
    plot(binss, pitch_right_cdf{context}, 'LineWidth', 2, 'LineStyle', function_params.context_lineStyle{context}, 'Color', colors_right, 'DisplayName', ['Right ' function_params.contexts{1, context}  ]);
    plot(binss, pitch_left_cdf{context}, 'LineWidth', 2, 'LineStyle', function_params.context_lineStyle{context}, 'Color', colors_left, 'DisplayName', ['Left ' function_params.contexts{1, context}  ]);
end
% Adjust axes and labels
ylim([0 1]);
xlim([binss(1), binss(end)]);
xticks_min = binss(1);
xticks_max = binss(end);
best_interval = utils.find_x_ticks(xticks_min, xticks_max, possible_intervals);
xticks_values = xticks_min:best_interval:xticks_max;
xticks(xticks_values);
ylabel('Cumulative Fraction');
if function_params.abs == 1
    xlabel('Speed Change');
else
    xlabel('Velocity Change');
end
title('Pitch','FontWeight','normal')
legend('Location', 'southeastoutside','box','off'); % Add legend for clarity

set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', [1, 1, 1.2, 1.2]);
utils.set_current_fig;

subplot(1,2,2) %ROLL second
hold on
for context = 1:length(function_params.contexts)
    plot(binss, right_cdf{context}, 'LineWidth', 2, 'LineStyle', function_params.context_lineStyle{context}, 'Color', colors_right, 'DisplayName', ['Right ' function_params.contexts{1, context}  ]);
    plot(binss, left_cdf{context}, 'LineWidth', 2, 'LineStyle', function_params.context_lineStyle{context}, 'Color', colors_left, 'DisplayName', ['Left ' function_params.contexts{1, context}  ]);
end
% Adjust axes and labels
ylim([0 1]);
xlim([binss(1), binss(end)]);
xticks_min = binss(1);
xticks_max = binss(end);
best_interval =utils.find_x_ticks(xticks_min, xticks_max, possible_intervals);
xticks_values = xticks_min:best_interval:xticks_max;
xticks(xticks_values);
% ylabel('Cumulative Fraction');
if function_params.abs == 1
    xlabel('Speed Change');
else
    xlabel('Velocity Change');
end
title('Roll','FontWeight','normal')
set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', [4.7, 1, 1.2, 1.2]);
utils.set_current_fig;
hold off

% do statistical comparisons across distributions of changes across contexts (here I am comparing all trials in each context)
% Initialize results
comparisons = {'deltaRoll_Left', 'deltaRoll_Right', 'deltaPitch_Left', 'deltaPitch_Right' ,'deltaBoth_left','deltaBoth_right'};

num_comparisons = numel(comparisons); % Number of comparisons
alpha = 0.05 / num_comparisons; % Bonferroni-corrected significance level

possible_tests = nchoosek(1:length(function_params.contexts),2); %comparisons across contexts!
% Initialize p-value storage (structured as {p-value, comparison name})
p_values = cell(size(possible_tests,1), num_comparisons, 2); % Adding an extra dimension

% Loop through each comparison category (Roll or Pitch)
for c = 1:num_comparisons
    curr_comp = comparisons{c};
    % Identify if it's a Roll or Pitch comparison
    if contains(curr_comp, 'Roll')
        matching_comparisons = find(contains(comparisons, 'Roll')); % Get Roll comparisons
    elseif contains(curr_comp, 'Pitch')
        matching_comparisons = find(contains(comparisons, 'Pitch')); % Get Pitch comparisons
    elseif contains(curr_comp, 'Both')
        matching_comparisons = find(contains(comparisons, 'Both')); % Get Pitch comparisons
    end
    % Only perform tests within the same category (Roll/Roll or Pitch/Pitch)
    if ismember(c, matching_comparisons)
        for t = 1:size(possible_tests,1)
            % Perform rank-sum test within Roll or Pitch category
            if ~isempty(speed_delta_axis_data{possible_tests(t,1),c}) && ~isempty(speed_delta_axis_data{possible_tests(t,2),c})
                p_val = ranksum(speed_delta_axis_data{possible_tests(t,1),c}, ...
                                speed_delta_axis_data{possible_tests(t,2),c});
                % Store p-value and comparison string
                p_values{t,c,1} = p_val;  % Store p-value
                p_values{t,c,2} = sprintf('%s: Context %d vs %d', curr_comp, possible_tests(t,1), possible_tests(t,2)); % Store string
                % Print results
                fprintf('Comparison: %s between contexts %d and %d\n', curr_comp, ...
                        possible_tests(t,1), possible_tests(t,2));
                fprintf('p-value: %.4f (Significant: %d)\n', p_val, p_val < alpha);
            else
                fprintf('p-value: %.4f (Significant: %d)\n', p_val, p_val < alpha);
            end
        end
    end
end



if ~isempty(save_data_directory)
    mkdir(save_data_directory)

    cd(save_data_directory)
    exportgraphics(figure(622),['cdf_difference_roll_vs_pitch_acrosscontext_' strcat(num2str(function_params.frames_before_stim),'-', num2str(function_params.frames_after_stim),'_abs_',num2str(function_params.abs)) '.pdf'], 'ContentType', 'vector');
    saveas(figure(622),['cdf_difference_roll_vs_pitch_acrosscontext_' strcat(num2str(function_params.frames_before_stim),'-', num2str(function_params.frames_after_stim),'_abs_',num2str(function_params.abs)) '.fig']);
    
    save_str=strcat("context_stats_changes_roll_vs_pitch_" ,num2str(function_params.frames_before_stim),"-", num2str(function_params.frames_after_stim),'_abs_',num2str(function_params.abs), ".mat");
    save(save_str, 'p_values');
end

