// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that the captured variables with the same name are note
// placed into the same scope, which can be achieved, for example, by using new
// blocks to adjust scoping.

test(dynamic x1, dynamic x2) {
  if (x1 case var y) {}
  if (x1 case var y) {
    if (x2 case var y) {
      return y;
    }
  }
  throw "Expected to never reach this line of the program.";
}

main() {
  expectEquals(test(1, 2), 2);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} and ${y} to be equal.";
  }
}
