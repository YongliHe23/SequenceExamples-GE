# 2D spoiled GRE sequence for Pulseq on GE v2 (pge2)

Dual-echo 2D SPGR acquisition, with two different ADC events.

Tested on the following system:
* GE MR750 
* SW version MR30.1_R01
* Pulseq interpreter pge2 (tv7) v2.2.0, available at https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.2.0
 (private repository -- access granted to institutions with a GE research scanner).

To download the required MATLAB packages,
create the pge sequence file, and reconstruct the data, see `main.m` in this folder.

For GE scan instructions, see https://github.com/jfnielsen/TOPPEpsdSourceCode/tree/UserGuide/v7

The output of `main.m` is shown below.
The images on the left and right are from the 1st and 2nd echoes, respectively.

![Ball phantom](1.jpg)

