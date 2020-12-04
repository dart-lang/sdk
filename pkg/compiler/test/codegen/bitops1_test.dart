// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library bitops1_test;

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
  return param & 15;
  // present: 'return param & 15;'
}
""";

const String TEST2 = r"""
int foo(int param) {
  return 15 & param;
  // Constant position canonicalization.
  // present: 'return param & 15;'
}
""";

const String TEST3 = r"""
int foo(int param) {
  return param & 0;
  // present: 'return 0;'
}
""";

const String TEST4 = r"""
int foo(int param) {
  return param & 12 & 6;
  // Reassociation and constant folding.
  // present: 'return param & 4'
  // absent: '12'
  // absent: '6'
}
""";

const String TEST5 = r"""
int foo(int param) {
  return 12 & param & 6;
  // Reassociation and constant folding.
  // present: 'return param & 4'
  // absent: '12'
  // absent: '6'
}
""";

const String TEST6 = r"""
foo(param) {
  return 15 | 7 & param;
  // Constant position canonicalization.
  // present: 'return param & 7 | 15;'
}
""";

const String TEST7 = r"""
foo(param) {
  param = toUInt32(param + 1);
  if (param == 0) return -1;
  return param & 0xFFFFFFFF | 1;
  // Removal of identity mask.
  // present: 'return (param | 1) >>> 0;'
}
int toUInt32(int x) => x & 0xFFFFFFFF;
""";

const String TEST8 = r"""
int foo(int aaa, int bbb, int ccc) {
  return 1 | aaa | bbb | 2 | ccc | 4;
  // Reassociation and constant folding.
  // present: 'aaa | bbb | ccc | 7'
}
int callFoo(int a, int b, int c) => foo(a, b, c);
""";

const String TEST9 = r"""
int foo(int aaa, int bbb, int ccc) {
  return 255 & aaa & bbb & 126 & ccc & 15;
  // Reassociation and constant folding not yet implemented for '&'.
  // We want to avoid moving the constants too far right, since masking can
  // enable a more efficient representation.
  // TODO(sra): constant-fold later masks into earlier mask.
  //
  // present: 'aaa & 255 & bbb & 126 & ccc & 15'
}
int callFoo(int a, int b, int c) => foo(a, b, c);
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
    await check(TEST5);
    await check(TEST6);
    await check(TEST7);
    await check(TEST8);
    await check(TEST9);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
