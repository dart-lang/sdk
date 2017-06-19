// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

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
  Future check(String test) {
    return compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
  }

  asyncTest(() => Future.wait([
        check(MOD1),
        check(MOD2),
        check(MOD3),
        check(REM1),
        check(REM2),
        check(REM3),
      ]));
}
