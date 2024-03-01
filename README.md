# extractBasalBodies
a set of ImageJ macros/GNU octave scripts for basal bodies extraction from ExM images 

## Workflow

### Part 1. Detecting basal bodies (BB) in 3D

0) Make sure that the [Correlescence plugin v.0.0.6](https://github.com/UU-cellbiology/Correlescence/releases/tag/v0.0.6) is installed on your FIJI.
1) Open a tiff file with basal bodies in ImageJ. It is recommended to remove channels that are not going to be used. For now, BigTrace (required for the later stage) can work only with 3 channels maximum.
2) Draw ROIs (of any type) at basal bodies (BB) locations at corresponding slices positions and add them to the ROI Manager. The center of the ROI should approximately overlap with the center of BB. It is recommended to save the whole list of ROIs from ROI Manager to a disk.
3) Run <b><i>detect_BB_BigTrace_single_YYYYMMDD.ijm</i></b> macro, a parameter dialog will appear, where we need to specify:
   <img src="https://github.com/UU-cellbiology/extractBasalBodies/blob/main/pictures/detect_dialog.png?raw=true" />
  - <i>Channel for detection</i> = number of the channel with total (panExM) stain;
  - <i>SD of the ring</i> = standard deviation of the Gaussian, fitted to the cross-section of BB ring;
  - <i>Maximum diameter</i> = of BB ring;
  - <i>Diameter step</i> = with which precision to determine a diameter;
  - If you select "Generate XY/XZ max proj", corresponding projections will be generated and saved as TIFF files in '<i>detectedXY</i>' and '<i>detectedXZ</i>' folders.
  - Option "Show detection (in overlay)" will add to the original image ROI circles at the detected BB positions. If you re-save original image, detections will be stored.
  - Option "Show diameter vs Z plots?" will generate windows showing detected BB diameter vs z-position plots. There would be as many windows and you have ROIs.
After clicking OK, a dialog with the choice of output storage folder will appear.

<b>OUTPUT:</b>    
In the storage folder (specified in the last step), the macro will make '<i>detected</i>' folder, where it will store tiffs with detected BBs and cvs files with coordinates of BB central axis in 3D. Filenames are the same as ROIs names.

 
   


