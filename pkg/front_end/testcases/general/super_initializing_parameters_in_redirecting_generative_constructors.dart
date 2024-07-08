// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int x;
  A(this.x);
}

class C extends A {
  C(super._);
  C.r(super._) : this(0); // Error.
  factory C.r2(super._) = C; // Error.
}
