// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing Math.min and Math.max.

#library('min_max_test');
#import('dart:math');

testMin() {
  Expect.equals(0, min(0, 2));
  Expect.equals(0, min(2, 0));

  Expect.equals(-10, min(-10, -9));
  Expect.equals(-10, min(-10, 9));
  Expect.equals(-10, min(-10, 0));
  Expect.equals(-10, min(-9, -10));
  Expect.equals(-10, min(9, -10));
  Expect.equals(-10, min(0, -10));

  Expect.equals(0.5, min(0.5, 2.5));
  Expect.equals(0.5, min(2.5, 0.5));

  Expect.equals(-10.5, min(-10.5, -9.5));
  Expect.equals(-10.5, min(-10.5, 9.5));
  Expect.equals(-10.5, min(-10.5, 0.5));
  Expect.equals(-10.5, min(-9.5, -10.5));
  Expect.equals(-10.5, min(9.5, -10.5));
  Expect.equals(-10.5, min(0.5, -10.5));

  // Test matrix:
  // NaN, -infinity, -499.0, -499, -0.0, 0.0, 0, 499.0, 499, +infinity.
  var inf = double.INFINITY;
  var nan = double.NAN;

  Expect.isTrue(min(nan, nan).isNaN);
  Expect.isTrue(min(nan, -inf).isNaN);
  Expect.isTrue(min(nan, -499.0).isNaN);
  Expect.isTrue(min(nan, -499).isNaN);
  Expect.isTrue(min(nan, -0.0).isNaN);
  Expect.isTrue(min(nan, 0.0).isNaN);
  Expect.isTrue(min(nan, 499.0).isNaN);
  Expect.isTrue(min(nan, 499).isNaN);
  Expect.isTrue(min(nan, inf).isNaN);

  Expect.equals(-inf, min(-inf, -inf));
  Expect.equals(-inf, min(-inf, -499.0));
  Expect.equals(-inf, min(-inf, -499));
  Expect.equals(-inf, min(-inf, -0.0));
  Expect.equals(-inf, min(-inf, 0.0));
  Expect.equals(-inf, min(-inf, 0));
  Expect.equals(-inf, min(-inf, 499));
  Expect.equals(-inf, min(-inf, 499.0));
  Expect.equals(-inf, min(-inf, inf));
  Expect.isTrue(min(-inf, nan).isNaN);

  Expect.equals(-inf, min(-499.0, -inf));
  Expect.equals(-499.0, min(-499.0, -499.0));
  Expect.equals(-499.0, min(-499.0, -499));
  Expect.equals(-499.0, min(-499.0, -0.0));
  Expect.equals(-499.0, min(-499.0, 0.0));
  Expect.equals(-499.0, min(-499.0, 0));
  Expect.equals(-499.0, min(-499.0, 499.0));
  Expect.equals(-499.0, min(-499.0, 499));
  Expect.equals(-499.0, min(-499.0, inf));
  Expect.isTrue(min(-499.0, nan).isNaN);

  Expect.isTrue(min(-499.0, -499.0) is double);
  Expect.isTrue(min(-499.0, -499) is double);
  Expect.isTrue(min(-499.0, -0.0) is double);
  Expect.isTrue(min(-499.0, 0.0) is double);
  Expect.isTrue(min(-499.0, 0) is double);
  Expect.isTrue(min(-499.0, 499.0) is double);
  Expect.isTrue(min(-499.0, 499) is double);
  Expect.isTrue(min(-499.0, inf) is double);

  Expect.equals(-inf, min(-499, -inf));
  Expect.equals(-499, min(-499, -499.0));
  Expect.equals(-499, min(-499, -499));
  Expect.equals(-499, min(-499, -0.0));
  Expect.equals(-499, min(-499, 0.0));
  Expect.equals(-499, min(-499, 0));
  Expect.equals(-499, min(-499, 499.0));
  Expect.equals(-499, min(-499, 499));
  Expect.equals(-499, min(-499, inf));
  Expect.isTrue(min(-499, nan).isNaN);

  Expect.isTrue(min(-499, -499.0) is int);
  Expect.isTrue(min(-499, -499) is int);
  Expect.isTrue(min(-499, -0.0) is int);
  Expect.isTrue(min(-499, 0.0) is int);
  Expect.isTrue(min(-499, 0) is int);
  Expect.isTrue(min(-499, 499.0) is int);
  Expect.isTrue(min(-499, 499) is int);
  Expect.isTrue(min(-499, inf) is int);

  Expect.equals(-inf, min(-0.0, -inf));
  Expect.equals(-499.0, min(-0.0, -499.0));
  Expect.equals(-499, min(-0.0, -499));
  Expect.equals(-0.0, min(-0.0, -0.0));
  Expect.equals(-0.0, min(-0.0, 0.0));
  Expect.equals(-0.0, min(-0.0, 0));
  Expect.equals(-0.0, min(-0.0, 499.0));
  Expect.equals(-0.0, min(-0.0, 499));
  Expect.equals(-0.0, min(-0.0, inf));
  Expect.isTrue(min(-0.0, nan).isNaN);

  Expect.isTrue(min(-0.0, -499.0) is double);
  Expect.isTrue(min(-0.0, -499) is int);
  Expect.isTrue(min(-0.0, -0.0) is double);
  Expect.isTrue(min(-0.0, 0.0) is double);
  Expect.isTrue(min(-0.0, 0) is double);
  Expect.isTrue(min(-0.0, 499.0) is double);
  Expect.isTrue(min(-0.0, 499) is double);
  Expect.isTrue(min(-0.0, inf) is double);

  Expect.isTrue(min(-0.0, -499.0).isNegative);
  Expect.isTrue(min(-0.0, -499).isNegative);
  Expect.isTrue(min(-0.0, -0.0).isNegative);
  Expect.isTrue(min(-0.0, 0.0).isNegative);
  Expect.isTrue(min(-0.0, 0).isNegative);
  Expect.isTrue(min(-0.0, 499.0).isNegative);
  Expect.isTrue(min(-0.0, 499).isNegative);
  Expect.isTrue(min(-0.0, inf).isNegative);

  Expect.equals(-inf, min(0.0, -inf));
  Expect.equals(-499.0, min(0.0, -499.0));
  Expect.equals(-499, min(0.0, -499));
  Expect.equals(-0.0, min(0.0, -0.0));
  Expect.equals(0.0, min(0.0, 0.0));
  Expect.equals(0.0, min(0.0, 0));
  Expect.equals(0.0, min(0.0, 499.0));
  Expect.equals(0.0, min(0.0, 499));
  Expect.equals(0.0, min(0.0, inf));
  Expect.isTrue(min(0.0, nan).isNaN);

  Expect.isTrue(min(0.0, -499.0) is double);
  Expect.isTrue(min(0.0, -499) is int);
  Expect.isTrue(min(0.0, -0.0) is double);
  Expect.isTrue(min(0.0, 0.0) is double);
  Expect.isTrue(min(0.0, 0) is double);
  Expect.isTrue(min(0.0, 499.0) is double);
  Expect.isTrue(min(0.0, 499) is double);
  Expect.isTrue(min(0.0, inf) is double);

  Expect.isTrue(min(0.0, -499.0).isNegative);
  Expect.isTrue(min(0.0, -499).isNegative);
  Expect.isTrue(min(0.0, -0.0).isNegative);
  Expect.isFalse(min(0.0, 0.0).isNegative);
  Expect.isFalse(min(0.0, 0).isNegative);
  Expect.isFalse(min(0.0, 499.0).isNegative);
  Expect.isFalse(min(0.0, 499).isNegative);
  Expect.isFalse(min(0.0, inf).isNegative);

  Expect.equals(-inf, min(0, -inf));
  Expect.equals(-499.0, min(0, -499.0));
  Expect.equals(-499, min(0, -499));
  Expect.equals(-0.0, min(0, -0.0));
  Expect.equals(0, min(0, 0.0));
  Expect.equals(0, min(0, 0));
  Expect.equals(0, min(0, 499.0));
  Expect.equals(0, min(0, 499));
  Expect.equals(0, min(0, inf));
  Expect.isTrue(min(0, nan).isNaN);

  Expect.isTrue(min(0, -499.0) is double);
  Expect.isTrue(min(0, -499) is int);
  Expect.isTrue(min(0, -0.0) is double);
  Expect.isTrue(min(0, 0.0) is int);
  Expect.isTrue(min(0, 0) is int);
  Expect.isTrue(min(0, 499.0) is int);
  Expect.isTrue(min(0, 499) is int);
  Expect.isTrue(min(0, inf) is int);

  Expect.isTrue(min(0, -499.0).isNegative);
  Expect.isTrue(min(0, -499).isNegative);
  Expect.isTrue(min(0, -0.0).isNegative);
  Expect.isFalse(min(0, 0.0).isNegative);
  Expect.isFalse(min(0, 0).isNegative);
  Expect.isFalse(min(0, 499.0).isNegative);
  Expect.isFalse(min(0, 499).isNegative);
  Expect.isFalse(min(0, inf).isNegative);

  Expect.equals(-inf, min(499.0, -inf));
  Expect.equals(-499.0, min(499.0, -499.0));
  Expect.equals(-499, min(499.0, -499));
  Expect.equals(-0.0, min(499.0, -0.0));
  Expect.equals(0.0, min(499.0, 0.0));
  Expect.equals(0, min(499.0, 0));
  Expect.equals(499.0, min(499.0, 499.0));
  Expect.equals(499.0, min(499.0, 499));
  Expect.equals(499.0, min(499.0, inf));
  Expect.isTrue(min(499.0, nan).isNaN);

  Expect.isTrue(min(499.0, -499.0) is double);
  Expect.isTrue(min(499.0, -499) is int);
  Expect.isTrue(min(499.0, -0.0) is double);
  Expect.isTrue(min(499.0, 0.0) is double);
  Expect.isTrue(min(499.0, 0) is int);
  Expect.isTrue(min(499.0, 499) is double);
  Expect.isTrue(min(499.0, 499.0) is double);
  Expect.isTrue(min(499.0, inf) is double);

  Expect.isTrue(min(499.0, -499.0).isNegative);
  Expect.isTrue(min(499.0, -499).isNegative);
  Expect.isTrue(min(499.0, -0.0).isNegative);
  Expect.isFalse(min(499.0, 0.0).isNegative);
  Expect.isFalse(min(499.0, 0).isNegative);
  Expect.isFalse(min(499.0, 499).isNegative);
  Expect.isFalse(min(499.0, 499.0).isNegative);
  Expect.isFalse(min(499.0, inf).isNegative);

  Expect.equals(-inf, min(499, -inf));
  Expect.equals(-499.0, min(499, -499.0));
  Expect.equals(-499, min(499, -499));
  Expect.equals(-0.0, min(499, -0.0));
  Expect.equals(0.0, min(499, 0.0));
  Expect.equals(0, min(499, 0));
  Expect.equals(499, min(499, 499.0));
  Expect.equals(499, min(499, 499));
  Expect.equals(499, min(499, inf));
  Expect.isTrue(min(499, nan).isNaN);

  Expect.isTrue(min(499, -499.0) is double);
  Expect.isTrue(min(499, -499) is int);
  Expect.isTrue(min(499, -0.0) is double);
  Expect.isTrue(min(499, 0.0) is double);
  Expect.isTrue(min(499, 0) is int);
  Expect.isTrue(min(499, 499.0) is int);
  Expect.isTrue(min(499, 499) is int);
  Expect.isTrue(min(499, inf) is int);

  Expect.isTrue(min(499, -499.0).isNegative);
  Expect.isTrue(min(499, -499).isNegative);
  Expect.isTrue(min(499, -0.0).isNegative);
  Expect.isFalse(min(499, 0.0).isNegative);
  Expect.isFalse(min(499, 0).isNegative);
  Expect.isFalse(min(499, 499.0).isNegative);
  Expect.isFalse(min(499, 499).isNegative);
  Expect.isFalse(min(499, inf).isNegative);

  Expect.equals(-inf, min(inf, -inf));
  Expect.equals(-499.0, min(inf, -499.0));
  Expect.equals(-499, min(inf, -499));
  Expect.equals(-0.0, min(inf, -0.0));
  Expect.equals(0.0, min(inf, 0.0));
  Expect.equals(0, min(inf, 0));
  Expect.equals(499.0, min(inf, 499.0));
  Expect.equals(499, min(inf, 499));
  Expect.equals(inf, min(inf, inf));
  Expect.isTrue(min(inf, nan).isNaN);

  Expect.isTrue(min(inf, -499.0) is double);
  Expect.isTrue(min(inf, -499) is int);
  Expect.isTrue(min(inf, -0.0) is double);
  Expect.isTrue(min(inf, 0.0) is double);
  Expect.isTrue(min(inf, 0) is int);
  Expect.isTrue(min(inf, 499) is int);
  Expect.isTrue(min(inf, 499.0) is double);
  Expect.isTrue(min(inf, inf) is double);

  Expect.isTrue(min(inf, -499.0).isNegative);
  Expect.isTrue(min(inf, -499).isNegative);
  Expect.isTrue(min(inf, -0.0).isNegative);
  Expect.isFalse(min(inf, 0.0).isNegative);
  Expect.isFalse(min(inf, 0).isNegative);
  Expect.isFalse(min(inf, 499).isNegative);
  Expect.isFalse(min(inf, 499.0).isNegative);
  Expect.isFalse(min(inf, inf).isNegative);
}

