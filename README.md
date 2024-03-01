# extractBasalBodies
a set of ImageJ macros/GNU octave scripts for basal bodies extraction from ExM images 

## Workflow

### Part 1. Detecting basal bodies (BB) in 3D

0) Make sure that the [Correlescence plugin v.0.0.6](https://github.com/UU-cellbiology/Correlescence/releases/tag/v0.0.6) is installed on your FIJI.
1) Open a tiff file with basal bodies in ImageJ. It is recommended to remove channels that are not going to be used.
2) Make a list of ROIs (any type) at basal bodies (BB) locations at corresponding slices positions. The center of the ROI should approximately overlap with the center of BB. It is recommended to save this list.
3) Run <b><i>detect_BB_BigTrace_single_YYYYMMDD.ijm</i></b> macro, a parameter dialog will appear, where we need to specify:
  - <i>Channel for detection</i> = number of the channel with total (panExM) stain;
  - <i>SD of the ring</i> = standard deviation of the Gaussian, fitted to the cross-section of BB ring;
  - <i>Maximum diameter</i> = of BB ring;
  - <i>Diameter step</i> = with which precision to determine a diameter;

 
   

