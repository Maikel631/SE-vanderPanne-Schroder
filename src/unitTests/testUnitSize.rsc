module unitTests::testUnitSize

import codeProperties::unitSize;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;


public bool testUnitSize() {
	loc testProject = |project://testProject|;
	M3 testModel = createM3FromEclipseProject(testProject);

	/* Check if the percentages calculated in the riskMap are
	 * the same as expected. They can be calculated as following:
	 * low:      104 lines
	 * moderate:  25 lines
	 * high:      40 lines
	 * very high:  0 lines
	 * which is based on the method lengths. 
	 * Percentage: each line divided by total lines which is 169 this case.
	 */
 	map[str, real] riskMap = unitSizeRiskMap(testModel);
	real low = riskMap["low"];
	real moderate = riskMap["moderate"];
	real high = riskMap["high"]; 
	real veryHigh = riskMap["very high"];
	
	assert low == 104/169.0:     "testUnitSize: incorrect \'low\' percentage.";
	assert moderate == 65/169.0: "testUnitSize: incorrect \'moderate\' percentage.";
	assert high == 0/169.0:     "testUnitSize: incorrect \'high\' percentage.";
	assert veryHigh == 0/169.0:  "testUnitSize: incorrect \'very high\' percentage.";

	/* Test whether the rating is correct. */
	assert getUnitSizeScore(testModel) == 3: "testUnitSize: incorrect rating";

	return true;
}