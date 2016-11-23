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
import Set;
import String;
import ParseTree;

import lang::java::jdt::m3::Core;

private map[loc, int] volumeIndex = ();
public void clearIndex() {
	volumeIndex = ();
}


public int getVolumeScore(M3 eclipseModel) {
	/* Calculate LOC in all files, from which the rating is calculated. */
	int totalLOC = getVolume(eclipseModel);
	int rating = volumeRating(totalLOC);
	
	println("=== Volume ===");
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

public int getVolume(eclipseModel) {
	set[loc] srcFiles = files(eclipseModel);
	return sum([countLOC(srcFile, eclipseModel) | srcFile <- srcFiles]);
}

public int countLOC(location, eclipseModel) {
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
