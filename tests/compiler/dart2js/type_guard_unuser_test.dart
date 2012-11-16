// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo(a) {
  int b = foo(true);
  if (a) b = foo(2);
  return b;
}
""";


const String TEST_TWO = r"""
bar(a) {}
foo(d) {
  int a = 1;
  int c = foo(1);
  if (true) {}
  return a + c;
}
""";

const String TEST_THREE = r"""
foo(int a, int b) {
  return 0 + a + b;
}
""";

const String TEST_THREE_WITH_BAILOUT = r"""
foo(int a, int b) {
  var t;
  for (int i = 0; i < 1; i++) {
    t = 0 + a + b;
  }
  return t;
}
""";

main() {
  String generated = compile(TEST_ONE, entry: 'foo');
  RegExp regexp = new RegExp(getIntTypeCheck(anyIdentifier));
  Iterator<Match> matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 0);
  Expect.isTrue(generated.contains(r'return a === true ? $.foo(2) : b;'));

  generated = compile(TEST_TWO, entry: 'foo');
  regexp = new RegExp("foo\\(1\\)");
  matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);

  generated = compile(TEST_THREE, entry: 'foo');
  regexp = new RegExp(getNumberTypeCheck('a'));
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = new RegExp(getNumberTypeCheck('b'));
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_THREE_WITH_BAILOUT, entry: 'foo');
  regexp = new RegExp(getNumberTypeCheck('a'));
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = new RegExp(getNumberTypeCheck('b'));
  Expect.isTrue(regexp.hasMatch(generated));
}
