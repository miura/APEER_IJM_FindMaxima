/*
  ImageJ macro for segmenting image stack using Find Maxima command 
  using virtual stacks to conserver RAM   so in theory even large number if images files --> stacks should work
  based on example generate_stack.ijm
  
  MIT License
  Copyright (c) 2020 Kota Miura
 */

// General global vars
RESULTSPATH = "/output/";
BATCHMODE = "true";
VERBOSE = true;
libmacro = "/apeerlib.ijm";

// Read JSON Variables
WFE_JSON = runMacro( libmacro , "captureWFE_JSON");

// sys exit if we cannot load oparameters. 
if ( WFE_JSON == ""){
	call("CallLog.shout", "WFE parameters cannot be found... exiting...");
	eval("script", "System.exit(0);");
}

// Read JSON WFE Parameters
JSON_READER = "/JSON_Read.js";
runMacro( libmacro , "checkJSON_ReadExists;" + JSON_READER);

call("CallLog.shout", "Reading JSON Parameters");

// Get WFE Json values as global vars
/*INPUTFILES = runMacro(JSON_READER, "settings.input_files[0]");*/
INPUTSTACK = runMacro(JSON_READER, "settings.input_files[0]");
PREFIX = ".tif";//runMacro(JSON_READER, "settings.prefix");
STACKNAME = runMacro(JSON_READER, "settings.output_filename");
WFEOUTPUT = runMacro(JSON_READER, "settings.WFE_output_params_file");
PARA_PROMINENCE = runMacro(JSON_READER, "settings.prominence");
PARA_PROMINENCE = parseFloat( PARA_PROMINENCE );
PARA_GAUSS_SIGMA = runMacro(JSON_READER, "settings.gaussian_filter_sigma");
PARA_GAUSS_SIGMA = parseFloat( PARA_GAUSS_SIGMA );

// Getting input file path from WFE input_files
path_substring = lastIndexOf(INPUTSTACK, "/");
IMAGEDIR_WFE = substring(INPUTSTACK, 0, path_substring+1);
if (VERBOSE) call("CallLog.shout", "IMAGE: " + INPUTSTACK);
if (VERBOSE) call("CallLog.shout", "IMAGEDIR_WFE: " + IMAGEDIR_WFE);

main();

function main() {
	tt = runMacro( libmacro , "currentTime");
	call("CallLog.shout", "Starting opening files, time: " + tt);
	
	if (BATCHMODE=="true") {
		setBatchMode(true);
	}

 	importData();
 	call("CallLog.shout", "... image opened");
	// Parameters
	GaussianBlurRad = PARA_GAUSS_SIGMA;//1.5;	// Gaussian filter radius
	NoiseTol = PARA_PROMINENCE;//7.0;
	call("CallLog.shout", "start Processing");		
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
 	//jsonOutV2();
 	filelist = STACKNAME + ".tif"; //used for JSON out
 	jsonarg = "JSON_OUT;" + RESULTSPATH + "," + filelist;
 	call("CallLog.shout", "...JSON args:" + jsonarg);
 	out = runMacro( libmacro , jsonarg);
 	call("CallLog.shout", "... JSON out written: " + out);
 	

	//call("CallLog.shout", "DONE! " + currentTime());
	tt = runMacro( libmacro , "currentTime");
	call("CallLog.shout", "Finished processing, time: " + tt);
	run("Close All");
	call("CallLog.shout", "Closed");
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

