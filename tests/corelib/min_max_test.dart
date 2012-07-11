// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing Math.min and Math.max.

testMin() {
  Expect.equals(0, Math.min(0, 2));
  Expect.equals(0, Math.min(2, 0));

  Expect.equals(-10, Math.min(-10, -9));
  Expect.equals(-10, Math.min(-10, 9));
  Expect.equals(-10, Math.min(-10, 0));
  Expect.equals(-10, Math.min(-9, -10));
  Expect.equals(-10, Math.min(9, -10));
  Expect.equals(-10, Math.min(0, -10));

  Expect.equals(0.5, Math.min(0.5, 2.5));
  Expect.equals(0.5, Math.min(2.5, 0.5));

  Expect.equals(-10.5, Math.min(-10.5, -9.5));
  Expect.equals(-10.5, Math.min(-10.5, 9.5));
  Expect.equals(-10.5, Math.min(-10.5, 0.5));
  Expect.equals(-10.5, Math.min(-9.5, -10.5));
  Expect.equals(-10.5, Math.min(9.5, -10.5));
  Expect.equals(-10.5, Math.min(0.5, -10.5));

  // Test matrix:
  // NaN, -infinity, -499.0, -499, -0.0, 0.0, 0, 499.0, 499, +infinity.
  var inf = double.INFINITY;
  var nan = double.NAN;

  Expect.isTrue(Math.min(nan, nan).isNaN());
  Expect.isTrue(Math.min(nan, -inf).isNaN());
  Expect.isTrue(Math.min(nan, -499.0).isNaN());
  Expect.isTrue(Math.min(nan, -499).isNaN());
  Expect.isTrue(Math.min(nan, -0.0).isNaN());
  Expect.isTrue(Math.min(nan, 0.0).isNaN());
  Expect.isTrue(Math.min(nan, 499.0).isNaN());
  Expect.isTrue(Math.min(nan, 499).isNaN());
  Expect.isTrue(Math.min(nan, inf).isNaN());

  Expect.equals(-inf, Math.min(-inf, -inf));
  Expect.equals(-inf, Math.min(-inf, -499.0));
  Expect.equals(-inf, Math.min(-inf, -499));
  Expect.equals(-inf, Math.min(-inf, -0.0));
  Expect.equals(-inf, Math.min(-inf, 0.0));
  Expect.equals(-inf, Math.min(-inf, 0));
  Expect.equals(-inf, Math.min(-inf, 499));
  Expect.equals(-inf, Math.min(-inf, 499.0));
  Expect.equals(-inf, Math.min(-inf, inf));
  Expect.isTrue(Math.min(-inf, nan).isNaN());

  Expect.equals(-inf, Math.min(-499.0, -inf));
  Expect.equals(-499.0, Math.min(-499.0, -499.0));
  Expect.equals(-499.0, Math.min(-499.0, -499));
  Expect.equals(-499.0, Math.min(-499.0, -0.0));
  Expect.equals(-499.0, Math.min(-499.0, 0.0));
  Expect.equals(-499.0, Math.min(-499.0, 0));
  Expect.equals(-499.0, Math.min(-499.0, 499.0));
  Expect.equals(-499.0, Math.min(-499.0, 499));
  Expect.equals(-499.0, Math.min(-499.0, inf));
  Expect.isTrue(Math.min(-499.0, nan).isNaN());

  Expect.isTrue(Math.min(-499.0, -499.0) is double);
  Expect.isTrue(Math.min(-499.0, -499) is double);
  Expect.isTrue(Math.min(-499.0, -0.0) is double);
  Expect.isTrue(Math.min(-499.0, 0.0) is double);
  Expect.isTrue(Math.min(-499.0, 0) is double);
  Expect.isTrue(Math.min(-499.0, 499.0) is double);
  Expect.isTrue(Math.min(-499.0, 499) is double);
  Expect.isTrue(Math.min(-499.0, inf) is double);

  Expect.equals(-inf, Math.min(-499, -inf));
  Expect.equals(-499, Math.min(-499, -499.0));
  Expect.equals(-499, Math.min(-499, -499));
  Expect.equals(-499, Math.min(-499, -0.0));
  Expect.equals(-499, Math.min(-499, 0.0));
  Expect.equals(-499, Math.min(-499, 0));
  Expect.equals(-499, Math.min(-499, 499.0));
  Expect.equals(-499, Math.min(-499, 499));
  Expect.equals(-499, Math.min(-499, inf));
  Expect.isTrue(Math.min(-499, nan).isNaN());

  Expect.isTrue(Math.min(-499, -499.0) is int);
  Expect.isTrue(Math.min(-499, -499) is int);
  Expect.isTrue(Math.min(-499, -0.0) is int);
  Expect.isTrue(Math.min(-499, 0.0) is int);
  Expect.isTrue(Math.min(-499, 0) is int);
  Expect.isTrue(Math.min(-499, 499.0) is int);
  Expect.isTrue(Math.min(-499, 499) is int);
  Expect.isTrue(Math.min(-499, inf) is int);

  Expect.equals(-inf, Math.min(-0.0, -inf));
  Expect.equals(-499.0, Math.min(-0.0, -499.0));
  Expect.equals(-499, Math.min(-0.0, -499));
  Expect.equals(-0.0, Math.min(-0.0, -0.0));
  Expect.equals(-0.0, Math.min(-0.0, 0.0));
  Expect.equals(-0.0, Math.min(-0.0, 0));
  Expect.equals(-0.0, Math.min(-0.0, 499.0));
  Expect.equals(-0.0, Math.min(-0.0, 499));
  Expect.equals(-0.0, Math.min(-0.0, inf));
  Expect.isTrue(Math.min(-0.0, nan).isNaN());

  Expect.isTrue(Math.min(-0.0, -499.0) is double);
  Expect.isTrue(Math.min(-0.0, -499) is int);
  Expect.isTrue(Math.min(-0.0, -0.0) is double);
  Expect.isTrue(Math.min(-0.0, 0.0) is double);
  Expect.isTrue(Math.min(-0.0, 0) is double);
  Expect.isTrue(Math.min(-0.0, 499.0) is double);
  Expect.isTrue(Math.min(-0.0, 499) is double);
  Expect.isTrue(Math.min(-0.0, inf) is double);

  Expect.isTrue(Math.min(-0.0, -499.0).isNegative());
  Expect.isTrue(Math.min(-0.0, -499).isNegative());
  Expect.isTrue(Math.min(-0.0, -0.0).isNegative());
  Expect.isTrue(Math.min(-0.0, 0.0).isNegative());
  Expect.isTrue(Math.min(-0.0, 0).isNegative());
  Expect.isTrue(Math.min(-0.0, 499.0).isNegative());
  Expect.isTrue(Math.min(-0.0, 499).isNegative());
  Expect.isTrue(Math.min(-0.0, inf).isNegative());

  Expect.equals(-inf, Math.min(0.0, -inf));
  Expect.equals(-499.0, Math.min(0.0, -499.0));
  Expect.equals(-499, Math.min(0.0, -499));
  Expect.equals(-0.0, Math.min(0.0, -0.0));
  Expect.equals(0.0, Math.min(0.0, 0.0));
  Expect.equals(0.0, Math.min(0.0, 0));
  Expect.equals(0.0, Math.min(0.0, 499.0));
  Expect.equals(0.0, Math.min(0.0, 499));
  Expect.equals(0.0, Math.min(0.0, inf));
  Expect.isTrue(Math.min(0.0, nan).isNaN());

  Expect.isTrue(Math.min(0.0, -499.0) is double);
  Expect.isTrue(Math.min(0.0, -499) is int);
  Expect.isTrue(Math.min(0.0, -0.0) is double);
  Expect.isTrue(Math.min(0.0, 0.0) is double);
  Expect.isTrue(Math.min(0.0, 0) is double);
  Expect.isTrue(Math.min(0.0, 499.0) is double);
  Expect.isTrue(Math.min(0.0, 499) is double);
  Expect.isTrue(Math.min(0.0, inf) is double);

  Expect.isTrue(Math.min(0.0, -499.0).isNegative());
  Expect.isTrue(Math.min(0.0, -499).isNegative());
  Expect.isTrue(Math.min(0.0, -0.0).isNegative());
  Expect.isFalse(Math.min(0.0, 0.0).isNegative());
  Expect.isFalse(Math.min(0.0, 0).isNegative());
  Expect.isFalse(Math.min(0.0, 499.0).isNegative());
  Expect.isFalse(Math.min(0.0, 499).isNegative());
  Expect.isFalse(Math.min(0.0, inf).isNegative());

  Expect.equals(-inf, Math.min(0, -inf));
  Expect.equals(-499.0, Math.min(0, -499.0));
  Expect.equals(-499, Math.min(0, -499));
  Expect.equals(-0.0, Math.min(0, -0.0));
  Expect.equals(0, Math.min(0, 0.0));
  Expect.equals(0, Math.min(0, 0));
  Expect.equals(0, Math.min(0, 499.0));
  Expect.equals(0, Math.min(0, 499));
  Expect.equals(0, Math.min(0, inf));
  Expect.isTrue(Math.min(0, nan).isNaN());

  Expect.isTrue(Math.min(0, -499.0) is double);
  Expect.isTrue(Math.min(0, -499) is int);
  Expect.isTrue(Math.min(0, -0.0) is double);
  Expect.isTrue(Math.min(0, 0.0) is int);
  Expect.isTrue(Math.min(0, 0) is int);
  Expect.isTrue(Math.min(0, 499.0) is int);
  Expect.isTrue(Math.min(0, 499) is int);
  Expect.isTrue(Math.min(0, inf) is int);

  Expect.isTrue(Math.min(0, -499.0).isNegative());
  Expect.isTrue(Math.min(0, -499).isNegative());
  Expect.isTrue(Math.min(0, -0.0).isNegative());
  Expect.isFalse(Math.min(0, 0.0).isNegative());
  Expect.isFalse(Math.min(0, 0).isNegative());
  Expect.isFalse(Math.min(0, 499.0).isNegative());
  Expect.isFalse(Math.min(0, 499).isNegative());
  Expect.isFalse(Math.min(0, inf).isNegative());

  Expect.equals(-inf, Math.min(499.0, -inf));
  Expect.equals(-499.0, Math.min(499.0, -499.0));
  Expect.equals(-499, Math.min(499.0, -499));
  Expect.equals(-0.0, Math.min(499.0, -0.0));
  Expect.equals(0.0, Math.min(499.0, 0.0));
  Expect.equals(0, Math.min(499.0, 0));
  Expect.equals(499.0, Math.min(499.0, 499.0));
  Expect.equals(499.0, Math.min(499.0, 499));
  Expect.equals(499.0, Math.min(499.0, inf));
  Expect.isTrue(Math.min(499.0, nan).isNaN());

  Expect.isTrue(Math.min(499.0, -499.0) is double);
  Expect.isTrue(Math.min(499.0, -499) is int);
  Expect.isTrue(Math.min(499.0, -0.0) is double);
  Expect.isTrue(Math.min(499.0, 0.0) is double);
  Expect.isTrue(Math.min(499.0, 0) is int);
  Expect.isTrue(Math.min(499.0, 499) is double);
  Expect.isTrue(Math.min(499.0, 499.0) is double);
  Expect.isTrue(Math.min(499.0, inf) is double);

  Expect.isTrue(Math.min(499.0, -499.0).isNegative());
  Expect.isTrue(Math.min(499.0, -499).isNegative());
  Expect.isTrue(Math.min(499.0, -0.0).isNegative());
  Expect.isFalse(Math.min(499.0, 0.0).isNegative());
  Expect.isFalse(Math.min(499.0, 0).isNegative());
  Expect.isFalse(Math.min(499.0, 499).isNegative());
  Expect.isFalse(Math.min(499.0, 499.0).isNegative());
  Expect.isFalse(Math.min(499.0, inf).isNegative());

  Expect.equals(-inf, Math.min(499, -inf));
  Expect.equals(-499.0, Math.min(499, -499.0));
  Expect.equals(-499, Math.min(499, -499));
  Expect.equals(-0.0, Math.min(499, -0.0));
  Expect.equals(0.0, Math.min(499, 0.0));
  Expect.equals(0, Math.min(499, 0));
  Expect.equals(499, Math.min(499, 499.0));
  Expect.equals(499, Math.min(499, 499));
  Expect.equals(499, Math.min(499, inf));
  Expect.isTrue(Math.min(499, nan).isNaN());

  Expect.isTrue(Math.min(499, -499.0) is double);
  Expect.isTrue(Math.min(499, -499) is int);
  Expect.isTrue(Math.min(499, -0.0) is double);
  Expect.isTrue(Math.min(499, 0.0) is double);
  Expect.isTrue(Math.min(499, 0) is int);
  Expect.isTrue(Math.min(499, 499.0) is int);
  Expect.isTrue(Math.min(499, 499) is int);
  Expect.isTrue(Math.min(499, inf) is int);

  Expect.isTrue(Math.min(499, -499.0).isNegative());
  Expect.isTrue(Math.min(499, -499).isNegative());
  Expect.isTrue(Math.min(499, -0.0).isNegative());
  Expect.isFalse(Math.min(499, 0.0).isNegative());
  Expect.isFalse(Math.min(499, 0).isNegative());
  Expect.isFalse(Math.min(499, 499.0).isNegative());
  Expect.isFalse(Math.min(499, 499).isNegative());
  Expect.isFalse(Math.min(499, inf).isNegative());

  Expect.equals(-inf, Math.min(inf, -inf));
  Expect.equals(-499.0, Math.min(inf, -499.0));
  Expect.equals(-499, Math.min(inf, -499));
  Expect.equals(-0.0, Math.min(inf, -0.0));
  Expect.equals(0.0, Math.min(inf, 0.0));
  Expect.equals(0, Math.min(inf, 0));
  Expect.equals(499.0, Math.min(inf, 499.0));
  Expect.equals(499, Math.min(inf, 499));
  Expect.equals(inf, Math.min(inf, inf));
  Expect.isTrue(Math.min(inf, nan).isNaN());

  Expect.isTrue(Math.min(inf, -499.0) is double);
  Expect.isTrue(Math.min(inf, -499) is int);
  Expect.isTrue(Math.min(inf, -0.0) is double);
  Expect.isTrue(Math.min(inf, 0.0) is double);
  Expect.isTrue(Math.min(inf, 0) is int);
  Expect.isTrue(Math.min(inf, 499) is int);
  Expect.isTrue(Math.min(inf, 499.0) is double);
  Expect.isTrue(Math.min(inf, inf) is double);

  Expect.isTrue(Math.min(inf, -499.0).isNegative());
  Expect.isTrue(Math.min(inf, -499).isNegative());
  Expect.isTrue(Math.min(inf, -0.0).isNegative());
  Expect.isFalse(Math.min(inf, 0.0).isNegative());
  Expect.isFalse(Math.min(inf, 0).isNegative());
  Expect.isFalse(Math.min(inf, 499).isNegative());
  Expect.isFalse(Math.min(inf, 499.0).isNegative());
  Expect.isFalse(Math.min(inf, inf).isNegative());
}

