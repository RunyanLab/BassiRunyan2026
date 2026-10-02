function [aa] = get_hist(data,edges);
%returns probability value for each edge
[a,b] = histcounts(data,edges,'normalization','probability');

[aa]=hist(data,b);
aa = aa./sum(aa); %normalize data to probability

% figure(3);clf;
% plot(edges,aa)