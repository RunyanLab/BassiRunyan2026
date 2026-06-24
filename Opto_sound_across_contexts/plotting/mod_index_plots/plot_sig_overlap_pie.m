function plot_sig_overlap_pie(percent_cells, overlap_labels, savepath, contexts_to_compare,varargin)
% plot_sig_overlap_pie plots a pie chart showing the overlap of significant neurons
% across behavioral contexts.
%
%   Inputs:
%     percent_cells      - 1x3 vector of percentages for each category. The order should be:
%                          [Percentage for behavioral_contexts{1} only,
%                           Percentage for behavioral_contexts{2} only,
%                           Percentage for Both,
%                           Percentage for Neither].
    %     overlap_labels- labels for plot
%     savepath           - (Optional) A string specifying the directory where the figure should be saved.
%                          If empty or not provided, the figure is not saved.
%
%   Example usage:
%     percent_cells = [0.25, 0.30, 0.20, 0.25];  % percentages for each category
%     behavioral_contexts = {'Active','Passive'};
%     plot_sig_overlap_pie(percent_cells, behavioral_contexts, 'C:\savepath');
%
%   The pie chart will display the percentages for each of the four categories with the following labels:
%       behavioral_contexts{1}, behavioral_contexts{2}, 'Both', 'Neither'.
%
    % ---- Optional inputs ----
    p = inputParser;
    addParameter(p, 'Colors', [], @(x) isnumeric(x));
    addParameter(p, 'SD', [], @(x) isnumeric(x));
    addParameter(p, 'save_string', '', @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});

    sd_vals    = p.Results.SD;
    saveName = char(p.Results.save_string);

    % Validate inputs.
    if numel(overlap_labels) < 2
        error('must contain at least two labels.');
    end
    % Define the labels.
    labels = overlap_labels;
    %define positions 
    positions = utils.calculateFigurePositions(1, 7, .2,[]); %rows and number of columns wanted followed by spacing between them (0.4)
    positions(:,2) = positions(:,2)-.5;
    
    % Create a new figure.
    f = figure(73); clf;
    hold on;
    % Plot the pie chart.
    hPie = pie(percent_cells);
    % Reposition and format the text labels.
    % In the output of pie, every second handle is a Text object.
    nLabels = numel(labels);
    for iLabel = 1:nLabels
        hText = hPie(2*iLabel);   % every second handle is text
        
        hText.Position = .9 * hText.Position;  % shift labels inward by half
        hText.FontSize = 6;
        hText.FontName = 'Arial';
        if ~isempty(sd_vals)
            if isempty(sd_vals)
                error('ShowMeanSD is true but SD values were not provided.');
            end
            hText.String = sprintf('%.0f ± %.0f%%', ...
                percent_cells(iLabel), sd_vals(iLabel));
        end
    end
    % Set a custom colormap.
    % Here, we use a 4x3 matrix where each row is an RGB triplet.
    colors =  ([1    1    1;    % white
              0.85 0.85 0.85; % light gray
              0.65 0.65 0.65; % medium gray
              0.45 0.45 0.45; % dark gray
              0.25 0.25 0.25 ]); %darker gray
    if ~isempty(p.Results.Colors)
        colors = p.Results.Colors;
    end
    
    patchHand = findobj(hPie, 'Type', 'Patch'); 
    % The slices come in reverse order, so flip if needed
    patchHand = flipud(patchHand);
    
    % Assign colors
    for k = 1:numel(patchHand)
        set(patchHand(k), 'FaceColor', colors(k,:));
    end

    % Remove axes visibility.
    set(gca, 'visible', 'off','Units','Inches', 'Position', positions(1,:));
    
    % (Optional) Call a function to standardize figure appearance.
    % For example, if you have a function set_current_fig, uncomment the following:
    % set_current_fig;

    % Create a legend and position it outside the pie chart.       
    leg = legend(labels,'FontSize', 6,  'box', 'off'); %'Location', 'eastoutside',
    % Set legend units to normalized so that you can adjust its position relative to the figure.
    leg.Units = 'Inches';
    % Adjust the legend position manually.
    % [x y width height] -- tweak these numbers until the legend is placed as desired.
    leg_pos = positions(2,:);
    leg_pos(4) = leg_pos(4)/2;
    leg_pos(2) = leg_pos(2) + leg_pos(4)/1.5;
    leg_pos(1) = leg_pos(1)-leg_pos(1)*.1;
%             leg_pos(2) = leg_pos(2) - leg_pos(4) + 0.1;
%             leg_pos(4) = leg_pos(4)/3;
    leg.ItemTokenSize = [10, 10]; % [width height] in points (adjust as needed)
    leg.Position = leg_pos; %subtract to make it a rectangle
    pause()

    % If a save path is provided, save the figure.
    if exist('savepath', 'var') && ~isempty(savepath)
%         outdir = fullfile(savepath, 'mod');
        outdir = savepath;
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        string_to_add = [];
        if ~isempty(saveName)
            string_to_add = saveName;
        end
        saveas(f, fullfile(outdir, ['mod_pie_overlap_' num2str(contexts_to_compare) string_to_add '.svg']));
        saveas(f, fullfile(outdir, ['mod_pie_overlap_' num2str(contexts_to_compare) string_to_add '.fig']));
        exportgraphics(f,fullfile(outdir, ['mod_pie_overlap_' num2str(contexts_to_compare) string_to_add '.pdf']), 'ContentType', 'vector');
    end
    hold off;
end