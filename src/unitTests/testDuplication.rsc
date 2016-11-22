module unitTests::testDuplication

import IO;
import lang::java::jdt::m3::Core;
import codeProperties::duplication;

public bool testDuplication() {
	/* Define test project and source file path, create model. */
	loc project = |project://testProject|;
	loc srcFile = project + "src/Kamer.java";
	M3 testModel = createM3FromEclipseProject(project);
	
	/* Create snippets for one of the project files, frameSize = 6. */
	list[str] snippets = createDupSnippets(srcFile, 6, testModel);
	list[str] snippetsResult = [
		"import java.util.*;public class Kamer {Gast gast;boolean vrij;Kamer() {vrij = true;",
		"public class Kamer {Gast gast;boolean vrij;Kamer() {vrij = true;}",
		"Gast gast;boolean vrij;Kamer() {vrij = true;}public String toString() {",
		"boolean vrij;Kamer() {vrij = true;}public String toString() {return \"\" + gast;",
		"Kamer() {vrij = true;}public String toString() {return \"\" + gast;}",
		"vrij = true;}public String toString() {return \"\" + gast;}}"
	];
	assert snippets == snippetsResult : "testDuplication: incorrect snippets";
	
	/* Test whether it indicates the correct amount of duplicated lines. */
	int dupLines = findDuplicates(testModel);
	assert dupLines == 30 : "testDuplication: incorrect #lines";
	
	/* Test whether the correct rating is returned for this project. */
	int score = getDuplicationScore(testModel);
	assert score == 2 : "testDuplication: incorrect rating";
	
	return true;
}