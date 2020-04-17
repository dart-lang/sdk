// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const a0 = 0 ~/ 0; // error
const a1 = 0.0 ~/ 0; // error
const a2 = -0.0 ~/ 0; // error
const a3 = double.nan ~/ 0; // error
const a4 = double.infinity ~/ 0; // error
const a5 = double.negativeInfinity ~/ 0; // error

const b0 = 0 ~/ 0.0; // error
const b1 = 0.0 ~/ 0.0; // error
const b2 = -0.0 ~/ 0.0; // error
const b3 = double.nan ~/ 0.0; // error
const b4 = double.infinity ~/ 0.0; // error
const b5 = double.negativeInfinity ~/ 0.0; // error

const c0 = 0 ~/ -0.0; // error
const c1 = 0.0 ~/ -0.0; // error
const c2 = -0.0 ~/ -0.0; // error
const c3 = double.nan ~/ -0.0; // error
const c4 = double.infinity ~/ -0.0; // error
const c5 = double.negativeInfinity ~/ -0.0; // error

const d0 = 0 ~/ double.nan; // error
const d1 = 0.0 ~/ double.nan; // error
const d2 = -0.0 ~/ double.nan; // error
const d3 = double.nan ~/ double.nan; // error
const d4 = double.infinity ~/ double.nan; // error
const d5 = double.negativeInfinity ~/ double.nan; // error

const e0 = 0 ~/ double.infinity; // ok
const e1 = 0.0 ~/ double.infinity; // ok
const e2 = -0.0 ~/ double.infinity; // ok
const e3 = double.nan ~/ double.infinity; // error
const e4 = double.infinity ~/ double.infinity; // error
const e5 = double.negativeInfinity ~/ double.infinity; // error

const f0 = 0 ~/ double.negativeInfinity; // ok
const f1 = 0.0 ~/ double.negativeInfinity; // ok
const f2 = -0.0 ~/ double.negativeInfinity; // ok
const f3 = double.nan ~/ double.negativeInfinity; // error
const f4 = double.infinity ~/ double.negativeInfinity; // error
const f5 = double.negativeInfinity ~/ double.negativeInfinity; // error

main() {
  test(0, 0, () => a0);
  test(0.0, 0, () => a1);
  test(-0.0, 0, () => a2);
  test(double.nan, 0, () => a3);
  test(double.infinity, 0, () => a4);
  test(double.negativeInfinity, 0, () => a5);

  test(0, 0.0, () => b0);
  test(0.0, 0.0, () => b1);
  test(-0.0, 0.0, () => b2);
  test(double.nan, 0.0, () => b3);
  test(double.infinity, 0.0, () => b4);
  test(double.negativeInfinity, 0.0, () => b5);

  test(0, -0.0, () => c0);
  test(0.0, -0.0, () => c1);
  test(-0.0, -0.0, () => c2);
  test(double.nan, -0.0, () => c3);
  test(double.infinity, -0.0, () => c4);
  test(double.negativeInfinity, -0.0, () => c5);

  test(0, double.nan, () => d0);
  test(0.0, double.nan, () => d1);
  test(-0.0, double.nan, () => d2);
  test(double.nan, double.nan, () => d3);
  test(double.infinity, double.nan, () => d4);
  test(double.negativeInfinity, double.nan, () => d5);

  test(0, double.infinity, () => e0);
  test(0.0, double.infinity, () => e1);
  test(-0.0, double.infinity, () => e2);
  test(double.nan, double.infinity, () => e3);
  test(double.infinity, double.infinity, () => e4);
  test(double.negativeInfinity, double.infinity, () => e5);

  test(0, double.negativeInfinity, () => f0);
  test(0.0, double.negativeInfinity, () => f1);
  test(-0.0, double.negativeInfinity, () => f2);
  test(double.nan, double.negativeInfinity, () => f3);
  test(double.infinity, double.negativeInfinity, () => f4);
  test(double.negativeInfinity, double.negativeInfinity, () => f5);
}

void test(num a, num b, num Function() f) {
  num result;
  try {
    result = a ~/ b;
    print('$a ~/ $b = $result');
  } catch (e) {
    print('$a ~/ $b throws $e');
    throws(f);
    return;
  }
  expect(f(), result);
}

void expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}

void throws(num Function() f) {
  try {
    f();
  } catch (e) {
    return;
  }
  throw 'Expected exception';
}
