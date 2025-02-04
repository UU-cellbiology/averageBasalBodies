Dialog.create("Destretch parameters:");

Dialog.addNumber("Channel for alignment ",2);
Dialog.addNumber("Profile line width (pix)",6);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.addNumber("Maximum diameter (um)",2.44);
Dialog.addNumber("Diameter step (um)",0.1);
Dialog.addCheckbox("Generate XY/XZ max proj?", true);
Dialog.show();

nChAlign = Dialog.getNumber();
nLineWidth = Dialog.getNumber();
nSD = Dialog.getNumber();
nDiamMax=Dialog.getNumber();
nDiamStep=Dialog.getNumber();
bGenXYXZ=Dialog.getCheckbox();
nVersion = "20240429";


destretchMacroName ="s4b_destretch_ellipse_single.ijm";
filesDir = getDir("Choose data folder files...");

macroDir = filesDir + "code/"


filesAlignedDir = filesDir+"s3_rotated/";
//File.makeDirectory(filesAlignedDir);
filesDestretchedDir = filesDir+"s4_destretched/";
logDir = filesDir+"logs/";

sTimeStamp = getTimeStamp_sec();
File.makeDirectory(logDir);
File.makeDirectory(filesDestretchedDir);

print("\\Clear");
print("Destretching BB (step 4) macro ver "+nVersion);
print("Working on folder  "+filesDir);
print("Parameters values");
print("Reference channel: "+toString(nChAlign));
print("SD of the ring (um): "+toString(nSD));
print("Maximum diameter (um): "+toString(nDiamMax));
print("Diameter step (um): "+toString(nDiamStep));
print("Working on folder  "+filesDir);

if(bGenXYXZ)
{
	filesAlignedXYDir = filesDestretchedDir+"destretchedXY/";
    File.makeDirectory(filesAlignedXYDir);
    filesAlignedXZDir = filesDestretchedDir+"destretchedXZ/";
    File.makeDirectory(filesAlignedXZDir);

}
setBatchMode(true);
suffix = ".tif";
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
		nTimeTic = getTime();
	
		runstr=toString(nChAlign)+" "+toString(nLineWidth)+" "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep);
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
		nTimeToc = getTime();
		print("time per file: "+toString((nTimeToc-nTimeTic)/1000)+" s");
		selectWindow("Log");
		saveAs("Text", logDir+sTimeStamp+"_log_s4_destretch_macro.txt");

	}
}
setBatchMode(false);
print("All done");
selectWindow("Log");
saveAs("Text", logDir+sTimeStamp+"_log_s4_destretch_macro.txt");
	
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