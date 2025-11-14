// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `factory() => C();` is a factory constructor whose name is the name of the
// enclosing class, and not a method.

// SharedOptions=--enable-experiment=declaring-constructors

class C {
  final int x;
  C.named(this.x);
  factory() => C.named(1); // Equivalent to `factory C() => C.named();`
}

void main() {
  var c = C.named(1);
  c.factory();
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}
