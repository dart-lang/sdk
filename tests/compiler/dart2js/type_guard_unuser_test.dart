// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const String TEST_ONE = r"""
foo(a) {
  int c = foo(true);
  if (a) c = foo(2);
  return c;
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
foo(int param1, int param2) {
  return 0 + param1 + param2;
}
""";

const String TEST_THREE_WITH_BAILOUT = r"""
foo(int param1, int param2) {
  var t;
  for (int i = 0; i < 1; i++) {
    t = 0 + param1 + param2;
  }
  return t;
}
""";

main() {
  String generated = compile(TEST_ONE, 'foo');
  RegExp regexp = new RegExp(getIntTypeCheck(anyIdentifier));
  Iterator<Match> matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 0);
  Expect.isTrue(generated.contains(r'return a === true ? $.foo(2) : c;'));

  generated = compile(TEST_TWO, 'foo');
  regexp = const RegExp("foo\\(1\\)");
  matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);

  generated = compile(TEST_THREE, 'foo');
  regexp = new RegExp(getNumberTypeCheck('param1'));
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = new RegExp(getNumberTypeCheck('param2'));
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_THREE_WITH_BAILOUT, 'foo');
  regexp = new RegExp(getNumberTypeCheck('param1'));
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = new RegExp(getNumberTypeCheck('param2'));
  Expect.isTrue(regexp.hasMatch(generated));
}
