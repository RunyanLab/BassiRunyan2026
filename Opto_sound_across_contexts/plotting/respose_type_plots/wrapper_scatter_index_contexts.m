function [modl_fit,stats] = wrapper_scatter_index_contexts(sig_mod_boot, xdata, ydata, pooled_cell_types, plot_info, save_dir, xlab, ylab, varargin)
%PLOT_SCATTER_INDEX_CONTEXTS  Wrapper to plot active & passive contexts
%
%   modl_fit = plot_scatter_index_contexts(xdata, ydata, pooled_cell_types, plot_info, save_dir, xlab, ylab)
%
%   Inputs:
%       xdata, ydata          - {datasets x 2} or cell arrays (context 1=active, 2=passive)
%       pooled_cell_types     - grouping of cell types
%       plot_info             - struct with colors/names
%       save_dir              - directory to save plots
%       xlab, ylab            - axis labels
%       varargin              - optional overrides: do_hist, do_sig, xlimits
%
%   Outputs:
%       modl_fit              - struct with .active and .passive fits

    % Defaults
    do_hist = 0;
    unity_line = 1;
    xlimits = [-0.6, 2];

    % Override defaults if user provided extras
    if ~isempty(varargin)
        if length(varargin) >= 1, do_hist = varargin{1}; end
        if length(varargin) >= 2, unity_line = varargin{2}; end
        if length(varargin) >= 3, xlimits = varargin{3}; end
    end

    modl_fit = struct();

    if size(xdata,2) > 1
        if size(pooled_cell_types,1) >1
            % Active (context 1)
            [modl_fit.active,~,~,stats.active] = scatter_index_sigcells_histogram_optional(sig_mod_boot, pooled_cell_types(1,:), ...
                [{xdata{:,1}}', {ydata{:,1}}'], plot_info, save_dir, ...
                ['Active ' xlab], ['Active ' ylab], do_hist, unity_line, xlimits);
        
            % Passive (context 2)
            [modl_fit.passive,~,~,stats.passive] = scatter_index_sigcells_histogram_optional(sig_mod_boot, pooled_cell_types(2,:), ...
                [{xdata{:,2}}', {ydata{:,2}}'], plot_info, save_dir, ...
                ['Passive ' xlab], ['Passive ' ylab], do_hist, unity_line, xlimits);
        else
            % Active (context 1)
            [modl_fit.active,~,~,stats.passive] = scatter_index_sigcells_histogram_optional(sig_mod_boot, pooled_cell_types, ...
                [{xdata{:,1}}', {ydata{:,1}}'], plot_info, save_dir, ...
                ['Active ' xlab], ['Active ' ylab], do_hist, unity_line, xlimits);
        
            % Passive (context 2)
            [modl_fit.passive,~,~,stats.active] = scatter_index_sigcells_histogram_optional(sig_mod_boot, pooled_cell_types, ...
                [{xdata{:,2}}', {ydata{:,2}}'], plot_info, save_dir, ...
                ['Passive ' xlab], ['Passive ' ylab], do_hist, unity_line, xlimits);
        end
    else
         [modl_fit.active,~,~,stats.active] = scatter_index_sigcells_histogram_optional(sig_mod_boot, pooled_cell_types(1,:), ...
                [{xdata{:,1}}', {ydata{:,1}}'], plot_info, save_dir, ...
                [xlab], [ylab], do_hist, unity_line, xlimits);
    end
end

