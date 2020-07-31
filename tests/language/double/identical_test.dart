// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.isTrue(identical(42.0, 42.0));
  Expect.isTrue(identical(-0.0, -0.0));
  Expect.isTrue(identical(0.0, 0.0));
  Expect.isTrue(identical(1.234E9, 1.234E9));
  Expect.isFalse(identical(0.0, -0.0));
  Expect.isTrue(identical(double.nan, double.nan));
}
