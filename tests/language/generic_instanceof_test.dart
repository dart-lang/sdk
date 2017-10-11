// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

library GenericInstanceofTest.dart;

import "package:expect/expect.dart";
part "generic_instanceof.dart";

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    GenericInstanceof.testMain();
  }
}
