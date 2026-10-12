function additivity_stats = test_irrelevant_sound_additivity( ...
    context_data, chosen_datasets, pre_frames, post_frames, varargin)

% TEST_IRRELEVANT_SOUND_ADDITIVITY
%
% Tests whether responses to relevant + irrelevant input are consistent
% with linear summation of independently measured relevant and irrelevant
% responses.
%
%
% =============================================================
% ASSUMED CONTEXT STRUCTURE
% =============================================================
%
% Context 1 = Active
%   .ctrl = relevant sound alone
%   .stim = relevant + irrelevant input
%
% Context 2 = Passive
%   .ctrl = relevant sound alone
%   .stim = relevant + irrelevant input
%
% Context 3 = Irrelevant input alone
%   .stim = irrelevant input alone
%
%
% =============================================================
% RESPONSE MODES
% =============================================================
%
% 'response_mode', 'default'     [DEFAULT]
%
%       Additivity / interaction:
%           uses evoked response = post - pre
%
%       DeltaStim:
%           post(combined) - post(relevant)
%
%       Panel 4:
%           irrelevant-alone evoked response (post - pre)
%           vs
%           post-only DeltaStim
%
%
% 'response_mode', 'post_only'
%
%       Uses mean post-stimulus activity for ALL analyses:
%
%           predicted =
%               post(relevant) + post(irrelevant)
%
%           interaction =
%               post(combined) - predicted
%
%           DeltaStim =
%               post(combined) - post(relevant)
%
%           Panel 4:
%               post(irrelevant) vs DeltaStim
%
% NOTE:
%       This mode will generally double-count ongoing baseline activity
%       in the additive prediction. It is included as a sensitivity /
%       comparison analysis.
%
%
% 'response_mode', 'post_minus_pre'
%
%       Uses baseline-subtracted evoked responses for ALL analyses:
%
%           response = post - pre
%
%           predicted =
%               evoked(relevant) + evoked(irrelevant)
%
%           interaction =
%               evoked(combined) - predicted
%
%           DeltaStim =
%               evoked(combined) - evoked(relevant)
%
%           Panel 4:
%               evoked(irrelevant) vs evoked DeltaStim
%
%
% =============================================================
% OPTIONAL NEURON SELECTION
% =============================================================
%
% 'neuron_indices', sig_neurons
%
% where:
%
%       sig_neurons{1,dataset}
%
% contains the ORIGINAL neuron indices to include for each dataset.
%
% If neuron_indices = [] (default), all neurons are included.
%
% The same neuron subset is applied to relevant, combined, and
% irrelevant-alone conditions.
%
%
% =============================================================
% OPTIONAL INPUTS
% =============================================================
%
% 'figure_num'          default = 710
% 'save_directory'      default = []
% 'use_median_trials'   default = false
%
% 'color_by'
%       'dataset'
%       'mouse'
%       'none'
%
% 'mouse_ids'
%       one ID per dataset
%
% 'analysis_context'
%       default = 2
%
% 'irrelevant_context'
%       default = 3
%
% 'data_type'
%       default = 'dff'
%
% 'response_mode'
%       'default'
%       'post_only'
%       'post_minus_pre'
%
% 'neuron_indices'
%       default = []
%
%
% =============================================================
% OUTPUT
% =============================================================
%
% additivity_stats.neuron
% additivity_stats.dataset
% additivity_stats.mouse
% additivity_stats.population
% additivity_stats.settings


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONAL INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

addParameter(p, 'figure_num', 710);
addParameter(p, 'save_directory', []);
addParameter(p, 'use_median_trials', false);

addParameter(p, 'color_by', 'dataset');
addParameter(p, 'mouse_ids', []);

addParameter(p, 'analysis_context', 2);
addParameter(p, 'irrelevant_context', 3);

addParameter(p, 'data_type', 'dff');

addParameter(p, 'response_mode', 'default');

addParameter(p, 'neuron_indices', []);

parse(p, varargin{:});


figure_num = ...
    p.Results.figure_num;

save_directory = ...
    p.Results.save_directory;

use_median_trials = ...
    p.Results.use_median_trials;

color_by = ...
    lower(string(p.Results.color_by));

mouse_ids = ...
    p.Results.mouse_ids;

analysis_context = ...
    p.Results.analysis_context;

irrelevant_context = ...
    p.Results.irrelevant_context;

data_type = ...
    p.Results.data_type;

response_mode = ...
    lower(string(p.Results.response_mode));

neuron_indices = ...
    p.Results.neuron_indices;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK RESPONSE MODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

valid_response_modes = [ ...
    "default", ...
    "post_only", ...
    "post_minus_pre"];


