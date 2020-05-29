// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String MOD1 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a % 2;
  // present: ' % 2'
  // absent: '$mod'
}
""";

const String MOD2 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : -0.0;
  return a % 2;
  // Cannot optimize due to potential -0.
  // present: '$mod'
  // absent: ' % 2'
}
""";

const String MOD3 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : -0.0;
  return (a + 1) % 2;
  // 'a + 1' cannot be -0.0, so we can optimize.
  // present: ' % 2'
  // absent: '$mod'
}
""";

const String REM1 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a.remainder(2);
  // Above can be compiled to '%'.
  // present: ' % 2'
  // absent: 'remainder'
}
""";

const String REM2 = r"""
foo(param) {
  var a = param ? 123.4 : -1;
  return a.remainder(3);
  // Above can be compiled to '%'.
  // present: ' % 3'
  // absent: 'remainder'
}
""";

const String REM3 = r"""
foo(param) {
  var a = param ? 123 : null;
  return 100.remainder(a);
  // No specialization for possibly null inputs.
  // present: 'remainder'
  // absent: '%'
}
""";

main() {
  runTests() async {
    check(String test) async {
      await compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(MOD1);
    await check(MOD2);
    await check(MOD3);
    await check(REM1);
    await check(REM2);
    await check(REM3);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
