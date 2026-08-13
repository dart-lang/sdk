// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/53294.
// Verifies that compiler doesn't crash after converting non-speculative ~/
// to unary-.

@pragma("vm:never-inline")
hide() => null;

@pragma("vm:never-inline")
int foo2() {
  int loc0 = 23;
  try {
    while (--loc0 > 0) {
      hide();
    }
  } catch (exception, stackTrace) {
  } finally {
    return loc0 ~/ -1;
  }
}

main() {
  foo2();
}
