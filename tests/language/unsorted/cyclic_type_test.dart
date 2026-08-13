// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// Tests self referencing types.

import "package:expect/expect.dart";

@pragma("vm:entry-point")  // Prevent obfuscation
class Base<T> {
  get t => T;
}

// Derived<T> is contractive.
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived<T> extends Base<Derived<T>> {} // //# 00: ok

// Derived<T> is contractive.
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived<T> extends Base<Derived<Derived<int>>> {} // //# 01: ok

// Derived<T> is non-contractive.
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived<T> extends Base<Derived<Derived<T>>> {} // //# 02: ok

// Derived1<U> and Derived2<V> are contractive.
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived1<U> extends Base<Derived2<U>> {} //  //# 03: ok
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived2<V> extends Base<Derived1<V>> {} //  //# 03: ok

// Derived1<U> and Derived2<V> are non-contractive.
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived1<U> extends Base<Derived2<U>> {} //  //# 04: ok
@pragma("vm:entry-point")  // Prevent obfuscation
class Derived2<V> extends Base<Derived1<Derived2<V>>> {} //  //# 04: ok

main() {
  var d;
  d = new Derived(); // //# 00: continued
  Expect.equals(Derived<dynamic>, d.t); // //# 00: continued
  d = new Derived<bool>(); // //# 00: continued
  Expect.equals(Derived<bool>, d.t); // //# 00: continued
  d = new Derived<Derived>(); // //# 00: continued
  Expect.equals(Derived<Derived<dynamic>>, d.t); // //# 00: continued

  d = new Derived(); // //# 01: continued

  Expect.equals(Derived<Derived<int>>, d.t); // //# 01: continued
  d = new Derived<bool>(); // //# 01: continued
  Expect.equals(Derived<Derived<int>>, d.t); // //# 01: continued
  d = new Derived<Derived>(); // //# 01: continued
  Expect.equals(Derived<Derived<int>>, d.t); // //# 01: continued

  d = new Derived(); // //# 02: continued
  Expect.equals(Derived<Derived<dynamic>>, d.t); // //# 02: continued
  d = new Derived<bool>(); // //# 02: continued
  Expect.equals(Derived<Derived<bool>>, d.t); // //# 02: continued
  d = new Derived<Derived>(); // //# 02: continued
  Expect.equals(Derived<Derived<Derived<dynamic>>>, d.t); // //# 02: continued

  d = new Derived1(); // //# 03: continued
  Expect.equals(Derived2<dynamic>, d.t); // //# 03: continued
  d = new Derived2(); // //# 03: continued
  Expect.equals(Derived1<dynamic>, d.t); // //# 03: continued
  d = new Derived2<Derived1<int>>(); // //# 03: continued
  Expect.equals(Derived1<Derived1<int>>, d.t); // //# 03: continued

  d = new Derived1(); // //# 04: continued
  Expect.equals(Derived2<dynamic>, d.t); // //# 04: continued
  d = new Derived2(); // //# 04: continued
  Expect.equals(Derived1<Derived2<dynamic>>, d.t); // //# 04: continued
  d = new Derived2<Derived1<int>>(); // //# 04: continued
  Expect.equals(Derived1<Derived2<Derived1<int>>>, d.t); // //# 04: continued
}
