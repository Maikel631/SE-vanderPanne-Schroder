module Series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import IO;
import String;
import List;
import Set;

import util::Resources;

//import lang::java::jdt::m3::AST;

//public M3 m1 = createM3FromEclipseProject(|project://smallsql0.21_src|);

public int countLinesOfCode(projectLoc) {
	
	allFiles = getProject(|project://smallsql0.21_src|);

	int lineCount = 0;
	visit(allFiles) {
		case file(f): {
			if ( /.*\.java/ := f.file ) {
				iprintln(f);
				contents = readFile(f);
				strippedContents = trimCode(contents);		
				lineCount += size(split("\n", strippedContents)); 
			}
		}
	}
	return lineCount;
}

public str trimCode(str S) {
    /* Remove multi line comments - on single and multi line. */
    trimmedComments = visit(S) {
 	    case /\/\*(?:.)*?\*\// => ""
 	    case /\/\*(?:.|\n|\r|\n\r)*?\*\// => "\n"
     }
    /* Remove all // comments. */
    trimmedComments2 = visit(trimmedComments) {
 	    case /\/\/.*/ => ""
    }
    /* Remove all whitespace lines. */
    return visit(trimmedComments2) {
 	    case /\s*\n/ => "\n"
    }
}