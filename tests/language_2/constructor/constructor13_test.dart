// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that there's no crash when constructor called with wrong
// number of args.

class Klass {
  Klass(v) {}
}

main() {
  new Klass();
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
  new Klass(1);
  new Klass(1, 2);
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.
}
