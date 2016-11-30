module Series2::duplication


import IO;
import List;
import String;

import util::Math;
import lang::java::m3::Core;
import Series2::trimCode;

public int getDuplicationScore(M3 eclipseModel) {
	int totalLOC = getVolume(eclipseModel);

	/* Find how many LOC are duplicated, convert it into a rating. */
	int duplicatedLOC = findDuplicates(eclipseModel);
	real duplicatedPerc = (duplicatedLOC / toReal(totalLOC)) * 100; 
	int rating = duplicationRating(duplicatedPerc);
	
	/* Output the LOC and rating, return the rating. */
	println("=== Duplication ===");
	println("Number of duplicated lines: <duplicatedLOC>");
	println("Duplicated lines percentage: <round(duplicatedPerc, 0.001)>%");
	println("\nDuplication rating: <rating>\n");
	
	return rating;
}

public int duplicationRating(real duplicatedPerc) {
	list[int] thresholds = [3, 5, 10, 20];
	
	/* Convert this percentage into a rating. */
	int rating = 5;
	for (threshold <- thresholds) {
		if (duplicatedPerc > threshold)
			rating -= 1;
	}
	return rating;
}

public int findDuplicates(M3 eclipseModel) {
	/* Determine all source files in the project. */
	set[loc] srcFiles = files(eclipseModel);
	
	int frameSize = 6;
	int linesDuplicated = 0;
	map[str, list[loc]] snippetList = ();
	
	for (srcFile <- srcFiles) {
		/* Split methods larger than 6 lines into snippets. */
		list[str] snippets = createDupSnippets(srcFile, frameSize, eclipseModel);
		if (isEmpty(snippets))
			continue;

		int dupLinesCount = 0;
		bool dupFound = false;
		
		for (snippet <- snippets) {
			/* Snippet in snippet list, thus a duplicate is found. */
			if (snippet in snippetList) {
				if (dupFound == false) {
					/* First time snippet found, add frameSize twice. */
					dupLinesCount = (size(snippetList[snippet]) > 2)  ? frameSize : frameSize * 2;
					
					dupFound = true;
				}
				/* Ongoing duplicate, add two lines if not found before. */
				else
					dupLinesCount += (size(snippetList[snippet]) > 2) ? 1 : 2;
				snippetList[snippet] += srcFile;
			}
			else {
				/* Unknown snippet, add to list for future matching. */
				snippetList[snippet] = [srcFile];
				
				/* If a duplicate ends here, add its linecount. */
				linesDuplicated += (dupFound ? dupLinesCount : 0);
				dupFound = false;
			}
		}
		if (dupFound)
			linesDuplicated += dupLinesCount;
	}
	return linesDuplicated;
}

public list[str] createDupSnippets(loc location, int frameSize, M3 eclipseModel) {
	str strippedContents = trimCode(location, eclipseModel);
	
	/* Split content into lines, return if less than 'frameSize' lines. */
	list[str] lines = split("\n", trim(strippedContents));
	if (size(lines) < frameSize)
		return [];
	
	/* Trim lines, generate all snippets of 'frameSize' lines. */
	trimmedLines = [trim(line) | line <- lines];
	return for (i <- [0..size(trimmedLines) - frameSize + 1]) {
		append intercalate("\n", trimmedLines[i..i+frameSize]);
	}
}