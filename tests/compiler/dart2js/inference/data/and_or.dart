// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: X.:[exact=X]*/
class X {}

/*member: returnDyn1:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn1() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31]*/ == true) ||
      ((a = 'foo') /*invoke: Value([exact=JSString], value: "foo")*/ == true);
  return a;
}

/*member: returnDyn2:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn2() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31]*/ == true) &&
      ((a = 'foo') /*invoke: Value([exact=JSString], value: "foo")*/ == true);
  return a;
}

/*member: returnDyn3:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn3() {
  var a;
  a = a == 54 ? 'foo' : 31;
  return a;
}

/*member: returnDyn4:Union([exact=JSUInt31], [exact=X])*/
returnDyn4() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31]*/ == true) ||
      ((a = new X()) /*invoke: [exact=X]*/ == true);
  return a;
}

/*member: returnDyn5:Union([exact=JSUInt31], [exact=X])*/
returnDyn5() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31]*/ == true) &&
      ((a = new X()) /*invoke: [exact=X]*/ == true);
  return a;
}

/*member: returnDyn6:Union([exact=JSString], [exact=X])*/
returnDyn6() {
  var a;
  a = a == 54 ? 'foo' : new X();
  return a;
}

/*member: returnDyn7b:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn7b(
    /*Union([exact=JSString], [exact=JSUInt31])*/ x) {
  return x;
}

/*member: returnDyn7:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn7() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString], value: "foo")*/ length
      /*invoke: [subclass=JSInt]*/ ==
      3) {
    a = 52;
  }
  if ((a is int) || (a is String && true)) returnDyn7b(a);
  return a;
}

/*member: returnDyn8:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn8(
    /*Union([exact=JSString], [exact=JSUInt31])*/ x) {
  return x;
}

/*member: test8:Union(null, [exact=JSString], [exact=JSUInt31])*/ test8() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString], value: "foo")*/ length
      /*invoke: [subclass=JSInt]*/ ==
      3) {
    a = 52;
  }
  // ignore: dead_code
  if ((false && a is! String) || returnDyn8(a)) return a;
}

/*member: returnDyn9:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn9(
    /*Union([exact=JSString], [exact=JSUInt31])*/ x) {
  return x;
}

/*member: test9:[null]*/
test9() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString], value: "foo")*/ length
      /*invoke: [subclass=JSInt]*/ ==
      3) {
    a = 52;
  }
  if (!(a is bool && a is bool)) returnDyn9(a);
}

/*member: returnString:[exact=JSString]*/ returnString(
        /*[exact=JSString]*/ x) =>
    x;

/*member: test10:[null]*/
test10() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString], value: "foo")*/ length
      /*invoke: [subclass=JSInt]*/ ==
      3) {
    a = 52;
  }
  if (!(a is num) && a is String) returnString(a);
}

/*member: main:[null]*/
main() {
  returnDyn1();
  returnDyn2();
  returnDyn3();
  returnDyn4();
  returnDyn5();
  returnDyn6();
  returnDyn7();
  test8();
  test9();
  test10();
}
