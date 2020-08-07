// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: a:OutputUnit(1, {lib})*/
a() => print("123");

/*member: b:OutputUnit(1, {lib})*/
b() => print("123");

/*member: c:OutputUnit(1, {lib})*/
c() => print("123");

/*member: d:OutputUnit(1, {lib})*/
d() => print("123");

/*class: B:OutputUnit(1, {lib})*/
class B {
  /*member: B.:OutputUnit(1, {lib})*/
  B() {
    b();
  }
}

/*class: B2:OutputUnit(1, {lib})*/
/*member: B2.:OutputUnit(1, {lib})*/
class B2 extends B {
  // No constructor creates a synthetic constructor that has an implicit
  // super-call.
}

/*class: A:OutputUnit(1, {lib})*/
class A {
  /*member: A.:OutputUnit(1, {lib})*/
  A() {
    a();
  }
}

/*class: A2:OutputUnit(1, {lib})*/
class A2 extends A {
  // Implicit super call.
  /*member: A2.:OutputUnit(1, {lib})*/
  A2();
}

/*class: C1:OutputUnit(1, {lib})*/
class C1 {}

/*class: C2:OutputUnit(1, {lib})*/
class C2 {
  /*member: C2.:OutputUnit(1, {lib})*/
  C2() {
    c();
  }
}

/*class: C2p:null*/
class C2p {
  C2() {
    c();
  }
}

/*class: C3:OutputUnit(1, {lib})*/
/*member: C3.:OutputUnit(1, {lib})*/
class C3 extends C2 with C1 {
  // Implicit redirecting "super" call via mixin.
}

/*class: E:OutputUnit(1, {lib})*/
class E {}

/*class: F:OutputUnit(1, {lib})*/
class F {}

/*class: G:OutputUnit(1, {lib})*/
/*member: G.:OutputUnit(1, {lib})*/
class G extends C3 with C1, E, F {}

/*class: D1:OutputUnit(1, {lib})*/
class D1 {}

/*class: D2:OutputUnit(1, {lib})*/
class D2 {
  /*member: D2.:OutputUnit(1, {lib})*/
  D2(x) {
    d();
  }
}

// Implicit redirecting "super" call with a parameter via mixin.
/*class: D3:OutputUnit(1, {lib})*/
class D3 = D2 with D1;
