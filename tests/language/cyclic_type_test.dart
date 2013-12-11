// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests self referencing types.

import "package:expect/expect.dart";

class Base<T> {
  get t => T;
}

class Derived<T> extends Base<Derived<Derived<T>>> {}

class Derived1<T> extends Base<Derived2<T>> {}

class Derived2<T> extends Base<Derived1<Derived2<T>>> {}

main() {
  var d = new Derived();
  Expect.equals("Derived<Derived>", d.t.toString());
  d = new Derived<bool>();
  Expect.equals("Derived<Derived<bool>>", d.t.toString());
  d = new Derived<Derived>();
  Expect.equals("Derived<Derived<Derived>>", d.t.toString());
  d = new Derived1();
  Expect.equals("Derived2", d.t.toString());
  d = new Derived2();
  Expect.equals("Derived1<Derived2>", d.t.toString());
  d = new Derived2<Derived1<int>>();
  Expect.equals("Derived1<Derived2<Derived1<int>>>", d.t.toString());
}
