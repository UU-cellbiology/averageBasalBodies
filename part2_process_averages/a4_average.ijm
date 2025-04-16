outputDir = getDir("Choose output data folder...");

nAverageIterations = 6;
//outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20250204/";
//outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_test_avrg/";

//source = getDir("Select folder with rescaled data...");
source = outputDir + "a3_rescaling/rescaled/";
saveTo = outputDir + "a4_averaged/rescaled_avrg/";
File.makeDirectory(saveTo);

run("Iterative Averaging", "input=[Tif files (low memory, slow)] select=["+source+
"] initial=Centered number="+toString(nAverageIterations)+" template=Average use constrain=[by image fraction] x=0.500 y=0.500 z=0.500 intermediate registered choose=["+
saveTo+"]");


///optional 
source = outputDir + "a3_rescaling/not_rescaled/";
saveTo = outputDir + "a4_averaged/not_rescaled_avrg/";
File.makeDirectory(saveTo);

run("Iterative Averaging", "input=[Tif files (low memory, slow)] select=["+source+
"] initial=Centered number="+toString(nAverageIterations)+" template=Average use constrain=[by image fraction] x=0.500 y=0.500 z=0.500 intermediate registered choose=["+
saveTo+"]");
