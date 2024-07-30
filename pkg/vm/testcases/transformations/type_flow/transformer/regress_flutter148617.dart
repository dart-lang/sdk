// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/148617.
// Verifies that TFA should not infer nullable return type if
// static return type is non-nullable.

int foo() => int.parse('1');

int bar() {
  try {
    return foo();
  } catch (e, st) {
    Error.throwWithStackTrace(e, st);
  }
}

main() {
  print(bar());
}
