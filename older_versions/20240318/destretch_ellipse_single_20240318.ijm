//called from another macro
values = getArgument();
if(values.length()>0)
{
	params = split(values, "");
	nChAlign=parseInt(params[0]);
	nLineWidth=parseInt(params[1]);
	nSD=parseFloat(params[2]);
	nDiamMax=parseFloat(params[3]);
	nDiamStep=parseFloat(params[4]);

	bDiamResults = true;
	if(parseFloat(params[5])==0)
	{
		bDiamResults=false;
	}

}
else
{

	Dialog.create("Destretch parameters:");
	Dialog.addNumber("Channel for alignment ",4);
	Dialog.addNumber("Profile line width (pix)",6);
	Dialog.addNumber("SD of the ring (um)",0.18);
	Dialog.addNumber("Maximum diameter (um)",2.44);
	Dialog.addNumber("Diameter step (um)",0.1);
	Dialog.addCheckbox("Get diameter from results? ", false);
	Dialog.show();
	nChAlign = Dialog.getNumber();
	nLineWidth = Dialog.getNumber();
	nSD = Dialog.getNumber();
	nDiamMax = Dialog.getNumber();
	nDiamStep = Dialog.getNumber();
	bDiamResults = Dialog.getCheckbox();
}
nDiamMin =3*nSD;
//image dimensions, etc
getVoxelSize(pW, pH, depth, unit);
Stack.getDimensions(width, height, channels, slices, frames);
nSDpix = nSD/pW; 
origID = getImageID();
origTitle = getTitle();
bitD = bitDepth();
if(bitD>16)
{
	exit("only 8- and 16-bit images are supported.");
}
//brightest slice
run("Duplicate...", "duplicate channels="+toString(nChAlign));
run("Grays");
chnID=getImageID();
nDiamTable = newArray(2);
if(bDiamResults)
{
	nDiamTable = newArray(nResults);
	for (i = 0; i < nResults(); i++) 
	{
	    nDiamTable[i] = getResult("finDiam", i);
	}
}
maxIntSlice = getMaxZprofSD();
//maxIntSlice=52;
print("MaxSD slice="+toString(maxIntSlice));
setSlice(maxIntSlice);
if(bDiamResults)
{
	print("getting diameter from results:");
	nDiam = nDiamTable[maxIntSlice-1];
	print("diameter=" + toString(nDiam));
}
else 
{
	print("estimating diameter...");
	nDiamTable = makeTemplateCircles(bitD, width, height, nSD, nDiamMin, nDiamMax, pW);
	templateID = getImageID();
	nTemplateSlN = nDiamTable.length+1;
	selectImage(chnID);
	run("Select All");
	run("Copy");
	selectImage(templateID);
	setSlice(1);
	run("Paste");
	run("Clear Results");
	run("2D cross-correlation", "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] limit max="+toString(width*0.25)+" max_0="+toString(height*0.25));
	currShiftX = newArray(nTemplateSlN-1);
	currShiftY = newArray(nTemplateSlN-1);
	for (i = 0; i < nTemplateSlN-1; i++) 
	{
		currShiftX[i]=getResult("Xmax_(px)", i+1);
		currShiftY[i]=getResult("Ymax_(px)", i+1);
	}
	ccID = getImageID();
	globCCMax = -100.0;
	nCentX =  Math.round(0.5*width);
	nCentY = Math.round(0.5*height);
	run("Clear Results");	
	for (i = 2; i <= nTemplateSlN; i++) 
	{
		    setSlice(i);
		    //makeRectangle(width*fraction, height*fraction, width*(1.0-2.0*fraction), height*(1.0-2.0*fraction));
		    //makeRectangle(nBorderPix,nBorderPix, width-2*nBorderPix, height-2*nBorderPix);
		    run("Measure");
		  
		    currMaxCC=getResult("Max", i-2);
		    //print("CC "+currMaxCC);
		    if(currMaxCC>globCCMax)
		    {
		    	globCCMax = currMaxCC;
		    	nCentX = Math.round(0.5*width)+ currShiftX[i-2];
		    	nCentY = Math.round(0.5*height)+ currShiftY[i-2];
		    	nDiam = nDiamTable[i-2];
		    }
	    
	}
	close();
	selectImage(templateID);
	close();
	print("Diameter = " +toString(nDiam));
	print("center x: "+toString(nCentX));
	print("center y: "+toString(nCentY));
	
	//adjust sizes
	//adjust canvas so that rotation center is in the middle
	pxLeft = nCentX;
	pxRight = width-nCentX-1;
	maxW = maxOf(pxLeft, pxRight);
	
	pxTop = nCentY;
	pxBottom = height-nCentY-1;
	maxH = maxOf(pxTop, pxBottom);
	//expand right
	run("Canvas Size...", "width="+toString(nCentX+maxW+1)+" height="+toString(nCentY+maxH+1)+" position=Top-Left zero");
	Stack.getDimensions(width, height, channels, slices, frames);
	//expand left
	run("Canvas Size...", "width="+toString(width+(maxW-pxLeft))+" height="+toString(height+(maxH-pxTop))+" position=Bottom-Right zero");
	selectImage(origID);
	Stack.getDimensions(width, height, channels, slices, frames);
	//expand right
	run("Canvas Size...", "width="+toString(nCentX+maxW+1)+" height="+toString(nCentY+maxH+1)+" position=Top-Left zero");
	Stack.getDimensions(width, height, channels, slices, frames);
	//expand left
	run("Canvas Size...", "width="+toString(width+(maxW-pxLeft))+" height="+toString(height+(maxH-pxTop))+" position=Bottom-Right zero");
	Stack.getDimensions(width, height, channels, slices, frames);
}
selectImage(chnID);
run("Z Project...", "start="+toString(maxIntSlice-1)+" stop="+toString(maxIntSlice+1)+" projection=[Max Intensity]");
analyzeSliceID=getImageID();
selectImage(chnID);
close();
selectImage(analyzeSliceID);

