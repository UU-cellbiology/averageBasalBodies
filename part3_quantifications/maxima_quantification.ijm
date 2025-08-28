///PARAMETERS
//total number of rows in csv
nColN = 145;

bUseRowRange = true;
nRowBeg = 1;
nRowEnd = 110;

//findng maximum tolerance in Z
dMaxToleranceZ = 100;
//findng maximum tolerance in R
dMaxToleranceR = 1;
//smoothing window (z-slices)
dSmoothWindow = 10;

if(!bUseRowRange)
{
	nRowBeg = 1;
}

input = getDirectory("Input folder with CSVs profiles");
output = getDirectory("Results output folder");
//input = "F:/PROJECTS/BasalBodiesAverage/Analysis_averages_20250415/test_in/";
//output = "F:/PROJECTS/BasalBodiesAverage/Analysis_averages_20250415/test_out/";

folderZMaxplots = output+"Zmax_plots/";
folderRMaxplots = output+"Rmax_plots/";
File.makeDirectory(folderZMaxplots);
File.makeDirectory(folderRMaxplots);

suffix = ".csv";
sTimeStamp =  getTimeStamp_sec(); 
print("\\Clear");
print("PARAMETERS:");
print("Number of columns: "+toString(nColN));
print("Use row range: "+toString(bUseRowRange));
print("First row: "+toString(nRowBeg));
print("Last row: "+toString(nRowEnd));

print("Max finding tolerance (Z): "+toString(dMaxToleranceZ));
print("Max finding tolerance (R): "+toString(dMaxToleranceR));
print("Smoothing window, points: "+toString(dSmoothWindow));
print("Input folder:" + input);
print("Output folder:" + output);
print("Analyzing FHWM...." + sTimeStamp);
list = getFileList(input);
nTotFiles = 0;
for (nFile = 0; nFile < list.length; nFile++)
{
	if(endsWith(list[nFile], suffix))
	{
		nTotFiles++;
	}
}


//image storing results
newImage("sumresults", "32-bit black", 18, nTotFiles, 1);
resID = getImageID();
run("Set...", "value=NaN");


maxNumber =  newArray(nTotFiles);

fFileTitle =  newArray(nTotFiles);

nFileCount = -1;

