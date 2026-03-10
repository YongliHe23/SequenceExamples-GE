data_root='/mnt/storage/yonglihe/transfer/20250618/';

pfile_fs_ovsoff=[data_root, 'jon_spine_fs/Series3/ScanArchive_7347633TMRFIX_20250618_165747110.h5'];

scan_root='/home/yonglihe/Documents/MATLAB/OVS-SOS/scan/20250608scan/tv6/';
readout_fs1=[scan_root 'ovs_sosp_fs/module7.mod'];
readout_fs2=[scan_root 'ovs_sosp_fs/module8.mod'];
readout_fs3=[scan_root 'ovs_sosp_fs/module9.mod'];

readout_us=[scan_root 'ovs_sosp_us/module7.mod'];

save_root='~/data/h5files/20250618/jon_spine/';
if ~isfolder(save_root)
    mkdir(save_root)
end
%%
addpath /home/yonglihe/Documents/MATLAB/SOSP3d/GE/
addpath /home/jfnielse/Programs/orchestra-sdk-2.1-1.matlab/


kdata_fs_ovsoff=readframes(pfile_fs_ovsoff,[1:10],'nrot',3,'outfile',[save_root 'sosp_kdata_fs.h5']);%[nframe,ncoil,nrot*nz,nread]
%%
N=[60 60 40];
fov=[0.36 0.36 0.36].*N;
nrot=3;

[nt,ncoil,nrotnz,nread]=size(kdata_fs_ovsoff);
kdata_fs_ovsoff=reshape(kdata_fs_ovsoff,nt,ncoil,nrot,[],nread);%[nt,ncoil,nrot,nz,nread]
kdata_fs_ovsoff=permute(kdata_fs_ovsoff,[5,3,4,1,2]);% reshape to size [ndat nleaf nz nt ncoil]

load /home/yonglihe/Documents/MATLAB/OVS-SOS/kz.mat kz
kz=kz+N(3)/2+1;

kdata_fs_ovsoff(:,:,kz,:,:)=kdata_fs_ovsoff;
%%
ktraj_fs_arm1=getspiraltrajs(readout_fs1,fov,N);
ktraj_fs_arm2=getspiraltrajs(readout_fs2,fov,N);
ktraj_fs_arm3=getspiraltrajs(readout_fs3,fov,N);

nread=size(kdata_fs_ovsoff,4);

kx=cat(2,ktraj_fs_arm1(1,1,1:nread),ktraj_fs_arm1(1,2,1:nread),ktraj_fs_arm1(1,3,1:nread));
ky=cat(2,ktraj_fs_arm1(2,1,1:nread),ktraj_fs_arm1(2,2,1:nread),ktraj_fs_arm1(2,3,1:nread));

kx=squeeze(kx)'; %[nread,nleaf]
ky=squeeze(ky)';

%%
if 1
    slice_set=1:2:N(3);
    fig_ncol=5;
    
    fig_nrow=ceil(length(slice_set)/fig_ncol);
    
    figure;
    i=1;
    for iz=slice_set
        subplot(fig_nrow,fig_ncol,i)
        plot_spiralk2(kx(:,1:3),ky(:,1:3),kdata_fs_ovsoff(:,1:3,iz,nt,1),10)
        i=i+1;
    end
    sgtitle('k-space')
end
%%
[imsos ims dcf] = toppe.utils.spiral.reconSoS(kdata_fs_ovsoff, kx, ky, fov(1:2), N(1:2), ...
                  'useParallel', false);