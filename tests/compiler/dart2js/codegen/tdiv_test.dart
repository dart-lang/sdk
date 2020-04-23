// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library tdiv_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST1 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a ~/ 2;
  // Above can be compiled to division followed by truncate.
  // present: ' / 2 | 0'
  // absent: 'tdiv'
}
""";

const String TEST2 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a ~/ 3;
  // Above can be compiled to division followed by truncate.
  // present: ' / 3 | 0'
  // absent: 'tdiv'
}
""";

const String TEST3 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : -1;
  return a ~/ 2;
  // Potentially negative inputs go via fast helper.
  // present: '_tdivFast'
  // absent: '/'
}
""";

const String TEST4 = r"""
foo(param1, param2) {
  var a = param1 ? 0xFFFFFFFF : 0;
  return a ~/ param2;
  // Unknown divisor goes via full implementation.
  // present: '$tdiv'
  // absent: '/'
}
""";

const String TEST5 = r"""
foo(param1, param2) {
  var a = param1 ? 0xFFFFFFFF : 0;
  var b = param2 ? 3 : 4;
  return a ~/ b;
  // We could optimize this with range analysis, but type inference summarizes
  // '3 or 4' to uint31, which is not >= 2.
  // present: '$tdiv'
  // absent: '/'
}
""";

const String TEST_REGRESS_37502 = r"""
foo(param1, param2) {
  var a = param1 ? 1.2 : 12.3;
  var b = param2 ? 3.14 : 2.81;
  return (a ~/ b).gcd(2);
  // The result of ~/ is int; gcd is defined only on int and is too complex
  // to be inlined.
  //
  // present: 'JSInt_methods.gcd'
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
    await check(TEST_REGRESS_37502);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
