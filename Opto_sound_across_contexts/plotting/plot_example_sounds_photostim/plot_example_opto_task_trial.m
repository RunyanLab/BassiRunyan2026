function plot_example_opto_task_trial(sync_dir,opto_color,timepoints,save_dir, addscale, addlegend,spont,chan,varargin)
[files,sync_rate] = abfload(sync_dir); %'V:\Connie\RawData\HA10-1L\wavesurfer\2023-04-10\01_VR_2locs_wstim_0000.abf'
figure(722);              % create or access figure 722
clf
hold on;
sound_chan = 5;
if nargin > 8
    sound_chan =  varargin{1,1};
end
if spont == 1
    plot(rescale(files(timepoints,sound_chan),-0.058,1),'color',opto_color,'LineWidth', 1.3);
    if addlegend
        legend('Photostim', 'Box', 'off','Location','southeast')
    end
else
    plot(rescale(files(timepoints,chan),-1,1),'-k','LineWidth', 1.0);
    plot(rescale(files(timepoints,sound_chan),-0.058,1),'color',opto_color,'LineWidth', 1.3);
    if addlegend
        legend('Sounds','Photostim', 'Box', 'off','Location','southeast')
    end
end


aa = gca;
set(gca,'Fontsize',7)

% set box property to off and remove background color
set(aa,'box','off','color','none','xtick',[],'ytick',[]);
aa.YAxis.Visible = 'off';
aa.XAxis.Visible = 'off';
%1/sync_rate*1e6
if addscale spont
    xlims = xlim;
    if spont
        ylim([-.6,1])
        addScaleBar(aa, 1000, '1 s', [], [],'XOffsetFrac',-.2,'LabelOffsetFrac', -.25,'XEndData',[xlims(2)*6/7]); %big figure 'XOffsetFrac', -0.4,'LabelOffsetFrac', .025
    else
        addScaleBar(aa, 1000, '1 s', [], [],'XOffsetFrac',-.3,'LabelOffsetFrac', -.25,'XEndData',[xlims(2)*6/7]); %big figure 'XOffsetFrac', -0.4,'LabelOffsetFrac', .025
    end
end

set(gcf, 'Units','inches', 'Position',[1,1,1.27,0.3]);

pause
if ~isempty(save_dir)
    % full folder path
p = sync_dir;
% --- 1) Normalize file separators
p = strrep(p, '/', filesep);
% --- 2) Split into parts
parts = strsplit(p, filesep);
% Expected structure:
% {'V:' 'Connie' 'RawData' 'HA10-1L' 'wavesurfer' '2023-04-10' ''}
mouse = parts{4};        % 'HA10-1L'
date_str = parts{6};     % '2023-04-10'
% --- 3) Make lowercase mouse name without the "-1L" if needed
mouse_base = lower( regexp(mouse, '^[A-Za-z0-9]+', 'match','once') );
% mouse_base = 'ha10'
% --- 4) Build final filename
save_name = sprintf('example_sound_opto_trace-%s-%s-spont%d', mouse_base, date_str,spont);

mkdir(save_dir)
% saveas(722,'example_sound_opto_trace-ha10-2023-04-10.svg');
saveas(722,fullfile(save_dir,[save_name '.svg']));
exportgraphics(figure(722),fullfile(save_dir, [save_name '.pdf']), 'ContentType', 'vector');
saveas(722,fullfile(save_dir,[save_name '.fig']));
end