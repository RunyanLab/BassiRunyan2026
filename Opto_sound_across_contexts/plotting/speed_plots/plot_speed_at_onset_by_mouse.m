function general_stats = plot_speed_at_onset_by_mouse( ...
    avg_speed_axis_data, mouse_ids, function_params, save_data_directory, varargin)

% avg_speed_axis_data{context, movement}
%   each entry = nDatasets x 1
%
% movement:
%   1 = Pitch
%   2 = Roll
%   3 = Both / Total Speed
%
% mouse_ids
%   nDatasets x 1 cell array or string array
%
% Example:
% avg_speed_axis_data{1,3} = total speed for Active, one value per dataset
% avg_speed_axis_data{2,3} = total speed for Passive, one value per dataset


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONAL INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

addParameter(p, 'movement_types', {'Pitch','Roll','Both'});
addParameter(p, 'aggregate_by', 'mouse');
addParameter(p, 'figure_num', 663);

parse(p, varargin{:});

movement_types = p.Results.movement_types;
aggregate_by   = p.Results.aggregate_by;
figure_num     = p.Results.figure_num;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nContexts  = length(function_params.contexts);
nMovements = length(movement_types);

mouse_ids = string(mouse_ids(:));

unique_mice = unique(mouse_ids, 'stable');

general_stats = struct();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plot_values = cell(nContexts,nMovements);

for moveIdx = 1:nMovements

    for contextIdx = 1:nContexts

        curr_values = avg_speed_axis_data{contextIdx,moveIdx};
        curr_values = curr_values(:);

        switch lower(aggregate_by)

            case 'session'

                plot_values{contextIdx,moveIdx} = curr_values;

            case 'mouse'

                mouse_values = nan(length(unique_mice),1);

                for mouseIdx = 1:length(unique_mice)

                    curr_mouse_sessions = ...
                        mouse_ids == unique_mice(mouseIdx);

                    mouse_values(mouseIdx) = ...
                        mean(curr_values(curr_mouse_sessions), 'omitnan');

                end

                plot_values{contextIdx,moveIdx} = mouse_values;

            otherwise

                error('aggregate_by must be ''session'' or ''mouse''.');

        end

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(figure_num);
clf;

positions = utils.calculateFigurePositions( ...
    1, 7, .3, []);

for moveIdx = 1:nMovements

    subplot(1,nMovements,moveIdx);
    hold on;

    nUnits = length(plot_values{1,moveIdx});

    values_matrix = nan(nUnits,nContexts);

    for contextIdx = 1:nContexts
        values_matrix(:,contextIdx) = ...
            plot_values{contextIdx,moveIdx};
    end


    % Plot paired individual units
    for unitIdx = 1:nUnits

        plot(1:nContexts, ...
            values_matrix(unitIdx,:), ...
            '-', ...
            'Color',[0.75 0.75 0.75], ...
            'LineWidth',0.75);

    end


    % Plot group mean +/- SEM
    for contextIdx = 1:nContexts

        curr_values = values_matrix(:,contextIdx);

        curr_mean = mean(curr_values,'omitnan');

        curr_sem = std(curr_values,'omitnan') / ...
            sqrt(sum(~isnan(curr_values)));

        errorbar( ...
            contextIdx, ...
            curr_mean, ...
            curr_sem, ...
            'o', ...
            'Color', ...
                function_params.contexts_colors(contextIdx,:), ...
            'MarkerFaceColor', ...
                function_params.contexts_colors(contextIdx,:), ...
            'MarkerEdgeColor', ...
                function_params.contexts_colors(contextIdx,:), ...
            'LineWidth',1.0, ...
            'MarkerSize',3, ...
            'CapSize',6);

    end


    % Axis labels
    xlim([0.5 nContexts+0.5]);

    xticks(1:nContexts);
    xticklabels(function_params.contexts);
    xtickangle(45);

    movement = movement_types{moveIdx};

    if strcmpi(movement,'Both')
        title('Total Speed','FontWeight','normal');
    else
        title(movement,'FontWeight','normal');
    end

    if function_params.abs == 1
        ylabel('Speed (cm/s)');
    else
        ylabel('Velocity (cm/s)');
    end

    set(gca, ...
        'FontSize',7, ...
        'Units','inches', ...
        'Position',positions(moveIdx,:));

    utils.set_current_fig;

    hold off;


    % Store stats
    field_name = matlab.lang.makeValidName( ...
        ['onset_' movement]);

    general_stats.(field_name).values = ...
        values_matrix;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STATISTICS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

possible_tests = ...
    nchoosek(1:nContexts,2);

num_tests = ...
    nMovements * size(possible_tests,1);

alpha = 0.05 / num_tests;

p_values = cell( ...
    size(possible_tests,1), ...
    nMovements, ...
    2);

for moveIdx = 1:nMovements

    for testIdx = 1:size(possible_tests,1)

        context1 = possible_tests(testIdx,1);
        context2 = possible_tests(testIdx,2);

        data1 = plot_values{context1,moveIdx};
        data2 = plot_values{context2,moveIdx};

        good_idx = ...
            ~isnan(data1) & ...
            ~isnan(data2);

        data1 = data1(good_idx);
        data2 = data2(good_idx);

        p_val = permutationTest_updatedcb( ...
            data1, ...
            data2, ...
            10000, ...
            'paired', ...
            1);

        comparison_string = sprintf( ...
            '%s: %s vs %s', ...
            movement_types{moveIdx}, ...
            function_params.contexts{context1}, ...
            function_params.contexts{context2});

        p_values{testIdx,moveIdx,1} = p_val;
        p_values{testIdx,moveIdx,2} = comparison_string;

        fprintf('\n%s\n',comparison_string);
        fprintf('p = %.6f\n',p_val);
        fprintf('Bonferroni alpha = %.6f\n',alpha);

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

general_stats.aggregate_by = aggregate_by;
general_stats.mouse_ids = mouse_ids;
general_stats.unique_mice = unique_mice;

general_stats.p_values = p_values;
general_stats.test = 'paired permutation test';
general_stats.alpha_bonferroni = alpha;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
avg_window = [function_params.specified_frames(1) ,function_params.specified_frames(end)];
if ~isempty(save_data_directory)

    exportgraphics( ...
        figure(figure_num), ...
        fullfile(save_data_directory, ...
        ['speed_at_stimulus_onset_' num2str(avg_window) '_' ...
         aggregate_by '.pdf']), ...
        'ContentType','vector');

    saveas( ...
        figure(figure_num), ...
        fullfile(save_data_directory, ...
        ['speed_at_stimulus_onset_' num2str(avg_window) '_' ...
         aggregate_by '.fig']));

    save( ...
        fullfile(save_data_directory, ...
        ['stats_speed_at_stimulus_onset_' num2str(avg_window) '_' ...
         aggregate_by '.mat']), ...
        'general_stats');

end

end