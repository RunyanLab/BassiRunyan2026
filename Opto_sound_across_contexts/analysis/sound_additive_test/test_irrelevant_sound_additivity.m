function additivity_stats = test_irrelevant_sound_additivity( ...
    context_data, chosen_datasets, pre_frames, post_frames, varargin)

% TEST_IRRELEVANT_SOUND_ADDITIVITY
%
% Tests whether responses to relevant + irrelevant input are consistent
% with linear summation of independently measured relevant and irrelevant
% responses.
%
% ASSUMED CONTEXT STRUCTURE
% -------------------------------------------------------------
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
% PRIMARY ANALYSIS
% -------------------------------------------------------------
%
% predicted combined =
%       relevant response + irrelevant-alone response
%
% interaction =
%       observed relevant+irrelevant response - predicted combined
%
% Interpretation:
%   interaction ~ 0  -> approximately additive
%   interaction < 0  -> sublinear
%   interaction > 0  -> supralinear
%
%
% SECOND ANALYSIS
% -------------------------------------------------------------
%
% DeltaStim =
%       relevant+irrelevant response - relevant response
%
% This is compared directly against the independently measured
% irrelevant-alone response.
%
%
% EXPECTED DATA FORMAT
% -------------------------------------------------------------
%
% context_data.dff{context,dataset}.ctrl
% context_data.dff{context,dataset}.stim
%
% Each array:
%       trials x frames x neurons
%
%
% OPTIONAL INPUTS
% -------------------------------------------------------------
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
%       context used for relevant-alone and relevant+irrelevant
%
% 'irrelevant_context'
%       default = 3
%
%
% OUTPUT
% -------------------------------------------------------------
%
% additivity_stats.neuron
% additivity_stats.dataset
% additivity_stats.mouse
% additivity_stats.population


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

parse(p, varargin{:});

figure_num        = p.Results.figure_num;
save_directory    = p.Results.save_directory;
use_median_trials = p.Results.use_median_trials;

color_by          = lower(string(p.Results.color_by));
mouse_ids         = p.Results.mouse_ids;

analysis_context  = p.Results.analysis_context;
irrelevant_context = p.Results.irrelevant_context;

data_type = p.Results.data_type;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE IDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(mouse_ids)

    mouse_ids = string(mouse_ids(:));

    if numel(mouse_ids) < chosen_datasets
        error('mouse_ids must contain one ID per dataset.');
    end

end

if color_by == "mouse" && isempty(mouse_ids)

    error('mouse_ids must be provided when color_by = ''mouse''.');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

all_rel = [];
all_irrel = [];
all_combined = [];

all_predicted = [];
all_interaction = [];
all_deltaStim = [];
all_deltaStim_error = [];

