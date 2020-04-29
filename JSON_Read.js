/*
 *  JSON read JSON and return the supplied key
 *  Robert Kirmse
 */

importClass(Packages.ij.IJ);

function readJSON(call) {

    //Path to the WFE_input_params.json
    var jsonDir = "/params/WFE_input_params.json";
    var f = new java.io.File( jsonDir );
    if ( f.exists() ){
        var settings = JSON.parse(IJ.openAsString(jsonDir));
        // var allPropertyNames = Object.keys(settings);	// put JSON keys in new Array
        // var count = Object.keys(settings).length;		// count number of JSON keys
    } else {
        var settings = JSON.parse( java.lang.System.getenv()['WFE_INPUT_JSON'] );
    }
    return (eval(call));
}

var arg = getArgument();
readJSON(arg);
