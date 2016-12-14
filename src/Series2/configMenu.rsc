module Series2::configMenu

import Series2::visUtilities;
import Series2::Series2;

import vis::Figure;
import List;
import util::Math;
import String;
import IO;

private map[loc, M3] eclipseProjectMap;
private M3 curProject;
private bool type2 = false;

public M3 getCurrentProject(str projectName) {
	loc projectLoc = toLocation("project://<projectName>");
	try {
		if (projectLoc notin eclispeProjectMap )
			eclispeProjectMap[projectLoc] = createM3FromEclipseProject(projectLoc);
		curProject = eclispeProjectMap[projectLoc];
		return curProject;
	}
	catch : {
		println("Invalid location given!");
		return curProject;
	}
}

public void startCloneDetection() {
	if (curProject?)
		findDuplicatesAST(curProject, type2);
}


public Figure createConfigMenu(list[str] vars, map[int, tuple[loc, int, int]] cloneExamples) {
	
	Figure header1 = text("  Configurations clone detector ", fontSize(16), top());
	Figure headerSep = box(vsize(4), fillColor(gray(220)), lineColor(gray(220)), vresizable(false));
	Figure lineSep = box(vsize(3), fillColor(gray(200)), lineColor("white"), vresizable(false));
	
	str entered = "";
	Figure projectField = vcat(
		[text("Project name: ", left()), 
		 textfield("", void(str s) {entered = s; println("<s>");})],
		vsize(80), vresizable(false), left());
	
	int numLines = 6;
	Figure numCodeLines = hcat([text("Num lines: ", left()), textfield("<numLines>", void(str s) {numLines = toInt(s); println("<s>");}, left(), hsize(30), hresizable(false))], vsize(80), resizable(false), left());
	
	Figure cloneType = vcat(
		[text("Clone type: ", left(), top()),
         choice(["1", "2"], void (str s) {type2 = s == "1" ? false : true; println("<s> - <type2>");}, left(), size(100, 60))],
	    resizable(false), left());
	
	Figure startButton = button(
		"Start clone detection",
	    void() {startCloneDetection();},
	    vresizable(false), vsize(50)
	);
	
	Figure resultHeader = text("  Results  ", fontSize(20));
	
	list[Figure] texts = [header1, headerSep, projectField, cloneType, numCodeLines, startButton, lineSep, resultHeader, headerSep];
	for (strText <- vars) {
		texts += text(" <strText> ", left(), fontSize(12));
	}
	texts += lineSep;
	
	
	int sizeBox = 50 + 10 * (size(texts) - 1);
	mainBox = vscrollable(box(vcat(texts), size(200, sizeBox), top(), vgap(2), resizable(false, false), lineColor(gray(200))));
	return mainBox;
}

//public Figure createCloneLegend(map[int, tuple[loc, int, int]] cloneExamples) {
//	list[Figure] cloneList = [];
//	
//	Figure createLegendBlock() {
//		continue;
//	}
//	
//	int numRows = ceil(size(cloneExamples) / 2.0);
//	for (rowNum <- [0,2..numRows]) {
//		firstBlock = cloneExamples[rowNum * 2];
//		Figure firstClones = 
//		
//		if (cloneExamples[rowNum * 2 + 1]?)
//			secondBlock = cloneExamples[rowNum * 2 + 1];
//		cloneList += hcat(firstBlock);
//	
//	}
//	return vcat(cloneList);
//}