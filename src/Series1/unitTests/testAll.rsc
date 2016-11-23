module Series1::unitTests::testAll

import Series1::unitTests::testDuplication;
import Series1::unitTests::testTestCoverage;
import Series1::unitTests::testUnitSize;
import Series1::unitTests::testVolume;
import Series1::unitTests::testUnitComplexity;

public bool runAllTests() {
	assert testVolume() == true:         "runAllTests: testVolume fails";
	assert testDuplication() == true:    "runAllTests: testDuplication fails";
	assert testUnitSize() == true:       "runAllTests: testUnitSize fails";
	assert testTestCoverage() == true:   "runAllTests: testTestCoverage fails";
	assert testUnitComplexity() == true: "runAllTests: testUnitComplexity fails";
	
	return true;
}