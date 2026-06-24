function trials_by_condition = find_trial_conditions(condition_type, varargin)

p = inputParser;
addParameter(p,'first_repeat',[]);
parse(p,varargin{:});

first_repeat = p.Results.first_repeat;

unique_conditions = unique(condition_type);

trials_by_condition = cell(length(unique_conditions),1);

for c = 1:length(unique_conditions)

    trials = find(condition_type == unique_conditions(c));

    % Only keep trials present in first_repeat if provided
    if ~isempty(first_repeat)
        trials = trials(ismember(trials, first_repeat));
    end

    trials_by_condition{c} = trials;

end

end