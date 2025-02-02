# Spiral sequence for Pulseq on GE v2 (pge2)

Interleaved 2D spiral.  

Tested on the following system(s):
* GE UHP
* SW version MR30.1_R01
* Pulseq interpreter pge2 (tv7) v2.2.0, available at https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.2.0

To download the required MATLAB packages,
create the pge sequence file, and reconstruct the data, see `main.m` in this folder.

For GE scan instructions, see https://github.com/jfnielsen/TOPPEpsdSourceCode/tree/UserGuide/v7

## Issues, troubleshooting

* Auto prescan fails when Nint >= 8, reason is unknown.
