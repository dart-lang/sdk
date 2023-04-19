// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A1.:[exact=A1]*/
class A1 {
  /*member: A1.foo:[null]*/
  void foo(/*[exact=JSUInt31]*/ x) => print(x);
}

/*member: B1.:[exact=B1]*/
class B1 extends A1 with M1 {}

/*member: C1.:[exact=C1]*/
class C1 with M1 {
  /*member: C1.foo:[null]*/
  void foo(/*[exact=JSUInt31]*/ x) => print(x);
}

mixin M1 {
  void foo(x);
  /*member: M1.bar:[null]*/
  void bar(/*[exact=JSUInt31]*/ y) {
    /*invoke: [subtype=M1]*/ foo(y);
  }
}

/*member: A2.:[exact=A2]*/
class A2 {
  /*member: A2.foo:[null]*/
  void foo(/*[empty]*/ x) => print(x);
}

/*member: B2.:[exact=B2]*/
class B2 extends A2 with M2 {}

/*member: C2.:[exact=C2]*/
class C2 with M2 {
  /*member: C2.foo:[null]*/
  void foo(/*Value([exact=JSString], value: "")*/ x) => print(x);
}

mixin M2 {
  /*member: M2.foo:[exact=JSUInt31]*/
  void foo(/*Value([exact=JSString], value: "")*/ x) => 5;
  /*member: M2.bar:[null]*/
  void bar(/*Value([exact=JSString], value: "")*/ y) {
    /*invoke: [subtype=M2]*/ foo(y);
  }
}

/*member: getB1:Union([exact=B1], [exact=C1])*/
getB1(bool /*Value([exact=JSBool], value: false)*/ x) => x ? B1() : C1();
/*member: getB2:Union([exact=B2], [exact=C2])*/
getB2(bool /*Value([exact=JSBool], value: false)*/ x) => x ? B2() : C2();

/*member: main:[null]*/
main() {
  getB1(false). /*invoke: Union([exact=B1], [exact=C1])*/ bar(3);
  getB2(false). /*invoke: Union([exact=B2], [exact=C2])*/ bar("");
}
