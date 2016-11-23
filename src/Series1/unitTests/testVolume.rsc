module Series1::unitTests::testVolume

import Series1::codeProperties::volume;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import IO;

public bool testVolume() {
	loc testProject = |project://testProject|;
	M3 testModel = createM3FromEclipseProject(testProject);
	
	/* Test whether the line count of the files:
	 * Datum: 45, Gast: 20, Gast2: 20, Hotel: 52, Kamer:11, Opgave5: 11 = 200
	 * is the same as counted by the getVolume function.
	 */
	int totalLines = 45 + 20 * 2 + 52 + 11 + 52;
	assert getVolume(testModel) == totalLines: "testVolume: incorrect line count."; 
	
	/* Test whether the rating is correct. */
	assert getVolumeScore(testModel) == 5: "testVolume: incorrect rating";
	
	return true;
}