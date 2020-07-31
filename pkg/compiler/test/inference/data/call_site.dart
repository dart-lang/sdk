// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: A1.:[exact=A1]*/
class A1 {
  /*member: A1.x1:Value([exact=JSString], value: "s")*/
  x1(
          /*Value([exact=JSString], value: "s")*/ p) =>
      p;
}

/*member: test1:[null]*/
test1() {
  new A1(). /*invoke: [exact=A1]*/ x1("s");
}

/*member: A2.:[exact=A2]*/
class A2 {
  /*member: A2.x2:[exact=JSUInt31]*/
  x2(/*[exact=JSUInt31]*/ p) => p;
}

/*member: test2:[null]*/
test2() {
  new A2(). /*invoke: [exact=A2]*/ x2(1);
}

/*member: A3.:[exact=A3]*/
class A3 {
  /*member: A3.x3:[empty]*/
  x3(/*[subclass=JSInt]*/ p) => /*invoke: [exact=A3]*/ x3(
      p /*invoke: [subclass=JSInt]*/ - 1);
}

/*member: test3:[null]*/
test3() {
  new A3(). /*invoke: [exact=A3]*/ x3(1);
}

/*member: A4.:[exact=A4]*/
class A4 {
  /*member: A4.x4:[empty]*/
  x4(/*[subclass=JSNumber]*/ p) => /*invoke: [exact=A4]*/ x4(
      p /*invoke: [subclass=JSNumber]*/ - 1);
}

/*member: test4:[null]*/
test4() {
  new A4(). /*invoke: [exact=A4]*/ x4(1.5);
}

/*member: A5.:[exact=A5]*/
class A5 {
  /*member: A5.x5:Union([exact=JSDouble], [exact=JSUInt31])*/
  x5(
          /*Union([exact=JSDouble], [exact=JSUInt31])*/ p) =>
      p;
}

/*member: test5:[null]*/
test5() {
  new A5(). /*invoke: [exact=A5]*/ x5(1);
  new A5(). /*invoke: [exact=A5]*/ x5(1.5);
}

/*member: A6.:[exact=A6]*/
class A6 {
  /*member: A6.x6:Union([exact=JSDouble], [exact=JSUInt31])*/
  x6(
          /*Union([exact=JSDouble], [exact=JSUInt31])*/ p) =>
      p;
}

/*member: test6:[null]*/
test6() {
  new A6(). /*invoke: [exact=A6]*/ x6(1.5);
  new A6(). /*invoke: [exact=A6]*/ x6(1);
}

/*member: A7.:[exact=A7]*/
class A7 {
  /*member: A7.x7:[empty]*/
  x7(
      /*Union([exact=JSString], [exact=JSUInt31])*/ p) => /*invoke: [exact=A7]*/ x7("x");
}

/*member: test7:[null]*/
test7() {
  new A7(). /*invoke: [exact=A7]*/ x7(1);
}

/*member: A8.:[exact=A8]*/
class A8 {
  /*member: A8.x8:[empty]*/
  x8(
          /*Union([exact=JSString], [subclass=JsLinkedHashMap])*/ p) =>
      /*invoke: [exact=A8]*/ x8("x");
}

/*member: test8:[null]*/
test8() {
  new A8(). /*invoke: [exact=A8]*/ x8({});
}

