// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Using `new` to declare constructors.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

class C1 {
  int x;
  new() : x = 1; // Equivalent to `C1() : x = 1;`
  new named() : x = 1; // Equivalent to `C1.named() : x = 1;`
}

class C2 {
  int x;
  new() : x = 1 {} // Equivalent to `C1() : x = 1 {}`
  new named() : x = 1 {}// Equivalent to `C1.named() : x = 1 {}`
}

class C3 {
  final int x;
  const new(this.x); // Equivalent to `const C2(this.x);`
  const new named(this.x); // Equivalent to `const C2.named(this.x);`
}

void main() {
  Expect.equals(1, C1().x);
  Expect.equals(1, C1.named().x);
  Expect.equals(1, C2().x);
  Expect.equals(1, C2.named().x);
  Expect.equals(1, C3(1).x);
  Expect.equals(1, C3.named(1).x);
}
