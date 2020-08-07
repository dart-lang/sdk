// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: Foo:OutputUnit(1, {libA, libB, libC})*/
class Foo {
  /*member: Foo.x:OutputUnit(1, {libA, libB, libC})*/
  int x;
  /*member: Foo.:OutputUnit(3, {libB})*/
  Foo() {
    x = DateTime.now().millisecond;
  }
  /*member: Foo.method:OutputUnit(1, {libA, libB, libC})*/
  int method() => x;
}

/*member: isFoo:OutputUnit(1, {libA, libB, libC})*/
bool isFoo(o) {
  return o is Foo;
}

/*member: callFooMethod:OutputUnit(3, {libB})*/
int callFooMethod() {
  return Foo().method();
}

typedef int FunFoo(Foo a);
typedef int FunFunFoo(FunFoo b, int c);

/*member: isFunFunFoo:OutputUnit(1, {libA, libB, libC})*/
bool isFunFunFoo(o) {
  return o is FunFunFoo;
}

/*class: Aoo:OutputUnit(4, {libB, libC})*/
class Aoo<T> {}

/*class: Boo:OutputUnit(4, {libB, libC})*/
class Boo<T> implements Aoo<T> {}

/*class: Coo:OutputUnit(4, {libB, libC})*/
/*member: Coo.:OutputUnit(6, {libC})*/
class Coo<T> {}

/*class: Doo:OutputUnit(4, {libB, libC})*/
/*member: Doo.:OutputUnit(6, {libC})*/
class Doo<T> extends Coo<T> with Boo<T> {}

/*member: createDooFunFunFoo:OutputUnit(6, {libC})*/
createDooFunFunFoo() => Doo<FunFunFoo>();

/*class: B:OutputUnit(2, {libA, libC})*/
/*member: B.:OutputUnit(6, {libC})*/
class B {}

/*class: B2:OutputUnit(2, {libA, libC})*/
/*member: B2.:OutputUnit(6, {libC})*/
class B2 extends B {}

/*class: C1:OutputUnit(2, {libA, libC})*/
class C1 {}

/*class: C2:OutputUnit(2, {libA, libC})*/
/*member: C2.:OutputUnit(6, {libC})*/
class C2 {}

/*class: C3:OutputUnit(2, {libA, libC})*/
/*member: C3.:OutputUnit(6, {libC})*/
class C3 extends C2 with C1 {}

/*class: D1:OutputUnit(2, {libA, libC})*/
class D1 {}

/*class: D2:OutputUnit(2, {libA, libC})*/
/*member: D2.:OutputUnit(6, {libC})*/
class D2 {}

/*class: D3:OutputUnit(2, {libA, libC})*/
class D3 = D2 with D1;

/*member: isMega:OutputUnit(5, {libA})*/
bool isMega(o) {
  return o is B2 || o is C3 || o is D3;
}
