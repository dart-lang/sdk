// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test constant folding on numbers.

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String INT_PLUS_ZERO = """
int foo(int x) => x;
main() {
  int x = foo(0);
  return (x & 1) + 0;
}
""";

const String ZERO_PLUS_INT = """
int foo(int x) => x;
main() {
  int x = foo(0);
  return 0 + (x & 1);
}
""";

const String NUM_PLUS_ZERO = """
num foo(num x) => x;
main() {
  num x = foo(0);
  return x + 0;
}
""";

const String ZERO_PLUS_NUM = """
num foo(num x) => x;
main() {
  num x = foo(0);
  return 0 + x;
}
""";

const String INT_TIMES_ONE = """
int foo(int x) => x;
main() {
  int x = foo(0);
  return (x & 1) * 1;
}
""";

const String ONE_TIMES_INT = """
int foo(int x) => x;
main() {
  int x = foo(0);
  return 1 * (x & 1);
}
""";

const String NUM_TIMES_ONE = """
num foo(num x) => x;
main() {
  num x = foo(0);
  return x * 1;
}
""";

const String ONE_TIMES_NUM = """
num foo(num x) => x;
main() {
  num x = foo(0);
  return 1 * x;
}
""";

main() {
  var plusZero = new RegExp(r"\+ 0");
  var zeroPlus = new RegExp(r"0 \+");
  var timesOne = new RegExp(r"\* 1");
  var oneTimes = new RegExp(r"1 \*");

  test() async {
    await compileAndDoNotMatch(INT_PLUS_ZERO, 'main', plusZero);
    await compileAndDoNotMatch(ZERO_PLUS_INT, 'main', zeroPlus);
    await compileAndMatch(NUM_PLUS_ZERO, 'main', plusZero);
    await compileAndMatch(ZERO_PLUS_NUM, 'main', zeroPlus);
    await compileAndDoNotMatch(INT_TIMES_ONE, 'main', timesOne);
    await compileAndDoNotMatch(ONE_TIMES_INT, 'main', oneTimes);
    await compileAndDoNotMatch(NUM_TIMES_ONE, 'main', timesOne);
    await compileAndDoNotMatch(ONE_TIMES_NUM, 'main', oneTimes);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await test();
  });
}
