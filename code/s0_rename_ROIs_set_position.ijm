nCount = roiManager("count");
if(nCount<1)
{
	exit("cannot find any ROIs in ROI manager");
}
nDigits = lengthOf(toString(nCount));
Dialog.create("Specify slice number");
Dialog.addNumber("selected slice number", 1);
Dialog.show();
nSlice = Dialog.getNumber();
for (i = 0; i < nCount; i++) 
{
	roiManager("Select", i);
	roiManager("Rename",String.pad(toString(i+1), nDigits));
	RoiManager.setPosition(nSlice);
}
print("renaming ROIs done.");