all_dataset_id = [];
all_neuron_id = [];
all_mouse_id = strings(0,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATASET-LEVEL STORAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataset_mean_interaction = nan(chosen_datasets,1);
dataset_median_interaction = nan(chosen_datasets,1);

dataset_r_predicted = nan(chosen_datasets,1);
dataset_p_predicted = nan(chosen_datasets,1);

dataset_r_deltaStim = nan(chosen_datasets,1);
dataset_p_deltaStim = nan(chosen_datasets,1);

dataset_mean_deltaStim_error = nan(chosen_datasets,1);
dataset_median_deltaStim_error = nan(chosen_datasets,1);

dataset_n_neurons = nan(chosen_datasets,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOOP DATASETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for dataset = 1:chosen_datasets

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GET DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rel_data = ...
        context_data.(data_type){analysis_context,dataset}.ctrl;

    combined_data = ...
        context_data.(data_type){analysis_context,dataset}.stim;

    irrel_data = ...
        context_data.(data_type){irrelevant_context,dataset}.stim;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(rel_data) || isempty(combined_data) || isempty(irrel_data)

        warning('Dataset %d contains empty data. Skipping.', dataset);
        continue

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK NEURON COUNTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    n_rel      = size(rel_data,3);
    n_combined = size(combined_data,3);
    n_irrel    = size(irrel_data,3);

    if ~(n_rel == n_combined && n_rel == n_irrel)

        warning(['Dataset %d has mismatched neuron counts: ' ...
            'rel=%d, combined=%d, irrel=%d. Skipping.'], ...
            dataset, n_rel, n_combined, n_irrel);

        continue

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TRIAL-LEVEL RESPONSES
    %
    % response = post - pre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rel_trial_response = ...
        get_trial_response(rel_data, pre_frames, post_frames);

    combined_trial_response = ...
        get_trial_response(combined_data, pre_frames, post_frames);

    irrel_trial_response = ...
        get_trial_response(irrel_data, pre_frames, post_frames);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % AVERAGE ACROSS TRIALS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if use_median_trials

        rel_response = ...
            median(rel_trial_response,1,'omitnan');

        combined_response = ...
            median(combined_trial_response,1,'omitnan');

        irrel_response = ...
            median(irrel_trial_response,1,'omitnan');

    else

        rel_response = ...
            mean(rel_trial_response,1,'omitnan');

        combined_response = ...
            mean(combined_trial_response,1,'omitnan');

        irrel_response = ...
            mean(irrel_trial_response,1,'omitnan');

    end


    rel_response      = rel_response(:);
    combined_response = combined_response(:);
    irrel_response    = irrel_response(:);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ADDITIVE MODEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    predicted_response = ...
        rel_response + irrel_response;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INTERACTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    interaction = ...
        combined_response - predicted_response;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DELTA STIM
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    deltaStim = ...
        combined_response - rel_response;


    deltaStim_error = ...
        deltaStim - irrel_response;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % REMOVE NANs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    good_idx = ...
        ~isnan(rel_response) & ...
        ~isnan(irrel_response) & ...
        ~isnan(combined_response);

    rel_response       = rel_response(good_idx);
    irrel_response     = irrel_response(good_idx);
    combined_response  = combined_response(good_idx);

    predicted_response = predicted_response(good_idx);
    interaction        = interaction(good_idx);

    deltaStim           = deltaStim(good_idx);
    deltaStim_error     = deltaStim_error(good_idx);

    neuron_ids = find(good_idx);

    n_good = length(interaction);

    dataset_n_neurons(dataset) = n_good;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DATASET-LEVEL SUMMARIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dataset_mean_interaction(dataset) = ...
        mean(interaction,'omitnan');

    dataset_median_interaction(dataset) = ...
        median(interaction,'omitnan');


    dataset_mean_deltaStim_error(dataset) = ...
        mean(deltaStim_error,'omitnan');

    dataset_median_deltaStim_error(dataset) = ...
        median(deltaStim_error,'omitnan');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DATASET-LEVEL CORRELATIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if n_good > 2

        [r,p_corr] = corr( ...
            predicted_response, ...
            combined_response, ...
            'rows','complete', ...
            'type','Pearson');

        dataset_r_predicted(dataset) = r;
        dataset_p_predicted(dataset) = p_corr;


        [r,p_corr] = corr( ...
            irrel_response, ...
            deltaStim, ...
            'rows','complete', ...
            'type','Pearson');

        dataset_r_deltaStim(dataset) = r;
        dataset_p_deltaStim(dataset) = p_corr;

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CONCATENATE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    all_rel = ...
        [all_rel; rel_response];

    all_irrel = ...
        [all_irrel; irrel_response];

    all_combined = ...
        [all_combined; combined_response];

    all_predicted = ...
        [all_predicted; predicted_response];

    all_interaction = ...
        [all_interaction; interaction];

    all_deltaStim = ...
        [all_deltaStim; deltaStim];

    all_deltaStim_error = ...
        [all_deltaStim_error; deltaStim_error];

    all_dataset_id = ...
        [all_dataset_id; repmat(dataset,n_good,1)];

    all_neuron_id = ...
        [all_neuron_id; neuron_ids];


    if ~isempty(mouse_ids)

        all_mouse_id = ...
            [all_mouse_id; ...
             repmat(mouse_ids(dataset),n_good,1)];

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATASET-LEVEL STATISTICAL TEST
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

    p_interaction_dataset = NaN;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE-LEVEL AGGREGATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mouse_mean_interaction = [];
mouse_median_interaction = [];
mouse_n_datasets = [];
unique_mice_valid = strings(0,1);
p_interaction_mouse = NaN;


if ~isempty(mouse_ids)

    unique_mice = ...
        unique(mouse_ids,'stable');

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
            dataset_mean_interaction(curr_dataset_idx);

        mouse_n_datasets(mouseIdx) = ...
            sum(curr_dataset_idx);


        if ~isempty(curr_values)

            mouse_mean_interaction(mouseIdx) = ...
                mean(curr_values,'omitnan');

            mouse_median_interaction(mouseIdx) = ...
                median(curr_values,'omitnan');

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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MOUSE-LEVEL SIGNIFICANCE TEST
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    all_combined, ...
    'rows','complete', ...
    'type','Pearson');


[r_delta,p_delta] = corr( ...
    all_irrel, ...
    all_deltaStim, ...
    'rows','complete', ...
    'type','Pearson');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NONLINEARITY SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

percent_sublinear = ...
    100 * mean(all_interaction < 0);

percent_supralinear = ...
    100 * mean(all_interaction > 0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLOR GROUPS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch color_by

    case "dataset"

        group_id = ...
            all_dataset_id;

        unique_groups = ...
            unique(group_id,'stable');

        cmap = ...
            jet(length(unique_groups));


    case "mouse"

        group_id = ...
            all_mouse_id;

        unique_groups = ...
            unique(group_id,'stable');

        cmap = ...
            jet(length(unique_groups));


    case "none"

        group_id = [];
        unique_groups = [];
        cmap = [];

    otherwise

        error('color_by must be ''dataset'', ''mouse'', or ''none''.');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POINT COLORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if color_by == "none"

    point_colors = ...
        repmat([0 0.4470 0.7410], ...
        length(all_dataset_id),1);

else

    point_colors = ...
        nan(length(all_dataset_id),3);

    for groupIdx = 1:length(unique_groups)

        idx = ...
            group_id == unique_groups(groupIdx);

        point_colors(idx,:) = ...
            repmat(cmap(groupIdx,:),sum(idx),1);

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STORE OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

additivity_stats.neuron.rel = ...
    all_rel;

additivity_stats.neuron.irrel = ...
    all_irrel;

additivity_stats.neuron.combined = ...
    all_combined;

additivity_stats.neuron.predicted = ...
    all_predicted;

additivity_stats.neuron.interaction = ...
    all_interaction;

additivity_stats.neuron.deltaStim = ...
    all_deltaStim;

additivity_stats.neuron.deltaStim_error = ...
    all_deltaStim_error;

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
    mean(all_interaction,'omitnan');

additivity_stats.population.median_interaction = ...
    median(all_interaction,'omitnan');

additivity_stats.population.percent_sublinear = ...
    percent_sublinear;

additivity_stats.population.percent_supralinear = ...
    percent_supralinear;

additivity_stats.population.n_neurons = ...
    length(all_interaction);

additivity_stats.population.n_datasets = ...
    sum(good_datasets);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(figure_num);
set(gcf,'Position',[100,100,700,400])
clf;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 1
% Predicted vs observed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,1);
set(gca, 'FontSize', 7)
hold on;

scatter( ...
    all_predicted, ...
    all_combined, ...
    10, ...
    point_colors, ...
    'filled');

lims = [ ...
    min([all_predicted; all_combined]), ...
    max([all_predicted; all_combined])];

plot(lims,lims,'k--','LineWidth',1);

xlim(lims);
ylim(lims);

xlabel('Predicted additive response');

ylabel('Observed Rel. + Irrel. response');

title(sprintf( ...
    'r = %.2f, p = %.2g', ...
    r_pred,p_pred), ...
    'FontWeight','normal');

axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 2
% Neuron-level interaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,2);
set(gca, 'FontSize', 7)
hold on;

