function get_percentile_speeds(mouse_vel_context,pct1,pct2);
all_speeds = [];
for dataset = 1:24
    all_speeds = [all_speeds; mean(mouse_vel_context{dataset,1}.ctrl,2)];
    all_speeds = [all_speeds; mean(mouse_vel_context{dataset,2}.ctrl,2)];
end

global_p25 = prctile(all_speeds,pct1);
global_p75 = prctile(all_speeds,pct2);