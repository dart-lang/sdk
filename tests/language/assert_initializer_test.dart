// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--assert_initializer
import "package:expect/expect.dart";

bool assertsEnabled = false;

main() {
  assert((assertsEnabled = true));
  runtimeAsserts(); // //# none: ok

  // Passing const expressions.
  const c00 = const AssertArgument.constFirst(true, 0, 1);
  const c01 = const AssertArgument.constLast(true, 0, 1);
  const c02 = const AssertArgument.constMiddle(true, 0, 1);
  const c03 = const AssertArgument.constMulti(true, 0, 1);
  const c04 = const AssertArgument.constFirstSuper(true, 0, 1);
  const c05 = const AssertArgument.constLastSuper(true, 0, 1);
  const c06 = const AssertArgument.constMiddleSuper(true, 0, 1);
  const c07 = const AssertArgument.constMultiSuper(true, 0, 1);

  const c08 = const AssertCompare.constFirst(1, 2);
  const c09 = const AssertCompare.constLast(1, 2);
  const c10 = const AssertCompare.constMiddle(1, 2);
  const c11 = const AssertCompare.constMulti(1, 2);
  const c12 = const AssertCompare.constFirstSuper(1, 2);
  const c13 = const AssertCompare.constLastSuper(1, 2);
  const c14 = const AssertCompare.constMiddleSuper(1, 2);
  const c15 = const AssertCompare.constMultiSuper(1, 2);

  // Failing const expressions

  const c = const AssertArgument.constFirst(false, 0, 1); //       //# 01: checked mode compile-time error
  const c = const AssertArgument.constLast(false, 0, 1); //        //# 02: checked mode compile-time error
  const c = const AssertArgument.constMiddle(false, 0, 1); //      //# 03: checked mode compile-time error
  const c = const AssertArgument.constMulti(false, 0, 1); //       //# 04: checked mode compile-time error
  const c = const AssertArgument.constFirstSuper(false, 0, 1); //  //# 05: checked mode compile-time error
  const c = const AssertArgument.constLastSuper(false, 0, 1); //   //# 06: checked mode compile-time error
  const c = const AssertArgument.constMiddleSuper(false, 0, 1); // //# 07: checked mode compile-time error
  const c = const AssertArgument.constMultiSuper(false, 0, 1); //  //# 08: checked mode compile-time error

  const c = const AssertArgument.constFirst("str", 0, 1); //       //# 11: checked mode compile-time error
  const c = const AssertArgument.constLast("str", 0, 1); //        //# 12: checked mode compile-time error
  const c = const AssertArgument.constMiddle("str", 0, 1); //      //# 13: checked mode compile-time error
  const c = const AssertArgument.constMulti("str", 0, 1); //       //# 14: checked mode compile-time error
  const c = const AssertArgument.constFirstSuper("str", 0, 1); //  //# 15: checked mode compile-time error
  const c = const AssertArgument.constLastSuper("str", 0, 1); //   //# 16: checked mode compile-time error
  const c = const AssertArgument.constMiddleSuper("str", 0, 1); // //# 17: checked mode compile-time error
  const c = const AssertArgument.constMultiSuper("str", 0, 1); //  //# 18: checked mode compile-time error

  const c = const AssertCompare.constFirst(3, 2); //               //# 21: checked mode compile-time error
  const c = const AssertCompare.constLast(3, 2); //                //# 22: checked mode compile-time error
  const c = const AssertCompare.constMiddle(3, 2); //              //# 23: checked mode compile-time error
  const c = const AssertCompare.constMulti(3, 2); //               //# 24: checked mode compile-time error
  const c = const AssertCompare.constFirstSuper(3, 2); //          //# 25: checked mode compile-time error
  const c = const AssertCompare.constLastSuper(3, 2); //           //# 26: checked mode compile-time error
  const c = const AssertCompare.constMiddleSuper(3, 2); //         //# 27: checked mode compile-time error
  const c = const AssertCompare.constMultiSuper(3, 2); //          //# 28: checked mode compile-time error

  // Functions not allowed in asserts in const execution.
  const c = const AssertArgument.constFirst(kTrue, 0, 1); //       //# 31: checked mode compile-time error
  const c = const AssertArgument.constLast(kTrue, 0, 1); //        //# 32: checked mode compile-time error
  const c = const AssertArgument.constMiddle(kTrue, 0, 1); //      //# 33: checked mode compile-time error
  const c = const AssertArgument.constMulti(kTrue, 0, 1); //       //# 34: checked mode compile-time error
  const c = const AssertArgument.constFirstSuper(kTrue, 0, 1); //  //# 35: checked mode compile-time error
  const c = const AssertArgument.constLastSuper(kTrue, 0, 1); //   //# 36: checked mode compile-time error
  const c = const AssertArgument.constMiddleSuper(kTrue, 0, 1); // //# 37: checked mode compile-time error
  const c = const AssertArgument.constMultiSuper(kTrue, 0, 1); //  //# 38: checked mode compile-time error

  const cTrue = const TrickCompare(true);
  // Value must be integer for potential-const expression to be actually const.
  const c = const AssertCompare.constFirst(cTrue, 2); //           //# 41: checked mode compile-time error
  const c = const AssertCompare.constLast(cTrue, 2); //            //# 42: checked mode compile-time error
  const c = const AssertCompare.constMiddle(cTrue, 2); //          //# 43: checked mode compile-time error
  const c = const AssertCompare.constMulti(cTrue, 2); //           //# 44: checked mode compile-time error
  const c = const AssertCompare.constFirstSuper(cTrue, 2); //      //# 45: checked mode compile-time error
  const c = const AssertCompare.constLastSuper(cTrue, 2); //       //# 46: checked mode compile-time error
  const c = const AssertCompare.constMiddleSuper(cTrue, 2); //     //# 47: checked mode compile-time error
  const c = const AssertCompare.constMultiSuper(cTrue, 2); //      //# 48: checked mode compile-time error
}


