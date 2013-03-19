// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_ONE = r"""
void foo(bar) {
  for (int i = 0; i < 1; i++) {
    print(1 + bar);
    print(1 + bar);
  }
}
""";

// Check that modulo does not have any side effect and we are
// GVN'ing the length of [:list:].
const String TEST_TWO = r"""
void foo(a) {
  var list = new List<int>();
  list[0] = list[0 % a];
  list[1] = list[1 % a];
}
""";

// Check that is checks get GVN'ed.
const String TEST_THREE = r"""
void foo(a) {
  print(42);  // Make sure numbers are used.
  print(a is num);
  print(a is num);
}
""";

// Check that instructions that don't have a builtin equivalent can
// still be GVN'ed.
const String TEST_FOUR = r"""
void foo(a) {
  print(1 >> a);
  print(1 >> a);
}
""";

main() {
  String generated = compile(TEST_ONE, entry: 'foo');
  RegExp regexp = new RegExp(r"1 \+ [a-z]+");
  checkNumberOfMatches(regexp.allMatches(generated).iterator, 1);

  generated = compile(TEST_TWO, entry: 'foo');
  checkNumberOfMatches(new RegExp("length").allMatches(generated).iterator, 1);

  generated = compile(TEST_THREE, entry: 'foo');
  checkNumberOfMatches(new RegExp("number").allMatches(generated).iterator, 1);

  generated = compile(TEST_FOUR, entry: 'foo');
  checkNumberOfMatches(new RegExp("shr").allMatches(generated).iterator, 1);
}
