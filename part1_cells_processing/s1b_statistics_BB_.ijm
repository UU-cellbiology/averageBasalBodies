nVersion = "20261005";


bBatchFolder = false;
values = getArgument();
paramSeparator = "?";
if(values.length() > 0)
{
	params = split(values, paramSeparator);
	filesDir = params[0];
	dCoeffDiam = parseFloat(params[1]);
  	bBatchFolder = true;
}
else 
{
	filesDir = getDir("Choose data folder...");
	dCoeffDiam = 3.3;
}
statDir = filesDir  +"statistics/";
File.makeDirectory(statDir);

filesDetectedDir = filesDir+"s1_detected/";
sTimeStamp = getTimeStamp_sec();

//count files
suffix = ".csv";
list = getFileList(filesDetectedDir);
nTotFiles = 0;
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		nTotFiles ++;
	}
}
maxDiam = newArray(nTotFiles);
minDiam = newArray(nTotFiles);
numSlices = newArray(nTotFiles);
fileNames = newArray(nTotFiles);
nFileCount = 0;
for (nFile = 0; nFile < list.length; nFile++) 
{	
	if(endsWith(list[nFile], suffix))
	{
		noExtFilename = substring(list[nFile], 0, lengthOf(list[nFile])-lengthOf(suffix));
		basecurr = filesDetectedDir+list[nFile];
		run("Table... ", "open=["+basecurr+"]");
		Table.rename(list[nFile], "Results");
		fileNames[nFileCount] = list[nFile];
		numSlices[nFileCount] = nResults;
		dMax = -1000000;
		dMin = 10000000;
		for(row = 0; row < nResults; row++)
  		{
  			currD = getResult("finDiam", row);
  			dMax = Math.max(dMax, currD);
  			dMin = Math.min(dMin, currD);
  		}
  		maxDiam[nFileCount] = dMax;
  		minDiam[nFileCount] = dMin;
		nFileCount++;
	}
}

//save results
diamFile = statDir + "detect_stat.csv";
if(File.exists(diamFile))
{
	File.delete(diamFile);
}
file_out = File.open(diamFile);
print(file_out,"filename,minDiam,maxDiam,Zspan");
dAvrgMax = 0;
for (nFile = 0; nFile < nTotFiles; nFile++) 
{
	print(file_out,fileNames[nFile] + "," + toString(minDiam[nFile])  + ","
										  + toString(maxDiam[nFile])  + ","
										  + toString(numSlices[nFile]));
	dAvrgMax += maxDiam[nFile];
}
File.close(file_out);
//average max diam in units
dAvrgMax /= nTotFiles;
//let's read pixel size
vxFile = statDir + "voxel_size.csv";
run("Table... ", "open=[" + vxFile + "]");
Table.rename("voxel_size.csv", "Results");
vxSizeX = getResult("X", 0);
return toString(dCoeffDiam*dAvrgMax/vxSizeX);

function getTimeStamp_sec() 
{ 
	// returns timestamp: yearmonthdayhourminutesecond
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	TimeStamp = toString(year)+IJ.pad(month+1,2)+IJ.pad(dayOfMonth,2);
	TimeStamp = TimeStamp+IJ.pad(hour,2)+IJ.pad(minute,2)+IJ.pad(second,2);
	return TimeStamp;
}