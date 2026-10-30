% to help save important variables
%directory= strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\',num2str(session),'\');
directory_opto= strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\',num2str(session),'\');

%directory= strcat('/Volumes/',server,'/Connie/ProcessedData/',num2str(mouseID),'/',num2str(date),'/',num2str(session),'/');
%directory= strcat('Y:\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\',num2str(session),'\');

mkdir(directory_opto);
cd(directory_opto);
save('exp','exp');
save('nonexp','nonexp');
save('bad_frames','bad_frames');
%save('dff','dff');
save('allcells','allcells');
save('sig_opto_cells','sig_opto_cells');

%powerseries
% save('p200');
% save('p400');
% save('p600');
% save('p800');
