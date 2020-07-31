// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library new_rti_is_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

// 'N' tests all have a nullable input so should not reduce is-test.
// TODO(NNBD): Add tests with non-nullable input types.

const TEST1N = r"""
foo(int a) {
  return a is double;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST2N = r"""
foo(int a) {
  return a is num;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST3N = r"""
foo(double a) {
  return a is int;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST4N = r"""
foo(double a) {
  return a is num;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST5N = r"""
foo(num a) {
  return a is int;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST6N = r"""
foo(num a) {
  return a is double;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST1I = r"""
foo(a) {
  if (a is int) return a is double;
  // present: 'return true'
}
""";

const TEST2I = r"""
foo(a) {
  if (a is int) return a is num;
  // present: 'return true'
}
""";

const TEST3I = r"""
foo(a) {
  if (a is double) return a is int;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST4I = r"""
foo(a) {
  if (a is double) return a is num;
  // present: 'return true'
}
""";

const TEST5I = r"""
foo(a) {
  if (a is num) return a is int;
  // absent: 'return true'
  // absent: 'return false'
}
""";

const TEST6I = r"""
foo(a) {
  if (a is num) return a is double;
  // present: 'return true'
}
""";

main() {
  runTests() async {
    Future check(String test) {
      return compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(TEST1N);
    await check(TEST2N);
    await check(TEST3N);
    await check(TEST4N);
    await check(TEST5N);
    await check(TEST6N);

    await check(TEST1I);
    await check(TEST2I);
    await check(TEST3I);
    await check(TEST4I);
    await check(TEST5I);
    await check(TEST6I);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
