function general_stats = cdf_speed_avg_across_contexts(avg_speed_axis_data, function_params,save_data_directory, varargin)
%avg_speed_axis_data(context, speed axis) - ROLL = 1, PITCH = 2, BOTH = 3;
% FRAMES WERE AVERAGE ACROSS LEFT AND RIGHT TRIALS!!!!!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONAL INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

addParameter(p, 'movement_types', {'Pitch','Roll','Both'});
addParameter(p, 'bin_struct', []);

parse(p, varargin{:});

movement_types = p.Results.movement_types;
bin_struct = p.Results.bin_struct;

if isempty(bin_struct)
    %0) define bins for cdf
    if function_params.abs == 1

        bin_struct.Pitch = 0:2:60;
        bin_struct.Roll = 0:2:40;
        bin_struct.Both = 20:2:60;
        bin_struct.Acceleration = 0:2:10;

    else

        bin_struct.Pitch = -10:4:60;
        bin_struct.Roll = -40:10:40;
        bin_struct.Both = -10:4:60;
        bin_struct.Acceleration = -10:2:10;

    end
end
% Compute CDF for each context and movement type
% movement_types = {'Pitch', 'Roll', 'Both'}; % Define movement types
% bin_sets = {binss2, binss, binss3, binns4}; % Corresponding bins for each movement type
% Initialize CDF storage dynamically
cdf_data = struct();
        
%SET PLOTTING PARAMS!!
possible_intervals = [20,25];

%make average trace and cdf plots!
positions = utils.calculateFigurePositions(1, 7, .3,[]); %rows and number of columns wanted followed by spacing between them (0.4)

figure(662);clf;

% Loop through movement types for plotting
for move_type = 1:length(movement_types)
    movement = movement_types{move_type};
    bins = bin_struct.(movement); % Get appropriate binning
    subplot(length(movement_types),1,move_type);
    hold on;
    % Plot each context
    for contextIdx = 1:length(function_params.contexts)
        [cdf_data.(movement)(contextIdx,:), ~] = make_cdf(avg_speed_axis_data{contextIdx, move_type}, bins);
        plot(bins, cdf_data.(movement)(contextIdx,:), 'LineWidth', 2, 'LineStyle', '-', ...
            'Color', function_params.contexts_colors(contextIdx,:));

        field_name = strcat('context',num2str(contextIdx),'_movement',num2str(move_type));
     general_stats.(field_name) = get_basic_stats(avg_speed_axis_data{contextIdx, move_type});
    end
    % Adjust axes and labels
    ylim([0 1]);
    xlim([bins(1), bins(end)]);
    if [bins(end) - bins(1)] <= 15
        xticks('auto');
    else
        best_interval = utils.find_x_ticks(bins(1), bins(end), possible_intervals);
        xticks(bins(1):best_interval:bins(end));
    end
    if function_params.abs == 1
        xlabel('Speed (cm/s)');
    else
        xlabel('Velocity (cm/s)');
    end
    if move_type == 4
        xlabel('Acc (cm/s^{2})');
    end
    if move_type == 1
        ylabel('CDF');
    end

    title(movement, 'FontWeight', 'normal');
    if move_type == 3
        title('Total Speed', 'FontWeight', 'normal');
    end
    if move_type == 3 && length(movement_types) < 4
        for contextIdx = 1:length(function_params.contexts)
            fontSize = 7;
            y_offset_base = 0.4;
            utils.place_text_labels(function_params.contexts, function_params.contexts_colors, y_offset_base, fontSize);
        end
    elseif move_type == 4
        for contextIdx = 1:length(function_params.contexts)
            fontSize = 7;
            y_offset_base = 0.4;
            utils.place_text_labels(function_params.contexts, function_params.contexts_colors, y_offset_base, fontSize);
        end
    end
    
    set(gca, 'XTickLabelRotation', 0, 'FontSize', 7, 'Units', 'inches', 'Position', positions(move_type,:));
    utils.set_current_fig;
    hold off;
    
end

