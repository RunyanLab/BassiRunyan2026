function [dff] = pydff(mouseID,date,server) 

% mouseID= 'HA11-1R'; 
%  date= '2023-04-27'; 
%  server = '\\136.142.49.178\Runyan5';
directory= strcat(server,'\Connie\ProcessedData\',num2str(mouseID),'\',num2str(date),'\suite2p\plane0');
%  directory= strcat(server,'\Alex\ProcessedData\',num2str(mouseID),'\',num2str(date),'\suite2p\plane0');
%  directory= strcat('Y:\Connie\RawData\',num2str(mouseID),'\',num2str(date),'\suite2p\plane0');
iscell = []; %keeps giving error about this particular variable...

 addpath(genpath(directory));
 cd(directory);
 x=dir();
 for folder=1:length(x)
    if contains(x(folder).name,'Fall.mat')==1 
        load(x(folder).name);
    end
end %%

numROI=size(F,1);
icel= find(iscell(:, 1));
count= length(icel);
fBodyRawPre= double(F(icel,:));
fPre=double(F(icel,:)-.7*Fneu(icel,:));

numFrames=length(fBodyRawPre); 
 fSom=fPre;
 fBodyRawSom=fBodyRawPre;  
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
z_dff=zscore(dff,0,2);
files=ops.filelist(1:length(ops.first_tiffs)/length(ops.frames_per_folder):length(ops.first_tiffs),1:size(ops.filelist,2));
%directory= strcat('\\136.142.49.216\Runyan2\Connie\ProcessedData\',num2str(mouseID),'\',num2str(date),'\');
directory= strcat(server,'\Connie\ProcessedData\',num2str(mouseID),'\',num2str(date),'\');
% directory= strcat(server,'\Alex\ProcessedData\',num2str(mouseID),'\',num2str(date),'\');

mkdir(directory);
cd(directory);
save('z_dff','z_dff');
save('dff','dff');
%% Making figure for all cells dff/time (s)
fs=30; %frames per second
nt=6; %number of tick marks
 
figure(8);
clf
hold on
for i=1:size(dff,1)
    plot(dff(i, :));
end
ylabel('dF/F');
xlabel('time (frames)');

title(mouseID);
hold off
%%
figure(9); 
clf
hold on
for i=1:5
    plot(dff(i,1:400));
end
hold off
%% Making a heatmap of population activity
%find z_score
z_dff=zscore(dff,0,2);

[y_axis,inds] = max(z_dff,[],2);
[~,value] = sort(inds,'descend');
r = 1:length(inds);
r(value) = r;
r=r';
maxx=5; %max(z_dff,[],'all');
minn=-1; %min(z_dff,[],'all');

figure(45);clf;
%subplot (3,1,1)

hold on
imagesc(z_dff(value,:));
colorbar;
caxis([minn maxx])
title(["Population activity ", mouseID, num2str(date)]);
ylabel('neuron #')
xlabel ('frames');
xlim([0 length(dff)]);
ylim([1 length(icel)]);
hold off

%% making plot of sound wave and running trace
%{
z_dff=zscore(dff,0,2);

[y_axis,inds] = max(z_dff,[],2);
[~,value] = sort(inds,'descend');
r = 1:length(inds);
r(value) = r;
r=r';
maxx=max(z_dff,[],'all');
minn=min(z_dff,[],'all');

figure(45);clf;
subplot (3,1,1)


hold on
%z_dff2=z_dff(:,(minus_frames):(4000-(282-minus_frames)));
z_dff2=z_dff(:,(minus_frames):(size(dff,2)-(282-minus_frames)));
%z_dff2=z_dff(:,minus_frames:(size(dff,2)-(282-minus_frames)));
imagesc(z_dff2(value,:));
colorbar;
caxis([minn maxx])
title(["Population activity ", mouseID]);
ylabel('neuron #')
xlabel ('frames');
xlim([0 length(z_dff2)]);
ylim([1 length(icel)]);
hold off

subplot (3,1,2)
hold on
j_specgram2(sound_stream,192000,1);
ylabel('Hz')
%new_s= imresize(spec,[1,size(F,2)]);
%plot(new_s);
caxis([-80 0])
ylim([0 35000])
colormap default
hold off


subplot (3,1,3)
hold on
ylabel('Running')
run2=run( minus_fr:(length(run)-15732));
%run2=run( 2717:(length(run)-6659));
new_run= imresize(run2,[1,size(z_dff2,2)]);
xlim([0 length(z_dff2)]);
plot(new_run);
hold off


%}

