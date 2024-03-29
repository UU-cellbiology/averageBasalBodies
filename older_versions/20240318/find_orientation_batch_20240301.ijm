Dialog.create("Find BB orientation parameters:");

Dialog.addNumber("Reference channel",2);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.show();
nChAlign=Dialog.getNumber();
nSD=Dialog.getNumber();


//orientationMacroName ="find_orientation_single_20240301.ijm";
orientationMacroName ="find_orientation_BB_single_20240304.ijm";
macroDir = getDir("Select a folder with macros...");
filesDir = getDir("Choose a folder with files...");
print("\\Clear");
print("Working on folder  "+filesDir);
filesExtractedDir = filesDir+"extracted/";
filesDetectionDir = filesDir+"detected/";
filesRotatedDir = filesDir+"rotated/";
filesMaskDir = filesDir+"rotated/mask/";

File.makeDirectory(filesRotatedDir);
File.makeDirectory(filesMaskDir);

suffix = "_straight.tif";
list = getFileList(filesExtractedDir);
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
		//get file ID
		openImageID=getImageID();
		//open results
		run("Table... ", "open=["+filesDetectionDir+noExtFilename+".csv]");
		Table.rename(noExtFilename+".csv", "Results");

		//run find orientation
		runstr=toString(nChAlign)+" "+toString(nSD)+" 1.0 1.0 1.0";
		runMacro(macroDir + orientationMacroName, runstr);	

		saveAs("Tiff", filesRotatedDir+noExtFilename+".tif");

		close();
		selectWindow("mask");
		saveAs("Tiff", filesMaskDir+noExtFilename+".tif");
		close();

	}
}
print("All done");
selectWindow("Log");

saveAs("Text", filesDir+getTimeStamp_sec()+"_log_rotate_batch_run.txt");

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}