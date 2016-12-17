/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  trimCode.rsc
 *        This file contains functions to strip a source file's contents
 *        from whitespace lines and comments, after which the linecount
 *        can be determined. 
 *
 *        The line count is not always accurate as not always all comment locations
 *        are retrieved through the M3 model. So, the count is sometimes too high.  
 *        The volumeIndex map is used to 'cache' some of the earlier line count calculation
 *        of files and methods. The cache can be cleared with the clearIndex() function. 
 *
 * USAGE: import 'Series2::duplication::trimCode' to use the functions.
 */

module Series2::duplication::trimCode

import IO;
import List;
import Set;
import String;
import ParseTree;

import lang::java::jdt::m3::Core;

private map[loc, int] volumeIndex = ();
public void clearIndex() {
	volumeIndex = ();
}

public int getVolume(eclipseModel) {
	set[loc] srcFiles = files(eclipseModel);
	return sum([countLOC(srcFile, eclipseModel) | srcFile <- srcFiles]);
}

public int countLOC(loc location, M3 eclipseModel) {
	/* If the location is not a file location, translate it. */
	if (location.scheme != "java+compilationUnit" && location.scheme != "file")
		location = convertToLoc(location, eclipseModel);

	/* Try to retrieve cached LOC. */
	if (location in volumeIndex) {
		return volumeIndex[location];
	}

	/* Remove comments and whitespace, return line count. */
	strippedContents = trimCode(location, eclipseModel);
	int numLines = size(split("\n", strippedContents));
	
	/* Cache the LOC. */
	volumeIndex[location] = numLines;
	return numLines;
}

public loc convertToLoc(method, model) {
	/* Convert a location to a 'file' typed location. */
	list[loc] locList = toList(model@declarations[method]);
	if (isEmpty(locList))
		return |file:///null|;
	return locList[0];
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(location, eclipseModel) {
	/* Determine all comment entries for this file. Use the comment offset
	 * to sort them. By sorting we can always remove the first occurrence.
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

