// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Derived from tests/dart2js_2/constant_folding_test

import "package:expect/expect.dart";

/*member: main:calls=[checkAll$1(1),checkAll$1(1),checkAll$1(1),checkAll$1(1),checkAll$1(1),checkAll$1(1),checkAll$1(1)],params=0*/
void main() {
  const BitNot(42, 4294967253).check();
  const BitNot(4294967253, 42).check();
  const BitNot(-42, 41).check();
  const BitNot(-1, 0).check();
  const BitNot(0, 0xFFFFFFFF).check();
  const BitNot(4294967295, 0).check();
  const BitNot(0x12121212121212, 0xEDEDEDED).check();
}

/*member: jsEquals:calls=[Expect_equals(3),Expect_equals(3),get$isNegative(1),get$isNegative(1),toString$0(1),toString$0(1)],params=3*/
void jsEquals(expected, actual, [String reason = null]) {
  if (expected is num && actual is num) {
    if (expected.isNaN && actual.isNaN) return;
  }

  Expect.equals(expected, actual, reason);

  if (expected == 0 && actual == 0) {
    Expect.equals(
        expected.isNegative,
        actual.isNegative,
        (reason == null ? "" : "$reason ") +
            "${expected.toString()} and "
                "${actual.toString()} have different signs.");
  }
}

abstract class TestOp {
  final expected;

  final result;

  const TestOp(this.expected, this.result);

  /*member: TestOp.checkAll:access=[arg,expected,result],calls=[jsEquals(3),jsEquals(3),jsEquals(3)],params=1*/
  @pragma('dart2js:noInline')
  checkAll(evalResult) {
    jsEquals(expected, result,
        "Frontend constant evaluation does not yield expected value.");
    jsEquals(expected, evalResult,
        "Backend constant evaluation does not yield expected value.");
    jsEquals(expected, eval(), "eval() does not yield expected value.");
  }

  eval();
}

class BitNot extends TestOp {
  /*member: BitNot.arg:emitted*/
  final arg;

  const BitNot(this.arg, expected) : super(expected, ~arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => ~arg;
}
