module Series2::testCode

import List;
import Set;
import IO;

public list[list[int]] sliceLists(list[int] inputList) {
	sizeList = size(inputList);
	set[list[int]] sliceList = {};
	for (int i <- [0..sizeList]) {
		for (int j <- [i..sizeList + 1]) {
			if (i == j)
				continue;
			list[int] slice = inputList[i..j];
			if (size(slice) > 1)
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

