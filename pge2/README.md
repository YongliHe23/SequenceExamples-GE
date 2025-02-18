# Pulseq on GE v2 (pge2) examples 

This repository contains examples of how to prepare and run Pulseq sequences
on GE scanners using the 'Pulseq on GE v2' (pge2) interpreter.

To execute a Pulseq (.seq) file using pge2, one option is to convert it to a .pge file
using the PulCeq toolbox.  

Compared to tv6, the main features of the pge2 interpreter are:
* Loads a single binary file. We suggest using the file extension '.pge' but this is not a requirement. 
This file can be created with 
[Pulserver](https://github.com/INFN-MRI/pulserver/),
or with seq2ceq.m and writeceq.m, available here: https://github.com/HarmonizedMRI/PulCeq/.

* Places the trapezoid, extended trapezoid, and arbitrary waveform events directly onto the hardware,
  without first interpolating to 4us raster time as in the tv6 interpreter. 
  This saves hardware memory and enables things like very long constant (CW) RF pulses.
* Updated gradient heating and SAR/RF checks, based on sliding-window calculation.



## A note on software releases

It is important to use the appropriate versions (release) of the PulCeq toolbox and pge2 interpreter.
In each example included here, the versions are specified. See [2DGRE/main.m](2DGRE/main.m) for an example.

The following is a list of compatible versions of the PulCeq MATLAB toolbox and the pge2 interpreter,
starting with the latest (and recommended) version:

| pge2 (tv7) | Compatible with:   | Comments |
| ---------- | ------------------ | -------- |
| [v2.3.0](https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v2.3.0) | [PulCeq v2.2.2](https://github.com/HarmonizedMRI/PulCeq/releases/tag/v2.2.2) | Latest release. Bug fix for rotated gradients. |

A complete list of the release history is available here:  
https://github.com/HarmonizedMRI/PulCeq/releases/  
https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/ 


## Quick start

We recommend starting with the example in [2DGRE](2DGRE).

For information about accessing and using the pge2 interpreter, see information below.


## Creating the .seq file

The key points to keep in mind when creating a .seq file for the pge2 interpreter are summarized here.

### Define segments (block groups) by adding TRID labels

As in tv6, we define a 'segment' as a consecutive sub-sequence of Pulseq blocks that are always executed together,
such as a TR or a magnetization preparation section.
The GE interpreter needs this information to construct the sequence.

Therefore, you must add `TRID` labels to mark the beginning of each TR or sequence sub-module. 
You can see how this is done in the examples included in this repository.
See also the Pulseq on GE v1 (tv6) manual.

When creating a segment, **the interpreter inserts a 116us dead time (gap) at the end of each segment**.
Please account for this when creating your .seq file.

At present, **each segment must contain at least one gradient event**.
Otherwise, the gradient heating check done by the pge2 interpreter may fail.
To disable the gradient heating check, set the CV `disableGradientCheck` to 1 on the console (user CVs screen).


### Set system hardware parameters

**Raster times:**  
Unlike tv6, the waveforms in the .seq file are NOT interpolated to 4us, but are instead
placed directly onto the hardware. 
This is far more memory efficient and generally more accurate.
Therefore, the following raster time requirements must be met in the .seq file:
* gradient raster time must be multiple of 4us
* rf raster time must be multiple of 2us
* adc raster time must be multiple of 2us
* In addition, it seems best to set block duration raster to 4us

**Minimum gaps before and after RF/ADC events:**   
Like on other vendors, there is some time required to turn on/off the RF amplifier and ADC card.
To our knowledge, on GE these are:
```
Time to turn RF amplifier ON = 72us             # RF dead time
Time to turn RF amplifier OFF = 54us            # RF ringdown time
Time to turn ADC ON = 40us                      # ADC dead time
Time to turn ADC OFF = 0us
```

The key thing to note is that the dead/ringdown intervals from one RF/ADC event must not overlap with those from another RF/ADC event.

Also note that these times do NOT necessarily correspond to the values of `rfDeadTime`, `rfRingdownTime`, and `adcDeadTime`
you should use when creating the .seq file.
While the Pulseq MATLAB toolbox encourages the insertion of RF/ADC dead/ringdown times at the beginning
and end of each block, this is generally not necessary on GE,
and it is perfectly ok to override that behavior to make the sequence more time-efficient.
See the `sys` struct example next.


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
This is because the block boundaries 'disappear' inside a segment.
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
If this results in overlapping RF/ADC dead/ringdown times, you would then adjust the timing as needed
by modifying the event delays and block durations when creating the .seq file.


### Adding gradient rotation

* Gradient rotations can be implemented with the `mr.rotate()` function in the Pulseq MATLAB toolbox, or by hand.
* At present, each rotated waveform is stored as a separate shape in the .seq file, i.e., rotation information is not formally preserved in the .seq file.
* During the seq2ceq.m step (part of the PulCeq toolbox), rotations are detected and written into the "Ceq" sequence structure.
  This is necessary since the pge2 interpreter implements rotations more efficiently than explicit waveform shapes.
* If a segment contains multiple blocks with different rotation matrices, **only the last** of the non-identity rotations are applied. 
* The rotation is applied to the **entire segment** as a whole.
  In other words, the interpreter cannot rotate each block within a segment independently.


### Sequence timing: Summary and further comments

* When loading a segment, the interpreter inserts a 116us dead time at the end of each segment.
* The parameters `rfDeadTime`, `rfRingdownTime`, and `adcDeadTime` were included in the Pulseq MATLAB toolbox
with Siemens scanners in mind, and as just discussed, setting them to 0 can in fact be a preferred option in many cases for GE users.
This is because the default behavior in the Pulseq toolbox is to quietly insert corresponding gaps at the 
start end end of each block, however this is not necessary on GE since the block boundaries 'vanish' within a segment.
* In the internal sequence representation used by the interpreter, RF and ADC events are delayed by about 100us to account for gradient delays.
Depending on the sequence details, you may need to extend the segment duration to account for this.

The Pulseq on GE v1 (tv6) user guide pdf discusses some of these points in more detail.


## Converting the .seq file to a .pge file

In MATLAB:
```
% Get PulCeq toolbox and convert to Ceq representation
system('git clone --branch v2.1.2 git@github.com:HarmonizedMRI/PulCeq.git');
addpath PulCeq/matlab
ceq = seq2ceq('gre2d.seq');
pislquant = 10;               % number of ADC events at beginning of scan for receive gain calibration
writeceq(ceq, 'gre2d.pge', 'pislquant', pislquant);   % write Ceq struct to file
```


## Running the .pge file on the scanner

For scan instructions, see https://github.com/jfnielsen/TOPPEpsdSourceCode/tree/UserGuide/v7


## Troubleshooting tips

### The sequence fails when clicking 'Download' on the scanner console

Possible causes:
* The number of rows in the .seq file exceeds NMAXBLOCKSFORGRADHEATCHECK which is hardcoded to 64000.
 Design a shorter scan and see if it will run, or increase NMAXBLOCKSFORGRADHEATCHECK (requires recompiling the interpreter).
* One or more segments does not contain at least one gradient waveform, as required by the gradient heating check.
 Redesign your scan.

For debugging, it can be helpful to disable the gradient heating check by setting the CV **disableGradientCheck** to 1.


### The scanner reports that the gradient heating exceeds the system limit 

* If the sequence contains pure delay blocks, the gradient heating check will generally be too conservative and may issue a failure.
 As a workaround for now, redesign a test version of your sequence without pure delay blocks and see if it will pass the gradient heating check.
 Then in your actual scan, disable the gradient heating check by setting disableGradientCheck to 1.

