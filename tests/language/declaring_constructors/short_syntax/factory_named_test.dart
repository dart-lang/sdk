// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Using `factory name()` to declare named factory constructors with new shorter
// syntax.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

class C1 {
  final int x;
  C1._(this.x);

  // Equivalent to `factory C1.named() => C1._(1);`
  factory named() => C1._(1);
}

class C2 {
  final int x;
  const C2._() : x = 1;

  // Equivalent to `const factory C2.named() = C2._;`
  const factory named() = C2._;
}

void main() {
  Expect.equals(1, C1.named().x);
  Expect.equals(1, C2.named().x);
}
