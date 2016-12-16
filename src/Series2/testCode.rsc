module Series2::testCode

import List;
import Set;
import IO;
import Relation;

import util::Math;
import vis::Figure;
import vis::Render;
import String;

public bool intInput(str s){
	return /^[0-9]+$/ := s;
}

public Figure higher(){
	int H = 100;
    return vcat( [ textfield("<H>", void(str s){H = toInt(s);}, intInput),
	               box(width(100), vresizable(false), vsize(num(){return H;}), fillColor("red"))
	             ], shrink(0.5), resizable(false));
}


public set[set[loc]] cloneClasses(rel[loc, loc] realPairs) {
	rel[loc, loc] reverseRel = {<b, a> | <a, b> <- realPairs};
	rel[loc, loc] allRel = reverseRel + realPairs;
	
	set[set[loc]] cloneClasses = {};
	for (i <- domain(allRel)) {
		set[loc] cloneClass = {i} + realPairs[i];
		for (j <- domain(allRel)) {
			for (item <- realPairs[j]) { 
				if (item == i)
					cloneClass += j;
			}
		}
		cloneClasses += {cloneClass};
	}
	for (class <- cloneClasses)
		println("<size(class)> - <class>");

	set[set[loc]] subSetClasses = {};
	/* Extract the subset classes which have to be deleted. */
	for (class1 <- cloneClasses) {
		for (class2 <- cloneClasses) {
			if (class1 == class2)
				continue;

			/* Is class1 subset of class2? */
			if (class1 <= class2) {
				subSetClasses += {class1};
				break;
			}
		}
	}
	return cloneClasses - subSetClasses;
}

public void genRels() {
	bla = [1, 2, 3];
	rel[int, int] clonePairs = {};
	for (int locA <- bla) {
		for (int locB <- bla, locA != locB) {
			if (<locB, locA> notin clonePairs)
				clonePairs += <locA, locB>;
		}
	}
	println(clonePairs);
}

public list[list[int]] sliceLists2(list[int] inputList) {
	int sizeList = size(inputList);
	set[list[int]] sliceList = {};
	for (int i <- [0..sizeList]) {
		for (int j <- [i..sizeList + 1], i != j) {
			if (j - i > 1 && j - i != sizeList)
				sliceList += inputList[i..j];
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

public lrel[int, int] mergeIntervals(lrel[int,int] intervals) {
	lrel[int, int] mergedIntervals = [];
	intervals = sort(intervals);
	
	mergedIntervals += intervals[0];
	for (higher <- intervals[1..]) {
		tuple[int, int] lower = mergedIntervals[-1];
		println(lower);
		if (higher[0] <= lower[1]) {
			int upp = max(lower[1], higher[1]);
			<_, mergedIntervals> = pop(mergedIntervals);
			mergedIntervals += <lower[0], upp>;
		}
		else
			mergedIntervals += higher;
	}
	return dup(mergedIntervals);
}



public Figure stairs(int nr){
	props = (nr == 0) ? [] : [mouseOver(stairs(nr-1))];
	return box(props + 
        [ ( nr %2 == 0 )? left() : right(),
          resizable(false),size(100),fillColor("green"),valign(0.25) ]);
}

public void kaas() {
	c = false; 
	b = box(fillColor(Color () { return c ? color("red") : color("green"); }),
		onMouseEnter(void () { c = true; }), onMouseExit(void () { c = false ; })
		,shrink(0.5));
	render(b);
}

Figure scaledbox(){
   int n = 100;
   return vcat([ hcat([ scaleSlider(int() { return 0; },     
                                    int () { return 200; },  
                                    int () { return n; },    
                                    void (int s) { n = s; }, 
                                    width(200)),
                        text(str () { return "n: <n>";})
                      ], left(),  top(), resizable(false)),  
                 computeFigure(Figure (){ return box(size(n), resizable(false)); })
               ]);
}

public void test123() {
	bool redraw = false;
	str s = "0";
	Figure getTextbox() {
	    return computeFigure(bool() {bool temp = redraw; redraw = false; return temp; },
	    Figure() {
	        return text(str() {return s; });
	    });
	}
	
	list[Figure] boxes = [];
	for (i <- [1..4]) {
	    t = text(toString(i));
	    boxes += box(t, onMouseEnter(void () {s = "<t[0]>"; redraw = true; }));
	}
	
	Figure changer = box(getTextbox());
	render(vcat(boxes + changer));
}


public bool checkIn(int numb) {
	if (numb in [100, 400, 95, 60]) 
		return true;
	return false;
}

public int testSpeed() {
	int i = 0;
	for (j <- [0..1000000]) { 
		if (checkIn(i + j)) 
			continue; 
		i += 1;
	}
	return 3;
}
