function [seq, kx, ky] = getSoSreadout(sys, fov, nx, nz, nleaf, trid, FLIP,varargin)
% function seq = getSoSreadout(sys, fov, nx, nz, nleaf, trid, [FLIP])
%
% Create stack-of-spirals fast SPGR/FLASH readout sequence
%
% Inputs
%    sys    struct   
%    fov    [3 1]          m
%    nx     [1]            matrix size
%    nz     [1]            number of kz partitions
%    nleaf  [1]            number of spiral leafs
%    trid   [1]            segment TRID
%    FLIP   [1] or [nz*nleaf]    constant or varying flip angle schedule for the nz shots (degrees)
%    varargin:
%       - Rxy: in-plane acceleration factor
%       - fatsat: [t/F]
%       - ovs: [t/F] apply outer-volume suppresion or not
%       - ovs_path: path to ovs tRF
% Outputs
%   seq     Pulseq sequence object
%   kx      [adc.numSamples nleaf]    cycles/cm
%   ky      [adc.numSamples nleaf]    cycles/cm

nShot = nz*nleaf;   % number of RF shots / inner TRs

if length(FLIP) == 1
    FLIP = FLIP*ones(nShot,1);
end

% options
arg.Rxy=1;
arg.fatsat=false;
arg.ovs=false;
arg.ovs_path='';

arg=toppe.utils.vararg_pair(arg,varargin);

assert(length(FLIP) == nShot, 'length(FLIP) must equal nz*nleaf');
assert(~(arg.ovs==true & isempty(arg.ovs_path)), 'Give me a path for tRF if you want OVS!')

% Sequence parameters
ny = nx;
nCyclesSpoil = 2;               % number of spoiler cycles
rfSpoilingInc = 117;            % RF spoiling increment