if ~ismember(response_mode, valid_response_modes)

    error( ...
        ['response_mode must be ''default'', ' ...
         '''post_only'', or ''post_minus_pre''.']);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE IDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(mouse_ids)

    mouse_ids = ...
        string(mouse_ids(:));

    if numel(mouse_ids) < chosen_datasets

        error( ...
            'mouse_ids must contain one ID per dataset.');

    end

end


if color_by == "mouse" && isempty(mouse_ids)

    error( ...
        'mouse_ids must be provided when color_by = ''mouse''.');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK NEURON INDEX CELL ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(neuron_indices)

    if ~iscell(neuron_indices)

        error( ...
            'neuron_indices must be a cell array.');

    end

    if numel(neuron_indices) < chosen_datasets

        error( ...
            ['neuron_indices must contain at least one ' ...
             'entry per chosen dataset.']);

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Raw components
all_rel_pre = [];
all_rel_post = [];
all_rel_evoked = [];

all_irrel_pre = [];
all_irrel_post = [];
all_irrel_evoked = [];

all_combined_pre = [];
all_combined_post = [];
all_combined_evoked = [];


% Responses actually used in primary analysis
all_rel_analysis = [];
all_irrel_analysis = [];
all_combined_analysis = [];

all_predicted = [];
all_interaction = [];

all_deltaStim = [];
all_deltaStim_error = [];

all_baseline_delta = [];


% IDs
all_dataset_id = [];
all_neuron_id = [];

all_mouse_id = ...
    strings(0,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATASET-LEVEL STORAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataset_mean_interaction = ...
    nan(chosen_datasets,1);

dataset_median_interaction = ...
    nan(chosen_datasets,1);


dataset_r_predicted = ...
    nan(chosen_datasets,1);

dataset_p_predicted = ...
    nan(chosen_datasets,1);


dataset_r_deltaStim = ...
    nan(chosen_datasets,1);

dataset_p_deltaStim = ...
    nan(chosen_datasets,1);


dataset_mean_deltaStim_error = ...
    nan(chosen_datasets,1);

dataset_median_deltaStim_error = ...
    nan(chosen_datasets,1);


dataset_mean_baseline_delta = ...
    nan(chosen_datasets,1);


dataset_n_neurons = ...
    nan(chosen_datasets,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOOP DATASETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for dataset = 1:chosen_datasets


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GET DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rel_data = ...
        context_data.(data_type){ ...
        analysis_context,dataset}.ctrl;


    combined_data = ...
        context_data.(data_type){ ...
        analysis_context,dataset}.stim;


    irrel_data = ...
        context_data.(data_type){ ...
        irrelevant_context,dataset}.stim;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(rel_data) || ...
            isempty(combined_data) || ...
            isempty(irrel_data)

        warning( ...
            'Dataset %d contains empty data. Skipping.', ...
            dataset);

        continue

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK NEURON COUNTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    n_rel = ...
        size(rel_data,3);

    n_combined = ...
        size(combined_data,3);

    n_irrel = ...
        size(irrel_data,3);


    if ~( ...
            n_rel == n_combined && ...
            n_rel == n_irrel)

        warning( ...
            ['Dataset %d has mismatched neuron counts: ' ...
             'rel=%d, combined=%d, irrel=%d. Skipping.'], ...
            dataset, ...
            n_rel, ...
            n_combined, ...
            n_irrel);

        continue

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OPTIONAL NEURON SELECTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(neuron_indices)

        curr_neurons = ...
            neuron_indices{1,dataset};


        if isempty(curr_neurons)

            warning( ...
                ['Dataset %d has no selected neurons. ' ...
                 'Skipping.'], ...
                dataset);

            continue

        end


        curr_neurons = ...
            curr_neurons(:);


        % Remove NaNs / nonfinite values
        curr_neurons = ...
            curr_neurons( ...
                isfinite(curr_neurons));


        % Keep valid integer indices
        curr_neurons = ...
            curr_neurons( ...
                curr_neurons >= 1 & ...
                curr_neurons <= n_rel & ...
                mod(curr_neurons,1) == 0);


        % Remove duplicates while preserving order
        curr_neurons = ...
            unique( ...
                curr_neurons, ...
                'stable');


        if isempty(curr_neurons)

            warning( ...
                ['Dataset %d contains no valid neuron indices ' ...
                 'after range checking. Skipping.'], ...
                dataset);

            continue

        end


        rel_data = ...
            rel_data(:,:,curr_neurons);

        combined_data = ...
            combined_data(:,:,curr_neurons);

        irrel_data = ...
            irrel_data(:,:,curr_neurons);


    else

        curr_neurons = ...
            (1:n_rel)';

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GET PRE / POST / EVOKED RESPONSES
    %
    % outputs:
    %       trials x neurons
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [ ...
        rel_pre_trials, ...
        rel_post_trials, ...
        rel_evoked_trials ...
        ] = ...
        get_trial_components( ...
            rel_data, ...
            pre_frames, ...
            post_frames);


    [ ...
        combined_pre_trials, ...
        combined_post_trials, ...
        combined_evoked_trials ...
        ] = ...
        get_trial_components( ...
            combined_data, ...
            pre_frames, ...
            post_frames);


    [ ...
        irrel_pre_trials, ...
        irrel_post_trials, ...
        irrel_evoked_trials ...
        ] = ...
        get_trial_components( ...
            irrel_data, ...
            pre_frames, ...
            post_frames);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SUMMARIZE ACROSS TRIALS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rel_pre = ...
        summarize_trials( ...
            rel_pre_trials, ...
            use_median_trials);

    rel_post = ...
        summarize_trials( ...
            rel_post_trials, ...
            use_median_trials);

    rel_evoked = ...
        summarize_trials( ...
            rel_evoked_trials, ...
            use_median_trials);


    combined_pre = ...
        summarize_trials( ...
            combined_pre_trials, ...
            use_median_trials);

    combined_post = ...
        summarize_trials( ...
            combined_post_trials, ...
            use_median_trials);

    combined_evoked = ...
        summarize_trials( ...
            combined_evoked_trials, ...
            use_median_trials);


    irrel_pre = ...
        summarize_trials( ...
            irrel_pre_trials, ...
            use_median_trials);

    irrel_post = ...
        summarize_trials( ...
            irrel_post_trials, ...
            use_median_trials);

    irrel_evoked = ...
        summarize_trials( ...
            irrel_evoked_trials, ...
            use_median_trials);


    % Convert to column vectors

    rel_pre = ...
        rel_pre(:);

    rel_post = ...
        rel_post(:);

    rel_evoked = ...
        rel_evoked(:);


    combined_pre = ...
        combined_pre(:);

    combined_post = ...
        combined_post(:);

    combined_evoked = ...
        combined_evoked(:);


    irrel_pre = ...
        irrel_pre(:);

    irrel_post = ...
        irrel_post(:);

    irrel_evoked = ...
        irrel_evoked(:);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SELECT RESPONSE DEFINITIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    switch response_mode


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DEFAULT PRIMARY ANALYSIS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        case "default"

            % Additivity:
            % use baseline-subtracted evoked responses

            rel_analysis = ...
                rel_evoked;

            combined_analysis = ...
                combined_evoked;

            irrel_analysis = ...
                irrel_evoked;


            % Original manuscript DeltaStim:
            % POST only

            deltaStim = ...
                combined_post - rel_post;


            % Panel 4 comparison:
            % independently measured IRREL EVOKED response

            irrel_for_deltaStim = ...
                irrel_evoked;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % POST ONLY EVERYWHERE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        case "post_only"

            rel_analysis = ...
                rel_post;

            combined_analysis = ...
                combined_post;

            irrel_analysis = ...
                irrel_post;


            deltaStim = ...
                combined_post - rel_post;


            irrel_for_deltaStim = ...
                irrel_post;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % POST - PRE EVERYWHERE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        case "post_minus_pre"

            rel_analysis = ...
                rel_evoked;

            combined_analysis = ...
                combined_evoked;

            irrel_analysis = ...
                irrel_evoked;


            deltaStim = ...
                combined_evoked - rel_evoked;


            irrel_for_deltaStim = ...
                irrel_evoked;

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ADDITIVE MODEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    predicted_response = ...
        rel_analysis + irrel_analysis;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INTERACTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    interaction = ...
        combined_analysis - predicted_response;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DELTASTIM ERROR
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    deltaStim_error = ...
        deltaStim - irrel_for_deltaStim;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % BASELINE DIFFERENCE
    %
    % useful for comparing default post-only
    % DeltaStim against evoked DeltaStim
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    baseline_delta = ...
        combined_pre - rel_pre;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % REMOVE NaNs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    good_idx = ...
        ~isnan(rel_analysis) & ...
        ~isnan(irrel_analysis) & ...
        ~isnan(combined_analysis) & ...
        ~isnan(deltaStim) & ...
        ~isnan(irrel_for_deltaStim);


    % Raw components

    rel_pre = ...
        rel_pre(good_idx);

    rel_post = ...
        rel_post(good_idx);

    rel_evoked = ...
        rel_evoked(good_idx);


    combined_pre = ...
        combined_pre(good_idx);

    combined_post = ...
        combined_post(good_idx);

    combined_evoked = ...
        combined_evoked(good_idx);


    irrel_pre = ...
        irrel_pre(good_idx);

    irrel_post = ...
        irrel_post(good_idx);

    irrel_evoked = ...
        irrel_evoked(good_idx);


    % Analysis variables

    rel_analysis = ...
        rel_analysis(good_idx);

    combined_analysis = ...
        combined_analysis(good_idx);

    irrel_analysis = ...
        irrel_analysis(good_idx);


    predicted_response = ...
        predicted_response(good_idx);

    interaction = ...
        interaction(good_idx);

    deltaStim = ...
        deltaStim(good_idx);

    irrel_for_deltaStim = ...
        irrel_for_deltaStim(good_idx);

    deltaStim_error = ...
        deltaStim_error(good_idx);

    baseline_delta = ...
        baseline_delta(good_idx);


    % Preserve ORIGINAL dataset neuron IDs

    neuron_ids = ...
        curr_neurons(good_idx);


    n_good = ...
        length(interaction);


    dataset_n_neurons(dataset) = ...
        n_good;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DATASET SUMMARIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dataset_mean_interaction(dataset) = ...
        mean( ...
            interaction, ...
            'omitnan');


    dataset_median_interaction(dataset) = ...
        median( ...
            interaction, ...
            'omitnan');


    dataset_mean_deltaStim_error(dataset) = ...
        mean( ...
            deltaStim_error, ...
            'omitnan');


    dataset_median_deltaStim_error(dataset) = ...
        median( ...
            deltaStim_error, ...
            'omitnan');


    dataset_mean_baseline_delta(dataset) = ...
        mean( ...
            baseline_delta, ...
            'omitnan');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DATASET CORRELATIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if n_good > 2


        [r,p_corr] = corr( ...
            predicted_response, ...
            combined_analysis, ...
            'rows','complete', ...
            'type','Pearson');


        dataset_r_predicted(dataset) = ...
            r;

        dataset_p_predicted(dataset) = ...
            p_corr;


        [r,p_corr] = corr( ...
            irrel_for_deltaStim, ...
            deltaStim, ...
            'rows','complete', ...
            'type','Pearson');


        dataset_r_deltaStim(dataset) = ...
            r;

        dataset_p_deltaStim(dataset) = ...
            p_corr;

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CONCATENATE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    all_rel_pre = ...
        [all_rel_pre; rel_pre];

    all_rel_post = ...
        [all_rel_post; rel_post];

    all_rel_evoked = ...
        [all_rel_evoked; rel_evoked];


    all_irrel_pre = ...
        [all_irrel_pre; irrel_pre];

    all_irrel_post = ...
        [all_irrel_post; irrel_post];

    all_irrel_evoked = ...
        [all_irrel_evoked; irrel_evoked];


    all_combined_pre = ...
        [all_combined_pre; combined_pre];

    all_combined_post = ...
        [all_combined_post; combined_post];

    all_combined_evoked = ...
        [all_combined_evoked; combined_evoked];


    all_rel_analysis = ...
        [all_rel_analysis; rel_analysis];

    all_irrel_analysis = ...
        [all_irrel_analysis; irrel_analysis];

    all_combined_analysis = ...
        [all_combined_analysis; combined_analysis];


    all_predicted = ...
        [all_predicted; predicted_response];

    all_interaction = ...
        [all_interaction; interaction];


    all_deltaStim = ...
        [all_deltaStim; deltaStim];

    all_deltaStim_error = ...
        [all_deltaStim_error; deltaStim_error];

    all_baseline_delta = ...
        [all_baseline_delta; baseline_delta];


    all_dataset_id = ...
        [all_dataset_id; ...
         repmat(dataset,n_good,1)];


    all_neuron_id = ...
        [all_neuron_id; neuron_ids];


    if ~isempty(mouse_ids)

        all_mouse_id = ...
            [all_mouse_id; ...
             repmat(mouse_ids(dataset),n_good,1)];

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATASET-LEVEL INTERACTION TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

good_datasets = ...
    ~isnan(dataset_mean_interaction);


dataset_interactions = ...
    dataset_mean_interaction(good_datasets);


if ~isempty(dataset_interactions)

    p_interaction_dataset = ...
        permutationTest_updatedcb( ...
            dataset_interactions, ...
            zeros(size(dataset_interactions)), ...
            10000, ...
            'paired', ...
            1);

else

    p_interaction_dataset = ...
        NaN;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE-LEVEL AGGREGATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mouse_mean_interaction = [];
mouse_median_interaction = [];
mouse_n_datasets = [];

unique_mice_valid = ...
    strings(0,1);

p_interaction_mouse = ...
    NaN;


if ~isempty(mouse_ids)

    unique_mice = ...
        unique( ...
            mouse_ids, ...
            'stable');


    n_mice = ...
        length(unique_mice);


    mouse_mean_interaction = ...
        nan(n_mice,1);

    mouse_median_interaction = ...
        nan(n_mice,1);

    mouse_n_datasets = ...
        nan(n_mice,1);


    for mouseIdx = 1:n_mice

        curr_mouse = ...
            unique_mice(mouseIdx);


        curr_dataset_idx = ...
            mouse_ids == curr_mouse & ...
            ~isnan(dataset_mean_interaction);


        curr_values = ...
            dataset_mean_interaction( ...
                curr_dataset_idx);


        mouse_n_datasets(mouseIdx) = ...
            sum(curr_dataset_idx);


        if ~isempty(curr_values)

            mouse_mean_interaction(mouseIdx) = ...
                mean( ...
                    curr_values, ...
                    'omitnan');


            mouse_median_interaction(mouseIdx) = ...
                median( ...
                    curr_values, ...
                    'omitnan');

        end

    end


    good_mice = ...
        ~isnan(mouse_mean_interaction);


    mouse_mean_interaction = ...
        mouse_mean_interaction(good_mice);

    mouse_median_interaction = ...
        mouse_median_interaction(good_mice);

    mouse_n_datasets = ...
        mouse_n_datasets(good_mice);

    unique_mice_valid = ...
        unique_mice(good_mice);


    if ~isempty(mouse_mean_interaction)

        p_interaction_mouse = ...
            permutationTest_updatedcb( ...
                mouse_mean_interaction, ...
                zeros(size(mouse_mean_interaction)), ...
                10000, ...
                'paired', ...
                1);

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POPULATION CORRELATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[r_pred,p_pred] = corr( ...
    all_predicted, ...
    all_combined_analysis, ...
    'rows','complete', ...
    'type','Pearson');


[r_delta,p_delta] = corr( ...
    all_irrel_analysis, ...
    all_deltaStim, ...
    'rows','complete', ...
    'type','Pearson');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT:
%
% In default mode, all_irrel_analysis is the
% evoked irrelevant-alone response, so this is
% exactly the desired Panel 4 comparison.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NONLINEARITY SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

percent_sublinear = ...
    100 * mean( ...
        all_interaction < 0);


percent_supralinear = ...
    100 * mean( ...
        all_interaction > 0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLOR GROUPS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch color_by


    case "dataset"

        group_id = ...
            all_dataset_id;

        unique_groups = ...
            unique( ...
                group_id, ...
                'stable');

        cmap = ...
            jet(length(unique_groups));


    case "mouse"

        group_id = ...
            all_mouse_id;

        unique_groups = ...
            unique( ...
                group_id, ...
                'stable');

        cmap = ...
            jet(length(unique_groups));


    case "none"

        group_id = [];
        unique_groups = [];
        cmap = [];


    otherwise

        error( ...
            ['color_by must be ''dataset'', ' ...
             '''mouse'', or ''none''.']);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POINT COLORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if color_by == "none"

    point_colors = ...
        repmat( ...
            [0 0.4470 0.7410], ...
            length(all_dataset_id), ...
            1);

else

    point_colors = ...
        nan( ...
            length(all_dataset_id), ...
            3);


    for groupIdx = 1:length(unique_groups)

        idx = ...
            group_id == ...
            unique_groups(groupIdx);


        point_colors(idx,:) = ...
            repmat( ...
                cmap(groupIdx,:), ...
                sum(idx), ...
                1);

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STORE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

additivity_stats.settings.data_type = ...
    data_type;


additivity_stats.settings.response_mode = ...
    response_mode;


additivity_stats.settings.neuron_selection_applied = ...
    ~isempty(neuron_indices);


if response_mode == "default"

    additivity_stats.settings.additivity_definition = ...
        'post_minus_pre';

    additivity_stats.settings.deltaStim_definition = ...
        'post_combined_minus_post_relevant';

    additivity_stats.settings.panel4_irrel_definition = ...
        'post_minus_pre';

else

    additivity_stats.settings.additivity_definition = ...
        char(response_mode);

    additivity_stats.settings.deltaStim_definition = ...
        char(response_mode);

    additivity_stats.settings.panel4_irrel_definition = ...
        char(response_mode);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEURON OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

additivity_stats.neuron.rel_pre = ...
    all_rel_pre;

additivity_stats.neuron.rel_post = ...
    all_rel_post;

additivity_stats.neuron.rel_evoked = ...
    all_rel_evoked;


additivity_stats.neuron.irrel_pre = ...
    all_irrel_pre;

additivity_stats.neuron.irrel_post = ...
    all_irrel_post;

additivity_stats.neuron.irrel_evoked = ...
    all_irrel_evoked;


additivity_stats.neuron.combined_pre = ...
    all_combined_pre;

additivity_stats.neuron.combined_post = ...
    all_combined_post;

additivity_stats.neuron.combined_evoked = ...
    all_combined_evoked;


additivity_stats.neuron.rel_analysis = ...
    all_rel_analysis;

additivity_stats.neuron.irrel_analysis = ...
    all_irrel_analysis;

additivity_stats.neuron.combined_analysis = ...
    all_combined_analysis;


additivity_stats.neuron.predicted = ...
    all_predicted;

additivity_stats.neuron.interaction = ...
    all_interaction;


additivity_stats.neuron.deltaStim = ...
    all_deltaStim;

additivity_stats.neuron.deltaStim_error = ...
    all_deltaStim_error;


additivity_stats.neuron.baseline_delta = ...
    all_baseline_delta;


additivity_stats.neuron.dataset_id = ...
    all_dataset_id;

additivity_stats.neuron.neuron_id = ...
    all_neuron_id;


if ~isempty(mouse_ids)

    additivity_stats.neuron.mouse_id = ...
        all_mouse_id;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATASET OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

additivity_stats.dataset.mean_interaction = ...
    dataset_mean_interaction;

additivity_stats.dataset.median_interaction = ...
    dataset_median_interaction;


additivity_stats.dataset.r_predicted = ...
    dataset_r_predicted;

additivity_stats.dataset.p_predicted = ...
    dataset_p_predicted;


additivity_stats.dataset.r_deltaStim = ...
    dataset_r_deltaStim;

additivity_stats.dataset.p_deltaStim = ...
    dataset_p_deltaStim;


additivity_stats.dataset.mean_deltaStim_error = ...
    dataset_mean_deltaStim_error;

additivity_stats.dataset.median_deltaStim_error = ...
    dataset_median_deltaStim_error;


additivity_stats.dataset.mean_baseline_delta = ...
    dataset_mean_baseline_delta;


additivity_stats.dataset.n_neurons = ...
    dataset_n_neurons;


additivity_stats.dataset.p_interaction = ...
    p_interaction_dataset;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(mouse_ids)

    additivity_stats.mouse.ids = ...
        unique_mice_valid;


    additivity_stats.mouse.mean_interaction = ...
        mouse_mean_interaction;


    additivity_stats.mouse.median_interaction = ...
        mouse_median_interaction;


    additivity_stats.mouse.n_datasets = ...
        mouse_n_datasets;


    additivity_stats.mouse.p_interaction = ...
        p_interaction_mouse;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POPULATION OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

additivity_stats.population.r_predicted_vs_observed = ...
    r_pred;

additivity_stats.population.p_predicted_vs_observed = ...
    p_pred;


additivity_stats.population.r_deltaStim_vs_irrel = ...
    r_delta;

additivity_stats.population.p_deltaStim_vs_irrel = ...
    p_delta;


additivity_stats.population.mean_interaction = ...
    mean( ...
        all_interaction, ...
        'omitnan');


additivity_stats.population.median_interaction = ...
    median( ...
        all_interaction, ...
        'omitnan');


additivity_stats.population.percent_sublinear = ...
    percent_sublinear;


additivity_stats.population.percent_supralinear = ...
    percent_supralinear;


additivity_stats.population.mean_baseline_delta = ...
    mean( ...
        all_baseline_delta, ...
        'omitnan');


additivity_stats.population.n_neurons = ...
    length(all_interaction);


additivity_stats.population.n_datasets = ...
    sum(good_datasets);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(figure_num);

set( ...
    gcf, ...
    'Position', ...
    [100,100,700,400]);

clf;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 1
% PREDICTED VS OBSERVED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,1);

set(gca,'FontSize',7);

hold on;


scatter( ...
    all_predicted, ...
    all_combined_analysis, ...
    10, ...
    point_colors, ...
    'filled');


lims = [ ...
    min([all_predicted; all_combined_analysis]), ...
    max([all_predicted; all_combined_analysis])];


plot( ...
    lims, ...
    lims, ...
    'k--', ...
    'LineWidth',1);


xlim(lims);
ylim(lims);


xlabel( ...
    'Predicted additive response');


ylabel( ...
    'Observed Rel. + Irrel. response');


title( ...
    sprintf( ...
        'r = %.2f, p = %.2g', ...
        r_pred, ...
        p_pred), ...
    'FontWeight','normal');


axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 2
% NEURON-LEVEL INTERACTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,2);

