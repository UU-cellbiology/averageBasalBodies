

values = getArgument();
//running from another macro
if(values.length()>0)
{
	params = split(values, "#");
	inputFullFilename = params[0];
	output = params[1];
}
//running on its own
else 
{
	//output = "F:/PROJECTS/BasalBodiesAverage/Analysis_averages_20241021/FWHM_profiles/";
	//open();
	inputFullFilename = File.openDialog("choose file");
	output = getDirectory("choose output directory");
}

//print(inputFullFilename);

open(inputFullFilename);
fileID = getImageID();
//input = "F:/Basal body averaging 2024/Analysis/Validation diameter/RAW_reg/temp_test";
sFilename = File.name;
sArrName = split(sFilename, "_");
nProteinsN = 2;
nNumberIndex = 4;
if(startsWith(sArrName[2],"decov"))
{
	nProteinsN = 1;
	nNumberIndex = 3;
}
sProtName = newArray(nProteinsN);

run("Plots...", "width=1000 height=340 font=14 draw_ticks list minimum=0 maximum=0 interpolate");

for (iP = 0; iP < nProteinsN; iP++) 
{
	sProtName[iP] = sArrName[iP+1] + "_" + sArrName[nNumberIndex]; 
	//print(sProtName[iP]);		
	if(iP == 1 && startsWith(sProtName[iP], "centriolin"))
	{
		sProtName[1] = sProtName[1]+"_"+sProtName[0];
	}
	//Pick name of file and channel number
	action(output, sProtName[iP], iP+2);
	selectImage(fileID);
}
selectImage(fileID);
close();

function action(output, proteinName,channel) 
{
		//analysis parameters
		xC = 243;
		yC = 236;
		nRadius = 110;
		zSliceBeg = 117;
		zSliceEnd = 261;
		sSliceRange = toString(zSliceBeg)+"-"+toString(zSliceEnd);
		sXC = toString(xC);
		sYC = toString(yC);
		sRad = toString(nRadius);

        print("Working on: " + proteinName);
        run("Select All");
        run("Duplicate...", "duplicate channels=channel slices=" + sSliceRange);
        chImageID = getImageID();
        run("Radial Profile Angle", "x_center="+ sXC +" y_center="+ sYC +" radius="+ sRad +" starting_angle=0 integration_angle=180 calculate_radial_profile_on_stack");
		selectWindow("Radial Profile Plot");
		close();
		saveAs("Results", output + proteinName + "_total.csv");
		Table.rename(Table.title, "Results");
//		selectWindow(proteinName + "_total.csv");
//		run("Close");
		selectImage(chImageID);
		run("Radial Profile Angle", "x_center="+ sXC +" y_center="+ sYC +" radius="+ sRad +" starting_angle=90 integration_angle=30 calculate_radial_profile_on_stack");
		selectWindow("Radial Profile Plot");
		close();
		saveAs("Results", output + proteinName + "_BF.csv");
		Table.rename(Table.title, "Results");
//		selectWindow(proteinName + "_BF.csv");
//		run("Close");
		selectImage(chImageID);
		run("Radial Profile Angle", "x_center="+ sXC +" y_center="+ sYC +" radius="+ sRad +" starting_angle=270 integration_angle=150 calculate_radial_profile_on_stack");
		selectWindow("Radial Profile Plot");
		close();
		saveAs("Results", output + proteinName + "_BB.csv");
		Table.rename(Table.title, "Results");

//		selectWindow(proteinName + "_BB.csv");
//		run("Close");
       // close();
       selectImage(chImageID);
       close();
}

