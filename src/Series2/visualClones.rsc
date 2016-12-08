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
	map[loc, list[node]] fileBoxMap = ();
	for (dupClass <- duplicateClasses) {
		randColor = color(colorNames()[arbInt(size(colorNames()))], 0.7);
		
		/* All boxes for each dupClass have the same color. */
		for (dup <- dupClass) {
			/* Determine the size and offset for displaying the box. */		
			startOffset = dup.begin.line / fileLengths[pathToLoc(dup.path)];
			lengthOffset = (dup.end.line - dup.begin.line) / fileLengths[pathToLoc(dup.path)];
			
			/* Create box for this duplicate, add it to the appropriate bin. */
			fileBox = nestedbbox(dup, randColor, startOffset, lengthOffset);

			/* Add box to appropriate file 'bin'. */
			if (pathToLoc(dup.path) in fileBoxMap)
				fileBoxMap[pathToLoc(dup.path)] += fileBox;
			else
				fileBoxMap[pathToLoc(dup.path)] = [fileBox];
		}
	}
	
	/* Normalize the file lenghts, determine the boxes' heights and offsets. */
	real normalizer = toReal(max([fileLengths[f] | f <- fileLengths]));
	map[loc, real] heightBoxes = (f : fileLengths[f] / normalizer | f <- fileLengths);
	real offsetWidth = 1.0 / toReal(size(fileLengths) - 1);
	real widthBoxes = 1.0 / toReal(size(fileLengths)) - 0.005;

	int i = 0;
	boxes = [];
	for (f <- fileBoxMap) {
		nestedBoxes = reverse(fileBoxMap[f]);
				
		/* Create a fileBox which encompasses the duplicates boxes. */
		fileBox = bbox(f, i, nestedBoxes, offsetWidth, widthBoxes, heightBoxes);
		
		i += 1;
		boxes += fileBox;
	}
	
	/* Render all fileBoxes which contain duplicate boxes. */
	render(overlay(boxes));
}

public Figure bbox(loc f, int i, list[node] nestedBoxes, real offsetWidth, real widthBoxes, map[loc, real] heightBoxes) {
	return box(
		overlay(nestedBoxes),
		fillColor("grey"),
		align(i * offsetWidth, 0),
		hshrink(widthBoxes),
		vshrink(heightBoxes[f]),
		onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
			openWindow(f);
			return true;
		})
	);
}

public Figure nestedbbox(loc f, int randColor, real startOffset, real lengthOffset) {
	return box(
		fillColor(randColor),
		align(0, startOffset),
		vshrink(lengthOffset),
		onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
			openWindow(f);
			return true;
		})
	);
}