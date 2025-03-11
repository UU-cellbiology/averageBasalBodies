Dialog.create("Batch folder");
//Dialog.addNumber("Reference channel",2);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.addNumber("Maximum diameter (um)",2.1);
Dialog.addNumber("Diameter step (um)",0.1);
Dialog.addNumber("Diameter of extraction (px)", 105);
Dialog.addNumber("Rescale XY factor",2.0);
Dialog.addNumber("Rescale Z factor",1.0);
Dialog.addNumber("Averaging iterations N", 4.0);
Dialog.show();
//nChAlign=Dialog.getNumber();
nSD = Dialog.getNumber();
nDiamMax = Dialog.getNumber();
nDiamStep = Dialog.getNumber();
nOutThickness = Dialog.getNumber();
nScaleXY = Dialog.getNumber();
nScaleZ = Dialog.getNumber();
nIterN = Dialog.getNumber();

folderDir = getDir("Choose data folder files...");
macroDir = getDir("Select code folder...");

scaleSuffix = "";
if(abs(nScaleXY-1.0)>0.001)
{
	scaleSuffix = scaleSuffix +"_XY"+toString(nScaleXY);
}
if(abs(nScaleZ-1.0)>0.001)
{
	scaleSuffix = scaleSuffix +"_Z"+toString(nScaleZ);
}

paramSeparator = "?";

suffix = "/";
listFolder = getFileList(folderDir);
for (nFolder = 0; nFolder < listFolder.length; nFolder++) 
{	
	if(endsWith(listFolder[nFolder], suffix))
	{	
		filesDir = folderDir+listFolder[nFolder];
		sFolderName = substring(listFolder[nFolder], 0, lengthOf(listFolder[nFolder])-lengthOf(suffix));
		bAllGoesWell = true;
		//open raw data file and
		//get last channel
		listFiles = getFileList(filesDir);
		bOneFile=true;
		for (nFile = 0; nFile < listFiles.length &&bOneFile ; nFile++) 
		{	
			if(endsWith(listFiles[nFile], ".tif"))
			{	
				bOneFile = false;
				//open file
				origFileTIF = filesDir+listFiles[nFile];
				open(origFileTIF);
				Stack.getDimensions(width, height, channels, slices, frames);
				nChAlign = channels;
				//close();
				origID = getImageID();
			}
		}
		if (bOneFile)
		{
			print("\\Clear");
			print("In the folder " + filesDir + " could not find tif file"); 
			selectWindow("Log");
			saveAs("Text", filesDir+"error.txt");
			bAllGoesWell = false;
		}
		if(bAllGoesWell)
		{
			//open ROIs
			bOneFile=true;
			for (nFile = 0; nFile < listFiles.length &&bOneFile; nFile++) 
			{	
				if(endsWith(listFiles[nFile], ".zip"))
				{	
					bOneFile = false;
					//open file
					roiFile = filesDir+listFiles[nFile];
					roiManager("Open", roiFile);
				}
				
			}
			if (bOneFile)
			{
				print("\\Clear");
				print("In the folder " + filesDir + " could not find zip file with ROIs"); 
				selectWindow("Log");
				saveAs("Text", filesDir+"error.txt");
				bAllGoesWell = false;
			}
		}
		
		if(bAllGoesWell)
		{
			//step one, detection
			runstr=toString(nChAlign)+paramSeparator+toString(nSD)+paramSeparator+toString(nDiamMax)+paramSeparator+toString(nDiamStep)+paramSeparator +filesDir;
			runMacro(macroDir + "s1_detect_BB_BigTrace_single.ijm", runstr);
			
			print("\\Clear");
			selectWindow("ROI Manager");
			run("Close");
			selectImage(origID);
			saveAs("Tiff",origFileTIF);
			close();
			
			//step two, extraction
			runstr=toString(nOutThickness)+paramSeparator+filesDir+paramSeparator+origFileTIF;
			runMacro(macroDir + "s2_cvs_extract_BigTrace_rois.ijm", runstr);
			
			//step three, scaling and rotation
			filesRotated = filesDir + "s3_rotated"+scaleSuffix+"/";
			filesAver = filesDir  + "s3_rotated"+scaleSuffix+"_avg/";
			File.makeDirectory(filesAver);
			runstr=toString(nChAlign)+paramSeparator+toString(nSD)+paramSeparator+toString(nDiamMax)+paramSeparator+toString(nDiamStep)+paramSeparator+toString(nScaleXY)+paramSeparator+toString(nScaleZ);
			runstr=runstr + paramSeparator+filesDir+paramSeparator+macroDir+paramSeparator;
			runMacro(macroDir + "s3_find_orientation_batch_scale.ijm", runstr);
			
			//step four, averaging
			print("\\Clear");						
			runstr = "input=[Tif files (low memory, slow)]] select=["+filesRotated+"] for=[use channel "+toString(nChAlign)+"] initial=Centered number="+toString(nIterN)+" template=Average use constrain=[by voxels] x=20 y=20 z=100.000 intermediate registered choose=["+filesAver+"]";
			run("Iterative Averaging", runstr);
			selectWindow("Log");
			saveAs("Text", filesAver+ getTimeStamp_sec()+"_log_averaging.txt");
			print("fitting diameters");
			//step five, quantifications of diameter
			runstr=toString(nChAlign)+paramSeparator+toString(nSD)+paramSeparator+toString(nDiamMax)+paramSeparator+toString(nDiamStep)*0.5+paramSeparator+toString(nScaleXY)+paramSeparator+toString(filesAver);
			runMacro(macroDir + "s3c_estimate_diam.ijm", runstr);

			print("done.");
			
			///rename averaged and diameter
			listTIF = getFileList(filesAver);
			bOneFile=true;
			for (nFileTIF = 0; nFileTIF < listTIF.length && bOneFile ; nFileTIF++) 
			{	
				if(endsWith(listTIF[nFileTIF], ".tif"))
				{	
					bOneFile = false;
					finalAverTIF = listTIF[nFileTIF];
					//rename final file
					File.rename(filesAver+finalAverTIF, filesAver+sFolderName+scaleSuffix+"_"+finalAverTIF);
					
				}
			}
			filenameCSV = substring(finalAverTIF, 0, lengthOf(finalAverTIF)-lengthOf(".tif"))+"_diam.csv";
			print(filenameCSV);
			File.rename(filesAver+filenameCSV, filesAver+sFolderName+scaleSuffix+"_"+filenameCSV);		}


		
	}
}

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month+1,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}