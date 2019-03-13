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
  const Negate(1, -1).check();
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
