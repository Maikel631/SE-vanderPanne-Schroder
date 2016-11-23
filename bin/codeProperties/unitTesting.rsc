/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  unitTesting.rsc
 *        This file contains functions to calculate the unit test coverage of
 *        an eclipse project. This is the percentage of lines of code that is
 *        called (directly or indirectly) by the unit tests written for the
 *        project.
 *
 * USAGE: import 'codeProperties::unitTesting' to use the functions.
 */
module codeProperties::unitTesting

import IO;
import Set;
import List;
import Map;
import String;
import Relation;
import util::Math;

import lang::java::m3::Core;
import codeProperties::volume;


public int getTestCoverageScore(M3 eclipseModel) {
	/* Calculate from the percentage covered the rating. */
	map[str, num] testCoverage = unitTestCoverage(eclipseModel);
	num coverage = testCoverage["coverage"];
	num productionSize = testCoverage["productionSize"];
	num percentageCovered = testCoverage["percentageCovered"];
	
	int rating = testCoverageRating(percentageCovered);
	
	/* Output the calculated values, return rating. */
	println("=== Unit Test Coverage ===");
	println("Number of production lines of code:    <productionSize>");
	println("Unit test lines coverage:              <coverage>");
	println("Percentage covered of producion files: <round(percentageCovered, 0.001)>%\n");
	println("Unit test coverage rating: <rating>\n");
	
	return rating;
}

public int testCoverageRating(real percentageCovered) {
	/* Return the score 1 - 5 and -1 if percentage is invalid.
	 * Score is based on the percentage of production code covered by
	 * the unit tests.
	 */
	list[real] rankPercentages = [20.0, 60.0, 80.0, 95.0, 100.0]; 
	int curRank = 1;
	for (rank <- rankPercentages) {
		if (percentageCovered <= rank)
			return curRank;
		curRank += 1;
	}
	return -1;
}

public map[str, num] unitTestCoverage(M3 eclipseModel) {
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
	calledMethods = getAllCalledMethods(calledMethods, modelMethods, toMap(modelInvocations));
	/* Filter the unit test files from called methods as coverage has to
	 * be calculated over only production code.
	 */
	calledMethods -= testMethods;
	
    /* Determine the cumulative linecount for all called methods. */
    int coverage = 0;
    if (!isEmpty(calledMethods))
    	coverage = sum([countLOC(method, eclipseModel) | method <- calledMethods]);
	
	/* Determine code size of all non-testing methods and calculate covered percentage. */
	int productionSize = sum([countLOC(method, eclipseModel) | method <- (modelMethods - testMethods)]); 
	real percentageCovered = (coverage / toReal(productionSize)) * 100.0;

	return ("coverage": coverage, "productionSize": productionSize, "percentageCovered": percentageCovered);
}


/* Helper function to get a set of all called methods using all methods
 * of a project, and all its method invocations as generated by the M3 model.
 */
private set[loc] getAllCalledMethods(set[loc] calledMethods, set[loc] modelMethods, 
                                     map[loc, set[loc]] modelInvocation) {
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
			if (method in modelInvocation)
				calledMethods += {to | to <- modelInvocation[method], to in modelMethods};
		}
	}
	return calledMethods;
}