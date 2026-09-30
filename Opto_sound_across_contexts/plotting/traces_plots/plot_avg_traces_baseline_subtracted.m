function [final_data_means,final_mouse_ids_used] = plot_avg_traces_baseline_subtracted(deconv_response, colors, lineStyles_contexts, celltypes_ids, frames, stim_frame, save_dir, average_over_neurons,type,plot_info,varargin)

if nargin < 9
    average_over_neurons = false;
end

positions = utils.calculateFigurePositions(1, 6, .4, []);
if size(deconv_response,3) > 1
%     positions = utils.calculateFigurePositions(1, 7, .3, []);
% 
%     %make skinnier and taller (good for 3)
%     positions(:,1) = positions(:,1)-.1;
%     positions(:,4) = positions(:,4)+.1;
%     positions(:,2) = positions(:,2)-.2;
%     positions(:,3) = positions(:,3)-.1;
positions = utils.calculateFigurePositions(1, 9, .2, []);

    %make skinnier and taller (good for 3)
    positions(:,1) = positions(:,1)-.1;
    positions(:,4) = positions(:,4)+.1;
    positions(:,2) = positions(:,2)-.2;
    positions(:,3) = positions(:,3)-.1;
end
if isfield(plot_info,'figure_width_traces')
    positions = utils.calculateFigurePositions(1, plot_info.figure_width_traces, .2, []);
end
contexts = {'active', 'passive'};
data_modes = plot_info.trace_modes;%{'raw', 'bs'}; % raw and baseline subtracted
stim_ctrl_idx = [1, 0, 1, 0, 1, 0];
final_data_means = {};
final_mouse_ids_used = {};
for fig_idx = 1:length(data_modes)*2
    figure(fig_idx); clf;

    for celtype = 1:size(deconv_response,3)
        subplot(1,size(deconv_response, 3),celtype);
        hold on;

        for context = 1:size(deconv_response,1)
            all_traces = [];  % All neuron traces pooled
            mouse_means = []; % Mean trace per dataset
            mouse_ids_used = [];
            all_traces_stim = [];
            mouse_means_stim = [];
            for mouse = 1:size(deconv_response,2)
                dat_struct = deconv_response{context,mouse,celtype};
                if isempty(dat_struct) || size(dat_struct.stim,2) == 1
                    continue
                end
                mouse_ids_used = [mouse_ids_used,mouse];
                
                %take away any Infs
                dat_struct.stim(isinf(dat_struct.stim)) = NaN;
                dat_struct.ctrl(isinf(dat_struct.ctrl)) = NaN;
                if stim_ctrl_idx(fig_idx) == 1
                    if ~isfield(dat_struct, 'stim') || isempty(dat_struct.stim)
                        continue
                    end
                    if length(size(dat_struct.stim))>2
                        dat = squeeze(mean(dat_struct.stim,'omitnan'));
                        dat_stim = dat;
                        if contains(type,'deconv')
%                             frame_window = 31:91;%1:size(dat_struct.ctrl,3);
%                             if nargin > 10
%                                 frame_window = 1:60;
%                             end
%                             
%                             dat = squeeze(squeeze(sum(dat_struct.stim(:,:,frame_window),1))/(length(frame_window)/30)); %/2 bc I display half the data
%                             dat_nan = zeros(size(dat,1),122);
%                             dat_nan(:,frame_window) = dat;
%                             dat_stim = dat_nan;
%                             dat = dat_stim;
                            dat = dat*30;
                            dat_stim = dat;
                        end
                    else
                        dat = dat_struct.stim;
                        dat_stim = dat;
                    end
                else
                    if ~isfield(dat_struct, 'ctrl') || isempty(dat_struct.ctrl)
                        continue
                    end
                    if length(size(dat_struct.stim))>2
                        dat = squeeze(mean(dat_struct.ctrl,'omitnan'));
                        if contains(type,'deconv')
