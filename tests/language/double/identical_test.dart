// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:expect/variations.dart' as v;

main() {
  Expect.isTrue(identical(42.0, 42.0));
  Expect.isTrue(identical(-0.0, -0.0));
  Expect.isTrue(identical(0.0, 0.0));
  Expect.isTrue(identical(1.234E9, 1.234E9));
  if (!v.jsNumbers) {
    Expect.isFalse(identical(0.0, -0.0));
    Expect.isTrue(identical(double.nan, double.nan));
  } else {
    // Web numbers have different behavior for identical for zeros and NaNs.
    // See: https://dart.dev/guides/language/numbers
    // TODO(https://dartbug.com/42224): Reconsider this different behavior.
    Expect.isTrue(identical(0.0, -0.0));
    Expect.isFalse(identical(double.nan, double.nan));
  }
}
