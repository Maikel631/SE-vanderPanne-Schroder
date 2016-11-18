/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 10-11-2016
 *
 * FILE:   Series1.rsc
 *         This file contains the code for the Series1 exercises
 *         for the Software Evolution course.
 *
 * USAGE: 'import Series1' to make use of the defined functions.   
 */
module Series1

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::\syntax::Java15;

import IO;
import String;
import List;
import Set;
import Map;

/* Calculate SIG scores for the Eclipse M3 project model. */
public int calculateMaintainabilityScore(eclipseModel) {
	/* Determine all source files of the project. */
	srcType = "java+compilationUnit";
	srcFiles = sort({e | <e, _> <- eclipseModel@declarations, e.scheme == srcType});
	
	/* Calculate LOC in all files; ignore comments & whitespace lines. */
	int totalLOC = sum([countLOC(srcFile, eclipseModel) | srcFile <- srcFiles]);
	real kloc = totalLOC / 1000.0;

	int manYearScore = 0;
	if (kloc < 0)
		manYearScore = -1;
	else if (kloc <= 66) 
		manYearScore = 5;
	else if (kloc <= 246)
		manYearScore = 4;
	else if (kloc <= 665)
		manYearScore = 3;
	else if (kloc <= 1310)
		manYearScore = 2;
	else
		manYearScore = 1;
	println("Total lines of code: <totalLOC> - Man year score: <manYearScore>");
	return manYearScore;
}

public int countLOC(location, eclipseModel) {
	/* Remove comments from the source file. */
	strippedContents = trimCode(location, eclipseModel);

	/* Remove whitespace lines and return the line count. */
	return size(split("\n", strippedContents));
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(location, eclipseModel) {
	/* Determine all comment entries for this file. Use the comment offset
	 * sort them. By sorting we can always remove the first occurrence.
	 */
	commentLocs = sort([<f.offset, f> | <e, f> <- eclipseModel@documentation, f.file == location.file]);
	
	/* Remove all comments from the file source. */
	fileContent = readFile(location);
	for (<offset, commentLoc> <- commentLocs)
		fileContent = replaceFirst(fileContent, readFile(commentLoc), "");
    
    /* Remove all whitespace lines. */
    return visit(trim(fileContent)) {
 	    case /\s*\n/ => "\n"
    }
}

public map[str, real] complexityRisk(M3 eclipseModel) {
	set[loc] allMethods = methods(eclipseModel);
	map[str, int] riskMap = ("low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0);
	
	/* Calculate complexity and LOC for each method. */
	for (method <- allMethods) {
		int complexity = cyclomaticComplexity(method, eclipseModel);
		if (complexity <= 10)
			riskMap["low"] += countLOC(method, m1);
		else if (complexity <= 20)
			riskMap["moderate"] += countLOC(method, m1);
		else if (complexity <= 50)
			riskMap["high"] += countLOC(method, m1);
		else if (complexity > 50)
			riskMap["very high"] += countLOC(method, m1);
	}
	
	/* Calculate totalLines, divide riskMap by totalLines. */
	real totalLines = sum([riskMap[index] | index <- riskMap]);
	return (index : riskMap[index] / totalLines | index <- riskMap);	
}

public int cyclomaticComplexity(methodLocation, model) {
	/* Start count at 1, because there is always one execution path. */
	int count = 1;

	/* Declarations: http://bit.ly/SaL4yQ */
	Declaration methodAST = getMethodASTEclipse(methodLocation, model=model);
	visit (methodAST) {
		case \case(_): count += 1;
		case \catch(_, _): count += 1;
		case \do(_, _): count += 1;
		case \if(_, _): count += 1;
		case \if(_, _, _): count += 1;
		case \for(_, _, _): count += 1;
		case \for(_, _, _, _): count += 1;
		case \foreach(_, _, _): count += 1;
		case \while(_, _): count += 1;
	}
	return count;
}


public list[str] createDupSnippets(loc location, int frameSize, M3 eclipseModel) {
	str strippedContents = trimCode(location, eclipseModel);
	
	/* Split stripped content and larger than frameSize lines. */
	list[str] lines = split("\n", trim(strippedContents));
	if (size(lines) < frameSize)
		return [];
	
	/* Trim lines to get rid of whitespace. */
	trimmedLines = [trim(line) | line <- lines];
	return for (i <- [0..size(trimmedLines) - frameSize + 1]) {
		append intercalate("", trimmedLines[i..i+frameSize]);
	}
}

public int findDuplicates(M3 eclipseModel) {
	str srcType = "java+compilationUnit";
	set[loc] srcFiles = {e | <e, _> <- eclipseModel@declarations, e.scheme == srcType};
	
	int linesDuplicated = 0;
	map[str, bool] snippetList = ();
	
	int frameSize = 6;
	for (srcFile <- srcFiles) {
		/* Split method in snippets, if method is smaller than 6 lines: skip it. */
		list[str] snippets = createDupSnippets(srcFile, frameSize, eclipseModel);
		if (isEmpty(snippets))
			continue;

		int dupLinesCount = 0;
		bool dupFound = false;
		for (snippet <- snippets) {
			/* Check if snippet is already added to the snippet list,
			 * if it is, a duplicate is found. If upfollowing snippets
			 * also are in this list, a duplication of a larger area is found.
			 */
			if (snippet in snippetList) {
				if (dupFound == false) {
					dupFound = true;
					/* When this snippet is not found as duplicate yet;
					 * frameSize * 2 lines has to be added to count all duplicated
					 * lines. Else add frameSize once. 
					 */
					dupLinesCount = (snippetList[snippet]) ? frameSize : frameSize * 2;
				}
				/* Next duplicate matches --> so add a single line count
				 * or double line count when not found earlier. 
				 */
				else
					dupLinesCount += (snippetList[snippet]) ? 1 : 2;
				snippetList[snippet] = true;
			}
			else {
				/* Unknown snippet, check for later instances if it can match. */
				snippetList[snippet] = false;
				if (dupFound) {
					linesDuplicated += dupLinesCount;
					dupFound = false;
				}
			}
			
		}
		if (dupFound)
			linesDuplicated += dupLinesCount;
	}
	return linesDuplicated;
}

public int unitTestCoverage(M3 eclipseModel) {
	
	set[loc] projectMethods = methods(eclipseModel);
	/* Determine all project methods which are called via the unit tests. */
	set[loc] calledMethods = {to | <from, to> <- eclipseModel@methodInvocation,
	                          contains(from.path, "test") || contains(from.path, "junit"),
	                          to in projectMethods};
		
	int newSizeCalledMethods = size(calledMethods);
	int oldSizeMethods = -1;
	
	set[loc] checkedMethods = {};
	
	/* Obtain all methods called by the methods which in turn are
	 * called in the unit tests. This will return the coverage of all
	 * method calls. 
	 */
	while( newSizeCalledMethods != oldSizeMethods) {
		oldSizeMethods = size(calledMethods);
		for (method <- calledMethods) {
			if (method in checkedMethods)
				continue;
			
			checkedMethods += method;
			calledMethods += {to | <from, to> <- eclipseModel@methodInvocation,
			                  from == method, to in projectMethods};
		}
		newSizeCalledMethods = size(calledMethods);
	}
	println("calledMethods - <size(calledMethods)>");
	
	/* Determine all lines of code covered by the unit tests. */
	int coverage = sum([countLOC(method, eclipseModel) | method <- calledMethods]);
	return coverage;
}