%                             frame_window = 31:91;%1:size(dat_struct.ctrl,3);
%                             if nargin > 10
%                                 frame_window = 1:60;
%                             end
%                             dat = squeeze(squeeze(sum(dat_struct.ctrl(:,:,frame_window),1))/(length(frame_window)/30));
%                             dat_nan = zeros(size(dat,1),122);
%                             dat_nan(:,frame_window) = dat;
%                             dat_ctrl = dat_nan;
%                             dat = dat_ctrl;

                            dat = dat*30;
                            dat_ctrl = dat;
                        end
                    else
                        dat = dat_struct.ctrl;
                    end

                end

                if isnan(dat)
                    continue
                end

                dat = dat(:, frames);
                dat_stim = dat_stim(:,frames);

                if strcmp(data_modes{ceil(fig_idx/2)}, 'bs')
                    baseline = mean(dat(:, 31:60), 2,'omitnan');
                    if nargin > 10
                        baseline = mean(dat(:, varargin{1,1}), 2,'omitnan');
                    end
                    dat = dat - baseline;
                end

                if average_over_neurons
                    all_traces = [all_traces; dat];  % Pool all neurons
                    all_traces_stim = [all_traces_stim; dat_stim];
                    
                else
                
                    mean_trace = mean(dat, 1,'omitnan');  % Average per dataset
                    mouse_means = [mouse_means; mean_trace];

                    mean_trace_stim = mean(dat_stim, 1,'omitnan');  % Average per dataset
                    mouse_means_stim = [mouse_means_stim; mean_trace_stim];
                end
            end
            if average_over_neurons
                if contains(plot_info.type,'sound') && fig_idx == 2
                    final_data_means{celtype,context} = all_traces;
                elseif ~contains(plot_info.type,'sound') && fig_idx == 1
                    final_data_means{celtype,context} = all_traces_stim;
                end
                
            else
                if contains(plot_info.type,'sound') && fig_idx == 2
                    final_data_means{celtype,context} = mouse_means;
                elseif ~contains(plot_info.type,'sound') && fig_idx == 1
                    final_data_means{celtype,context} = mouse_means_stim;
                end
            end

            final_mouse_ids_used{celtype,context} = mouse_ids_used;

            if average_over_neurons && ~isempty(all_traces)
                shadedErrorBar([], mean(all_traces,1), ...
                    std(all_traces,[],1)/sqrt(size(all_traces,1)), ...
                    'lineprops', {'LineWidth', 1., 'LineStyle', '-', ...
                    'Color', colors((celtype-1)*3+context,:)});
            elseif ~isempty(mouse_means)
                shadedErrorBar([], mean(mouse_means,1), ...
                    std(mouse_means,[],1)/sqrt(size(mouse_means,1)), ...
                    'lineprops', {'LineWidth', 1., 'LineStyle', '-', ...
                    'Color', colors((celtype-1)*3+context,:)});
            end

%             %place legends (plot too small to do this consistently)
%             if context == size(deconv_response,1)
%                 utils.place_text_labels(plot_info.behavioral_contexts, colors((celtype-1)*3+1:(celtype-1)*3+2,:), 0.75, 7); %.4
%             end
                hold off;
        end

        xlimss = [31 91];
        if isfield(plot_info,'xlims_traces')
            xlim(plot_info.xlims_traces);
        end
        xticks([31 61 91]);
        xticklabels([-1 0 1]);

        if  isfield(plot_info,'trace_ylims') && ~isempty(plot_info.trace_ylims)
            ylim([plot_info.trace_ylims]);
        end
        
        yli = ylim;
        if diff(yli) < 0.04
            yli = [yli(1)-0.01,yli(2)+0.01];
        end
        if nargin <= 10
            if contains(plot_info.type,'sound')
                onset_color = [0.5 0.5 0.5];
            else
                onset_color =[1 0.8 0.3];
            end
%             for f = 1:size(stim_frame,1)
%                 x = [stim_frame(f,1), stim_frame(f,2), stim_frame(f,2), stim_frame(f,1)];
%                 y = [yli(1), yli(1), yli(2), yli(2)];
%                 patch(x, y, onset_color, 'EdgeColor', 'none', 'FaceAlpha', 1); %[.5 .5 .5]
% 
%             end
        else 
            xlimss = [1 60];
            xlim(xlimss );
            xticks([1 60]);
            xticklabels([-2 0]);
            yli = ylim;
%             for f = 1:size(stim_frame,1)
%                 %highlight the pre stimulus period!
%                 x1 = 51;
%                 x2 = 61;
%                 x = [x1, x2, x2,x1];
%                 y = [yli(1), yli(1), yli(2), yli(2)];
%                 patch(x, y, [.9 .0 .6], 'EdgeColor', 'none', 'FaceAlpha', 0.1); %[.5 .5 .5]
% 
%             end
            

%             xlimss = [1 122];
%             xlim(xlimss );
%             xticks([1 61 122]);
%             xticklabels([-2 0 2]);

%             xlimss = [50 61];
%             xlim(xlimss );
%             xticks([50 61]);
%             xticklabels([-0.33 0]);
        end

%         [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(30, length(xlimss ));
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
        set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(celtype, :));
        title(celltypes_ids{celtype}, 'FontSize', 7, 'FontName', 'arial','FontWeight','normal');


        ax = gca;
        ax.YAxis.Exponent = 0;  % removes the x10^… factor

        positions(celtype,2) = positions(celtype,2)-.2;
        
        
        yli = ylim;
        if nargin <= 10
            for f = 1:size(stim_frame,1)
                if contains(type,'opto')
                    color_onset = [1 0.8 0.3];
                else
                    color_onset = [.5 .5 .5];
                end
    
                rectangle('Position', [stim_frame(f,1), yli(1), stim_frame(f,2)-stim_frame(f,1), ...
                    yli(2)-yli(1)], 'FaceColor', color_onset, 'EdgeColor', 'none');
            end
        else
            for f = 1:size(stim_frame,1)
                %highlight the pre stimulus period!
                x1 = 50;
                x2 = 59;
                x = [x1, x2, x2,x1];
                y = [yli(1), yli(1), yli(2), yli(2)];
                patch(x, y, [.9 .0 .6], 'EdgeColor', 'none', 'FaceAlpha', 0.1); %[.5 .5 .5]

            end
        end
