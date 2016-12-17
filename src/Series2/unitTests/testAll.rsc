/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  testAll.rsc
 * 		This file runs all unit tests implemented.
 *
 * USAGE:  ':test' in the rascal terminal.
 */

module Series2::unitTests::testAll

import Series2::unitTests::testClones;
import Series2::unitTests::testAst;
import Series2::unitTests::testSeries2;


test bool testAll() {
	assert(testIsParent() &&              /* Clones */
	       cloneClassGeneration() &&
	       testGenClonePairs() &&
	       testGetMergedClonePairs() &&
	       testMergeLocations() &&        /* AST */
	       testSliceLists() &&         
	       testGetterSetter() &&          /* Series2 */
	       testfindDuplicatesAst());
	return true;
}