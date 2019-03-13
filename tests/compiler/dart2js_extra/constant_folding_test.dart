// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  const BitNot(42, 4294967253).check();
  const BitNot(4294967253, 42).check();
  const BitNot(-42, 41).check();
  const BitNot(-1, 0).check();
  const BitNot(0, 0xFFFFFFFF).check();
  const BitNot(4294967295, 0).check();
  const BitNot(0x12121212121212, 0xEDEDEDED).check();

  const Negate(0, -0).check();
  const Negate(-0, 0).check();
  const Negate(0.0, -0.0).check();
  const Negate(-0.0, 0.0).check();
  const Negate(-0.0, 0).check();
  const Negate(-0, 0.0).check();
  const Negate(0, -0.0).check();
  const Negate(0.0, -0).check();
  const Negate(1, -1).check();
  const Negate(-1, 1).check();
  const Negate(1.0, -1.0).check();
  const Negate(-1.0, 1.0).check();
  const Negate(3.14, -3.14).check();
  const Negate(-3.14, 3.14).check();
  const Negate(4294967295, -4294967295).check();
  const Negate(-4294967295, 4294967295).check();
  const Negate(4294967295.5, -4294967295.5).check();
  const Negate(-4294967295.5, 4294967295.5).check();
  const Negate(4294967296, -4294967296).check();
  const Negate(-4294967296, 4294967296).check();
  const Negate(4294967296.5, -4294967296.5).check();
  const Negate(-4294967296.5, 4294967296.5).check();
  const Negate(9007199254740991, -9007199254740991).check();
  const Negate(-9007199254740991, 9007199254740991).check();
  const Negate(9007199254740991.5, -9007199254740991.5).check();
  const Negate(-9007199254740991.5, 9007199254740991.5).check();
  const Negate(9007199254740992, -9007199254740992).check();
  const Negate(-9007199254740992, 9007199254740992).check();
  const Negate(9007199254740992.5, -9007199254740992.5).check();
  const Negate(-9007199254740992.5, 9007199254740992.5).check();
  const Negate(double.infinity, double.negativeInfinity).check();
  const Negate(double.negativeInfinity, double.infinity).check();
  const Negate(double.maxFinite, -double.maxFinite).check();
  const Negate(-double.maxFinite, double.maxFinite).check();
  const Negate(double.minPositive, -double.minPositive).check();
  const Negate(-double.minPositive, double.minPositive).check();
  const Negate(double.nan, double.nan).check();

  const Not(true, false).check();
  const Not(false, true).check();

  const BitAnd(314159, 271828, 262404).check();
  const BitAnd(271828, 314159, 262404).check();
  const BitAnd(0, 0, 0).check();
  const BitAnd(-1, 0, 0).check();
  const BitAnd(-1, 314159, 314159).check();
  const BitAnd(-1, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitAnd(0xff, -4, 0xfc).check();
  const BitAnd(0, 0xFFFFFFFF, 0).check();
  const BitAnd(0xFFFFFFFF, 0, 0).check();
  const BitAnd(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitAnd(0x123456789ABC, 0xEEEEEEEEEEEE, 0x46688AAC).check();

  const BitOr(314159, 271828, 323583).check();
  const BitOr(271828, 314159, 323583).check();
  const BitOr(0, 0, 0).check();
  const BitOr(-8, 0, 0xFFFFFFF8).check();
  const BitOr(-8, 271828, 0xFFFFFFFC).check();
  const BitOr(-8, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0x1, -4, 0xFFFFFFFD).check();
  const BitOr(0, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0xFFFFFFFF, 0, 0xFFFFFFFF).check();
  const BitOr(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitOr(0x123456789ABC, 0x111111111111, 0x57799BBD).check();
}

/// Wraps [Expect.equals] to accommodate JS equality semantics.
///
/// Naively using [Expect.equals] causes JS values to be compared with `===`.
/// This can yield some unintended results:
///
/// * Since `NaN === NaN` is `false`, [Expect.equals] will throw even if both
///   values are `NaN`. Therefore, we check for `NaN` specifically.
/// * Since `0.0 === -0.0` is `true`, [Expect.equals] will fail to throw if one
///   constant evaluation results in `0` or `0.0` and the other results in
///   `-0.0`. Therefore, we additionally check that both values have the same
///   sign in this case.
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
  final arg;

  const BitNot(this.arg, expected) : super(expected, ~arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => ~arg;
}

class Negate extends TestOp {
  final arg;

  const Negate(this.arg, expected) : super(expected, -arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => -arg;
}

class Not extends TestOp {
  final arg;

  const Not(this.arg, expected) : super(expected, !arg);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => !arg;
}

class BitAnd extends TestOp {
  final arg1;
  final arg2;

  const BitAnd(this.arg1, this.arg2, expected) : super(expected, arg1 & arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 & arg2;
}

class BitOr extends TestOp {
  final arg1;
  final arg2;

  const BitOr(this.arg1, this.arg2, expected) : super(expected, arg1 | arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 | arg2;
}
