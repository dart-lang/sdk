// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: X.:[exact=X|powerset={N}{O}{N}]*/
class X {}

/*member: returnDyn1:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn1() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == true) ||
      ((a = 'foo') /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ ==
          true);
  return a;
}

/*member: returnDyn2:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn2() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == true) &&
      ((a = 'foo') /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ ==
          true);
  return a;
}

/*member: returnDyn3:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn3() {
  var a;
  a = a == 54 ? 'foo' : 31;
  return a;
}

/*member: returnDyn4:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=X|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
returnDyn4() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == true) ||
      ((a = X()) /*invoke: [exact=X|powerset={N}{O}{N}]*/ == true);
  return a;
}

/*member: returnDyn5:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=X|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
returnDyn5() {
  var a;
  ((a = 52) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == true) &&
      ((a = X()) /*invoke: [exact=X|powerset={N}{O}{N}]*/ == true);
  return a;
}

/*member: returnDyn6:Union([exact=JSString|powerset={I}{O}{I}], [exact=X|powerset={N}{O}{N}], powerset: {IN}{O}{IN})*/
returnDyn6() {
  var a;
  a = a == 54 ? 'foo' : X();
  return a;
}

/*member: returnDyn7b:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn7b(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ x,
) {
  return x;
}

/*member: returnDyn7:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn7() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ length /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ ==
      3) {
    a = 52;
  }
  if ((a is int) || (a is String && true)) returnDyn7b(a);
  return a;
}

/*member: returnDyn8:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn8(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ x,
) {
  return x;
}

/*member: test8:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
test8() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ length /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ ==
      3) {
    a = 52;
  }
  // ignore: dead_code
  if ((false && a is! String) || returnDyn8(a)) return a;
}

/*member: returnDyn9:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn9(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ x,
) {
  return x;
}

/*member: test9:[null|powerset={null}]*/
test9() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ length /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ ==
      3) {
    a = 52;
  }
  if (!(a is bool && a is bool)) returnDyn9(a);
}

/*member: returnString:[exact=JSString|powerset={I}{O}{I}]*/
returnString(/*[exact=JSString|powerset={I}{O}{I}]*/ x) => x;

/*member: test10:[null|powerset={null}]*/
test10() {
  dynamic a = "foo";
  if (a. /*Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/ length /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ ==
      3) {
    a = 52;
  }
  if (!(a is num) && a is String) returnString(a);
}

/*member: main:[null|powerset={null}]*/
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
