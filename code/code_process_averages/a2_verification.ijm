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
prevMarkDir =  outputDir+"a1_scaling/BB_marks/";
BBchanDir =  outputDir+"a1_scaling/BB_channel/";
root1Dir =  outputDir+"a1_scaling/";

rootDir =  outputDir+"a2_scaling/";
File.makeDirectory(rootDir);
marksBBDir = rootDir+"BB_marks/";
File.makeDirectory(marksBBDir);
rescaleZBBDir = rootDir+"rescaleZ/";
File.makeDirectory(rescaleZBBDir);
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
fPxWSize = newArray(nTotFolders);
fPxHSize = newArray(nTotFolders);
fPxDSize = newArray(nTotFolders);
nTop = newArray(nTotFolders);
nMiddle = newArray(nTotFolders);
nBottom = newArray(nTotFolders);
nScalez1 = newArray(nTotFolders);
nScalez2 = newArray(nTotFolders);

nCenterX = newArray(nTotFolders);
nCenterY = newArray(nTotFolders);
nWidthY = newArray(nTotFolders);
nWidthX = newArray(nTotFolders);

//read centers
Table.open(root1Dir+"summary_fit_params.csv");
Table.rename(Table.title, "Results");
for (i = 0; i < nResults(); i++) 
{
    nCenterX[i] = getResult("center_X", i);
    nCenterY[i] = getResult("center_Y", i);
}


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

				open(prevMarkDir+sAvrgName+"_YZ_max.tif");
				yzID = getImageID();
				Table.open(prevMarkDir+sAvrgName+"_marks.csv");
				Table.rename(Table.title, "Results");
				setLineWidth(1);
				for (i = 0; i < 3; i++) 
				{
					yH = getResult("C2", i);
					drawLine(0, yH, getWidth()-1, yH);
				}
				nTop[nCurrFolderInd] =  getResult("C2", 0);
				nMiddle[nCurrFolderInd] =  getResult("C2", 1);
				nBottom[nCurrFolderInd] =  getResult("C2", 2);
				nScalez1[nCurrFolderInd] =  nMiddle[nCurrFolderInd] -nTop[nCurrFolderInd] ;
				nScalez2[nCurrFolderInd] =  nBottom[nCurrFolderInd] - nMiddle[nCurrFolderInd];
				///saveAs("Tiff",marksBBDir+sAvrgName+"_YZ_marks.tif");

				//close();
				
				//determine XY width 
				//open BB channel				
				open(BBchanDir+sAvrgName+"_BB.tif");
				bbID = getImageID();
				Stack.getDimensions(widthOrig, heightOrig, nChAlign, slices, frames);
				makeLine(nCenterX[nCurrFolderInd], 0, nCenterX[nCurrFolderInd], heightOrig-1);
				Roi.setStrokeWidth(1);
				run("Reslice [/]...", "slice_count=1");
				yzC = getImageID();
				nZ = nTop[nCurrFolderInd] + 0.5*nScalez1[nCurrFolderInd];
				makeLine(0, nZ,  heightOrig-1, nZ);
				Roi.setStrokeWidth(5);
				profile = getProfile();
				selectImage(yzC);
				close();

				selectImage(yzID);
				maxEdgePos = Array.findMaxima(profile, 200);
				setLineWidth(1);
				for(i=0;i<2;i++)
				{
					drawLine(maxEdgePos[i], 0, maxEdgePos[i], getHeight()-1);
				}
				nWidthY[nCurrFolderInd] = Math.abs(maxEdgePos[0]-maxEdgePos[1]);
				//XY
				selectImage(bbID);
				makeLine(0,nCenterY[nCurrFolderInd], widthOrig-1, nCenterY[nCurrFolderInd]);
				Roi.setStrokeWidth(1);
				run("Reslice [/]...", "slice_count=1");
				xzC = getImageID();
				//nZ = nTop[nCurrFolderInd] + 0.5*nScalez1[nCurrFolderInd];
				makeLine(0, nZ,  widthOrig-1, nZ);
				Roi.setStrokeWidth(5);
				profile = getProfile();
				selectImage(xzC);
				close();
				selectImage(bbID);
				close();
				
				maxEdgePos = Array.findMaxima(profile, 200);
				nWidthX[nCurrFolderInd] = Math.abs(maxEdgePos[0]-maxEdgePos[1]);
				
				
				saveAs("Tiff",marksBBDir+sAvrgName+"_YZ_marks.tif");

				close();
				

				nSubFolder = listCurrFolder.length;
			}
		}
		nCurrFolderInd++;
	}
}
setBatchMode(false);
run("Clear Results");
Array.getStatistics(nScalez1, min, max, meanZ1, stdDev);
Array.getStatistics(nScalez2, min, max, meanZ2, stdDev);
Array.getStatistics(nWidthX, min, max, meanX, stdDev);
Array.getStatistics(nWidthY, min, max, meanY, stdDev);

for(i = 0; i<nCurrFolderInd; i++)
{
	setResult("Label", i, sNames[i]);
	setResult("Top", i, nTop[i]);
	setResult("Middle", i,nMiddle[i]);
	setResult("Bottom", i, nBottom[i]);
	setResult("ZSize1", i, nScalez1[i]);
	setResult("ZSize2", i, nScalez2[i]);
	setResult("ZScale1", i, meanZ1/nScalez1[i]);
	setResult("ZScale2", i, meanZ2/nScalez2[i]);
	setResult("XSize",i, nWidthX[i]);
	setResult("XScale",i, meanX/nWidthX[i]);
	setResult("YSize",i, nWidthY[i]);
	setResult("YScale",i, meanY/nWidthY[i]);

}
print("MeanScaleZ1 ",meanZ1);
print("MeanScaleZ2 ",meanZ2);
print("MeanX ",meanX);
print("MeanY ",meanY);
saveAs("Results",rootDir+"summary_fit_params.csv");
for(i = 0; i<nCurrFolderInd; i++)
{
	sAvrgName = sNames[i];
	open(prevMarkDir+sAvrgName+"_YZ_max.tif");
	yzID = getImageID();
	imW = getWidth();
	imH = getHeight();
	makeRectangle(0, 0, imW-1, nMiddle[i]);
	run("Duplicate...", "title=TOP");
	tempID = getImageID();
	run("Scale...", "x=1 y="+toString( meanZ1/nScalez1[i])+" interpolation=Bicubic average create");
	scaledID = getImageID();
	selectImage(tempID);
	close();
	selectImage(scaledID);
	rename("TOP");
	
	selectImage(yzID);
	makeRectangle(0, nMiddle[i], imW-1, imH-nMiddle[i]);
	run("Duplicate...", "title=BOTTOM");
	tempID = getImageID();
	run("Scale...", "x=1 y="+toString( meanZ2/nScalez2[i])+" interpolation=Bicubic average create");
	scaledID = getImageID();
	selectImage(tempID);
	close();
	selectImage(scaledID);
	rename("BOTTOM");
	run("Combine...", "stack1=TOP stack2=BOTTOM combine");
	run("Scale...", "x="+toString(meanY/nWidthY[i])+" y=1 interpolation=Bicubic average");// create");
	saveAs("Tiff",rescaleZBBDir+sAvrgName+"_rescaled_YZ.tif");
	close();
	selectImage(yzID);
	close();
}


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
