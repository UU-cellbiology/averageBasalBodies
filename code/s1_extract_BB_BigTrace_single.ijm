// Cell Biology, Neurobiology and Biophysics Department of Utrecht University.
// email y.katrukha@uu.nl
// this macro requires the following plugin to be installed
// https://github.com/UU-cellbiology/Correlescence/releases/tag/v0.0.7

nVersion = "20240429";

Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);

//in case it is called from another macro
values = getArgument();
if(values.length()>0)
{
	params = split(values, "");
	nChAlign=parseInt(params[0]);
	nSD=parseFloat(params[1]);
	nDiamMax=parseFloat(params[2]);
	nDiamStep=parseFloat(params[3]);
	bGenXYXZ = true;
	if(parseFloat(params[4])==0)
	{
		bGenXYXZ=false;
	}
	bShowDetection = false;
	bExtractStack = false;
}
else
{
	Dialog.create("BB detection parameters:");
	Dialog.addNumber("Channel for detection ",channels);
	Dialog.addNumber("SD of the ring (um)",0.18);
	Dialog.addNumber("Maximum diameter (um)",2.44);
	Dialog.addNumber("Diameter step (um)",0.1);
	Dialog.addCheckbox("Extract stacks? ", false);
	Dialog.addCheckbox("Generate XY/XZ max proj?", false);
	Dialog.addCheckbox("Show detection (in overlay)? ", true);
	Dialog.show();
	nChAlign=Dialog.getNumber();
	nSD=Dialog.getNumber();
	nDiamMax=Dialog.getNumber();
	nDiamStep=Dialog.getNumber();
	bExtractStack=Dialog.getCheckbox();
	bGenXYXZ=Dialog.getCheckbox();
	bShowDetection=Dialog.getCheckbox();

}

nDiamMin =3*nSD;
filesDir = getDir("Choose a folder to save output...");
print("\\Clear");
print("Detecting basal bodies (step 1) macro ver "+nVersion);
print("Parameters values");
print("Detection channel: "+toString(nChAlign));
print("SD of the ring (um): "+toString(nSD));
print("Maximum diameter (um): "+toString(nDiamMax));
print("Diameter step (um): "+toString(nDiamStep));
filesAlignedDir = filesDir+"s1_detected/";
File.makeDirectory(filesAlignedDir);
logDir = filesDir+"logs/";
File.makeDirectory(logDir);

sTimeStamp = getTimeStamp_sec();

if(bGenXYXZ)
{
	filesAlignedXYDir = filesAlignedDir+"detectedXY/";
    File.makeDirectory(filesAlignedXYDir);
    filesAlignedXZDir = filesAlignedDir+"detectedXZ/";
    File.makeDirectory(filesAlignedXZDir);

}

setBatchMode(true);

//preparations
run("Set Measurements...", "min redirect=None decimal=5");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);

origID = getImageID();
origTitle = getTitle();
print("Analyzing file: "+ origTitle);
bitD = bitDepth();
if(bitD>16)
{
	exit("only 8- and 16-bit images are supported.");
}
Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
getVoxelSize(pW, pH, pD, unit);
//getPixelSize(unit, pW, pH);
nSDpix = nSD/pW; 
nShiftThreshold=nSDpix*2;
if(bShowDetection)
{
	run("Remove Overlay");
}
//expand the image
//get only channel we need
run("Select All");
run("Duplicate...", "title=alignChannel duplicate channels="+toString(nChAlign));
pixExp = Math.round(0.5*(nDiamMax+6*nSD)/pW)+4;
run("Canvas Size...", "width="+toString(widthOrig+2*pixExp)+" height="+toString(heightOrig+2*pixExp)+" position=Center zero");
origExpID = getImageID();

//make a stack of circles with the first image empty
//count slices

//size of the template in XY
tempSize = (nDiamMax+6*nSD)/pW;
nCenterShift = Math.round(0.5*tempSize);
nDiamTable = makeTemplateCircles(bitD, tempSize, tempSize, nSD,nDiamMin, nDiamMax, pW);
templateID = getImageID();
nTemplateSlN = nDiamTable.length+1;


