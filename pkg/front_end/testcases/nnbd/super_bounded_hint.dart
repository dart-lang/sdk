// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// -------------------------------- Gives hint. -------------------------------

class A<X> {}

typedef F<X extends A<X>, Y extends A<Y>> = X Function(Y);

foo1a(F<A<dynamic>, A<Never>> x) {}
foo1b(F x) {}

foo2a<X extends F<A<dynamic>, A<Never>>>() {}
foo2b<X extends F>() {}

class Foo3a<X extends F<A<dynamic>, A<Never>>> {}

class Foo3b<X extends F> {}

F<A<dynamic>, A<Never>> foo4a() => throw 42;
F foo4b() => throw 42;

foo5a({required F<A<dynamic>, A<Never>> x}) {}
foo5b({required F x}) {}

foo6a() {
  F<A<dynamic>, A<Never>> x;
  for (F<A<dynamic>, A<Never>> x in []) {}
  fooFoo1(F<A<dynamic>, A<Never>> x) {}
  fooFoo2<X extends F<A<dynamic>, A<Never>>>() {}
  F<A<dynamic>, A<Never>> fooFoo4() => throw 42;
  fooFoo5({required F<A<dynamic>, A<Never>> x}) {}
  fooFoo7([F<A<dynamic>, A<Never>>? x]) {}
}

foo6b() {
  F x;
  for (F x in []) {}
  fooFoo1(F x) {}
  fooFoo2<X extends F>() {}
  F fooFoo4() => throw 42;
  fooFoo5({required F x}) {}
  fooFoo7([F? x]) {}
}

foo7a([F<A<dynamic>, A<Never>>? x]) {}
foo7b([F? x]) {}

// ---------------------------- Doesn't give hint. ----------------------------

class B<X extends int> {}

bar1(B<num> x) {}

bar2<X extends B<num>>() {}

class Bar3<X extends B<num>> {}

B<num> bar4() => throw 42;

bar5({required B<num> x}) {}

bar6() {
  B<num> x;
  for (B<num> x in []) {}
  barBar1(B<num> x) {}
  barBar2<X extends B<num>>() {}
  B<num> barBar4() => throw 42;
  barBar5({required B<num> x}) {}
  barBar7([B<num>? x]) {}
  new B<dynamic>();
  new A<B<dynamic>>();
}

bar7([B<num>? x]) {}

class Bar8 extends B<dynamic> {}

main() {}
