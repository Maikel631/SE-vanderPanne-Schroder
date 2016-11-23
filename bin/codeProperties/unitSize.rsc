/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  unitSize.rsc
 *        This file contains functions to calculate the size (in lines of code)
 *        of units (methods). Based on the size of all methods in the eclipse
 *        project, a risk profile is set up.
 *
 *        This risk profile is then translated into a 1-5 star rating using a
 *        scoring table.
 *
 * USAGE: import 'codeProperties::unitTesting' to use the functions.
 */
module codeProperties::unitSize

import IO;
import List;

import lang::java::m3::Core;
import codeProperties::volume;

public int getUnitSizeScore(eclipseModel) {
	/* Calculate the risk profile, convert it to a rating. */
	map[str, real] riskMap = unitSizeRiskMap(eclipseModel);
	int rating = unitSizeRating(riskMap);
	
	/* Output the calculated values, return rating. */
	println("=== Unit size ===");
	println("Risk profile:");
	println("Low:\t\t<riskMap["low"] * 100>%");
	println("Moderate:\t<riskMap["moderate"] * 100>%");
	println("High:\t\t<riskMap["high"] * 100>%");
	println("Very high:\t<riskMap["very high"] * 100>%");
	println("\nUnit Size rating: <rating>\n");
	
	return rating;
}

public int unitSizeRating(map[str, real] riskMap) {
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

public map[str, real] unitSizeRiskMap(M3 eclipseModel) {
	set[loc] allMethods = methods(eclipseModel);
	map[str, real] riskMap = (
		"low": 0.0, "moderate": 0.0, "high": 0.0, "very high": 0.0
	);
	
	/* Iterate over all methods, add its LOC to correct category. */
	for (method <- allMethods) {
		int methodSize = countLOC(method, eclipseModel);
		if (methodSize <= 20)
			riskMap["low"] += methodSize;
		else if (methodSize <= 40)
			riskMap["moderate"] += methodSize;
		else if (methodSize <= 60)
			riskMap["high"] += methodSize;
		else if (methodSize > 60)
			riskMap["very high"] += methodSize;
	}

	/* Convert absolute LOC in each category to percentages. */
	real totalLines = sum([riskMap[index] | index <- riskMap]);
	riskMap = (index : riskMap[index] / totalLines | index <- riskMap);
	
	return riskMap;
}