function [output,output_relative] = setdiff_sig_cells(sig_mod_boot_thr,sig_mod_boot_thr2, mod_indexm,varargin)
output = {};
output_relative = [];
length_datasets = length(sig_mod_boot_thr);
numcells = cumsum(cellfun(@(x) length(x), mod_indexm(1:length_datasets)));
numcells = [0, numcells];
if nargin < 4
    for m = 1:length(sig_mod_boot_thr)
        output{m} = setdiff(sig_mod_boot_thr{1,m},sig_mod_boot_thr2{1,m});
        output_relative = [output_relative,output{m}+numcells(m)];
    end
else
    sig_mod_boot_thr3 = varargin{1,1};
    for m = 1:length(sig_mod_boot_thr)
        temp = [];
        temp = setdiff(sig_mod_boot_thr{1,m},sig_mod_boot_thr2{1,m});
        output{m} = setdiff(temp,sig_mod_boot_thr3{1,m});
        output_relative = [output_relative,output{m}+numcells(m)];
    end
end