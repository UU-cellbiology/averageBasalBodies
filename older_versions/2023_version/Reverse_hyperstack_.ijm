Stack.getDimensions(width, height, channels, slices, frames);
origTitle=getTitle();
run("Split Channels");
for(c=1;c<=channels;c++)
{
	selectWindow("C"+toString(c)+"-"+origTitle);
	run("Reverse");
}
runstr="";
for(c=1;c<=channels;c++)
{
	runstr=runstr+"c"+toString(c)+"=[C"+toString(c)+"-"+origTitle+"] ";
}
runstr=runstr+"create";
run("Merge Channels...", runstr);