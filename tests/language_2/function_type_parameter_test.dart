// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to check that we can parse closure type formal parameters with
// default value.

class A {
  final f;
  A(int this.f());
  const A.nother(int this.f());

  static Function func;

  static SetFunc([String fmt(int i) = null]) {
    func = fmt;
  }
}

main() {
  Expect.equals(null, A.func);
  A.SetFunc((i) => "$i");
  Expect.equals(false, null == A.func);
  Expect.equals("1234", A.func(1230 + 4));
  A.SetFunc();
  Expect.equals(null, A.func);

  Expect.equals(42, new A(() => 42).f());
  Expect.equals(42, new A.nother(() => 42).f());
}
