module unitTests::testAll

import unitTests::testDuplication;
import unitTests::testTestCoverage;
import unitTests::testUnitSize;
import unitTests::testVolume;

public bool runAllTests() {
	assert testVolume() == true:         "runAllTests: testVolume fails";
	assert testDuplication() == true:    "runAllTests: testDuplication fails";
	assert testUnitSize() == true:       "runAllTests: testUnitSize fails";
	assert testTestCoverage() == true:   "runAllTests: testTestCoverage fails";
	assert testUnitComplexity() == true: "runAllTests: testUnitComplexity fails";
	
	return true;
}