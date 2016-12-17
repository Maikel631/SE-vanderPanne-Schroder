/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  ast.rsc
 *        This file contains functions that act on the AST of a Java Eclipse
 *        project. The main purpose of these functions is to create a mapping
 *        between AST subtrees (which represent some snippet of code) and the
 *        the locations where in the sourcecode this subtree occurs. If a
 *        subtree occurs more than once, it means it is a duplicate.
 *
 *        To support type 2 clones, a method is included that generalizes a
 *        number of AST properties. A number of combinations are generated for
 *        sequences of nodes, after which each combination is converted into
 *        an overarching node. This node is then added to the mapping.
 *
 * USAGE: import 'Series2::duplication::ast' to use the functions.
 */
module Series2::duplication::ast

import IO;
import Map;
import Node;
import List;

import lang::java::m3::AST;
import lang::java::m3::Core;

/* Creates a mapping of AST subtrees to locations where it occurs. */
public map[node, list[loc]] createTreeMap(set[Declaration] AST, M3 eclipseModel, int cloneSize) {
	map[node, list[loc]] treeMap = ();

	top-down visit(AST) {
		case node n:
			treeMap = processNode(treeMap, n, cloneSize);
		case list[node] n:
			treeMap = processNodeList(treeMap, n, eclipseModel, cloneSize);
	}	
	return treeMap;
}

/* Filter code fragments for type 2 duplicates. */
public set[Declaration] stripAST(set[Declaration] AST) {
	return visit(AST) {
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

/* Combinations of sequences of nodes will be added as new nodes. */
public map[node, list[loc]] processNodeList(map[node, list[loc]] treeMap, list[node] nodeList,
											M3 eclipseModel, int cloneSize) {
	/* Create slices of the nodeList. */
	nodeListSlices = sliceLists(nodeList);
	
	/* Create node out of each nodeList permutation. */
	for (slice <- nodeListSlices) {
		newNode = createNodeFromList(slice, eclipseModel, cloneSize);
		if (getName(newNode) == "invalid")
			continue;
	
		/* Process this new node. */
		treeMap = processNode(treeMap, newNode, cloneSize);
	}

	return treeMap;
}

/* Using a list of nodes, create a new node that contains them. */
public node createNodeFromList(list[node] nodeList, M3 eclipseModel, int cloneSize) {
	if (isEmpty(nodeList))
		return makeNode("invalid", []);

	/* Extract start and end node location. */
	if ("src" in getAnnotations(nodeList[0]) &&
		loc locStart := getAnnotations(nodeList[0])["src"] &&
		"src" in getAnnotations(nodeList[-1]) &&
		loc locEnd := getAnnotations(nodeList[-1])["src"])
	{
		/* Check if the merged location encompassed at least 'cloneSize' LOC. */
		if (locEnd.end.line - locStart.begin.line < cloneSize)
			return makeNode("invalid", []);

		/* Create a node using the nodeList and location. */
		newNode = makeNode("node", nodeList);
		return setAnnotations(newNode, ("src": mergeLocations(locStart, locEnd)));
	}
	return makeNode("invalid", []);
}

/* Add a node to the treeMap if it is valid. */
public map[node, list[loc]] processNode(map[node, list[loc]] treeMap, node curNode, int cloneSize) {
	annotations = getAnnotations(curNode);
	
	/* Skip nodes with no annotations, cast src to loc. */
	if (!isEmpty(annotations) && "src" in annotations) {
		if (loc location := annotations["src"]) {
			if (location.end.line - location.begin.line < cloneSize)
				return treeMap;

			/* Add node to the treeMap. */
			if (curNode in treeMap)
				treeMap[curNode] += location;
			else
				treeMap[curNode] = [location];
		}
	}
	
	return treeMap;
}

/* TODO: When using max size = 2, then it is considerably faster.
 * However, clone merging has to be changed significantly. Check how.
 */
public list[list[node]] sliceLists(list[node] inputList) {	
	int sizeList = size(inputList);
	list[list[node]] sliceList = [];
	for (int i <- [0..sizeList]) {
		for (int j <- [i..sizeList + 1], i != j) {
			/* Check if the current size of the slice is larger then 1, as single nodes are already
			 * added to the tree map.
			 */
			if (j - i > 1 && j - i != sizeList)
				sliceList += [inputList[i..j]]; 
		}
	}
	return sliceList;
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

/* Not necessary, but still useful! */
public node cleanTree(node curNode) {
	curNode = delAnnotations(curNode);
	curNode = visit (curNode) {
		case node n => delAnnotations(n)
	}
	return curNode;
}