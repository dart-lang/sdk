// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: Foo:OutputUnit(1, {libB}), type=OutputUnit(3, {libA, libB, libC})*/
class Foo {
  /*member: Foo.x:OutputUnit(1, {libB})*/
  int x;
  /*member: Foo.:OutputUnit(1, {libB})*/
  Foo() {
    x = DateTime.now().millisecond;
  }
  /*member: Foo.method:OutputUnit(1, {libB})*/
  int method() => x;
}

/*member: isFoo:OutputUnit(3, {libA, libB, libC})*/
bool isFoo(o) {
  return o is Foo;
}

/*member: callFooMethod:OutputUnit(1, {libB})*/
int callFooMethod() {
  return Foo().method();
}

typedef int FunFoo(Foo a);
typedef int FunFunFoo(FunFoo b, int c);

/*member: isFunFunFoo:OutputUnit(3, {libA, libB, libC})*/
bool isFunFunFoo(o) {
  return o is FunFunFoo;
}

/*class: Aoo:none, type=OutputUnit(2, {libC})*/
class Aoo<T> {}

/*class: Boo:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
class Boo<T> implements Aoo<T> {}

/*class: Coo:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
/*member: Coo.:OutputUnit(2, {libC})*/
class Coo<T> {}

/*class: Doo:OutputUnit(2, {libC}), type=OutputUnit(5, {libB, libC})*/
/*member: Doo.:OutputUnit(2, {libC})*/
class Doo<T> extends Coo<T> with Boo<T> {}

/*member: createDooFunFunFoo:OutputUnit(2, {libC})*/
createDooFunFunFoo() => Doo<FunFunFoo>();

/*class: B:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
/*member: B.:OutputUnit(2, {libC})*/
class B {}

/*class: B2:OutputUnit(2, {libC}), type=OutputUnit(4, {libA, libC})*/
/*member: B2.:OutputUnit(2, {libC})*/
class B2 extends B {}

/*class: C1:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
class C1 {}

/*class: C2:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
/*member: C2.:OutputUnit(2, {libC})*/
class C2 {}

/*class: C3:OutputUnit(2, {libC}), type=OutputUnit(4, {libA, libC})*/
/*member: C3.:OutputUnit(2, {libC})*/
class C3 extends C2 with C1 {}

/*class: D1:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
class D1 {}

/*class: D2:OutputUnit(2, {libC}), type=OutputUnit(2, {libC})*/
/*member: D2.:OutputUnit(2, {libC})*/
class D2 {}

/*class: D3:OutputUnit(2, {libC}), type=OutputUnit(4, {libA, libC})*/
class D3 = D2 with D1;

/*member: isMega:OutputUnit(6, {libA})*/
bool isMega(o) {
  return o is B2 || o is C3 || o is D3;
}
