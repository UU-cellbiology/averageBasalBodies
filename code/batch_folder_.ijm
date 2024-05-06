Dialog.create("Batch folder");
//Dialog.addNumber("Reference channel",2);
Dialog.addNumber("SD of the ring (um)",0.18);
Dialog.addNumber("Maximum diameter (um)",2.44);
Dialog.addNumber("Diameter step (um)",0.1);
Dialog.addNumber("Rescale XY factor",1.0);
Dialog.addNumber("Rescale Z factor",1.0);
Dialog.addNumber("Averaging iterations N", 4.0);
Dialog.show();
//nChAlign=Dialog.getNumber();
nSD=Dialog.getNumber();
nDiamMax=Dialog.getNumber();
nDiamStep=Dialog.getNumber();
nScaleXY=Dialog.getNumber();
nScaleZ=Dialog.getNumber();
nIterN=Dialog.getNumber();

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


suffix = "/";
list = getFileList(folderDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{	
		filesDir = folderDir+list[nFile];
		sFolderName = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//get last channel
		sExtr = filesDir+"s2_extracted/";
		listTIF = getFileList(sExtr);
		bOneFile=true;
		for (nFileTIF = 0; nFileTIF < listTIF.length &&bOneFile ; nFileTIF++) 
		{	
			if(endsWith(listTIF[nFileTIF], ".tif"))
			{	
				bOneFile = false;
				//open file
				testFile = sExtr+listTIF[nFileTIF];
				open(testFile);
				Stack.getDimensions(width, height, channels, slices, frames);
				nChAlign = channels;
				close();
			}
		}
		filesRotated = filesDir + "s3_rotated"+scaleSuffix+"/";
		filesAver = filesDir  + "s3_rotated"+scaleSuffix+"_avg/";
		File.makeDirectory(filesAver);
		runstr=toString(nChAlign)+" "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep)+" "+toString(nScaleXY)+" "+toString(nScaleZ);
		runstr=runstr + " "+filesDir+" "+ " "+macroDir+" ";
		runMacro(macroDir + "s3_find_orientation_batch_scale.ijm", runstr);
		print("\\Clear");
		
		
		runstr = "input=[Tif files (low memory, slow)]] select="+filesRotated+" for=[use channel "+toString(nChAlign)+"] initial=Centered number="+toString(nIterN)+" template=Average use constrain=[by voxels] x=30 y=30 z=100.000 intermediate registered choose=/"+filesAver;
		run("Iterative Averaging", runstr);
		selectWindow("Log");
		saveAs("Text", filesAver+"Log.txt");
		listTIF = getFileList(filesAver);
		bOneFile=true;
		for (nFileTIF = 0; nFileTIF < listTIF.length &&bOneFile ; nFileTIF++) 
		{	
			if(endsWith(listTIF[nFileTIF], ".tif"))
			{	
				bOneFile = false;
				//rename final file
				File.rename(filesAver+listTIF[nFileTIF], filesAver+sFolderName+"_"+scaleSuffix+"_"+listTIF[nFileTIF]);
			
			}
		}
		
	}
}