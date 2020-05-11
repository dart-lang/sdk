// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library sets up various null-safe classes which have as a
// superinterface one of `A<int>`,`A<int?>`, `M<int>` or `M<int?>`.
// Each class has a getter, setter, and method; each is concrete; and
// the method signatures are incompatible (so the signature from `A<int>`
// and from `A<int?>` do not have a correct override relationship in
// any direction), thus allowing a test to verify that legacy type
// mitigation does take place when superinterfaces like `A<int>` and
// `A<int?>` are brought together, it is not just overriding.

// Naming conventions: Class `A` and mixin `M` are used as the top of every
// superinterface graph (except Object). Classes named `Be..` extend `A`,
// classes named `Bwm..` apply the mixin `M` (`w` refers to `with`), and
// classes named `Bwc..` apply the class `A` as a mixin. Finally, classes
// named `Bi..` implement `A`. In each case, classes whose name ends in `q`
// have `A<int?>` as a superinterface and other classes have `A<int>`.
// All classes are concrete, so a couple of them repeat the member
// implementation declarations (with the same member signatures, i.e., with
// no conflicts).

class A<X> {
  List<X> get a => [];
  set a(List<X> _) {}
  X m(X x) => x;
}

mixin M<X> {
  List<X> get a => [];
  set a(List<X> _) {}
  X m(X x) => x;
}

class Be extends A<int> {}

class Bi implements A<int> {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class Beq extends A<int?> {}

class Biq implements A<int?> {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

class Bwc with A<int> {}

class Bwcq with A<int?> {}

class Bwm with M<int> {}

class Bwmq with M<int?> {}
