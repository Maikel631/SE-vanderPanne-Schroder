/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  volume.rsc
 *        This file contains functions to strip a source file's contents
 *        from whitespace lines and comments, after which the linecount
 *        can be determined.
 *
 * USAGE: import 'codeProperties::volume' to use the functions.
 */
module codeProperties::volume

import IO;
import List;
import String;

import lang::java::jdt::m3::Core;

public int countLOC(location, eclipseModel) {
	/* Remove comments from the source file. */
	strippedContents = trimCode(location, eclipseModel);

	/* Remove whitespace lines and return the line count. */
	return size(split("\n", strippedContents));
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(location, eclipseModel) {
	/* Determine all comment entries for this file. Use the comment offset
	 * sort them. By sorting we can always remove the first occurrence.
	 */
	commentLocs = sort([<f.offset, f> | <e, f> <- eclipseModel@documentation, f.file == location.file]);
	
	/* Remove all comments from the file source. */
	fileContent = readFile(location);
	for (<offset, commentLoc> <- commentLocs)
		fileContent = replaceFirst(fileContent, readFile(commentLoc), "");
    
    /* Remove all whitespace lines. */
    return visit(trim(fileContent)) {
 	    case /\s*\n/ => "\n"
    }
}