/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 10-11-2016
 *
 * FILE:   Series1.rsc
 *         This file contains the code for the Series1 exercises
 *         for the Software Evolution course.
 *
 * USAGE: 'import Series1' to make use of the defined functions.   
 */
module Series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::Resources;

import IO;
import String;
import List;
import Set;

/* Count the lines of code in a project. */
public int countLinesOfCode(projectLoc) {
	int lineCount = 0;
	allFiles = getProject(|project://smallsql0.21_src|);

	/* Visit all files in the directory structure;  */
	visit(allFiles) {
		case file(f): {
			/* Match on a '*.java' file. */
			if (/.*\.java/ := f.file) {
				contents = readFile(f);
				strippedContents = trimCode(contents);
				
				/* Trim the contents to remove newline at start of file. */
				lineCount += size(split("\n", trim(strippedContents)));
				iprintln("<f> <lineCount>");
			}
		}
	}
	return lineCount;
}

/* Remove all comments and whitespace lines from the code. */
public str trimCode(str S) {
	/* Remove string contents as they could contain comments. */
	trimmedQuotes = visit(S) {
		case /\".*?\"/ => "\"\""
	}
    /* Remove multiline comments - on single-line. */
    trimmedComments1 = visit(trimmedQuotes) {
 	    case /\/\*(?:.)*?\*\// => ""
    }
    /* Remove multiline comments - on multiple lines. */
    trimmedComments2 = visit(trimmedComments1) {
    	case /\/\*(?:.|\n|\r|\n\r)*?\*\// => "\n" 
    }
    /* Remove all single-line comments. */
    trimmedComments3 = visit(trimmedComments2) {
 	    case /\/\/.*/ => ""
    }
    /* Remove all whitespace lines. */
    return visit(trimmedComments3) {
 	    case /\s*\n/ => "\n"
    }
}