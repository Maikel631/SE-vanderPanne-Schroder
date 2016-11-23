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
module Series1::codeProperties::unitComplexity

import IO;
import List;
import ParseTree;
import util::Math;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import Series1::codeProperties::volume;

public int getComplexityScore(M3 eclipseModel) {
	/* Calculate the risk profile, convert it to a rating. */
	map[str, real] riskMap = complexityRiskMap(eclipseModel);
	int rating = complexityRating(riskMap);
	
	/* Output the calculated values, return rating. */
	println("=== Unit complexity ===");
	println("Risk profile:");
	println("Low:\t\t<round(riskMap["low"] * 100, 0.001)>%");
	println("Moderate:\t<round(riskMap["moderate"] * 100, 0.001)>%");
	println("High:\t\t<round(riskMap["high"] * 100, 0.001)>%");
	println("Very high:\t<round(riskMap["very high"] * 100, 0.001)>%");
	println("\nUnit Complexity rating: <rating>\n");
	
	return rating;
}

public map[str, real] complexityRiskMap(M3 eclipseModel) {
	set[Declaration] AST = createAstsFromEclipseProject(eclipseModel.id, false);
	map[str, real] riskMap = (
		"low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0
	);

	/* Visit each sourcefile in the AST, extract the methods. */
	for (srcFile <- AST) {
		visit(srcFile) {
			case m:\method(_, _, _, _):
				riskMap = addToRiskMap(riskMap, m, eclipseModel);
			case m:\method(_, _, _, _, _):
				riskMap = addToRiskMap(riskMap, m, eclipseModel);
			case m:\constructor(_, _, _, _):
				riskMap = addToRiskMap(riskMap, m, eclipseModel);
		}
	}

	/* Convert absolute LOC in each riskMap category to percentages. */
	real totalLines = sum([riskMap[index] | index <- riskMap]);
	if (totalLines != 0)
		riskMap = (index : riskMap[index] / totalLines | index <- riskMap);
	
	return riskMap;
}

public map[str, real] addToRiskMap(map[str, real] riskMap, Declaration methodAST, M3 eclipseModel) {
	/* For each methodAST, add its LOC to the correct category. */
	int complexity = cyclomaticComplexity(methodAST);
	int linesOfCode = countLOC(methodAST@src, eclipseModel);
	
	if (complexity <= 10)
		riskMap["low"] +=  linesOfCode;
	else if (complexity <= 20)
		riskMap["moderate"] += linesOfCode;
	else if (complexity <= 50)
		riskMap["high"] += linesOfCode;
	else if (complexity > 50)
		riskMap["very high"] += linesOfCode;
	return riskMap;
}

public int complexityRating(map[str, real] riskMap) {
	real high = riskMap["high"];
	real veryHigh = riskMap["very high"];
	real moderate = riskMap["moderate"];
	
	/* Based on the amount of code in each category, assign the rating. */
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

public int cyclomaticComplexity(Declaration methodAst) {
	/* Start count at 1, because there is always one execution path. */
	int count = 1;

	visit (methodAst) {
		case \case(_): count += 1;
		case \catch(_, _): count += 1;
		case \do(_, _): count += 1;
		case \if(_, _): count += 1;
		case \if(_, _, _): count += 1;
		case \for(_, _, _): count += 1;
		case \for(_, _, _, _): count += 1;
		case \foreach(_, _, _): count += 1;
		case \while(_, _): count += 1;
		case \conditional(_,_,_): count += 1;
		case infix(_, "&&", _): count += 1;
		case infix(_, "||", _): count += 1;
	}
	return count;
}