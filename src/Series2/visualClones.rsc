module Series2::visualClones

import Series2::visUtilities;
import Series2::visFileBoxes;
import Series2::visStatistics;
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


public bool redrawConfig = false;
public bool redrawBoxes = false;
int count = 0;

private map[loc, M3] eclipseProjectMap = ();
private M3 curProject = emptyM3(|file://null|);
private int numLines = 6;
private bool type2 = false;

/* === Getter and setter related variables. === */
private set[set[loc]] duplicateClasses = {};

public set[set[loc]] getDuplicateClasses() {
	return duplicateClasses;
}

/* Get the current M3 project. */
public M3 getCurProject() {
	return curProject;
}

/* === Helper functions === */
/* Check if the project is set to something valid. */
public bool projectIsSet() {
	return (curProject.id != |file://null|);
}

/* Redraw the configuration statistics and the fileBoxes. */
public void redrawAll() {
	redrawConfig = true;
	redrawBoxes = true;
}

/* Try to retreive all the clone classes calculated for this particular configuration. */
public bool readCloneClasses() {
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

/* Try to create a M3 project which will fail if the path does not exists.
 * However, the exists function will crash on project paths: thus use try catch.
 */
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
	
}

/* === Main function to start the visualization. === */
public void startVisualization() {
	duplicateClasses = {};
	curProject = emptyM3(|file://null|);

	Figure configInput = configInputFields();
	Figure stats = statsScreen();
	Figure fileBoxes = fileBoxFigures();

	Figure configMenu = vcat([configInput, stats, space()], top(), left(),  size(325, 800));
	render(hcat([vscrollable(configMenu, hresizable(false), top()), fileBoxes], top()));
}

/* Create the menu to the right containing the input fields, which
 * configure the clone detector.
 */
public Figure configInputFields() {
	Figure header1 = text("  Configurations clone detector ", fontSize(16), top());
	Figure headerSep = box(vsize(4), fillColor(gray(220)), lineColor(gray(220)), vresizable(false));
	Figure lineSep = box(vsize(3), fillColor(gray(200)), lineColor("white"), vresizable(false));
	
	/* Create the project name input field and create a M3 model on input confirmation. */
	Figure projectField = vcat(
		[text("Project name: ", left()), 
		 textfield("", 
		 	void(str s) {
		 		 getCurrentProject(s);
		 	}, hsize(325), hresizable(false))
		 ],
		vsize(80), vresizable(false), left());
	
	/* Set the number of lines on which the clone classes are based at minimum. */
	Figure numCodeLines = hcat(
		[text("Num lines: ", left()),
		 textfield("<numLines>",
		 		   void(str s) {
		 		   	 numLines = intInput(s) ? toInt(s) : numLines;
		 		   	 setCloneSize(numLines); // Set the number of lines in the clone detector.
		 		   }, left(), hsize(30), hresizable(false))
		], vsize(80), resizable(false), left());
	
	/* Create a dropdown list to choose the clone detection type. */
	Figure cloneType = vcat(
		[text("Clone type: ", left(), top()),
         choice(["1", "2"],
         void (str s) {
         	type2 = s == "1" ? false : true;
         	println("<s> - <type2>");
         }, left(), size(100, 60))
        ], resizable(false), left());
	
	/* Start the clone detection algorithm and reload all the views. */
	Figure startButton = button(
		"Start clone detection",
	    void() { if (projectIsSet()) findDuplicatesAST(curProject, detectType2=type2); redrawAll(); },
	    resizable(false), size(325, 50), left()
	);
	
	/* Now combine everything. */
	list[Figure] configBoxContents = [];
	configBoxContents += [header1, headerSep, projectField, cloneType];
	configBoxContents += [numCodeLines, startButton, lineSep];
	mainBox = box(vcat(configBoxContents), size(325, 400), top(), vgap(2), vresizable(false), lineColor(gray(200)));
	return mainBox;
}

/* Create a compute figure for the file boxes. */
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
		}
	);
	return fileBoxes;
}