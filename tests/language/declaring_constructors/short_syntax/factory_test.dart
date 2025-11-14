// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `factory() => C();` is a factory constructor whose name is the name of the
// enclosing class, and not a method.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

class C1 {
  final int x;
  C1._(this.x);
  factory() => C1._(1); // Equivalent to `factory C1() => C1._(1);`
}

class C2 {
  final int x;
  const C2._() : x = 1;
  const factory() = C2._; // Equivalent to `const factory C2() = C2._;`
}

void main() {
  Expect.equals(1, C1().x);
  Expect.equals(1, C2().x);
}
