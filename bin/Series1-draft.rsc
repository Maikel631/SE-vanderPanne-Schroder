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
public str calculateMaintainabilityScore(M3 eclipseModel) {
	/* Determine all source files of the project. */
	srcType = "java+compilationUnit";
	srcFiles = sort({e | <e, _> <- eclipseModel@declarations, e.scheme == srcType});
	
	/* Calculate LOC in all files; ignore comments & whitespace lines. */
	totalLOC = sum([countLOC(srcFile) | srcFile <- srcFiles]);
	real kloc = totalLoc / 1000.0;

	str manYearScore = "";
	if (kloc < 0)
		manYearScore = "Invalid!";
	else if (kloc <= 66)
		manYearScore = "++";
	else if (kloc <= 246)
		manYearScore = "+";
	else if (kloc <= 665)
		manYearScore = "0";
	else if (kloc <= 1310)
		manYearScore = "-";
	else
		manYearScore = "--";
	println("Total lines of code: <totalLOC> - Man year score: <manYearScore>");
	return manYearScore;
}

public int countLOC(loc location) {
	/* Remove comments and whitespace lines. */
	strippedContents = trimCode(location);
	
	/* Trim the contents surplus newline at start/end; return size. */
	return size(split("\n", trim(strippedContents)));
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(loc location) {
	S = readFile(location);
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

public int findDuplicates3(M3 eclipseModel) {
	srcType = "java+compilationUnit";
	srcFiles = sort({e | <e, _> <- eclipseModel@declarations, e.scheme == srcType});
	
	int linesDuplicated = 0;
	list[str] snippetList = [];	
	
	int frameSize = 6;
	for (srcFile <- srcFiles) {
		/* Split method in snippets, if method is smaller than 6 lines: skip it. */
		snippets = createDupSnippets(srcFile, eclipseModel, frameSize);			
		if (isEmpty(snippets))
			continue;

		bool dupFound = false;
		int dupLinesCount = 0;
		for (snippet <- snippets) {
			/* Check if snippet is already added to the snippet list,
			 * if it is, a duplicate is found. If upfollowing snippets
			 * also are in this list, a duplication of a larger area is found.
			 */
			if (snippet in snippetList) {
				if (dupFound == false) {
					dupFound = true;
					dupLinesCount = 6;
				}
				/* Next duplicate matches --> so add a single line count. */
				else
					dupLinesCount += 1;
			}
			else {
				/* Unknown snippet, check for later instances if it can match. */
				snippetList += snippet;
				if (dupFound) {
					dupFound = false;
					linesDuplicated += dupLinesCount * 2;
				}
			}
		}
		if (dupFound)
			linesDuplicated += dupLinesCount * 2;
		
	}
	return linesDuplicated;
}


public lrel[int, int, str] createDupSnippets2(loc location, M3 eclipseModel, int frameSize) {
	strippedContents = trimCode(location);
	
	/* Split stripped content and larger than frameSize lines. */
	list[str] lines = split("\n", trim(strippedContents));
	if (size(lines) < frameSize)
		return [];
	
	/* Trim lines to get rid of whitespace. */
	trimmedLines = [trim(line) | line <- lines];
	return for (i <- [0..size(trimmedLines) - frameSize + 1]) {
		append <i, i + frameSize, intercalate("\n", trimmedLines[i..i+frameSize])>;
	}
}


public list[str] findDuplicates2(M3 eclipseModel) {
	srcType = "java+compilationUnit";
	srcFiles = sort({e | <e, _> <- eclipseModel@declarations, e.scheme == srcType});
	map[loc, list[str]] classLines = ();
	
	
	for (srcFile <- srcFiles) {
		classLines[srcFile] = [trim(line) | line <- split("\n", trim(trimCode(srcFile)))];
	}
	
	int frameSize = 6;
	map[str, lrel[int, int, loc]] duplicates = ();
	
	for (srcFile <- srcFiles) {
		snippetsWithOffsets = createDupSnippets2(srcFile, eclipseModel, frameSize);
		for (snippet <- snippetsWithOffsets) { 
			duplicates[snippet[2]] = [<snippet[0], snippet[1], srcFile>];
		}
	}
	
	for (srcFile <- srcFiles) {
		snippetsWithOffsets = createDupSnippets2(srcFile, eclipseModel, frameSize);
		// [[int, int, str]]
		/* Map all snippets in the duplicate map. Use a list of locations
		 * to keep track of multiple duplicates in the same method.
		 */
		for (snippet <- snippetsWithOffsets) { 
			//println("<snippet>");
			//println("<snippet[0]>");
			str code = snippet[2];
			if (code in duplicates) {
				firstDup = duplicates[snippet[2]][0];
				println(firstDup);
				startRange1 = snippet[0];
				endRange1 = snippet[1];
				
				startRange2 = firstDup[0];
				endRange2 = firstDup[1];
				
				dupFile = firstDup[2];
				isDup = true;
				
				end1 = size(classLines[srcFile]) - 1;
				end2 = size(classLines[dupFile]) - 1;
				
				/* Find largest match! */
				while (isDup) {
					fstDuplicateLines = classLines[srcFile][startRange1..endRange1];
					secDuplicateLines = classLines[dupFile][startRange2..endRange2];
					
					if (fstDuplicateLines != secDuplicateLines) {
					    isDup = false;
					    continue;
				    }
				    
					if (endRange1 <= end1)
						endRange1 += 1;
					else
						 break;
					if (endRange2 <= end2)
						endRange2 += 1;
					else
						break;
				}
				largestSnippet = intercalate("\n", classLines[srcFile][startRange1..endRange1]);
				
				if (dupFile == srcFile && endRange1 == endRange2) {
					continue;	
				}
				
				
				println("LargestSNippet: <largestSnippet>");
				duplicates = (d : duplicates[d] | d <- duplicates, !contains(largestSnippet, d));
				println("Filtered duplicates:");
				for (dup <- duplicates) {
					println("Duptest: <dup>");
				}
				duplicates[largestSnippet] = [<startRange1, endRange1, srcFile>];
				
				//println("Merged duplicates:");
				//for (dup <- duplicates) {
				//	println("dup: <dup>  \n");
				//}
			}
			//else {
				// snippetstr -> [start, end, file]
				
			//}
		}
	}
	
	for (dup <- duplicates) {
		println("dup: <dup>  \n");
	}
	println(size(duplicates));
}


public list[str] findDuplicates(M3 eclipseModel) {
	set[loc] allMethods = classes(eclipseModel);
	map[str, list[loc]] duplicates = ();
	
	int frameSize = 6;
	
	set[loc] canBeSkipped = {};
	
	bool foundDup = true;
	bool first = true;
	
	//allMethods = {|project://Software%20Evolution/src/Duplicates.java|};
	
	while (foundDup) {
	
		println("Trying with frameSize: <frameSize>");
		foundDup = false;
		map[str, list[loc]] newDuplicates = ();
		
		for (method <- allMethods) {
			/* Split method in snippets, if method is smaller than 6 lines: skip it. */
			if (method in canBeSkipped)
				continue;
			
			snippets = createDupSnippets(method, eclipseModel, frameSize);
			
			if (isEmpty(snippets)) {
				canBeSkipped += method;
				continue;
			}
			
			/* Map all snippets in the duplicate map. Use a list of locations
			 * to keep track of multiple duplicates in the same method.
			 */
			for (snippet <- snippets) { 
				if (snippet in newDuplicates) {
					newDuplicates[snippet] += method;
					allFiles = newDuplicates[snippet];
					foundDup = true;
				}
				else
					newDuplicates[snippet] = [method];
			}
		}
		
		/* Remove all unnecessary indices. */
		newDuplicates = (index : newDuplicates[index] | index <- newDuplicates, size(newDuplicates[index]) > 1);
		
		frameSize += 1;
		
		if (first) {
			duplicates = newDuplicates;
			first = false;
			continue;
		}
		
		/* Merge duplicates. */
		map[str, list[loc]] allDuplicates = ();
		for (newFrameSnippets <- newDuplicates) {
			for (oldFrameSnippets <- duplicates) {
				list[loc] newSnipsLocs = newDuplicates[newFrameSnippets];
				list[loc] oldSnipsLocs = duplicates[oldFrameSnippets];
				if (newFrameSnippets == oldFrameSnippets)
					continue;
				
				if (contains(newFrameSnippets, oldFrameSnippets)) {
					allDuplicates[newFrameSnippets] = newSnipsLocs & oldSnipsLocs; 
				}
			}
		}
		duplicates = allDuplicates;
		break;
	}
	
	/* List all snippets which are a duplicate */
	lrel[int, list[loc], str] realDups = [<size(duplicates[index]), duplicates[index], index> | index <- duplicates, size(duplicates[index]) > 1];
	println("Number of duplicates found: <size(realDups)>");
	println("Duplicates are:");
	for (dup <- realDups) {
		println("Dup: <dup> \n");
	}
	return realDups;
}

public map[str, real] complexityRisk(M3 m1) {
	allMethods = methods(m1);
	riskMap = ("low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0);
	
	/* Calculate complexity and LOC for each method. */
	for (method <- allMethods) {
		complexity = cyclomaticComplexity(method);
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

public int cyclomaticComplexity(loc methodLocation, M3 model) {
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

public list[str] createDupSnippets(loc location, M3 eclipseModel, int frameSize) {
	strippedContents = trimCode(location);
	
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