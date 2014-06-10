// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
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
  asyncTest(() => Future.wait([
    compile(TEST_ONE, entry: 'foo', check: (String generated) {
      RegExp regexp = new RegExp(getIntTypeCheck(anyIdentifier));
      Iterator<Match> matches = regexp.allMatches(generated).iterator;
      checkNumberOfMatches(matches, 0);
      Expect.isTrue(
          generated.contains(
              new RegExp(r'return a === true \? [$A-Z]+\.foo\(2\) : b;')));
    }),
    compile(TEST_TWO, entry: 'foo', check: (String generated) {
      RegExp regexp = new RegExp("foo\\(1\\)");
      Iterator<Match> matches = regexp.allMatches(generated).iterator;
      checkNumberOfMatches(matches, 1);
    }),
    compile(TEST_THREE, entry: 'foo', check: (String generated) {
      RegExp regexp = new RegExp(getNumberTypeCheck('a'));
      Expect.isTrue(regexp.hasMatch(generated));
      regexp = new RegExp(getNumberTypeCheck('b'));
      Expect.isTrue(regexp.hasMatch(generated));
    }),
    compile(TEST_THREE_WITH_BAILOUT, entry: 'foo', check: (String generated) {
      RegExp regexp = new RegExp(getNumberTypeCheck('a'));
      Expect.isTrue(regexp.hasMatch(generated));
      regexp = new RegExp(getNumberTypeCheck('b'));
      Expect.isTrue(regexp.hasMatch(generated));
    })
  ]));
}
