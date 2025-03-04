// Cell Biology, Neurobiology and Biophysics Department of Utrecht University.
// email y.katrukha@uu.nl
// full info, check https://github.com/UU-cellbiology/extractBasalBodies

nVersion = "20250205";

bBatchFolder = false;
values = getArgument();
paramSeparator = "?";
if(values.length()>0)
{
	params = split(values, paramSeparator);
	nOutThickness=parseInt(params[0]);
	filesDir = params[1];
	fileExtract = params[2];
  	bBatchFolder = true;
}
else
{
	Dialog.create("extract straightened BB:");
	Dialog.addNumber("Thickness (diameter), px",105);
	Dialog.show();
	nOutThickness = Dialog.getNumber();
}
if(!bBatchFolder)
{
	filesDir = getDir("Choose data folder files...");
	fileExtract = File.openDialog("Choose z-stack (TIF file) for BB extraction");
}
filesDetectedDir = filesDir+"s1_detected/";
filesExtractedDir = filesDir+"s2_extracted/";
filesBTROIsDir = filesDir+"s2_extracted/BT_rois/";
logDir = filesDir+"logs/";
sTimeStamp = getTimeStamp_sec();
File.makeDirectory(filesExtractedDir);
File.makeDirectory(filesBTROIsDir);
File.makeDirectory(logDir);
print("\\Clear");
print("Extracting basal foot (step 2) macro ver "+nVersion);
print("Working on folder  "+filesDir);
print("Parameters values");
print("Thickness (diameter), px: "+toString(nOutThickness));
print("Extracting BB from " +fileExtract);

suffix = ".csv";
list = getFileList(filesDetectedDir);

roiFile =filesBTROIsDir + "BB_ROIs_btrois.csv";
print("exporting BigTrace ROIs to " +roiFile);
selectWindow("Log");
saveAs("Text", logDir+sTimeStamp+"_log_s2_extract_BB_macro.txt");
if(File.exists(roiFile))
{
	File.delete(roiFile);
}
file_out = File.open(roiFile);
print(file_out,"BigTrace_groups,version,0.5.2");
print(file_out,"GroupsNumber,1\nBT_Group,1\nName,*undefined*");
print(file_out,"PointSize,4\nPointColor,0,255,0,255");
print(file_out,"LineThickness,"+toString(nOutThickness)+"\nLineColor,0,0,255,255");
print(file_out,"RenderType,2");
print(file_out,"End of BigTrace Groups");
print(file_out,"BigTrace_ROIs,version,0.5.2");
print(file_out,"ROIsNumber,"+toString(list.length));
//print(f,"");


nRoiCount = 1;
//setBatchMode(true);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		basecurr = filesDetectedDir+list[nFile];
		run("Table... ", "open=["+basecurr+"]");
		Table.rename(list[nFile], "Results");
		
	 	print(file_out,"BT_Roi,"+toString(nRoiCount)+"\nType,LineTrace");
  		print(file_out,"Name,"+noExtFilename);
  		print(file_out,"GroupInd,0");
  		print(file_out,"TimePoint,0");
  		print(file_out,"PointSize,4\nPointColor,0,255,0,255");
 		print(file_out,"LineThickness,"+toString(nOutThickness)+"\nLineColor,0,0,255,255");
 		print(file_out,"RenderType,2");
  		print(file_out,"Vertices,2");
  		ind = 0;
  		print(file_out,toString(getResult("finX", ind))+","+toString(getResult("finY", ind))+"," +toString(getResult("finZ", ind)));
  		ind = nResults-1;
  		print(file_out,toString(getResult("finX", ind))+","+toString(getResult("finY", ind))+"," +toString(getResult("finZ", ind)));
  		print(file_out,"SegmentsNumber,1");
  		print(file_out,"Segment,1,Points,"+toString(ind));
  		nRoiCount++;
  		for(ind=0;ind<nResults;ind++)
  		{
  			print(file_out,toString(getResult("finX", ind))+","+toString(getResult("finY", ind))+"," +toString(getResult("finZ", ind)));
  		}
	}
}
print(file_out,"End of BigTrace ROIs");
File.close(file_out);
print("done. Running BigTrace.");
selectWindow("Log");
saveAs("Text", logDir+sTimeStamp+"_log_s2_extract_BB_macro.txt");
run("Open 3D image", "open=["+fileExtract+"]");
Ext.btShapeInterpolation("Spline", 5);
Ext.btIntensityInterpolation("Linear");
Ext.btLoadROIs(roiFile, "Clean");
Ext.btStraighten(2, filesExtractedDir, "Square");
Ext.btClose();
//setBatchMode(false);
print("extraction finished.");
selectWindow("Log");
saveAs("Text", logDir+sTimeStamp+"_log_s2_extract_BB_macro.txt");

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month+1,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}