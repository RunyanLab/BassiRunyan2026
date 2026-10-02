function [alignment_frames, dff_struct, deconv_struct, deconv_struct_interp] = process_neural_data(data, before_after_frames, varargin)
    
    % Set default trial types
    if nargin < 3 || isempty(varargin{1})
        trial_types = {'stim', 'ctrl'};
        data.exp = data.exp;
        data.nonexp = data.nonexp;

    else %assuming it's sound locations
        trial_types = varargin{1};
        data.exp = data.left;
        data.nonexp = data.right;
    end
    
    % Align frames and process data
    if isfield(data,'padding')
    [allcells, allcells_nogap, alignment_frames] = optoalign_function(...
        data.exp, data.nonexp, data.bad_frames, data.dff, data.deconv, ...
        before_after_frames(1), before_after_frames(2),data.padding);
    else
    [allcells, allcells_nogap, alignment_frames] = optoalign_function(...
        data.exp, data.nonexp, data.bad_frames, data.dff, data.deconv, ...
        before_after_frames(1), before_after_frames(2));
    end
    % Process dF/F data
    [matrix1, matrix2, z_matrix1, z_matrix2] = ...
        make_tr_cel_time(allcells, 1); % Gives matrix of size: trials x cells x frames
    
    % Process deconvolution data
    [deconv_matrix1, deconv_matrix2] = make_tr_cel_time(allcells_nogap, 0); % No gap means no interpolation (useful for looking at artifact)
    [deconv_matrix1_interp, deconv_matrix2_interp] = make_tr_cel_time(allcells, 0);
    
    % Package results using dynamic field names based on trial_types
    dff_struct = struct(trial_types{1}, matrix1, trial_types{2}, matrix2, ...
                        ['z_', trial_types{1}], z_matrix1, ['z_', trial_types{2}], z_matrix2);
    
    deconv_struct = struct(trial_types{1}, deconv_matrix1, trial_types{2}, deconv_matrix2);
    
    deconv_struct_interp = struct(trial_types{1}, deconv_matrix1_interp, ...
                                  trial_types{2}, deconv_matrix2_interp);
end

% function [alignment_frames,dff_struct, deconv_struct, deconv_struct_interp] = process_neural_data(data, before_after_frames,vargin)
%     
% % Set default trial types
%     if nargin < 3 || isempty(varargin{1})
%         trial_types = {'stim', 'ctrl'};
%     else
%         trial_types = varargin{1};
%     end
% 
%     % Align frames and process data
%     [allcells, allcells_nogap, alignment_frames] = optoalign_function(...
%         data.exp, data.nonexp, data.bad_frames, data.dff, data.deconv, ...
%         before_after_frames(1), before_after_frames(2));
%     
%     % Process dF/F data
%     [stim_matrix, ctrl_matrix, z_stim_matrix, z_ctrl_matrix] = ...
%         make_tr_cel_time(allcells, 1); %gives matrix of size: trials x cells x frames
%     
%     % Process deconvolution data
%     [deconv_stim, deconv_control] = make_tr_cel_time(allcells_nogap, 0); %no gap means there is no interpolation (useful for looking at artifact)
%     [deconv_stim_interp, deconv_control_interp] = make_tr_cel_time(allcells, 0);
%     
%     
%     % Package results
%     dff_struct = struct('stim', stim_matrix, 'ctrl', ctrl_matrix, ...
%                        'z_stim', z_stim_matrix, 'z_ctrl', z_ctrl_matrix);
%     deconv_struct = struct('stim', deconv_stim, 'ctrl', deconv_control);
%     deconv_struct_interp = struct('stim', deconv_stim_interp, ...
%                                  'ctrl', deconv_control_interp);
% end
