% actions
createSequenceFile = false;
reconstruct = true;

if createSequenceFile
    % create .seq file
    system('git clone --depth 1 git@github.com:pulseq/pulseq.git');
    addpath pulseq/matlab
    write2DGRE;   % writes .seq file, and sets pislquant

    % Convert .seq file to a PulCeq (Ceq) object
    system('git clone --branch v2.1.2 git@github.com:HarmonizedMRI/PulCeq.git');
    addpath PulCeq/matlab
    ceq = seq2ceq('gre2d_ma.seq');
    writeceq(ceq, 'gre2d_ma.pge', 'pislquant', pislquant);
end

% Next, exeucte gre2d_ma.pge with the pge2 interpreter
% See README.md

if reconstruct
    addpath ~/Programs/orchestra-sdk-2.1-1.matlab/

    archive = GERecon('Archive.Load', 'test.h5');

    % skip past receive gain calibration TRs (pislquant)
    for n = 1:pislquant
        currentControl = GERecon('Archive.Next', archive);
    end

    % read first phase-encode of first echo
    currentControl = GERecon('Archive.Next', archive);
    [nx1 nc] = size(currentControl.Data);
    ny1 = nx1;
    d1 = zeros(nx1, nc, ny1);
    d1(:,:,1) = currentControl.Data;

    % read first phase-encode of second echo
    currentControl = GERecon('Archive.Next', archive);
    [nx2 nc] = size(currentControl.Data);
    d2 = zeros(nx2, nc, ny1);

    for iy = 2:ny1
        currentControl = GERecon('Archive.Next', archive);
        d1(:,:,iy) = currentControl.Data;
        currentControl = GERecon('Archive.Next', archive);
        d2(:,:,iy) = currentControl.Data;
    end

    d1 = permute(d1, [1 3 2]);   % [nx1 nx1 nc]
    d2 = permute(d2(:, :, end/2-nx2:end/2+nx2-1), [1 3 2]);   % [nx2 nx2 nc]

    [~, im1] = toppe.utils.ift3(d1, 'type', '2d');
    [~, im2] = toppe.utils.ift3(d2, 'type', '2d');

    system('git clone --depth 1 git@github.com:JeffFessler/mirt.git');
    cd mirt; setup; cd ..;

    subplot(121); im(im1);
    subplot(122); im(im2);
end

