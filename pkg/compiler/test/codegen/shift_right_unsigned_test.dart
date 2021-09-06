// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.11

library shru_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const COMMON = r"""
int g1 = 0, g2 = 0;
int sink1 = 0, sink2 = 0;

main() {
  for (int i = 0; i < 0x100000000; i = i + (i >> 4) + 1) {
    g1 = g2 = i;
    sink1 = callFoo(i, 1 - i, i);
    sink2 = callFoo(2 - i, i, 3 - i);
  }
}
""";

const tests = [
  r"""
// constant-fold positive
int foo(int param) {
  int a = 100;
  int b = 2;
  return a >>> b;
  // present: 'return 25;'
}
""",

  r"""
// constant-fold negative
int foo(int param) {
  int a = -1;
  int b = 30;
  return a >>> b;
  // present: 'return 3;'
}
  """,

  r"""
// base case
int foo(int value, int shift) {
  return value >>> shift;
  // Default code pattern:
  // present: 'JSInt_methods.$shru(value, shift);'
}
int callFoo(int a, int b, int c) => foo(a, b);
""",

  r"""
// shift by zero
int foo(int param) {
  return param >>> 0;
  // present: 'return param >>> 0;'
}
  """,

  r"""
// shift by one
int foo(int param) {
  return param >>> 1;
  // present: 'return param >>> 1;'
}
""",

  r"""
// shift masked into safe range
int foo(int value, int shift) {
  return value >>> (shift & 31);
  // present: 'return value >>> (shift & 31);'
}
int callFoo(int a, int b, int c) => foo(a, b);
""",

  r"""
// idempotent shift by zero
int foo(int param) {
  return param >>> 0 >>> 0 >>> 0;
  // present: 'return param >>> 0;'
}
""",

  r"""
// idempotent shift by zero #2
int foo(int param) {
  return (param & 15) >>> 0;
  // present: 'return param & 15;'
}
  """,

// TODO(sra): shift-shift reduction.
//  r"""
//// shift-shift-reduction
//int foo(int param) {
//  return param >>> 1 >>> 2;
//  // present: 'return param >>> 3'
//}
//""",

  r"""
// mask-shift to shift-mask reduction
int foo(int param) {
  return (param & 0xF0) >>> 4;
  // present: 'return param >>> 4 & 15'
}
""",

  r"""
// mask-shift to shift-mask reduction enabling mask reduction
int foo(int param) {
  return (param & 0x7FFFFFFF) >>> 31;
  // present: 'return 0;'
}
""",
];

main() {
  runTests() async {
    Future check(String test) {
      String program = COMMON + '\n\n' + test;
      if (!test.contains('callFoo')) {
        program += 'int callFoo(int a, int b, int c) => foo(a);\n';
      }
      return compile(program,
          entry: 'main',
          methodName: 'foo',
          disableTypeInference: false,
          soundNullSafety: true,
          check: checkerForAbsentPresent(test));
    }

    for (final test in tests) {
      String name = 'unnamed';
      if (test.startsWith('//')) {
        final comment = test.split('\n').first.replaceFirst('//', '').trim();
        if (comment.isNotEmpty) name = comment;
      }
      print('-- $name');
      await check(test);
    }
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
