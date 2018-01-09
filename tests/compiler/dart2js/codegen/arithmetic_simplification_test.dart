// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding on numbers.

import 'package:async_helper/async_helper.dart';
import '../compiler_helper.dart';

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

// TODO(johnniwinther): Find out why this doesn't work without the `as num`
// cast.
const String NUM_PLUS_ZERO = """
int foo(x) => x;
void main() {
  var x = foo(0) as num;
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

  test({bool useKernel}) async {
    await compileAndDoNotMatch(INT_PLUS_ZERO, 'main', plusZero,
        useKernel: useKernel);
    await compileAndDoNotMatch(ZERO_PLUS_INT, 'main', zeroPlus,
        useKernel: useKernel);
    await compileAndMatch(NUM_PLUS_ZERO, 'main', plusZero,
        useKernel: useKernel);
    await compileAndMatch(ZERO_PLUS_NUM, 'main', zeroPlus,
        useKernel: useKernel);
    await compileAndDoNotMatch(INT_TIMES_ONE, 'main', timesOne,
        useKernel: useKernel);
    await compileAndDoNotMatch(ONE_TIMES_INT, 'main', oneTimes,
        useKernel: useKernel);
    await compileAndDoNotMatch(NUM_TIMES_ONE, 'main', timesOne,
        useKernel: useKernel);
    await compileAndDoNotMatch(ONE_TIMES_NUM, 'main', oneTimes,
        useKernel: useKernel);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await test(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await test(useKernel: true);
  });
}