%         xline(stim_frame(1), '--k', 'LineWidth', 1);

    end

    if ~isempty(save_dir)
        fig_suffix = {'raw_stim','raw_ctrl','bs_stim','bs_ctrl'};
        if isfield(plot_info,'trace_ylims') && ~isempty(plot_info.trace_ylims)
            fig_suffix = {'raw_stim_ylims','raw_ctrl_ylims','bs_stim_ylims','bs_ctrl_ylims'};
        end
        mkdir(fullfile(save_dir, 'avg_traces'));
        if average_over_neurons
            saveas(fig_idx, fullfile(save_dir, 'avg_traces', ...
                strcat('avg_over_neurons_traces_', fig_suffix{fig_idx},'_', type,'.fig')));
            exportgraphics(gcf, fullfile(save_dir, 'avg_traces', ...
                strcat('avg_over_neurons_traces_', fig_suffix{fig_idx},'_', type,'.pdf')), 'ContentType', 'vector');
        else
            saveas(fig_idx, fullfile(save_dir, 'avg_traces', ...
                strcat('avg_traces_', fig_suffix{fig_idx},'_', type,'.fig')));
            exportgraphics(gcf, fullfile(save_dir, 'avg_traces', ...
                strcat('avg_traces_', fig_suffix{fig_idx},'_', type,'.pdf')), 'ContentType', 'vector');
        end
    end
end

% 
% positions = utils.calculateFigurePositions(1, 5, .5, []);
% contexts = {'active', 'passive'};
% data_modes = {'raw', 'bs'}; % raw and baseline subtracted
% stim_ctrl_idx = [1, 0, 1, 0];
% 
% for fig_idx = 1:4
%     figure(fig_idx); clf;
% %     t = tiledlayout(1, size(deconv_response, 3), 'TileSpacing', 'Compact', 'Padding', 'Compact');
% 
%     for celtype = 1:size(deconv_response,3)
% %         nexttile;
%         subplot(1,size(deconv_response, 3),celtype);
%         hold on;
% 
%         for context = 1:2
%             mouse_means = [];
% 
%             for mouse = 1:size(deconv_response,2)
%                 dat_struct = deconv_response{context,mouse,celtype};
%                 if isempty(dat_struct)
%                     continue
%                 end
% 
%                 if stim_ctrl_idx(fig_idx) == 1
%                     if ~isfield(dat_struct, 'stim') || isempty(dat_struct.stim)
%                         continue
%                     end
%                     dat = squeeze(mean(dat_struct.stim));
%                 else
%                     if ~isfield(dat_struct, 'ctrl') || isempty(dat_struct.ctrl)
%                         continue
%                     end
%                     dat = squeeze(mean(dat_struct.ctrl));
%                 end
% 
%                 if isnan(dat)
%                     continue
%                 end
% 
%                 dat = dat(:, frames);
% 
%                 if strcmp(data_modes{ceil(fig_idx/2)}, 'bs')
%                     baseline = mean(dat(:, 31:60), 2);
%                     dat = dat - baseline;
%                 end
% 
%                 mean_trace = mean(dat, 1);
%                 mouse_means = [mouse_means; mean_trace];
%             end
% 
%             if ~isempty(mouse_means)
%                 shadedErrorBar([], mean(mouse_means,1), ...
%                     std(mouse_means,[],1)/sqrt(size(mouse_means,1)), ...
%                     'lineprops', {'LineWidth', 1.5, 'LineStyle', lineStyles_contexts{context}, 'Color', colors((celtype-1)*3+context,:)});
%             end
%         end
% 
%         xlim([31 91]);
%         xticks([31 61 91]);
%         xticklabels([-1 0 1]);
%         [xticks_in, xticks_lab] = utils.x_axis_sec_aligned(stim_frame(1,1), length([31:91]));
%         xticks(xticks_in);
%         xticklabels(xticks_lab);
% 
%         title(celltypes_ids{celtype}, 'FontSize', 7, 'FontName', 'arial','FontWeight','normal');
% 
%         yli = ylim;
%         for f = 1:size(stim_frame,1)
%             rectangle('Position', [stim_frame(f,1), yli(1), stim_frame(f,2)-stim_frame(f,1), yli(2)-yli(1)], ...
%                       'FaceColor', [1 0.8 0.3], 'EdgeColor', 'none');
%         end
%         xline(stim_frame(1), '--k', 'LineWidth', 1);
%         hold off;
%         set(gca, 'FontSize', 7, 'Units', 'inches', 'Position', positions(celtype, :));
%     end
%     
% 
%     if ~isempty(save_dir)
%         fig_suffix = {'raw_stim','raw_ctrl','bs_stim','bs_ctrl'};
%         mkdir(fullfile(save_dir, 'avg_traces'));
%         saveas(fig_idx, fullfile(save_dir, 'avg_traces', strcat('avg_traces_', fig_suffix{fig_idx}, '.svg')));
%         saveas(fig_idx, fullfile(save_dir, 'avg_traces', strcat('avg_traces_', fig_suffix{fig_idx}, '.fig')));
%     end
% end
