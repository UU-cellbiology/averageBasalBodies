// Cell Biology, Neurobiology and Biophysics Department of Utrecht University.
// email y.katrukha@uu.nl
// full info, check https://github.com/UU-cellbiology/extractBasalBodies

nVersion = "20250822";

bBatchFolder = false;
values = getArgument();
//called from another macro
paramSeparator = "?";
if(values.length()>0)
{
	params = split(values, paramSeparator);
	nChAlign = parseInt(params[0]);
	nSD = parseFloat(params[1]);
	nDiamMax = parseFloat(params[2]);
	nDiamStep = parseFloat(params[3]);
	nScaleXY = 1.0/parseFloat(params[4]);
	filesDir = params[5];
	
	bBatchFolder = true;
}
else
{
	Dialog.create("BB detection parameters:");
	Dialog.addNumber("Channel for detection ",1);
	Dialog.addNumber("SD of the ring nm)",47);
	Dialog.addNumber("Maximum diameter (um)",470);
	Dialog.addNumber("Diameter step (um)",16);
	Dialog.addNumber("Rescale XY factor",1.0);
	Dialog.show();
	nChAlign=Dialog.getNumber();
	nSD=Dialog.getNumber();
	nDiamMax=Dialog.getNumber();
	nDiamStep=Dialog.getNumber();
	nScaleXY = 1.0/Dialog.getNumber();
}
if(!bBatchFolder)
{
	filesDir = getDir("Choose data folder files...");
}

setBatchMode(true);
//preparations
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
run("Set Measurements...", "mean min redirect=None decimal=7");
nDiamMin = 3*nSD;

//setBatchMode(true);
suffix = ".tif";

list = getFileList(filesDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		print("Working on file "+list[nFile]);
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//open file
		basecurr = filesDir+list[nFile];
		//open file
		open(basecurr);
		//get file ID
		openImageID=getImageID();
		nTimeTic = getTime();
		Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
		getVoxelSize(pW, pH, pD, unit);
		nSDpix = nSD/pW; 
		bitD = bitDepth();

		//resize to have odd number of pixels
		run("Canvas Size...", "width="+toString(Math.floor(widthOrig/2)*2+1)+" height="+toString(Math.floor(heightOrig/2)*2+1)+" position=Center");
		Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
		
		//get only channel we need
		run("Select All");
		run("Duplicate...", "title=alignChannel duplicate channels="+toString(nChAlign));
		alignID = getImageID();
		if(Math.abs(nScaleXY-1)>0.001)
		{
			run("Scale...", "x="+toString(nScaleXY)+" y="+toString(nScaleXY)+" z=1.0 interpolation=Bilinear average process create");
			
			alignScaled = getImageID();
			selectImage(alignID);
			close();
			selectImage(alignScaled);
			alignID = getImageID();
			Stack.getDimensions(widthOrig, heightOrig, tempchan, slices, frames);
			getVoxelSize(pW, pH, pD, unit);
			nSDpix = nSD/pW; 
		}
		
		nDiamTable = makeTemplateCircles(bitD, widthOrig, heightOrig, nSD, nDiamMin, nDiamMax, pW);
		templateID = getImageID();
		nTemplateSlN = nDiamTable.length+1;
		globX = newArray(slices);
		globY = newArray(slices);
		globDiam  = newArray(slices);
		globCCMax = newArray(slices);
		
		for(nSl=1; nSl<=slices; nSl++)
		{
			
			selectImage(alignID);
			setSlice(nSl);
			run("Select All");
			run("Measure");
			intVal = getResult("Mean", nResults-1);
			if(intVal>0.001)
			{
				findSlicePosition(globCCMax,globX,globY,globDiam,nSl);
			}
			else 
			{
				globCCMax[nSl-1] = NaN;
		   		globX[nSl-1] = NaN;
		   		globY[nSl-1] = NaN;
		   		globDiam[nSl-1] = NaN;
			}
		}
		selectImage(alignID);
		close();
		selectImage(templateID);
		close();
		run("Clear Results");	
		for(i=0;i<slices;i++)
		{
			setResult("finCCMax", i, globCCMax[i]);
			setResult("finDiam", i, globDiam[i]);
			setResult("finX", i ,0.5*widthOrig +  globX[i]);
			setResult("finY", i, 0.5*heightOrig + globY[i]);
			setResult("finZ", i, i+1);

		}
		selectImage(openImageID);

		close();

		//saving results
		saveAs("Results",  filesDir+noExtFilename+"_center_diam.csv");
		print("Done");
	}
}
setBatchMode(false);

function findSlicePosition(globCCMax,globX,globY,globDiam,nCurrSlice)
{

	selectImage(alignID);
	setSlice(nCurrSlice);
	run("Select All");
	run("Copy");
	selectImage(templateID);
	setSlice(1);
	run("Select All");
	run("Paste");
	run("Clear Results");
	run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] limit max=20 max_0=20");
	//close CC stack
	close();
	globX[nCurrSlice-1] = getResult("Xmax_(px)", 1);
	globX[nCurrSlice-1] = getResult("Ymax_(px)", 1);
	globDiam[nCurrSlice-1] = nDiamTable[0];
	globCCMax[nCurrSlice-1] = getResult("CC_max", 1);
	
	for (i = 1; i < nTemplateSlN-1; i++) 
	{
		currMaxCC = getResult("CC_max", i+1);
		if(currMaxCC>globCCMax[nCurrSlice-1])
		{
		   	globCCMax[nCurrSlice-1] = currMaxCC;
		   	globX[nCurrSlice-1] = getResult("Xmax_(px)", i+1);
		   	globY[nCurrSlice-1] = getResult("Ymax_(px)", i+1);
		   	globDiam[nCurrSlice-1] = nDiamTable[i];
	    }
	}

}

function makeTemplateCircles(bitD, tempW, tempH, nSD,nDiamMin, nDiamMax, pW)
{
	//make a stack of circles with the first image empty
	//count slices

	nTemplateSlN = 1;
	for (nDiameter = nDiamMin; nDiameter<=nDiamMax; nDiameter+=nDiamStep) 
	{	
		nTemplateSlN++;
	}
	//print(nTemplateSlN);
	//make it 2x larger
	newImage("circletemplate", toString(bitD)+"-bit black", tempW*2+1, tempH*2+1, nTemplateSlN);
	templateID = getImageID();
	nDiamTable = newArray(nTemplateSlN-1);
	nTempSlice = 2;
	nCenterShiftX = (tempW);
	nCenterShiftY = (tempH);
	for (nDiameter = nDiamMin; nDiameter<=nDiamMax; nDiameter+=nDiamStep) 
	{
		selectImage(templateID);
		setSlice(nTempSlice);
		nRadPx = Math.round(nDiameter/pW);
		
		//make an image of a circle
		setLineWidth(1);
		drawOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
	
		run("Select All");
		//blur
		run("Gaussian Blur...", "sigma="+toString(2*nSDpix));
		nDiamTable[nTempSlice-2]=nDiameter;
		nTempSlice++;
	}
	//make it 2x smaller
	tempx2ID = getImageID();
	run("Scale...", "x=- y=- z=1.0 width="+toString(tempW)+" height="+toString(tempH)+" interpolation=Bilinear average process create");
	tempxID = getImageID();
	selectImage(tempx2ID);
	close();
	selectImage(tempxID);

	return nDiamTable;
}