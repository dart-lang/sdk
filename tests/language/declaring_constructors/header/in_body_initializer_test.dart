// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A declaring header constructor can have a body and/or an initializer list.
// These elements are placed in the class body in a declaration that provides
// "the rest" of the constructor declaration which is given in the header.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class C1(final int x) {
  int y;
  this : y = x;
}

class C2(final int x) {
  this : assert(x > 0);
}

class C3(final int x) extends C1 {
  // Will override the `x` instance variable in `C1`.
  this : super(x + 1);
}

class C4(int z) extends C1 {
  int y;
  this : y = z, assert(z > 0), super(z + 1);
}

extension type Ext1(final int x) {
  this : assert(x > 0);
}

enum const Enum1(final int x) {
  e(1);

  this : assert(x > 0);
}

enum const Enum2(final int x) {
  e(1);

  final int y;
  this : y = x;
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
