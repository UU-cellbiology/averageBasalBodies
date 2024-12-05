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
root2Dir =  outputDir+"a2_scaling/";

rootDir =  outputDir+"a3_scaling/";
File.makeDirectory(rootDir);
notRescaledBBDir = rootDir+"not_rescaled/";
File.makeDirectory(notRescaledBBDir);
rescaledDir = rootDir+"rescaled/";
File.makeDirectory(rescaledDir);
//setBatchMode(true);

suffix = "/";
listFolder = getFileList(topDataFolderDir);
//setBatchMode(true);
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

nMiddle = newArray(nTotFolders);
nScalez1 = newArray(nTotFolders);
nScalez2 = newArray(nTotFolders);
nWidthY = newArray(nTotFolders);
nWidthX = newArray(nTotFolders);
sNameCheck = newArray(nTotFolders);
//read scales
Table.open(root2Dir+"summary_fit_params.csv");
Table.rename(Table.title, "Results");
for (i = 0; i < nResults(); i++) 
{
    nMiddle[i] = getResult("Middle", i);
    nWidthX[i] = getResult("XSize", i);
    nWidthY[i] = getResult("YSize", i);
    nScalez1[i] = getResult("ZScale1", i);
    nScalez2[i] = getResult("ZScale2", i);
   sNameCheck[i] = getResultLabel(i);
}
//Array.getStatistics(nScalez1, min, max, meanZ1, stdDev);
//Array.getStatistics(nScalez2, min, max, meanZ2, stdDev);
Array.getStatistics(nWidthX, min, max, meanX, stdDev);
Array.getStatistics(nWidthY, min, max, meanY, stdDev);
//print("MeanScaleZ1 ",meanZ1);
//print("MeanScaleZ2 ",meanZ2);
print("MeanX ",meanX);
print("MeanY ",meanY);
meanXY = Math.max(meanX, meanY);
print("MeanXY ",meanXY);

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
				print(sNameCheck[nCurrFolderInd]);
				open(sSubFolderPath+sAvrgName+".tif");
				
				fileID = getImageID();
				//get only channel we need
				run("Select All");
				Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
				print("Slices  not rescaled",slices);
				slBefore = slices;
				getVoxelSize(pxWSize, pxHSize, pxDSize, unit);
				sTitle = getTitle();
				run("Split Channels");
				sPref2 = "C1-";
				//print (channels);
				if(channels ==2)
				{
					newImage("C3-"+sTitle, "32-bit black", widthOrig, heightOrig, slices);
					sPref1 = "C2-";
					sPref3 = "C3-";
				}
				if(channels ==3) 
				{
					sPref1 = "C3-";
					sPref3 = "C2-";					
				}
				if(channels ==4) 
				{
					sPref1 = "C4-";
					sPref3 = "C2-";
					selectWindow("C3-"+sTitle);
					close();
				}
				
				run("Merge Channels...", "c1=["+ sPref1 + sTitle +
				"] c2=["+ sPref2 + sTitle + 
				"] c3=["+ sPref3 + sTitle +
				"] create ignore");
				saveAs("Tiff",notRescaledBBDir+sAvrgName+"_ch.tif");
				normCh = getImageID();
				//close();
				run("Reslice [/]...", "start=Left");
				reslID = getImageID();
				imW = getWidth();
				imH = getHeight();
				makeRectangle(0, 0, imW-1, nMiddle[nCurrFolderInd]);
				run("Duplicate...", "title=TOP duplicate");
				tempID = getImageID();
				run("Scale...", "x=1 y="+toString( nScalez1[nCurrFolderInd])+" interpolation=Bicubic average create");
				scaledID = getImageID();
				selectImage(tempID);
				close();
				selectImage(scaledID);
				rename("TOP");
				selectImage(reslID);
				makeRectangle(0, nMiddle[nCurrFolderInd], imW-1, imH-nMiddle[nCurrFolderInd]);
				run("Duplicate...", "title=BOTTOM duplicate");
				tempID = getImageID();
				run("Scale...", "x=1 y="+toString( nScalez2[nCurrFolderInd])+" interpolation=Bicubic average create");
				scaledID = getImageID();
				selectImage(tempID);
				close();
				selectImage(scaledID);
				rename("BOTTOM");			
				run("Combine...", "stack1=TOP stack2=BOTTOM combine");
				combFinID = getImageID();
				selectImage(reslID);
				close();
				selectImage(normCh);
				close();					
				selectImage(combFinID);
				run("Reslice [/]...", "start=Top flip");
				preFinID = getImageID();
				selectImage(combFinID);
				close();
				selectImage(preFinID);
				run("Rotate 90 Degrees Right");
				Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
				if(channels == 1)
				{
					run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices="+slices/3+" frames=1 display=Composite");
				}
				preFinID = getImageID();
				run("Scale...", "x="+toString( meanXY/nWidthX[nCurrFolderInd])+" y="+toString( meanXY/nWidthY[nCurrFolderInd])+" interpolation=Bicubic average create");
				setVoxelSize(250.0/meanXY, 250.0/meanXY, 2*250/meanXY, "nm");
				Stack.getDimensions(widthOrig, heightOrig, channels, slices, frames);
				print("Slices rescaled ",slices);
				print("Estimate slices rescaled ",  0.5*nMiddle[nCurrFolderInd]*nScalez1[nCurrFolderInd]+
				(slBefore-0.5*nMiddle[nCurrFolderInd])*nScalez2[nCurrFolderInd]);
				for(nCh=1;nCh<4;nCh++)
				{
					Stack.setPosition(nCh, Math.round(slices*0.5), 1);
					resetMinAndMax();
					if(nCh==1)
					{
						run("Grays");
					}
					if(nCh==2)
					{
						run("Magenta");
					}

					if(nCh==3)
					{
						run("Cyan");
					}

				}
				saveAs("Tiff",rescaledDir+sAvrgName+"_rescaled.tif");
				close();
				selectImage(preFinID);
				close();
				
		
				nSubFolder = listCurrFolder.length;
			}
		}
		nCurrFolderInd++;
	}
}
setBatchMode(false);



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
