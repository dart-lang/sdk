// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
  test12();
  test13();
  test14();
  test15();
  test16();
  test17();
  test18();
  test19();
}

/*member: A1.:[exact=A1|powerset=0]*/
class A1 {
  /*member: A1.x1:Value([exact=JSString|powerset=0], value: "s", powerset: 0)*/
  x1(/*Value([exact=JSString|powerset=0], value: "s", powerset: 0)*/ p) => p;
}

/*member: test1:[null|powerset=1]*/
test1() {
  A1(). /*invoke: [exact=A1|powerset=0]*/ x1("s");
}

/*member: A2.:[exact=A2|powerset=0]*/
class A2 {
  /*member: A2.x2:[exact=JSUInt31|powerset=0]*/
  x2(/*[exact=JSUInt31|powerset=0]*/ p) => p;
}

/*member: test2:[null|powerset=1]*/
test2() {
  A2(). /*invoke: [exact=A2|powerset=0]*/ x2(1);
}

/*member: A3.:[exact=A3|powerset=0]*/
class A3 {
  /*member: A3.x3:[empty|powerset=0]*/
  x3(/*[subclass=JSInt|powerset=0]*/ p) => /*invoke: [exact=A3|powerset=0]*/
      x3(p /*invoke: [subclass=JSInt|powerset=0]*/ - 1);
}

/*member: test3:[null|powerset=1]*/
test3() {
  A3(). /*invoke: [exact=A3|powerset=0]*/ x3(1);
}

/*member: A4.:[exact=A4|powerset=0]*/
class A4 {
  /*member: A4.x4:[empty|powerset=0]*/
  x4(/*[subclass=JSNumber|powerset=0]*/ p) => /*invoke: [exact=A4|powerset=0]*/
      x4(p /*invoke: [subclass=JSNumber|powerset=0]*/ - 1);
}

/*member: test4:[null|powerset=1]*/
test4() {
  A4(). /*invoke: [exact=A4|powerset=0]*/ x4(1.5);
}

