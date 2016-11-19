/* Participants: Gerard Schröder, Maikel van der Panne
 * StudentIDs: 10550237, 10576711
 * Study: Software Engineering
 * Date: 23-11-2016
 *
 * FILE:  unitSize.rsc
 *        This file contains functions to calculate the size (in lines of code)
 *        of units (methods). Based on the size of all methods in the eclipse
 *        project, a risk profile is set up.
 *
 *        This risk profile is then translated into a 1-5 star rating using a
 *        scoring table.
 *
 * USAGE: import 'codeProperties::unitTesting' to use the functions.
 */
module codeProperties::unitSize

import IO;

import lang::java::m3::Core;
import codeProperties::volume;

public void unitSize(M3 eclipseModel) {
	list[int] histValues = [];

	/* Determine the size of all methods in the model and count occurrences. */
	for (method <- methods(eclipseModel)) {
		histValues += countLOC(method, eclipseModel);
	}
	println(histValues);
}