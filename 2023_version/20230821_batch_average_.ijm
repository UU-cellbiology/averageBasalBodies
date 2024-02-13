Dialog.create("Align/destretch parameters:");
Dialog.addNumber("Channel for alignment ",4);
Dialog.addNumber("Scale factor (1=no scale) ",2);
Dialog.addNumber("SD of the ring (um)",0.23);
Dialog.addNumber("Maximum diameter (um)",2.44);
Dialog.addNumber("Diameter step (um)",0.1);
Dialog.addNumber("Profile line width (pix)",6);
Dialog.show();
nChAlign=Dialog.getNumber();
nScale=Dialog.getNumber();
nSD=Dialog.getNumber();
nDiamMax=Dialog.getNumber();
nDiamStep=Dialog.getNumber();
nLineWidth=Dialog.getNumber();

alignMacroName ="20230821_circle_CC_multicolor_.ijm";
destretchMacroName ="20230821_ellipse_transform_multicolor_.ijm";

macroDir = getDir("Select a folder with macros...");
filesDir = getDir("Choose a folder with files...");
print("\\Clear");
print("Working on folder  "+filesDir);
filesAlignedDir = filesDir+"aligned/";
File.makeDirectory(filesAlignedDir);
filesDestretchedDir = filesDir+"destretched/";
File.makeDirectory(filesDestretchedDir);



suffix = ".tif";
list = getFileList(filesDir);
for (nFile = 0; nFile < list.length; nFile++) 
{
	
	if(endsWith(list[nFile], suffix))
	{
		print("Working on file "+list[nFile]);
		basecurr = filesDir+list[nFile];
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));

		//open file
		open(basecurr);
	
		//get file ID
		openImageID=getImageID();
		print("centering "+list[nFile]);
		//run alignment
		runstr=toString(nChAlign)+" "+toString(nScale)+" "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep);
		runMacro(macroDir+alignMacroName, runstr);
		alignID = getImageID();
		saveAs("Tiff", filesAlignedDir+noExtFilename+"_scaledx"+toString(nScale)+"_aligned.tif");
		saveAs("Results", filesAlignedDir+noExtFilename+"_align_Results.csv");
		//Table.rename(noExtFilename+"_align_Results.csv", "Results");
		selectImage(alignID);
		print("destretching "+list[nFile]);
		//run destretch
		runstr=toString(nChAlign)+" 1.0 "+toString(nLineWidth)+" 1";
		runMacro(macroDir + destretchMacroName, runstr);	
		destretchID=getImageID();
		roiManager("Select", 0);
		roiManager("Save", filesDestretchedDir+noExtFilename+".roi");
		print("one more alignment  "+list[nFile]);
		//run alignment again without scaling
		runstr=toString(nChAlign)+" 1 "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep);
		runMacro(macroDir+alignMacroName, runstr);
		destretch_alignID = getImageID();
				
		saveAs("Tiff", filesDestretchedDir+noExtFilename+"_scaledx"+toString(nScale)+"_aligned_destretched.tif");
		saveAs("Results", filesDestretchedDir+noExtFilename+"_destretch_Results.csv");
		
		print("finished  "+list[nFile]);
		//close everything
		selectImage(destretch_alignID);
		close();
		selectImage(destretchID);
		close();
		selectImage(alignID);
		close();
		selectImage(openImageID);
		close();
	
	
	}

}
print("All done");
selectWindow("Log");

saveAs("Text", filesDir+"Log_batch_run.txt");
