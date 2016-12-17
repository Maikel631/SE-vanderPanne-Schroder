/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 17-12-2016
 *
 * FILE:  Series2.rsc
 *        This file contains functions to calculate the clone classes that
 *        present in a Java Eclipse project. The AST of the project is used
 *        to find preliminary clone classes by creating a mapping between
 *        AST subtrees and locations where the subtree occurs.
 *
 *        To find clones of sequences of nodes (e.g. statements), combinations
 *        of the nodes in for example a method or if-statement are added to the
 *		  mapping as well.
 *        
 *        After completing this mapping, clone pairs are formed which we can
 *        then merge to get rid of superfluous clones. The filtered clone pair
 *        list can then be converted back to clone classes.
 *
 * USAGE: import 'Series2::Series2' to use the functions.
 */
module Series2::Series2

import IO;

import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

import Series2::duplication::ast;
import Series2::duplication::clones;

/* Globals for writing to a static location. */
public loc writeLoc = |project://Software%20Evolution/src/Series2/|;

/* Getters and setters for clone detection. */
private int cloneSize = 6;
public int getCloneSize() { return cloneSize; }
public void setCloneSize(int newSize) { cloneSize = newSize; }

/* Main function used to find duplicates given an M3 model. */
public set[set[loc]] findDuplicatesAST(M3 eclipseModel, bool detectType2=false) {
	set[Declaration] AST = createAstsFromEclipseProject(eclipseModel.id, false);
	if (detectType2 == true)
		AST = stripAST(AST);
	
	/* Top-bottom visit of all files to create preliminary clones. */
	map[node, list[loc]] treeMap = createTreeMap(AST, eclipseModel, cloneSize);
	
	/* Create clone pairs and merge them if possible. */
	lrel[loc, loc] clonePairs = getClonePairs(treeMap);
	rel[loc, loc] mergedClonePairs = getMergedPairs(clonePairs);
	
	/* Convert the final clone pairs back to clone classes.*/
	set[set[loc]] cloneClasses = getCloneClasses(
		mergedClonePairs, eclipseModel, cloneSize
	);
	
	/* Write the results to file. */
	str typeDetection = (!detectType2) ? "type1" : "type2";
	str fileName = "result-<eclipseModel.id.authority>-<cloneSize>-<typeDetection>";
	writeFile(writeLoc + fileName, "<cloneClasses>;");
	
	return cloneClasses;
}