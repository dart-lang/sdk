// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*member: listIndexPostfixIncrement:[subclass=JSPositiveInt|powerset={I}{O}]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ ++;
}

/*member: listIndexPostfixDecrement:[subclass=JSInt|powerset={I}{O}]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  [0] /*invoke: [subclass=JSInt|powerset={I}{O}]*/ --;
}

/*member: Super1.:[empty|powerset=empty]*/
class Super1 {
  /*member: Super1.[]:[exact=JSUInt31|powerset={I}{O}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}]*/ index) => 42;

  /*member: Super1.[]=:[null|powerset={null}]*/
  operator []=(
    /*[exact=JSUInt31|powerset={I}{O}]*/ index,
    /*[subclass=JSUInt32|powerset={I}{O}]*/ value,
  ) {}
}

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 extends Super1 {
  /*member: Class1.method:[exact=JSUInt31|powerset={I}{O}]*/
  method() => super[0] /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ ++;
}

/*member: superIndexPostfixIncrement:[null|powerset={null}]*/
superIndexPostfixIncrement() {
  Class1(). /*invoke: [exact=Class1|powerset={N}{O}]*/ method();
}
