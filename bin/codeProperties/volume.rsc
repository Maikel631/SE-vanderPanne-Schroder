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

public int getVolumeScore(eclipseModel) {
	/* Determine all source files of the project. */
	str srcType = "java+compilationUnit";
	set[loc] srcFiles = {e | <e, _> <- eclipseModel@declarations, e.scheme == srcType};

	/* Calculate LOC in all files, from which the rating is calculated. */
	int totalLOC = sum([countLOC(srcFile, eclipseModel) | srcFile <- srcFiles]);
	int rating = volumeRating(totalLOC);
	
	println("Lines of code: <totalLOC>");
	println("Volume rating: <rating>\n");
	return rating;
}

public int volumeRating(int totalLOC) {
	/* Based on the amount of KLOC, a rating is assigned. */
	list[int] thresholds = [66, 246, 665, 1310];
	real kloc = totalLOC / 1000.0;
	if (kloc < 0)
		return -1;
	
	/* Iterate over the thresholds, assign the correct rating. */
	int rating = 5;
	for (threshold <- thresholds) {
		if (kloc > threshold)
			rating -= 1;
	}
	return rating;
}

public int countLOC(location, eclipseModel) {
	/* Remove comments and whitespace, return line count. */
	strippedContents = trimCode(location, eclipseModel);
	return size(split("\n", strippedContents));
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