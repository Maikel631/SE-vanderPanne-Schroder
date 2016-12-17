/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  testAst.rsc
 * 		This file contains all AST related unitTests.
 *
 * USAGE:  ':test' in the rascal terminal.
 */
module Series2::unitTests::testAst

import Series2::duplication::ast;
import Node;
import List;
import util::Math;

/* Test the merging of two locations. */
test bool testMergeLocations() {
	int offsetA = 5;
	int offsetB = 100;
	int lengthA = 10;
	int lengthB = 200;
	loc a = |project://src/Series2/Series2.rsc|(offsetA, lengthA, <0, 0>, <0, 0>);
	loc b = |project://src/Series2/Series2.rsc|(offsetB, lengthB, <0, 0>, <0, 0>);

	loc ab = mergeLocations(a, b);
	loc ba = mergeLocations(b, a);

	assert(ab == ba);
	assert(ab.offset == ba.offset && ab.offset == min(offsetA, offsetB));
	assert(ab.length == ba.length && ab.length == (b.offset - a.offset) + b.length);

	return true;
}

/* Test the output of sliceLists function. */
test bool testSliceLists() {
	list[node] testList = [
		 makeNode("a", [1, 2]),
		 makeNode("b", [2, 3]),
		 makeNode("c", [3, 4]),
		 makeNode("a", [5, 6])
	];
	 
	list[list[node]] result = sliceLists(testList);
	
	/* Whole list may not be part of the end result */
	assert(testList notin result);

	/* All slices have to be larger than 1 */
	assert(size(result) == size([1 | res <- result, size(res) >= 2]));

	/* Check final result to be the right slices. */
	assert(result == [testList[0..2], testList[0..3], testList[1..3], testList[1..4], testList[2..4]]);
	
	return true;
}