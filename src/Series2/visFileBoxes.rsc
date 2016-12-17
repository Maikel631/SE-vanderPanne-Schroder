module Series2::visFileBoxes

import Series2::Series2;
import Series2::trimCode;
import Series2::visUtilities;
import Series2::visualClones;

import vis::Figure;
import vis::KeySym;

import String;
import List;
import Map;
import Set;
import IO;
import util::Math;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;


private map[int, tuple[loc, int, int]] cloneExamples = ();
private map[loc, int] fileDupCounts = ();
private map[int, list[loc]] cloneClassDups = ();
private list[int] filteredClones = [];
private list[int] colorList = [];

/* === Getter related functions === */
public map[int, tuple[loc, int, int]] getCloneExamples() {
	return cloneExamples;
}

public map[int, list[loc]] getCloneClassDups(){
	return cloneClassDups; 
}

/* === Filter related functions === */
public map[loc, int] getFileDupCount() {
	return fileDupCounts;
}

public void hideAll(int maxClasses) {
	filteredClones = [1..maxClasses];
}

public void showAll() {
	filteredClones = [];
}

public void addToFilter(int classNum) {
	filteredClones += classNum;
}
public bool inFilter(int classNum) {
	return (classNum in filteredClones );
}

public void delFromFilter(int classNum) {
	filteredClones -= classNum;
}

/* === Figure functions === 
 * getFileBoxes creates all the file boxes and marks the duplicates into them.
 * The duplicate boxes overlap and can be turned off or on by the statistics menu.
 *
 * This main function creates the duplicate boxes and combines them with the fileboxes.
 * Other statistics are also calculated on the way.
 */
public Figure getFileBoxes(set[set[loc]] duplicateClasses) {
	/* Retrieve clone classes, files affected by clones and their length. */
	cloneExamples = ();
	set[loc] filesWithClones = {pathToLoc(fileLoc.path) | fileLoc <- union(duplicateClasses)};
	map[loc, real] fileLengths = (
		fileLoc : toReal(size(readFileLines(fileLoc))) | fileLoc <- filesWithClones
	);
	
	/* Create boxes for all duplicates and map them per file. */
	map[loc, list[Figure]] fileBoxMap = ();
	map[loc, list[loc]] fileDups = ();
	int classNum = 1;

	M3 model = getCurProject();
	if (size(colorList) != size(duplicateClasses))
		colorList = [];

	for (dupClass <- duplicateClasses) {
		/* Keep colors list always the same when redrawing everything. */
		if (size(colorList) != size(duplicateClasses))
			colorList += color(colorNames()[arbInt(size(colorNames()))], 0.6);
		randColor = colorList[classNum - 1];
		
		/* All boxes for each dupClass have the same color. */
		for (dup <- dupClass) {
			/* Determine the size and offset for displaying the box. */		
			startOffset = dup.begin.line / fileLengths[pathToLoc(dup.path)];
			lengthOffset = (dup.end.line - dup.begin.line) / fileLengths[pathToLoc(dup.path)];

			/* Create box for this duplicate, add it to the appropriate bin. */
			fileBox = box(
				fillColor(randColor),
				align(0, startOffset),
				vshrink(lengthOffset),
				lineColor(randColor),
				getMouseDownAction(dup),
				getMouseOverBox(" Class: <classNum> - Clone found on lines <dup.begin.line> - <dup.end.line> SLOC size: <countLOC(dup, model)> ", bottom())
			);

			if (classNum notin cloneExamples) {
				cloneExamples[classNum] = <dup, countLOC(dup, model), randColor>;
				cloneClassDups[classNum] = [dup];
			}
			else
				cloneClassDups[classNum] += [dup];

			/* Add box to appropriate file 'bin'. */
			loc dupKey = pathToLoc(dup.path);
			if (dupKey in fileBoxMap) {
				if (classNum notin filteredClones)
					fileBoxMap[dupKey] += fileBox;
				fileDups[dupKey] += dup;
			}
			else {
				if (classNum notin filteredClones)
					fileBoxMap[dupKey] = [fileBox];
				fileDups[dupKey] = [dup];
			}
		}
		classNum += 1;
	}
	fileDupCounts = calculateCodeDupLines(fileDups);
	list[Figure] boxes = createFileBoxes(fileBoxMap, fileLengths, fileDupCounts);
	
	/* Render all fileBoxes which contain duplicate boxes. */
	return hcat(boxes);
}


