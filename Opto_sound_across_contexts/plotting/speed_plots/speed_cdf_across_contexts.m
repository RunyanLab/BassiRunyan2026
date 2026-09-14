% make heatmap and cdf across contexts
function [mouse_vel_context,mouse_vel_context_roll,mouse_vel_context_pitch,mouse_acc_context,general_stats] = speed_cdf_across_contexts(save_dir,mouse_vel,plot_info,stim_trials_context,ctrl_trials_context,chosen_mice,frames,varargin)
dt = 1; %data already converted to seconds
nContexts = length(stim_trials_context{1,1});
for dataset_id = 1:length(chosen_mice)
    current_dataset = chosen_mice(dataset_id)
    for context = 1:nContexts
        stim_vel = mouse_vel(current_dataset).both_opto( ...
            stim_trials_context{1,current_dataset}{1,context}, ...
            frames);

        mouse_vel_context{current_dataset,context}.stim = stim_vel;

        mouse_vel_context_roll{current_dataset,context}.stim = ...
            mouse_vel(current_dataset).both_opto_roll( ...
            stim_trials_context{1,current_dataset}{1,context}, ...
            frames);

        mouse_vel_context_pitch{current_dataset,context}.stim = ...
            mouse_vel(current_dataset).both_opto_pitch( ...
            stim_trials_context{1,current_dataset}{1,context}, ...
            frames);

        % acceleration
        mouse_acc_context{current_dataset,context}.stim = ...
            gradient(stim_vel, dt, 2);

        if nargin > 7
            mouse_vel_context{current_dataset,context}.ctrl = varargin{1,1};
        end
        ctrl_vel = mouse_vel(current_dataset).both_control( ...
            ctrl_trials_context{1,current_dataset}{1,context}, ...
            frames);

        mouse_vel_context{current_dataset,context}.ctrl = ctrl_vel;

        mouse_vel_context_roll{current_dataset,context}.ctrl = ...
            mouse_vel(current_dataset).both_control_roll( ...
            ctrl_trials_context{1,current_dataset}{1,context}, ...
            frames);

        mouse_vel_context_pitch{current_dataset,context}.ctrl = ...
            mouse_vel(current_dataset).both_control_pitch( ...
            ctrl_trials_context{1,current_dataset}{1,context}, ...
            frames);

        % acceleration
        mouse_acc_context{current_dataset,context}.ctrl = ...
            gradient(ctrl_vel, dt, 2);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % GENERAL STATS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % combine stim + ctrl
        combined_speed = [mean(mouse_vel_context{current_dataset,context}.stim,2); ...
           mean(mouse_vel_context{current_dataset,context}.ctrl,2)];
        
        combined_acc = [mean(mouse_acc_context{current_dataset,context}.stim,2); ...
            mean(mouse_acc_context{current_dataset,context}.ctrl,2)];
        
        combined_roll = [ ...
            mean(mouse_vel_context_roll{current_dataset,context}.stim,2); ...
            mean(mouse_vel_context_roll{current_dataset,context}.ctrl,2)];
        
        combined_pitch = [ ...
            mean(mouse_vel_context_pitch{current_dataset,context}.stim,2); ...
            mean(mouse_vel_context_pitch{current_dataset,context}.ctrl,2)];
        
        % stats
        general_stats.speed{current_dataset,context} = ...
            get_basic_stats(combined_speed(:));
        
        general_stats.acc{current_dataset,context} = ...
            get_basic_stats(combined_acc(:));
        
        general_stats.roll{current_dataset,context} = ...
            get_basic_stats(combined_roll(:));
        
        general_stats.pitch{current_dataset,context} = ...
            get_basic_stats(combined_pitch(:));
    end
end
binss = ([0:5:60]);
figure(95);clf
%t = tiledlayout(1,1,'TileSpacing','Compact','Padding','Compact');

for context = 1:nContexts
    mice_vel_context = cat(1,mouse_vel_context{:,context});% cat(1,mice_vel_context.stim);
    [stim_cdf,p1] = make_cdf(mean(cat(1,mice_vel_context.stim),2),binss);%make_cdf(mean(mouse_vel_context{1,c}.stim,2),binss); %find(ismember(sorted_sig_cells,sorted_pyr)
    [ctrl_cdf,p4] = make_cdf(mean(cat(1,mice_vel_context.ctrl),2),binss);

    %make plots
    hold on
    a(context) = plot(binss,stim_cdf);
    set( a(context), 'LineWidth', 1.5, 'LineStyle', plot_info.lineStyles_contexts{context}, 'color',plot_info.colors_stimctrl(1,:));%linecolors(2,:));

    b(context) = plot(binss,ctrl_cdf);
    set( b(context), 'LineWidth', 1.5, 'LineStyle', plot_info.lineStyles_contexts{context}, 'color',plot_info.colors_stimctrl(2,:));%linecolors(2,:));
end

hold off
grid on
legend(a, [plot_info.behavioral_contexts{1,:}],'Location', 'southeast'); %'Task','Passive','Spont'
ylim([0 1])
xlim([0 60])
ylabel('Cumulative Fraction')
xlabel('Running Speed prior to Stim(cm/s)')
set(gca,'fontsize',14)

%%
if ~isempty(save_dir)
    mkdir(strcat(save_dir,'/running'))
    cd(strcat(save_dir,'/running'))
    saveas(95,strcat('speed_cdf_across_contexts_',num2str(frames(1)),'-',num2str(frames(end)),'frames_',num2str(length(chosen_mice)),'_datasets.svg'));
    saveas(95,strcat('speed_cdf_across_contexts_',num2str(frames(1)),'-',num2str(frames(end)),'frames_',num2str(length(chosen_mice)),'_datasets.fig'));
end