filesDir = getDir("Choose a folder with files...");

filesXYDir = filesDir+"max_XY/";
File.makeDirectory(filesXYDir);
filesXZDir = filesDir+"max_XZYZ/";
File.makeDirectory(filesXZDir);

suffix = ".tif";
list = getFileList(filesDir);
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
	    print("Working on file (XY XZ proj) "+list[nFile]);
		//in case you need only filename
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		//open file
		basecurr = filesDir+list[nFile];
		//open file
		open(basecurr);
		//get file ID
		openImageID=getImageID();
				
		getVoxelSize(pW, pH, pD, unit);
		run("Z Project...", "projection=[Max Intensity]");
		run("Make Composite");
		Stack.getDimensions(width, height, channels, slices, frames);
		for(i=1;i<=channels;i++)
		{
			Stack.setChannel(i);
			resetMinAndMax();
		}
		saveAs("Tiff", filesXYDir+noExtFilename+"_max_xy.tif");
		close();
		selectImage(openImageID);
		run("Select All");
		run("Reslice [/]...", "output="+toString(pD)+" start=Top");
		tempRS=getImageID();
		run("Z Project...", "projection=[Max Intensity]");
		projXZ=getImageID();
		selectImage(tempRS);
		close();
		selectImage(projXZ);
		rename("xz");
		xzyzW = getWidth();
		xzyzH = getHeight();
		run("Canvas Size...", "width="+toString(xzyzW+2)+" height="+toString(xzyzH)+" position=Center zero");
		selectImage(openImageID);
		run("Select All");
		run("Reslice [/]...", "output="+toString(pD)+" start=Left");
		tempRS=getImageID();
		run("Z Project...", "projection=[Max Intensity]");
		projXY=getImageID();
		selectImage(tempRS);
		close();
		selectImage(projXY);
		rename("yz");
		xzyzW = getWidth();
		xzyzH = getHeight();
		run("Canvas Size...", "width="+toString(xzyzW+2)+" height="+toString(xzyzH)+" position=Center zero");
		run("Combine...", "stack1=xz stack2=yz");
		xzyzW = getWidth();
		xzyzH = getHeight();
		run("Canvas Size...", "width="+toString(xzyzW+10)+" height="+toString(xzyzH)+" position=Center zero");
		run("Make Composite");
		for(i=1;i<=channels;i++)
		{
			Stack.setChannel(i);
			resetMinAndMax();
		}
		saveAs("Tiff", filesXZDir+noExtFilename+"_max_xzyz.tif");
		close();
		selectImage(openImageID);
		close();
		
	}
}
