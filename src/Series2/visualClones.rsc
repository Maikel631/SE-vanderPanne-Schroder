module Series2::visualClones

import Series2::Series2;
import Series2::trimCode;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import util::Eval;
import util::Math;
import util::Editors;
import Traversal;
import String;
import Node;
import Type;
import List;
import Map;
import Set;
import Relation;
import IO;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

/* Read in and evaluate the duplicate classes. */
public set[set[loc]] readDuplicates() {
	contents = readFile(|project://Software%20Evolution/src/Series2/result|);
	contents = replaceAll(contents, " ", "%20");
	visit (eval(contents)) {
		case set[set[loc]] a: return a;
	};
}

/* Workaround to open Eclipse window. */
public void openWindow(loc f) {
	list[LineDecoration] ld = [];
	try {
		f.begin;
		ld = [info(l, "Here") | l <- [f.begin.line..f.end.line+1]];
	}
	catch: ld = [info(1, "Here")];
	
	edit(f, ld);
}

/* Convert file path to loc variable. */
public loc pathToLoc(str path) {
	/* Convert spaces in path to "%20". */
	path = replaceAll(path, " ", "%20");
	return toLocation("file://<path>");
}

public void visualizeClones() {
	/* Retrieve clone classes, files affected by clones and their length. */
	set[set[loc]] duplicateClasses = readDuplicates();
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
	render(hcat(boxes));
}

public list[int] calculateCodeDupLines(map[loc, list[loc]] fileDups) {
	 list[int] fileDupCounts = [];
	 for (f <- fileDups) {
	 	rel[int, int] temp = {<dup.begin.line, dup.end.line> | dup <- fileDups[f]};
	 	/* Merge the file intervals and sum the difference between them to get the total
	 	 * number of duplicate lines per file. 
	 	 */
	 	println(mergeIntervals(temp));
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
	real infoBoxSize = 0.01;
	for (f <- fileBoxMap) {
		nestedBoxes = reverse(fileBoxMap[f]);
		/* Create a fileBox which encompasses the duplicates boxes. */
		fileBox = box(
			overlay(nestedBoxes),
			size(100, round(fileLengths[f]) * 1.2),
			vresizable(false),
			fillColor(gray(230)),
			align(i * offsetWidth, infoBoxSize),
			shrink(0.99, heightBoxes[f] - infoBoxSize),
			getMouseDownAction(f),
			lineColor(gray(200))
		);
		
		str fileName = intercalate("/", split("/", f.path)[-3..]);;
		str mouseOverText = " File: <fileName> \n";
		mouseOverText += " Length: <toInt(fileLengths[f])> lines \n";
		mouseOverText += " Num clones found: <size(fileBoxMap[f])> \n";
		mouseOverText += " Number of clone lines: <fileDupCounts[i]> ";
		
		infoBox = box( text("File information", fontSize(8)),
			fillColor("white"),
			size(100, 20),
			lineColor(rgb(202, 220, 249)),
			align(i * offsetWidth, 0),
			shrink(0.99, infoBoxSize),
		    vgap(2),
		    getMouseDownAction(f),
		    getMouseOverBox(mouseOverText, center())
		);
		
		fileBox = vcat([infoBox, fileBox]);
		i += 1;
		boxes += fileBox;
	}
	return boxes;
}

public FProperty getMouseDownAction(loc f) {
	return onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
		openWindow(f);
		return true;
	});
}

public FProperty getMouseOverBox(str boxText, FProperty alignment) {
	return (onMouseOver(box(
			text(boxText, align(0,0)),
		    alignment, vshrink(0.1), fillColor(rgb(251, 255, 147, 0.8))
	)));
}