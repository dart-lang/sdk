// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// Test unboxed double operations inside try-catch.
foo(bool b) {
  if (b) throw 123;
}

test_double(double x, bool b) {
  try {
    x += 1.0;
    foo(b);
  } catch (e) {
    var result = x - 1.0;
    Expect.equals(1.0, result);
    return result;
  }
}

main() {
  for (var i = 0; i < 100; i++) test_double(1.0, false);
  test_double(1.0, false);
  Expect.equals(1.0, test_double(1.0, true));
}

