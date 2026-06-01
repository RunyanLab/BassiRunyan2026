function global_ranges = get_percentile_speeds(mouse_vel_context,chosen_datasets, pct1,pct2)
all_speeds = [];
for dataset = 1:chosen_datasets
    all_speeds = [all_speeds; mean(mouse_vel_context{dataset,1}.ctrl,2)];
    all_speeds = [all_speeds; mean(mouse_vel_context{dataset,2}.ctrl,2)];
end

global_1 = prctile(all_speeds,pct1);
global_2 = prctile(all_speeds,pct2);

global_ranges = [global_1,global_2];