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
import ParseTree;

public list[str] findDuplicates(m1) {
	allMethods = methods(m1);
	
	for (method <- allMethods) {
		println(createDupSnippets(method));
	}
}

public map[str, real] complexityRisk(m1) {
	allMethods = methods(m1);
	riskMap = ("low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0);
	
	/* Calculate complexity and LOC for each method. */
	for (method <- allMethods) {
		complexity = cyclomaticComplexity(method, m1);
		if (complexity <= 10)
			riskMap["low"] += countLOC(method);
		else if (complexity <= 20)
			riskMap["moderate"] += countLOC(method);
		else if (complexity <= 50)
			riskMap["high"] += countLOC(method);
		else if (complexity > 50)
			riskMap["very high"] += countLOC(method);
	}
	
	/* Calculate totalLines, divide riskMap by totalLines. */
	real totalLines = sum([riskMap[index] | index <- riskMap]);
	return (index : riskMap[index] / totalLines | index <- riskMap);	
}

public int cyclomaticComplexity(methodLocation, model) {
	/* Start count at 1, because there is always one exection path. */
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

public rel[loc, str] createDupSnippets(location) {
	contents = readFile(location);
	strippedContents = trimCode(contents);
	println(strippedContents);
	
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

public int countLOC(location) {
	contents = readFile(location);
	strippedContents = trimCode(contents);
	
	return size(split("\n", trim(strippedContents)));
}

/* Count the lines of code in a project. */
public int countLinesOfCode(projectLoc) {
	int lineCount = 0;
	allFiles = getProject(|project://smallsql0.21_src|);

	/* Visit all files in the directory structure;  */
	visit(allFiles) {
		case file(f): {
			/* Match on a '*.java' file. */
			if (/.*\.java/ := f.file) {
				contents = readFile(f);
				strippedContents = trimCode(contents);
				
				/* Trim the contents to remove newline at start of file. */
				lineCount += size(split("\n", trim(strippedContents)));
				iprintln("<f> <lineCount>");
				break;
			}
		}
	}
	return lineCount;
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(str S) {
	/* Remove string contents as they could contain comments. */
	trimmedQuotes = visit(S) {
		case /\".*?\"/ => "\"\""
	}
    /* Remove multiline comments - on single-line. */
    trimmedComments1 = visit(trimmedQuotes) {
 	    case /\/\*(?:.)*?\*\// => ""
    }
    /* Remove multiline comments - on multiple lines. */
    trimmedComments2 = visit(trimmedComments1) {
    	case /\/\*(?:.|\n|\r|\n\r)*?\*\// => "\n" 
    }
    /* Remove all single-line comments. */
    trimmedComments3 = visit(trimmedComments2) {
 	    case /\/\/.*/ => ""
    }
    /* Remove all whitespace lines. */
    return visit(trimmedComments3) {
 	    case /\s*\n/ => "\n"
    }
}