x_jitter = ...
    1 + (rand(size(all_interaction))-0.5)*0.2;

scatter( ...
    x_jitter, ...
    all_interaction, ...
    8, ...
    point_colors, ...
    'filled');

yline(0,'k--');


mean_interaction = ...
    mean(all_interaction,'omitnan');

sem_interaction = ...
    std(all_interaction,'omitnan') / ...
    sqrt(sum(~isnan(all_interaction)));


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
xticklabels({'Interaction'});

ylabel('Observed - predicted additive');

title(sprintf( ...
    '%.1f%% sublinear', ...
    percent_sublinear), ...
    'FontWeight','normal');

axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 3
% Dataset OR mouse-level interaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,3);
set(gca, 'FontSize', 7)
hold on;


if color_by == "mouse" && ~isempty(mouse_ids)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MOUSE-LEVEL PANEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for mouseIdx = 1:length(mouse_mean_interaction)

        groupIdx = ...
            find(unique_groups == unique_mice_valid(mouseIdx),1);

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
        mean(mouse_mean_interaction,'omitnan');

    group_sem = ...
        std(mouse_mean_interaction,'omitnan') / ...
        sqrt(sum(~isnan(mouse_mean_interaction)));


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
    xticklabels({'Mouse mean'});

    ylabel('Interaction');

    title(sprintf( ...
        'p = %.3g', ...
        p_interaction_mouse), ...
        'FontWeight','normal');


