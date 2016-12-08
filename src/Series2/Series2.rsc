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
import Relation;
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

public set[set[loc]] findDuplicatesAST(M3 eclipseModel, bool detectType2=false) {
	set[Declaration] AST = createAstsFromEclipseProject(eclipseModel.id, false);
	if (detectType2 == true)
		AST = stripAST(AST);
	
	/* Top-bottom visit of all files. */
	map[node, list[loc]] treeMap = createTreeMap(AST, eclipseModel);
	count = otherCount = 0;
	
	rel[tuple[int, int], loc, loc] clonePairs = {};
	for (duplicateCode <- treeMap) {
		if (size(treeMap[duplicateCode]) < 2)
			continue;

		for (loc locA <- treeMap[duplicateCode]) {
			for (loc locB <- treeMap[duplicateCode], locA != locB) {
				/* Create the keys to sort all the file offset on, 
				 * so the pairs can be merged more easily. 
				 *
		         * You want to sort the file offset from smallest to largest,
		         * but you want to sort the file lengths from largest to smallest.
		         * Workaround: use as second sortKey: offset minus the length. 
				 */
				keyA = <locA.offset, locA.offset - locA.length>;
				keyB = <locB.offset, locB.offset - locB.length>;
				if (<keyA, locA, locB> notin clonePairs &&
				    <keyB, locB, locA> notin clonePairs) {
				
					/* Make sure when covering multiple file pairs, 
					 * the first index is always the same. Thus, swap if necessary. */
					if (locA.path < locB.path)
						clonePairs += <keyA, locA, locB>;
					else
						clonePairs += <keyB, locB, locA>;
				}
			}
		}
	}
	
	/* Sort on the keys created above and create a final sorted list of file relations. */
	lrel[loc, loc] sortedPairs = [<locA, locB> | <_, locA, locB> <- sort(clonePairs)];

	/* Optimization: use maps. */
	rel[loc, loc] realPairs = {};	
	map[tuple[loc, loc], bool] containedPairs = ();	
	map[tuple[loc, loc], bool] checked = ();
	
	/* Merge each sorted clonePair if it is the parent of the other.  */
	for (pairA <- sortedPairs) {
		for (pairB <- sortedPairs, pairA != pairB) {
			/* Some iterations can be skipped. */
			if (pairB in checked || pairB in containedPairs)
				continue;
			
			/* As everything is sorted, you can easily check if it is an contained pair.
			 * If pairB falls into pairA, it is part of the same clone. So pairA, is the
			 * parent of B.
			 */
			if (isParentTree(pairA[0], pairB[0]) && isParentTree(pairA[1], pairB[1])) {
				realPairs += pairA;
				containedPairs[pairB] = true;
			}
			else { /* Found likely a clone pair that is probably not part of a parent clone: thus add it. */
				realPairs += pairB;
			}
		}
		checked[pairA] = true;
	}

	/* Now all containedPairs are known, remove the likely pairs which were part of a parent clone. */
	realPairs -= domain(containedPairs);

	return getCloneClasses(realPairs);
}

/* TODO: It should be possible to get this a bit nicer... */
public set[set[loc]] getCloneClasses(rel[loc, loc] realPairs) {
	set[loc] indices = domain(realPairs) + range(realPairs);
	
	set[set[loc]] cloneClasses = {};
	for (i <- indices) {
		/* Define set of clone locations */
		set[loc] cloneClass = {i} + realPairs[i];
		
		for (j <- indices, i != j) {
			/* For the set of clone locations,
			 * check if you can find 
			 * the same location in the ranges, 
			 * if it is, j is part of the cloneClass;
			 */
			for (cloneLoc <- realPairs[j]) { 
				if (cloneLoc == i) {
					cloneClass += j;
					break;
				}
			}
		}
		cloneClasses += {cloneClass};
	}

	/* Extract the subset classes which have to be deleted as it is already
	 * a subset of another class.
	 */
	set[set[loc]] subSetClasses = {};
	for (classA <- cloneClasses) {
		for (classB <- cloneClasses, classA != classB) {
			/* Is classA subset of classB? */
			if (classA <= classB) {
				subSetClasses += {classA};
				break;
			}
		}
	}
	return cloneClasses - subSetClasses;
}


public set[Declaration] stripAST(set[Declaration] AST) {
	
	/* Filter code fragments for type 2 duplicates. */
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
	if (isEmpty(nodeList))
		return makeNode("invalid", []);
	
	/* Extract start and end node location. */
	if (loc locStart := getAnnotations(nodeList[0])["src"] &&
		loc locEnd := getAnnotations(nodeList[-1])["src"]) {
		loc mergedLoc = mergeLocations(locStart, locEnd);
		
		/* Check if the merged location encompassed at least 6 LOC. */
		if (mergedLoc.end.line - mergedLoc.begin.line < 6 || countLOC(mergedLoc, eclipseModel) < 6) {
				return makeNode("invalid", []);
		}
		
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

public loc extractSrc (node n) {
	if (loc location := getAnnotations(n)["src"])
		return location;
	return |file://null|;
}

public map[node, list[loc]] processNode(map[node, list[loc]] treeMap, node curNode) {
	/* Skip subtrees smaller than 15 nodes. */
	//if (treeSize(curNode) < 10)
	//	return treeMap;
	annotations = getAnnotations(curNode);
	
	/* Skip nodes with no annotations, cast src to loc. */
	if (!isEmpty(annotations) && "src" in annotations) {
		if (loc location := annotations["src"]) {
			if (location.end.line - location.begin.line < 6)
				return treeMap;
		
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

//public bool isPartOf(loc srcA, loc srcB) {
//	return (isParentTree(srcA, srcB) || isOverlapping(srcA, srcB));
//}

/* Is 'a' a subtree of 'b'? */
public bool isParentTree(loc srcA, loc srcB) {
	endA = srcA.offset + srcA.length;
	endB = srcB.offset + srcB.length;
	
	if (srcA.path == srcB.path && srcA.offset <= srcB.offset && endB <= endA)
		return true;
	return false;
}

/* Does 'a' overlap  'b'? */
//public bool isOverlapping(loc srcA, loc srcB) {
//	endA = srcA.offset + srcA.length;
//	endB = srcB.offset + srcB.length;
//	
//	if (srcA.path == srcB.path && (srcA.offset < endB || srcB.offset < endA))
//		return true;
//	return false;
//}

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

/* TODO: When using max size = 2, then it is considerably faster.
 * However, clone merging has to be changed significantly. Check how.
 */
public list[list[node]] sliceLists(list[node] inputList) {	
	sizeList = size(inputList);
	set[list[node]] sliceList = {};
	for (int i <- [0..sizeList]) {
		for (int j <- [i..sizeList + 1]) {
			if (i == j)
				continue;
			list[node] slice = inputList[i..j];
			int sliceSize = size(slice);
			if (sliceSize > 1 && sliceSize != size(inputList))
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