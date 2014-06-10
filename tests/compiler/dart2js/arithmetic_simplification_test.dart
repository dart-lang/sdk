// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding on numbers.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String INT_PLUS_ZERO = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return (x & 1) + 0;
}
""";

const String ZERO_PLUS_INT = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return 0 + (x & 1);
}
""";

const String NUM_PLUS_ZERO = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return x + 0;
}
""";

const String ZERO_PLUS_NUM = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return 0 + x;
}
""";


const String INT_TIMES_ONE = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return (x & 1) * 1;
}
""";

const String ONE_TIMES_INT = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return 1 * (x & 1);
}
""";

const String NUM_TIMES_ONE = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return x * 1;
}
""";

const String ONE_TIMES_NUM = """
int foo(x) => x;
void main() {
  var x = foo(0);
  return 1 * x;
}
""";

main() {
  var plusZero = new RegExp(r"\+ 0");
  var zeroPlus = new RegExp(r"0 \+");
  var timesOne = new RegExp(r"\* 1");
  var oneTimes = new RegExp(r"1 \*");

  asyncTest(() => Future.wait([
    compileAndDoNotMatch(INT_PLUS_ZERO, 'main', plusZero),
    compileAndDoNotMatch(ZERO_PLUS_INT, 'main', zeroPlus),
    compileAndMatch(NUM_PLUS_ZERO, 'main', plusZero),
    compileAndMatch(ZERO_PLUS_NUM, 'main', zeroPlus),
    compileAndDoNotMatch(INT_TIMES_ONE, 'main', timesOne),
    compileAndDoNotMatch(ONE_TIMES_INT, 'main', oneTimes),
    compileAndDoNotMatch(NUM_TIMES_ONE, 'main', timesOne),
    compileAndDoNotMatch(ONE_TIMES_NUM, 'main', oneTimes),
  ]));
}
