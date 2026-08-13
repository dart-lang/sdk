// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/45691.
// Verifies that materialization of objects with uninitialized late fields
// doesn't crash.

// VMOptions=--optimization-counter-threshold=100 --deterministic

import 'package:expect/expect.dart';

class A {
  late int x = int.parse('42');
  int y = 10;
}

@pragma("vm:never-inline")
void foo(num deopt) {
  A a = A();
  deopt + 1;
  Expect.equals(10, a.y);
}

void main() {
  for (int i = 0; i < 150; ++i) {
    foo(i > 100 ? 1.0 : 2);
  }
}
