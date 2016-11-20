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
public int calculateSIGScore(eclipseModel) {	
	/* Calculate score for each source code property. */
	volume = getVolumeScore(eclipseModel);
	unitComplexity = getComplexityScore(eclipseModel);
	duplication = getDuplicationScore(eclipseModel);
	
	/* Determine the ISO 9126 maintainability subscores. */
	
	/* Determine the overall maintainability score. */
	return 0;
}
