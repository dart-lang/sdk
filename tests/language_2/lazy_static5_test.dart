// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final x = (int t) => (int u) => t + u;

main() {
  Expect.equals(499, x(498)(1));
  Expect.equals(42, x(39)(3));
}
