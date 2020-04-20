// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library equals_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST1 = r"""
foo(int a) {
  return a == null;
  // present: 'a == null'
  // absent: 'eq'
}
""";

const String TEST2 = r"""
foo(int a) {
  return a == 123;
  // present: 'a === 123'
  // absent: 'eq'
}
""";

const String TEST3 = r"""
foo(int a, int b) {
  return a == b;
  // present: 'a == b'
  // absent: 'eq'
  // absent: '==='
}
""";

const String TEST4 = r"""
foo(String a, String b) {
  return a == b;
  // present: 'a == b'
  // absent: 'eq'
  // absent: '==='
}
""";

// Comparable includes String and int, so can't be compared with `a == b` since
// that will convert an operand to make `2 == "2"` true.
const String TEST5 = r"""
foo(Comparable a, Comparable b) {
  return a == b;
  // present: 'a === b'
  // present: 'a == null'
  // present: 'b == null'
  // absent: 'eq'
  // absent: 'a == b'
}
""";

const String TEST6 = r"""
foo(dynamic a, dynamic b) {
  return a == b;
  // present: 'eq'
  // absent: '=='
}
""";

// StringBuffer uses `Object.==`, i.e. `identical`.  This can be lowered to `==`
// because no operand will cause JavaScript conversions.
const String TEST7 = r"""
foo(StringBuffer a, StringBuffer b) {
  return a == b;
  // present: ' == '
  // absent: '==='
  // absent: 'eq'
}
""";

main() {
  runTests() async {
    Future check(String test) {
      return compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(TEST1);
    await check(TEST2);
    await check(TEST3);
    await check(TEST4);
    await check(TEST5);
    await check(TEST6);
    await check(TEST7);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
