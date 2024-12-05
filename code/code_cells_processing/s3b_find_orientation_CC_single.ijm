//called from another macro
values = getArgument();

nVersion = "20240405";

Stack.getDimensions(width, height, channels, slices, frames);
if(values.length()>0)
{
	params = split(values, "");
	nChAlign=parseInt(params[0]);
	nSD=parseFloat(params[1]);
	nDiamMax=parseFloat(params[2]);
	nDiamStep=parseFloat(params[3]);
	bDiamResults = true;
	if(parseFloat(params[4])<1)
	{
		bDiamResults=false;
	}
	bShowDetection=true;
	if(parseFloat(params[5])<1)
	{
		bShowDetection=false;
	}
}
else
{
	Dialog.create("Find BB orientation parameters:");
	Dialog.addNumber("Reference channel",channels);
	Dialog.addNumber("SD of the ring (um)",0.18);
	Dialog.addNumber("Maximum diameter (um)",2.44);
	Dialog.addNumber("Diameter step (um)",0.1);
	Dialog.addCheckbox("Get diameter from results? ", false);
	Dialog.addCheckbox("Show detection? ", false);
	Dialog.show();
	nChAlign=Dialog.getNumber();
	nSD=Dialog.getNumber();
	nDiamMax=Dialog.getNumber();
	nDiamStep=Dialog.getNumber();
	bDiamResults=Dialog.getCheckbox();
	bShowDetection=Dialog.getCheckbox();
}

nDiamMin =2*nSD;
nAngleStep=1;
nAngleRange = 380;

//preparations
run("Set Measurements...", "mean min redirect=None decimal=5");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
run("Select All");

//get image parameters
origTitle=getTitle();
bitD = bitDepth();
origID = getImageID();
Stack.getDimensions(width, height, channels, slices, frames);
getVoxelSize(unit, pW, pH, pD);

nSDpix = nSD/pW;

//get max projection of the alignment channel
run("Z Project...", "projection=[Max Intensity]");
tempID = getImageID();
run("Duplicate...", "duplicate channels="+toString(nChAlign));
run("Enhance Contrast", "saturated=0.35");

maxPrID = getImageID();
selectImage(tempID);
close();
selectImage(maxPrID);
run("Tubeness", "sigma="+toString(nSD)+" use");
rename("tubeness");
tubID = getImageID();
selectImage(maxPrID);

//read diameter from results
if(bDiamResults)
{
	circlDiam = -100;
	
	for (i = 0; i < nResults(); i++) 
	{
   		nCurDiam = getResult("finDiam", i);
   		if(nCurDiam>circlDiam)
   		{
   			circlDiam = nCurDiam;
   		}
	}
	//make sure we do not detect diameter again
	if(circlDiam>0)
	{
		nDiamMin=circlDiam;
		nDiamMax=circlDiam+nDiamStep*0.1;
	}
}
//find the diameter and position of the center
//from template

nDiamTable = makeTemplateCircles(bitD, width, height, nSD,nDiamMin, nDiamMax, pW);
templateID = getImageID();
nTemplateSlN = nDiamTable.length+1;
selectImage(maxPrID);
run("Select All");
run("Copy");
selectImage(templateID);
setSlice(1);
run("Paste");
run("Clear Results");
dispMax = 0.3*nDiamMax/pW;
run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] limit max="+toString(dispMax)+" max_0="+toString(dispMax));
close();

circlX = 0;
circlY = 0;
circlDiam = 0;
ccMAX = -10000;
for (i = 0; i < nTemplateSlN-1; i++) 
{
	currShiftX=getResult("Xmax_(px)", i+1);
	currShiftY=getResult("Ymax_(px)", i+1);
	ccCurr = getResult("CC_max", i+1);
	if(ccMAX<ccCurr)
	{
		ccMAX = ccCurr;
		circlX = currShiftX;
		circlY = currShiftY;
		circlDiam = nDiamTable[i];
		//print("Detected diameter = " + toString(circlDiam));
		
	}
}

circlX+=Math.round(0.5*width); //nCenterShiftX
circlY+=Math.round(0.5*height); //nCenterShiftY

print("center X = " + circlX);
print("center Y = " + circlY);
print("diam " +circlDiam);
selectImage(templateID);
close();


nAngleTable = makeTemplateBB(bitD, width, height, circlX, circlY, nSD, circlDiam, nAngleStep, pW);

