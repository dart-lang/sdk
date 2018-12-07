// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/flutter/flutter/issues/25041

// This test may produce a compile time exception from stack overflow during
// enum initialization or succeed in enum initialization depending on exactly
// how much stack is left and used by the compiler. It should never crash nor
// produce a runtime exception.

enum Fruit {
  apple,
  banana,
}

getFruit() => Fruit.apple;

recurse() {
  try {
    recurse();
  } catch (e, st) {
    print("$e ${getFruit()}");
  }
}

main() {
  try {
    recurse();
  } on StackOverflowError catch (e) {
    // Swallow.
  }
}
