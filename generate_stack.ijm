/*
  ImageJ Script to open sequences individual images   and safe these as a corresponding TIFF-Stack 
  using virtual stacks to conserver RAM   so in theory even large number if images files --> stacks should work
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
INPUTFILES = runMacro(JSON_READER, "settings.input_files[0]");
PREFIX = runMacro(JSON_READER, "settings.prefix");
STACKNAME = runMacro(JSON_READER, "settings.name");
WFEOUTPUT = runMacro(JSON_READER, "settings.WFE_output_params_file");

// Getting input file path from WFE input_files
path_substring = lastIndexOf(INPUTFILES, "/");
IMAGEDIR_WFE = substring(INPUTFILES, 0, path_substring+1);

main();

function main() {
	call("CallLog.shout", "Starting opening files, time: " + currentTime());
	
	if (BATCHMODE=="true") {
		setBatchMode(true);
	}

 	importData();
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
		call("CallLog.shout", "opening sequence in: "+ IMAGEDIR_WFE + " with no filter");
		run("Image Sequence...", "open=" +IMAGEDIR_WFE +"  sort use");
	}
	else {
		call("CallLog.shout", "opening sequence in: "+ IMAGEDIR_WFE + " with filter: " + PREFIX);
		run("Image Sequence...", "open=" +IMAGEDIR_WFE +" file="+ PREFIX +" sort use");
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