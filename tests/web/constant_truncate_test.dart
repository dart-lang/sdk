// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const a0 = 0 ~/ 0; //# a0: compile-time error
const a1 = 0.0 ~/ 0; //# a1: compile-time error
const a2 = -0.0 ~/ 0; //# a2: compile-time error
const a3 = double.nan ~/ 0; //# a3: compile-time error
const a4 = double.infinity ~/ 0; //# a4: compile-time error
const a5 = double.negativeInfinity ~/ 0; //# a5: compile-time error

const b0 = 0 ~/ 0.0; //# b0: compile-time error
const b1 = 0.0 ~/ 0.0; //# b1: compile-time error
const b2 = -0.0 ~/ 0.0; //# b2: compile-time error
const b3 = double.nan ~/ 0.0; //# b3: compile-time error
const b4 = double.infinity ~/ 0.0; //# b4: compile-time error
const b5 = double.negativeInfinity ~/ 0.0; //# b5: compile-time error

const c0 = 0 ~/ -0.0; //# c0: compile-time error
const c1 = 0.0 ~/ -0.0; //# c1: compile-time error
const c2 = -0.0 ~/ -0.0; //# c2: compile-time error
const c3 = double.nan ~/ -0.0; //# c3: compile-time error
const c4 = double.infinity ~/ -0.0; //# c4: compile-time error
const c5 = double.negativeInfinity ~/ -0.0; //# c5: compile-time error

const d0 = 0 ~/ double.nan; //# d0: compile-time error
const d1 = 0.0 ~/ double.nan; //# d1: compile-time error
const d2 = -0.0 ~/ double.nan; //# d2: compile-time error
const d3 = double.nan ~/ double.nan; //# d3: compile-time error
const d4 = double.infinity ~/ double.nan; //# d4: compile-time error
const d5 = double.negativeInfinity ~/ double.nan; //# d5: compile-time error

const e0 = 0 ~/ double.infinity; //# e0: ok
const e1 = 0.0 ~/ double.infinity; //# e1: ok
const e2 = -0.0 ~/ double.infinity; //# e2: ok
const e3 = double.nan ~/ double.infinity; //# e3: compile-time error
const e4 = double.infinity ~/ double.infinity; //# e4: compile-time error
const e5 = double.negativeInfinity ~/ double.infinity; //# e5: compile-time error

const f0 = 0 ~/ double.negativeInfinity; //# f0: ok
const f1 = 0.0 ~/ double.negativeInfinity; //# f1: ok
const f2 = -0.0 ~/ double.negativeInfinity; //# f2: ok
const f3 = double.nan ~/ double.negativeInfinity; //# f3: compile-time error
const f4 = double.infinity ~/ double.negativeInfinity; //# f4: compile-time error
const f5 = double.negativeInfinity ~/ double.negativeInfinity; //# f5: compile-time error

main() {
  test(0, 0, () => a0); //# a0: continued
  test(0.0, 0, () => a1); //# a1: continued
  test(-0.0, 0, () => a2); //# a2: continued
  test(double.nan, 0, () => a3); //# a3: continued
  test(double.infinity, 0, () => a4); //# a4: continued
  test(double.negativeInfinity, 0, () => a5); //# a5: continued

  test(0, 0.0, () => b0); //# b0: continued
  test(0.0, 0.0, () => b1); //# b1: continued
  test(-0.0, 0.0, () => b2); //# b2: continued
  test(double.nan, 0.0, () => b3); //# b3: continued
  test(double.infinity, 0.0, () => b4); //# b4: continued
  test(double.negativeInfinity, 0.0, () => b5); //# b5: continued

  test(0, -0.0, () => c0); //# c0: continued
  test(0.0, -0.0, () => c1); //# c1: continued
  test(-0.0, -0.0, () => c2); //# c2: continued
  test(double.nan, -0.0, () => c3); //# c3: continued
  test(double.infinity, -0.0, () => c4); //# c4: continued
  test(double.negativeInfinity, -0.0, () => c5); //# c5: continued

  test(0, double.nan, () => d0); //# d0: continued
  test(0.0, double.nan, () => d1); //# d1: continued
  test(-0.0, double.nan, () => d2); //# d2: continued
  test(double.nan, double.nan, () => d3); //# d3: continued
  test(double.infinity, double.nan, () => d4); //# d4: continued
  test(double.negativeInfinity, double.nan, () => d5); //# d5: continued

  test(0, double.infinity, () => e0); //# e0: continued
  test(0.0, double.infinity, () => e1); //# e1: continued
  test(-0.0, double.infinity, () => e2); //# e2: continued
  test(double.nan, double.infinity, () => e3); //# e3: continued
  test(double.infinity, double.infinity, () => e4); //# e4: continued
  test(double.negativeInfinity, double.infinity, () => e5); //# e5: continued

  test(0, double.negativeInfinity, () => f0); //# f0: continued
  test(0.0, double.negativeInfinity, () => f1); //# f1: continued
  test(-0.0, double.negativeInfinity, () => f2); //# f2: continued
  test(double.nan, double.negativeInfinity, () => f3); //# f3: continued
  test(double.infinity, double.negativeInfinity, () => f4); //# f4: continued
  test(double.negativeInfinity, double.negativeInfinity, () => f5); //# f5: continued
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