testMax() {
  Expect.equals(2, max(0, 2));
  Expect.equals(2, max(2, 0));

  Expect.equals(-9, max(-10, -9));
  Expect.equals(9, max(-10, 9));
  Expect.equals(0, max(-10, 0));
  Expect.equals(-9, max(-9, -10));
  Expect.equals(9, max(9, -10));
  Expect.equals(0, max(0, -10));

  Expect.equals(2.5, max(0.5, 2.5));
  Expect.equals(2.5, max(2.5, 0.5));

  Expect.equals(-9.5, max(-10.5, -9.5));
  Expect.equals(9.5, max(-10.5, 9.5));
  Expect.equals(0.5, max(-10.5, 0.5));
  Expect.equals(-9.5, max(-9.5, -10.5));
  Expect.equals(9.5, max(9.5, -10.5));
  Expect.equals(0.5, max(0.5, -10.5));

  // Test matrix:
  // NaN, infinity, 499.0, 499, 0.0, 0, -0.0, -499.0, -499, -infinity.
  var inf = double.INFINITY;
  var nan = double.NAN;

  Expect.isTrue(max(nan, nan).isNaN);
  Expect.isTrue(max(nan, -inf).isNaN);
  Expect.isTrue(max(nan, -499.0).isNaN);
  Expect.isTrue(max(nan, -499).isNaN);
  Expect.isTrue(max(nan, -0.0).isNaN);
  Expect.isTrue(max(nan, 0.0).isNaN);
  Expect.isTrue(max(nan, 499.0).isNaN);
  Expect.isTrue(max(nan, 499).isNaN);
  Expect.isTrue(max(nan, inf).isNaN);

  Expect.equals(inf, max(inf, inf));
  Expect.equals(inf, max(inf, 499.0));
  Expect.equals(inf, max(inf, 499));
  Expect.equals(inf, max(inf, 0.0));
  Expect.equals(inf, max(inf, 0));
  Expect.equals(inf, max(inf, -0.0));
  Expect.equals(inf, max(inf, -499));
  Expect.equals(inf, max(inf, -499.0));
  Expect.equals(inf, max(inf, -inf));
  Expect.isTrue(max(inf, nan).isNaN);

  Expect.equals(inf, max(499.0, inf));
  Expect.equals(499.0, max(499.0, 499.0));
  Expect.equals(499.0, max(499.0, 499));
  Expect.equals(499.0, max(499.0, 0.0));
  Expect.equals(499.0, max(499.0, 0));
  Expect.equals(499.0, max(499.0, -0.0));
  Expect.equals(499.0, max(499.0, -499));
  Expect.equals(499.0, max(499.0, -499.0));
  Expect.equals(499.0, max(499.0, -inf));
  Expect.isTrue(max(499.0, nan).isNaN);

  Expect.isTrue(max(499.0, 499.0) is double);
  Expect.isTrue(max(499.0, 499) is double);
  Expect.isTrue(max(499.0, 0.0) is double);
  Expect.isTrue(max(499.0, 0) is double);
  Expect.isTrue(max(499.0, -0.0) is double);
  Expect.isTrue(max(499.0, -499) is double);
  Expect.isTrue(max(499.0, -499.0) is double);
  Expect.isTrue(max(499.0, -inf) is double);

  Expect.equals(inf, max(499, inf));
  Expect.equals(499, max(499, 499.0));
  Expect.equals(499, max(499, 499));
  Expect.equals(499, max(499, 0.0));
  Expect.equals(499, max(499, 0));
  Expect.equals(499, max(499, -0.0));
  Expect.equals(499, max(499, -499));
  Expect.equals(499, max(499, -499.0));
  Expect.equals(499, max(499, -inf));
  Expect.isTrue(max(499, nan).isNaN);

  Expect.isTrue(max(499, 499.0) is int);
  Expect.isTrue(max(499, 499) is int);
  Expect.isTrue(max(499, 0.0) is int);
  Expect.isTrue(max(499, 0) is int);
  Expect.isTrue(max(499, -0.0) is int);
  Expect.isTrue(max(499, -499) is int);
  Expect.isTrue(max(499, -499.0) is int);
  Expect.isTrue(max(499, -inf) is int);

  Expect.equals(inf, max(0.0, inf));
  Expect.equals(499.0, max(0.0, 499.0));
  Expect.equals(499, max(0.0, 499));
  Expect.equals(0.0, max(0.0, 0.0));
  Expect.equals(0.0, max(0.0, 0));
  Expect.equals(0.0, max(0.0, -0.0));
  Expect.equals(0.0, max(0.0, -499));
  Expect.equals(0.0, max(0.0, -499.0));
  Expect.equals(0.0, max(0.0, -inf));
  Expect.isTrue(max(0.0, nan).isNaN);

  Expect.isTrue(max(0.0, 499.0) is double);
  Expect.isTrue(max(0.0, 499) is int);
  Expect.isTrue(max(0.0, 0.0) is double);
  Expect.isTrue(max(0.0, 0) is double);
  Expect.isTrue(max(0.0, -0.0) is double);
  Expect.isTrue(max(0.0, -499) is double);
  Expect.isTrue(max(0.0, -499.0) is double);
  Expect.isTrue(max(0.0, -inf) is double);

  Expect.isFalse(max(0.0, 0.0).isNegative);
  Expect.isFalse(max(0.0, 0).isNegative);
  Expect.isFalse(max(0.0, -0.0).isNegative);
  Expect.isFalse(max(0.0, -499).isNegative);
  Expect.isFalse(max(0.0, -499.0).isNegative);
  Expect.isFalse(max(0.0, -inf).isNegative);

  Expect.equals(inf, max(0, inf));
  Expect.equals(499.0, max(0, 499.0));
  Expect.equals(499, max(0, 499));
  Expect.equals(0, max(0, 0.0));
  Expect.equals(0, max(0, 0));
  Expect.equals(0, max(0, -0.0));
  Expect.equals(0, max(0, -499));
  Expect.equals(0, max(0, -499.0));
  Expect.equals(0, max(0, -inf));
  Expect.isTrue(max(0, nan).isNaN);

  Expect.isTrue(max(0, 499.0) is double);
  Expect.isTrue(max(0, 499) is int);
  Expect.isTrue(max(0, 0.0) is int);
  Expect.isTrue(max(0, 0) is int);
  Expect.isTrue(max(0, -0.0) is int);
  Expect.isTrue(max(0, -499) is int);
  Expect.isTrue(max(0, -499.0) is int);
  Expect.isTrue(max(0, -inf) is int);

  Expect.isFalse(max(0, 0.0).isNegative);
  Expect.isFalse(max(0, 0).isNegative);
  Expect.isFalse(max(0, -0.0).isNegative);
  Expect.isFalse(max(0, -499).isNegative);
  Expect.isFalse(max(0, -499.0).isNegative);
  Expect.isFalse(max(0, -inf).isNegative);

  Expect.equals(inf, max(-0.0, inf));
  Expect.equals(499.0, max(-0.0, 499.0));
  Expect.equals(499, max(-0.0, 499));
  Expect.equals(0.0, max(-0.0, 0.0));
  Expect.equals(0.0, max(-0.0, 0));
  Expect.equals(-0.0, max(-0.0, -0.0));
  Expect.equals(-0.0, max(-0.0, -499));
  Expect.equals(-0.0, max(-0.0, -499.0));
  Expect.equals(-0.0, max(-0.0, -inf));
  Expect.isTrue(max(-0.0, nan).isNaN);

  Expect.isTrue(max(-0.0, 499.0) is double);
  Expect.isTrue(max(-0.0, 499) is int);
  Expect.isTrue(max(-0.0, 0.0) is double);
  Expect.isTrue(max(-0.0, 0) is int);
  Expect.isTrue(max(-0.0, -0.0) is double);
  Expect.isTrue(max(-0.0, -499) is double);
  Expect.isTrue(max(-0.0, -499.0) is double);
  Expect.isTrue(max(-0.0, -inf) is double);

  Expect.isFalse(max(-0.0, 0.0).isNegative);
  Expect.isFalse(max(-0.0, 0).isNegative);
  Expect.isTrue(max(-0.0, -0.0).isNegative);
  Expect.isTrue(max(-0.0, -499).isNegative);
  Expect.isTrue(max(-0.0, -499.0).isNegative);
  Expect.isTrue(max(-0.0, -inf).isNegative);

  Expect.equals(inf, max(-499, inf));
  Expect.equals(499.0, max(-499, 499.0));
  Expect.equals(499, max(-499, 499));
  Expect.equals(0.0, max(-499, 0.0));
  Expect.equals(0.0, max(-499, 0));
  Expect.equals(-0.0, max(-499, -0.0));
  Expect.equals(-499, max(-499, -499));
  Expect.equals(-499, max(-499, -499.0));
  Expect.equals(-499, max(-499, -inf));
  Expect.isTrue(max(-499, nan).isNaN);

  Expect.isTrue(max(-499, 499.0) is double);
  Expect.isTrue(max(-499, 499) is int);
  Expect.isTrue(max(-499, 0.0) is double);
  Expect.isTrue(max(-499, 0) is int);
  Expect.isTrue(max(-499, -0.0) is double);
  Expect.isTrue(max(-499, -499) is int);
  Expect.isTrue(max(-499, -499.0) is int);
  Expect.isTrue(max(-499, -inf) is int);

  Expect.isFalse(max(-499, 0.0).isNegative);
  Expect.isFalse(max(-499, 0).isNegative);
  Expect.isTrue(max(-499, -0.0).isNegative);
  Expect.isTrue(max(-499, -499).isNegative);
  Expect.isTrue(max(-499, -499.0).isNegative);
  Expect.isTrue(max(-499, -inf).isNegative);

  Expect.equals(inf, max(-499.0, inf));
  Expect.equals(499.0, max(-499.0, 499.0));
  Expect.equals(499, max(-499.0, 499));
  Expect.equals(0.0, max(-499.0, 0.0));
  Expect.equals(0.0, max(-499.0, 0));
  Expect.equals(-0.0, max(-499.0, -0.0));
  Expect.equals(-499.0, max(-499.0, -499));
  Expect.equals(-499.0, max(-499.0, -499.0));
  Expect.equals(-499.0, max(-499.0, -inf));
  Expect.isTrue(max(-499.0, nan).isNaN);

  Expect.isTrue(max(-499.0, 499.0) is double);
  Expect.isTrue(max(-499.0, 499) is int);
  Expect.isTrue(max(-499.0, 0.0) is double);
  Expect.isTrue(max(-499.0, 0) is int);
  Expect.isTrue(max(-499.0, -0.0) is double);
  Expect.isTrue(max(-499.0, -499) is double);
  Expect.isTrue(max(-499.0, -499.0) is double);
  Expect.isTrue(max(-499.0, -inf) is double);

  Expect.isFalse(max(-499.0, 0.0).isNegative);
  Expect.isFalse(max(-499.0, 0).isNegative);
  Expect.isTrue(max(-499.0, -0.0).isNegative);
  Expect.isTrue(max(-499.0, -499).isNegative);
  Expect.isTrue(max(-499.0, -499.0).isNegative);
  Expect.isTrue(max(-499.0, -inf).isNegative);

  Expect.equals(inf, max(-inf, inf));
  Expect.equals(499.0, max(-inf, 499.0));
  Expect.equals(499, max(-inf, 499));
  Expect.equals(0.0, max(-inf, 0.0));
  Expect.equals(0.0, max(-inf, 0));
  Expect.equals(-0.0, max(-inf, -0.0));
  Expect.equals(-499, max(-inf, -499));
  Expect.equals(-499.0, max(-inf, -499.0));
  Expect.equals(-inf, max(-inf, -inf));
  Expect.isTrue(max(-inf, nan).isNaN);

  Expect.isTrue(max(-inf, 499.0) is double);
  Expect.isTrue(max(-inf, 499) is int);
  Expect.isTrue(max(-inf, 0.0) is double);
  Expect.isTrue(max(-inf, 0) is int);
  Expect.isTrue(max(-inf, -0.0) is double);
  Expect.isTrue(max(-inf, -499) is int);
  Expect.isTrue(max(-inf, -499.0) is double);
  Expect.isTrue(max(-inf, -inf) is double);

  Expect.isFalse(max(-inf, 0.0).isNegative);
  Expect.isFalse(max(-inf, 0).isNegative);
  Expect.isTrue(max(-inf, -0.0).isNegative);
  Expect.isTrue(max(-inf, -499).isNegative);
  Expect.isTrue(max(-inf, -499.0).isNegative);
  Expect.isTrue(max(-inf, -inf).isNegative);
}

main() {
  testMin();
  testMax();
}
