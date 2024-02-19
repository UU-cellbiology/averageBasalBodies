Dialog.create("Destretch parameters:");

Dialog.addNumber("Channel for alignment ",4);
//Dialog.addNumber("Diameter (um) ",1.52);
Dialog.addNumber("Profile line width (pix)",6);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.show();

nChAlign = Dialog.getNumber();
//nDiamIn = Dialog.getNumber();
nLineWidth = Dialog.getNumber();
nSD = Dialog.getNumber();



destretchMacroName ="destretch_ellipse_single_20240219.ijm";
macroDir = getDir("Select a folder with macros...");
filesDir = getDir("Choose a folder with files...");
print("\\Clear");
print("Working on folder  "+filesDir);
filesAlignedDir = filesDir+"aligned/";
//File.makeDirectory(filesAlignedDir);
filesDestretchedDir = filesDir+"destretched/";
File.makeDirectory(filesDestretchedDir);


suffix = "_aligned.tif";
list = getFileList(filesAlignedDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		print("Working on file (destretch) "+list[nFile]);
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//open file
		basecurr = filesAlignedDir+list[nFile];
		//open file
		open(basecurr);
		//get file ID
		openImageID=getImageID();
		//open results
		run("Table... ", "open=["+filesAlignedDir+noExtFilename+".csv]");
		Table.rename(noExtFilename+".csv", "Results");
		//open(filesAlignedDir+noExtFilename+".csv");
		//run destretch
		runstr=toString(nChAlign)+" 1.0 "+toString(nLineWidth)+" "+toString(nSD)+" 1";
		runMacro(macroDir + destretchMacroName, runstr);	
		destretchID = getImageID();
		roiManager("Select", 0);
		roiManager("Save", filesDestretchedDir+noExtFilename+".roi");
		saveAs("Tiff", filesDestretchedDir+noExtFilename+"_aligned_destretched.tif");
		close();
		selectImage(openImageID);
		close();

	}
}
print("All done");
selectWindow("Log");

saveAs("Text", filesDir+"Log_batch_run.txt");
	