%Create Fatsat pulse
if arg.fatsat
    fatsat.flip    = 90;      % degrees
    fatsat.slThick = 1e5;     % dummy value (determines slice-select gradient, but we won't use it; just needs to be large to reduce dead time before+after rf pulse)
    fatsat.tbw     = 3.5;     % time-bandwidth product
    fatsat.dur     = 8.0;     % pulse duration (ms)
    
    % RF waveform in Gauss
    wav = toppe.utils.rf.makeslr(fatsat.flip, fatsat.slThick, fatsat.tbw, fatsat.dur, 1e-6, toppe.systemspecs(), ...
        'type', 'ex', ...    % fatsat pulse is a 90 so is of type 'ex', not 'st' (small-tip)
        'ftype', 'min', ...
        'writeModFile', false);
    
    % Convert from Gauss to Hz, and interpolate to sys.rfRasterTime
    rfp = rf2pulseq(wav, 4e-6, sys.rfRasterTime);
    
    % Create pulseq object
    % Try to account for the fact that makeArbitraryRf scales the pulse as follows:
    % signal = signal./abs(sum(signal.*opt.dwell))*flip/(2*pi);
    flip_ang = fatsat.flip/180*pi;
    flipAssumed = abs(sum(rfp));
    rfsat = mr.makeArbitraryRf(rfp, ...
        flip_ang*abs(sum(rfp*sys.rfRasterTime))*(2*pi), ...
        'system', sys);
    rfsat.signal = rfsat.signal/max(abs(rfsat.signal))*max(abs(rfp)); % ensure correct amplitude (Hz)
    rfsat.freqOffset = -1*425;  % Hz
end

if arg.ovs
    sys_beta=sys;
    load(arg.ovs_path);
    
    %create IV saturation rf pulse
    rf_beta=mr.makeArbitraryRf(Rf_sat*4258,3.14,'system',sys_beta,'delay',100e-6);
    rf_beta.signal= rf_beta.signal/max(abs(rf_beta.signal))*max(abs(Rf_sat*4258)); % ensure correct amplitude (Hz)
    
    gx_beta=mr.makeArbitraryGrad('x',Gx_sat*425.8e3,'system',sys_beta,'delay',100e-6);
    gy_beta=mr.makeArbitraryGrad('y',Gy_sat*425.8e3,'system',sys_beta,'delay',100e-6);
    gz_beta=mr.makeArbitraryGrad('z',Gz_sat*425.8e3,'system',sys_beta,'delay',100e-6);
end

% slice selection pulse and gradient
[ex.rf, ex.gz] = mr.makeSincPulse(max(FLIP)*pi/180, 'Duration', 2e-3, ...
                        'SliceThickness', fov(3)*0.8, 'apodization', 0.42, ...
                        'use', 'excitation', ...
                        'timeBwProduct', 8, 'system', sys);
ex.gzReph = mr.makeTrapezoid('z', sys, 'Area', -ex.gz.area/2, 'system', sys);

% spiral readout 
% write to tmp.mod to check PNS
[sp.wav, sp.dur] = getspiral(nleaf, sys.gradRasterTime, fov(1)*100, nx);
toppe.writemod(toppe.systemspecs(), 'gx', real(sp.wav(:)), 'gy', imag(sp.wav(:)), 'ofname', 'tmp.mod');
sp.gx = mr.makeArbitraryGrad('x', real(sp.wav)*1e-4*sys.gamma*100, sys, ... 
                             'first', 0, 'last', 0, ...
                             'delay', sys.adcDeadTime);  
sp.gy = mr.makeArbitraryGrad('y', imag(sp.wav)*1e-4*sys.gamma*100, sys, ...
                             'first', 0, 'last', 0, ...
                             'delay', sys.adcDeadTime);  
sp.dwell = 4e-6;
sp.nread = 4*floor(sp.dur/sp.dwell/4);
sp.adc = mr.makeAdc(sp.nread, sys, 'Duration', sp.nread*sp.dwell, 'Delay', 0);

% z prephaser and spoilers
deltak = 1./fov;
gzPre = mr.makeTrapezoid('z', sys, ...
    'Area', nz*deltak(3)/2);   % PE2 gradient, max amplitude
gzSpoil = mr.makeTrapezoid('z', sys, 'Area', nx*deltak(1)*nCyclesSpoil);
gxSpoil = mr.makeTrapezoid('x', sys, 'Area', gzSpoil.area);

% z PE steps: center out
% Avoid exactly zero so that scaled trapezoids are recognized as such by Matlab Pulseq toolbox
tmp = -nz/2:nz/2-1;
kz = 0*tmp;
kz(1:2:end) = tmp(nz/2+1:end);
kz(2:2:end) = flip(tmp(1:nz/2));
save kz kz
pe2Steps = kz/(nz/2) + eps;

% Create the sequence object
seq = mr.Sequence(sys);           

rf_phase = 0;
rf_inc = 0;
textprogressbar('Writing readout sequence: ');
%fprintf('writing readout sequence:')
for iz = 1:nz
    textprogressbar(iz/nz*100);
    %fprintf('Progress:%f\n',iz/nz*100)
    for leaf = 1:arg.Rxy:nleaf
        if arg.fatsat
            rfsat.phaseOffset=rf_phase/180*pi;

            seq.addBlock(rfsat,mr.makeLabel('SET','TRID',trid-2))
            seq.addBlock(gxSpoil,gzSpoil)

            rf_inc=mod(rf_inc+rfSpoilingInc,360.0);
            rf_phase=mod(rf_phase+rf_inc,360.0);
        end
        if arg.ovs
            rf_beta.phaseOffset=rf_phase/180*pi;

            seq.addBlock(rf_beta,gx_beta,gy_beta,gz_beta,mr.makeLabel('SET','TRID',trid-1))
            seq.addBlock(gxSpoil,gzSpoil)
            
            rf_inc=mod(rf_inc+rfSpoilingInc,360.0);
            rf_phase=mod(rf_phase+rf_inc,360.0);
        end

	    % RF spoiling
	    ex.rf.phaseOffset = rf_phase/180*pi;
	    sp.adc.phaseOffset = rf_phase/180*pi;
	    rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
	    rf_phase = mod(rf_phase+rf_inc, 360.0);

	    %-- START SEGMENT INSTANCE --%
		
	    % excitation
        tmp = ex.rf.signal;
        iShot = (iz-1)*nleaf + leaf;  % shot number
        ex.rf.signal = ex.rf.signal*FLIP(iShot)/max(FLIP);  % set flip angle
	    seq.addBlock(ex.rf, ex.gz, mr.makeLabel('SET', 'TRID', trid));
        ex.rf.signal = tmp;
	    seq.addBlock(ex.gzReph);

	    % readout and spoiling
	    seq.addBlock(mr.scaleGrad(gzPre, pe2Steps(iz)));
	    seq.addBlock(mr.rotate('z', (leaf-1)/nleaf*2*pi,'system',sys, sp.gx, sp.gy, sp.adc));
	    seq.addBlock(mr.scaleGrad(gzPre, -pe2Steps(iz)));
	    seq.addBlock(gxSpoil, gzSpoil);

	    %-- END SEGMENT INSTANCE --%
    end
end
textprogressbar('');

seq.setDefinition('FOV', fov);

% Write k-space sampling trajectory to file and append to seq struct
[kx, ky] = toppe.utils.g2k(1e2/sys.gamma*[sp.gx.waveform(:) sp.gy.waveform(:)], nleaf);
kx = kx(1:sp.adc.numSamples,:);
ky = ky(1:sp.adc.numSamples,:);

return

% Plot k-space (2d)
[ktraj_adc,t_adc,ktraj,t_ktraj,t_excitation,t_refocusing] = seq.calculateKspacePP();
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D k-space plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points
title('full k-space trajectory (k_x x k_y)');
