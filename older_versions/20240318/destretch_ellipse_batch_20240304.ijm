Dialog.create("Destretch parameters:");

Dialog.addNumber("Channel for alignment ",4);
Dialog.addNumber("Profile line width (pix)",6);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.addCheckbox("Generate XY/XZ max proj?", true);
Dialog.show();

nChAlign = Dialog.getNumber();
nLineWidth = Dialog.getNumber();
nSD = Dialog.getNumber();
bGenXYXZ=Dialog.getCheckbox();


destretchMacroName ="destretch_ellipse_single_20240220.ijm";
macroDir = getDir("Select a folder with macros...");
filesDir = getDir("Choose base folder with files...");
print("\\Clear");
print("Working on folder  "+filesDir);
filesDetectedDir = filesDir+"detected/";
filesExtractedDir = filesDir+"extracted/";
//File.makeDirectory(filesAlignedDir);
filesDestretchedDir = filesDir+"destretched/";
File.makeDirectory(filesDestretchedDir);
if(bGenXYXZ)
{
	filesAlignedXYDir = filesDestretchedDir+"destretchedXY/";
    File.makeDirectory(filesAlignedXYDir);
    filesAlignedXZDir = filesDestretchedDir+"destretchedXZ/";
    File.makeDirectory(filesAlignedXZDir);

}

suffix = "_straight.tif";
list = getFileList(filesExtractedDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		print("Working on file (destretch) "+list[nFile]);
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//open file
		basecurr = filesExtractedDir+list[nFile];
		//open file
		open(basecurr);
		//get file ID
		openImageID=getImageID();
		//open results
		run("Table... ", "open=["+filesDetectedDir+noExtFilename+".csv]");
		Table.rename(noExtFilename+".csv", "Results");
		//open(filesAlignedDir+noExtFilename+".csv");
		//run destretch
		runstr=toString(nChAlign)+" 1.0 "+toString(nLineWidth)+" "+toString(nSD)+" 1";
		runMacro(macroDir + destretchMacroName, runstr);	
		destretchID = getImageID();
		roiManager("Select", 0);
		roiManager("Save", filesDestretchedDir+noExtFilename+".roi");
		saveAs("Tiff", filesDestretchedDir+noExtFilename+".tif");
		if(bGenXYXZ)
		{
			saveXYXZproj(filesAlignedXYDir, filesAlignedXZDir, nChAlign, noExtFilename);
		}
		close();
		selectImage(openImageID);
		close();

	}
}
print("All done");
selectWindow("Log");

saveAs("Text", filesDir+getTimeStamp_sec()+"_log_destretch_batch_run.txt");
	
function saveXYXZproj(filesAlignedXYDir, filesAlignedXZDir, nChAlign, noExtFilename)
{
		finID=getImageID();
		getVoxelSize(pW, pH, pD, unit);
		run("Z Project...", "projection=[Max Intensity]");
		run("Make Composite");
		Stack.setChannel(nChAlign);
		resetMinAndMax();
		saveAs("Tiff", filesAlignedXYDir+"MAX_XY_"+noExtFilename+"_aligned_destretched.tif");
		close();
		selectImage(finID);
		run("Select All");
		run("Reslice [/]...", "output="+toString(pD)+" start=Top");
		tempRS=getImageID();
		run("Z Project...", "projection=[Max Intensity]");
		projXZ=getImageID();
		selectImage(tempRS);
		close();
		selectImage(projXZ);
		run("Make Composite");
		Stack.setChannel(nChAlign);
		resetMinAndMax();
		saveAs("Tiff", filesAlignedXZDir+"MAX_XZ_"+noExtFilename+"_aligned_destretched.tif");
		close();
		selectImage(finID);
}
function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}