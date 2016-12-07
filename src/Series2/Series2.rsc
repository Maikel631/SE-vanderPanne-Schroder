/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  duplication.rsc
 *        This file contains functions to calculate the number of lines of
 *        code that occurs more than once in equal code blocks of at least
 *        6 lines. In our methods, these blocks are referred to as 'snippets'.
 *
 *        The percentage of all code that consists of duplicated code is then
 *        calculated and turned into a 1-5 score using a scoring table.
 *
 * USAGE: import 'codeProperties::duplication' to use the functions.
 */
module Series2::Series2

import IO;
import Set;
import Type;
import List;
import Node;
import Map;
import String;
import Traversal;
import ParseTree;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import Series2::trimCode;

public void findDuplicatesAST(M3 eclipseModel) {
	set[Declaration] AST = createAstsFromEclipseProject(eclipseModel.id, false);
	
	/* Top-bottom visit of all files. */
	map[node, list[loc]] treeMap = createTreeMap(AST, eclipseModel);
	count = otherCount = 0;
	
	for (duplicateCode <- treeMap) {
		if (size(treeMap[duplicateCode]) < 2)
			continue;
		println(treeMap[duplicateCode]);
	}
	
	/* Loop over subtrees. */
	//fullLocList = [];
	//for (locList <- range(treeMap)) {
	//	if (size(locList) < 2)
	//		continue;
	//	fullLocList += locList;
	//}
	//println(size(fullLocList));
	//
	//someList = {};
	//for (location1 <- fullLocList) {
	//	for (location2 <- fullLocList, location2 != location1) {
	//		println(location1);
	//		println(location2);
	//		println(isSubTree(location1, location2));
	//		if (!isSubTree(location1, location2)) {
	//			someList += location1;
	//		}
	//	}
	//}
	//println(size(someList));
	//println(someList);
}

public void stripAST(M3 eclipseModel) {
	AST = createAstsFromEclipseProject(eclipseModel.id, false);
	
	/* Filter code fragments for type 2 duplicates. */
	AST = visit(AST) {
		case Type x => string()
		case \number(_) => \number("1")
		case \booleanLiteral(_) => \booleanLiteral(true)
		case \stringLiteral(_) => \stringLiteral("_")
		case \variable(_, extraDimensions) => \variable("var", extraDimensions)
		case \variable(_, extraDimensions, init) => \variable("var", extraDimensions, init)
		case \parameter(a, b, c) => \parameter(a, "param", c)
		case \simpleName(a) => \simpleName("var")
	}
}

public map[node, list[loc]] createTreeMap(set[Declaration] AST, M3 eclipseModel) {
	map[node, list[loc]] treeMap = ();
	
	top-down visit(AST) {
		case Declaration n:
			treeMap = processNode(treeMap, n);
		case Expression n:
			treeMap = processNode(treeMap, n);
		case Statement n:
			treeMap = processNode(treeMap, n);
		case list[Declaration] n:
			treeMap = processNodeList(treeMap, n, eclipseModel);
		case list[Expression] n:
			treeMap = processNodeList(treeMap, n, eclipseModel);
		case list[Statement] n:
			treeMap = processNodeList(treeMap, n, eclipseModel);
	}
	//for (snippet <- treeMap)
	//	println(treeMap[snippet]);
		
	return treeMap;
}

public node createNodeFromList(list[node] nodeList, M3 eclipseModel) {
	/* Extract start and end node location. */
	if (loc locStart := getAnnotations(nodeList[0])["src"] &&
		loc locEnd := getAnnotations(nodeList[-1])["src"]) {
		loc mergedLoc = mergeLocations(locStart, locEnd);
		
		/* Check if the merged location encompassed at least 6 LOC. */
		if (countLOC(mergedLoc, eclipseModel) < 6)
			return makeNode("invalid", []);
		
		/* Create a node using the nodeList and location. */
		newNode = makeNode("node", nodeList);
		return setAnnotations(newNode, ("src": mergedLoc));
	}
	return makeNode("invalid", []);
}

public map[node, list[loc]] processNodeList(map[node, list[loc]] treeMap,
											list[node] nodeList, M3 eclipseModel) {
	/* Create slices of the nodeList. */
	nodeListSlices = sliceLists(nodeList);
	
	/* Create node out of each nodeList permutation. */
	for (slice <- nodeListSlices) {
		newNode = createNodeFromList(slice, eclipseModel);
		if (getName(newNode) == "invalid")
			continue;
	
		/* Process this new node. */
		treeMap = processNode(treeMap, newNode);
	}

	return treeMap;
}

public map[node, list[loc]] processNode(map[node, list[loc]] treeMap, node curNode) {
	/* Skip subtrees smaller than 15 nodes. */
	if (treeSize(curNode) < 10)
		return treeMap;
	annotations = getAnnotations(curNode);
	
	/* Skip nodes with no annotations, cast src to loc. */
	if (!isEmpty(annotations) && "src" in annotations) {
		if (loc location := annotations["src"]) {
			/* Not necessary; makes more visible. */
			//curNode = cleanTree(curNode);
			if (curNode in treeMap)
				treeMap[curNode] += location;
			else
				treeMap[curNode] = [location];
		}
	}
	
	return treeMap;
}

/* Is 'a' a subtree of 'b'? */
public bool isSubTree(loc srcA, loc srcB) {
	endA = srcA.offset + srcA.length;
	endB = srcB.offset + srcB.length;
	
	if (srcA.path == srcB.path && srcA.offset >= srcB.offset && endA <= endB)
		return true;
	return false;
}

/* Not necessary! */
public node cleanTree(node curNode) {
	curNode = delAnnotations(curNode);
	curNode = visit (curNode) {
		case node n => delAnnotations(n)
	}
	return curNode;
}

public int treeSize(node curNode) {
	subTreeSize = 0;
	visit (curNode) {
		case Declaration n: subTreeSize += 1;
		case Expression n: subTreeSize += 1;
		case Statement n: subTreeSize += 1;
	}
	return subTreeSize;
}

public list[list[node]] sliceLists(list[node] inputList) {
	sizeList = size(inputList);
	set[list[node]] sliceList = {};
	for (int i <- [0..sizeList]) {
		for (int j <- [i..sizeList + 1]) {
			if (i == j)
				continue;
			list[node] slice = inputList[i..j];
			if (size(slice) > 1)
				sliceList += slice; 
		}
	}
	return toList(sliceList);
}

public loc mergeLocations(loc locFileA, loc locFileB) {	
	if (locFileA.offset > locFileB.offset)
		<locFileA, locFileB> = <locFileB, locFileA>;

	/* Calc new length by subtracting the offsets to get all chars inbetween. */
	locFileA.length = (locFileB.offset - locFileA.offset) + locFileB.length;
	locFileA.end.line = locFileB.end.line;
	locFileA.end.column = locFileB.end.column;
	
	return locFileA;
}