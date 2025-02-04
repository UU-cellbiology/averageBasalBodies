source = getDir("Select folder with rescaled data...");
saveTo = getDir("Select folder to save averaged data...");
//source = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20241021/a3_scaling/rescaled/";
//saveTo = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20241021/a3_scaling/rescaled_avrg/";

run("Iterative Averaging", "input=[Tif files (low memory, slow)] select="+source+
" initial=Centered number=6 template=Average use constrain=[by image fraction] x=0.500 y=0.500 z=0.500 intermediate registered choose="+
saveTo);


///optional 
source = getDir("Select folder with non-rescaled data...");
saveTo = getDir("Select folder to save averaged data...");

//source = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20241021/a3_scaling/not_rescaled/";
//saveTo = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20241021/a3_scaling/not_rescaled_avrg/";

run("Iterative Averaging", "input=[Tif files (low memory, slow)] select="+source+
" initial=Centered number=6 template=Average use constrain=[by image fraction] x=0.500 y=0.500 z=0.500 intermediate registered choose="+
saveTo);
