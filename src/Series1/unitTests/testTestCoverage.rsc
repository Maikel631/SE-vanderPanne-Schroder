module Series1::unitTests::testTestCoverage

import IO;

import Series1::codeProperties::unitTesting;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

public bool testTestCoverage() {
	loc testProject = |project://testProject|;
	M3 testModel = createM3FromEclipseProject(testProject);

	/* Check if the line count of all methods is the same as the line count given
	 * by the testCoverage score.
	 */
 	map[str, real] testCoverage = unitTestCoverage(testModel);
	real coverage = testCoverage["coverage"];
	real productionSize = testCoverage["productionSize"];
	real percentageCovered = testCoverage["percentageCovered"];
	println(percentageCovered);

	/* Coverage: Datum(), Gast() and Gast.toString(). */
	assert coverage == 40: "testTestCoverage: incorrect test coverage.";
	assert productionSize == 169: "testTestCoverage: incorrect production size."; 
	assert percentageCovered == (40/169.0) * 100: "testTestCoverage: incorrect percentage covered";

	/* Test whether the rating is correct. */
	assert getTestCoverageScore(testModel) == 2: "testTestCoverage: incorrect rating";

	return true;
}