/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:   Series1.rsc
 *         This file contains the code for the Series1 exercises
 *         for the Software Evolution course.
 *
 * USAGE: import 'Series1' to use the functions.   
 */
module Series1

import IO;
import Set;
import List;

import util::Math;

import analysis::statistics::Descriptive;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import codeProperties::volume;
import codeProperties::unitComplexity;
import codeProperties::duplication;
import codeProperties::unitSize;
import codeProperties::unitTesting;

import unitTests::testAll;


public bool testSIGMethods() {
	return runAllTests();
}

public void calculateSIGSmall() {
	println("=== Creating smallSQL model ===");
	M3 smallsqlModel = createM3FromEclipseProject(|project://smallsql0.21_src|);
	println("=== Calculate SIG scores ===");
	calculateSIGScore(smallsqlModel);
	
	/* Clear volumeIndex which caches some line count results. */
	clearIndex();
}

public void calculateSIGLarge() {
	println("\n=== Creating HSQLdb model ===");
	M3 hsqldbModel = createM3FromEclipseProject(|project://hsqldb-2.3.1|);
	println("=== Calculate SIG scores ===");
	calculateSIGScore(hsqldbModel);
	
	/* Clear volumeIndex which caches some line count results. */
	clearIndex();
}

/* Calculate SIG scores for the Eclipse M3 project model. */
public real calculateSIGScore(M3 eclipseModel) {
	/* Calculate score for each source code property. */
	int volume = getVolumeScore(eclipseModel);
	int unitComplexity = getComplexityScore(eclipseModel);
	int duplication = getDuplicationScore(eclipseModel);
	int testCoverage = getTestCoverageScore(eclipseModel);
	int unitSize = getUnitSizeScore(eclipseModel);
	
	/* Determine the ISO 9126 maintainability subscores. */
	real analysability = mean([volume, duplication, unitSize, testCoverage]);
	real changeability = mean([unitComplexity, duplication]);
	real stability = toReal(testCoverage);
	real testability = mean([unitComplexity, unitSize, testCoverage]);
	
	println("=== ISO 9126 Maintability subscores ===");
	println("Analysability:  <round(analysability, 0.001)>");
	println("Changeability:  <round(changeability, 0.001)>");
	println("Stability:      <round(stability,     0.001)>");
	println("Testability:    <round(testability,   0.001)>");
	
	/* Determine the overall maintainability score. */
	real overallScore = mean([analysability, changeability, stability, testability]);
	println("\n=== Overall Maintability score ===");
	println("Overall score:  <round(overallScore, 0.001)>\n");
	
	return overallScore;
}
