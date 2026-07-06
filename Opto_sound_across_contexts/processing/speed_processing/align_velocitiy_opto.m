function [vel_before, vel_before_opto, vel_before_control,vel_both_opto,vel_both_control] = align_velocitiy_opto(velocity_cat, before_frames,after_frames, mouse_date, server,stim_info,varargin)
base = [server '/Connie/ProcessedData/' mouse_date '/'];
cd(base);
bad_frames=[]; vel_aligned ={};
if isempty(stim_info)
    load('bad_frames.mat');
    load('exp.mat');
    load('nonexp.mat');
    exp = exp;
    nonexp=nonexp;
    bad_frames=bad_frames;
else
    exp = stim_info{1,2};
    nonexp = stim_info{1,3};
    bad_frames = stim_info{1,1};
end
%define velocity for periods before stim
% normalize velocity
vel = velocity_cat;
% normalized_velraw=(vel-nanmean(vel))/nanstd(vel);
% vel=smooth(vel,30,'window');
% vel=vel-min(vel);
%find velocity before and after
%including after in case I want to look at it another time
stim_trials=[];
stim_trials = [nonexp, exp];

p = inputParser;

addOptional(p,'padding',[1 2], ...
    @(x) isnumeric(x) && numel(x)==2);

parse(p,varargin{:});

before_padding = p.Results.padding(1);
after_padding  = p.Results.padding(2);

x1=before_frames+before_padding;
x2=before_padding;
y1=after_padding;
y2=after_frames+after_padding;
lenInt=length(bad_frames);
vel_before = [];
 for i=1:length(stim_trials) %stim_only%
       j= stim_trials(i);
       x= bad_frames(j,1);
       y= bad_frames(j,2);
       bfint= x-x1:x-x2; %before window
       afint= y+y1:y+y2;
       if all(~isnan(bfint)) && all(~isnan(afint)) && afint(end)<size(vel,2)
           vel_before(i,:) = vel(bfint); %finding velocity before window
           vel_after (i,:) = vel(afint);
           vel_both (i,:) = [ vel(bfint), vel(afint)];
       end
end
%vel_mean_before = mean(vel_before,2);
vel_before_opto = vel_before(find(ismember(stim_trials,exp)),:); %(exp,:);
vel_before_control = vel_before(find(ismember(stim_trials,nonexp)),:);
vel_both_opto = vel_both(find(ismember(stim_trials,exp)),:);
vel_both_control = vel_both(find(ismember(stim_trials,nonexp)),:);
vel_aligned.opto = vel_both_opto;
vel_aligned.control = vel_both_control; 
save('vel_aligned','vel_aligned');


