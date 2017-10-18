// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that an attempt to assign to a class, enum, typedef, or type
// parameter produces a static warning and runtime error.

import "package:expect/expect.dart";

noMethod(e) => e is NoSuchMethodError;

class C<T> {
  f() {
    Expect.throws(() => T = null, noMethod); //# 01: static type warning
  }
}

class D {}

enum E { e0 }

typedef void F();

main() {
  new C<D>().f();
  Expect.throws(() => D = null, noMethod); //# 02: static type warning
  Expect.throws(() => E = null, noMethod); //# 03: static type warning
  Expect.throws(() => F = null, noMethod); //# 04: static type warning
}
