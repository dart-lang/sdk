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

  const BitXor(314159, 271828, 61179).check();
  const BitXor(271828, 314159, 61179).check();
  const BitXor(0, 0, 0).check();
  const BitXor(-1, 0, 0xFFFFFFFF).check();
  const BitXor(-256, 1, 0xFFFFFF01).check();
  const BitXor(-256, -255, 1).check();
  const BitXor(0, 0xFFFFFFFF, 0xFFFFFFFF).check();
  const BitXor(0xFFFFFFFF, 0, 0xFFFFFFFF).check();
  const BitXor(0xFFFFFFFF, 0xFFFFFFFF, 0).check();
  const BitXor(0x123456789ABC, 0x111111111111, 0x47698BAD).check();

  const ShiftLeft(42, 0, 42).check();
  const ShiftLeft(42, 5, 1344).check();
  const ShiftLeft(1, 31, 0x80000000).check();
  const ShiftLeft(1, 32, 0).check();
  const ShiftLeft(1, 100, 0).check();
  const ShiftLeft(0, 0, 0).check();
  const ShiftLeft(0, 5, 0).check();
  const ShiftLeft(0, 31, 0).check();
  const ShiftLeft(0, 32, 0).check();
  const ShiftLeft(0, 100, 0).check();
  const ShiftLeft(-1, 0, 0xFFFFFFFF).check();
  const ShiftLeft(-1, 5, 0xFFFFFFE0).check();
  const ShiftLeft(-1, 31, 0x80000000).check();
  const ShiftLeft(-1, 32, 0).check();
  const ShiftLeft(-1, 100, 0).check();

  const ShiftRight(8675309, 0, 8675309).check();
  const ShiftRight(8675309, 5, 271103).check();
  const ShiftRight(0xFEDCBA98, 0, 0xFEDCBA98).check();
  const ShiftRight(0xFEDCBA98, 5, 0x07F6E5D4).check();
  const ShiftRight(0xFEDCBA98, 31, 1).check();
  const ShiftRight(0xFEDCBA98, 32, 0).check();
  const ShiftRight(0xFEDCBA98, 100, 0).check();
  const ShiftRight(0xFFFFFEDCBA98, 0, 0xFEDCBA98).check();
  const ShiftRight(0xFFFFFEDCBA98, 5, 0x07F6E5D4).check();
  const ShiftRight(0xFFFFFEDCBA98, 31, 1).check();
  const ShiftRight(0xFFFFFEDCBA98, 32, 0).check();
  const ShiftRight(0xFFFFFEDCBA98, 100, 0).check();
  const ShiftRight(-1, 0, 0xFFFFFFFF).check();
  const ShiftRight(-1, 5, 0xFFFFFFFF).check();
  const ShiftRight(-1, 31, 0xFFFFFFFF).check();
  const ShiftRight(-1, 32, 0xFFFFFFFF).check();
  const ShiftRight(-1, 100, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 0, 0xC0000000).check();
  const ShiftRight(-1073741824, 5, 0xFE000000).check();
  const ShiftRight(-1073741824, 31, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 32, 0xFFFFFFFF).check();
  const ShiftRight(-1073741824, 100, 0xFFFFFFFF).check();

  const BooleanAnd(true, true, true).check();
  const BooleanAnd(true, false, false).check();
  const BooleanAnd(false, true, false).check();
  const BooleanAnd(false, false, false).check();
  const BooleanAnd(false, null, false).check();

  const BooleanOr(true, true, true).check();
  const BooleanOr(true, false, true).check();
  const BooleanOr(false, true, true).check();
  const BooleanOr(false, false, false).check();
  const BooleanOr(true, null, true).check();

  const Subtract(314159, 271828, 42331).check();
  const Subtract(271828, 314159, -42331).check();
  const Subtract(0, 0, 0).check();
  const Subtract(0, 42, -42).check();
  const Subtract(0, -42, 42).check();
  const Subtract(42, 0, 42).check();
  const Subtract(42, 42, 0).check();
  const Subtract(42, -42, 84).check();
  const Subtract(-42, 0, -42).check();
  const Subtract(-42, 42, -84).check();
  const Subtract(-42, -42, 0).check();
  const Subtract(4294967295, -1, 4294967296).check();
  const Subtract(4294967296, -1, 4294967297).check();
  const Subtract(9007199254740991, -1, 9007199254740992).check();
  const Subtract(9007199254740992, -1, 9007199254740992).check();
  const Subtract(9007199254740992, -100, 9007199254741092).check();
  const Subtract(-4294967295, 1, -4294967296).check();
  const Subtract(-4294967296, 1, -4294967297).check();
  const Subtract(-9007199254740991, 1, -9007199254740992).check();
  const Subtract(-9007199254740992, 1, -9007199254740992).check();
  const Subtract(-9007199254740992, 100, -9007199254741092).check();
  const Subtract(
          0x7fffffff00000000, -0x7fffffff00000000, 2 * 0x7fffffff00000000)
      .check();
  const Subtract(4.2, 1.5, 2.7).check();
  const Subtract(1.5, 4.2, -2.7).check();
  const Subtract(1.5, 0, 1.5).check();
  const Subtract(0, 1.5, -1.5).check();
  const Subtract(1.5, 1.5, 0.0).check();
  const Subtract(-1.5, -1.5, 0.0).check();
  const Subtract(0.0, 0.0, 0.0).check();
  const Subtract(0.0, -0.0, 0.0).check();
  const Subtract(-0.0, 0.0, -0.0).check();
  const Subtract(-0.0, -0.0, 0.0).check();
  const Subtract(double.maxFinite, -double.maxFinite, double.infinity).check();
  const Subtract(-double.maxFinite, double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(1.5, double.nan, double.nan).check();
  const Subtract(double.nan, 1.5, double.nan).check();
  const Subtract(double.nan, double.nan, double.nan).check();
  const Subtract(double.nan, double.infinity, double.nan).check();
  const Subtract(double.nan, double.negativeInfinity, double.nan).check();
  const Subtract(double.infinity, double.nan, double.nan).check();
  const Subtract(double.negativeInfinity, double.nan, double.nan).check();
  const Subtract(double.infinity, double.maxFinite, double.infinity).check();
  const Subtract(double.infinity, -double.maxFinite, double.infinity).check();
  const Subtract(
          double.negativeInfinity, double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(
          double.negativeInfinity, -double.maxFinite, double.negativeInfinity)
      .check();
  const Subtract(1.5, double.infinity, double.negativeInfinity).check();
  const Subtract(1.5, double.negativeInfinity, double.infinity).check();
  const Subtract(double.infinity, double.infinity, double.nan).check();
  const Subtract(double.infinity, double.negativeInfinity, double.infinity)
      .check();
  const Subtract(
          double.negativeInfinity, double.infinity, double.negativeInfinity)
      .check();
  const Subtract(double.negativeInfinity, double.negativeInfinity, double.nan)
      .check();
  const Subtract(double.minPositive, double.minPositive, 0.0).check();
  const Subtract(-double.minPositive, -double.minPositive, 0.0).check();
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

class BitXor extends TestOp {
  final arg1;
  final arg2;

  const BitXor(this.arg1, this.arg2, expected) : super(expected, arg1 ^ arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 ^ arg2;
}

class ShiftLeft extends TestOp {
  final arg1;
  final arg2;

  const ShiftLeft(this.arg1, this.arg2, expected)
      : super(expected, arg1 << arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 << arg2;
}

class ShiftRight extends TestOp {
  final arg1;
  final arg2;

  const ShiftRight(this.arg1, this.arg2, expected)
      : super(expected, arg1 >> arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 >> arg2;
}

class BooleanAnd extends TestOp {
  final arg1;
  final arg2;

  const BooleanAnd(this.arg1, this.arg2, expected)
      : super(expected, arg1 && arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 && arg2;
}

class BooleanOr extends TestOp {
  final arg1;
  final arg2;

  const BooleanOr(this.arg1, this.arg2, expected)
      : super(expected, arg1 || arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 || arg2;
}

class Subtract extends TestOp {
  final arg1;
  final arg2;

  const Subtract(this.arg1, this.arg2, expected) : super(expected, arg1 - arg2);

  @pragma('dart2js:tryInline')
  check() => checkAll(eval());

  @override
  @pragma('dart2js:tryInline')
  eval() => arg1 - arg2;
}
