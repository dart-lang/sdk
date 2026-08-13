// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/378737064.
//
// Verifies that compiler doesn't crash after it incorrectly converts
// null-aware int? comparison to IfThenElse.

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
int foo(int? x, int? y) => x == y ? 0 : 255;

main() {
  Expect.equals(0, foo(0, 0));
  Expect.equals(255, foo(0, 42));
  Expect.equals(0, foo(null, null));
  Expect.equals(255, foo(null, 0x1234567890));
  Expect.equals(0, foo(0x1234567890, 0x1234567890));
  Expect.equals(255, foo(0x1234567890, 0x1234567891));
}
