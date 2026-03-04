// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Consider a factory constructor declaration of the form `factory C(...`
// optionally starting with the modifier `const`. Assume that `C` is the
// name of the enclosing class, mixin class, enum, or extension type. In
// this situation, the declaration declares a constructor whose name is
// `C`.
//
// The rule which is being tested here is also applicable when the
// declaration has some of the keywords external and augment, but we don't
// test those kinds of constructors here.

// SharedOptions=--enable-experiment=primary-constructors

import "package:expect/expect.dart";

class C {
  final int x;
  C._(this.x);

  // The special rule ensures this declares constructor `C`, not `C.C`.
  factory C(int x) => C._(x);
}

class D {
  final int x;
  const D._(this.x);

  // The special rule ensures this declares constructor `D`, not `D.D`.
  const factory D(int x) = D._;
}

class Methods {
  // Not a factory constructor because it starts with a type.
  int factory() => 1;
}

void main() {
  Expect.equals(1, C(1).x);
  Expect.equals(2, D(2).x);
  Expect.equals(1, Methods().factory());
}
