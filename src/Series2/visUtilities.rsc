module Series2::visUtilities

import Series2::trimCode;
import Series2::visFileBoxes;
import Series2::visualClones;

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

/* Validate integer input. */
public bool intInput(str s){
	return /^[0-9]+$/ := s;
}

/* Workaround to get variables in loop working */
public FProperty getMouseDownAction(loc f) {
	return onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
		openWindow(f);
		return true;
	});
}

/* Wrapper function to get an MouseOver box*/
public FProperty getMouseOverBox(str boxText, FProperty alignment) {
	return (onMouseOver(box(
			text(boxText, align(0,0)),
		    alignment, 
		    vshrink(0.1), 
		    fillColor(rgb(251, 255, 147, 0.8)),
		    lineColor(gray(140))
	)));
}

/* Create an hider box figure executing
 * the void onPlus() function when on [+] and clicking on the text,
 * and onMin() when the text is [-].
 */
public Figure createHiderBox(void() onPlus, void() onMin, bool startPlus) {
	/* Add class hider */
	str hideText = startPlus ? "[+]" : "[-]";
	bool redrawFig = false;
	Figure hiderBox = computeFigure(
		bool () { 
			if (!redrawFig)
				return false;
			redrawFig = false;
		    return true;
	    }, 
		Figure() {
			return text(" <hideText> ", fontColor(gray(100)), right());
		},
		onMouseUp(bool (int butnr, map[KeyModifier, bool] modifiers) {
			if (hideText == "[-]")  {
				hideText = "[+]";
				onMin();
			} 
			else {
				hideText = "[-]";
				onPlus();
			}
			redrawAll();
			redrawFig = true;
			redrawBoxes = true;
			return true;
		})
	);
	return hiderBox;
}
