// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A1.:[exact=A1|powerset=0]*/
class A1 {
  /*member: A1.foo:[null|powerset=1]*/
  void foo(/*[exact=JSUInt31|powerset=0]*/ x) => print(x);
}

/*member: B1.:[exact=B1|powerset=0]*/
class B1 extends A1 with M1 {}

/*member: C1.:[exact=C1|powerset=0]*/
class C1 with M1 {
  /*member: C1.foo:[null|powerset=1]*/
  void foo(/*[exact=JSUInt31|powerset=0]*/ x) => print(x);
}

mixin M1 {
  void foo(x);
  /*member: M1.bar:[null|powerset=1]*/
  void bar(/*[exact=JSUInt31|powerset=0]*/ y) {
    /*invoke: [subtype=M1|powerset=0]*/
    foo(y);
  }
}

/*member: A2.:[exact=A2|powerset=0]*/
class A2 {
  /*member: A2.foo:[null|powerset=1]*/
  void foo(/*[empty|powerset=0]*/ x) => print(x);
}

/*member: B2.:[exact=B2|powerset=0]*/
class B2 extends A2 with M2 {}

/*member: C2.:[exact=C2|powerset=0]*/
class C2 with M2 {
  /*member: C2.foo:[null|powerset=1]*/
  void foo(/*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ x) =>
      print(x);
}

mixin M2 {
  /*member: M2.foo:[exact=JSUInt31|powerset=0]*/
  void foo(/*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ x) =>
      5;
  /*member: M2.bar:[null|powerset=1]*/
  void bar(/*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ y) {
    /*invoke: [subtype=M2|powerset=0]*/
    foo(y);
  }
}

/*member: getB1:Union([exact=B1|powerset=0], [exact=C1|powerset=0], powerset: 0)*/
getB1(bool /*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ x) =>
    x ? B1() : C1();
/*member: getB2:Union([exact=B2|powerset=0], [exact=C2|powerset=0], powerset: 0)*/
getB2(bool /*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ x) =>
    x ? B2() : C2();

/*member: main:[null|powerset=1]*/
main() {
  getB1(
    false,
  ). /*invoke: Union([exact=B1|powerset=0], [exact=C1|powerset=0], powerset: 0)*/ bar(
    3,
  );
  getB2(
    false,
  ). /*invoke: Union([exact=B2|powerset=0], [exact=C2|powerset=0], powerset: 0)*/ bar(
    "",
  );
}
