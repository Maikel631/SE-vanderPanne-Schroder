/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  testClones.rsc
 * 		This file contains all clones related unitTests.
 *
 * USAGE:  ':test' in the rascal terminal.
 */
module Series2::unitTests::testClones

import Series2::duplication::clones;
import Series2::Series2;
import Series2::duplication::trimCode;
import List;
import Node;
import Set;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

M3 model = createM3FromEclipseProject(|project://testProject|);

test bool testIsParent() {
	int offsetA = 80;
	int lengthA = 200;
	
	int offsetB = 100;
	int lengthB = 180;
	
	loc a = |project://src/Series2/Series2.rsc|(offsetA, lengthA, <0, 0>, <0, 0>);
	loc b = |project://src/Series2/Series2.rsc|(offsetB, lengthB, <0, 0>, <0, 0>);
	
	assert(isParentTree(a, b) == true);
	assert(isParentTree(b, a) == false);
	
	/* Make 'a' not a parent of 'b' or the other way around. */
	a.offset = b.offset + b.length;
	assert(isParentTree(a, b) == false);
	assert(isParentTree(b, a) == false);
	
	loc c = |file://filePath/test1.txt|(0, 100);
	loc d = |file://filePath/test2.txt|(10, 50);
	
	assert(isParentTree(c, d) == false);
	assert(isParentTree(d, c) == false);
	
	return true;
}

test bool cloneClassGeneration() {
	rel[loc, loc] clonePairs = {
		/* Class1: Datum.java, Hotel.java, Gast.java */
		<|java+class:///Datum|, |java+class:///Hotel|>,
		<|java+class:///Hotel|, |java+class:///Gast|>,
		
		/* Class2: Kamer.java, Opgave5.java, unitTests.java */
		<|java+class:///Gast2|,    |java+class:///Kamer|>,
		<|java+class:///Opgave5|,  |java+class:///unitTests|>,
		<|java+class:///unitTests|,|java+class:///Kamer|>,
		<|java+class:///Kamer|,    |java+class:///Opgave5|>
	};
	
	set[set[loc]] cloneClasses = getCloneClasses(clonePairs, model, 4);
	
	assert(size(cloneClasses) == 2);
	/* Class 1: */
	assert({|java+class:///Datum|, |java+class:///Gast|, |java+class:///Hotel|} in cloneClasses);
	/* Class 2: */
	assert({|java+class:///Kamer|, |java+class:///Opgave5|, |java+class:///Gast2|, |java+class:///unitTests|} in cloneClasses);
	
	setCloneSize(6);
	return true;
}

test bool testGenClonePairs() {
	map[node, list[loc]] testMap =
		( makeNode("a", [1, 2, 3]) : [|project://testProject/src/Datum.java|(0, 100, <0, 20>, <20, 0>),
		                              |project://testProject/src/Gast.java|(0, 100, <0, 20>, <20, 0>),
		                              |project://testProject/src/Hotel.java|(0, 100, <0, 20>, <20, 0>)],
		  makeNode("b", [4, 5, 6]) : [|project://testProject/src/Gast2.java|(0, 100, <0, 20>, <20, 0>),
		                              |project://testProject/src/Opgave5.java|(0, 100, <0, 20>, <20, 0>),
		                              |project://testProject/src/Hotel.java|(0, 100, <0, 20>, <20, 0>)] 
		);
	lrel[loc, loc] clonePairs = getClonePairs(testMap);
	lrel[str, str] clonePairsStr = [<a.path, b.path>  | <a, b> <- clonePairs];
	assert(size(clonePairs) == 6);
	assert(clonePairsStr == 
			[<"/src/Gast.java",    "/src/Datum.java">,
			 <"/src/Hotel.java",   "/src/Datum.java">,
			 <"/src/Hotel.java",   "/src/Gast.java">,
			 <"/src/Hotel.java",   "/src/Gast2.java">,
			 <"/src/Opgave5.java", "/src/Gast2.java">,
			 <"/src/Opgave5.java", "/src/Hotel.java">]);
	
	return true;
}

test bool testGetMergedClonePairs() {
	loc parentA = |file://test/test1/fileA.txt|(20, 250, <0, 20>, <20, 0>); 
	loc parentB = |file://test/test1/fileB.txt|(50, 200, <0, 20>, <20, 0>);
	loc childA  = |file://test/test1/fileA.txt|(20, 220, <0, 20>, <20, 0>);
	loc childB  = |file://test/test1/fileB.txt|(70, 170, <0, 20>, <20, 0>);
	
	loc fileC1 = |file://test/test1/fileC.txt|(0, 100, <0, 20>, <20, 0>); 
	loc fileC2  = |file://test/test1/fileC.txt|(0, 100, <0, 20>, <20, 0>); 
	
	lrel[loc, loc] sortedClonePairs = [<parentA, parentB>, <childA, childB>, <fileC1, fileC2>];
	rel[loc, loc] result = getMergedPairs(sortedClonePairs);
	
	/* childA and childB should be merged into ParentA and parentB */
	assert(size(result) == 2);
	assert(<childA, childB> notin result);
	assert(<parentA, parentB> in result);
	assert(<fileC1,  fileC2>  in result);
	
	return true;
}