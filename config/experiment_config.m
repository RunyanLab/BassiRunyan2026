function params  = experiment_config()
        % Configuration settings for optical imaging analysis
    % Get base experiment parameters
    params.info = get_info_params();
    params.frames = get_frame_params();
    params.mod = get_modulation_params();
    params.mod_sounds = get_modulation_params_sounds()
    params.selectivity_sounds = get_selectivity_params_sounds()
    params.min_cells = 0;
    params.info_ctrl = get_info_params_control_mice()
    params.info_updated = get_info_params_updated()
end

function info = get_info_params()
    % Dataset and path information
    info.mouse_date = {'HA11-1R/2023-05-05'	'HA11-1R/2023-04-13'	'HA2-1L/2023-04-12'	'HA2-1L/2023-05-05'	'HA1-00/2023-06-29'	'HA1-00/2023-08-28'	'HE4-1L1R/2023-08-21'	'HE4-1L1R/2023-08-24'	'HA10-1L\2023-04-10'	'HA10-1L\2023-04-17'	'HA10-1L\2023-04-12'	'HA11-1R\2023-04-07'	'HA11-1R\2023-05-01'	'HA11-1R\2023-05-02'	'HA2-1L\2023-04-28'	'HA2-1L\2023-05-01'	'HA1-00\2023-06-27'	'HA1-00\2023-07-07'	'HA1-00\2023-08-25'	'HE4-1L1R\2023-08-14'	'HE4-1L1R\2023-08-28'	'HE4-1L1R\2023-09-04'	'HE4-1L1R\2023-09-11'	'HA10-1L\2023-03-31' 'HE1-00\2023-05-30'};
    info.serverid = {'V:'	'V:'	'V:'	'V:'	'V:'	'W:'	'W:'	'W:'	'V:'	'V:'	'V:'	'V:'	'V:'	'V:'	'V:'	'V:'	'V:'	'W:'	'W:'	'W:'	'W:'	'W:'	'W:'	'V:'    'V:'};
    info.mouseid = {1  1  2  2  3  3  4  4  5  5  5  1  1  1  2  2  3  3  3  4  4  4  4  5  6};
    info.path_string = 'context_stim/updated'; %used get_vaid_stim_onsets_trials to get trials with imaging structure info (from context_stim/60)
    info.savepath = 'V:/Connie/results/opto_sound_2025/context';
    info.savepath_sounds = 'V:/Connie/results/opto_sound_2025/context/sounds';
    info.base_dir = 'V:\Connie\results\opto_sound_2025\context\'; %where original data got saved
    mkdir(info.savepath);
    
    % Ensure 1xN format for cell arrays
    info.mouse_date = reshape(info.mouse_date, 1, []);
    info.serverid = reshape(info.serverid, 1, []);
end

function info = get_info_params_updated()
    % Dataset and path information
    info.mouse_date = {'KN8-3L\2026-06-15','KN8-3L\2026-06-16','KN8-3L\2026-06-18','KN8-3L\2026-06-24','KN8-3L\2026-06-26','KN8-3L\2026-07-02','KN7-1L\2026-07-02','KW-2-1L\2026-07-01'};
    info.serverid = {'W:','W:','W:','W:','W:','W:','W:','W:'};
    info.mouseid = {1,1,1};
    info.mouse_date = {'KN8-3L\2026-06-15','KN8-3L\2026-06-16','KN8-3L\2026-06-18','KN8-3L\2026-06-24','KN8-3L\2026-06-26','KN8-3L\2026-07-02','KN7-1L\2026-07-02','KW-2-1L\2026-07-01'};
    info.serverid = {'W:','W:','W:','W:','W:','W:','W:','W:'};
    info.mouseid = {1,1,1,1,1,1,2,3};
    info.path_string = 'context_stim/updated'; %used get_vaid_stim_onsets_trials to get trials with imaging structure info (from context_stim/60)
    info.savepath = 'W:\Connie\results\Bassi2025\fig3\reviews';
    info.savepath_sounds = 'W:\Connie\results\Bassi2025\fig3\reviews\sounds';
end

function frames = get_frame_params()
    % Frame indices for analysis
    frames.before = 50:60;
    frames.after = 63:92;
    frames.stim = frames.before(end) + 1;
    frames.window = [60, 60];
end

