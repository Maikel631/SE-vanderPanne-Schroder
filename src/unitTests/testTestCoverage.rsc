module unitTests::testTestCoverage

import codeProperties::unitTesting;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

public bool testTestCoverage() {
	loc testProject = |project://testProject|;
	M3 testModel = createM3FromEclipseProject(testProject);

	/* Check if the line count of all methods is the same as the line count given
	 * by the testCoverage score.
	 */
 	map[str, num] testCoverage = unitTestCoverage(testModel);
	num coverage = testCoverage["coverage"];
	num productionSize = testCoverage["productionSize"];
	num percentageCovered = testCoverage["percentageCovered"];

	assert coverage == 0: "testTestCoverage: incorrect test coverage.";
	assert productionSize == 169: "testTestCoverage: incorrect production size."; 
	assert percentageCovered == 0: "testTestCoverage: incorrect percentage covered";

	/* Test whether the rating is correct. */
	assert getTestCoverageScore(testModel) == 1: "testTestCoverage: incorrect rating";

	return true;
}