for (nFile = 0; nFile < list.length; nFile++)
{
	if(endsWith(list[nFile], suffix))
	{
		nFileCount++;
		currentFullFilename = input+list[nFile];
		//fNameIn = "CEP120_001_total.csv";
		fNameIn = list[nFile];
		print(fNameIn);
		fFileTitle[nFileCount] = fNameIn;
		open(currentFullFilename);
		//open("F:/PROJECTS/BasalBodiesAverage/Analysis_averages_20250415/IntensityProfiles/" + fNameIn);
		Table.rename(fNameIn, "Results");
		plotYin = newArray(nColN);
		plotX = newArray(nColN);
		
		if(!bUseRowRange)
		{
			nRowEnd = nResults;
		}
		for (i = 0; i < nColN; i++)
		{
			for (nRow = nRowBeg; nRow <= nRowEnd; nRow++)
			{
				plotYin[i]+=getResult("Y"+toString(i), nRow-1);
			}
			plotX[i]=i;
		}
		//smooth the intensity
		plotY = newArray(nColN);
		smoothSubtractInt(plotYin, plotY, dSmoothWindow);		
		
		//find maxima and plot them (Z-Slices)
		
		maxLocsZ = Array.findMaxima(plotY, dMaxToleranceZ, 1);
		nMaxZN = maxLocsZ.length;
		maxNumber[nFileCount] = nMaxZN;

		Plot.create(fNameIn, "Z-slice", "Sum_intensity", plotX, plotY);
		Plot.addText("Z_"+fNameIn, 0, 0);

		//PLOT ALL Z MAXIMA
		maxplotx = newArray(nMaxZN);
		maxploty = newArray(nMaxZN);	
	
		for (jj = 0; jj < nMaxZN; jj++)
		{
		      x = maxLocsZ[jj];
		      maxplotx[jj]=x;
		      y = plotY[x];
		      maxploty[jj] = y;
			  // print("MAXIMA x= ", x, " y= ", y);
		}		
		Plot.add("circle", maxplotx, maxploty);
		Plot.setStyle(1, "blue,white,3,Circle");

		nTotZMax = Math.min(2,nMaxZN);
		for(maxZInd = 0; maxZInd<  nTotZMax; maxZInd++)
		{
		
			//find all "left" "right"			
			maxLR = newArray(2);
			findLRMax(plotY, maxplotx[maxZInd], maxLR);
			//store results
			setPixel(maxZInd*3, nFileCount, maxLocsZ[maxZInd]+1);
			setPixel(maxZInd*3+1, nFileCount, maxLR[0]);
			setPixel(maxZInd*3+2, nFileCount, maxLR[1]);
			
			//plot results
			LRPlotY = newArray(4);
			LRPlotX = newArray(4);
			makePlotLineLR(maxLR, plotY[maxplotx[maxZInd]], LRPlotX,LRPlotY);

			Plot.add("line", LRPlotX, LRPlotY);
			if(maxZInd ==1 )
			{
				Plot.setStyle(4, "green,white,3,Line");	
			}
		}
			
		Plot.show();	
		saveAs("Tiff", folderZMaxplots+"Z_"+fNameIn);
		close();
		
		/////RADIUS LOCATIONS
		for(maxZInd = 0; maxZInd<  nTotZMax; maxZInd++)
		{
			
			Zpos =  maxLocsZ[maxZInd];
			
			plotRYin = newArray(nRowEnd - nRowBeg+1);
			plotRY = newArray(nRowEnd - nRowBeg+1);
			plotRX = newArray(nRowEnd - nRowBeg+1);
			for (nRow = nRowBeg; nRow <= nRowEnd; nRow++)
			{
				plotRYin[nRow-nRowBeg]+=getResult("Y"+toString(Zpos), nRow-1);
				plotRX[nRow-nRowBeg] = nRow-1;
			}
			smoothSubtractInt(plotRYin, plotRY, dSmoothWindow);
			Plot.create(fNameIn, "Radius", "Sum_intensity_sl_"+toString(Zpos+1), plotRX, plotRY);
			Plot.addText("R_(zmax"+toString(maxZInd+1)+")_"+fNameIn, 0, 0);
			
			
			maxLocsR = Array.findMaxima(plotRY, dMaxToleranceR, 1);
			nMaxRN = maxLocsR.length;
			//print(nMaxRN);
			
			//PLOT ALL R MAXIMA
			maxplotx = newArray(nMaxRN);
			maxploty = newArray(nMaxRN);	
		
			for (jj = 0; jj < nMaxRN; jj++)
			{
			      x = maxLocsR[jj];
			      maxplotx[jj] = x + nRowBeg-1;
			      y = plotRY[x];
			      maxploty[jj] = y;
				  // print("MAXIMA x= ", x, " y= ", y);
			}		
			Plot.add("circle", maxplotx, maxploty);
			Plot.setStyle(1, "blue,white,3,Circle");
			
			//FIND LEFT AND RIGHT
			nTotRMax = Math.min(2,nMaxRN);
			for(maxRInd = 0; maxRInd<  nTotRMax; maxRInd++)
			{
				//find all "left" "right"				
				maxLR = newArray(2);
				findLRMax(plotRY,  maxLocsR[maxRInd], maxLR);
				
				//store results
				setPixel((maxZInd+1)*6 + maxRInd*3, nFileCount,maxLocsR[maxRInd] + nRowBeg-1);
				setPixel((maxZInd+1)*6 + maxRInd*3+1, nFileCount, maxLR[0] + nRowBeg-1);
				setPixel((maxZInd+1)*6 + maxRInd*3+2, nFileCount, maxLR[1] + nRowBeg-1);

				//plot results
				LRPlotY = newArray(4);
				LRPlotX = newArray(4);
				maxLRCorr = newArray(2);
				for(k=0;k<2;k++)
				{
					maxLRCorr[k] = maxLR[k] + nRowBeg-1;
				}
				makePlotLineLR(maxLRCorr, plotRY[maxLocsR[maxRInd]], LRPlotX,LRPlotY);
	
				Plot.add("line", LRPlotX, LRPlotY);
				if(maxRInd ==1 )
				{
					Plot.setStyle(4, "green,white,3,Line");	
				}
			}
			
			Plot.show();
			saveAs("Tiff", folderRMaxplots+"R_(Zmax"+toString(maxZInd+1)+")"+fNameIn);
			close();
		}
		
		if(nMaxZN ==0)
		{
			print("NO MAXIMA IN "+fNameIn);
		}

	}
	
}
run("Clear Results");
for(nFile =0; nFile<nTotFiles; nFile++)
{
	setResult("Filename", nFile , fFileTitle[nFile]);
	setResult("Z_maxN", nFile , maxNumber[nFile]);
	for(i=0;i<2;i++)
	{
		setResult("Z_max"+toString(i+1), nFile , getPixel(i*3, nFile));
		setResult("Z_max"+toString(i+1)+"Left", nFile , getPixel(i*3+1, nFile));
		setResult("Z_max"+toString(i+1)+"Right", nFile , getPixel(i*3+2, nFile));
	}
	for(i=0;i<2;i++)
	{
		for(j=0;j<2;j++)
		{
			setResult("R_(Zmax"+toString(i+1)+")_max"+toString(j+1), nFile , getPixel((i+1)*6 + j*3, nFile));
			setResult("R_(Zmax"+toString(i+1)+")_max"+toString(j+1)+"Left", nFile , getPixel((i+1)*6 + j*3+1, nFile));
			setResult("R_(Zmax"+toString(i+1)+")_max"+toString(j+1)+"Right", nFile , getPixel((i+1)*6 + j*3+2, nFile));

		}
	}
	
}
selectImage(resID);
close();
saveAs("Results", output+"FHWM_Results_"+sTimeStamp+".csv");
//File.openSequence(folderRMaxplots);
print("all done.");
//save log
selectWindow("Log");
saveAs("Text", output+"Log_"+sTimeStamp+".txt");

