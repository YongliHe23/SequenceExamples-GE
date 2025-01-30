# 2D spoiled GRE sequence for tv6 (Pulseq on GE v1) with DABOUT output trigger/TTL pulse

Tested on the following system:
* GE MR750 
* SW version MR30.1_R01
* Pulseq interpreter tv6 [v1.9.1](https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v1.9.1)

The steps below are contained in [main.m](main.m).

This is similar to the example in ../2DGRE/, it just adds an external trigger 
during every other rf block.