/*member: A9.:[exact=A9]*/
class A9 {
  /*member: A9.x9:[empty]*/ x9(
          /*[exact=JSUInt31]*/ p1,
          /*Union([exact=JSString], [exact=JSUInt31])*/ p2,
          /*Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/ p3) =>
      /*invoke: [exact=A9]*/ x9(p1, "x", {});
}

/*member: test9:[null]*/
test9() {
  new A9(). /*invoke: [exact=A9]*/ x9(1, 2, 3);
}

/*member: A10.:[exact=A10]*/
class A10 {
  /*member: A10.x10:[empty]*/ x10(
      /*[exact=JSUInt31]*/ p1,
      /*[exact=JSUInt31]*/ p2) => /*invoke: [exact=A10]*/ x10(p1, p2);
}

/*member: test10:[null]*/
test10() {
  new A10(). /*invoke: [exact=A10]*/ x10(1, 2);
}

/*member: A11.:[exact=A11]*/
class A11 {
  /*member: A11.x11:[empty]*/
  x11(
      /*[exact=JSUInt31]*/ p1,
      /*[exact=JSUInt31]*/ p2) => /*invoke: [exact=A11]*/ x11(p1, p2);
}

/*member: f11:[null]*/
void f11(/*[null]*/ p) {
  p. /*invoke: [null]*/ x11("x", "y");
}

/*member: test11:[null]*/
test11() {
  f11(null);
  new A11(). /*invoke: [exact=A11]*/ x11(1, 2);
}

/*member: A12.:[exact=A12]*/
class A12 {
  /*member: A12.x12:[empty]*/
  x12(
          /*Union([exact=JSString], [exact=JSUInt31])*/ p1,
          /*Union([exact=JSString], [exact=JSUInt31])*/ p2) =>
      /*invoke: [exact=A12]*/ x12(1, 2);
}

/*member: test12:[null]*/
test12() {
  new A12(). /*invoke: [exact=A12]*/ x12("x", "y");
}

/*member: A13.:[exact=A13]*/
class A13 {
  /*member: A13.x13:[exact=JSUInt31]*/
  x13(
          /*Value([exact=JSString], value: "x")*/ p1,
          [/*[exact=JSUInt31]*/ p2 = 1]) =>
      1;
}

/*member: test13:[null]*/
test13() {
  new A13(). /*invoke: [exact=A13]*/ x13("x", 1);
  new A13(). /*invoke: [exact=A13]*/ x13("x");
}

/*member: A14.:[exact=A14]*/
class A14 {
  /*member: A14.x14:[exact=JSUInt31]*/
  x14(
          /*Union([exact=JSDouble], [exact=JSUInt31])*/ p) =>
      1;
}

/*member: f14:[exact=JSUInt31]*/
f14(/*[exact=A14]*/ p) => p. /*invoke: [exact=A14]*/ x14(2.2);

/*member: test14:[null]*/
test14() {
  new A14(). /*invoke: [exact=A14]*/ x14(1);
  f14(new A14());
}

/*member: A15.:[exact=A15]*/
class A15 {
  /*member: A15.x15:[exact=JSUInt31]*/
  x15(/*[exact=JSUInt31]*/ p1,
      [/*Value([exact=JSString], value: "s")*/ p2 = "s"]) {
    p2. /*Value([exact=JSString], value: "s")*/ length;
    return 1;
  }
}

/*member: test15:[null]*/
test15() {
  new A15(). /*invoke: [exact=A15]*/ x15(1);
}

/*member: A16.:[exact=A16]*/
class A16 {
  /*member: A16.x16:[exact=JSUInt31]*/
  x16(
          /*Value([exact=JSString], value: "x")*/ p1,
          [/*[exact=JSBool]*/ p2 = true]) =>
      1;
}

/*member: f16:[empty]*/
f16(/*[null]*/ p) => p. /*invoke: [null]*/ a("x");

/*member: test16:[null]*/
test16() {
  new A16(). /*invoke: [exact=A16]*/ x16("x");
  new A16(). /*invoke: [exact=A16]*/ x16("x", false);
  f16(null);
}

/*member: A17.:[exact=A17]*/
class A17 {
  /*member: A17.x17:[exact=JSUInt31]*/
  x17(/*[exact=JSUInt31]*/ p1,
          [/*[exact=JSUInt31]*/ p2 = 1, /*[exact=JSString]*/ p3 = "s"]) =>
      1;
}

/*member: test17:[null]*/
test17() {
  new A17(). /*invoke: [exact=A17]*/ x17(1);
  new A17(). /*invoke: [exact=A17]*/ x17(1, 2);
  new A17(). /*invoke: [exact=A17]*/ x17(1, 2, "x");
  dynamic a = new A17();
  a. /*invoke: [exact=A17]*/ x17(1, p2: 2);
  dynamic b = new A17();
  b. /*invoke: [exact=A17]*/ x17(1, p3: "x");
  dynamic c = new A17();
  c. /*invoke: [exact=A17]*/ x17(1, p3: "x", p2: 2);
  dynamic d = new A17();
  d. /*invoke: [exact=A17]*/ x17(1, p2: 2, p3: "x");
}

/*member: A18.:[exact=A18]*/
class A18 {
  /*member: A18.x18:[exact=JSUInt31]*/
  x18(/*[exact=JSUInt31]*/ p1,
          [/*[exact=JSBool]*/ p2 = 1, /*[exact=JSDouble]*/ p3 = "s"]) =>
      1;
}

/*member: test18:[null]*/
test18() {
  new A18(). /*invoke: [exact=A18]*/ x18(1, true, 1.1);
  new A18(). /*invoke: [exact=A18]*/ x18(1, false, 2.2);
  dynamic a = new A18();
  a. /*invoke: [exact=A18]*/ x18(1, p3: 3.3, p2: true);
  dynamic b = new A18();
  b. /*invoke: [exact=A18]*/ x18(1, p2: false, p3: 4.4);
}

/*member: A19.:[exact=A19]*/
class A19 {
  /*member: A19.x19:[empty]*/
  x19(
          /*Union([exact=JSString], [exact=JSUInt31])*/ p1,
          /*Union([exact=JSString], [exact=JSUInt31])*/ p2) =>
      /*invoke: [subclass=A19]*/ x19(p1, p2);
}

/*member: B19.:[exact=B19]*/
class B19 extends A19 {}

/*member: test19:[null]*/
test19() {
  new B19(). /*invoke: [exact=B19]*/ x19("a", "b");
  new A19(). /*invoke: [exact=A19]*/ x19(1, 2);
}
