module Series2::visUtilities

import Series2::trimCode;

import util::Eval;
import util::Math;
import vis::Figure;
import vis::KeySym;
import Set;
import List;
import String;
import IO;
import util::Editors;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

/* Read in and evaluate the duplicate classes. */
public set[set[loc]] readDuplicates(loc filePath) { 
	contents = readFile(filePath);
	contents = replaceAll(contents, " ", "%20");
	visit (eval(contents)) {
		case set[set[loc]] a: return a;
	};
}

/* Convert file path to loc variable. */
public loc pathToLoc(str path) {
	/* Convert spaces in path to "%20". */
	path = replaceAll(path, " ", "%20");
	return toLocation("file://<path>");
}

public map[str, int] calcStats(set[set[loc]] cloneClasses, M3 eclipseModel) {
	map[str, int] cloneStats = (
		"numClones": 0, "numCloneClasses": 0,
		"bigClone": 0, "bigCloneClass": 0
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
		if (cloneClassSize > cloneStats["bigCloneClass"])
			cloneStats["bigCloneClass"] = cloneClassSize;
	}
	return cloneStats;
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

public bool intInput(str s){
	return /^[0-9]+$/ := s;
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