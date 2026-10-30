function save_opto_figs(mouseID, date,session,string,server)
%directory= strcat('\\136.142.49.216\',server,'\Connie\results\',num2str(mouseID),'\',num2str(date),'\',num2str(session),'\');
directory= strcat(server,'\Connie\results\',num2str(mouseID),'\',num2str(date),'\',num2str(session),'\');

%directory= strcat('/Volumes/',server,'/Connie/results/',num2str(mouseID),'/',num2str(date),'/',num2str(session),'/');
mkdir(directory);
cd(directory);
saveas(figure(59),[string 'heatmap_100.fig']);
saveas(figure(59),[string 'heatmap_100.png']);
saveas(figure(6),[string 'before_after_100.fig']);
saveas(figure(6),[string 'before_after_100.png']);
saveas(figure(50),[string 'opto_sig_cells.fig']);
saveas(figure(50),[string 'opto_sig_cells.png']);
saveas(figure(52),['0_power' 'ctrl_sig_cells.fig']);
saveas(figure(52),['0_power' 'ctrl_sig_cells.png']);
end