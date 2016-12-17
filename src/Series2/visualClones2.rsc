module Series2::visualClones2

import Series2::visUtilities;
import Series2::visFileBoxes;
import Series2::Series2;
import Series2::trimCode;

import vis::Figure;
import vis::Render;
import String;
import List;
import util::Math;
import IO;
import Map;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;


private bool redrawConfig = false;
private bool redrawBoxes = false;
int count = 0;

private map[loc, M3] eclipseProjectMap = ();
private M3 curProject = emptyM3(|file://null|);
private int numLines = 6;
private bool type2 = false;

private set[set[loc]] duplicateClasses = {};

public M3 getCurProject() {
	return curProject;
}

public bool projectIsSet() {
	return (curProject.id != |file://null|);
}

private void redrawAll() {
	redrawConfig = true;
	redrawBoxes = true;
}

private bool readCloneClasses() {
	str typeDetection = (!type2) ? "type1" : "type2"; 
	loc filePath = toLocation("project://Software%20Evolution/src/Series2/result-<curProject.id.authority>-<numLines>-<typeDetection>");
	if (exists(filePath) && projectIsSet()) {
		println("Got clone classes!");
		duplicateClasses = readDuplicates(filePath);
		return true;
	}
	println("Clone classes do not exist - or project is not set yet.");
	return false;
}

public M3 getCurrentProject(str projectName) {
	projectName = trim(projectName);
	loc projectLoc = toLocation("project://<projectName>");
	try {
		println("Trying to make M3 model of project: <projectName>");
		if (projectLoc notin eclipseProjectMap)
			eclipseProjectMap[projectLoc] = createM3FromEclipseProject(projectLoc);
		curProject = eclipseProjectMap[projectLoc];
		if (readCloneClasses())
			redrawAll();
		println("Finished project creation!");
	}
	catch :
		println("Invalid location given!");

	return curProject;
}

public void startCloneDetection() {
	findDuplicatesAST(curProject, detectType2=type2);
}


public void startVisualization() {
	duplicateClasses = {};
	curProject = emptyM3(|file://null|);

	Figure configInput = configInputFields();
	Figure stats = statsScreen();
	Figure fileBoxes = fileBoxFigures();

	render(hcat([vscrollable(vcat([configInput, stats, space()], top(), left(),  size(325, 800)), hresizable(false), top()), fileBoxes], top()));
}

public Figure configInputFields() {
	
	Figure header1 = text("  Configurations clone detector ", fontSize(16), top());
	Figure headerSep = box(vsize(4), fillColor(gray(220)), lineColor(gray(220)), vresizable(false));
	Figure lineSep = box(vsize(3), fillColor(gray(200)), lineColor("white"), vresizable(false));
	
	Figure projectField = vcat(
		[text("Project name: ", left()), 
		 textfield("", 
		 	void(str s) {
		 		 getCurrentProject(s);
		 	}, hsize(325), hresizable(false))
		 ],
		vsize(80), vresizable(false), left());
	
	Figure numCodeLines = hcat(
		[text("Num lines: ", left()),
		 textfield("<numLines>",
		 		   void(str s) {
		 		   	 numLines = intInput(s) ? toInt(s) : numLines;
		 		   	 setCloneSize(numLines); // Set the number of lines in the clone detector.
		 		   }, left(), hsize(30), hresizable(false))
		], vsize(80), resizable(false), left());
	
	Figure cloneType = vcat(
		[text("Clone type: ", left(), top()),
         choice(["1", "2"],
         void (str s) {
         	type2 = s == "1" ? false : true;
         	println("<s> - <type2>");
         }, left(), size(100, 60))
        ], resizable(false), left());
	
	Figure startButton = button(
		"Start clone detection",
	    void() { if (projectIsSet()) startCloneDetection(); redrawAll(); },
	    resizable(false), size(325, 50), left()
	);
	
	list[Figure] configBoxContents = [];
	configBoxContents += [header1, headerSep, projectField, cloneType];
	configBoxContents += [numCodeLines, startButton, lineSep];
	mainBox = box(vcat(configBoxContents), size(325, 400), top(), vgap(2), vresizable(false), lineColor(gray(200)));
	return mainBox;
}

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
				return resultsFigure();
			else
				return space();
		}
	);

	
	return box(vcat([resultHeader, resultStats], resizable(false), left(), top()), hsize(325), resizable(false), top(), left(), lineColor(gray(200)));
}

public Figure resultsFigure() {
	
	int linesOfCode = getVolume(curProject);
	map[loc, int] fileDupCount = getFileDupCount();
	int linesOfCloneCode = sum([0] + [fileDupCount[f] | f <- fileDupCount]);
	
	real clonePercentage = (linesOfCode == 0) ? 0.0 : ((linesOfCloneCode / toReal(linesOfCode)) * 100.0);
	
	map[str, int] stats = calcStats(duplicateClasses, curProject);
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

	return vcat(resultFigures + createCloneLegend(), top(), vresizable(false));
}

public Figure fileBoxFigures() { 
	Figure fileBoxes = computeFigure(
		bool() {
			if (!redrawBoxes)
				return false; 
			redrawBoxes = false;
			return true;
		},
		Figure() {
			if (readCloneClasses()) {
				Figure boxes = getFileBoxes(duplicateClasses);
				redrawConfig = true;
				return boxes;
			} 
			else {
				return space();
			}
		});
	return fileBoxes;
}





public Figure createCloneLegend() {
	map[int, tuple[loc, int, int]] cloneExamples = getCloneExamples();
	int numColumns = 3;
	map[int, list[Figure]] legendColumns = (); 
	
	Figure createLegendBlock(int classNum, tuple[loc, int, int] block) {
		<cloneLoc, lineNum, classColor> = block;
		str mouseOverText = "SLOC <lineNum> - Click for example on box.";
		return hcat([text("<classNum>  - "),
		             box(fillColor(classColor), lineColor(classColor), size(10, 10),
		             getMouseDownAction(cloneLoc), resizable(false), right(), getMouseOverBox(mouseOverText, right()))
		            ],resizable(false), size(50, 12), vresizable(false), left());
	}

	for (cloneIndex <- [1..size(cloneExamples) + 1]) {
		firstBlock = cloneExamples[cloneIndex];
		columnIndex = cloneIndex % numColumns;
		if (columnIndex in legendColumns)
			legendColumns[columnIndex] += createLegendBlock(cloneIndex, firstBlock);
		else
			legendColumns[columnIndex] = [createLegendBlock(cloneIndex, firstBlock)];
	}
	
	return hcat([vcat(legendColumns[col], resizable(false), left(), top()) | col <- legendColumns]);
}