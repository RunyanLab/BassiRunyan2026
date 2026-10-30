function [dff,fPre] = pydff_optov2(mouse_date,server,F,Fneu,iscell,bad_frames,edge_interpolate)
directory= strcat(server,'\Connie\ProcessedData\',num2str(mouse_date),'\suite2p\plane0');
%directory= strcat('Y:\Connie\RawData\',num2str(mouseID),'\',num2str(date),'\suite2p\plane0');
%directory= strcat('/Volumes/',server,'/Connie/RawData/',num2str(mouseID),'/',num2str(date),'/suite2p/plane0');
%addpath(genpath(directory));

%addpath(genpath(strcat('Z:\runyan-fs-01\Runyan\Connie\2presults\PVhetBL2-2L\2020-03-11b\ordered_run\suite2p\plane0\Fall.mat')))
numROI=size(F,1);
icel= find(iscell(:, 1)==1);
count= length(icel);
fBodyRawPre= double(F(icel,:));
fPre=double(F(icel,:)-.7*Fneu(icel,:));

intervals(:,1)= bad_frames(:,1)-edge_interpolate(1);%-1; 
intervals(:,2)= bad_frames(:,2)+edge_interpolate(2);%+2; 
%intervals(:,2)-bad_frames(:,2)
%numFrames=round(length(fBodyRawPre)-1,-2);
numFrames=length(fBodyRawPre); %round(length(fBodyRawPre)-5,-1);
 
 fBodyRawSom=fBodyRawPre;
%%% getting rid of f during intervals  
for int=1:size(intervals,1)
    frames=intervals(int,1): intervals(int,2); %current bad_frames
    
    if sum(frames>(size(F,2)-2))>0
        frames=intervals(int,1): (intervals(int,2)-2);    
    end
    for f = frames
        for cels =1:count
            m1=(fPre(cels,intervals(int,2))-fPre(cels,intervals(int,1)))/(intervals(int,2)-intervals(int,1)); % calculate slope
            fPre(cels,f)= m1*(f-intervals(int,1)) +fPre(cels,intervals(int,1)); % y = mx + b 
            m2=(fBodyRawSom(cels,intervals(int,2))-fBodyRawSom(cels,intervals(int,1)))/(intervals(int,2)-intervals(int,1)); % calculate slope
            fBodyRawSom(cels,f)= m2*(f-intervals(int,1)) +fBodyRawSom(cels,intervals(int,1)); % y = mx + b
        end
    end
end
fSom=fPre;

figure(1111); clf
title('Look at example interpolation of example cells near the edges')
subplot(2,1,1)
hold on
plot(F(1,:))
plot(fBodyRawSom(1,:));
hold off

subplot(2,1,2)
hold on
plot(F(icel(end),:))
plot(fBodyRawSom(end,:));
hold off


figure(1112); clf
hold on
for i=1:count
    plot(fBodyRawSom(i, :));
end
ylim([-100,500])
% xline(intervals(:,1),'-c')
% xline(intervals(:,2),'-c')

stim_info{1,1} = bad_frames;
mouse_data{1,1}.dff =fBodyRawSom;
[slopes] = bad_frames_slope_calculation(mouse_data,stim_info);
mean_slope = []; ratio=[];
for c = 1:count
    mean_slope=[mean_slope,mean(slopes{1,1}(c,:))];
    ratio = [ratio, length(find((slopes{1,1}(c,:))>0))/size(slopes{1,1},2)];
end
figure(1113);clf
title('ratio of positive/negative slopes during bad frames')
subplot(1,2,1)
histogram(ratio,'binWidth',0.5)
ylabel("# cells")
title(strcat('mean slopes: ',num2str(mean(mean_slope))))
subplot(1,2,2)
histogram(mean_slope,'binWidth',5)
ylabel("# cells")

pause
 %%%reflect data for fluorescence baseline
    fReflect(:,1:450)=fliplr(fSom(:,1:450));
    fReflect2(:,1:450)=fliplr(fBodyRawSom(:,1:450));
    fReflect(:,451:numFrames+450)=fSom(:,1:numFrames);
    fReflect2(:,451:numFrames+450)=fBodyRawSom(:,1:numFrames);
    fReflect(:,numFrames+451:numFrames+900)=fliplr(fSom(:,numFrames-449:numFrames));
    fReflect2(:,numFrames+451:numFrames+900)=fliplr(fBodyRawSom(:,numFrames-449:numFrames));

cellCount=count;
for c=1:cellCount
        for frame=451:numFrames+450
            tempArray(1,1:450)=fReflect(c,(frame-450):(frame-1));
            tempArray2(1,1:450)=fReflect2(c,(frame-450):(frame-1));
            tempArray(1,451:900)=fReflect(c,frame+1:frame+450);
            tempArray2(1,451:900)=fReflect2(c,frame+1:frame+450);

            resultArray(c,frame-450)=prctile(tempArray(1,:),8);
            resultArray2(c,frame-450)=prctile(tempArray2(1,:),8);

            tempArray=[];
            tempArray2=[];
        end
end
for c=1:cellCount
    for frame=1:numFrames
        dff(c,frame)=(fSom(c,frame)-resultArray(c,frame))/resultArray2(c,frame);
    end
end
clear fReflect2 fReflectRaw result resultRaw temp tempRaw f2 f fRaw
%files=ops.filelist(1:length(ops.first_tiffs)/length(ops.frames_per_folder):length(ops.first_tiffs),1:size(ops.filelist,2));
z_dff=zscore(dff,0,2);
%[off_frames,idx] = findpeaks(normc(ops.xoff1(:,2)),'MinPeakHeight',0.02);%
directory= strcat(server,'\Connie\ProcessedData\',num2str(mouse_date),'\');
%directory= strcat('/Volumes/',server,'/Connie/ProcessedData/',num2str(mouseID),'/',num2str(date),'/');
%directory= strcat('Y:\Connie\ProcessedData\',num2str(mouseID),'\',num2str(date),'\');

mkdir(directory);
cd(directory);
save('z_dff','z_dff');
save('dff','dff');
save('bad_frames','bad_frames');
save('edge_interpolate','edge_interpolate');
% Making figure for all cells dff/time (s)

%fs=30; %frames per second
%nt=6; %number of tick marks
minn= 5;%min(dff,[], 'all');
maxx= -2;%max(dff,[], 'all');
stiminter= []; 
figure();
clf
for i=1:size(intervals,1)
    patch([intervals(i,1) intervals(i,2) intervals(i,2) intervals(i,1)], ...
    [minn*[1 1] maxx*[1 1]], [0.5 0.5 0.5], 'LineStyle','none', 'FaceAlpha',.7)   
end
hold on
for i=1:cellCount
    plot(dff(i, :));
end
ylabel('dF/F');
xlabel('time (s)');
%xticks(round([0:(numFrames/nt):numFrames]));
%xticklabels([0:((numFrames/nt)/fs):(numFrames/fs)]);
title([num2str(mouse_date)]);%([ mouseID," ", date] );
hold off