nAngleTotSlN = nAngleTable.length;
templateID = getImageID();
//selectImage(maxPrID);
selectImage(tubID);
run("Select All");
run("Copy");
selectImage(templateID);
setSlice(1);
run("Paste");
run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] max=0 max_0=0");
ccID = getImageID();
cccX = 0;
cccY = 0;
toUnscaled(cccX, cccY);
makeRectangle(cccX, cccY, 1, 1);

run("Plot Z-axis Profile");
Plot.getValues(xpoints, anglCC);
close();
selectImage(ccID);
close();
selectImage(maxPrID);
modeInt = getValue("Mode");
//find all maxima
minCC=1000;
maxCC=-1000;
maxInd = 0;
for(i=1; i<anglCC.length;i++)
{
	if(anglCC[i]<minCC)
		minCC=anglCC[i];
	if(anglCC[i]>maxCC)
	{
		maxCC = anglCC[i];
		maxInd = i;
	}
}
rotAngle  = nAngleTable[maxInd];
halfCC = 0.25*(minCC+maxCC);
maxLocs= Array.findMaxima(anglCC, 0.002, 1);
//print(maxLocs.length);
bIsBad = true;
for(i=0; i<maxLocs.length && bIsBad; i++)
{
	if(anglCC[maxLocs[i]]>halfCC)
	{
		//print(nAngleTable[maxLocs[i]-1]);
		// isGoodAngle(maxLocs[i], circlX, circlY, nSD, circlDiam,  pW, modeInt);
		if(	isGoodAngle(nAngleTable[maxLocs[i]-1], circlX, circlY, nSD, circlDiam,  pW, modeInt))
		{
			bIsBad = false;
			rotAngle = nAngleTable[maxLocs[i]-1];
			maxInd = maxLocs[i]-1;
		}
	}
}

/*
maxAnglCC = -10000;
rotAngle = 0;
maxInd = 0;maxLocs[i]
for (i = 1; i < anglCC.length; i++) 
{
 	if(anglCC[i]>maxAnglCC)
 	{
 		maxAnglCC = anglCC[i];
 		maxInd = i-1;
 		rotAngle = nAngleTable[i-1];
 	}
}
rotAngle = nAngleTable[maxInd];
*/
print("final angle " +rotAngle);
selectImage(templateID);
if(bShowDetection)
{
	setSlice(maxInd+2);
	run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", "title=detectedSlice");
	selectImage(tubID);
	selectImage(maxPrID);
	run("32-bit");
	rename("maxpr");
	run("Merge Channels...", "c5=tubeness c6=detectedSlice c7=maxpr create ignore");
	rename("rot_detected");
	selectImage(templateID);
	//rename("MAX_"+origTitle+"_detected");
}
else 
{
	selectImage(tubID);
	close();
	selectImage(maxPrID);
	close();
	selectImage(templateID);
}
close();

selectImage(origID);

//adjust canvas so that rotation center is in the middle
pxLeft = circlX;
pxRight = width-circlX-1;
maxW = maxOf(pxLeft, pxRight);

pxTop = circlY;
pxBottom = height-circlY-1;
maxH = maxOf(pxTop, pxBottom);

//expand right
run("Canvas Size...", "width="+toString(circlX+maxW+1)+" height="+toString(circlY+maxH+1)+" position=Top-Left zero");
Stack.getDimensions(width, height, channels, slices, frames);
//expand left
run("Canvas Size...", "width="+toString(width+(maxW-pxLeft))+" height="+toString(height+(maxH-pxTop))+" position=Bottom-Right zero");

run("Rotate... ", "angle="+toString((-1)*rotAngle)+" grid=1 interpolation=Bicubic fill enlarge stack");
run("Enhance Contrast", "saturated=0.35");

function makeTemplateCircles(bitD, tempW, tempH, nSD,nDiamMin, nDiamMax, pW)
{
	//make a stack of circles with the first image empty
	//count slices
	setLineWidth(1);
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
		setLineWidth(1);
		drawOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		//makeOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		//run("Draw", "slice");
		run("Select All");
		//blur
		run("Gaussian Blur...", "sigma="+toString(nSDpix));
		nDiamTable[nTempSlice-2]=nDiameter;
		nTempSlice++;
	}
	return nDiamTable;
}

