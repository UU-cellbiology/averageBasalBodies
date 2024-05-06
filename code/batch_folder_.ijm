Dialog.create("Batch folder");
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

folderDir = getDir("Choose data folder files...");
macroDir = getDir("Select code folder...");

suffix = "/";
list = getFileList(folderDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{	
		filesDir = folderDir+list[nFile];
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
		filesAver = filesDir + "s4_averaged/";
		File.makeDirectory(filesAver);
		runstr=toString(nChAlign)+" "+toString(nSD)+" "+toString(nDiamMax)+" "+toString(nDiamStep)+" "+toString(nScaleXY)+" "+toString(nScaleZ);
		runstr=runstr + " "+filesDir+" "+ " "+macroDir+" ";
		runMacro(macroDir + "s3_find_orientation_batch_scale_special.ijm", runstr);
		print("\\Clear");
		filesRotated = filesDir + "s3_rotated/";
		runstr = "input=[Tif files (high memory, fast)] select="+filesRotated+" choose=/"+filesAver;
		run("Iterative Averaging", runstr);
		selectWindow("Log");
		saveAs("Text", filesAver+"Log.txt");
	}
}