set(gca,'FontSize',7);

hold on;


x_jitter = ...
    1 + ...
    (rand(size(all_interaction))-0.5)*0.2;


scatter( ...
    x_jitter, ...
    all_interaction, ...
    8, ...
    point_colors, ...
    'filled');


yline( ...
    0, ...
    'k--');


mean_interaction = ...
    mean( ...
        all_interaction, ...
        'omitnan');


sem_interaction = ...
    std( ...
        all_interaction, ...
        'omitnan') / ...
    sqrt( ...
        sum(~isnan(all_interaction)));


errorbar( ...
    1, ...
    mean_interaction, ...
    sem_interaction, ...
    'ko', ...
    'MarkerFaceColor','k', ...
    'LineWidth',1.5, ...
    'CapSize',6);


xlim([0.5 1.5]);

xticks(1);

xticklabels( ...
    {'Interaction'});


ylabel( ...
    'Observed - predicted additive');


title( ...
    sprintf( ...
        '%.1f%% sublinear', ...
        percent_sublinear), ...
    'FontWeight','normal');


axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 3
% DATASET OR MOUSE INTERACTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,3);

set(gca,'FontSize',7);

hold on;


if color_by == "mouse" && ...
        ~isempty(mouse_ids)


    for mouseIdx = ...
            1:length(mouse_mean_interaction)

        groupIdx = ...
            find( ...
                unique_groups == ...
                unique_mice_valid(mouseIdx), ...
                1);


        curr_color = ...
            cmap(groupIdx,:);


        scatter( ...
            1 + (rand-0.5)*0.12, ...
            mouse_mean_interaction(mouseIdx), ...
            45, ...
            curr_color, ...
            'filled');

    end


    group_mean = ...
        mean( ...
            mouse_mean_interaction, ...
            'omitnan');


    group_sem = ...
        std( ...
            mouse_mean_interaction, ...
            'omitnan') / ...
        sqrt( ...
            sum(~isnan(mouse_mean_interaction)));


    errorbar( ...
        1, ...
        group_mean, ...
        group_sem, ...
        'ko', ...
        'MarkerFaceColor','k', ...
        'LineWidth',1.5, ...
        'CapSize',6);


    xlim([0.5 1.5]);

    xticks(1);

    xticklabels( ...
        {'Mouse mean'});


    ylabel( ...
        'Interaction');


    title( ...
        sprintf( ...
            'p = %.3g', ...
            p_interaction_mouse), ...
        'FontWeight','normal');


