// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression for #24134: inference was not tracking ??= correctly.
library dart2js.if_null2_test;

import "package:expect/expect.dart";

main() {
  var map;
  map ??= {};
  Expect.equals(0, map.length);
  Expect.isTrue(map.length == 0);
}
