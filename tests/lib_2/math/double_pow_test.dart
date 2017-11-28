// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

library math_test;

import "package:expect/expect.dart";
import 'dart:math';

void checkVeryClose(double a, double b) {
  // We find a ulp (unit in the last place) by shifting the original number
  // to the right. This only works if we are not too close to infinity or if
  // we work with denormals.
  // We special case for 0.0, but not for infinity.
  if (a == 0.0) {
    final minimalDouble = 4.9406564584124654e-324;
    Expect.equals(true, b.abs() <= minimalDouble);
    return;
  }
  if (b == 0.0) {
    // No need to look if they are close. Otherwise the check for 'a' above
    // would have triggered.
    Expect.equals(a, b);
  }
  final double shiftRightBy52 = 2.220446049250313080847263336181640625e-16;
  final double shiftedA = (a * shiftRightBy52).abs();
  // Compared to 'a', 'shiftedA' is now ~1-2 ulp.

  final double limitLow = a - shiftedA;
  final double limitHigh = a + shiftedA;
  Expect.equals(false, a == limitLow);
  Expect.equals(false, a == limitHigh);
  Expect.equals(true, limitLow <= b);
  Expect.equals(true, b <= limitHigh);
}

const NaN = double.nan;
const Infinity = double.infinity;

var samples = [
  NaN,
  -Infinity,
  -3.0, // Odd integer
  -2.0, // Even integer
  -1.5, // Non-integer, magnitude > 1
  -1.0, // Unit
  -0.5, // Non-integer, magnitude < 1.
  -0.0,
  0.5, // Non-integer, magnitude < 1.
  1.0, // Unit
  1.5, // Non-integer, magnitude > 1
  2.0, // Even integer
  3.0, // Odd integer
  Infinity
];

test() {
  // Tests of pow(x, y):
  for (var d in samples) {
    // if `y` is zero (0.0 or -0.0), the result is always 1.0.
    Expect.identical(1.0, pow(d, 0.0), "$d");
    Expect.identical(1.0, pow(d, -0.0), "$d");
  }
  for (var d in samples) {
    // if `x` is 1.0, the result is always 1.0.
    Expect.identical(1.0, pow(1.0, d), "$d");
  }
  for (var d in samples) {
    // otherwise, if either `x` or `y` is NaN then the result is NaN.
    if (d != 0.0) Expect.isTrue(pow(NaN, d).isNaN, "$d");
    if (d != 1.0) Expect.isTrue(pow(d, NaN).isNaN, "$d");
  }

  for (var d in samples) {
    // if `x` is a finite and strictly negative and `y` is a finite non-integer,
    // the result is NaN.
    if (d < 0 && !d.isInfinite) {
      Expect.isTrue(pow(d, 0.5).isNaN, "$d");
      Expect.isTrue(pow(d, -0.5).isNaN, "$d");
      Expect.isTrue(pow(d, 1.5).isNaN, "$d");
      Expect.isTrue(pow(d, -1.5).isNaN, "$d");
    }
  }

  for (var d in samples) {
    if (d < 0) {
      // if `x` is Infinity and `y` is strictly negative, the result is 0.0.
      Expect.identical(0.0, pow(Infinity, d), "$d");
    }
    if (d > 0) {
      // if `x` is Infinity and `y` is strictly positive, the result is Infinity.
      Expect.identical(Infinity, pow(Infinity, d), "$d");
    }
  }

  for (var d in samples) {
    if (d < 0) {
      // if `x` is 0.0 and `y` is strictly negative, the result is Infinity.
      Expect.identical(Infinity, pow(0.0, d), "$d");
    }
    if (d > 0) {
      // if `x` is 0.0 and `y` is strictly positive, the result is 0.0.
      Expect.identical(0.0, pow(0.0, d), "$d");
    }
  }

  for (var d in samples) {
    if (!d.isInfinite && !d.isNaN) {
      var dint = d.toInt();
      if (d == dint && dint.isOdd) {
        // if `x` is -Infinity or -0.0 and `y` is an odd integer, then the
        // result is`-pow(-x ,y)`.
        Expect.identical(-pow(Infinity, d), pow(-Infinity, d));
        Expect.identical(-pow(0.0, d), pow(-0.0, d));
        continue;
      }
    }
    // if `x` is -Infinity or -0.0 and `y` is not an odd integer, then the
    // result is the same as `pow(-x , y)`.
    if (d.isNaN) {
      Expect.isTrue(pow(Infinity, d).isNaN);
      Expect.isTrue(pow(-Infinity, d).isNaN);
      Expect.isTrue(pow(0.0, d).isNaN);
      Expect.isTrue(pow(-0.0, d).isNaN);
      continue;
    }
    Expect.identical(pow(Infinity, d), pow(-Infinity, d));
    Expect.identical(pow(0.0, d), pow(-0.0, d));
  }

  for (var d in samples) {
    if (d.abs() < 1) {
      // if `y` is Infinity and the absolute value of `x` is less than 1, the
      // result is 0.0.
      Expect.identical(0.0, pow(d, Infinity));
    } else if (d.abs() > 1) {
      // if `y` is Infinity and the absolute value of `x` is greater than 1,
      // the result is Infinity.
      Expect.identical(Infinity, pow(d, Infinity));
    } else if (d == -1) {
      // if `y` is Infinity and `x` is -1, the result is 1.0.
      Expect.identical(1.0, pow(d, Infinity));
    }
    // if `y` is -Infinity, the result is `1/pow(x, Infinity)`.
    if (d.isNaN) {
      Expect.isTrue((1 / pow(d, Infinity)).isNaN);
      Expect.isTrue(pow(d, -Infinity).isNaN);
    } else {
      Expect.identical(1 / pow(d, Infinity), pow(d, -Infinity));
    }
  }

  // Some non-exceptional values.
  checkVeryClose(16.0, pow(4.0, 2.0));
  checkVeryClose(SQRT2, pow(2.0, 0.5));
  checkVeryClose(SQRT1_2, pow(0.5, 0.5));
  // Denormal result.
  Expect.identical(5e-324, pow(2.0, -1074.0));
  // Overflow.
  Expect.identical(Infinity, pow(10.0, 309.0));
  // Underflow.
  Expect.identical(0.0, pow(10.0, -325.0));

  // Conversion to double.

  // The second argument is an odd integer as int, but not when converted
  // to double.
  Expect.identical(Infinity, pow(-0.0, -9223372036854775807));
}

main() {
  for (int i = 0; i < 10; i++) test();
}