else


    good_dataset_ids = ...
        find(good_datasets);


    for ii = ...
            1:length(good_dataset_ids)

        dataset = ...
            good_dataset_ids(ii);


        if color_by == "dataset"

            groupIdx = ...
                find( ...
                    unique_groups == dataset, ...
                    1);

            curr_color = ...
                cmap(groupIdx,:);


        elseif color_by == "mouse" && ...
                ~isempty(mouse_ids)

            curr_mouse = ...
                mouse_ids(dataset);

            groupIdx = ...
                find( ...
                    unique_groups == curr_mouse, ...
                    1);

            curr_color = ...
                cmap(groupIdx,:);


        else

            curr_color = ...
                [0 0.4470 0.7410];

        end


        scatter( ...
            1 + (rand-0.5)*0.12, ...
            dataset_mean_interaction(dataset), ...
            35, ...
            curr_color, ...
            'filled');

    end


    group_mean = ...
        mean( ...
            dataset_interactions, ...
            'omitnan');


    group_sem = ...
        std( ...
            dataset_interactions, ...
            'omitnan') / ...
        sqrt( ...
            sum(~isnan(dataset_interactions)));


    errorbar( ...
        1, ...
        group_mean, ...
        group_sem, ...
        'ko', ...
        'MarkerFaceColor','k', ...
        'LineWidth',1.5, ...
        'CapSize',6);


    xlim([0.5 1.5]);

    xticks(1);

    xticklabels( ...
        {'Dataset mean'});


    ylabel( ...
        'Interaction');


    title( ...
        sprintf( ...
            'p = %.3g', ...
            p_interaction_dataset), ...
        'FontWeight','normal');

