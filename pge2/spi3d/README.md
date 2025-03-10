# 3D TGA SPI sequence for Pulseq on GE 

Code for sequence generation and recon provided by David Frey (djfrey@umich.edu)

This example is 3D TINY Golden Angle Spiral Projection Imaging.  

This example demonstrates gradient rotation detection with seq2ceq.m;
which is needed since rotation matrices are not stored in the Pulseq (.seq) file.
For more information about including rotated gradients in your .seq file, 
see https://github.com/HarmonizedMRI/SequenceExamples-GE/tree/main/pge2.

Tested on the following system(s):  

| Scanner | Scanner SW version | pge2 version | PulCeq version |  
| --- | --- | --- | --- |  
| GE MR750 | MR30.1\_R01 | [v2.5.0-beta](https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.5.0-beta) | [v2.4.0-alpha](https://github.com/HarmonizedMRI/PulCeq/releases/tag/v2.4.0-alpha) |  
| GE MR750 | MR30.1\_R01 | [v2.3.0](https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.3.0) | git clone --branch tv7 git@github.com:fmrifrey/PulCeq.git |

To download the required MATLAB packages,
create the pge sequence file, and reconstruct the data, see `main.m` in this folder.

Example reconstruction result:  
![image](https://github.com/user-attachments/assets/6f8a9bbb-a9e6-47d3-88c9-580bf4b66cdc)

