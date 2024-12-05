Dialog.create("Batch homogenization");
//Dialog.addNumber("Reference channel",2);

//Dialog.addNumber("Averaging iterations N", 4.0);
//Dialog.show();
//nChAlign=Dialog.getNumber();
//nIterN = Dialog.getNumber();

//topDataFolderDir = getDir("Select top data folder...");
topDataFolderDir="F:/PROJECTS/BasalBodiesAverage/Emma_analysis_july_processed/";
//topDataFolderDir="F:/PROJECTS/BasalBodiesAverage/Emma_test/";

//macroDir = getDir("Select code folder...");
//print(topDataFolderDir);
outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20241021/"; 
//outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_test_avrg/";
//outputDir = getDir("Choose output data folder...");
//print(outputDir);
rootDir =  outputDir+"a1_scaling/";
File.makeDirectory(rootDir);
stacksBBDir = rootDir+"BB_channel/";
File.makeDirectory(stacksBBDir);
csvBBDir = rootDir+"BB_csv/";
File.makeDirectory(csvBBDir);
fitPicBBDir = rootDir+"plots_D_fits/";
File.makeDirectory(fitPicBBDir);
intProfBBDir = rootDir+"plots_intProf/";
File.makeDirectory(intProfBBDir);
intProfCenterBBDir = rootDir+"plots_intProfCenter/";
File.makeDirectory(intProfCenterBBDir);
marksBBDir = rootDir+"BB_marks/";
File.makeDirectory(marksBBDir);
//setBatchMode(true);

suffix = "/";
listFolder = getFileList(topDataFolderDir);

//count all folders
nTotFolders = 0;
for (nFolder = 0; nFolder < listFolder.length; nFolder++) 
{	
	if(endsWith(listFolder[nFolder], suffix))
	{	
		nTotFolders++;
	}
}
print("Detected "+toString(nTotFolders) +" folders."); 
sNames = newArray(nTotFolders);
fFitTop = newArray(nTotFolders);
fFitBottom = newArray(nTotFolders);
fFitZPos = newArray(nTotFolders);
fFitSlope = newArray(nTotFolders);
nToTZSlices = newArray(nTotFolders);
fPxWSize = newArray(nTotFolders);
fPxHSize = newArray(nTotFolders);
fPxDSize = newArray(nTotFolders);
fCenterX = newArray(nTotFolders);
fCenterY = newArray(nTotFolders);

