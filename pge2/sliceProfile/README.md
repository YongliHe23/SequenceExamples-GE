# Sequence for simulating and imaging slice profile

Sequence excites a vertical slice and does 2D imaging.  
See `main.m` for workflow.  
Set paths with `setup.m`.

Workflow
1. Get code dependencies
   ```matlab
   >> setup
   ```

2. Edit main.m and run it:
   ```matlab
   >> main
   ```

   You should see the simulated slice profile:  
   <img width="610" height="599" alt="image" src="https://github.com/user-attachments/assets/1123e9ef-61b7-42a0-9b25-493be291ca77" />


4. Copy `sliceprofile.pge` to your GE scanner and run it using the pge2 interpreter, https://github.com/GEHC-External/pulseq-ge-interpreter/

   
