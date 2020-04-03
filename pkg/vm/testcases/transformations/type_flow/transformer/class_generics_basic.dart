// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  foo() => D<T>();
  dynamic id1(T x) => x;
  dynamic id2(T x) => x;
}

class D<T> {}

class E<S, T> extends C<T> {
  foo() => super.foo();
  bar() => D<S>();
  baz() => D<T>();
}

class X {}

class Y extends X {}

class Z extends X {}

class I<T> {}

class J extends I<int> {}

class K<T> {}

class C2<T> {
  dynamic id3(Comparable<T> x) => x;
  dynamic id4(K<I<T>> x) => x;
}

main() {
  // Test that type arguments are instantiated correctly on concrete types.
  print(C<int>().foo());
  print(E<int, String>().foo());
  print(E<int, String>().bar());
  print(E<int, String>().baz());

  // Test that narrow against type-parameters works.
  C<X> c = new C<Y>();
  c.id1(Y());
  c.id2(Z());

  // Test that generic supertypes of non-generic types are handled correctly.
  C2<num> c2 = new C2<num>();
  c2.id3(3.0);
  c2.id4(K<J>());
}