void runtimeAsserts() {

  testAssertArgumentCombinations(value, test, [testConst]) {
    test(() => new AssertArgument.first(value, 0, 1));
    test(() => new AssertArgument.last(value, 0, 1));
    test(() => new AssertArgument.middle(value, 0, 1));
    test(() => new AssertArgument.multi(value, 0, 1));
    test(() => new AssertArgument.firstSuper(value, 0, 1));
    test(() => new AssertArgument.lastSuper(value, 0, 1));
    test(() => new AssertArgument.middleSuper(value, 0, 1));
    test(() => new AssertArgument.multiSuper(value, 0, 1));
    testConst ??= test;
    testConst(() => new AssertArgument.constFirst(value, 0, 1));
    testConst(() => new AssertArgument.constLast(value, 0, 1));
    testConst(() => new AssertArgument.constMiddle(value, 0, 1));
    testConst(() => new AssertArgument.constMulti(value, 0, 1));
    testConst(() => new AssertArgument.constFirstSuper(value, 0, 1));
    testConst(() => new AssertArgument.constLastSuper(value, 0, 1));
    testConst(() => new AssertArgument.constMiddleSuper(value, 0, 1));
    testConst(() => new AssertArgument.constMultiSuper(value, 0, 1));
  }

  testAssertCompareCombinations(v1, v2, test, [testConst]) {
    test(() => new AssertCompare.first(v1, v2));
    test(() => new AssertCompare.last(v1, v2));
    test(() => new AssertCompare.middle(v1, v2));
    test(() => new AssertCompare.multi(v1, v2));
    test(() => new AssertCompare.firstSuper(v1, v2));
    test(() => new AssertCompare.lastSuper(v1, v2));
    test(() => new AssertCompare.middleSuper(v1, v2));
    test(() => new AssertCompare.multiSuper(v1, v2));
    testConst ??= test;
    testConst(() => new AssertCompare.constFirst(v1, v2));
    testConst(() => new AssertCompare.constLast(v1, v2));
    testConst(() => new AssertCompare.constMiddle(v1, v2));
    testConst(() => new AssertCompare.constMulti(v1, v2));
    testConst(() => new AssertCompare.constFirstSuper(v1, v2));
    testConst(() => new AssertCompare.constLastSuper(v1, v2));
    testConst(() => new AssertCompare.constMiddleSuper(v1, v2));
    testConst(() => new AssertCompare.constMultiSuper(v1, v2));
  }

  testAssertArgumentCombinations(true, pass);
  testAssertArgumentCombinations(kTrue, pass, failType);
  testAssertArgumentCombinations(false, failAssert);
  testAssertArgumentCombinations(kFalse, failAssert, failType);
  testAssertArgumentCombinations(42, failType);
  testAssertArgumentCombinations(null, failAssert);

  testAssertCompareCombinations(1, 2, pass);
  testAssertCompareCombinations(3, 2, failAssert);
  var TrickCompareInt = const TrickCompare(42);
  testAssertCompareCombinations(TrickCompareInt, 0, failType);
  var TrickCompareTrueFun = const TrickCompare(kTrue);
  testAssertCompareCombinations(TrickCompareTrueFun, 0, pass, failType);
  var TrickCompareFalseFun = const TrickCompare(kFalse);
  testAssertCompareCombinations(TrickCompareFalseFun, 0, failAssert, failType);
}


