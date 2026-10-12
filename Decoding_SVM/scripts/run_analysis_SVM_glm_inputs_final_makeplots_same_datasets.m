%% compare cellypes during active context USING SAME DATASETS ACROSS ALL
stim_ctrl_labels = {};

event_names = {'sound_category','choice'};
do_passive = 0;
for event = 1:length(event_names)
    %full population plots
    
    savepath = ['W:\Connie\results\Bassi2025\fig2\SVM_1\full_population\' event_names{event} '\outcome_datasets\']; 
    plot_final_svm_traces_boxplots('full',{event_names{event},'outcome'},do_passive,savepath,stim_ctrl_labels);
    
%     %nmatch population plots
%     savepath = ['W:\Connie\results\Bassi2025\fig2\SVM_1\' event_names{event} '\outcome_datasets\nmatch\']; %['V:\Connie\results\SVM_1_wtop\active_passive\' info.task_event_type '\'];%['V:\Connie\results\SVM_1\' info.task_event_type '\'];
%     plot_final_svm_traces_boxplots('nmatch',{event_names{event},'outcome'},do_passive,savepath,stim_ctrl_labels);

end
