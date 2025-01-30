createSequenceFile = true;
reconstruct = false;

if createSequenceFile
    % Get Pulseq toolbox and write gre2d.seq
    system('git clone git@github.com:pulseq/pulseq.git');
    addpath pulseq/matlab
    writeSpiral;

    % Convert .seq file to a TOPPE tar-ball
    system('git clone --branch v1.10.6 git@github.com:HarmonizedMRI/PulCeq.git');
    addpath PulCeq/matlab
    %addpath ~/github/HarmonizedMRI/PulCeq/matlab
    system('git clone --branch v1.9.1 git@github.com:toppeMRI/toppe.git');
    addpath toppe

    sysGE = toppe.systemspecs('maxGrad', sys.maxGrad/sys.gamma*100, ...   % G/cm
        'maxSlew', sys.maxSlew/sys.gamma/10, ...                          % G/cm/ms
        'maxRF', 0.15, ...                   % recommend to keep this <= 0.15 G for accurate b1 scaling
        'rfDeadTime', 0, ...                 % us
        'rfRingdownTime', 0, ...             % us
        'adcDeadTime', 0);                   % us

    seq2ge('spiral.seq', sysGE, 'spiral.tar');

    % plot TOPPE sequence files
    system('tar xf spiral.tar');
    figure;
    toppe.plotseq(sysGE, 'timeRange', [0 inf]);  % plot the whole sequence
end

if reconstruct
    %Get MIRT toolbox
    system('git clone --depth 1 git@github.com:JeffFessler/mirt.git');
    cd mirt; setup; cd ..;

    addpath ~/Programs/orchestra-sdk-2.1-1.matlab/

    d = toppe.utils.loadsafile('mydata.h5', 'acq_order', true); %, 'version', 'tv6');

    % TODO: do gridding recon
end
