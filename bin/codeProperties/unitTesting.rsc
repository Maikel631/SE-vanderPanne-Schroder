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
import String;
import Relation;

import lang::java::m3::Core;
import codeProperties::volume;

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