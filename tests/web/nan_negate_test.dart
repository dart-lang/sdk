// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Don't convert !(a op b) to (a neg-op b) when a or b might be NaN.
test(double n) {
  // Force known type to double, preserves NaN.
  n = 0.0 + n;
  Expect.isFalse(n >= 0);
  Expect.isTrue(!(n < 0));

  Expect.isFalse(n <= 0);
  Expect.isTrue(!(n > 0));

  Expect.isFalse(n < 0);
  Expect.isTrue(!(n >= 0));

  Expect.isFalse(n > 0);
  Expect.isTrue(!(n <= 0));

  Expect.isFalse(n == 0);
  Expect.isFalse(!(n != 0));

  Expect.isTrue(n != 0);
  Expect.isTrue(!(n == 0));

  Expect.isFalse(identical(n, 0));
  Expect.isFalse(!(!identical(n, 0)));

  Expect.isTrue(!identical(n, 0));
  Expect.isTrue(!(identical(n, 0)));

  Expect.isFalse(0 >= n);
  Expect.isTrue(!(0 < n));

  Expect.isFalse(0 <= n);
  Expect.isTrue(!(0 > n));

  Expect.isFalse(0 < n);
  Expect.isTrue(!(0 >= n));

  Expect.isFalse(0 > n);
  Expect.isTrue(!(0 <= n));

  Expect.isFalse(0 == n);
  Expect.isFalse(!(0 != n));

  Expect.isTrue(0 != n);
  Expect.isTrue(!(0 == n));

  Expect.isFalse(identical(0, n));
  Expect.isFalse(!(!identical(0, n)));

  Expect.isTrue(!identical(0, n));
  Expect.isTrue(!(identical(0, n)));
}

testConstant() {
  Expect.isFalse(double.nan >= 0);
  Expect.isTrue(!(double.nan < 0));

  Expect.isFalse(double.nan <= 0);
  Expect.isTrue(!(double.nan > 0));

  Expect.isFalse(double.nan < 0);
  Expect.isTrue(!(double.nan >= 0));

  Expect.isFalse(double.nan > 0);
  Expect.isTrue(!(double.nan <= 0));

  Expect.isFalse(double.nan == 0);
  Expect.isFalse(!(double.nan != 0));

  Expect.isTrue(double.nan != 0);
  Expect.isTrue(!(double.nan == 0));

  Expect.isFalse(identical(double.nan, 0));
  Expect.isFalse(!(!identical(double.nan, 0)));

  Expect.isTrue(!identical(double.nan, 0));
  Expect.isTrue(!(identical(double.nan, 0)));

  Expect.isFalse(0 >= double.nan);
  Expect.isTrue(!(0 < double.nan));

  Expect.isFalse(0 <= double.nan);
  Expect.isTrue(!(0 > double.nan));

  Expect.isFalse(0 < double.nan);
  Expect.isTrue(!(0 >= double.nan));

  Expect.isFalse(0 > double.nan);
  Expect.isTrue(!(0 <= double.nan));

  Expect.isFalse(0 == double.nan);
  Expect.isFalse(!(0 != double.nan));

  Expect.isTrue(0 != double.nan);
  Expect.isTrue(!(0 == double.nan));

  Expect.isFalse(identical(0, double.nan));
  Expect.isFalse(!(!identical(0, double.nan)));

  Expect.isTrue(!identical(0, double.nan));
  Expect.isTrue(!(identical(0, double.nan)));
}

main() {
  test(hideConstant(27, double.nan));
  testConstant();
}

double hideConstant(int n, double result) {
  if (n == 1) return result;
  if ((n & 1) == 0) return hideConstant(n >> 1, result);
  return hideConstant(3 * n + 1, result);
}
