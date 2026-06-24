function data_clean = regress_out_behavior_3d(data, behavior, train_trials, avg_frames)
% data:     trials x neurons x frames
% behavior: trials x predictors x frames
%           e.g. speed only: trials x 1 x frames
%           speed + pitch + roll: trials x 3 x frames
% train_trials: trial indices used to fit regression

    if nargin < 4
            avg_frames = [];
    end
    
    % If requested, collapse behavior to one trial-level value per predictor
    if ~isempty(avg_frames)
        behavior = nanmean(behavior(:,:,avg_frames), 3);  % trials x predictors
    end

    [n_trials, n_neurons, n_frames] = size(data);
    data_clean = nan(size(data));

    for t = 1:n_frames
        if ndims(behavior) == 3
            X = squeeze(behavior(:,:,t));      % trials x predictors
        else
            X = behavior;                      % trials x predictors
        end

        if isvector(X)
            X = X(:);
        end

        X = [ones(n_trials,1), X];      % intercept

        for n = 1:n_neurons
            y = squeeze(data(:,n,t));

            good_train = train_trials(:);
            good_train = good_train(~any(isnan(X(good_train,:)),2) & ~isnan(y(good_train)));

            if numel(good_train) < size(X,2) + 2
                data_clean(:,n,t) = y;
                continue
            end

            beta = X(good_train,:) \ y(good_train); %ordinary least squares.

            % Remove only behavioral contribution, keep intercept/mean structure
            behavioral_pred = X(:,2:end) * beta(2:end);
            data_clean(:,n,t) = y - behavioral_pred;
        end
    end
end