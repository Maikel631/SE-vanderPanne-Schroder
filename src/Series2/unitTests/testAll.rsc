module Series2::unitTests::testAll

import Series2::Series2;
import Series2::trimCode;

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
	
	setCloneSize(4); // Adjust for this test.
	set[set[loc]] cloneClasses = getCloneClasses(clonePairs, model);
	
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
