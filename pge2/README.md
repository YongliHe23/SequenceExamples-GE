# Pulseq on GE v2 (pge2) examples 

This repository contains examples of how to prepare and run Pulseq sequences
on GE scanners using the 'Pulseq on GE v2' (pge2) interpreter.


## Quick start

We recommend starting with the example in [2DGRE](2DGRE).

For information about accessing and using the pge2 interpreter, see information below.


## A note on software releases

It is important to use the appropriate versions (release) of the PulCeq toolbox and pge2 interpreter.
In each example included here, the versions are specified. See [2DGRE/main.m](2DGRE/main.m) for an example.

The various releases are available here:  
https://github.com/HarmonizedMRI/PulCeq/releases/  
https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/ 


## Preparing a .seq file for GE

### Define segments (block groups) by adding TRID labels

We define a 'segment' as a consecutive sub-sequence of Pulseq blocks that are always executed together,
such as a TR or a magnetization preparation section.
The GE interpreter needs this information to construct the sequence.

Therefore, like in tv6, you must add `TRID` labels to mark the beginning of each TR or sequence sub-module. 
You can see how this is done in the examples included in this repository.
See also the tv6 manual for further details.

When creating a segment, **the interpreter inserts a 116us dead time at the end of each segment**.
Please account for this when creating your .seq file.


### Set system hardware parameters

**Raster times:**  
* gradient raster time must be multiple of 4us
* rf raster time must be multiple of 2us
* adc raster time must be multiple of 2us
* In addition, it seems best to set block duration raster to 4us

**Minimum gaps before and after RF/ADC events:**   
* Time to turn RF amplifier ON = 72us
* Time to turn RF amplifier OFF = 54us
* Time to turn ADC ON = 40us
* Time to turn ADC OFF = 0us

**Examples:**
```
sys = mr.opts('maxGrad', 40, 'gradUnit','mT/m', ...
              'maxSlew', 180, 'slewUnit', 'T/m/s', ...
              'rfDeadTime', 100e-6, ...
              'rfRingdownTime', 60e-6, ...
              'adcDeadTime', 40e-6, ...
              'adcRasterTime', 2e-6, ...
              'rfRasterTime', 2e-6, ...
              'gradRasterTime', 4e-6, ...
              'blockDurationRaster', 4e-6, ...
              'B0', 3.0);
```
Note, however, that it may be possible to set some or all of the various dead- and ringdown times to 0
as long as there is a gap in the previous/subsequent block to allow time 
to turn on/off RF and ADC events.
If you know this to be the case, you may want to try the following, more time-efficient, alternative:

```
sys = mr.opts('maxGrad', 40, 'gradUnit','mT/m', ...
              'maxSlew', 180, 'slewUnit', 'T/m/s', ...
              'rfDeadTime', 0, ...
              'rfRingdownTime', 0, ...
              'adcDeadTime', 0, ...
              'adcRasterTime', 2e-6, ...
              'rfRasterTime', 2e-6, ...
              'gradRasterTime', 4e-6, ...
              'blockDurationRaster', 4e-6, ...
              'B0', 3.0);
```




## Converting the .seq file to a .pge file

In MATLAB:
```
% Get PulCeq toolbox and convert to Ceq representation
system('git clone --branch v2.1.2 git@github.com:HarmonizedMRI/PulCeq.git');
addpath PulCeq/matlab
ceq = seq2ceq('gre2d.seq');
pislquant = 10;               % number of ADC events at beginning of scan to use for receive gain calibration
writeceq(ceq, 'gre2d.pge', 'pislquant', pislquant);   % write Ceq struct to file. This is what pge2 will load and run.
```


## The pge2 interpreter

The EPIC source code is available at 
https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/.

For scan instructions, see https://github.com/jfnielsen/TOPPEpsdSourceCode/tree/UserGuide/v7

For those familiar with the previous interpreter (tv6), the main changes are:

* Loads a single binary file. We suggest using the file extension '.pge' but this is not a requirement. 
This file can be created with 
[Pulserver](https://github.com/INFN-MRI/pulserver/),
or with seq2ceq.m and writeceq.m, available here: https://github.com/HarmonizedMRI/PulCeq/.

* Preserves the trapezoid, extended trapezoid, and arbitrary waveform representations in the Pulseq file, 
  which saves hardware memory and enables things like very long constant (CW) RF pulses.
  (In tv6, every waveform was interpolated to 4us raster, which is limiting.)

* Updated gradient heating and SAR/RF checks, based on sliding-window calculation (safety.e)


