// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests self referencing types.

import "package:expect/expect.dart";

class Base<T> {
  get t => T;
}

// Derived<T> is contractive.
class Derived<T> extends Base<Derived<T>> {} // //# 00: ok

// Derived<T> is contractive.
class Derived<T> extends Base<Derived<Derived<int>>> {} // //# 01: ok

// Derived<T> is non-contractive.
class Derived<T> extends Base<Derived<Derived<T>>> {} // //# 02: ok

// Derived1<U> and Derived2<V> are contractive.
class Derived1<U> extends Base<Derived2<U>> {} //  //# 03: ok
class Derived2<V> extends Base<Derived1<V>> {} //  //# 03: ok

// Derived1<U> and Derived2<V> are non-contractive.
class Derived1<U> extends Base<Derived2<U>> {} //  //# 04: ok
class Derived2<V> extends Base<Derived1<Derived2<V>>> {} //  //# 04: ok

main() {
  // In the tests below we test that we get "int" and "bool" when calling
  // toString() on the int and bool type respectively. This is not required
  // behavior. However, we want to keep the original names for the most common
  // core types so we make sure to handle these specifically in the compiler.

  var d;
  d = new Derived(); // //# 00: continued
  Expect.equals("Derived", d.t.toString()); // //# 00: continued
  d = new Derived<bool>(); // //# 00: continued
  Expect.equals("Derived<bool>", d.t.toString()); // //# 00: continued
  d = new Derived<Derived>(); // //# 00: continued
  Expect.equals("Derived<Derived>", d.t.toString()); // //# 00: continued

  d = new Derived(); // //# 01: continued

  Expect.equals("Derived<Derived<int>>", d.t.toString()); // //# 01: continued
  d = new Derived<bool>(); // //# 01: continued
  Expect.equals("Derived<Derived<int>>", d.t.toString()); // //# 01: continued
  d = new Derived<Derived>(); // //# 01: continued
  Expect.equals("Derived<Derived<int>>", d.t.toString()); // //# 01: continued

  d = new Derived(); // //# 02: continued
  Expect.equals("Derived<Derived>", d.t.toString()); // //# 02: continued
  d = new Derived<bool>(); // //# 02: continued
  Expect.equals("Derived<Derived<bool>>", d.t.toString()); // //# 02: continued
  d = new Derived<Derived>(); // //# 02: continued
  Expect.equals("Derived<Derived<Derived>>", d.t.toString()); // //# 02: continued

  d = new Derived1(); // //# 03: continued
  Expect.equals("Derived2", d.t.toString()); // //# 03: continued
  d = new Derived2(); // //# 03: continued
  Expect.equals("Derived1", d.t.toString()); // //# 03: continued
  d = new Derived2<Derived1<int>>(); // //# 03: continued
  Expect.equals("Derived1<Derived1<int>>", d.t.toString()); // //# 03: continued

  d = new Derived1(); // //# 04: continued
  Expect.equals("Derived2", d.t.toString()); // //# 04: continued
  d = new Derived2(); // //# 04: continued
  Expect.equals("Derived1<Derived2>", d.t.toString()); // //# 04: continued
  d = new Derived2<Derived1<int>>(); // //# 04: continued
  Expect.equals("Derived1<Derived2<Derived1<int>>>", d.t.toString()); // //# 04: continued
}
