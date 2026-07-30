function [pooled_cell_types, pooled_names,pooled_colors, sig_mod_boot] = organize_functional_groups(all_celltypes, sound_sig, opto_sig, opto_mod, group_order,chosen_sessions,plot_info,varargin)
% pooled_cell_types = organize_cells(all_celltypes, sound_sig, opto_sig, opto_mod, group_order, [contexts])
%
% INPUTS
%   all_celltypes : cell array with structs (fields: pyr_cells, som_cells, pv_cells)
%   sound_sig     : {datasets x 1} or {datasets x contexts}, sound-modulated cells
%   opto_sig      : {datasets x 1} or {datasets x contexts}, opto-modulated cells
%   opto_mod      : indices or logical mask of opto-modulated cells (for helpers)
%   group_order   : cell array of strings defining which groups to return, e.g.
%                   {'sound','opto','both','unmodulated','all'} in desired order
%   contexts      : (optional) number of contexts, default = 1
%
% OUTPUT
%   pooled_cell_types : 
%       If contexts=1: {datasets} struct with fields in group_order
%       If contexts>1: {contexts, datasets} same but separated per context
    % Optional inputs
    if nargin > 8
        sound_sig_neg = varargin{1,2};   % {datasets x 1} negative sound cells
    else
        sound_sig_neg = [];
    end

    if nargin > 7
        n_contexts = varargin{1};
    else
        n_contexts = 1;
    end

    sig_mod_boot = [];

    % color + name mapping
    group_map = struct( ...
        'sound',       struct('name','Sound','color',[0.3,0.2,0.6]), ...
        'sound_neg',       struct('name','Sound Neg.','color',[0.2,0,0.5]),...
        'opto',        struct('name','Photostim','color',[1,0.7,0]), ...
        'both',        struct('name','Both','color',[0.3,0.8,1]), ...
        'unmodulated', struct('name','Unmodulated','color',[0.5,0.5,0.5]), ...
        'modulated',   struct('name','Modulated','color',[0,0,0]));

    % gather all cells per type
    all_cells = [cellfun(@(x) x.pyr_cells, all_celltypes, 'UniformOutput', false)]; ...
%                  cellfun(@(x) x.som_cells, all_celltypes, 'UniformOutput', false); ...
%                  cellfun(@(x) x.pv_cells,  all_celltypes, 'UniformOutput', false)];
    num_cells = cellfun(@length, all_cells);

    pooled_cell_types = cell(n_contexts, length(chosen_sessions));

    for context = 1:n_contexts
        % pick correct input depending on context
        if n_contexts == 1
            sound_cells = sound_sig;
            if ~isempty(sound_sig_neg)
                sound_cells_neg = sound_sig_neg;
            end
            opto_cells  = opto_sig;
            if size(opto_sig,1) > 3 && size(opto_sig,2) < size(opto_sig,1)
                opto_cells  = opto_sig';
            end
        else
            sound_cells = sound_sig(chosen_sessions,context)';
            if ~isempty(sound_sig_neg)
                sound_cells_neg = sound_sig_neg(chosen_sessions,context)';
            end
            opto_cells  = opto_sig(chosen_sessions,context)';
        end

        % precompute all sets
        sound_only = setdiff_sig_cells(sound_cells(chosen_sessions), opto_cells(chosen_sessions), opto_mod);
        if ~isempty(sound_sig_neg)
            sound_neg_only = setdiff_sig_cells(sound_cells_neg(chosen_sessions), opto_cells(chosen_sessions), opto_mod);
            all_sound = union_sig_cells(sound_cells(chosen_sessions), sound_cells_neg(chosen_sessions), opto_mod);
        else
            sound_neg_only = cell(size(sound_only)); % empty cells
            all_sound = sound_cells(chosen_sessions);
        end
        opto_only  = setdiff_sig_cells(opto_cells(chosen_sessions), all_sound(chosen_sessions), opto_mod);
        both       = intersect_sig_cells(opto_cells(chosen_sessions), all_sound(chosen_sessions), opto_mod);

        for dataset = chosen_sessions
            all_ids    = 1:sum(num_cells(:,dataset));
            current_sig = [sound_only{dataset}, opto_only{dataset}, both{dataset}];
            if ~isempty(sound_sig_neg)
                current_sig = [current_sig, sound_neg_only{dataset}];
            end
            unmod      = setdiff(all_ids, current_sig);
            % assign dynamically according to requested order
            for g = 1:length(group_order)
                switch lower(group_order{g})
                    case 'sound'
                        pooled_cell_types{context,dataset}.sound = sound_only{dataset};
                    case 'sound_neg'
                        pooled_cell_types{context,dataset}.sound_neg = sound_neg_only{dataset};
                    case 'opto'
                        pooled_cell_types{context,dataset}.opto = opto_only{dataset};
                    case 'both'
                        pooled_cell_types{context,dataset}.both = both{dataset};
                    case 'unmodulated'
                        pooled_cell_types{context,dataset}.unmodulated = unmod;
                    case 'modulated'
                        pooled_cell_types{context,dataset}.modulated = current_sig;
                    case 'all'
                        pooled_cell_types{context,dataset}.all = all_ids;
                    otherwise
                        error('Unknown group name: %s', group_order{g});
                end
            end
            if length(group_order) == 1
                switch lower(group_order{g})
                    case 'sound'
                        sig_mod_boot{context,dataset} = sound_only{dataset};
                    case 'sound_neg'
                        sig_mod_boot{context,dataset} = sound_neg_only{dataset};
                    case 'opto'
                        sig_mod_boot{context,dataset} = opto_only{dataset};
                    case 'both'
                        sig_mod_boot{context,dataset} = both{dataset};
                    case 'unmodulated'
                        sig_mod_boot{context,dataset} = unmod;
                    case 'modulated'
                        sig_mod_boot{context,dataset} = current_sig;
                    case 'all'
                        sig_mod_boot{context,dataset} = all_ids;
                    otherwise
                        error('Unknown group name: %s', group_order{g});
                end
                 
            end
        end
    end

    % if only one context, collapse back to {datasets}
    if n_contexts == 1
        pooled_cell_types = pooled_cell_types(1,:);
    end

    % Match colors/names to requested group_order
    for g = 1:length(group_order)
        if strcmpi(group_order{g},'opto')
            group_order{g} = 'Photostim';
        end
        if strcmpi(group_order{g},'sound_neg')
            group_order{g} = 'Sound Negative';
        end
        if strcmpi(group_order{g},'both')
            group_order{g} = 'S & P';
        end
        idx = find(strcmpi(plot_info.pooled_names, capitalize(group_order{g})),1);
        if ~isempty(idx)
            pooled_colors(g,:) = plot_info.pooled_colors(idx,:);
            pooled_names{g}    = plot_info.pooled_names{idx};
        else
            pooled_colors(g,:) = [0 0 0]; % fallback: black
            pooled_names{g}    = group_order{g};
        end
    end
end

function s = capitalize(str)
    s = lower(str);
    s(1) = upper(s(1));
end

%     % build names & colors aligned to order
%     pooled_names = cell(size(group_order));
%     pooled_colors = nan(numel(group_order),3);
%     for g = 1:length(group_order)
%         group = lower(group_order{g});
%         if isfield(group_map, group)
%             pooled_names{g}  = group_map.(group).name;
%             pooled_colors(g,:) = group_map.(group).color;
%         else
%             % e.g. 'all' → no mapping
%             pooled_names{g}  = group_order{g};
%             pooled_colors(g,:) = [NaN NaN NaN];
%         end
%     end
% end
