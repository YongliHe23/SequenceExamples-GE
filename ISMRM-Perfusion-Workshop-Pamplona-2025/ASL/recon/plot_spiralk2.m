function plot_spiralk2(kx,ky,d,sz)
% display one platter of stack-of-spiral (SOSP) k space
% Inputs:
% - kx : [nread nleaf]
% - ky : [nread nleaf]
% - d: [nread nleaf]
% -sz: scalar, size of each scatter point

assert(size(kx,2)==size(d,2),"size of traj does not match data")

for ileaf=1:size(kx,2)
    scatter(kx(:,ileaf),ky(:,ileaf),sz,log(abs(squeeze(d(:,ileaf)))),'filled');hold on
end
%title('k data');
xlabel("kx");
ylabel("ky");