end


yline( ...
    0, ...
    'k--');


axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 4
% IRRELEVANT RESPONSE VS DELTASTIM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,4);

set(gca,'FontSize',7);

hold on;


scatter( ...
    all_irrel_analysis, ...
    all_deltaStim, ...
    10, ...
    point_colors, ...
    'filled');


lims = [ ...
    min([all_irrel_analysis; all_deltaStim]), ...
    max([all_irrel_analysis; all_deltaStim])];


plot( ...
    lims, ...
    lims, ...
    'k--', ...
    'LineWidth',1);


xlim(lims);
ylim(lims);


if response_mode == "default"

    xlabel( ...
        'Measured Irrel. evoked response');

    ylabel( ...
        '\DeltaStim: post(Rel.+Irrel.) - post(Rel.)');

else

    xlabel( ...
        sprintf( ...
            'Measured Irrel. (%s)', ...
            char(response_mode)));

    ylabel( ...
        sprintf( ...
            '\\DeltaStim (%s)', ...
            char(response_mode)));

end


title( ...
    sprintf( ...
        'r = %.2f, p = %.2g', ...
        r_delta, ...
        p_delta), ...
    'FontWeight','normal');


axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINT SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');

fprintf( ...
    '==============================================\n');

fprintf( ...
    'Relevant + irrelevant additivity analysis\n');

