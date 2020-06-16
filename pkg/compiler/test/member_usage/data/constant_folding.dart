// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Derived from tests/dart2js_2/constant_folding_test

import "package:expect/expect.dart";

/*member: main:invoke*/
void main() {
  const BitNot(42, 4294967253).check();
  const BitNot(4294967253, 42).check();
  const BitNot(-42, 41).check();
  const BitNot(-1, 0).check();
  const BitNot(0, 0xFFFFFFFF).check();
  const BitNot(4294967295, 0).check();
  const BitNot(0x12121212121212, 0xEDEDEDED).check();
}

/*member: jsEquals:invoke*/
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
  /*member: TestOp.expected:init,read*/
  final expected;

  /*member: TestOp.result:init,read*/
  final result;

  const TestOp(this.expected, this.result);

  /*member: TestOp.checkAll:invoke*/
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
  /*member: BitNot.arg:init,read*/
  final arg;

  const BitNot(this.arg, expected) : super(expected, ~arg);

  /*member: BitNot.check:invoke*/
  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  /*member: BitNot.eval:invoke*/
  @override
  @pragma('dart2js:tryInline')
  eval() => ~arg;
}
