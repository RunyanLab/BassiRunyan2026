function struct = get_top_informative_neurons(struct,celltype,varargin)
%load informative sound neurons
load('V:\Connie\results\opto_sound_2025\context\data_info\info.mat');
load('V:\Connie\results\opto_sound_2025\context\data_info\all_celltypes.mat')
data = load('V:\Connie\ProcessedData\sorted_peaks\sorted_peaks_passive_sound_category_14to100.mat');
min_cells = [];
if nargin > 2
    min_cells = varargin{1,1};
end
all_top = {};
for d = 1:length(info.mouse_date)
    if contains(info.mouse_date{1,d},'\')
        curr_mouse = strrep(info.mouse_date{1,d}, '\', '_');
    else
        curr_mouse = strrep(info.mouse_date{1,d}, '/', '_');
    end
    curr_mouse = strrep(curr_mouse, '-', '_');
    curr_mouse = [curr_mouse '_' celltype];
    num_observations_needed = min(cellfun(@length,struct2cell(all_celltypes{1,d}))); %min number of cells 
    if ~isempty(min_cells)
        num_observations_needed = min_cells;
    end
    if isfield(data,curr_mouse)
        curr_cells = data.(curr_mouse)+1;%+1 bc of Python indexing
        curr_cells = curr_cells(1:num_observations_needed);
    else
        curr_cells = [];
    end
    all_top{d} = curr_cells;

end
struct.sig_cells_top = all_top;