else

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DATASET-LEVEL PANEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    good_dataset_ids = ...
        find(good_datasets);


    for ii = 1:length(good_dataset_ids)

        dataset = ...
            good_dataset_ids(ii);


        if color_by == "dataset"

            groupIdx = ...
                find(unique_groups == dataset,1);

            curr_color = ...
                cmap(groupIdx,:);

        elseif color_by == "mouse" && ~isempty(mouse_ids)

            curr_mouse = ...
                mouse_ids(dataset);

            groupIdx = ...
                find(unique_groups == curr_mouse,1);

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
        mean(dataset_interactions,'omitnan');

    group_sem = ...
        std(dataset_interactions,'omitnan') / ...
        sqrt(sum(~isnan(dataset_interactions)));


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
    xticklabels({'Dataset mean'});

    ylabel('Interaction');

    title(sprintf( ...
        'p = %.3g', ...
        p_interaction_dataset), ...
        'FontWeight','normal');

end


yline(0,'k--');

axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PANEL 4
% Irrelevant alone vs DeltaStim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,4,4);
set(gca, 'FontSize', 7)
hold on;

scatter( ...
    all_irrel, ...
    all_deltaStim, ...
    10, ...
    point_colors, ...
    'filled');

lims = [ ...
    min([all_irrel; all_deltaStim]), ...
    max([all_irrel; all_deltaStim])];

plot(lims,lims,'k--','LineWidth',1);

xlim(lims);
ylim(lims);

xlabel('Measured Irrel. alone');

ylabel('\DeltaStim: Rel.+Irrel. - Rel.');

title(sprintf( ...
    'r = %.2f, p = %.2g', ...
    r_delta,p_delta), ...
    'FontWeight','normal');

axis square;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINT SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('==============================================\n');
fprintf('Relevant + irrelevant additivity analysis\n');
fprintf('==============================================\n');

fprintf('Neurons: %d\n', ...
    length(all_interaction));

fprintf('Datasets: %d\n', ...
    sum(good_datasets));

fprintf('\n');

fprintf('Mean neuron interaction = %.4f\n', ...
    mean(all_interaction,'omitnan'));

fprintf('Median neuron interaction = %.4f\n', ...
    median(all_interaction,'omitnan'));

fprintf('Sublinear neurons = %.1f%%\n', ...
    percent_sublinear);

fprintf('Supralinear neurons = %.1f%%\n', ...
    percent_supralinear);

fprintf('\n');

fprintf('Dataset-level interaction vs zero: p = %.6g\n', ...
    p_interaction_dataset);


if ~isempty(mouse_ids)

    fprintf('Mouse-level interaction vs zero: p = %.6g\n', ...
        p_interaction_mouse);

end


fprintf('\n');

fprintf('Predicted vs observed: r = %.3f, p = %.6g\n', ...
    r_pred,p_pred);

fprintf('Measured irrelevant vs DeltaStim: r = %.3f, p = %.6g\n', ...
    r_delta,p_delta);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINT MOUSE SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(mouse_ids)

    fprintf('\n');
    fprintf('==============================================\n');
    fprintf('Mouse-level summary\n');
    fprintf('==============================================\n');

    for mouseIdx = 1:length(unique_mice_valid)

        fprintf( ...
            'Mouse %s: mean interaction = %.4f, n datasets = %d\n', ...
            unique_mice_valid(mouseIdx), ...
            mouse_mean_interaction(mouseIdx), ...
            mouse_n_datasets(mouseIdx));

    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(save_directory)

    filename_base = ...
        ['irrelevant_input_additivity_' char(color_by) '_datatype_' char(data_type)];

    exportgraphics( ...
        figure(figure_num), ...
        fullfile(save_directory, ...
        [filename_base '.pdf']), ...
        'ContentType','vector');

    saveas( ...
        figure(figure_num), ...
        fullfile(save_directory, ...
        [filename_base '.fig']));

    save( ...
        fullfile(save_directory, ...
        [filename_base '_stats.mat']), ...
        'additivity_stats');

end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trial_response = get_trial_response( ...
    trial_data, pre_frames, post_frames)

% trial_data:
%       trials x frames x neurons
%
% output:
%       trials x neurons

baseline = ...
    squeeze(mean( ...
        trial_data(:,pre_frames,:), ...
        2, ...
        'omitnan'));

response = ...
    squeeze(mean( ...
        trial_data(:,post_frames,:), ...
        2, ...
        'omitnan'));

trial_response = ...
    response - baseline;

end