fprintf( ...
    '==============================================\n');


fprintf( ...
    'Data type: %s\n', ...
    char(data_type));


fprintf( ...
    'Response mode: %s\n', ...
    char(response_mode));


if isempty(neuron_indices)

    fprintf( ...
        'Neuron selection: all neurons\n');

else

    fprintf( ...
        'Neuron selection: supplied neuron indices\n');

end


fprintf( ...
    'Neurons analyzed: %d\n', ...
    length(all_interaction));


fprintf( ...
    'Datasets analyzed: %d\n', ...
    sum(good_datasets));


fprintf('\n');


if response_mode == "default"

    fprintf( ...
        ['Additivity: post - pre\n' ...
         'DeltaStim: post(combined) - post(relevant)\n' ...
         'Panel 4 Irrel.: post - pre\n']);

elseif response_mode == "post_only"

    fprintf( ...
        'All analyses use post-only responses.\n');

elseif response_mode == "post_minus_pre"

    fprintf( ...
        'All analyses use post - pre responses.\n');

end


fprintf('\n');


fprintf( ...
    'Mean neuron interaction = %.4f\n', ...
    mean( ...
        all_interaction, ...
        'omitnan'));


fprintf( ...
    'Median neuron interaction = %.4f\n', ...
    median( ...
        all_interaction, ...
        'omitnan'));


