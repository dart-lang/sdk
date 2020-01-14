// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A();
}

main() {
  new A(42);
  //   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
}