function findLRMax(Yvals, xMax, xLR)
{
	//going to the left
	vHalf = 0.5*Yvals[xMax];
	
	//LEFT
	currX = xMax;
	currY = Yvals[xMax];
	bSearch = true;
	while(bSearch)
	{
		currX--;
		prevY = currY;
		currY = Yvals[currX];
		if(currX == 0)
		{
			bSearch = false;
		}
		else {
			if(currY>=prevY)
			{
				currX++;
				bSearch = false;
			}
			else {

				if(Yvals[currX]<=vHalf)
				{
					bSearch = false;
				}
			}
		}
	}
	xLR[0] = currX;
	
	//RIGHT
	currX = xMax;
	currY = Yvals[xMax];
	bSearch = true;
	while(bSearch)
	{
		currX++;
		prevY = currY;
		currY = Yvals[currX];
		if(currX ==Yvals.length-1)
		{
			bSearch = false;
		}
		else {
			if(currY>=prevY)
			{
				currX--;
				bSearch = false;
			}
			else {

				if(Yvals[currX]<=vHalf)
				{
					bSearch = false;
				}
			}
		}
	}
	xLR[1] = currX;
}

function makePlotLineLR(xLR, yMax, outX,outY)
{
	outX[0] = xLR[0];
	outX[1] = xLR[0];
	outX[2] = xLR[1];
	outX[3] = xLR[1];

	outY[0] = 0;
	outY[1] = yMax;
	outY[2] = yMax;
	outY[3] = 0;		
}

function smoothSubtractInt(in, out, dWindow)
{
	dHalfW = Math.ceil(dWindow*0.5);
	N = in.length;
	for (i = 0; i < N; i++) 
	{
		nMin = Math.max(0,i-dHalfW);
		nMax = Math.min(i+dHalfW, N-1);
		nCount = 0;
		out[i]=0;
		for(x=nMin;x<nMax;x++)
		{
			out[i]+=in[x];
			nCount++;
		}
		out[i]/=nCount;
	}
	
		minY = 1000000000000000;
		//subtract minimun
		for (i = 0; i < N; i++)
		{
			if(out[i]<minY)
				minY = out[i];
		}
		
		for (i = 0; i < N; i++)
		{
			out[i]-=minY;
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