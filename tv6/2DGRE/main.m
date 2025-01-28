createSequenceFile = true;
reconstruct = true;

if createSequenceFile
    % Get Pulseq toolbox and write gre2d.seq
    system('git clone git@github.com:pulseq/pulseq.git');
    addpath pulseq/matlab
    write2DGRE;

    % Convert .seq file to a TOPPE tar-ball
    system('git clone --branch v1.10.2 git@github.com:HarmonizedMRI/PulCeq.git');
    addpath PulCeq/matlab
    system('git clone --branch v1.9.1 git@github.com:toppeMRI/toppe.git');
    addpath toppe

    sysGE = toppe.systemspecs('maxGrad', sys.maxGrad/sys.gamma*100, ...   % G/cm
        'maxSlew', sys.maxSlew/sys.gamma/10, ...                          % G/cm/ms
        'maxRF', 0.15, ...                    % recommend to keep this <= 0.15 G for accurate b1 scaling
        'rfDeadTime', 100, ...                % us
        'rfRingdownTime', 60, ...             % us
        'adcDeadTime', 40);                   % us

    seq2ge('gre2d.seq', sysGE, 'gre2d.tar');

    % plot TOPPE sequence files
    system('tar xf gre2d.tar');
    figure;
    toppe.plotseq(sysGE, 'timeRange', [0 inf]);  % plot the whole sequence
end

if reconstruct
    %Get MIRT toolbox
    system('git clone --depth 1 git@github.com:JeffFessler/mirt.git');
    cd mirt; setup; cd ..;

    addpath ~/Programs/orchestra-sdk-2.1-1.matlab/

    d = toppe.utils.loadsafile('mydata.h5', 'acq_order', true); %, 'version', 'tv6');

    % discard data during receive gain calibration (see write2DGRE.m)
    pislquant = 10;
    d = d(:,:, (pislquant+1):end);   

    d = permute(d, [1 3 2]);   % [Nx Ny ncoils]

    [nx, ny, ncoil] = size(d);

    % reconstruct complex coil images
    clear ims
    for ic = 1:ncoil
        ims(:,:,ic) = fftshift(ifftn(fftshift(d(:,:,ic))));
    end

    if ndims(d) > 2
        I = sqrt(sum(abs(ims).^2, ndims(d)));   % root sum of squares coil combination
    else
        I = abs(ims);
    end

    % Display. Requires MIRT toolbox, https://github.com/JeffFessler/mirt
    figure; im(flipdim(I', 1));   % to match orientation of object on console UI
end
