function [current_mice,onset_id, active_events, passive_events,task_event_type] = default_data_info(task_event_type)

    % Default event times
    passive_events = [7, 39, 71];
    active_events = [7, 39, 71, 132, 146];

    % ---------------------------------------------------------
    % All event types use the same datasets as OUTCOME
    % ---------------------------------------------------------
    current_mice = setdiff(1:25, [3, 8, 9, 21, 22, 23]);

    % ---------------------------------------------------------
    % Get onset_id based on the requested event type
    % ---------------------------------------------------------
    if iscell(task_event_type)
        % If multiple events are provided, determine onset_id
        % from the event type that is being requested.
        onset_id = [];%zeros(size(task_event_type));

        for i = 1%:numel(task_event_type)
            switch lower(task_event_type{i})
                case 'sound_category'
                    onset_id(i) = 1;

                case 'choice'
                    onset_id(i) = 4;

                case 'photostim'
                    onset_id(i) = 1;

                case 'outcome'
                    onset_id(i) = 5;

                otherwise
                    error('Unknown task_event_type: %s', task_event_type{i});
            end
        end
        task_event_type = task_event_type{1};

    else
        switch lower(task_event_type)
            case 'sound_category'
                onset_id = 1;

            case 'choice'
                onset_id = 4;

            case 'photostim'
                onset_id = 1;

            case 'outcome'
                onset_id = 5;

            otherwise
                error('Unknown task_event_type: %s', task_event_type);
        end
        task_event_type = task_event_type;
    end
end

