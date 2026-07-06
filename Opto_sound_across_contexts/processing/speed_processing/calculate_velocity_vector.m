function [velocity_vector,velocity_smooth] = calculate_velocity_vector(mouse, date,velocity_cat,server)
velocity_vector = sqrt(velocity_cat(1,:).^2+ velocity_cat(2,:).^2); %sqrt(velocity_resampled(1,:).^2+ velocity_resampled(2,:).^2);
%base_path_wav = strcat('\\136.142.49.216\Runyan2\Connie\RawData\',num2str(mouse),'\wavesurfer\',num2str(date),'\');
%cd(base_path_wav)
% velocity_cat=[];
% blockedges =[];
% temp1=[];
% temp=[];
% for i = 1:length(v)
%     velocity_cat = [velocity_cat,v(i).velocity_vector];
%     temp1 = length(v(i).velocity_vector); 
%     temp = [temp,temp1];
%     blockedges = [blockedges, sum(temp)];
% end
velocity_smooth = velocity_vector;
velraw=velocity_smooth;
normalized_velraw=(velocity_smooth-nanmean(velraw))/nanstd(velraw);
velocity_smooth=smooth(velocity_smooth,6,'window');
velocity_smooth=velocity_smooth-min(velocity_smooth);

cd(strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date)));
save('velocity_vector','velocity_vector')
% save('velocity_smooth','velocity_smooth')