fprintf( ...
    'Sublinear neurons = %.1f%%\n', ...
    percent_sublinear);


fprintf( ...
    'Supralinear neurons = %.1f%%\n', ...
    percent_supralinear);


fprintf('\n');


fprintf( ...
    'Dataset-level interaction vs zero: p = %.6g\n', ...
    p_interaction_dataset);


if ~isempty(mouse_ids)

    fprintf( ...
        'Mouse-level interaction vs zero: p = %.6g\n', ...
        p_interaction_mouse);

end


fprintf('\n');


fprintf( ...
    ['Predicted vs observed: ' ...
     'r = %.3f, p = %.6g\n'], ...
    r_pred, ...
    p_pred);


fprintf( ...
    ['Measured irrelevant vs DeltaStim: ' ...
     'r = %.3f, p = %.6g\n'], ...
    r_delta, ...
    p_delta);


fprintf( ...
    ['Mean combined - relevant pre-stim baseline ' ...
     'difference = %.4f\n'], ...
    mean( ...
        all_baseline_delta, ...
        'omitnan'));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(mouse_ids)

    fprintf('\n');

    fprintf( ...
        '==============================================\n');

    fprintf( ...
        'Mouse-level summary\n');

    fprintf( ...
        '==============================================\n');


    for mouseIdx = ...
            1:length(unique_mice_valid)

        fprintf( ...
            ['Mouse %s: mean interaction = %.4f, ' ...
             'n datasets = %d\n'], ...
            unique_mice_valid(mouseIdx), ...
            mouse_mean_interaction(mouseIdx), ...
            mouse_n_datasets(mouseIdx));

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(save_directory)

    if isempty(neuron_indices)

        neuron_label = ...
            'allneurons';

    else

        neuron_label = ...
            'selectedneurons';

    end


    filename_base = ...
        ['irrelevant_input_additivity_' ...
         char(color_by) ...
         '_datatype_' ...
         char(data_type) ...
         '_response_' ...
         char(response_mode) ...
         '_' ...
         neuron_label];


    exportgraphics( ...
        figure(figure_num), ...
        fullfile( ...
            save_directory, ...
            [filename_base '.pdf']), ...
        'ContentType','vector');


    saveas( ...
        figure(figure_num), ...
        fullfile( ...
            save_directory, ...
            [filename_base '.fig']));


    save( ...
        fullfile( ...
            save_directory, ...
            [filename_base '_stats.mat']), ...
        'additivity_stats');

end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER:
% GET PRE, POST, AND EVOKED RESPONSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pre_response, post_response, evoked_response] = ...
    get_trial_components( ...
        trial_data, pre_frames, post_frames)

% trial_data:
%       trials x frames x neurons
%
% outputs:
%       trials x neurons


pre_response = ...
    squeeze( ...
        mean( ...
            trial_data(:,pre_frames,:), ...
            2, ...
            'omitnan'));


post_response = ...
    squeeze( ...
        mean( ...
            trial_data(:,post_frames,:), ...
            2, ...
            'omitnan'));


evoked_response = ...
    post_response - pre_response;

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER:
% SUMMARIZE TRIALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function response = ...
    summarize_trials( ...
        trial_response, use_median_trials)


if use_median_trials

    response = ...
        median( ...
            trial_response, ...
            1, ...
            'omitnan');

else

    response = ...
        mean( ...
            trial_response, ...
            1, ...
            'omitnan');

end

end
