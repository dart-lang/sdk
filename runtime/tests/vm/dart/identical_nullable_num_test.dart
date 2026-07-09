// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--optimization_level=3

@pragma("vm:never-inline")
void check(num a, num? b) {
  if (!identical(a, b)) throw "bad";
}

main() {
  // same value, different object, but `identical` is equal for numbers
  check(0.0, double.parse("0.0"));
}
