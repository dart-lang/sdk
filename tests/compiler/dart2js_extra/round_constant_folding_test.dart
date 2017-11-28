// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

const double PD1 = 0.0;
const double PD2 = double.minPositive;
const double PD3 = 2.0 * double.minPositive;
const double PD4 = 1.18e-38;
const double PD5 = 1.18e-38 * 2;
const double PD6 = 0.49999999999999994;
const double PD7 = 0.5;
const double PD8 = 0.9999999999999999;
const double PD9 = 1.0;
const double PD10 = 1.000000000000001;
const double PD11 = double.maxFinite;

const double ND1 = -PD1;
const double ND2 = -PD2;
const double ND3 = -PD3;
const double ND4 = -PD4;
const double ND5 = -PD5;
const double ND6 = -PD6;
const double ND7 = -PD7;
const double ND8 = -PD8;
const double ND9 = -PD9;
const double ND10 = -PD10;
const double ND11 = -PD11;

const X1 = double.infinity;
const X2 = double.negativeInfinity;
const X3 = double.nan;

// The following numbers are on the border of 52 bits.
// For example: 4503599627370499 + 0.5 => 4503599627370500.
const PQ1 = 4503599627370496.0;
const PQ2 = 4503599627370497.0;
const PQ3 = 4503599627370498.0;
const PQ4 = 4503599627370499.0;
const PQ5 = 9007199254740991.0;
const PQ6 = 9007199254740992.0;

const NQ1 = -PQ1;
const NQ2 = -PQ2;
const NQ3 = -PQ3;
const NQ4 = -PQ4;
const NQ5 = -PQ5;
const NQ6 = -PQ6;

const int PI1 = 0;
const int PI2 = 1;
const int PI3 = 0x1234;
const int PI4 = 0x12345678;
const int PI5 = 0x123456789AB;
const int PI6 = 0x123456789ABCDEF;
const int PI7 = 0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;

const int NI1 = 0 - PI1;
const int NI2 = -PI2;
const int NI3 = -PI3;
const int NI4 = -PI4;
const int NI5 = -PI5;
const int NI6 = -PI6;
const int NI7 = -PI7;

/// Ensures that the behaviour of `action()` is the same as `value.round()`.
@NoInline() // To ensure 'value.round()' has a non-constant receiver.
check(value, action) {
  var result1, result2;
  try {
    result1 = value.round();
  } catch (e) {
    result1 = e;
  }

  try {
    result2 = action();
  } catch (e) {
    result2 = e;
  }

  Expect.equals(result1.runtimeType, result2.runtimeType);
  if (result1 is num) {
    Expect.equals(result1, result2);
    Expect.equals(result1 is int, result2 is int);
  } else {
    Expect.equals(result1.runtimeType, result2.runtimeType);
    Expect.isTrue(result1 is Error);
  }
}

@NoInline()
void unusedCall(num x) {
  x.round(); // This call should not be removed since it might throw.
}

main() {
  check(PD1, () => PD1.round());
  check(PD2, () => PD2.round());
  check(PD3, () => PD3.round());
  check(PD4, () => PD4.round());
  check(PD5, () => PD5.round());
  check(PD6, () => PD6.round());
  check(PD7, () => PD7.round());
  check(PD8, () => PD8.round());
  check(PD9, () => PD9.round());
  check(PD10, () => PD10.round());
  check(PD11, () => PD11.round());

  check(ND1, () => ND1.round());
  check(ND2, () => ND2.round());
  check(ND3, () => ND3.round());
  check(ND4, () => ND4.round());
  check(ND5, () => ND5.round());
  check(ND6, () => ND6.round());
  check(ND7, () => ND7.round());
  check(ND8, () => ND8.round());
  check(ND9, () => ND9.round());
  check(ND10, () => ND10.round());
  check(ND11, () => ND11.round());

  check(X1, () => X1.round());
  check(X2, () => X2.round());
  check(X3, () => X3.round());

  check(PQ1, () => PQ1.round());
  check(PQ2, () => PQ2.round());
  check(PQ3, () => PQ3.round());
  check(PQ4, () => PQ4.round());
  check(PQ5, () => PQ5.round());
  check(PQ6, () => PQ6.round());

  check(NQ1, () => NQ1.round());
  check(NQ2, () => NQ2.round());
  check(NQ3, () => NQ3.round());
  check(NQ4, () => NQ4.round());
  check(NQ5, () => NQ5.round());
  check(NQ6, () => NQ6.round());

  check(PI1, () => PI1.round());
  check(PI2, () => PI2.round());
  check(PI3, () => PI3.round());
  check(PI4, () => PI4.round());
  check(PI5, () => PI5.round());
  check(PI6, () => PI6.round());
  check(PI7, () => PI7.round());

  check(NI1, () => NI1.round());
  check(NI2, () => NI2.round());
  check(NI3, () => NI3.round());
  check(NI4, () => NI4.round());
  check(NI5, () => NI5.round());
  check(NI6, () => NI6.round());
  check(NI7, () => NI7.round());

  // Check that the operation is not removed if it can throw, even if the result
  // is unused.
  Expect.throws(() {
    X1.round();
  });
  Expect.throws(() {
    X2.round();
  });
  Expect.throws(() {
    X3.round();
  });
  unusedCall(0);
  Expect.throws(() {
    unusedCall(X1);
  });
  Expect.throws(() {
    unusedCall(X2);
  });
  Expect.throws(() {
    unusedCall(X3);
  });
}
