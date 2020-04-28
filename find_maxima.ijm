/*
  ImageJ macro for segmenting image stack using Find Maxima command 
  using virtual stacks to conserver RAM   so in theory even large number if images files --> stacks should work
  based on example generate_stack.ijm
 */

// General global vars
RESULTSPATH = "/output/";
BATCHMODE = "true";

// Read JSON Variables
call("CallLog.shout", "calllog Trying to read WFE_JSON");

WFE_file = "/params/WFE_input_params.json";
if (!File.exists(WFE_file)) {
	call("CallLog.shout", "WFE_input_params.json does not exist... exiting...");
	eval("script", "System.exit(0);");
	} 
	else {
		call("CallLog.shout", "WFE_input_params.json found... reading file...");
		WFE_JSON = File.openAsString(WFE_file);
	}
	
call("CallLog.shout", "WFE_JSON contents: " + WFE_JSON);

// Read JSON WFE Parameters
JSON_READER = "/JSON_Read.js";

if (!File.exists(JSON_READER)) {
	call("CallLog.shout", "JSON_Read.js does not exist... exiting...");
	eval("script", "System.exit(0);");
	} 
	else {
		call("CallLog.shout", "JSON_Read.js found... reading file...");
	}

call("CallLog.shout", "Reading JSON Parameters");

// Get WFE Json values as global vars
/*INPUTFILES = runMacro(JSON_READER, "settings.input_files[0]");*/
INPUTSTACK = runMacro(JSON_READER, "settings.input_files[0]");
PREFIX = ".tif"//runMacro(JSON_READER, "settings.prefix");
STACKNAME = runMacro(JSON_READER, "settings.output_filename");
WFEOUTPUT = runMacro(JSON_READER, "settings.WFE_output_params_file");
PARA_PROMINENCE = runMacro(JSON_READER, "settings.prominence");
PARA_PROMINENCE = parseFloat( PARA_PROMINENCE );
PARA_GAUSS_SIGMA = runMacro(JSON_READER, "settings.gaussian_filter_sigma");
PARA_GAUSS_SIGMA = parseFloat( PARA_GAUSS_SIGMA );

// Getting input file path from WFE input_files
path_substring = lastIndexOf(INPUTSTACK, "/");
IMAGEDIR_WFE = substring(INPUTSTACK, 0, path_substring+1);

main();

function main() {
	call("CallLog.shout", "Starting opening files, time: " + currentTime());
	
	if (BATCHMODE=="true") {
		setBatchMode(true);
	}

 	importData();
	// Parameters
	GaussianBlurRad = PARA_GAUSS_SIGMA;//1.5;	// Gaussian filter radius
	NoiseTol = PARA_PROMINENCE;//7.0;		
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	run("Set Measurements...", "  mean centroid median redirect=None decimal=2");
	InitialStackID = getImageID();
	InitialStackTitle = getTitle();	
	// Copy stack + pre-filtering
	run("Duplicate...", "title=Copy duplicate range=1-"+d2s(nSlices,0));
	run("Gaussian Blur...", "sigma="+d2s(GaussianBlurRad,2)+" stack");
	rename("PreProcessed");
	// Binary mask generation (apply seeded watershed to all slices)
	newImage("ParticlesStack", "8-bit Black", getWidth(), getHeight(), nSlices);
	for(i=1;i<=nSlices;i++) {
		selectImage("PreProcessed");
		setSlice(i);
		run("Find Maxima...", "noise="+d2s(NoiseTol,2)+" output=[Segmented Particles] light");
		rename("Particles");
		run("Copy");
		selectImage("ParticlesStack");
		setSlice(i);
		run("Paste");
		selectImage("Particles");
		close();
	}
	selectImage("ParticlesStack");
	run("Invert", "stack");
	selectImage("PreProcessed");
	close();
	selectImage("ParticlesStack");
	run("Select None");
	run("Merge Channels...", "red=ParticlesStack green=*None* blue=*None* gray="+InitialStackTitle+" create keep");
	rename("Segmentation overlay");
	selectImage("ParticlesStack");
	close();
	
 	savingStack();
 	jsonOut();

	call("CallLog.shout", "DONE! " + currentTime());
	run("Close All");
	call("CallLog.shout", "Closed");
	shout("test print");
	print( "test macro print command" );
	eval("script", "System.exit(0);");
}

function importData() {
	call("CallLog.shout", "Importing Data");
	
	if (PREFIX == "no-filter") {
		call("CallLog.shout", "opening image stack in: "+ IMAGEDIR_WFE + " with no filter");
		//run("Image Sequence...", "open=" +IMAGEDIR_WFE +"  sort use");
		open( INPUTSTACK );
	}
	else {
		call("CallLog.shout", "opening  image stack in: "+ IMAGEDIR_WFE + " with filter: " + PREFIX);
		//run("Image Sequence...", "open=" +IMAGEDIR_WFE +" file="+ PREFIX +" sort use");
		open( INPUTSTACK );
	}
}

function savingStack() {
	if (STACKNAME=="output") {
		call("CallLog.shout", "writing tif stack with default name: output.tif");
		saveAs("Tiff", "/output/output.tif");
	}
	else {
		call("CallLog.shout", "writing tif stack with user name: " + STACKNAME + ".tif");
		saveAs("Tiff", "/output/" + STACKNAME + ".tif");
	}
}

// Generate output.json for WFE
function jsonOut() {
	call("CallLog.shout", "Starting JSON Output");
	jsonout = File.open(RESULTSPATH + "json_out.txt");
	call("CallLog.shout", "File open: JSON Output");
	
	print(jsonout,"{");
	print(jsonout,"\"RESULTSDATA\": [");

	if (STACKNAME=="output") {
		print(jsonout,"\t\"/output/output.tif\"");
	}
	else {
		print(jsonout,"\t\"/output/"+ STACKNAME + ".tif\"");
	}
	print(jsonout,"\t]");
	print(jsonout,"}");
	File.close(jsonout);
	File.rename(RESULTSPATH + "json_out.txt", RESULTSPATH + WFEOUTPUT);
	
	call("CallLog.shout", "Done with JSON Output");
}

/*
 * functions for support tasks
 */
// Get SystemTimer
 function currentTime() {
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");

     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

     timeString = DayNames[dayOfWeek]+" ";

     if (dayOfMonth<10) {timeString = timeString + "0";}
     timeString = timeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+" @ ";

     if (hour<10) {timeString = timeString + "0";}
     timeString = timeString+hour+":";

     if (minute<10) {timeString = timeString + "0";}
     timeString = timeString+minute+":";

     if (second<10) {timeString = timeString + "0";}
     timeString = timeString+second;

     return timeString;
} 

function shout( out ){
	sc = "java.lang.System.out.println( '" + out + "' )";
	eval("js", sc);
} 
