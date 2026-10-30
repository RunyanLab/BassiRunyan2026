function [bad_frames,bad_frames_all,cel_pos] = find_bad_frames_v2(server,mouse_date,thr_strength,baselineF,F,stat,save)
% data_dir= strcat(server,'\Connie\ProcessedData\',num2str(mouse_date),'\suite2p\plane0\Fall.mat');
% load(data_dir)
good_c = 0; 
length_data = size(F,2);
cel_pos = [];
for c = 1:size(F,1)
    %median(F(c,25000:30000))>baselineF && std(F(c,25000:30000))<100% median(F(c,120000:123000))>baselineF || c == 512%
    if median(F(c,length_data-5000:length_data)>baselineF) %need to look at cells with high baseline to get good estimate
        % usually 100 works well
        cell = c
        norm_signal = (F);
%         s = std(norm_signal(cell,:));
%         m = mean(norm_signal(cell,end-5000:end));
        minn = min(norm_signal(cell,:));
        threshold = thr_strength;%minn*thr_strength; %6 works for some
        frames=size(norm_signal,2);
        bad_fr=[]; 
        [~,bad_fr] =find(norm_signal(cell,:)<threshold &norm_signal(cell,:)>0);
        group = {}; count = 1; 
        temp=[];
        for i=1:length(bad_fr)-1
            if bad_fr(i)+5>bad_fr(i+1)
                temp = [temp,bad_fr(i)];
                group(count).group = [ min(temp), max(temp)];%[ min(temp), min(temp)+2]; %max(temp)
                
            else
                temp=[];
                count=count+1;
            end
        end
        bad_frames = []; ct= 0;
        for i =1:length(group); 
            if ~isempty(group(i).group)
                ct = ct+1; 
                bad_frames(ct,1) = group(i).group(1)-1;
                bad_frames(ct,2) = group(i).group(2)+1;   
            end
        end
        good_c = good_c+1;
        bad_frames_all(good_c,:,:) = [bad_frames];   
        cel_pos = [cel_pos,stat{1,c}.med(1)];
    end 
end
%dividing cells into three groups
count =0; count_1 = 0; count_2 = 0;
for c = 1:size(bad_frames_all,1)
    if cel_pos(c) <50
        count = count+1;
       bad_frames_group(1,count,:,:) = bad_frames_all(c,:,:);
    elseif cel_pos(c) <462
        count_1 = count_1+1;
        bad_frames_group(2,count_1,:,:) = bad_frames_all(c,:,:);
    else
        count_2 = count_2+1;
        bad_frames_group(3,count_2,:,:) = bad_frames_all(c,:,:);
    end
end
if count == 0 | count_1 == 0 |count_2 == 0
    fprintf('Not enough cells in all positions!')
    keyboard
end
%figure(111);clf;c = c
%hold on; plot(norm_signal(c,:)); plot(bad_frames_all{1,c}(:,1),norm_signal(cell,bad_frames_all{1,c}(:,1)),'*r');plot(bad_frames_all{1,c}(:,2),norm_signal(cell,bad_frames_all{1,c}(:,2)),'*c');
for g = 1:size(bad_frames_group,1)
    temp = squeeze(mean(bad_frames_group(g,find(bad_frames_group(g,:,1,1)>0),:,:),[2],'omitnan'));
    grouped_bad_frames(g,:,:)= temp;
end


mean_bad_frames = squeeze(mean(grouped_bad_frames,1,'omitnan'));
rounded_bad_frames = [ceil(mean_bad_frames(:,1)), ceil(mean_bad_frames(:,2))];
bad_frames = rounded_bad_frames;
if save == 1
directory= strcat(server,'\Connie\ProcessedData\',num2str(mouse_date),'\');
cd(directory)
save('bad_frames','bad_frames')
end


%%
% function [bad_frames,bad_frames_all] = find_bad_frames(reps,server,mouse,date)
% data_dir= strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\suite2p\plane0\Fall.mat');
% load(data_dir)
% %reps= 10;
% celli = randi(size(F,1),reps,1);
% true_reps = 0;
% for c = 1:reps
%     if mean(F(celli)>300)
%     cell = celli(c);% 
%     norm_signal = (F);
%     s = std(norm_signal(cell,:));
%     m = mean(norm_signal(cell,end-5000:end));
%     minn = norm_signal(cell,:);
%     threshold = minn+20;
%     frames=size(norm_signal,2);
%     
%     bad_fr=[]; for f=1:frames; if [norm_signal(cell,f)]<threshold; bad_fr = [bad_fr,f];end;end;
%     group = {}; count = 1; 
%     temp=[];
%     for i=1:length(bad_fr)-1
%         if bad_fr(i)+4>bad_fr(i+1)
%             temp = [temp,bad_fr(i)];
%             group(count).group = [ min(temp), max(temp)];%[ min(temp), min(temp)+2]; %max(temp)
%             
%         else
%             temp=[];
%             count=count+1;
%         end
%     end
%     bad_frames = []; ct= 0;for i =1:length(group); if ~isempty(group(i).group);ct = ct+1; bad_frames(ct,1) = group(i).group(1)-1;bad_frames(ct,2) = group(i).group(2)+1; end;end
%     bad_frames_all(c) = {bad_frames};
%     true_reps = true_reps+1;
%     end
%     
% end
% P = nchoosek(1:true_reps,2); 
% comp = [];
% for i = 1:size(P,1)
%     a = isequal(bad_frames_all{1,P(i,1)},bad_frames_all{1,P(i,2)});
%     if a == 0
%         disp('Error, check to make sure everything looks alright');
%         figure(111);clf; subplot(2,1,1); hold on; plot(norm_signal(celli(P(i,1)),:)); plot(bad_frames_all{1,P(i,1)}(:,1),norm_signal(cell,bad_frames_all{1,P(i,1)}(:,1)),'*r');plot(bad_frames_all{1,P(i,1)}(:,2),norm_signal(cell,bad_frames_all{1,P(i,1)}(:,2)),'*c'); ...
%             subplot(2,1,2); hold on; plot(norm_signal(celli(P(i,2)),:)); plot(bad_frames_all{1,P(i,2)}(:,1),norm_signal(cell,bad_frames_all{1,P(i,2)}(:,1)),'*r');plot(bad_frames_all{1,P(i,2)}(:,2),norm_signal(cell,bad_frames_all{1,P(i,2)}(:,2)),'*c'); hold off
%     keyboard
%     end
% end
% directory= strcat(server,'\Connie\ProcessedData\',num2str(mouse),'\',num2str(date),'\');
% cd(directory)
% save('bad_frames','bad_frames')
% % figure(1);clf;plot(F(cell,:));
% % bad_frames = []; for i =1:length(group); bad_frames(i,1) = group(i).group(1)-1;bad_frames(i,2) = group(i).group(2)+1; end