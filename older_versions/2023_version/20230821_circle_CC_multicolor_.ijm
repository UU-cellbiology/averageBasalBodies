//called from another macro
values = getArgument();
if(values.length()>0)
{
	params = split(values, "");
	nChAlign=parseInt(params[0]);
	nScale=parseInt(params[1]);
	nSD=parseFloat(params[2]);
	nDiamMax=parseFloat(params[3]);
	nDiamStep=parseFloat(params[4]);
	bShowDetection=false;
	bShowPlots = false;
}
else
{
	Dialog.create("Align parameters:");
	Dialog.addNumber("Channel for alignment ",4);
	Dialog.addNumber("Scale factor (1=no scale) ",1);
	Dialog.addNumber("SD of the ring (um)",0.23);
	Dialog.addNumber("Maximum diameter (um)",2.44);
	Dialog.addNumber("Diameter step (um)",0.1);
	Dialog.addCheckbox("Show detection? ", false);
	Dialog.addCheckbox("Show XY shift/diameter plots? ", false);
	Dialog.show();
	nChAlign=Dialog.getNumber();
	nScale=Dialog.getNumber();
	nSD=Dialog.getNumber();
	nDiamMax=Dialog.getNumber();
	nDiamStep=Dialog.getNumber();
	
	bShowDetection=Dialog.getCheckbox();
	bShowPlots=Dialog.getCheckbox();

}
nDiamMin =2*nSD;
/*
nScale = 1;
nChAlign=4;
nSD = 0.21;
nDiamMax = 2.44;
nDiamStep = 0.1;
nDiamMin =2*nSD;
bShowPlots = false;
bShowDetection = true;
*/

//preparations
run("Set Measurements...", "min redirect=None decimal=5");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
run("Select All");

//get image parameters
origTitle=getTitle();
origNonScaled = getImageID();
if(nScale>1)
{
	run("Scale...", "x="+toString(nScale)+" y="+toString(nScale)+" z="+toString(nScale)+" interpolation=Bicubic average create");
	origTitle=origTitle+"_scaledx"+toString(nScale);
	rename(origTitle);
}
origID = getImageID();
Stack.getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pW, pH);
nSDpix = nSD/pW; 

//global optimum search variables
globCCMax= newArray(slices);
globX = newArray(slices);
globY = newArray(slices);
globDiam = newArray(slices);

// global max of CC
for (i = 0; i < slices; i++) 
{
	globCCMax[i]=-100;
}
run("Duplicate...", "title=alignChannel duplicate channels="+toString(nChAlign));
//run("Duplicate...", "title=alignChannel duplicate");
run("32-bit");
run("Grays");
alignID = getImageID();

//center of the image coordinates
nCx = Math.round(0.5*width);
nCy = Math.round(0.5*height);
for (nDiameter = nDiamMin; nDiameter<=nDiamMax; nDiameter+=nDiamStep) 
{	
	newImage("Circle", "32-bit black", width, height, 1);
	nRadPx = Math.round(0.5*nDiameter/pW);
	//circle should be fully visible
	//so we can crop CC/search
	nBorderPix = Math.round((0.5*nDiameter+2*nSD)/pW);
	
	//make an image of a circle
	makeOval(nCx-nRadPx, nCy-nRadPx, 2*nRadPx, 2*nRadPx);
	run("Draw", "slice");
	run("Select All");
	//blur
	run("Gaussian Blur...", "sigma="+toString(nSDpix));
	circleID=getImageID();
	run("Concatenate...", "keep image1=Circle image2=alignChannel");
	stackID=getImageID();
	run("Clear Results");
	runstr= "calculate=[current image in stack and all others] for=1 calculation=[FFT cross-correlation (fast)] ";
	//runstr=runstr+"limit max="+toString(Math.round(0.5*width*(1.0-2.0*fraction)))+" max_0="+toString(Math.round(0.5*height*(1.0-2.0*fraction)));
	runstr=runstr+"limit max="+toString(Math.round(0.5*width-nBorderPix))+" max_0="+toString(Math.round(0.5*height-nBorderPix));
	
	run("2D cross-correlation", runstr);
	ccID = getImageID();
	
	//get CC center
	currShiftX=newArray(slices);
	currShiftY=newArray(slices);
	
	for (nSl = 1; nSl <= slices; nSl++) 
	{
		currShiftX[nSl-1] = getResult("Xmax_(px)", nSl);
		currShiftY[nSl-1] = getResult("Ymax_(px)", nSl);
		//print(currShiftX[nSl-1]);
	}
	
	selectImage(circleID);
	close();
	selectImage(stackID);
	close();
	updateCCMAX(globCCMax,globX,globY,globDiam);

}
if(bShowDetection)
{
	showMergedDetection();
}
else 
{
	close();
}

nStretchMax = newArray(3);
findLongestStretch(globX,globY,globDiam,pW, nStretchMax);
//print(nStretchMax[0]);
//print(nStretchMax[1]);
//print(nStretchMax[2]);
newLen = nStretchMax[0];
nBeg = nStretchMax[1];
nEnd = nStretchMax[2];
//final extraction
finCCMax= newArray(newLen);
finX = newArray(newLen);
finY = newArray(newLen);
finDiam = newArray(newLen);
for (i = 0; i < newLen; i++) 
{
	finCCMax[i]=globCCMax[i+nBeg-1];
	finX[i]=globX[i+nBeg-1];
	finY[i]=globY[i+nBeg-1];
	finDiam[i]=globDiam[i+nBeg-1];

}
selectImage(origID);
run("Duplicate...", "title=["+origTitle+"_crop_aligned] duplicate slices="+toString(nBeg)+"-"+toString(nEnd));
if(nScale!=1)
{
	newW=getImageID();
	selectImage(origID);
	close();
	selectImage(newW);
}