testMax() {
  Expect.equals(2, Math.max(0, 2));
  Expect.equals(2, Math.max(2, 0));

  Expect.equals(-9, Math.max(-10, -9));
  Expect.equals(9, Math.max(-10, 9));
  Expect.equals(0, Math.max(-10, 0));
  Expect.equals(-9, Math.max(-9, -10));
  Expect.equals(9, Math.max(9, -10));
  Expect.equals(0, Math.max(0, -10));

  Expect.equals(2.5, Math.max(0.5, 2.5));
  Expect.equals(2.5, Math.max(2.5, 0.5));

  Expect.equals(-9.5, Math.max(-10.5, -9.5));
  Expect.equals(9.5, Math.max(-10.5, 9.5));
  Expect.equals(0.5, Math.max(-10.5, 0.5));
  Expect.equals(-9.5, Math.max(-9.5, -10.5));
  Expect.equals(9.5, Math.max(9.5, -10.5));
  Expect.equals(0.5, Math.max(0.5, -10.5));

  // Test matrix:
  // NaN, infinity, 499.0, 499, 0.0, 0, -0.0, -499.0, -499, -infinity.
  var inf = double.INFINITY;
  var nan = double.NAN;

  Expect.isTrue(Math.max(nan, nan).isNaN());
  Expect.isTrue(Math.max(nan, -inf).isNaN());
  Expect.isTrue(Math.max(nan, -499.0).isNaN());
  Expect.isTrue(Math.max(nan, -499).isNaN());
  Expect.isTrue(Math.max(nan, -0.0).isNaN());
  Expect.isTrue(Math.max(nan, 0.0).isNaN());
  Expect.isTrue(Math.max(nan, 499.0).isNaN());
  Expect.isTrue(Math.max(nan, 499).isNaN());
  Expect.isTrue(Math.max(nan, inf).isNaN());

  Expect.equals(inf, Math.max(inf, inf));
  Expect.equals(inf, Math.max(inf, 499.0));
  Expect.equals(inf, Math.max(inf, 499));
  Expect.equals(inf, Math.max(inf, 0.0));
  Expect.equals(inf, Math.max(inf, 0));
  Expect.equals(inf, Math.max(inf, -0.0));
  Expect.equals(inf, Math.max(inf, -499));
  Expect.equals(inf, Math.max(inf, -499.0));
  Expect.equals(inf, Math.max(inf, -inf));
  Expect.isTrue(Math.max(inf, nan).isNaN());

  Expect.equals(inf, Math.max(499.0, inf));
  Expect.equals(499.0, Math.max(499.0, 499.0));
  Expect.equals(499.0, Math.max(499.0, 499));
  Expect.equals(499.0, Math.max(499.0, 0.0));
  Expect.equals(499.0, Math.max(499.0, 0));
  Expect.equals(499.0, Math.max(499.0, -0.0));
  Expect.equals(499.0, Math.max(499.0, -499));
  Expect.equals(499.0, Math.max(499.0, -499.0));
  Expect.equals(499.0, Math.max(499.0, -inf));
  Expect.isTrue(Math.max(499.0, nan).isNaN());

  Expect.isTrue(Math.max(499.0, 499.0) is double);
  Expect.isTrue(Math.max(499.0, 499) is double);
  Expect.isTrue(Math.max(499.0, 0.0) is double);
  Expect.isTrue(Math.max(499.0, 0) is double);
  Expect.isTrue(Math.max(499.0, -0.0) is double);
  Expect.isTrue(Math.max(499.0, -499) is double);
  Expect.isTrue(Math.max(499.0, -499.0) is double);
  Expect.isTrue(Math.max(499.0, -inf) is double);

  Expect.equals(inf, Math.max(499, inf));
  Expect.equals(499, Math.max(499, 499.0));
  Expect.equals(499, Math.max(499, 499));
  Expect.equals(499, Math.max(499, 0.0));
  Expect.equals(499, Math.max(499, 0));
  Expect.equals(499, Math.max(499, -0.0));
  Expect.equals(499, Math.max(499, -499));
  Expect.equals(499, Math.max(499, -499.0));
  Expect.equals(499, Math.max(499, -inf));
  Expect.isTrue(Math.max(499, nan).isNaN());

  Expect.isTrue(Math.max(499, 499.0) is int);
  Expect.isTrue(Math.max(499, 499) is int);
  Expect.isTrue(Math.max(499, 0.0) is int);
  Expect.isTrue(Math.max(499, 0) is int);
  Expect.isTrue(Math.max(499, -0.0) is int);
  Expect.isTrue(Math.max(499, -499) is int);
  Expect.isTrue(Math.max(499, -499.0) is int);
  Expect.isTrue(Math.max(499, -inf) is int);

  Expect.equals(inf, Math.max(0.0, inf));
  Expect.equals(499.0, Math.max(0.0, 499.0));
  Expect.equals(499, Math.max(0.0, 499));
  Expect.equals(0.0, Math.max(0.0, 0.0));
  Expect.equals(0.0, Math.max(0.0, 0));
  Expect.equals(0.0, Math.max(0.0, -0.0));
  Expect.equals(0.0, Math.max(0.0, -499));
  Expect.equals(0.0, Math.max(0.0, -499.0));
  Expect.equals(0.0, Math.max(0.0, -inf));
  Expect.isTrue(Math.max(0.0, nan).isNaN());

  Expect.isTrue(Math.max(0.0, 499.0) is double);
  Expect.isTrue(Math.max(0.0, 499) is int);
  Expect.isTrue(Math.max(0.0, 0.0) is double);
  Expect.isTrue(Math.max(0.0, 0) is double);
  Expect.isTrue(Math.max(0.0, -0.0) is double);
  Expect.isTrue(Math.max(0.0, -499) is double);
  Expect.isTrue(Math.max(0.0, -499.0) is double);
  Expect.isTrue(Math.max(0.0, -inf) is double);

  Expect.isFalse(Math.max(0.0, 0.0).isNegative());
  Expect.isFalse(Math.max(0.0, 0).isNegative());
  Expect.isFalse(Math.max(0.0, -0.0).isNegative());
  Expect.isFalse(Math.max(0.0, -499).isNegative());
  Expect.isFalse(Math.max(0.0, -499.0).isNegative());
  Expect.isFalse(Math.max(0.0, -inf).isNegative());

  Expect.equals(inf, Math.max(0, inf));
  Expect.equals(499.0, Math.max(0, 499.0));
  Expect.equals(499, Math.max(0, 499));
  Expect.equals(0, Math.max(0, 0.0));
  Expect.equals(0, Math.max(0, 0));
  Expect.equals(0, Math.max(0, -0.0));
  Expect.equals(0, Math.max(0, -499));
  Expect.equals(0, Math.max(0, -499.0));
  Expect.equals(0, Math.max(0, -inf));
  Expect.isTrue(Math.max(0, nan).isNaN());

  Expect.isTrue(Math.max(0, 499.0) is double);
  Expect.isTrue(Math.max(0, 499) is int);
  Expect.isTrue(Math.max(0, 0.0) is int);
  Expect.isTrue(Math.max(0, 0) is int);
  Expect.isTrue(Math.max(0, -0.0) is int);
  Expect.isTrue(Math.max(0, -499) is int);
  Expect.isTrue(Math.max(0, -499.0) is int);
  Expect.isTrue(Math.max(0, -inf) is int);

  Expect.isFalse(Math.max(0, 0.0).isNegative());
  Expect.isFalse(Math.max(0, 0).isNegative());
  Expect.isFalse(Math.max(0, -0.0).isNegative());
  Expect.isFalse(Math.max(0, -499).isNegative());
  Expect.isFalse(Math.max(0, -499.0).isNegative());
  Expect.isFalse(Math.max(0, -inf).isNegative());

  Expect.equals(inf, Math.max(-0.0, inf));
  Expect.equals(499.0, Math.max(-0.0, 499.0));
  Expect.equals(499, Math.max(-0.0, 499));
  Expect.equals(0.0, Math.max(-0.0, 0.0));
  Expect.equals(0.0, Math.max(-0.0, 0));
  Expect.equals(-0.0, Math.max(-0.0, -0.0));
  Expect.equals(-0.0, Math.max(-0.0, -499));
  Expect.equals(-0.0, Math.max(-0.0, -499.0));
  Expect.equals(-0.0, Math.max(-0.0, -inf));
  Expect.isTrue(Math.max(-0.0, nan).isNaN());

  Expect.isTrue(Math.max(-0.0, 499.0) is double);
  Expect.isTrue(Math.max(-0.0, 499) is int);
  Expect.isTrue(Math.max(-0.0, 0.0) is double);
  Expect.isTrue(Math.max(-0.0, 0) is int);
  Expect.isTrue(Math.max(-0.0, -0.0) is double);
  Expect.isTrue(Math.max(-0.0, -499) is double);
  Expect.isTrue(Math.max(-0.0, -499.0) is double);
  Expect.isTrue(Math.max(-0.0, -inf) is double);

  Expect.isFalse(Math.max(-0.0, 0.0).isNegative());
  Expect.isFalse(Math.max(-0.0, 0).isNegative());
  Expect.isTrue(Math.max(-0.0, -0.0).isNegative());
  Expect.isTrue(Math.max(-0.0, -499).isNegative());
  Expect.isTrue(Math.max(-0.0, -499.0).isNegative());
  Expect.isTrue(Math.max(-0.0, -inf).isNegative());

  Expect.equals(inf, Math.max(-499, inf));
  Expect.equals(499.0, Math.max(-499, 499.0));
  Expect.equals(499, Math.max(-499, 499));
  Expect.equals(0.0, Math.max(-499, 0.0));
  Expect.equals(0.0, Math.max(-499, 0));
  Expect.equals(-0.0, Math.max(-499, -0.0));
  Expect.equals(-499, Math.max(-499, -499));
  Expect.equals(-499, Math.max(-499, -499.0));
  Expect.equals(-499, Math.max(-499, -inf));
  Expect.isTrue(Math.max(-499, nan).isNaN());

  Expect.isTrue(Math.max(-499, 499.0) is double);
  Expect.isTrue(Math.max(-499, 499) is int);
  Expect.isTrue(Math.max(-499, 0.0) is double);
  Expect.isTrue(Math.max(-499, 0) is int);
  Expect.isTrue(Math.max(-499, -0.0) is double);
  Expect.isTrue(Math.max(-499, -499) is int);
  Expect.isTrue(Math.max(-499, -499.0) is int);
  Expect.isTrue(Math.max(-499, -inf) is int);

  Expect.isFalse(Math.max(-499, 0.0).isNegative());
  Expect.isFalse(Math.max(-499, 0).isNegative());
  Expect.isTrue(Math.max(-499, -0.0).isNegative());
  Expect.isTrue(Math.max(-499, -499).isNegative());
  Expect.isTrue(Math.max(-499, -499.0).isNegative());
  Expect.isTrue(Math.max(-499, -inf).isNegative());

  Expect.equals(inf, Math.max(-499.0, inf));
  Expect.equals(499.0, Math.max(-499.0, 499.0));
  Expect.equals(499, Math.max(-499.0, 499));
  Expect.equals(0.0, Math.max(-499.0, 0.0));
  Expect.equals(0.0, Math.max(-499.0, 0));
  Expect.equals(-0.0, Math.max(-499.0, -0.0));
  Expect.equals(-499.0, Math.max(-499.0, -499));
  Expect.equals(-499.0, Math.max(-499.0, -499.0));
  Expect.equals(-499.0, Math.max(-499.0, -inf));
  Expect.isTrue(Math.max(-499.0, nan).isNaN());

  Expect.isTrue(Math.max(-499.0, 499.0) is double);
  Expect.isTrue(Math.max(-499.0, 499) is int);
  Expect.isTrue(Math.max(-499.0, 0.0) is double);
  Expect.isTrue(Math.max(-499.0, 0) is int);
  Expect.isTrue(Math.max(-499.0, -0.0) is double);
  Expect.isTrue(Math.max(-499.0, -499) is double);
  Expect.isTrue(Math.max(-499.0, -499.0) is double);
  Expect.isTrue(Math.max(-499.0, -inf) is double);

  Expect.isFalse(Math.max(-499.0, 0.0).isNegative());
  Expect.isFalse(Math.max(-499.0, 0).isNegative());
  Expect.isTrue(Math.max(-499.0, -0.0).isNegative());
  Expect.isTrue(Math.max(-499.0, -499).isNegative());
  Expect.isTrue(Math.max(-499.0, -499.0).isNegative());
  Expect.isTrue(Math.max(-499.0, -inf).isNegative());

  Expect.equals(inf, Math.max(-inf, inf));
  Expect.equals(499.0, Math.max(-inf, 499.0));
  Expect.equals(499, Math.max(-inf, 499));
  Expect.equals(0.0, Math.max(-inf, 0.0));
  Expect.equals(0.0, Math.max(-inf, 0));
  Expect.equals(-0.0, Math.max(-inf, -0.0));
  Expect.equals(-499, Math.max(-inf, -499));
  Expect.equals(-499.0, Math.max(-inf, -499.0));
  Expect.equals(-inf, Math.max(-inf, -inf));
  Expect.isTrue(Math.max(-inf, nan).isNaN());

  Expect.isTrue(Math.max(-inf, 499.0) is double);
  Expect.isTrue(Math.max(-inf, 499) is int);
  Expect.isTrue(Math.max(-inf, 0.0) is double);
  Expect.isTrue(Math.max(-inf, 0) is int);
  Expect.isTrue(Math.max(-inf, -0.0) is double);
  Expect.isTrue(Math.max(-inf, -499) is int);
  Expect.isTrue(Math.max(-inf, -499.0) is double);
  Expect.isTrue(Math.max(-inf, -inf) is double);

  Expect.isFalse(Math.max(-inf, 0.0).isNegative());
  Expect.isFalse(Math.max(-inf, 0).isNegative());
  Expect.isTrue(Math.max(-inf, -0.0).isNegative());
  Expect.isTrue(Math.max(-inf, -499).isNegative());
  Expect.isTrue(Math.max(-inf, -499.0).isNegative());
  Expect.isTrue(Math.max(-inf, -inf).isNegative());
}

main() {
  testMin();
  testMax();
}
