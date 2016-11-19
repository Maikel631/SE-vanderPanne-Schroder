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

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import codeProperties::volume;
import codeProperties::unitComplexity;
import codeProperties::duplication;
import codeProperties::unitSize;
import codeProperties::unitTesting;

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