/*member: A5.:[exact=A5|powerset=0]*/
class A5 {
  /*member: A5.x5:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  x5(
    /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p,
  ) => p;
}

/*member: test5:[null|powerset=1]*/
test5() {
  A5(). /*invoke: [exact=A5|powerset=0]*/ x5(1);
  A5(). /*invoke: [exact=A5|powerset=0]*/ x5(1.5);
}

/*member: A6.:[exact=A6|powerset=0]*/
class A6 {
  /*member: A6.x6:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  x6(
    /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p,
  ) => p;
}

/*member: test6:[null|powerset=1]*/
test6() {
  A6(). /*invoke: [exact=A6|powerset=0]*/ x6(1.5);
  A6(). /*invoke: [exact=A6|powerset=0]*/ x6(1);
}

/*member: A7.:[exact=A7|powerset=0]*/
class A7 {
  /*member: A7.x7:[empty|powerset=0]*/
  x7(
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p,
  ) => /*invoke: [exact=A7|powerset=0]*/ x7("x");
}

/*member: test7:[null|powerset=1]*/
test7() {
  A7(). /*invoke: [exact=A7|powerset=0]*/ x7(1);
}

/*member: A8.:[exact=A8|powerset=0]*/
class A8 {
  /*member: A8.x8:[empty|powerset=0]*/
  x8(
    /*Union([exact=JSString|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/ p,
  ) =>
  /*invoke: [exact=A8|powerset=0]*/ x8("x");
}

/*member: test8:[null|powerset=1]*/
test8() {
  A8(). /*invoke: [exact=A8|powerset=0]*/ x8({});
}

/*member: A9.:[exact=A9|powerset=0]*/
class A9 {
  /*member: A9.x9:[empty|powerset=0]*/
  x9(
    /*[exact=JSUInt31|powerset=0]*/ p1,
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p2,
    /*Union([exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/ p3,
  ) =>
  /*invoke: [exact=A9|powerset=0]*/ x9(p1, "x", {});
}

/*member: test9:[null|powerset=1]*/
test9() {
  A9(). /*invoke: [exact=A9|powerset=0]*/ x9(1, 2, 3);
}

/*member: A10.:[exact=A10|powerset=0]*/
class A10 {
  /*member: A10.x10:[empty|powerset=0]*/
  x10(
    /*[exact=JSUInt31|powerset=0]*/ p1,
    /*[exact=JSUInt31|powerset=0]*/ p2,
  ) => /*invoke: [exact=A10|powerset=0]*/ x10(p1, p2);
}

/*member: test10:[null|powerset=1]*/
test10() {
  A10(). /*invoke: [exact=A10|powerset=0]*/ x10(1, 2);
}

/*member: A11.:[exact=A11|powerset=0]*/
class A11 {
  /*member: A11.x11:[empty|powerset=0]*/
  x11(
    /*[exact=JSUInt31|powerset=0]*/ p1,
    /*[exact=JSUInt31|powerset=0]*/ p2,
  ) => /*invoke: [exact=A11|powerset=0]*/ x11(p1, p2);
}

/*member: f11:[null|powerset=1]*/
void f11(/*[null|powerset=1]*/ p) {
  p. /*invoke: [null|powerset=1]*/ x11("x", "y");
}

/*member: test11:[null|powerset=1]*/
test11() {
  f11(null);
  A11(). /*invoke: [exact=A11|powerset=0]*/ x11(1, 2);
}

/*member: A12.:[exact=A12|powerset=0]*/
class A12 {
  /*member: A12.x12:[empty|powerset=0]*/
  x12(
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p1,
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p2,
  ) =>
  /*invoke: [exact=A12|powerset=0]*/ x12(1, 2);
}

/*member: test12:[null|powerset=1]*/
test12() {
  A12(). /*invoke: [exact=A12|powerset=0]*/ x12("x", "y");
}

/*member: A13.:[exact=A13|powerset=0]*/
class A13 {
  /*member: A13.x13:[exact=JSUInt31|powerset=0]*/
  x13(
    /*Value([exact=JSString|powerset=0], value: "x", powerset: 0)*/ p1, [
    /*[exact=JSUInt31|powerset=0]*/ p2 = 1,
  ]) => 1;
}

/*member: test13:[null|powerset=1]*/
test13() {
  A13(). /*invoke: [exact=A13|powerset=0]*/ x13("x", 1);
  A13(). /*invoke: [exact=A13|powerset=0]*/ x13("x");
}

/*member: A14.:[exact=A14|powerset=0]*/
class A14 {
  /*member: A14.x14:[exact=JSUInt31|powerset=0]*/
  x14(
    /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p,
  ) => 1;
}

/*member: f14:[exact=JSUInt31|powerset=0]*/
f14(/*[exact=A14|powerset=0]*/ p) =>
    p. /*invoke: [exact=A14|powerset=0]*/ x14(2.2);

/*member: test14:[null|powerset=1]*/
test14() {
  A14(). /*invoke: [exact=A14|powerset=0]*/ x14(1);
  f14(new A14());
}

/*member: A15.:[exact=A15|powerset=0]*/
class A15 {
  /*member: A15.x15:[exact=JSUInt31|powerset=0]*/
  x15(
    /*[exact=JSUInt31|powerset=0]*/ p1, [
    /*Value([exact=JSString|powerset=0], value: "s", powerset: 0)*/ p2 = "s",
  ]) {
    p2. /*Value([exact=JSString|powerset=0], value: "s", powerset: 0)*/ length;
    return 1;
  }
}

/*member: test15:[null|powerset=1]*/
test15() {
  A15(). /*invoke: [exact=A15|powerset=0]*/ x15(1);
}

/*member: A16.:[exact=A16|powerset=0]*/
class A16 {
  /*member: A16.x16:[exact=JSUInt31|powerset=0]*/
  x16(
    /*Value([exact=JSString|powerset=0], value: "x", powerset: 0)*/ p1, [
    /*[exact=JSBool|powerset=0]*/ p2 = true,
  ]) => 1;
}

/*member: f16:[empty|powerset=0]*/
f16(/*[null|powerset=1]*/ p) => p. /*invoke: [null|powerset=1]*/ a("x");

/*member: test16:[null|powerset=1]*/
test16() {
  A16(). /*invoke: [exact=A16|powerset=0]*/ x16("x");
  A16(). /*invoke: [exact=A16|powerset=0]*/ x16("x", false);
  f16(null);
}

/*member: A17.:[exact=A17|powerset=0]*/
class A17 {
  /*member: A17.x17:[exact=JSUInt31|powerset=0]*/
  x17(
    /*[exact=JSUInt31|powerset=0]*/ p1, [
    /*[exact=JSUInt31|powerset=0]*/ p2 = 1,
    /*[exact=JSString|powerset=0]*/ p3 = "s",
  ]) => 1;
}

/*member: test17:[null|powerset=1]*/
test17() {
  A17(). /*invoke: [exact=A17|powerset=0]*/ x17(1);
  A17(). /*invoke: [exact=A17|powerset=0]*/ x17(1, 2);
  A17(). /*invoke: [exact=A17|powerset=0]*/ x17(1, 2, "x");
  dynamic a = A17();
  a. /*invoke: [exact=A17|powerset=0]*/ x17(1, p2: 2);
  dynamic b = A17();
  b. /*invoke: [exact=A17|powerset=0]*/ x17(1, p3: "x");
  dynamic c = A17();
  c. /*invoke: [exact=A17|powerset=0]*/ x17(1, p3: "x", p2: 2);
  dynamic d = A17();
  d. /*invoke: [exact=A17|powerset=0]*/ x17(1, p2: 2, p3: "x");
}

/*member: A18.:[exact=A18|powerset=0]*/
class A18 {
  /*member: A18.x18:[exact=JSUInt31|powerset=0]*/
  x18(
    /*[exact=JSUInt31|powerset=0]*/ p1, [
    /*[exact=JSBool|powerset=0]*/ p2 = 1,
    /*[exact=JSNumNotInt|powerset=0]*/ p3 = "s",
  ]) => 1;
}

/*member: test18:[null|powerset=1]*/
test18() {
  A18(). /*invoke: [exact=A18|powerset=0]*/ x18(1, true, 1.1);
  A18(). /*invoke: [exact=A18|powerset=0]*/ x18(1, false, 2.2);
  dynamic a = A18();
  a. /*invoke: [exact=A18|powerset=0]*/ x18(1, p3: 3.3, p2: true);
  dynamic b = A18();
  b. /*invoke: [exact=A18|powerset=0]*/ x18(1, p2: false, p3: 4.4);
}

/*member: A19.:[exact=A19|powerset=0]*/
class A19 {
  /*member: A19.x19:[empty|powerset=0]*/
  x19(
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p1,
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ p2,
  ) =>
  /*invoke: [subclass=A19|powerset=0]*/ x19(p1, p2);
}

/*member: B19.:[exact=B19|powerset=0]*/
class B19 extends A19 {}

/*member: test19:[null|powerset=1]*/
test19() {
  B19(). /*invoke: [exact=B19|powerset=0]*/ x19("a", "b");
  A19(). /*invoke: [exact=A19|powerset=0]*/ x19(1, 2);
}
