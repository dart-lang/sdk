// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

library org.dartlang.test.part2_test;

part "part.dart"; //# 01: compile-time error

main() {
  print(foo); //# 01: continued
}
