// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializer is expected after final variable declaration.

class ConstInit6NegativeTest {
  final x;
  const ConstInit6NegativeTest()
    : x = 1.toString();  // Error: not a compile time const.
}

main() {
  const ConstInit6NegativeTest();
}
