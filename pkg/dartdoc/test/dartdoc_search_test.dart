// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dartdoc_search_test;

// TODO(rnystrom): Use "package:" URL (#4968).
part '../lib/src/dartdoc/nav.dart';
part '../lib/src/client/search.dart';

const String URL = 'dummy-url';

testTopLevelVsMembers() {
	var search = new SearchText('timer');
	var match = obtainMatch(search, 'timer');
	// Matching a top-level field 'timer';
	var topLevelResult = new Result(match, FIELD, URL);
	// Matching a member field 'timer' in 'Foo';
	var memberResult = new Result(match, FIELD, URL, type: 'Foo');
	Expect.equals(-1, resultComparator(topLevelResult, memberResult),
		"Top level fields should be preferred to member fields");
}

testTopLevelFullVsPrefix() {
	var search = new SearchText('cancel');
	var fullMatch = obtainMatch(search, 'cancel');
	var prefixMatch = obtainMatch(search, 'cancelable');
	// Matching a top-level method 'cancel';
	var fullResult = new Result(fullMatch, METHOD, URL);
	// Matching a top-level method 'cancelable';
	var prefixResult = new Result(prefixMatch, METHOD, URL);
	Expect.equals(-1, resultComparator(fullResult, prefixResult),
		"Full matches should be preferred to prefix matches");
}

testMemberFullVsPrefix() {
	var search = new SearchText('cancel');
	var fullMatch = obtainMatch(search, 'cancel');
	var prefixMatch = obtainMatch(search, 'cancelable');
	// Matching a member method 'cancel' in 'Isolate';
	var fullResult = new Result(fullMatch, METHOD, URL, type: 'Isolate');
	// Matching a member field 'cancelable' in 'Event';
	var prefixResult = new Result(prefixMatch, FIELD, URL, type: 'Event');
	Expect.equals(-1, resultComparator(fullResult, prefixResult),
		"Full matches should be preferred to prefix matches");
}

void main() {
	testTopLevelVsMembers();
	testTopLevelFullVsPrefix();
	testMemberFullVsPrefix();
}