/* Merge the file offset intervals into larger offset, so the countLOC function
 * can be executed more efficiently. 
 */
public map[loc, int] calculateCodeDupLines(map[loc, list[loc]] fileDups) {
 	 fileDupCounts = ();
	 M3 project = getCurProject();
	 for (f <- fileDups) {
	 	rel[int, int] temp = {<dup.offset, dup.offset + dup.length> | dup <- fileDups[f]};
	 	/* Merge the file intervals and sum the difference between them to get the total
	 	 * number of duplicate lines per file. 
	 	 */
	 	for (<offsetStart, offsetEnd> <- mergeIntervals(temp)) {
			dupFile = fileDups[f][0];
	 		
	 		dupFile.offset = offsetStart;
	 		dupFile.length = offsetEnd - offsetStart;
	 		if (f in fileDupCounts)
	 			fileDupCounts[f] += countLOC(dupFile, project);
	 		else
	 			fileDupCounts[f] = countLOC(dupFile, project);
	 	}
	 }
	 return fileDupCounts;
}

/* Merge a list of integer intervals to one single interval list
 * Based on codereview.stackexchange.com/questions/69242 
 */
public lrel[int, int] mergeIntervals(rel[int,int] intervals) {
	lrel[int, int] mergedIntervals = [];
	/* Sort all the intervals, so the first index will always be the smallest. */
	lrel[int, int] sortedIntervals = sort(intervals);
	
	mergedIntervals += sortedIntervals[0];
	for (higher <- sortedIntervals[1..]) {
		tuple[int, int] lower = mergedIntervals[-1];
		
		if (higher[0] <= lower[1]) {
			int upp = max(lower[1], higher[1]);
			/* Replace last element from list to merged one.  */
			mergedIntervals = delete(mergedIntervals, size(mergedIntervals) - 1);
			mergedIntervals += <lower[0], upp>;
		}
		else {
			if (higher notin mergedIntervals)
				mergedIntervals += higher;
		}
	}
	return mergedIntervals;
}

/* Create the file boxes which contain the duplication boxes. */
public list[Figure] createFileBoxes(map[loc, list[node]] fileBoxMap, map[loc, real] fileLengths, map[loc, int] fileDupCounts) {
	/* Normalize the file lenghts, determine the boxes' heights and offsets. */
	real normalizer = toReal(max([fileLengths[f] | f <- fileLengths]));
	map[loc, real] heightBoxes = (f : fileLengths[f] / normalizer | f <- fileLengths);
	real offsetWidth = 1.0 / toReal(size(fileLengths) - 1);
	real widthBoxes = 1.0 / toReal(size(fileLengths)) - 0.005;

	int i = 0;
	boxes = [];
	real infoBoxSize = 0.1;
	for (f <- fileBoxMap) {
		nestedBoxes = reverse(fileBoxMap[f]);
		/* Create a fileBox which encompasses the duplicates boxes. */
		fileBox = box(
			overlay(nestedBoxes),
			size(150, round(fileLengths[f] * 1.2)),
			fillColor(gray(230)),
			align(i * offsetWidth, infoBoxSize),
			getMouseDownAction(f),
			lineColor(gray(200))
		);
		
		str fileName = intercalate("/", split("/", f.path)[-3..]);;
		str mouseOverText = " File: <fileName> \n";
		mouseOverText += " Length: <toInt(fileLengths[f])> lines \n";
		mouseOverText += " Num clones found: <size(fileBoxMap[f])> \n";
		mouseOverText += " Number of clone lines (SLOC): <fileDupCounts[f]> ";
		
		infoBox = box( text(f.file, fontSize(8)),
			fillColor("white"),
			size(150, 20),
			lineColor(rgb(202, 220, 249)),
			align(i * offsetWidth, 0),
		    getMouseDownAction(f),
		    vresizable(false),
		    getMouseOverBox(mouseOverText, center())
		);
		
		fileBox = vcat([infoBox, fileBox], resizable(false), top(), vgap(2));
		i += 1;
		boxes += fileBox;
	}
	return boxes;
}