/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  visStatistics.rsc
 *        This file contains functions to calculate statistics about the
 *        that are shown in the visualization.
 *
 * USAGE: import 'Series2::visualization::visStatistics' to use the functions.
 */
module Series2::visualization::visStatistics

import IO;
import Map;
import Set;
import List;
import util::Math;

import vis::Figure;
import vis::KeySym;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import Series2::visualization::visualClones;
import Series2::visualization::visFileBoxes;
import Series2::visualization::visUtilities;
import Series2::duplication::trimCode;

public Figure statsScreen() {
	Figure resultHeader = text("  Results  ", vresizable(false), vsize(20), fontSize(20), left(), top());
	Figure resultStats = computeFigure(
		bool() {
			if (!redrawConfig)
				return false; 
			redrawConfig = false;
			return true;
		},
	Figure() {
			if (readCloneClasses())
				return resultsFigure(getDuplicateClasses());
			else
				return space();
		}
	);
	return box(vcat([resultHeader, resultStats], resizable(false), left(), top()), hsize(325), resizable(false), top(), left(), lineColor(gray(200)));
}

public map[str, int] calcStats(set[set[loc]] cloneClasses, M3 eclipseModel) {
	map[str, int] cloneStats = (
		"numClones": 0, "numCloneClasses": 0,
		"bigClone": 0, "bigCloneClassLines": 0, "biggestCloneClass": 0
	);

	/* Iterate over all clones to determine statistics. */
	for (cloneClass <- cloneClasses) {
		cloneClassSize = 0;
	
		for (clone <- cloneClass) {
			cloneStats["numClones"] += 1;
			cloneSize = countLOC(clone, eclipseModel);
			cloneClassSize += cloneSize;
			if (cloneSize > cloneStats["bigClone"])
				cloneStats["bigClone"] = cloneSize;
		}
		cloneStats["numCloneClasses"] += 1;
		if (cloneClassSize > cloneStats["bigCloneClassLines"]) {
			cloneStats["bigCloneClassLines"] = cloneClassSize;
			cloneStats["biggestCloneClass"] = cloneStats["numCloneClasses"];
		}
	}
	return cloneStats;
}

public Figure resultsFigure(set[set[loc]] duplicateClasses) {
	M3 model = getCurProject();
	int linesOfCode = getVolume(model);
	map[loc, int] fileDupCount = getFileDupCount();
	int linesOfCloneCode = sum([0] + [fileDupCount[f] | f <- fileDupCount]);
	
	real clonePercentage = (linesOfCode == 0) ? 0.0 : ((linesOfCloneCode / toReal(linesOfCode)) * 100.0);
	map[str, int] stats = calcStats(duplicateClasses, model);
	
	list[Figure] resultFigures = [];
	Figure makeStatStr(str textStr) {
		return text(textStr, left(), vsize(12), vresizable(false));
	}

	resultFigures += makeStatStr(" Number of lines of code in project (SLOC): <linesOfCode> ");
	resultFigures += makeStatStr(" Number of clone lines in project (SLOC): <linesOfCloneCode> ");
	resultFigures += makeStatStr(" Clone percentage: <round(clonePercentage, 0.05)>% ");
	resultFigures += makeStatStr(" Number of clones: <stats["numClones"]> ");
	resultFigures += makeStatStr(" Number of clone classes: <stats["numCloneClasses"]> ");
	resultFigures += makeStatStr(" Biggest clone (SLOC): <stats["bigClone"]> ");
	resultFigures += makeStatStr(" Biggest clone class lines: <stats["bigCloneClassLines"]> ");
	resultFigures += makeStatStr(" Biggest clone class: <stats["biggestCloneClass"]> ");
	resultFigures += text(" Clone Legend  ", left(), fontSize(20));

	return vcat(resultFigures + createCloneLegend(3, duplicateClasses), top(), vresizable(false));
}

public Figure createCloneLegend(int numColumns, set[set[loc]] duplicateClasses) {
	map[int, tuple[loc, int, int]] cloneExamples = getCloneExamples();
	map[int, list[Figure]] legendColumns = (); 
	map[int, list[loc]] cloneClassDups = getCloneClassDups();

	Figure createLegendBlock(int classNum, <loc cloneLoc, int lineNum, int classColor>) {
		/* Create text based for the class color box. */
		str mouseOverText = "SLOC <lineNum> - Click for example on box.\n";
		mouseOverText += intercalate(",\n", ["<dupExample.file>" |dupExample <- cloneClassDups[classNum]]);
		Figure hider = createHiderBox(void() { delFromFilter(classNum); },
		                              void() { addToFilter(classNum);   }, inFilter(classNum));

		return hcat([text("<classNum>  - "),
		             box(fillColor(classColor), lineColor(classColor), size(10, 10),
		             getMouseDownAction(cloneLoc), resizable(false), right(), getMouseOverBox(mouseOverText, right()))
		             , hider],resizable(false), size(50, 12), vresizable(false), left());
	}

	int numClones = size(cloneExamples) + 1;
	for (cloneIndex <- [1..numClones]) {
		firstBlock = cloneExamples[cloneIndex];
		columnIndex = cloneIndex % numColumns;
		if (columnIndex in legendColumns)
			legendColumns[columnIndex] += createLegendBlock(cloneIndex, firstBlock);
		else
			legendColumns[columnIndex] = [createLegendBlock(cloneIndex, firstBlock)];
	}
	
	return hcat([vcat(legendColumns[col], resizable(false), left(), top()) | col <- legendColumns]);
}