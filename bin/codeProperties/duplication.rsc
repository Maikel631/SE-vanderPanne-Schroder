/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  duplication.rsc
 *        This file contains functions to calculate the number of lines of
 *        code that occurs more than once in equal code blocks of at least
 *        6 lines. In our methods, these blocks are referred to as 'snippets'.
 *
 *        The percentage of all code that consists of duplicated code is then
 *        calculated and turned into a 1-5 score using a scoring table.
 *
 * USAGE: import 'codeProperties::duplication' to use the functions.
 */
module codeProperties::duplication

import List;
import String;

import lang::java::m3::Core;
import codeProperties::volume;

public int findDuplicates(M3 eclipseModel) {
	str srcType = "java+compilationUnit";
	set[loc] srcFiles = {e | <e, _> <- eclipseModel@declarations, e.scheme == srcType};
	
	int linesDuplicated = 0;
	map[str, bool] snippetList = ();
	
	int frameSize = 6;
	for (srcFile <- srcFiles) {
		/* Split method in snippets, if method is smaller than 6 lines: skip it. */
		list[str] snippets = createDupSnippets(srcFile, frameSize, eclipseModel);
		if (isEmpty(snippets))
			continue;

		int dupLinesCount = 0;
		bool dupFound = false;
		for (snippet <- snippets) {
			/* Check if snippet is already added to the snippet list,
			 * if it is, a duplicate is found. If upfollowing snippets
			 * also are in this list, a duplication of a larger area is found.
			 */
			if (snippet in snippetList) {
				if (dupFound == false) {
					dupFound = true;
					/* When this snippet is not found as duplicate yet;
					 * frameSize * 2 lines has to be added to count all duplicated
					 * lines. Else add frameSize once. 
					 */
					dupLinesCount = (snippetList[snippet]) ? frameSize : frameSize * 2;
				}
				/* Next duplicate matches --> so add a single line count
				 * or double line count when not found earlier. 
				 */
				else
					dupLinesCount += (snippetList[snippet]) ? 1 : 2;
				snippetList[snippet] = true;
			}
			else {
				/* Unknown snippet, check for later instances if it can match. */
				snippetList[snippet] = false;
				if (dupFound) {
					linesDuplicated += dupLinesCount;
					dupFound = false;
				}
			}
		}
		if (dupFound)
			linesDuplicated += dupLinesCount;
	}
	return linesDuplicated;
}

public list[str] createDupSnippets(loc location, int frameSize, M3 eclipseModel) {
	str strippedContents = trimCode(location, eclipseModel);
	
	/* Split stripped content and larger than frameSize lines. */
	list[str] lines = split("\n", trim(strippedContents));
	if (size(lines) < frameSize)
		return [];
	
	/* Trim lines to get rid of whitespace. */
	trimmedLines = [trim(line) | line <- lines];
	return for (i <- [0..size(trimmedLines) - frameSize + 1]) {
		append intercalate("", trimmedLines[i..i+frameSize]);
	}
}