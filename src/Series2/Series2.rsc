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
	map[node, list[loc]] treeMap = createTreeMap(AST);
	
	/* Loop over subtrees. */
	for (subtree <- treeMap) {
		if (size(treeMap[subtree]) < 2)
			continue;
			
		/* */
		println(treeMap[subtree]);
	}
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

public map[node, list[loc]] createTreeMap(set[Declaration] AST) {
	map[node, list[loc]] treeMap = ();
	
	top-down visit(AST) {
		case Declaration n: treeMap = processNode(treeMap, n);
		case Expression n:  treeMap = processNode(treeMap, n);
		case Statement n:   treeMap = processNode(treeMap, n);
	}
	//for (snippet <- treeMap)
	//	println(treeMap[snippet]);
		
	return treeMap;
}

public map[node, list[loc]] processNode(map[node, list[loc]] treeMap, node curNode) {
	/* Skip subtrees smaller than 15 nodes. */
	if (treeSize(curNode) < 15)
		return treeMap;
	annotations = getAnnotations(curNode);
	
	/* Skip nodes with no annotations, cast src to loc. */
	if (!isEmpty(annotations)) {
		if (loc location := annotations["src"]) {
			cleanNode = delAnnotations(curNode);
			if (curNode in treeMap)
				treeMap[cleanNode] += location;
			else
				treeMap[cleanNode] = [location];
		}
	}
	
	return treeMap;
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