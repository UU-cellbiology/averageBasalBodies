
input = getDirectory("Input folder with TIFs");
output = getDirectory("Results output folder");
macroDir = getDir("Select macro containing folder...");


//define suffix of files here
suffix = ".tif";
prefix = "reg_";

list = getFileList(input);

for (nFile = 0; nFile < list.length; nFile++) 
{
	if(startsWith(list[nFile], prefix) && endsWith(list[nFile], suffix))
	{
		currentFullFilename = input+list[nFile];

		//in case you need only filename
		
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		print("Working on file: " + noExtFilename);
		//step one, detection
		sParameters = currentFullFilename+"#"+output;
		runMacro(macroDir + "Macro-RadialPlotProfile_single.ijm", sParameters);
	
	}

}