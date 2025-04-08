// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: X.:[exact=X|powerset=0]*/
class X {}

/*member: returnDyn1:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn1() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset=0]*/ == true) ||
      ((a = 'foo') /*invoke: Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ ==
          true);
  return a;
}

/*member: returnDyn2:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn2() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset=0]*/ == true) &&
      ((a = 'foo') /*invoke: Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ ==
          true);
  return a;
}

/*member: returnDyn3:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn3() {
  var a;
  a = a == 54 ? 'foo' : 31;
  return a;
}

/*member: returnDyn4:Union([exact=JSUInt31|powerset=0], [exact=X|powerset=0], powerset: 0)*/
returnDyn4() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset=0]*/ == true) ||
      ((a = X()) /*invoke: [exact=X|powerset=0]*/ == true);
  return a;
}

/*member: returnDyn5:Union([exact=JSUInt31|powerset=0], [exact=X|powerset=0], powerset: 0)*/
returnDyn5() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset=0]*/ == true) &&
      ((a = X()) /*invoke: [exact=X|powerset=0]*/ == true);
  return a;
}

/*member: returnDyn6:Union([exact=JSString|powerset=0], [exact=X|powerset=0], powerset: 0)*/
returnDyn6() {
  var a;
  a = a == 54 ? 'foo' : X();
  return a;
}

/*member: returnDyn7b:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn7b(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ x,
) {
  return x;
}

/*member: returnDyn7:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn7() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ length /*invoke: [subclass=JSInt|powerset=0]*/ ==
      3) {
    a = 52;
  }
  if ((a is int) || (a is String && true)) returnDyn7b(a);
  return a;
}

/*member: returnDyn8:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn8(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ x,
) {
  return x;
}

/*member: test8:Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
test8() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ length /*invoke: [subclass=JSInt|powerset=0]*/ ==
      3) {
    a = 52;
  }
  // ignore: dead_code
  if ((false && a is! String) || returnDyn8(a)) return a;
}

/*member: returnDyn9:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn9(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ x,
) {
  return x;
}

/*member: test9:[null|powerset=1]*/
test9() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ length /*invoke: [subclass=JSInt|powerset=0]*/ ==
      3) {
    a = 52;
  }
  if (!(a is bool && a is bool)) returnDyn9(a);
}

/*member: returnString:[exact=JSString|powerset=0]*/
returnString(/*[exact=JSString|powerset=0]*/ x) => x;

/*member: test10:[null|powerset=1]*/
test10() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ length /*invoke: [subclass=JSInt|powerset=0]*/ ==
      3) {
    a = 52;
  }
  if (!(a is num) && a is String) returnString(a);
}

/*member: main:[null|powerset=1]*/
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
