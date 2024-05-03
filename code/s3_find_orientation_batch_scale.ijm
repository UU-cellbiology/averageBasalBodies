Dialog.create("Find BB orientation parameters:");

Dialog.addNumber("Reference channel",2);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.addNumber("Maximum diameter (um)",2.44);
Dialog.addNumber("Diameter step (um)",0.1);
Dialog.addNumber("Rescale XY factor",1.0);
Dialog.addNumber("Rescale Z factor",1.0);
Dialog.show();
nChAlign=Dialog.getNumber();
nSD=Dialog.getNumber();
nDiamMax=Dialog.getNumber();
nDiamStep=Dialog.getNumber();
nScaleXY=Dialog.getNumber();
nScaleZ=Dialog.getNumber();
nVersion = "20240503";


//orientationMacroName ="find_orientation_single_20240301.ijm";
orientationMacroName ="s3b_find_orientation_CC_single.ijm";
//macroDir = getDir("Select a folder with macros...");
filesDir = getDir("Choose data folder files...");

macroDir = filesDir + "code/"
filesExtractedDir = filesDir+"s2_extracted/";
filesRotatedDir = filesDir+"s3_rotated/";
filesRotatedDetectionDir = filesRotatedDir+"detected/";
logDir = filesDir+"logs/";

sTimeStamp = getTimeStamp_sec();

File.makeDirectory(filesRotatedDir);
File.makeDirectory(filesRotatedDetectionDir);
File.makeDirectory(logDir);
//File.makeDirectory(filesMaskDir);
print("\\Clear");
print("Finding basal foot (step 3) macro ver "+nVersion);
print("Working on folder  "+filesDir);
print("Parameters values");
print("Reference channel: "+toString(nChAlign));
print("SD of the ring (um): "+toString(nSD));
print("Maximum diameter (um): "+toString(nDiamMax));
print("Diameter step (um): "+toString(nDiamStep));
print("Scale factor XY: "+toString(nScaleXY));
print("Scale factor Z: "+toString(nScaleZ));

suffix = "_straight.tif";
list = getFileList(filesExtractedDir);
setBatchMode(true);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		print("Working on file (orientation) "+list[nFile]);
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//open file
		basecurr = filesExtractedDir+list[nFile];
		//open file
		open(basecurr);
		nTimeTic = getTime();
		//get file ID
		openImageIDsmall=getImageID();
		run("Scale...", "x="+toString(nScaleXY)+" y="+toString(nScaleXY)+" z="+toString(nScaleZ)+" interpolation=Bicubic average create");
		openImageID=getImageID();
		selectImage(openImageIDsmall);
		close();
		//open results
		//run("Table... ", "open=["+filesDetectionDir+noExtFilename+".csv]");
		//Table.rename(noExtFilename+".csv", "Results");

		//run find orientation
		runstr=toString(nChAlign)+" "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep)+" 0.0 1.0";
		runMacro(macroDir + orientationMacroName, runstr);	

		saveAs("Tiff", filesRotatedDir+noExtFilename+".tif");

		close();
		selectWindow("rot_detected");
		saveAs("Tiff", filesRotatedDetectionDir+noExtFilename+"_rot.tif");
		close();
		nTimeToc = getTime();
		print("time per file: "+toString((nTimeToc-nTimeTic)/1000)+" s");
		selectWindow("Log");
		saveAs("Text", logDir+sTimeStamp+"_log_s3_find_orientation_macro.txt");
	}
}
setBatchMode(false);
print("All done");
selectWindow("Log");

saveAs("Text", logDir+sTimeStamp+"_log_s3_find_orientation_macro.txt");

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month+1,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}