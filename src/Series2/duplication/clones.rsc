/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  clones.rsc
 *        This file contains functions to create clone pairs, merge clone pairs
 *        and converting these merged clone pairs back to clone classes. The
 *        required input is a 'treeMap', which contains the preliminary clone
 *        classes. It is created by visiting the AST of a Java Eclipse project
 *        and creating a mapping between subtrees and their locations.
 *
 *        The final clone classes are the maximum duplicates for the project.
 *
 * USAGE: import 'Series2::duplication::clones' to use the functions.
 */
module Series2::duplication::clones

import Map;
import Set;
import List;
import Relation;

import lang::java::m3::AST;
import lang::java::m3::Core;

import Series2::duplication::trimCode;

/* Using the tree map, create all clone pairs. These clone pairs include clones
 * that later will be subsumed. By sorting everything, the merging is optimized.
 */
public lrel[loc, loc] getClonePairs(map[node, list[loc]] treeMap) {
	rel[loc, loc] clonePairs = {};
	
	/* Loop over the preliminary clone classes and create pairs. */
	for (cloneClass <- treeMap) {
		if (size(treeMap[cloneClass]) < 2)
			continue;

		for (loc locA <- treeMap[cloneClass]) {
			for (loc locB <- treeMap[cloneClass], locA != locB) {
				/* Optimization: skip pairs that overlap. */
				if (locA.path == locB.path && !(locA.end.line < locB.begin.line || locB.end.line < locA.begin.line))
					continue;

				/* First index must be the same, swap if necessary. */
				if (locA.path < locB.path)
					<locB, locA> = <locA, locB>;
				clonePairs += <locA, locB>;
			}
		}
	}
	
	bool isLess(<loc locA, loc A2>, <loc locB, loc B2>) {
		/* Sort the file offset ascending and sort the file length
		 * descending by using 'offset - length' as second sort key.
		 */
		return ((<<locA.offset, locA.offset - locA.length>, locA, A2>) <
				(<<locB.offset, locB.offset - locB.length>, locB, B2>));
	}
	return sort(clonePairs, isLess);
}


/* Remove clones that are a subset of other clones. Because the pairs are
 * sorted on file offset and clone size, smaller clones can be merged by 
 * if the first location the pairA is the parent of pairB. If so, pairB can
 * be discarded. 
 */
public rel[loc, loc] getMergedPairs(lrel[loc, loc] clonePairs) {
	/* Optimization: use maps. */
	rel[loc, loc] mergedClonePairs = {};	
	map[tuple[loc, loc], bool] containedPairs = ();	
	map[tuple[loc, loc], bool] checked = ();
	
	/* Merge each sorted clonePair if it is the parent of the other.  */
	for (pairA <- clonePairs) {
		for (pairB <- clonePairs, pairA != pairB) {
			/* Some iterations can be skipped. */
			if (checked[pairB]? || containedPairs[pairB]?)
				continue;
			
			/* As everything is sorted, you can easily check if it is an contained pair.
			 * If pairB falls into pairA, it is part of the same clone. So pairA, is the
			 * parent of B.
			 */
			if (isParentTree(pairA[0], pairB[0]) && isParentTree(pairA[1], pairB[1])) {
				mergedClonePairs += pairA;
				containedPairs[pairB] = true;
			}
			else { /* Found likely a clone pair that is probably not part of a parent clone: thus add it. */
				mergedClonePairs += pairB;
			}
		}
		checked[pairA] = true;
	}

	/* Now all containedPairs are known, remove the likely pairs which were
	 * part of a parent clone. Use the domain to get the correct values.
	 */
	return (mergedClonePairs - domain(containedPairs));
}


/* TODO: It should be possible to get this a bit nicer... */
public set[set[loc]] getCloneClasses(rel[loc, loc] clonePairs, M3 eclipseModel, int cloneSize) {
	set[loc] indices = domain(clonePairs) + range(clonePairs);
	
	set[set[loc]] cloneClasses = {};
	for (i <- indices) {
		/* Define set of clone locations */
		set[loc] cloneClass = {i} + clonePairs[i];
		
		for (j <- indices, i != j) {
			/* For the set of clone locations check if you can find 
			 * the same location in the ranges, if it is found,
			 * j is part of the cloneClass.
			 */
			for (cloneLoc <- clonePairs[j]) { 
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
	
	/* Now all final clone classes are defined. However, it is not sure if all
	 * clones are larger than 'cloneSize' lines (which is a slow operation). Now, we
	 * only have to check one of the clones per class to be larger than 'cloneSize'.
	 */
	set[set[loc]] mergedClasses = cloneClasses - subSetClasses;
	set[set[loc]] finalClasses = {};
	for (cloneClass <- mergedClasses) {
		loc clone = toList(cloneClass)[0];	
		if (countLOC(clone, eclipseModel) >= cloneSize) {
			finalClasses += {cloneClass};
		}
	}
	
	return finalClasses;
}

/* Is 'b' a subtree of 'a', thus its parent? */
public bool isParentTree(loc srcA, loc srcB) {
	endA = srcA.offset + srcA.length;
	endB = srcB.offset + srcB.length;
	if (srcA.path == srcB.path && (
		(srcA.offset < srcB.offset && endB <= endA) ||
		(srcA.offset <= srcB.offset && endB < endA)
	   ))
		return true;
	return false;
}