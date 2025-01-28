# Pulseq on GE v1 (tv6) examples 

**Updated January 2025**

This repository contains examples of how to prepare and run Pulseq sequences
on GE scanners using the Pulseq on GE v1 (tv6) interpreter.

For tv6 scan instructions, see the 
[Pulseq on GE v1 user guide [pdf]](https://drive.google.com/file/d/1eToTYUtFipf6UaAohOfuroNdFi4h8cOs/view?usp=sharing).

As discussed [here](https://github.com/jfnielsen/TOPPEpsdSourceCode/discussions/37), 
there are now two versions of tv6: the v1.9.x series and v1.10.x series.  
* v1.9.x is older and more stable, and resides in the 'main' branch of the EPIC source repository.  
* v1.10.x allows multiple ADC events, and resides in the 'develop' branch

The EPIC source code is available here: https://github.com/jfnielsen/TOPPEpsdSourceCode/


## Quick start

We recommend starting with the example in [2DGRE](2DGRE).

The user guide pdf mentioned describes additional examples -- the scripts for those examples
can be found here: 
https://github.com/jfnielsen/TOPPEpsdSourceCode/tree/UserGuide/v6/examples


## Preparing a .seq file for tv6

The key points to keep in mind when creating a .seq file for GE scanners are summarized here.
For more details, see the user guide pdf.

### Define segments (block groups) by adding TRID labels

We define a 'segment' as a consecutive sub-sequence of Pulseq blocks that are always executed together,
such as a TR or a magnetization preparation section.
The GE interpreter needs this information to construct the sequence.

Therefore, you must add `TRID` labels to mark the beginning of each TR or sequence sub-module. 
You can see how this is done in the examples included in this repository.
See the tv6 manual for further details.

When creating a segment, **the interpreter inserts a 116us dead time at the end of each segment**.
Please account for this when creating your .seq file.


### Set system hardware parameters

**Raster times:**  
* It is ok (and actually preferred) to use the default RF and gradient raster times 
in the Pulseq MATLAB toolbox (1us and 10us, respectively), since
the `seq2ge.m` conversion interpolates all waveforms to 4us.
* ADC dwell time must be an integer multiple of 2us

**Minimum gaps before and after RF/ADC events:**   
Like on other vendors, there is some time required to turn on/off the RF amplifier and ADC card.
To our knowledge, on GE these are:
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
              'rfRasterTime', 1e-6, ...
              'gradRasterTime', 10e-6, ...
              'blockDurationRaster', 10e-6, ...
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
              'rfRasterTime', 1e-6, ...
              'gradRasterTime', 10e-6, ...
              'blockDurationRaster', 10e-6, ...
              'B0', 3.0);
```

### Further comments on sequence timing

* The parameters `rfDeadTime`, `rfRingdownTime`, and `adcDeadTime` were included in the Pulseq MATLAB toolbox
with Siemens scanners in mind, and as just discussed, setting them to 0 can in fact be a preferred option in many cases for GE users.
This is because the default behavior in the Pulseq toolbox is to quietly insert corresponding gaps at the 
start end end of each block, however this is not necessary on GE since the block boundaries 'vanish' within a segment.
* In the internal sequence representation used by the interpreter, RF and ADC events are delayed by about 100us to account for gradient delays.
Depending on the sequence details, you may need to extend the segment duration to account for this.

The user guide pdf discusses these points in more detail.