nCurrFolderInd = 0;
for (nFolder = 0; nFolder < listFolder.length; nFolder++) 
{	
	if(endsWith(listFolder[nFolder], suffix))
	{	
		folderPath = topDataFolderDir+listFolder[nFolder];
		sFolderName = substring(listFolder[nFolder], 0, lengthOf(listFolder[nFolder])-lengthOf(suffix));
		//print(folderPath);
		suffixSF = "avg/";
		listCurrFolder = getFileList(folderPath);
		for (nSubFolder = 0; nSubFolder < listCurrFolder.length; nSubFolder++) 
		{
			if(endsWith(listCurrFolder[nSubFolder], suffixSF))
			{	
				sSubFolderName = substring(listCurrFolder[nSubFolder], 0, lengthOf(listCurrFolder[nSubFolder])-lengthOf(suffixSF));
				sSubFolderPath = folderPath+listCurrFolder[nSubFolder];
				//print();
				sAvrgName = getFirstFileNameNoExt(sSubFolderPath, ".tif");
				sNames[nCurrFolderInd] = sAvrgName;
				print(sAvrgName);
				open(sSubFolderPath+sAvrgName+".tif");
				fileID = getImageID();
				//get only channel we need
				run("Select All");
				Stack.getDimensions(widthOrig, heightOrig, nChAlign, slices, frames);
				nToTZSlices[nCurrFolderInd] = slices;
				getVoxelSize(pxWSize, pxHSize, pxDSize, unit);
				fXY_Zscale = pxDSize/pxWSize;
				fPxWSize[nCurrFolderInd] = pxWSize;
				fPxHSize[nCurrFolderInd] = pxHSize;
				fPxDSize[nCurrFolderInd] = pxDSize;
				run("Duplicate...", "title=BB duplicate channels="+toString(nChAlign));
				imageBB = getImageID();
				

				
				run("Grays");
				run("Select All");
				run("Plot Z-axis Profile");
				saveAs("PNG", intProfBBDir+ sAvrgName+"_fit.png" );
				
				Plot.getValues(slice, weights);
				close();
				selectImage(imageBB);
				run("Select All");
				run("Reslice [/]...", "start=Left");
				resliceID = getImageID();
				run("Z Project...", "projection=[Max Intensity]");
				yzID = getImageID();
				selectImage(resliceID);
				close();
//				selectImage(imageBB);
//				saveAs("Tiff",stacksBBDir+sAvrgName+"_BB.tif");
//				close();
				selectImage(fileID);
				close();
				sCSVName = getFirstFileNameNoExt(sSubFolderPath, "_diam.csv");
				//File.copy(sSubFolderPath+sCSVName+"_diam.csv", csvBBDir+sCSVName+"_BB.csv");
				Table.open(sSubFolderPath+sCSVName+"_diam.csv");
				Table.rename(Table.title, "Results");
				//open(sSubFolderPath+sCSVName+"_diam.csv");
				xpoints = newArray(nResults);
				ypoints = newArray(nResults);
				fMaxInt = -100.0;
				dCenterX = 0;
				dCenterY = 0;
				for (i = 0; i < nResults(); i++) 
				{
				   xpoints[i] = getResult("finZ", i);
				   ypoints[i] = getResult("finDiam", i);
				   setResult("IntWeight", i, weights[i]);
				   if(weights[i]>fMaxInt)
				   {
				   	fMaxInt = weights[i];
				   	dCenterX = getResult("finX", i);
				   	dCenterY = getResult("finY", i);
				   }
				}
				print(fMaxInt);
				
				saveAs("Results", csvBBDir+sCSVName+"_BB_fitdata.csv");

				Fit.doWeightedFit("Rodbard", xpoints, ypoints, weights);
				

				Fit.plot;
				fFitTop[nCurrFolderInd] = Fit.p(0);
				fFitSlope[nCurrFolderInd] = Fit.p(1);
				fFitZPos[nCurrFolderInd] = Fit.p(2);
				fFitBottom[nCurrFolderInd] = Fit.p(3);

				rename(sAvrgName+"_fit");
				saveAs("PNG", fitPicBBDir+ sAvrgName+"_fit.png" );
				close();

				//get centrl profile
				selectImage(imageBB);
				//print(dCenterY);
				dCenterX = dCenterX*2 + widthOrig*0.5;
				dCenterY = dCenterY*2 + heightOrig*0.5;
				fCenterX[nCurrFolderInd] = dCenterX;
				fCenterY[nCurrFolderInd] = dCenterY;
				
				nCW = fFitTop[nCurrFolderInd]/pxWSize;
				makeRectangle(dCenterX-0.5*nCW, dCenterY-0.5*nCW, nCW, nCW);
				run("Plot Z-axis Profile");
				Plot.getValues(slice, centerInt);
				
				saveAs("PNG", intProfCenterBBDir+ sAvrgName+"_center.png" );
				close();
			
				selectImage(imageBB);
				saveAs("Tiff",stacksBBDir+sAvrgName+"_BB.tif");
				close();
				
				selectImage(yzID);
				
				run("FeatureJ Edges", "compute smoothing=3 lower=[] higher=[]");
				gradID = getImageID();
				
				selectImage(yzID);
				//calc position transition top			
				nFrTransTop= invRodb (fFitSlope[nCurrFolderInd],
										fFitZPos[nCurrFolderInd], 0.9);
				nFrTransTop = Math.round(nFrTransTop*fXY_Zscale);
				nFrTransBottom= invRodb (fFitSlope[nCurrFolderInd],
											fFitZPos[nCurrFolderInd], 0.1);
				nFrTransBottom = Math.round(nFrTransBottom*fXY_Zscale);
				//draw lines 
				setLineWidth(1);
				//drawLine(0, nFrTransTop, heightOrig-1, nFrTransTop);
				//run("Draw", "slice");
				//drawLine(0, nFrTransBottom, heightOrig-1, nFrTransBottom);
				//run("Draw", "slice");
				
				fMaxInt = -100;
				for (i = 0; i < nResults(); i++) 
				{
					if(fMaxInt<centerInt[i])
					{
						fMaxInt=centerInt[i] ;
					}
				}
			
				fIntTh = fMaxInt*0.5;
				dInd = -1;
				//find the top
				for (i = 0; i < nResults(); i++) 
				{
					if(centerInt[i]>fIntTh)
					{
						dInd = i;
						//print(dInd);
						i =nResults();
					}
				}
				//drawLine(0, dInd*fXY_Zscale, heightOrig-1,dInd*fXY_Zscale);
				//run("Draw", "slice");
				
				saveAs("Tiff",marksBBDir+sAvrgName+"_YZ_max.tif");
				//setAutoThreshold("Default dark no-reset");
				//run("Threshold...");
				//run("Convert to Mask");
				//run("Skeletonize");
				//saveAs("Tiff",marksBBDir+sAvrgName+"_skel.tif");
				close();
				//selectImage(yzID);
				//close();
				//exit
				selectImage(gradID);
				makeLine(dCenterY, 0, dCenterY, getHeight()-1);
				Roi.setStrokeWidth(15);

				profile = getProfile();
				//Array.getStatistics(profile, min, maxI); 
				//Plot.create("Profile", "X", "Value", profile);

				maxEdgePos = Array.findMaxima(profile, 20);
				Array.sort(maxEdgePos);
				f = File.open(marksBBDir+sAvrgName+"_marks.csv");
				for (nMax = 0; nMax < maxEdgePos.length; nMax++) 
				{
					print(f, toString(nMax+1) +","+toString(maxEdgePos[nMax]));
					drawLine(0, maxEdgePos[nMax], heightOrig-1,maxEdgePos[nMax]);					
					//run("Draw", "slice");
				}
				File.close(f);
				//Plot.create("Profile", "X", "Value", profile);
				saveAs("Tiff",marksBBDir+sAvrgName+"_YZ_edge.tif");
				close();
				

				nSubFolder = listCurrFolder.length;
			}
		}
		nCurrFolderInd++;
	}
}
setBatchMode(false);
run("Clear Results");
for(i = 0; i<nCurrFolderInd; i++)
{
	setResult("Label", i, sNames[i]);
	setResult("fit_Z", i, fFitZPos[i]);
	setResult("fit_Slope_px", i, fFitSlope[i]);
	setResult("fit_Top_px", i, fFitTop[i]/ fPxWSize[i]);
	setResult("fit_Bottom_px", i, fFitBottom[i]/ fPxWSize[i]);
	setResult("px_X", i, fPxWSize[i]);
	setResult("px_Y", i, fPxHSize[i]);
	setResult("px_Z", i, fPxDSize[i]);
	setResult("center_X", i, fCenterX[i]);
	setResult("center_Y", i, fCenterY[i]);
	
	setResult("TotZSlices", i, nToTZSlices[i]);

}
saveAs("Results",rootDir+"summary_fit_params.csv");
print("Done");

function getFirstFileNameNoExt(path, suffixFile)
{
	//suffixFile = ".tif";
	listFiles = getFileList(path);
	for (nF = 0; nF < listFiles.length; nF++) 
	{	
		if(endsWith(listFiles[nF], suffixFile))
		{	
			return 	substring(listFiles[nF], 0, lengthOf(listFiles[nF])-lengthOf(suffixFile));
		}
	}
}

function invRodb (b,c, nFr)
{
	out = (1.0/nFr) - 1.0;
	out = c*Math.pow(out, 1.0/b);
	return out;
}