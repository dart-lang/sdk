// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.


class C {
  // Expect a compile-time error below:
  // No default values allowed in abstract method parameter lists.
  abstract int F31(int a, [int b = 20, int c = 30]);
}

main() {
  Expect.equals(true, false);
}
