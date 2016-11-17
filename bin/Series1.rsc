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
import util::Resources;

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
	totalLOC = sum([countLOC(srcFile, eclipseModel) | srcFile <- srcFiles]);	
	return totalLOC;
}

public int countLOC(location, eclipseModel) {
	/* Remove comments and whitespace lines. */
	strippedContents = trimCode(location, eclipseModel);
	
	/* Trim the contents surplus newline at start/end; return size. */
	return size(split("\n", trim(strippedContents)));
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
	
	/* Remove lines with whitespace only. */
	return visit(fileContent) {
 	    case /\s*\n/ => "\n"
    }
}

public list[str] findDuplicates(m1) {
	allMethods = methods(m1);
	
	for (method <- allMethods) {
		println(createDupSnippets(method, m1));
	}
}

public map[str, real] complexityRisk(m1) {
	allMethods = methods(m1);
	riskMap = ("low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0);
	
	/* Calculate complexity and LOC for each method. */
	for (method <- allMethods) {
		complexity = cyclomaticComplexity(method, m1);
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
	count = 1;

	/* Declarations: http://bit.ly/SaL4yQ */
	methodAST = getMethodASTEclipse(methodLocation, model=model);
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

public lrel[loc, str] createDupSnippets(location, eclipseModel) {
	strippedContents = trimCode(location, eclipseModel);
	
	/* Split stripped content and larger than 6 lines. */
	list[str] lines = split("\n", trim(strippedContents));
	if (size(lines) < 6)
		return [];
	
	/* Trim lines to get rid of whitespace. */
	trimmedLines = [trim(line) | line <- lines];
	snippets = for (i <- [0..size(trimmedLines) - 6 + 1]) {
		append intercalate("", trimmedLines[i..i+6]);
	}
	
	/* */
	return [<location, snippet> | snippet <- snippets];
}