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
	map[node, list[loc]] treeMap = removeAnnotations(AST);
	
	/* Loop over subtrees, find subtrees > 6. */
	for (subtree <- treeMap) {
		if (size(treeMap[subtree]) < 2)
			continue;
		
		/* Check size of the duplicated subtree. */
		if (countLOC(treeMap[subtree][0], eclipseModel) > 6)
			println(treeMap[subtree][0]);
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

public map[node, list[loc]] removeAnnotations(set[Declaration] AST) {
	map[node, list[loc]] treeMap = ();
	
	AST = visit(AST) {
		case node n => {
			println(n);
			annotations = getAnnotations(n);
			
			/* Skip nodes with no annotations. */
			if (!isEmpty(annotations)) {
				if (loc srcNode := annotations["src"]) {
					location = srcNode;
					cleanNode = delAnnotations(n);
					
					if (cleanNode in treeMap)
						treeMap[cleanNode] += location;
					else
						treeMap[cleanNode] = [location];
					
					cleanNode;
				}
				else
					n;
			}
			else
				n;
		}
		//case value n: println(n);
	}
	//iprintln(AST);
	//for (snippet <- treeMap)
	//	println(treeMap[snippet]);
		
	return treeMap;
}