function plot_individual_mod_neurons(stim_data_subset, ctrl_data_subset, mod_index, sig_neurons, time_vector, dataset_index, left_trials_total, save_dir, plot_mode, plot_avg,plot_info)
% PLOT_INDIVIDUAL_MOD_NEURONS generates plots of neural activity for selected neurons.
%
%   Inputs:
%       stim_data_subset  - 3D array of stimulation data [nTrials x nNeurons x nFrames].
%       ctrl_data_subset  - 3D array of control data [nTrials x nNeurons x nFrames].
%       mod_index         - 1 x nNeurons vector of modulation indices.
%       sig_neurons       - Vector of neuron indices (local to the dataset) to plot.
%       time_vector       - Vector of time points corresponding to frames.
%                           If empty, frame indices are used.
%       dataset_index     - Index information for the dataset (e.g., [datasetID, contextID]).
%       left_trials_total - Vector for trial separation (used for plotting both data types).
%       save_dir          - (Optional) Directory where figures should be saved.
%       plot_mode         - (Optional) String: 'both' (default), 'stim', or 'ctrl'.
%                           Determines which data to plot.
%       plot_avg          - (Optional) Boolean (default true). If true, plots the average response subplot.
%
%   For each neuron in sig_neurons, the function creates a figure with:
%       - If plot_avg is true:
%           Subplot (2,1,1): imagesc plot of trial-by-trial activity.
%           Subplot (2,1,2): line plot of the mean response.
%       - If plot_avg is false:
%           A single axes with the imagesc plot.
%
%   Example:
%       plot_individual_mod_neurons(stim_data, ctrl_data, mod_index, sig_neurons, 1:120, [1,2], [30,30], 'C:\save_figs', 'both', true);
%
%   Author: Your Name, Date

    % Set default values for optional arguments.
    if nargin < 5 || isempty(time_vector)
        time_vector = 1:size(stim_data_subset, 3);
    end
    if nargin < 8
        save_dir = '';
    end
    if nargin < 9 || isempty(plot_mode)
        plot_mode = 'both';
    end
    if nargin < 10 || isempty(plot_avg)
        plot_avg = true;
    end

    % Validate plot_mode.
    valid_modes = {'both', 'stim', 'ctrl'};
    if ~ismember(plot_mode, valid_modes)
        error('Unknown plot_mode. Use ''both'', ''stim'', or ''ctrl''.');
    end

    if length(sig_neurons) > 10
        total_to_plot = 10;
    else
        total_to_plot = length(sig_neurons);
    end

    % Loop over each selected neuron.
    for i = 1:total_to_plot
        neuron_id = sig_neurons(i);
        % Extract the neuron's data (across trials and frames).
        neuron_data = squeeze(stim_data_subset(:, neuron_id, :));
        neuron_data_ctrl = squeeze(ctrl_data_subset(:, neuron_id, :));

        % Compute the mean response across trials.
        mean_response = mean(neuron_data, 1);
        mean_response_ctrl = mean(neuron_data_ctrl, 1);

        % Create a figure for this neuron.
        figure(i + (dataset_index(1)*10)); clf;

        % Create subplot for the imagesc plot.
        if plot_avg
            subplot(2,1,1);
        else
            subplot(1,1,1);
        end

        % Plot the trial-by-trial activity based on plot_mode.
        switch plot_mode
            case 'both'
                imagesc([neuron_data; neuron_data_ctrl]); % stack trials vertically
                colormap('viridis');  % Change colormap as desired.
                % Add dividing lines to delineate stim vs. control.
                xline(61, '-w', 'LineWidth', 1);
                yline(left_trials_total(1), '-w', 'LineWidth', 1);
                yline(size(neuron_data, 1), '--w', 'LineWidth', 1);
                yline(size(neuron_data, 1) + left_trials_total(2), '-w', 'LineWidth', 1);
            case 'stim'
                imagesc(neuron_data);
                colormap('viridis');
                xline(61, '-w', 'LineWidth', 1);
                yline(left_trials_total(1), '-w', 'LineWidth', 1);
            case 'ctrl'
                imagesc(neuron_data_ctrl);
                colormap('viridis');
                xline(61, '-w', 'LineWidth', 1);
                yline(left_trials_total(2), '-w', 'LineWidth', 1);
        end

        xlabel('Time');
        ylabel('Trial');
        [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(61, 122, 1);
        xticks(xticks_in);
        xticklabels(xticks_lab);
        caxis([-.3 1]);
        
        utils.set_current_fig;
        set(gca, 'FontSize', 6);
%         title(sprintf('Neuron %d\nMod Index: %.2f', neuron_id, mod_index(neuron_id)), 'FontWeight', 'normal');
        title(sprintf('Neuron %d MI: %.2f', neuron_id, mod_index(neuron_id)), 'FontWeight', 'normal');

        % If average plot is requested, create the mean response subplot.
        if plot_avg
            subplot(2,1,2);
            hold on;
            switch plot_mode
                case 'both'
                    plot(time_vector, mean_response, 'k', 'LineWidth', 1);
                    plot(time_vector, mean_response_ctrl, 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);
                case 'stim'
                    plot(time_vector, mean_response, 'k', 'LineWidth', 1);
                case 'ctrl'
                    plot(time_vector, mean_response_ctrl, 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);
            end
            xlabel('Time');
            ylabel('Mean Response');
            xlim([min(time_vector), max(time_vector)]);
            xline(61, '--k', 'LineWidth', 1);
            [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(61, 122, 1);
            xticks(xticks_in);
            xticklabels(xticks_lab);
            utils.set_current_fig;
            set(gca, 'FontSize', 6);
            hold off;
        end
        if isfield(plot_info,'caxis') && plot_info.caxis == 1;
            colorbar('position',[0.789936246481369,0.316666666666667,0.044444444444444,0.488888888888889])%;'eastoutside'
        end

        % Adjust figure size (optional).
        set(gcf, 'Position', [100, 100, 100, 80]);

        % Save the figure if a save directory is provided.
        if ~isempty(save_dir)
            if ~exist(save_dir, 'dir')
                mkdir(save_dir);
            end
            saveas(gcf, fullfile(save_dir, sprintf('Neuron_%d_dataset_%i_context_%c.fig', neuron_id, dataset_index(1), num2str(dataset_index(2)))));
            exportgraphics(gcf, fullfile(save_dir, sprintf('Neuron_%d_dataset_%i_context_%c.pdf', neuron_id, dataset_index(1), num2str(dataset_index(2)))), 'ContentType', 'vector');
%             saveas(gcf, fullfile(save_dir, sprintf('Neuron_%d_dataset_%i_context_%c.pdf', neuron_id, dataset_index(1), num2str(dataset_index(2)))));
        end
    end
end

% function plot_individual_mod_neurons(stim_data_subset, ctrl_data_subset, mod_index, sig_neurons, time_vector, dataset_index,left_trials_total,save_dir)
% % PLOT_INDIVIDUAL_MOD_NEURONS generates plots of neural activity for selected neurons.
% %
% %   Inputs:
% %       stim_data_subset  - 3D array of stimulation data [nTrials x nNeurons x nFrames].
% %       ctrl_data_subset  - 3D array of control data [nTrials x nNeurons x nFrames] (optional).
% %                           (In this example, we use only stimulation data.)
% %       mod_index         - 1 x nNeurons vector of modulation indices.
% %       sig_neurons       - Vector of neuron indices (local to the dataset) to plot.
% %       time_vector       - Vector of time points corresponding to frames.
% %                           If empty, frame indices are used.
% %       save_dir          - (Optional) Directory where figures should be saved.
% %
% %   For each neuron in sig_neurons, the function creates a figure with:
% %       - Subplot (2,1,1): an imagesc plot of the neuron's trial-by-trial activity.
% %       - Subplot (2,1,2): a line plot of the mean response (averaged across trials).
% %   The figure title includes the neuron ID and its modulation index.
% %
% %   Example:
% %       plot_individual_mod_neurons(stim_data, ctrl_data, mod_index, sig_neurons, 1:120, 'C:\save_figs');
% %
% %   Author: Your Name, Date
%     % If time_vector is empty, default to frame indices.
%     if nargin < 5 || isempty(time_vector)
%         time_vector = 1:size(stim_data_subset, 3);
%     end
%     if nargin < 6
%         save_dir = '';
%     end
% 
%     if length(sig_neurons) > 5
%         total_to_plot = 5;
%     else
%         total_to_plot = length(sig_neurons);
%     end
%     % Loop over each selected neuron.
%     for i = 1:total_to_plot
%         neuron_id = sig_neurons(i);
%         % Extract the neuron's data (across trials and frames).
%         % This returns a matrix of size [nTrials x nFrames].
%         neuron_data = squeeze(stim_data_subset(:, neuron_id, :));
%         neuron_data_ctrl = squeeze(ctrl_data_subset(:, neuron_id, :));
% 
%         % Compute the mean response across trials.
%         mean_response = mean(neuron_data, 1);
%         mean_response_ctrl = mean(squeeze(ctrl_data_subset(:, neuron_id, :)));
% 
%         % Create a figure for this neuron.
%         figure(i+(dataset_index(1)*10));clf;
%         % Subplot 1: imagesc of trial-by-trial activity.
%         subplot(2,1,1);
%         imagesc([neuron_data;neuron_data_ctrl]); %stack trials
%         colormap('viridis');  % Change colormap as desired.
% %         colorbar;
%         xlabel('Time');
%         ylabel('Trial');
%         xline(61,'-w','LineWidth',2)
%         yline(left_trials_total(1),'-w','LineWidth',1) %size(neuron_data,1)/2
%         yline(size(neuron_data,1),'--w','LineWidth',2)
%         yline(size(neuron_data,1)+left_trials_total(2),'-w','LineWidth',1)
%         [xticks_in,xticks_lab]  = utils.x_axis_sec_aligned(61,122,1);
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
% 
%         caxis([-.3 1]);
%         utils.set_current_fig;
%         set(gca,'FontSize',6);
%         title(sprintf('Neuron %d Mod Index: %.3f', neuron_id, mod_index(neuron_id)),'FontWeight','normal');
% 
%         % Subplot 2: line plot of the mean response.
%         subplot(2,1,2);
%         hold on
%         plot(time_vector, mean_response,'k', 'LineWidth', 1);
%         plot(time_vector, mean_response_ctrl, 'LineWidth', 1,'Color', [0.5 0.5 0.5]);
%         xlabel('Time');
%         ylabel('Mean Response');
% %         title('Mean Across Trials','FontWeight','normal');
%         xlim([min(time_vector), max(time_vector)]);
%         xline(61,'--k','LineWidth',1)
%         [xticks_in,xticks_lab]  = utils.x_axis_sec_aligned(61,122,1);
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
%         utils.set_current_fig;
%         set(gca,'FontSize',6);
%         hold off
%         % Adjust figure size (optional).
%         set(gcf, 'Position', [100, 100, 300, 400]);
%         % Save the figure if a save directory is provided.
%         if ~isempty(save_dir)
%             if ~exist(save_dir, 'dir')
%                 mkdir(save_dir);
%             end
%             saveas(gcf, fullfile(save_dir, sprintf('Neuron_%d_dataset_%i_context_%c.fig', neuron_id,dataset_index(1),num2str(dataset_index(2)))));
%             saveas(gcf, fullfile(save_dir, sprintf('Neuron_%d_dataset_%i_context_%c.png', neuron_id,dataset_index(1),num2str(dataset_index(2)))));
%         end
%     end
% end