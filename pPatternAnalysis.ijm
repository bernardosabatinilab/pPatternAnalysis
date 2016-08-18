// Urine pattern analysis macro
// For reference only - this code is optimized for specific camera and experimental settings
// Bernardo Sabatini Lab
// Hou et al., 2016
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black edm=16-bit");

name=getInfo("image.filename");
dir=getInfo("image.directory");
roiManager("reset"); run("Clear Results");
radius=46; height=getHeight(); width=getWidth(); minspotsize=5;

// create central pee region
waitForUser("Draw Central Pee Region, then Click OK");
run("Set Measurements...", "centroid redirect=None decimal=3");
run("Measure");
x=getResult("X",0); y=getResult("Y",0);
run("Clear Results");
makeOval(x-radius, y-radius, 2*radius, 2*radius);
roiManager("Add");
roiManager("Save", dir+name+"_CentralRegion.zip");

// create mask file
run("Select None");
run("Duplicate...", "title=mask");
run("Subtract Background...", "rolling=100");
run("Gaussian Blur...", "sigma=1");
setThreshold(30, 255);
setOption("BlackBackground", true);
run("Convert to Mask");

roiManager("Select", 0);
run("Clear", "slice");
run("Select None");
saveAs("Tiff", dir+name+"_mask.tif");
run("16-bit");
run("Multiply...", "value=300");
rename("mask");

// get distance map
newImage("distance", "8-bit black", width, height, 1);
setPixel(x,y,255);
run("Invert");
run("Distance Map");
selectImage("distance"); close();
imageCalculator("AND", "EDM of distance","mask");

selectImage("EDM of distance");
run("Set Measurements...", "area min integrated area_fraction redirect=None decimal=3");
run("Measure");

print(dir+name);
area=getResult("Area", 0) * getResult("%Area", 0) / 100.0; 
avedis=getResult("RawIntDen", 0) / area;
max=getResult("Max", 0) ;
print("Pee_Pixels	Average_Distance");
print(area+"	"+avedis);


// get Histogram
print("");
print("Distance	Pixel#");
selectImage("EDM of distance");
getHistogram(values, counts, max);
for(i=1; i<values.length; i++)
   print(values[i]+"	"+counts[i]);

selectImage("EDM of distance");
run("Histogram", "bins="+max+" use x_min=1 x_max="+max+" y_max=Auto");
selectImage("Histogram of EDM");
saveAs("Tiff", dir+name+"_histogram.tif");

run("Close All");
run("Clear Results");
roiManager("reset");
selectWindow("Log");
saveAs("Text", dir+name+"_Distance.txt");
selectWindow("Log"); run("Close");


// get  spot #.
open(dir+name+"_mask.tif");
rename("mask");

run("Duplicate...", "title=spot");
run("Watershed");
run("Analyze Particles...", "size="+minspotsize+"-Infinity clear add");
spotcount=roiManager("Count");
roiManager("reset");
selectImage("spot"); close();


// get Y direction
run("Subtract...", "value=254");
run("Reslice [/]...", "output=1.000 start=Left avoid");
run("Z Project...", "projection=[Sum Slices]");
selectImage("Reslice of mask"); close();
selectImage("mask"); close();

print(dir+name);
print("Spot#	"+spotcount);
print("Center_X	"+x+"	Center_Y	"+y);
print("YDis	UP	Down	Total");
for(i=0;i<max;i++)
 {
  up=getPixel(y-i,0); 
  down=getPixel(y+i,0); 
  if( i==0 ) print(i+"	"+up+"	"+down+"	"+up);
  else print(i+"	"+up+"	"+down+"	"+(up+down));
 
 }
selectWindow("Log");
saveAs("Text", dir+name+"_Y_spot.txt");
selectWindow("Log"); run("Close");
close();