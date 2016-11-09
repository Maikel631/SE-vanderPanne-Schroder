module Series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import IO;

//import lang::java::jdt::m3::AST;

//public M3 m1 = createM3FromEclipseProject(|project://smallsql0.21_src|);

public int countLinesOfCode(M3 m) {
	
	set[loc] mMethods = methods(m);
	
	int lineCount = 0;
	//for (method <- mMethods) {
		loc method = |java+method:///smallsql/junit/TestGroupBy/testTest()|; // 27
		contents = readFileLines(method);
		iprintln(method);
		bool inComment = false;
		for (str line <- contents) {
			switch (line) {
				case /^\s*$|^\s*\/\/.*$/:
					lineCount += 0;
				case /\/\*/:
					inComment = true;
				case /\*\//:
					inComment = false;
				case /\S/:
					if (inComment == false) {
						lineCount += 1;
						println(line);	
					}					
				default:
					lineCount += 0;
			}
		}

	//}
	return lineCount;
}