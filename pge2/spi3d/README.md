# 3D TGA SPI sequence for Pulseq on GE 

Code for sequence generation and recon provided by David Frey (djfrey@umich.edu)

This example is 3D TINY Golden Angle Spiral Projection Imaging.  

This example demonstrates gradient rotation detection with seq2ceq.m;
which is needed since rotation matrices are not stored in the Pulseq (.seq) file.
For more information about including rotated gradients in your .seq file, 
see https://github.com/HarmonizedMRI/SequenceExamples-GE/tree/main/pge2.

Tested by on the following system(s):
* GE MR750
* SW version MR30.1\_R01
* Pulseq interpreter pge2 version: https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.3.0

To download the required MATLAB packages,
create the pge sequence file, and reconstruct the data, see `main.m` in this folder.

Example reconstruction result:  
![image](https://github.com/user-attachments/assets/6f8a9bbb-a9e6-47d3-88c9-580bf4b66cdc)

