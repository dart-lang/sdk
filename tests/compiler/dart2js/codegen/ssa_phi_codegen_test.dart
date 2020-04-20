// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test that parameters keep their names in the output.

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
void foo(bar) {
  var a = 1;
  if (bar) {
    a = 2;
  } else {
    a = 3;
  }
  print(a);
  print(a);
}
""";

const String TEST_TWO = r"""
void main() {
  var t = 0;
  for (var i = 0; i == 0; i = i + 1) {
    t = t + 10;
  }
  print(t);
}
""";

const String TEST_THREE = r"""
foo(b, c, d) {
  var val = 42;
  if (b) {
    c = c && d;
    if (c) {
      val = 43;
    }
  }
  return val;
}
""";

const String TEST_FOUR = r"""
foo() {
  var a = true;
  var b = false;
  for (var i = 0; a; i = i + 1) {
    if (i == 9) a = false;
    for (var j = 0; b; j = j + 1) {
      if (j == 9) b = false;
    }
  }
  print(a);
  print(b);
}
""";

const String TEST_FIVE = r"""
void main() {
  var hash = 0;
  for (var i = 0; i == 0; i = i + 1) {
    hash = hash + 10;
    hash = hash + 42;
  }
  print(hash);
}
""";

main() {
  runTests() async {
    await compileAndMatchFuzzy(TEST_ONE, 'foo', "var x = x \\? 2 : 3;");
    await compileAndMatchFuzzy(TEST_ONE, 'foo', "print\\(x\\);");

    await compileAndMatchFuzzy(TEST_TWO, 'main', "x \\+= 10");
    await compileAndMatchFuzzy(TEST_TWO, 'main', "\\+\\+x");

    // Check that we don't have 'd = d' (using regexp back references).
    await compileAndDoNotMatchFuzzy(TEST_THREE, 'foo', '(x) = \1');
    await compileAndMatchFuzzy(TEST_THREE, 'foo', 'return x');

    // Check that a store just after the declaration of the local
    // only generates one instruction.
    await compileAndMatchFuzzy(TEST_THREE, 'foo', 'x = 42');

    await compileAndDoNotMatchFuzzy(TEST_FOUR, 'foo', '(x) = \1;');

    await compileAndDoNotMatch(TEST_FIVE, 'main', new RegExp('hash0'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