function mod = get_modulation_params()
    % Modulation analysis parameters
    mod.mod_type = 'ctrl'; % 'prepost', 'ctrl', 'influence', 'prepost_sound'
    mod.mode = 'separate'; %'pooled', 'separate', 'simple'
    mod.response_range = {63:92; 51:60};
    mod.data_type_dff = 1; %dff or deconv
    mod.nShuffles = 10000; %total shuffles for bootstrapping
    mod.simple_or_not = 0; %if simple takes given trials and uses those to compute (no balancing or separating into left and right)
end

function mod = get_modulation_params_sounds()
    % Modulation analysis parameters
    mod.mod_type = 'prepost_sound'; % 'prepost', 'ctrl', 'influence', 'prepost_sound'
    mod.mode = 'separate';%'separate'; %'pooled', 'separate', 'simple'
    mod.response_range = {63:92; 51:60};
    mod.data_type_dff = 1; %dff or deconv
    mod.nShuffles = 10000; %total shuffles for bootstrapping
    mod.chosen_mice = 1:25;
end

function mod = get_selectivity_params_sounds()
    % Modulation analysis parameters
    mod.mod_type = 'prepost_ctrl'; % 'prepost', 'ctrl', 'influence', 'prepost_sound' 'prepost_sound'
    mod.mode = 'selectivity'; %'pooled', 'separate', 'simple'
    mod.response_range = {63:92; 51:60};
    mod.data_type_dff = 1; %dff or deconv
    mod.nShuffles = 10000; %total shuffles for bootstrapping
    mod.chosen_mice = 1:25;
end

function info = get_info_params_control_mice()
    % Dataset and path information
    %these includes most experiments for HA12,HA13,GE6 (HE1 probably has more)
    info.mouse_date_all={'HA12-00/2023-02-17','HA12-00/2023-02-24','HA12-00/2023-03-02','HA12-00/2023-03-17','HA12-00/2023-03-23','HA12-00/2023-04-11', ...
    'HA13-1L/2023-02-17','HA13-1L/2023-02-24','HA13-1L/2023-03-02','HA13-1L/2023-03-17','HA13-1L/2023-03-23','HA13-1L/2023-04-11', ...
    'GE6-1R/2022-10-13','GE6-1R/2022-10-18','GE6-1R/2022-10-20','HE1-00\2023-05-30','HE1-00\2023-05-31'};
    info.serverid_all = {'Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','V:','V:'};
    info.mouseid_all = {1 1 1 1 1 1  2 2 2 2 2 2  3 3 3 4 4};

    %IMPORTANT: using dates after the mice got habituated for HA12,HA13,HE1 (these are
    %mice that learned to run on the ball), GE6 was fully naive and never
    %learned to run so it had no behavioral or opto effects in any of its
    %sessions!
% %     info.mouse_date={'HA12-00/2023-03-17','HA12-00/2023-03-23','HA12-00/2023-04-11', ...
% %     'HA13-1L/2023-03-17','HA13-1L/2023-03-23','HA13-1L/2023-04-11', ...
% %     'GE6-1R/2022-10-13','GE6-1R/2022-10-18','GE6-1R/2022-10-20','HE1-00\2023-05-30','HE1-00\2023-05-31'}; 
% %     info.serverid = {'Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','Y:','V:','V:'};
% %     info.mouseid = {1 1 1  2 2 2  3 3 3 4 4}; %MISSING DATA FOR GE!!

    info.mouse_date={'HA12-00/2023-03-17','HA12-00/2023-03-23','HA12-00/2023-04-11', ...
    'HA13-1L/2023-03-17','HA13-1L/2023-03-23','HA13-1L/2023-04-11', ...
    'HE1-00\2023-05-30','HE1-00\2023-05-31'};
    info.serverid = {'Y:','Y:','Y:','Y:','Y:','Y:','V:','V:'};
    info.mouseid = {1 1 1  2 2 2 3 3};
    info.path_string = 'context_stim/updated'; %used get_vaid_stim_onsets_trials to get trials with imaging structure info (from context_stim/60)
    info.savepath = 'W:\Connie\results\Bassi2025\fig3\control_mice';
    info.savepath_sounds = 'W:\Connie\results\Bassi2025\fig3\sounds\control_mice';
    info.base_dir = 'V:\Connie\results\opto_sound_2025\context\'; %where original data got saved
    mkdir(info.savepath);
    
    % Ensure 1xN format for cell arrays
    info.mouse_date = reshape(info.mouse_date, 1, []);
    info.serverid = reshape(info.serverid, 1, []);
end