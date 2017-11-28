// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var myIdentical = identical;

main() {
  // Mint (2^63).
  // TODO(rnystrom): Figure out how to change this to work on the web.
  Expect.isTrue(myIdentical(0x8000000000000000, 0x8000000000000000));
  Expect.isFalse(myIdentical(0x8000000000000000, 0x8000000000000001));

  // Different types.
  Expect.isFalse(myIdentical(42, 42.0));

  // NaN handling.
  Expect.isTrue(myIdentical(double.nan, double.nan));
}