%do statistical comparisons across distributions of changes across contexts
%where we do paired comparisons for each dataset!
% Initialize results
comparisons = {'Pitch across context', 'Roll across context', 'Both across contexts'};
if length(movement_types) > 3
    comparisons = {'Pitch across context', 'Roll across context', 'Both across contexts','Acceleration across contexts'};
end

num_comparisons = numel(comparisons); % Number of comparisons
alpha = 0.05 / num_comparisons; % Bonferroni-corrected significance level

possible_tests = nchoosek(1:length(function_params.contexts),2); %comparisons across contexts!
% Initialize p-value storage (structured as {p-value, comparison name})
p_values = cell(size(possible_tests,1), num_comparisons, 2); % Adding an extra dimension

% Loop through each comparison category 
for c = 1:num_comparisons
    curr_comp = comparisons{c};
    % Identify if it's a Roll or Pitch comparison
    if contains(curr_comp, 'Roll')
        matching_comparisons = find(contains(comparisons, 'Roll')); % Get Roll comparisons
    elseif contains(curr_comp, 'Pitch')
        matching_comparisons = find(contains(comparisons, 'Pitch')); % Get Pitch comparisons
    elseif contains(curr_comp, 'Both')
        matching_comparisons = find(contains(comparisons, 'Both')); % Get both comparisons
    elseif contains(curr_comp, 'Acceleration')
        matching_comparisons = find(contains(comparisons, 'Acceleration')); % Get both comparisons
    end
    % Only perform tests within the same category (Roll/Roll or Pitch/Pitch)
    if ismember(c, matching_comparisons)
        for t = 1:size(possible_tests,1)
            % Perform rank-sum test within Roll or Pitch category
%             p_val = signrank(avg_speed_axis_data{possible_tests(t,1),c}, avg_speed_axis_data{possible_tests(t,2),c});
            p_val = permutationTest_updatedcb(avg_speed_axis_data{possible_tests(t,1),c}, avg_speed_axis_data{possible_tests(t,2),c},10000,'paired',1);
            % Store p-value and comparison string
            p_values{t,c,1} = p_val;  % Store p-value
            p_values{t,c,2} = sprintf('%s: Context %d vs %d', curr_comp, possible_tests(t,1), possible_tests(t,2)); % Store string
            % Print results
            fprintf('Comparison: %s between contexts %d and %d\n', curr_comp, ...
                    possible_tests(t,1), possible_tests(t,2));
            fprintf('p-value: %.4f (Significant: %d)\n', p_val, p_val < alpha);

%             if  p_val < alpha
%                 xline_vars(1) = possible_tests(t,1); 
%                 xline_vars(2) = possible_tests(t,2); 
%                 xval = 0;  
%                 plot_pval_star(xval, .7+ct, p_stim(t), xline_vars,0.01)
%                 ct = ct+0.1;
%             end
        end
    end
end
general_stats.cdf_running_p_values = p_values;
general_stats.cdf_running_test = 'paired permutation test';


if ~isempty(save_data_directory)
    
    exportgraphics(figure(662),fullfile(save_data_directory,['avg_speed_all_axis_cdf_acrosscontext_' strcat(num2str(function_params.frames_before_event),'-', num2str(function_params.frames_after_event),'_abs_',num2str(function_params.abs)),'_movements_',num2str(length(movement_types)), '.pdf']), 'ContentType', 'vector');
    saveas(figure(662),fullfile(save_data_directory,['avg_speed_all_axis_cdf_acrosscontext_' strcat(num2str(function_params.frames_before_event),'-', num2str(function_params.frames_after_event),'_abs_',num2str(function_params.abs)),'_movements_',num2str(length(movement_types)), '.fig']));

    save_str=strcat("stats_cdf_context_stats_avg_speed_all_axis_" ,num2str(function_params.frames_before_event),"-", num2str(function_params.frames_after_event),'_abs_',num2str(function_params.abs),'_movements_',num2str(length(movement_types)), ".mat");
    save(fullfile(save_data_directory,save_str), 'general_stats');

end