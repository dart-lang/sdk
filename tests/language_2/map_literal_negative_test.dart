// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Legacy compound literal syntax that should go away.

class MapLiteralNegativeTest {
  static testMain() {
    var map = new Map<int>{ "a": 1, "b": 2, "c": 3 };
  }
}

main() {
  MapLiteralNegativeTest.testMain();
}
