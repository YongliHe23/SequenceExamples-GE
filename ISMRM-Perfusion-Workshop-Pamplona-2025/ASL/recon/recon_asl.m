% path to Orchestra toolbox
addpath /home/jfnielse/Programs/orchestra-sdk-2.1-1.matlab/

% number of 'runs' = number of times the sequence is repeated
% Each run consists of one label-control pair
opnex = 60;   
nt = 2*opnex;  %2*74; %rhnframes;   % number of label-control pairs is nt/2

load ../sequence/readout
nz = readout.nz;  
nleaf = readout.nleaf;   % number of spiral leafs

% load first shot and get data size
clear archive
archive = GERecon('Archive.Load', '../data/data.h5');
shot = GERecon('Archive.Next', archive);

[ndat nc] = size(shot.Data);

%rhnframes = archive.DownloadData.rdb_hdr_rec.rdb_hdr_nframes;

d = zeros(ndat, nc, nleaf, nz, nt);

load ../sequence/kz   %
kz = kz + nz/2 + 1;   % range is now [1 nz]

% load first frame
k = 1; l = 1; t = 1;
d(:, :, l, kz(k), t) = shot.Data;
for l = 2:nleaf
    shot = GERecon('Archive.Next', archive);
    d(:, :, l, kz(k), t) = shot.Data;
end
for k = 2:nz
    for l = 1:nleaf
        shot = GERecon('Archive.Next', archive);
        d(:, :, l, kz(k), t) = shot.Data;
    end
end

% load other frames
textprogressbar('Loading data: ');
for t = 2:nt
    textprogressbar(t/nt*100);
    for k = 1:nz
        for l = 1:nleaf
            shot = GERecon('Archive.Next', archive);
            d(:, :, l, kz(k), t) = shot.Data;
        end
    end
end
textprogressbar('');

% get kx and ky sampling trajectory
kx = readout.kx(1:ndat,:);
ky = -readout.ky(1:ndat,:);  % rotations are negated, need to look into this TODO

% recon
d = permute(d, [1 3 4 5 2]);   % reshape to size [ndat nleaf nz nt ncoil]

nx = readout.nx;
[imsos ims dcf] = toppe.utils.spiral.reconSoS(d, kx, ky, 100*readout.fov(1:2), 2*[nx nx], ...
                  'useParallel', false);

%%
save_root='~/data/h5files/20250612/';
if ~isfolder(save_root)
    mkdir(save_root)
end
save([save_root 'ims_vsasl_spinal.mat'],'imsos');

save([save_root 'kdata_vsasl_brain.mat'],'d');

%% display k-space one slice
iz=nz/2;
figure;
scatter(kx(:,1),ky(:,1),50,log(abs(squeeze(d(:,1,iz,nt,1)))),'filled');title('k data');hold on
scatter(kx(:,2),ky(:,2),50,log(abs(squeeze(d(:,2,iz,nt,1)))),'filled');hold on
scatter(kx(:,3),ky(:,3),50,log(abs(squeeze(d(:,3,iz,nt,1)))),'filled');

%% display k-space multiple slice
slice_set=1:2:40;
fig_ncol=5;

fig_nrow=ceil(length(slice_set)/fig_ncol);

figure;
i=1;
for iz=slice_set
    subplot(fig_nrow,fig_ncol,i)
    plot_spiralk2(kx(:,1:3),ky(:,1:3),d(:,1:3,iz,nt,1),10)
    i=i+1;
end
sgtitle('k-space')