nTotROIS = roiManager("count");
nRoiLocated = 0;
for(nRoiIndex = 0; nRoiIndex<nTotROIS;nRoiIndex++)
{
	nTimeTic = getTime();
	selectImage(origID);
	roiManager("Select", nRoiIndex);
	sRoiName = RoiManager.getName(nRoiIndex);
	print("working on ROI "+sRoiName +" ("+toString(nRoiIndex+1)+"/"+toString(nTotROIS)+")");
	Stack.getPosition(nFirstCh,nFirstSlice,nFirstFrame);
	getSelectionBounds(sel_x, sel_y, sel_width, sel_height);

	nCenterXini = Math.round(sel_x+0.5*sel_width);
	nCenterYini = Math.round(sel_y+0.5*sel_height);
	nCenterX = nCenterXini;
	nCenterY = nCenterYini;
	nCurrSlice = nFirstSlice;
	globX = newArray(slices);
	globY = newArray(slices);
	globDiam  = newArray(slices);
	globCCMax = newArray(slices);
	nBeginSlice = 1;
	bFoundSpan = true;
	while(nCurrSlice>0)
	{
		if(findSlicePosition(globCCMax,globX,globY,globDiam,nCurrSlice,nCenterX, nCenterY)>0)
		{
			nCenterX = globX[nCurrSlice-1];
			nCenterY = globY[nCurrSlice-1];
			nCurrSlice--;
		}
		else 
		{
			if(nCurrSlice == nFirstSlice)
			{
				bFoundSpan = false;
			}
			nBeginSlice = nCurrSlice+1;
			nCurrSlice = -1;
		}
	}
	nEndSlice = slices;
	if(nFirstSlice!=slices && bFoundSpan)
	{
		nCurrSlice = nFirstSlice+1;
	    nCenterX = nCenterXini;
	    nCenterY = nCenterYini;
		while(nCurrSlice<=slices)
		{
			if(findSlicePosition(globCCMax,globX,globY,globDiam,nCurrSlice,nCenterX, nCenterY)>0)
			{
				nCenterX = globX[nCurrSlice-1];
				nCenterY = globY[nCurrSlice-1];

				nCurrSlice++;	
			}
			else 
			{
			  nEndSlice = nCurrSlice-1;
			  nCurrSlice = slices+1;
			}
	
		}
	}
	if(bFoundSpan)
	{
		nRoiLocated++;
		print("found z-range "+nBeginSlice+" to "+nEndSlice);
	
		run("Clear Results");	
		for(i=nBeginSlice;i<=nEndSlice;i++)
		{
			setResult("finCCMax", i-nBeginSlice, globCCMax[i-1]);
			setResult("finDiam", i-nBeginSlice, globDiam[i-1]);
			setResult("finX", i-nBeginSlice, globX[i-1]);
			setResult("finY", i-nBeginSlice, globY[i-1]);
			setResult("finZ", i-nBeginSlice, i);
		}
		//saving results
		saveAs("Results",  filesAlignedDir+sRoiName+".csv");
		
		
		
		if(bExtractStack || bGenXYXZ)
		{
			
			//found coordinates, let's extract image data
			nOutputHalfSize = Math.round(0.5*((1.5*nDiamMax+6*nSD)/pW));
			newImage("HyperStack", toString(bitD)+"-bit composite-mode", nOutputHalfSize*2+1, nOutputHalfSize*2+1, channels, nEndSlice-nBeginSlice+1, frames);
			setVoxelSize(pW, pH, pD, unit);
			outputID = getImageID();
			for(nCh=1; nCh<=channels; nCh++)
			{
				selectImage(outputID);
				Stack.setChannel(nCh);
				selectImage(origID);
				Stack.setChannel(nCh);
				for(nSl=nBeginSlice;nSl<=nEndSlice;nSl++)
				{
					selectImage(origID);
					Stack.setSlice(nSl);
					makeRectangle(globX[nSl-1]-nOutputHalfSize, globY[nSl-1]-nOutputHalfSize, nOutputHalfSize*2+1, nOutputHalfSize*2+1);	
					run("Copy");
					selectImage(outputID);
					Stack.setSlice(nSl-nBeginSlice+1);
					run("Select All");
				    run("Paste");
				}
			
			}
			if(bExtractStack)
			{
				print("exporting detected stack");
				saveAs("Tiff", filesAlignedDir+sRoiName+".tif");
			}
			if(bGenXYXZ)
			{
				print("generating XY XZ projections");
				saveXYXZproj(filesAlignedXYDir, filesAlignedXZDir, nChAlign, sRoiName);
			}
			close();
			
	
		}
		if(bShowDetection)
		{
			print("adding detection to the overlay");
			selectImage(origID);
			Stack.setChannel(nChAlign);
			for(nSl=nBeginSlice;nSl<=nEndSlice;nSl++)
			{
				Stack.setSlice(nSl);
				diamPx = globDiam[nSl-1]/pW;
				makeOval(globX[nSl-1]+1-0.5*diamPx, globY[nSl-1]+1-0.5*diamPx, diamPx, diamPx);
				run("Add Selection...");
			}
		}
	}
	else 
	{
		print("Failed to locate BB for this ROI");
	}
	nTimeToc = getTime();
	print("time per ROI: "+toString((nTimeToc-nTimeTic)/1000)+" s");
	selectWindow("Log");
	saveAs("Text", logDir+sTimeStamp+"_log_s1_extract_BB_macro.txt");

}
selectImage(templateID);
close();
selectImage(origExpID);
close();
print("all ROIs done.");
print("detected BB for "+toString(nRoiLocated) +" out of "+toString(nTotROIS)+" ROIs.");
selectWindow("Log");
saveAs("Text", logDir+sTimeStamp+"_log_s1_extract_BB_macro.txt");

