// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S {
  static foo() => 42;
}

class M {
  static bar() => 87;
}

typedef C = S with M;

main() {
  Expect.equals(42, S.foo());
  Expect.equals(87, M.bar());

  Expect.throws(() => C.foo(), (e) => e is NoSuchMethodError);
  Expect.throws(() => C.bar(), (e) => e is NoSuchMethodError);
}
