// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/63478.
// Verifies that initializer of a late variable doesn't affect
// subsequent statements.

void test1() {
  late var x = throw "error";
  print("reachable");
}

Never sayNever() => throw 'Never';

void test2() {
  late Never y = sayNever();
  print("reachable");
}

void main() {
  test1();
  test2();
}