run("Clear Results");
for (i = 0; i < newLen; i++) 
{
	Stack.setSlice(i+1);
	for(c=1;c<=channels;c++)
	{
		Stack.setChannel(c);
    	run("Translate...", "x="+finX[i]+" y="+finY[i]+" interpolation=None slice");
	}
	//print(finY[i-1]);
	setResult("finCCMax", i, finCCMax[i]);
	setResult("finDiam", i, finDiam[i]);
	setResult("finX", i, finX[i]);
	setResult("finY", i, finY[i]);
	setResult("X", i, nCx-finX[i]);
	setResult("Y", i, nCy-finY[i]);
	setResult("Z", i, nBeg+i-1);
}

if(bShowPlots)
{
	slicesNArr = newArray(newLen);
	for (i = 1; i <= newLen; i++) 
	{
		slicesNArr[i-1]=i;
	}
	Plot.create("displacement in X and Y (px)", "slice position", "pixels", slicesNArr, finY)
	Plot.add( "line",slicesNArr, finX, "x");
	Plot.setLimitsToFit();
	Plot.show();
	Plot.create("diameter", "slice position", unit, slicesNArr, finDiam);
}


///////////////////////////////////////////////////////////////////////
function showMergedDetection() 
{ 
	run("Clear Results");
	newImage("Circle_map", "32-bit black", width, height, slices);
	for (i = 0; i < slices; i++) 
	{
	    
	    setResult("globCCMax", i, globCCMax[i]);
	    setResult("globDiam", i, globDiam[i]);
	    setResult("globX", i, globX[i]);
	    setResult("globY", i, globY[i]);
	    setSlice(i+1);
	    nRadPx=Math.round(0.5*globDiam[i]/pW);
	    makeOval(nCx-nRadPx-globX[i], nCy-nRadPx-globY[i], 2*nRadPx, 2*nRadPx);
		run("Draw", "slice");
	}
	run("Select All");
	run("Gaussian Blur...", "sigma="+toString(nSDpix)+" stack");
	run("Merge Channels...", "c2=Circle_map c4=alignChannel create ignore");
	rename(origTitle+"_detected");
}
function updateCCMAX(globCCMax,globX,globY,globDiam)
{
	selectImage(ccID);
	setSlice(1);
	//get CC max	
	run("Clear Results");	
	for (i = 2; i <= slices+1; i++) 
	{
		    setSlice(i);
		    //makeRectangle(width*fraction, height*fraction, width*(1.0-2.0*fraction), height*(1.0-2.0*fraction));
		    makeRectangle(nBorderPix,nBorderPix, width-2*nBorderPix, height-2*nBorderPix);
		    run("Measure");
		  
		    currMaxCC=getResult("Max", i-2);
		    if(currMaxCC>globCCMax[i-2])
		    {
		    	globCCMax[i-2]=currMaxCC;
		    	globX[i-2]=currShiftX[i-2];
		    	globY[i-2]=currShiftY[i-2];
		    	globDiam[i-2]= nDiameter;
	
		    }
	    
	}
	close();
}

function findLongestStretch(globX,globY,globDiam,pW,nStretch) 
{ 
	// function finds longest detected event where displacement is smaller than dDistMax
	totSl = globX.length;
	dispArr = newArray(totSl-1);
	for (i = 0; i < totSl-1; i++) 
	{
		dispArr[i]=Math.pow(globX[i]-globX[i+1], 2)+Math.pow(globY[i]-globY[i+1], 2);
		dispArr[i] = Math.sqrt(dispArr[i]);
	}
	//looking for stretches
	nRuns = 1;
	nBegArr=newArray(totSl);
	nEndArr=newArray(totSl);
	nLengArr = newArray(totSl);
	nBegArr[0]=1;
	nLen=1;
	for (i = 0; i < totSl-1; i++) 
	{
		//jump in displacement, new stretch
		if(dispArr[i]>(0.75*globDiam[i])/pW)
		{
			nEndArr[nRuns-1]=i+1;
			nLengArr[nRuns-1]= nLen;
			nRuns++;
			nLen=1;
			nBegArr[nRuns-1]=i+2;
		}
		else 
		{
			nLen++;
		}
	}
	//let's finish
	nEndArr[nRuns-1]=totSl;
	nLengArr[nRuns-1]= nLen;
	print("Total tracks:"+toString(nRuns));
	nLongestInd = -1;
	for (i = 1; i <=nRuns; i++) 
	{
		if(nLengArr[i-1]>nLongestInd)
		{
			nLongestInd = nLengArr[i-1];
			//nStretch[0]
			//nLenMax=nLongestInd;
			//nBeg = nBegArr[i-1];
			//nEnd = nEndArr[i-1];
			nStretch[0]=nLongestInd;
			nStretch[1] = nBegArr[i-1];
			nStretch[2] = nEndArr[i-1];
		}
		print("Stretch "+toString(i)+", "+toString(nLengArr[i-1])+" slices, from "+toString(nBegArr[i-1])+" to "+toString(nEndArr[i-1]));
	}
}
