%mouse_date = {'GE4-1L\2022-10-18','GE4-1L\2022-10-20','GE4-1L\2022-10-25','GE7-1L1R\2022-10-20','GE7-1L1R\2022-12-20','GS8-00\2022-11-01','GS8-00\2022-11-23','EC3-1L\2021-12-10','EC3-1L\2021-12-22','EC3-1L\2021-12-09','EC1-1R\2022-01-13'};
%mouse_date = {'HA10-1L\2023-02-21','HA10-1L\2023-03-27-session2','HA10-1L\2023-03-31','HA10-1L\2023-04-10','HA10-1L\2023-04-17','HA11-1R\2023-03-27','HA11-1R\2023-04-13','HA11-1R\2023-05-05'};
%mouse_date = {'HA10-1L\2023-03-27-session2','HA10-1L\2023-03-31','HA10-1L\2023-04-10','HA10-1L\2023-04-17','HA11-1R\2023-03-27','HA11-1R\2023-04-13','HA11-1R\2023-05-05'};
%mouse_date = {'GE4-1L\2022-10-06','GE4-1L\2022-10-18','GE4-1L\2022-10-20','GE4-1L\2022-10-25','GE7-1L1R\2022-10-20','GE7-1L1R\2022-12-20','GS8-00\2022-11-01','GS8-00\2022-11-23','EC3-1L\2021-12-10','EC3-1L\2021-12-22','EC3-1L\2021-12-09','EC1-1R\2022-01-13','GE3-00\2022-10-20','GE3-00\2022-10-27'};
% mouse_date = {'KN8-3L\2026-07-09'}
mouse_date = {'KW-2-1L\2026-10-22'};%{'KW-2-1L\2026-10-19','LD5-00\2026-10-19','LD5-00\2026-10-21','LD5-00\2026-10-22','LD1-00\2026-10-21','LD1-00\2026-10-22'};%,'LD5-00\2026-08-25','LD2-1L\2026-08-26','LD1-00\2026-08-25','LD1-00\2026-08-27','LD2-1L\2026-08-24','LD1-00\2026-08-24'}%'KW-2-1L\2026-08-03','KW-2-1L\2026-08-04'};%{'KW-2-1L\2026-07-28'};%{'KW-2-1L\2026-07-21','KW-2-1L\2026-07-23'} 
%TO DO
% 'HA10-1L\2023-04-02','HA11-1R\2023-04-05', HA9-00\2023-10-12

server = {'\\runyan-fs-02.bns.pitt.edu\Alex Data'};% {'\\runyan-fs-02.bns.pitt.edu\Alex Data','W:','W:','W:','W:','W:'};%{'\\runyan-fs-02.bns.pitt.edu\Alex Data'};%%{'W:'};%{'\\runyan-fs-02.bns.pitt.edu\Alex Data'};%{'W:'};%{'\\runyan-fs-02.bns.pitt.edu\Alex Data'};%'\\136.142.49.178\Runyan5';%'\\136.142.49.216\Runyan2';
% server = {'\\runyan-fs-02.bns.pitt.edu\Alex Data','\\runyan-fs-02.bns.pitt.edu\Alex Data'}
for m = 1:length(m\ouse_date)
    mm = mouse_date(m); 
    mm = mm{1,1};
    ss = server(m);
    ss = ss {1,1};
%mouse = 'FL5-3L';
%date = '2022-03-09';
mm
signal_type = 'deconv'; 
if strcmp(ss,'\\runyan-fs-02.bns.pitt.edu\Alex Data')
    experimenter = 'Alex';
else
    experimenter = 'Connie';
end
load(strcat(ss,'\',experimenter,'\ProcessedData\',mm,'\dff.mat'));
[dff_interp, denoisesig, deconvsig, options]=deconvsig_cb_mod(dff)

deconv = deconvsig;
deconv(find(deconv<0.05))=0; %anything below 0.05 

mkdir(strcat(ss,'\',experimenter,'\ProcessedData\',mm,'\',signal_type,'\'));
cd(strcat(ss,'\',experimenter,'\ProcessedData\',mm,'\',signal_type,'\'));
save('deconv', 'deconv');
save('denoisesig','denoisesig');
save('dff_interp','dff_interp');
save('deconvsig','deconvsig');
save('options','options');
end