function makeTemplateBB(bitD, tempW, tempH, nCenterShiftX, nCenterShiftY, nSD, nDiam, nAngleStep, pW)
{
	nSDpix = nSD/pW;
	
	
	//count slices
	nTemplateSlN = 1;
	for (nAngle = 0; nAngle<nAngleRange; nAngle+=nAngleStep)
	{
		nTemplateSlN++;
	}
	nAngleTable = newArray(nTemplateSlN-1);
	//newImage("BB_template", toString(bitD)+"-bit black", tempW, tempH, nTemplateSlN);
	newImage("BB_template", "32-bit black", tempW, tempH, nTemplateSlN);
	templateID = getImageID();
	nTempSlice = 2;
	setLineWidth(0);
	for (nAngle = 0; nAngle<nAngleRange; nAngle+=nAngleStep)
	{
		selectImage(templateID);
		setSlice(nTempSlice);
		nRadPx = Math.round(0.5*nDiam/pW);
		//circle should be fully visible
		//make an image of a circle
		setLineWidth(1);
		//drawOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		//makeOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		//Roi.setStrokeWidth(1);
		//run("Draw", "slice");
		/* triangle try)
		dX =  1.5*nSDpix;
		for(dXshift=-dX;dXshift<dX*1.5;dXshift+=2*dX)
		{
			nRadBB = Math.round(0.5*nDiam/pW)+1.0*nSDpix;
			nRadBB *=-1;
			newX1 = dXshift*cos(nAngle*PI/180) - nRadBB*sin(nAngle*PI/180);
			newY1 = dXshift*sin(nAngle*PI/180)+nRadBB*cos(nAngle*PI/180);
			
			nRadOut = Math.round(0.5*nDiam/pW)+1.5*nSDpix+nDiam*0.4/pW;
			nRadOut *=-1;
			newX2 = (-1)*nRadOut*sin(nAngle*PI/180);
			newY2 = nRadOut*cos(nAngle*PI/180);
			makeLine(nCenterShiftX+newX1, nCenterShiftY+newY1, nCenterShiftX+newX2, nCenterShiftY+newY2);
			Roi.setStrokeWidth(1);
			run("Draw", "slice");
		
		}
		*/
			//single line	
			nRadBB = Math.round(0.5*nDiam/pW)+2.0*nSDpix;
			nRadBB *=-1;
			newX1 = -nRadBB*sin(nAngle*PI/180);
			newY1 = nRadBB*cos(nAngle*PI/180);
			
			nRadOut = Math.round(0.5*nDiam/pW)+3.0*nSDpix+nDiam*0.5/pW;
			nRadOut *=-1;
			newX2 = (-1)*nRadOut*sin(nAngle*PI/180);
			newY2 = nRadOut*cos(nAngle*PI/180);
			makeLine(nCenterShiftX+newX1, nCenterShiftY+newY1, nCenterShiftX+newX2, nCenterShiftY+newY2);
			Roi.setStrokeWidth(1);
			run("Draw", "slice");
		run("Select All");
		//blur
		run("Gaussian Blur...", "sigma="+toString(nSDpix));
		nAngleTable[nTempSlice-2]=nAngle;
		nTempSlice++;
	}
	return nAngleTable;

}

function isGoodAngle(nAngle, nCenterShiftX, nCenterShiftY, nSD, nDiam,  pW, nMode)
{
			nSDpix = nSD/pW;
			nRadBB = Math.round(0.5*nDiam/pW)+1.3*nSDpix;
			nRadBB *=-1;
			newX1 = -nRadBB*sin(nAngle*PI/180);
			newY1 = nRadBB*cos(nAngle*PI/180);
			
			nRadOut = Math.round(0.5*nDiam/pW)+1.5*nSDpix+nDiam*0.5/pW;
			nRadOut *=-1;
			newX2 = (-1)*nRadOut*sin(nAngle*PI/180);
			newY2 = nRadOut*cos(nAngle*PI/180);
			
			nRadOut2 = nRadOut+nRadBB;//Math.round(0.5*nDiam/pW)+1.5*nSDpix+nDiam*0.5/pW;
			//nRad2 *=-1;
			newX3 = (-1)*nRadOut2*sin(nAngle*PI/180);
			newY3 = nRadOut2*cos(nAngle*PI/180);
			makeLine(nCenterShiftX, nCenterShiftY,nCenterShiftX+newX1, nCenterShiftY+newY1,7);
			//print(getValue("Mean")-nMode);
			nIn = getValue("Mean")-nMode;
			
			makeLine(nCenterShiftX+newX2, nCenterShiftY+newY2, nCenterShiftX+newX3, nCenterShiftY+newY3, 7);
			//print(getValue("Mean")-nMode);
			nOut= getValue("Mean")-nMode;
			if(nOut>0.5*nIn)
			{
				//print("false");
				return false;
				
			}
			else 
			{
				//print("true");
				return true;
				
			}

}
