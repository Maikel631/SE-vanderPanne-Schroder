module Series2::visFileBoxes

import Series2::Series2;
import Series2::trimCode;
import Series2::visUtilities;
import Series2::visualClones2;

import vis::Figure;
import vis::KeySym;

import util::Eval;
import util::Math;
import Traversal;
import String;
import Node;
import Type;
import List;
import Map;
import Set;
import Relation;
import IO;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;


private map[int, tuple[loc, int, int]] cloneExamples = ();

public map[int, tuple[loc, int, int]] getCloneExamples() {
	return cloneExamples;
}



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

	for (dupClass <- duplicateClasses) {
		randColor = color(colorNames()[arbInt(size(colorNames()))], 0.6);
		
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
				getMouseOverBox(" Class: <classNum> - Clone found on lines <dup.begin.line> - <dup.end.line> Size: <dup.end.line - dup.begin.line> ", bottom())
			);

			if (classNum notin cloneExamples)
				cloneExamples[classNum] = <dup, 3, randColor>;

			/* Add box to appropriate file 'bin'. */
			loc dupKey = pathToLoc(dup.path);
			if (dupKey in fileBoxMap) {
				fileBoxMap[dupKey] += fileBox;
				fileDups[dupKey] += dup;
			}
			else {
				fileBoxMap[dupKey] = [fileBox];
				fileDups[dupKey] = [dup];
			}
		}
		classNum += 1;
	}
	list[int] fileDupCounts = calculateCodeDupLines(fileDups);
	list[Figure] boxes = createFileBoxes(fileBoxMap, fileLengths, fileDupCounts);
	
	/* Render all fileBoxes which contain duplicate boxes. */
	return hcat(boxes);
}



public list[int] calculateCodeDupLines(map[loc, list[loc]] fileDups) {
	 list[int] fileDupCounts = [];
	 for (f <- fileDups) {
	 	rel[int, int] temp = {<dup.begin.line, dup.end.line> | dup <- fileDups[f]};
	 	/* Merge the file intervals and sum the difference between them to get the total
	 	 * number of duplicate lines per file. 
	 	 */
	 	fileDupCounts += sum([endF - startF |<startF, endF> <- mergeIntervals(temp)]);
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

public list[Figure] createFileBoxes(map[loc, list[node]] fileBoxMap, map[loc, real] fileLengths, list[int] fileDupCounts) {
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
			//shrink(0.99, heightBoxes[f] - infoBoxSize),
			getMouseDownAction(f),
			lineColor(gray(200))
		);
		
		str fileName = intercalate("/", split("/", f.path)[-3..]);;
		str mouseOverText = " File: <fileName> \n";
		mouseOverText += " Length: <toInt(fileLengths[f])> lines \n";
		mouseOverText += " Num clones found: <size(fileBoxMap[f])> \n";
		mouseOverText += " Number of clone lines: <fileDupCounts[i]> ";
		
		infoBox = box( text(f.file, fontSize(8)),
			fillColor("white"),
			size(150, 20),
			lineColor(rgb(202, 220, 249)),
			align(i * offsetWidth, 0),
			//shrink(0.99, infoBoxSize),
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