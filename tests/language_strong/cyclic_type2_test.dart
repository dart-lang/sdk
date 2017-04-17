// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests self referencing types.

import "package:expect/expect.dart";

class Base<U, V> {
  get u => U;
  get v => V;
}

class Derived1<U, V>
    extends Base<Derived1<U, V>, Derived1<Derived2<V, U>, Derived2>> {}

class Derived2<U, V>
    extends Base<Derived2<U, V>, Derived2<Derived1<V, U>, Derived1>> {}

main() {
  var d = new Derived1<Derived1, Derived2>();
  Expect.equals("Derived1<Derived1, Derived2>", d.u.toString());
  Expect.equals(
      "Derived1<Derived2<Derived2, Derived1>, Derived2>", d.v.toString());
  Expect.isTrue(d is Derived1<Derived1, Derived2>);
  Expect.isFalse(d is Derived1<Derived1, Derived1>);
  Expect.isTrue(d is Base<Derived1<Derived1, Derived2>,
      Derived1<Derived2<Derived2, Derived1>, Derived2>>);
  Expect.isFalse(d is Base<Derived1<Derived1, Derived2>,
      Derived1<Derived2<Derived2, Derived2>, Derived2>>);
}
