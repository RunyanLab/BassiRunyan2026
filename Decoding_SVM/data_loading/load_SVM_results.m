function loaded_svm_result = load_SVM_results( ...
    info, model_type, task_event_type, svm_result_to_load, varargin)

% Optional inputs:
%   'base_dir' : public or local base directory
%   other optional strings (kept for backward compatibility)

p = inputParser;
addParameter(p, 'base_dir', '', @ischar);
addOptional(p, 'svm_subdir', '', @ischar);  % replaces old varargin{1}
parse(p, varargin{:});

base_dir   = p.Results.base_dir;
svm_subdir = p.Results.svm_subdir;

% loaded_svm_result = cell(1, length(info.chosen_mice));
loaded_svm_result = {};
count = 0;
for n = 1:length(info.chosen_mice)

    % Mouse/date string (e.g. mouse/date or mouse\date)
    mm = info.mouse_date(info.chosen_mice(n));
    mm = mm{1};

    % ---------------------------------------------------------------------
    % Decide where data live
    % ---------------------------------------------------------------------
    if ~isempty(base_dir)
        % PUBLIC / SHARED PATH
        base = fullfile(base_dir, mm, model_type, 'decoding', ...
                        ['SVM' svm_subdir]);
    else
        % BACKWARD-COMPATIBILITY (private server layout)
        ss = info.serverid(info.chosen_mice(n));
        ss = ss{1};

        base = fullfile(num2str(ss), 'Connie', 'ProcessedData', ...
                        mm, model_type, 'decoding', ['SVM' svm_subdir]);
    end

    % ---------------------------------------------------------------------
    % Load result
    % ---------------------------------------------------------------------
    filename = sprintf('%s_%s.mat', task_event_type, svm_result_to_load);
    filepath = fullfile(base, filename);

    
    if exist(filepath, 'file')
        count = count+1;
        tmp = load(filepath);
        loaded_svm_result{count} = tmp.(svm_result_to_load);
%     else
%         loaded_svm_result{n} = [];
    end

end
end

% model_type = 'GLM_3nmf_passive';
% task_event_type = 'sound_category';
% model_type = 'GLM_3nmf_passive';
% missing_indices = [];
% for m = 1:length(info.mouse_date)
%     mm = info.mouse_date(m);
%     mm = mm{1,1};
%     ss = info.serverid(m);
%     ss = ss {1,1};
%     base = (strcat(num2str(ss),'/Connie/ProcessedData/',num2str(mm),'/', model_type, '/decoding/'));
%     filepath = ([base 'sound_category_svm_info.mat']);
%     if isfile(filepath)
%         load(filepath);
%     else
%         disp(['File missing for index: ' num2str(m)]);
%         missing_indices = [missing_indices; m-1]; % Record the index of the missing file
%     end
% end
% % Display all missing indices
% disp('Indices of datasets with missing files:');
% disp(missing_indices);
