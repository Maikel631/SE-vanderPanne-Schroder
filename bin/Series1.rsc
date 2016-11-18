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

import IO;
import String;
import List;
import Set;
import Map;
import Relation;

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

public int complexityRisk(M3 eclipseModel) {
	set[loc] allMethods = methods(eclipseModel);
	map[str, real] riskMap = ("low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0);
	
	/* Calculate complexity and LOC for each method. */
	for (method <- allMethods) {
		int complexity = cyclomaticComplexity(method, eclipseModel);
		if (complexity <= 10)
			riskMap["low"] += countLOC(method, eclipseModel);
		else if (complexity <= 20)
			riskMap["moderate"] += countLOC(method, eclipseModel);
		else if (complexity <= 50)
			riskMap["high"] += countLOC(method, eclipseModel);
		else if (complexity > 50)
			riskMap["very high"] += countLOC(method, eclipseModel);
	}
	
	/* Calculate totalLines, divide riskMap by totalLines. */
	real totalLines = sum([riskMap[index] | index <- riskMap]);
	riskMap = (index : riskMap[index] / totalLines | index <- riskMap);
	
	println("Riskmap percentages: <riskMap>");
	real high = riskMap["high"];
	real veryHigh = riskMap["very high"];
	real moderate = riskMap["moderate"];
	
	//list[real] moderateScores = [0.25, 0.30, 0.40, 0.50];
	//list[real] highScores     = [0.00, 0.05, 0.10, 0.15];
	//list[real] veryHighScores = [0.00, 0.00, 0.00, 0.05];
	//
	//int rank = 5;
	//for (i <- [0..4]) {
	//	if (moderate <= moderateScores[i] && high <= highScores[i] &&
	//	    veryHighScores <= veryHighScores[i]) {
	//		break;
	//	}
	//	rank -= 1; 
	//}
	
	if (moderate < 0.25 && high == 0 && veryHigh == 0)
		return 5;
	else if (moderate < 0.30 && high < 0.05 && veryHigh == 0)
		return 4;
	else if (moderate < 0.40 && high < 0.10 && veryHigh == 0)
		return 3;
	else if (moderate < 0.50 && high < 0.15 && veryHigh < 0.05)
		return 2;
	else
		return 1;
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

/* Helper function to get a set of all called methods using all methods
 * of a project, and all its method invocations as generated by the M3 model.
 */
private set[loc] getAllCalledMethods(set[loc] calledMethods, set[loc] modelMethods, 
                                     rel[loc, loc] modelInvocations) {
	set[loc] checkedMethods = {};
	int sizeBefore = 0;
	
	/* Iteratively find all unique methods called by the unit tests.
	 * Works similar to a transative closure calculation.
	 */
	while (sizeBefore != size(calledMethods)) {
		sizeBefore = size(calledMethods);
		
		/* Find new methods called by the current methods. */
		for (method <- calledMethods) {
			if (method in checkedMethods)
				continue;
			checkedMethods += method;
			
			calledMethods += {to | <from, to> <- modelInvocations,
				              from == method, to in modelMethods};
		}
	}
	return calledMethods;
}

public int unitTestCoverage(M3 eclipseModel) {
    /* Fetch all methods and method invocations for this project. */
    set[loc] modelMethods = methods(eclipseModel);
    rel[loc, loc] modelInvocations = eclipseModel@methodInvocation;
    
    /* Find project methods called from Unit Test files. */
    rel[loc, loc] allTestMethods = {
         <from, to> | <from, to> <- modelInvocations, to in modelMethods,
    	 contains(from.path, "junit") || contains(from.path, "test")};

    set[loc] testMethods = domain(allTestMethods);
    set[loc] calledMethods = range(allTestMethods);

	/* Now find all methods called within the methods called by the unit test methods;
	 * all newly found methods will also be analyzed to fully find all covered
	 * methods in the project. 
	 */
	calledMethods = getAllCalledMethods(calledMethods, modelMethods, modelInvocations);
	/* Filter the unit test files from called methods as coverage has to
	 * be calculated over only production code.
	 */
	calledMethods -= testMethods;
	
    /* Determine the cumulative linecount for all called methods. */
    int coverage = sum([countLOC(method, eclipseModel) | method <- calledMethods]);
	println("Unit test lines coverage: <coverage>");
	
	/* Determine code size of all non-testing methods */
	int productionSize = sum([countLOC(method, eclipseModel) | method <- (modelMethods - testMethods)]); 
	println("Number of production lines of code: <productionSize>");
	
	real percentageCovered = (coverage / (productionSize * 1.0)) * 100.0;
	println("Percentage covered files: <percentageCovered>%");
	
	/* Return the score 1 - 5. */
	list[real] rankPercentages = [20.0, 60.0, 80.0, 95.0, 100.0]; 
	int curRank = 1;
	for (rank <- rankPercentages) {
		if (percentageCovered <= rank)
			return curRank;
		curRank += 1;
	}
	return -1;
}