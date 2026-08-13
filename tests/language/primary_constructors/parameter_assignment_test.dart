// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that non-declaring primary constructor parameters can be assigned to
// in the constructor body. The test includes regular constructor variants
// that are errors for primary constructors.

import 'package:expect/expect.dart';

class C0(int? i) {
  int? x;
  this {
    i ??= 0;
    x = i;
  }
}

class S1 {
  S1(x);
}

class C1 extends S1 {
  int? x;

  C1(int? i) : super((i = 0) == 0) {
    x = i;
  }
}

class C2 {
  bool field;
  int? x;

  C2(int? i) : field = (i = 0) == 0 {
    x = i;
  }
}

main() {
  Expect.equals(0, C0(null).x);
  Expect.equals(1, C0(1).x);
  Expect.equals(0, C1(null).x);
  Expect.equals(0, C1(1).x);
  Expect.equals(0, C2(null).x);
  Expect.equals(0, C2(1).x);
}
