module unitTests::testUnitComplexity

import IO;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import codeProperties::unitComplexity;

public bool testUnitComplexity() {
	/* Define test project, create model and AST. */
	loc project = |project://testProject|;
	M3 testModel = createM3FromEclipseProject(project);
	set[Declaration] AST = createAstsFromEclipseProject(testModel.id, false);
	
	/* Create a riskMap for this model and check its correctness. */
	map[str, num] riskMap = complexityRiskMap(testModel);
	num low = riskMap["low"];
	num moderate = riskMap["moderate"];
	num high = riskMap["high"]; 
	num veryHigh = riskMap["very high"];
	
	assert low == 1:     "testUnitSize: incorrect \'low\' percentage.";
	assert moderate == 0: "testUnitSize: incorrect \'moderate\' percentage.";
	assert high == 0:     "testUnitSize: incorrect \'high\' percentage.";
	assert veryHigh == 0:  "testUnitSize: incorrect \'very high\' percentage.";

	/* Test whether the rating is correct. */
	assert getComplexityScore(testModel) == 5: "testUnitSize: incorrect rating";

	return true;
}