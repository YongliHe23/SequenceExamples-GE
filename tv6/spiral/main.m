createSequenceFile = true;

if createSequenceFile
    % Get Pulseq toolbox and write spiral.seq
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

    % Plot TOPPE sequence files.
    % This is done by first untarring the files in the current working directory,
    % then calling toppe.plotseq() which will load and display those files.
    system('tar xf spiral.tar');
    figure;
    toppe.plotseq(sysGE, 'timeRange', [0 inf]);  % plot the whole sequence
end