setBatchMode(false);

function saveXYXZproj(filesAlignedXYDir, filesAlignedXZDir, nChAlign, sRoiName)
{
		finID=getImageID();
		run("Z Project...", "projection=[Max Intensity]");
		run("Make Composite");
		Stack.setChannel(nChAlign);
		resetMinAndMax();
		saveAs("Tiff", filesAlignedXYDir+"MAX_XY_"+sRoiName+".tif");
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
		saveAs("Tiff", filesAlignedXZDir+"MAX_XZ_"+sRoiName+".tif");
		close();
		selectImage(finID);
}



function findSlicePosition(globCCMax,globX,globY,globDiam,nCurrSlice, nCenterX, nCenterY)
{

	selectImage(origExpID);
	setSlice(nCurrSlice);
	makeRectangle(pixExp-nCenterShift+nCenterX, pixExp-nCenterShift+nCenterY, tempSize, tempSize);
	run("Copy");
	selectImage(templateID);
	setSlice(1);
	run("Select All");
	run("Paste");
	run("Clear Results");
	run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)]");
	//close CC stack
	close();
	globX[nCurrSlice-1] = getResult("Xmax_(px)", 1);
	globX[nCurrSlice-1] = getResult("Ymax_(px)", 1);
	globDiam[nCurrSlice-1] = nDiamTable[0];
	globCCMax[nCurrSlice-1] =getResult("CC_max", 1);
	
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

	nShiftOk = 1;
	if(globCCMax[nCurrSlice-1]<0 || globCCMax[nCurrSlice-1]>1.0)
	{
		nShiftOk = 0;
	}
	else 
	{
		disp = sqrt(globX[nCurrSlice-1]*globX[nCurrSlice-1]+globY[nCurrSlice-1]*globY[nCurrSlice-1]);
		if(disp>nShiftThreshold)
		{
			nShiftOk = 0;
		}
	}
	if(nShiftOk == 1)
	{
		nCenterX += globX[nCurrSlice-1];
		nCenterY += globY[nCurrSlice-1];
		globX[nCurrSlice-1] = nCenterX;
		globY[nCurrSlice-1] = nCenterY;
		
		return 1;
	}
	else 
	{
		return -1;
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
	newImage("circletemplate", toString(bitD)+"-bit black", tempW, tempH, nTemplateSlN);
	templateID = getImageID();
	nDiamTable = newArray(nTemplateSlN-1);
	nTempSlice = 2;
	nCenterShiftX = Math.round(0.5*tempW);
	nCenterShiftY = Math.round(0.5*tempH);
	for (nDiameter = nDiamMin; nDiameter<=nDiamMax; nDiameter+=nDiamStep) 
	{
		selectImage(templateID);
		setSlice(nTempSlice);
		nRadPx = Math.round(0.5*nDiameter/pW);
		//circle should be fully visible
		//so we can crop CC/search
		//nBorderPix = Math.round((0.5*nDiameter+2*nSD)/pW);
		
		//make an image of a circle
		makeOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		run("Draw", "slice");
		run("Select All");
		//blur
		run("Gaussian Blur...", "sigma="+toString(nSDpix));
		nDiamTable[nTempSlice-2]=nDiameter;
		nTempSlice++;
	}
	return nDiamTable;
}

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}