void pass(void action()) {
  action();
}

void failAssert(void action()) {
  if (assertsEnabled) {
    Expect.throws(action, (e) => e is AssertionError && e is! TypeError);
  } else {
    action();
  }
}

void failType(void action()) {
  if (assertsEnabled) {
    Expect.throws(action, (e) => e is TypeError);
  } else {
    action();
  }
}

bool kTrue() => true;
bool kFalse() => false;

class AssertArgument {
  final y;
  final z;
  AssertArgument.first(x, y, z) : assert(x), y = y, z = z;
  AssertArgument.last(x, y, z) : y = y, z = z, assert(x);
  AssertArgument.middle(x, y, z) : y = y, assert(x), z = z;
  AssertArgument.multi(x, y, z)
      : assert(x), y = y, assert(x), z = z, assert(x);
  AssertArgument.firstSuper(x, y, z) : assert(x), y = y, z = z, super();
  AssertArgument.lastSuper(x, y, z) : y = y, z = z, assert(x), super();
  AssertArgument.middleSuper(x, y, z) : y = y, assert(x), z = z, super();
  AssertArgument.multiSuper(x, y, z)
      : assert(x), y = y, assert(x), z = z, assert(x), super();
  const AssertArgument.constFirst(x, y, z) : assert(x), y = y, z = z;
  const AssertArgument.constLast(x, y, z) : y = y, z = z, assert(x);
  const AssertArgument.constMiddle(x, y, z) : y = y, assert(x), z = z;
  const AssertArgument.constMulti(x, y, z)
      : assert(x), y = y, assert(x), z = z, assert(x);
  const AssertArgument.constFirstSuper(x, y, z)
      : assert(x), y = y, z = z, super();
  const AssertArgument.constLastSuper(x, y, z)
      : y = y, z = z, assert(x), super();
  const AssertArgument.constMiddleSuper(x, y, z)
      : y = y, assert(x), z = z, super();
  const AssertArgument.constMultiSuper(x, y, z)
      : assert(x), y = y, assert(x), z = z, assert(x), super();
}

class AssertCompare {
  final y;
  final z;
  AssertCompare.first(y, z) : assert(y < z), y = y, z = z;
  AssertCompare.last(y, z) : y = y, z = z, assert(y < z);
  AssertCompare.middle(y, z) : y = y, assert(y < z), z = z;
  AssertCompare.multi(y, z)
      : assert(y < z), y = y, assert(y < z), z = z, assert(y < z);
  AssertCompare.firstSuper(y, z) : assert(y < z), y = y, z = z, super();
  AssertCompare.lastSuper(y, z) : y = y, z = z, assert(y < z), super();
  AssertCompare.middleSuper(y, z) : y = y, assert(y < z), z = z, super();
  AssertCompare.multiSuper(y, z)
      : assert(y < z), y = y, assert(y < z), z = z, assert(y < z), super();
  const AssertCompare.constFirst(y, z) : assert(y < z), y = y, z = z;
  const AssertCompare.constLast(y, z) : y = y, z = z, assert(y < z);
  const AssertCompare.constMiddle(y, z) : y = y, assert(y < z), z = z;
  const AssertCompare.constMulti(y, z)
      : assert(y < z), y = y, assert(y < z), z = z, assert(y < z);
  const AssertCompare.constFirstSuper(y, z)
      : assert(y < z), y = y, z = z, super();
  const AssertCompare.constLastSuper(y, z)
      : y = y, z = z, assert(y < z), super();
  const AssertCompare.constMiddleSuper(y, z)
      : y = y, assert(y < z), z = z, super();
  const AssertCompare.constMultiSuper(y, z)
      : assert(y < z), y = y, assert(y < z), z = z, assert(y < z), super();
}

class TrickCompare {
  final result;
  const TrickCompare(this.result);
  operator<(other) => result;  // Nyah-nyah!
}