//center of the image coordinates
nCx = Math.round(0.5*width);
nCy = Math.round(0.5*height);

nMaxAngle = -1;
nMaxLen=-1;

run("Clear Results");
nResCount = 0;
setBatchMode(true);
nAverL=0;
nPolyX=newArray(180*2);
nPolyY=newArray(180*2);
for(nAngle=0;nAngle<180;nAngle++)
{
	//nAngle=25;
	nHalfSpan = 0.5*(nDiam+6*nSD)/pW;
	nPosXY=newArray(4);
	dl=getEdgePositions(nAngle,nPosXY,nHalfSpan,nCx,nCy, nLineWidth);
	//makePoint(nPosXY[0], nPosXY[1], "small yellow hybrid");
	//roiManager("Add");
	//makePoint(nPosXY[2], nPosXY[3], "small yellow hybrid");
	//roiManager("Add");
	nPolyX[nAngle]=nPosXY[0];
	nPolyY[nAngle]=nPosXY[1];
	nPolyX[180+nAngle]=nPosXY[2];
	nPolyY[180+nAngle]=nPosXY[3];
	if(dl>nMaxLen)
	{
		nMaxLen=dl;
		nMaxAngle=nAngle;
	}
	setResult("Diameter_px", nResCount,dl );
	setResult("Angle_degrees", nResCount,nAngle );
	nAverL+=dl;
	nResCount++;
}

print("angle rotate = "+toString(nMaxAngle));
print("maxlen "+toString(nMaxLen));
nAverL = nAverL/nResCount;
print("averLen "+toString(nAverL));
//perpendicular
dlPerp = getEdgePositions(nMaxAngle+90,nPosXY,nHalfSpan,nCx,nCy, nLineWidth);
close();
setBatchMode(false);
run("ROI Manager...");
roiManager("reset");
makeSelection("polygon", nPolyX, nPolyY);
roiManager("Add");
run("Select All");
print("perpLen "+toString(dlPerp));
selectImage(origID);
run("Duplicate...", "title=["+origTitle+"_destretch] duplicate");
run("Rotate... ", "angle="+toString(nMaxAngle)+" grid=1 interpolation=Bicubic enlarge stack");
nScaleY = nAverL/nMaxLen;
nScaleX = nAverL/dlPerp;
print("factor X ",toString(nScaleX));
print("factor Y ",toString(nScaleY));

tempID=getImageID();
//run("Scale...", "x="+toString(nScaleX)+" y="+toString(nScaleY)+" z=1.0 interpolation=Bicubic average process");
run("Scale...", "x="+toString(nScaleX)+" y="+toString(nScaleY)+" z=1.0 interpolation=Bicubic average process create");

