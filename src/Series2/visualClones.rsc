module Series2::visualClones

import Series2::Series2;
import Series2::trimCode;
import vis::Figure;
import vis::Render;
import vis::KeySym;

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

public void main(M3 eclipseModel) {
	/* Retrieve clone classes, files affected by clones and their length. */
	set[set[loc]] duplicateClasses = findDuplicatesAST(eclipseModel);
	set[loc] filesWithClones = {pathToLoc(fileLoc.path) | fileLoc <- union(duplicateClasses)};
	map[loc, real] fileLengths = (
		fileLoc : toReal(size(readFileLines(fileLoc))) | fileLoc <- filesWithClones
	);
	
	/* Create boxes for all duplicates and map them per file. */
	map[loc, list[node]] fileBoxMap = ();
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
				getMouseDownAction(dup),
				getMouseOverBox(" Class: <classNum> - Clone found on lines <dup.begin.line> - <dup.end.line> ", bottom())
			);

			/* Add box to appropriate file 'bin'. */
			if (pathToLoc(dup.path) in fileBoxMap)
				fileBoxMap[pathToLoc(dup.path)] += fileBox;
			else
				fileBoxMap[pathToLoc(dup.path)] = [fileBox];
		}
		classNum += 1;
	}
	
	/* Normalize the file lenghts, determine the boxes' heights and offsets. */
	real normalizer = toReal(max([fileLengths[f] | f <- fileLengths]));
	map[loc, real] heightBoxes = (f : fileLengths[f] / normalizer | f <- fileLengths);
	real offsetWidth = 1.0 / toReal(size(fileLengths) - 1);
	real widthBoxes = 1.0 / toReal(size(fileLengths)) - 0.005;

	int i = 0;
	boxes = [];
	real infoBoxSize = 0.03;
	for (f <- fileBoxMap) {
		nestedBoxes = reverse(fileBoxMap[f]);
		/* Create a fileBox which encompasses the duplicates boxes. */
		fileBox = box(
			overlay(nestedBoxes),
			fillColor(gray(230)),
			align(i * offsetWidth, infoBoxSize),
			shrink(0.99, heightBoxes[f] - infoBoxSize),
			getMouseDownAction(f)
		);
		
		infoBox = box( text("File information", fontSize(5)),
			fillColor("white"),
			align(i * offsetWidth, 0),
			shrink(0.99, infoBoxSize),
		    vgap(2),
		    getMouseDownAction(f),
		    getMouseOverBox(" File information \n File: <f.path> \n Num clones found: <size(fileBoxMap[f])> ", center())
		);
		
		fileBox = vcat([infoBox, fileBox]);
		i += 1;
		boxes += fileBox;
	}
	
	/* Render all fileBoxes which contain duplicate boxes. */
	render(hcat(boxes));
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