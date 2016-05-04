// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing Math.min and Math.max.

import "package:expect/expect.dart";

negate(x) => -x;

main() {
  // Test matrix:
  // -inf < -499.0 == -499 < -0.0 < 0.0 == 0 < 499.0 == 499 < +inf < -NaN, NaN.
  var inf = double.INFINITY;
  var nan = double.NAN;
  var mnan = negate(nan);

  Expect.equals(0, (-inf).compareTo(-inf));
  Expect.equals(-1, (-inf).compareTo(-499.0));
  Expect.equals(-1, (-inf).compareTo(-499));
  Expect.equals(-1, (-inf).compareTo(-0.0));
  Expect.equals(-1, (-inf).compareTo(0));
  Expect.equals(-1, (-inf).compareTo(0.0));
  Expect.equals(-1, (-inf).compareTo(499.0));
  Expect.equals(-1, (-inf).compareTo(499));
  Expect.equals(-1, (-inf).compareTo(inf));
  Expect.equals(-1, (-inf).compareTo(nan));
  Expect.equals(-1, (-inf).compareTo(mnan));

  Expect.equals(1, (-499.0).compareTo(-inf));
  Expect.equals(0, (-499.0).compareTo(-499.0));
  Expect.equals(0, (-499.0).compareTo(-499));
  Expect.equals(-1, (-499.0).compareTo(-0.0));
  Expect.equals(-1, (-499.0).compareTo(0));
  Expect.equals(-1, (-499.0).compareTo(0.0));
  Expect.equals(-1, (-499.0).compareTo(499.0));
  Expect.equals(-1, (-499.0).compareTo(499));
  Expect.equals(-1, (-499.0).compareTo(inf));
  Expect.equals(-1, (-499.0).compareTo(nan));
  Expect.equals(-1, (-499.0).compareTo(mnan));

  Expect.equals(1, (-499).compareTo(-inf));
  Expect.equals(0, (-499).compareTo(-499.0));
  Expect.equals(0, (-499).compareTo(-499));
  Expect.equals(-1, (-499).compareTo(-0.0));
  Expect.equals(-1, (-499).compareTo(0));
  Expect.equals(-1, (-499).compareTo(0.0));
  Expect.equals(-1, (-499).compareTo(499.0));
  Expect.equals(-1, (-499).compareTo(499));
  Expect.equals(-1, (-499).compareTo(inf));
  Expect.equals(-1, (-499).compareTo(nan));
  Expect.equals(-1, (-499).compareTo(mnan));

  Expect.equals(1, (-0.0).compareTo(-inf));
  Expect.equals(1, (-0.0).compareTo(-499.0));
  Expect.equals(1, (-0.0).compareTo(-499));
  Expect.equals(0, (-0.0).compareTo(-0.0));
  Expect.equals(-1, (-0.0).compareTo(0));
  Expect.equals(-1, (-0.0).compareTo(0.0));
  Expect.equals(-1, (-0.0).compareTo(499.0));
  Expect.equals(-1, (-0.0).compareTo(499));
  Expect.equals(-1, (-0.0).compareTo(inf));
  Expect.equals(-1, (-0.0).compareTo(nan));
  Expect.equals(-1, (-0.0).compareTo(mnan));

  Expect.equals(1, (0).compareTo(-inf));
  Expect.equals(1, (0).compareTo(-499.0));
  Expect.equals(1, (0).compareTo(-499));
  Expect.equals(1, (0).compareTo(-0.0));
  Expect.equals(0, (0).compareTo(0));
  Expect.equals(0, (0).compareTo(0.0));
  Expect.equals(-1, (0).compareTo(499.0));
  Expect.equals(-1, (0).compareTo(499));
  Expect.equals(-1, (0).compareTo(inf));
  Expect.equals(-1, (0).compareTo(nan));
  Expect.equals(-1, (0).compareTo(mnan));

  Expect.equals(1, (0.0).compareTo(-inf));
  Expect.equals(1, (0.0).compareTo(-499.0));
  Expect.equals(1, (0.0).compareTo(-499));
  Expect.equals(1, (0.0).compareTo(-0.0));
  Expect.equals(0, (0.0).compareTo(0));
  Expect.equals(0, (0.0).compareTo(0.0));
  Expect.equals(-1, (0.0).compareTo(499.0));
  Expect.equals(-1, (0.0).compareTo(499));
  Expect.equals(-1, (0.0).compareTo(inf));
  Expect.equals(-1, (0.0).compareTo(nan));
  Expect.equals(-1, (0.0).compareTo(mnan));

  Expect.equals(1, (499.0).compareTo(-inf));
  Expect.equals(1, (499.0).compareTo(-499.0));
  Expect.equals(1, (499.0).compareTo(-499));
  Expect.equals(1, (499.0).compareTo(-0.0));
  Expect.equals(1, (499.0).compareTo(0));
  Expect.equals(1, (499.0).compareTo(0.0));
  Expect.equals(0, (499.0).compareTo(499.0));
  Expect.equals(0, (499.0).compareTo(499));
  Expect.equals(-1, (499.0).compareTo(inf));
  Expect.equals(-1, (499.0).compareTo(nan));
  Expect.equals(-1, (499.0).compareTo(mnan));

  Expect.equals(1, (499).compareTo(-inf));
  Expect.equals(1, (499).compareTo(-499.0));
  Expect.equals(1, (499).compareTo(-499));
  Expect.equals(1, (499).compareTo(-0.0));
  Expect.equals(1, (499).compareTo(0));
  Expect.equals(1, (499).compareTo(0.0));
  Expect.equals(0, (499).compareTo(499.0));
  Expect.equals(0, (499).compareTo(499));
  Expect.equals(-1, (499).compareTo(inf));
  Expect.equals(-1, (499).compareTo(nan));
  Expect.equals(-1, (499).compareTo(mnan));

  Expect.equals(1, inf.compareTo(-inf));
  Expect.equals(1, inf.compareTo(-499.0));
  Expect.equals(1, inf.compareTo(-499));
  Expect.equals(1, inf.compareTo(-0.0));
  Expect.equals(1, inf.compareTo(0));
  Expect.equals(1, inf.compareTo(0.0));
  Expect.equals(1, inf.compareTo(499.0));
  Expect.equals(1, inf.compareTo(499));
  Expect.equals(0, inf.compareTo(inf));
  Expect.equals(-1, inf.compareTo(nan));
  Expect.equals(-1, inf.compareTo(mnan));

  Expect.equals(1, nan.compareTo(-inf));
  Expect.equals(1, nan.compareTo(-499.0));
  Expect.equals(1, nan.compareTo(-499));
  Expect.equals(1, nan.compareTo(-0.0));
  Expect.equals(1, nan.compareTo(0));
  Expect.equals(1, nan.compareTo(0.0));
  Expect.equals(1, nan.compareTo(499.0));
  Expect.equals(1, nan.compareTo(499));
  Expect.equals(1, nan.compareTo(inf));
  Expect.equals(0, nan.compareTo(nan));
  Expect.equals(0, nan.compareTo(mnan));
}
