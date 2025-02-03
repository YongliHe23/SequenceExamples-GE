# 2D spoiled GRE sequence for tv6 (Pulseq on GE v1) with DABOUT output trigger/TTL pulse

Tested on the following system:
* GE UHP
* SW version MR30.1_R01
* Pulseq interpreter tv6 [v1.9.2](https://github.com/jfnielsen/TOPPEpsdSourceCode/releases/tag/v1.9.2)

Result:  
* CV7 = 6 results in TTL output pulse on J6 BNC 
* CV7 = 5 results in TTL output pulse on J8 BNC 

See [main.m](main.m).

This example is similar to the example in ../2DGRE/, it just adds an external trigger 
prior to the rf event.

Note:
* The **start position** of the TTL pulse is determined by the trigger event delay.
  The start position will be stated in modules.txt for the relevant block.
* The **duration** of the trigger is determined by the control variable `trigdur` on the scanner console.
  It defaults to 500us.
* **Only one segment** can contain a TTL trigger out. If a trigger is specified in subsequent segments,
  the interpreter ignores it.
* If a trigger is added to a segment, it will require a **separate TRID**.

When simulating in WTools/PulseStudio, you can see the two trigger-related SSP pulses 
(trigon and trigoff)
at about 200us and 700us from the beginning of the TR, respectively:
![Pulse Studio](pulsestudio.png)

The 500us TTL pulse is seen in the 2nd channel on this scope trace:

![Oscilloscope](scope.jpg)

