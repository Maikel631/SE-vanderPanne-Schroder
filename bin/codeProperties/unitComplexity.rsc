/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  unitComplexity.rsc
 *        This file contains functions to calculate the cyclomatic complexity
 *        of a unit in an eclipse project. In this case, the unit is a method.
 *
 *        Using this measure and the linecount of the method, a risk profile
 *        is set up for all methods. This risk profile is then translated into
 *        a 1-5 star rating using a scoring table.
 *
 * USAGE: import 'codeProperties::unitComplexity' to use the functions.
 */
module codeProperties::unitComplexity

import IO;
import List;

import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import codeProperties::volume;

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