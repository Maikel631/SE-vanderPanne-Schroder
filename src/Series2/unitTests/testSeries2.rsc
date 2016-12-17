/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  testSeries2.rsc
 * 		This file contains Series2 related unitTests.
 *
 * USAGE:  ':test' in the rascal terminal.
 */
module Series2::unitTests::testSeries2

import Series2::Series2;
import Series2::duplication::trimCode;
import Series2::duplication::clones;
import Series2::duplication::ast;

import util::Math;
import IO;
import List;
import Set;
import Node;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

M3 model = createM3FromEclipseProject(|project://testProject|);

/* Use the rascal terminal and type ':test' to get a complete test report. */
test bool testGetterSetter() {
	int curSize = getCloneSize();
	setCloneSize(curSize + 1);
	
	assert(getCloneSize() == curSize + 1);
	return true;
}

/* Test the main duplication checker */
test bool testfindDuplicatesAst() {
	setCloneSize(6);
	
	bool assertCloneSize(set[set[loc]] cloneClasses) {
		for (cloneClass <- cloneClasses) {
			for (clone <- cloneClass)
				assert(countLOC(clone, model) >= 6);
		}
		return true;
	}
	set[set[loc]] cloneClasses1 = findDuplicatesAST(model, detectType2=false);
	assert(assertCloneSize(cloneClasses1));
	
	set[set[loc]] cloneClasses2 = findDuplicatesAST(model, detectType2=true);
	assert(assertCloneSize(cloneClasses2));

	// Is this always the case?
	//assert(size(union(cloneClasses1)) <= size(union(cloneClasses2))); 

	set[set[str]] getClassNames(set[set[loc]] cloneClasses) {
		set[set[str]] finalSet = {};
		for (cloneClass <- cloneClasses) {
			set[str] temp = {};
			for (clone <- cloneClass) {
				temp += clone.file;
			}
			finalSet += {temp};
		}
		return finalSet;
	}

	set[set[str]] cloneClasses1Strs = getClassNames(cloneClasses1);
	assert({"Gast.java", "Gast2.java"} in cloneClasses1Strs);
	assert({"Opgave5.java","Gast.java","Gast2.java"} in cloneClasses1Strs);
	
	set[set[str]] cloneClasses2Strs = getClassNames(cloneClasses2);
	assert({"Gast.java", "Gast2.java"} in cloneClasses2Strs);
	assert({"Opgave5.java","Gast.java","Gast2.java","Hotel.java"} in cloneClasses2Strs);

	return true;
}
