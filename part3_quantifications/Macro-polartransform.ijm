roiManager("Select", 0);
run("Polar Transformer", "method=Polar degrees=360 for_polar_transforms, center_x=97 center_y=96");
roiManager("Select", 1);
run("Plot Profile");
saveAs("Results", "F:/PROJECTS/BasalBodiesAverage/Data representation_20250219/BB proteins/CEP164_001/Plot Values_CEP164.csv");

