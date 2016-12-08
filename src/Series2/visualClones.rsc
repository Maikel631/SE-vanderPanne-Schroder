module Series2::visualClones

import Series2::Series2;
import Series2::trimCode;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import util::Math;
import util::Editors;
import List;
import Set;
import IO;


import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;


/* Workaround to open eclipse window. */
public void openWindow(loc file, str msg) {
	list[LineDecoration] ld = [];
	try {
		file.begin;
		ld = [info(l, msg) | l <- [file.begin.line..file.end.line+1]];
	}
	catch: ld = [info(1, msg)];
	
	edit(file, ld);
}

public void main(M3 eclipseModel) {
	list[loc] fileList = [convertToLoc(f, eclipseModel) | f <- files(eclipseModel)];
	
	int numFiles = size(fileList);
	list[int] lengthFiles = [size(readFileLines(f)) | f <- fileList];
	
	real normalizer = toReal(max(lengthFiles));
	list[real] heightBoxes = [height / normalizer | height <- lengthFiles];
	real offsetWidth = 1.0 / toReal(numFiles - 1);
	real widthBoxes = 1.0 / toReal(numFiles) - 0.005;
	
	boxes = [];
	for (i <- [0..numFiles]) {
		fileBox = box(
		   onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
		       openWindow(fileList[i], "Here");
		       return true;
	       }),
		   fillColor("red"), align(i * offsetWidth, 0), hshrink(widthBoxes), vshrink(heightBoxes[i]));
		boxes += fileBox;
	}
	render(overlay(boxes));
}