//rotate back
//recalculate rotation angle
//let's take a vector (0,1)
xnew = (-1)*sin(nMaxAngle*PI/180);
ynew = cos(nMaxAngle*PI/180);
//print(180*Math.atan2(ynew, xnew)/PI-90);
xnew*=nScaleX;
ynew*=nScaleY;
nBackRotAngle = 180*Math.atan2(ynew, xnew)/PI-90;
//print(nBackRotAngle);

//run("Rotate... ", "angle="+toString((-1)*nMaxAngle)+" grid=1 interpolation=Bicubic enlarge stack");
run("Rotate... ", "angle="+toString((-1)*nBackRotAngle)+" grid=1 interpolation=Bicubic enlarge stack");

run("Canvas Size...", "width="+toString(width)+" height="+toString(height)+" position=Center zero");
rename(origTitle+"_destretch");
setVoxelSize(pW, pH, depth, unit);
run("Select All");
selectImage(tempID);
close();

function getEdgePositions(nAngle,nPosXY,nHalfSpan,nCx,nCy, nLineWidth)
{
	cosA=cos(nAngle*PI/180);
	sinA=sin(nAngle*PI/180);
	makeLine(nCx+nHalfSpan*sinA, nCy+nHalfSpan*cosA, nCx-nHalfSpan*sinA, nCy-nHalfSpan*cosA,nLineWidth);
	run("Plot Profile");
	Plot.getValues(xpoints, ypoints);
	close();
	nHalfW = Math.round(0.5*xpoints.length);
	fitX=newArray(nHalfW);
	fitY=newArray(nHalfW);
	for (i = 0; i < nHalfW; i++) 
	{
		fitX[i]=xpoints[i];
		fitY[i]=ypoints[i];
	}
	Fit.doFit("Gaussian", fitX, fitY);
	//print(Fit.p(2));
	lenPx=Fit.p(2)/pW;
	len1=lenPx;
	nPosXY[0]=nCx+sinA*(nHalfSpan-lenPx);
	nPosXY[1]=nCy+cosA*(nHalfSpan-lenPx);
	//makePoint(nCx+nHalfSpan*sinA-sinA*lenPx, nCy+nHalfSpan*cosA-cosA*lenPx, "small yellow hybrid");
	
	//roiManager("Add");
	//second shoulder
	fitX=newArray(xpoints.length-nHalfW+1);
	fitY=newArray(xpoints.length-nHalfW+1);
	for (i = nHalfW; i < xpoints.length; i++) 
	{
		fitX[i-nHalfW]=xpoints[i];
		fitY[i-nHalfW]=ypoints[i];
	}
	Fit.doFit("Gaussian", fitX, fitY);
	lenPx=Fit.p(2)/pW;
	nPosXY[2]=nCx+sinA*(nHalfSpan-lenPx);
	nPosXY[3]=nCy+cosA*(nHalfSpan-lenPx);
	//makePoint(nCx+nHalfSpan*sinA-sinA*lenPx, nCy+nHalfSpan*cosA-cosA*lenPx, "small yellow hybrid");
	//roiManager("Add");
	len2=lenPx;
	dl=len2-len1;
	return dl;
}

function getMaxZprof()
{
	run("Select All");
	run("Plot Z-axis Profile");
	Plot.getValues(xpoints, ypoints);
	close();
	maxVal = 0.0;
	maxInd=-1;
	for (i = 0; i < ypoints.length; i++) 
	{
		if(maxVal<ypoints[i])
		{
			maxVal =ypoints[i];
			maxInd=i;
		}
		
	}
	return maxInd;
}

function getMaxZprofSD()
{
	run("Set Measurements...", "standard min redirect=None decimal=5");
	run("Select All");
	nSliceN=1;
	nMaxSD = -100;
	for (i = 1; i <= nSlices; i++) 
	{
	    setSlice(i);
	   // makeOval(31, 29, 67, 69);
	    // do something here;
		//run("Measure");
		getStatistics(area, mean, min, max, currSD);
		//currSD=getResult("StdDev", i-1);
		if(currSD>nMaxSD)
		{
			nMaxSD=currSD;
			nSliceN=i;
		}
	}
	return nSliceN;
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
