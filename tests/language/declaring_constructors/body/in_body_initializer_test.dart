// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A declaring body constructor can have a body and an initializer list as well
// as initializing formals, just like other constructors in the body.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class C1 {
  int y;
  this(final int x) : y = x;
}

class C2 {
  this(final int x) : assert(x > 0);
}

class C3 extends C1 {
  // Will override the `x` instance variable in `C1`.
  this(final int x) : super(x + 1);
}

class C4 extends C1 {
  int y;
  this(int z) : y = z, assert(z > 0), super(z + 1);
}

extension type Ext1 {
  this(final int x) : assert(x > 0);
}

enum Enum1 {
  e(1);

  const this(final int x) : assert(x > 0);
}

enum const Enum2 {
  e(1);

  final int y;
  this(final int x) : y = x;
}

void main() {
  Expect.equals(1, C1(1).x);
  Expect.equals(1, C1(1).y);

  Expect.equals(1, C2(1).x);

  Expect.equals(1, C3(1).x);

  Expect.equals(2, C4(1).x);
  Expect.equals(1, C4(1).y);

  Expect.equals(1, Ext1(1).x);

  Expect.equals(1, Enum1.e.x);
  Expect.equals(1, Enum2.e.x);
}
