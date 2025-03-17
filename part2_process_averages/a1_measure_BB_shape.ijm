
//PARAMETERS 

// smooth scale for the calculation of the gradient image (edges)
nSmoothScale = 3;
//This is the width of the line in the middle of the gradient image 
//to get intensity profile. This profile will be used to find intensity maximum
nMiddleLineWidthEdges = 15;
// this is tolerance while finding maxima for marks (see above)
nMaxToleranceEdges = 20;

Dialog.create("Batch homogenization");
//Dialog.addNumber("Reference channel",2);

//Dialog.addNumber("Averaging iterations N", 4.0);
//Dialog.show();
//nChAlign=Dialog.getNumber();
//nIterN = Dialog.getNumber();

//topDataFolderDir = getDir("Select top data folder...");
//topDataFolderDir="F:/PROJECTS/BasalBodiesAverage/20240512_test/";
topDataFolderDir="F:/PROJECTS/BasalBodiesAverage/Emma_analysis_july_processed/";

//macroDir = getDir("Select code folder...");
//print(topDataFolderDir);
outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_averages_20250204/"; 
//outputDir = "F:/PROJECTS/BasalBodiesAverage/Emma_test_avrg/";
//outputDir = getDir("Choose output data folder...");
//print(outputDir);
rootDir =  outputDir+"a1_measure/";
File.makeDirectory(rootDir);
stacksBBDir = rootDir+"BB_channel/";
File.makeDirectory(stacksBBDir);
intProfBBDir = rootDir+"plots_intProf/";
File.makeDirectory(intProfBBDir);
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
				
				//get only channel we need, i.e. total protein stain
				run("Select All");
				//nChAling <- number of channel with total protein stain,
				// in our case it is always the last channel,
				// so we get its number here
				Stack.getDimensions(widthOrig, heightOrig, nChAlign, slices, frames);
				
				nToTZSlices[nCurrFolderInd] = slices;
				getVoxelSize(pxWSize, pxHSize, pxDSize, unit);
				fXY_Zscale = pxDSize/pxWSize;
				fPxWSize[nCurrFolderInd] = pxWSize;
				fPxHSize[nCurrFolderInd] = pxHSize;
				fPxDSize[nCurrFolderInd] = pxDSize;
				run("Duplicate...", "title=BB duplicate channels="+toString(nChAlign));
				imageBB = getImageID();
				//close original stack
				selectImage(fileID);
				close();

				// Plot Z-axis profile
				run("Grays");
				run("Select All");
				run("Plot Z-axis Profile");
				saveAs("PNG", intProfBBDir+ sAvrgName+"_fit.png" );
				// store intensity values			
				Plot.getValues(slice, weights);
				close();
				
				//BUILD YZ VIEW MAX PROJECTION
				selectImage(imageBB);
				run("Select All");
				run("Reslice [/]...", "start=Left");
				resliceID = getImageID();
				run("Z Project...", "projection=[Max Intensity]");
				yzID = getImageID();
				selectImage(resliceID);
				close();
				selectImage(imageBB);
				saveAs("Tiff",stacksBBDir+sAvrgName+"_BB.tif");
				close();

				// get the center XY coordinates at the slice 
				// with the maximum intensity along Z (using weights above) 
				sCSVName = getFirstFileNameNoExt(sSubFolderPath, "_diam.csv");
				Table.open(sSubFolderPath+sCSVName+"_diam.csv");
				Table.rename(Table.title, "Results");

				fMaxInt = -100.0;
				dCenterX = 0;
				dCenterY = 0;
				for (i = 0; i < nResults(); i++) 
				{
				   setResult("IntWeight", i, weights[i]);
				   if(weights[i]>fMaxInt)
				   {
					   	fMaxInt = weights[i];
					   	dCenterX = getResult("finX", i);
					   	dCenterY = getResult("finY", i);
				   }
				}
				print(fMaxInt);

				//correct coordinates to get absolute value
				dCenterX = dCenterX*2 + widthOrig*0.5;
				dCenterY = dCenterY*2 + heightOrig*0.5;
				fCenterX[nCurrFolderInd] = dCenterX;
				fCenterY[nCurrFolderInd] = dCenterY;
				
				//calculate Edges (max of gradient)
				selectImage(yzID);				
				run("FeatureJ Edges", "compute smoothing="+toString(nSmoothScale)+" lower=[] higher=[]");
				gradID = getImageID();	
				selectImage(yzID);
				saveAs("Tiff",marksBBDir+sAvrgName+"_YZ_max.tif");
				close();
				selectImage(gradID);
				
				
				// get intensity progile in the center
				makeLine(dCenterY, 0, dCenterY, getHeight()-1);
				
				Roi.setStrokeWidth(nMiddleLineWidthEdges);

				profile = getProfile();
				//Array.getStatistics(profile, min, maxI); 
				//Plot.create("Profile", "X", "Value", profile);

				maxEdgePos = Array.findMaxima(profile, nMaxToleranceEdges);
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
	setResult("px_X", i, fPxWSize[i]);
	setResult("px_Y", i, fPxHSize[i]);
	setResult("px_Z", i, fPxDSize[i]);
	setResult("center_X", i, fCenterX[i]);
	setResult("center_Y", i, fCenterY[i]);	
	setResult("TotZSlices", i, nToTZSlices[i]);

}
saveAs("Results", rootDir+"summary_fit_params.csv");
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