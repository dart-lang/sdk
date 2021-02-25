// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library bitops2_test;

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

const String TEST1 = r"""
int foo(int param) {
  return (param & 0xFF0000) >> 16;
  // Shift mask reduction.
  // present: 'return param >>> 16 & 255;'
  // absent: 'FF0000'
  // absent: '16711680'
}
""";

const String TEST2 = r"""
int foo(int param) {
  param &= 0xFFFFFFFF;
  if (param == 0) return -1;
  return param << 0;
  // Shift-by-zero reduction.
  // present: 'return param;'
}
""";

const String TEST3 = r"""
int foo(int param) {
  param &= 0xFFFFFFFF;
  if (param == 0) return -1;
  return ((param >> 8) & 7) << 8;
  // Shift-mask-unshift reduction.
  // present: 'return param & 1792;'
}
""";

const String TEST4 = r"""
foo(int color) {
  int alpha = 100;
  int red = (color & 0xFF0000) >> 16;
  int green = (color & 0xFF00) >> 8;
  int blue = (color & 0xFF) >> 0;

  return (alpha & 255) << 24 |
      (red & 255) << 16 |
      (green & 255) << 8 |
      (blue & 255) << 0;

  // present: 'color & 16777215 | 1677721600'
  // absent: '<<'
  // absent: '>>'
}
""";

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
          check: checkerForAbsentPresent(test));
    }

    await check(TEST1);
    await check(TEST2);
    await check(TEST3);
    await check(TEST4);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
