// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*member: listIndexPostfixIncrement:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSPositiveInt|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSPositiveInt|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++;
}

/*member: listIndexPostfixDecrement:[subclass=JSInt|powerset={I}{O}{N}]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  [0] /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ --;
}

/*member: Super1.:[empty|powerset=empty]*/
class Super1 {
  /*member: Super1.[]:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}{N}]*/ index) => 42;

  /*member: Super1.[]=:[null|powerset={null}]*/
  operator []=(
    /*[exact=JSUInt31|powerset={I}{O}{N}]*/ index,
    /*[subclass=JSUInt32|powerset={I}{O}{N}]*/ value,
  ) {}
}

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 extends Super1 {
  /*member: Class1.method:[exact=JSUInt31|powerset={I}{O}{N}]*/
  method() => super[0] /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++;
}

/*member: superIndexPostfixIncrement:[null|powerset={null}]*/
superIndexPostfixIncrement() {
  Class1(). /*invoke: [exact=Class1|powerset={N}{O}{N}]*/ method();
}
