// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*member: listIndexPostfixIncrement:[subclass=JSPositiveInt|powerset={I}]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ ++;
}

/*member: listIndexPostfixDecrement:[subclass=JSInt|powerset={I}]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: 1, powerset: {I})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: 1, powerset: {I})*/
  [0] /*invoke: [subclass=JSInt|powerset={I}]*/ --;
}

/*member: Super1.:[exact=Super1|powerset={N}]*/
class Super1 {
  /*member: Super1.[]:[exact=JSUInt31|powerset={I}]*/
  operator [](/*[exact=JSUInt31|powerset={I}]*/ index) => 42;

  /*member: Super1.[]=:[null|powerset={null}]*/
  operator []=(
    /*[exact=JSUInt31|powerset={I}]*/ index,
    /*[subclass=JSUInt32|powerset={I}]*/ value,
  ) {}
}

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 extends Super1 {
  /*member: Class1.method:[exact=JSUInt31|powerset={I}]*/
  method() => super[0] /*invoke: [exact=JSUInt31|powerset={I}]*/ ++;
}

/*member: superIndexPostfixIncrement:[null|powerset={null}]*/
superIndexPostfixIncrement() {
  Class1(). /*invoke: [exact=Class1|powerset={N}]*/ method();
}
