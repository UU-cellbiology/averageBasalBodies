//called from another macro
values = getArgument();
if(values.length()>0)
{
	params = split(values, "");
	nChAlign=parseInt(params[0]);
	nSD=parseFloat(params[1]);
	nDiamMax=parseFloat(params[2]);
	nDiamStep=parseFloat(params[3]);
	bDiamResults = true;
	if(parseFloat(params[4])==0)
	{
		bDiamResults=false;
	}
	bShowDetection=false;
}
else
{
	Dialog.create("Rotation find parameters:");
	Dialog.addNumber("Channel for alignment ",4);
	Dialog.addNumber("SD of the ring (um)",0.18);
	Dialog.addNumber("Maximum diameter (um)",2.44);
	Dialog.addNumber("Diameter step (um)",0.1);
	Dialog.addCheckbox("Get diameter from results? ", false);
	Dialog.addCheckbox("Show detection (in overlay)? ", false);
	Dialog.show();
	nChAlign=Dialog.getNumber();
	nSD=Dialog.getNumber();
	nDiamMax=Dialog.getNumber();
	nDiamStep=Dialog.getNumber();
	bDiamResults=Dialog.getCheckbox();
	bShowDetection=Dialog.getCheckbox();
}

nDiamMin =2*nSD;

//preparations
run("Set Measurements...", "min redirect=None decimal=5");
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
dispMax = 0.5*nDiamMax/pW;
run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] limit max="+toString(dispMax)+" max_0="+toString(dispMax));
close();
dLen = 1000000;
circlX = 0;
circlY = 0;
circlDiam = 0;
for (i = 0; i < nTemplateSlN-1; i++) 
{
	currShiftX=getResult("Xmax_(px)", i+1);
	currShiftY=getResult("Ymax_(px)", i+1);
	dLenCurr = Math.sqrt(Math.pow(currShiftX,2)+Math.pow(currShiftY,2));
	if(dLenCurr<dLen)
	{
		dLen = dLenCurr;
		circlX = currShiftX;
		circlY = currShiftY;
		circlDiam = nDiamTable[i];
		print(circlDiam);
		
	}
}
circlX+=Math.round(0.5*width); //nCenterShiftX
circlY+=Math.round(0.5*height); //nCenterShiftY

print("center X = " + circlX);
print("center Y = " + circlY);
print("diam " +circlDiam);
selectImage(templateID);
close();


nAngleTable = makeTemplateBB(bitD, width, height, circlX, circlY, nSD, circlDiam, 2, pW);
nAngleTotSlN = nAngleTable.length;
templateID = getImageID();
selectImage(maxPrID);
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
maxAnglCC = -10000;
rotAngle = 0;
maxInd = 0;
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
print("final angle " +rotAngle);
selectImage(ccID);
close();
selectImage(templateID);
setSlice(maxInd+2);
run("Enhance Contrast", "saturated=0.35");

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

function makeTemplateBB(bitD, tempW, tempH, nCenterShiftX, nCenterShiftY, nSD, nDiam, nAngleStep, pW)
{
	nSDpix = nSD/pW;
	
	
	//count slices
	nTemplateSlN = 1;
	for (nAngle = 0; nAngle<360; nAngle+=nAngleStep)
	{
		nTemplateSlN++;
	}
	nAngleTable = newArray(nTemplateSlN-1);
	newImage("BB_template", toString(bitD)+"-bit black", tempW, tempH, nTemplateSlN);
	templateID = getImageID();
	nTempSlice = 2;
	setLineWidth(0);
	for (nAngle = 0; nAngle<360; nAngle+=nAngleStep)
	{
		selectImage(templateID);
		setSlice(nTempSlice);
		nRadPx = Math.round(0.5*nDiam/pW);
		//circle should be fully visible
		//make an image of a circle
		makeOval(nCenterShiftX-nRadPx, nCenterShiftY-nRadPx, 2*nRadPx, 2*nRadPx);
		Roi.setStrokeWidth(1);
		run("Draw", "slice");
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
			nRadBB = Math.round(0.5*nDiam/pW)+1.3*nSDpix;
			nRadBB *=-1;
			newX1 = -nRadBB*sin(nAngle*PI/180);
			newY1 = nRadBB*cos(nAngle*PI/180);
			
			nRadOut = Math.round(0.5*nDiam/pW)+1.5*nSDpix+nDiam*0.3/pW;
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
