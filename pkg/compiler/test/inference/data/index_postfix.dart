// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*member: listIndexPostfixIncrement:[subclass=JSPositiveInt|powerset=0]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
  /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++;
}

/*member: listIndexPostfixDecrement:[subclass=JSInt|powerset=0]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: 1, powerset: 0)*/
  /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: 1, powerset: 0)*/
  [0] /*invoke: [subclass=JSInt|powerset=0]*/ --;
}

/*member: Super1.:[exact=Super1|powerset=0]*/
class Super1 {
  /*member: Super1.[]:[exact=JSUInt31|powerset=0]*/
  operator [](/*[exact=JSUInt31|powerset=0]*/ index) => 42;

  /*member: Super1.[]=:[null|powerset=1]*/
  operator []=(
    /*[exact=JSUInt31|powerset=0]*/ index,
    /*[subclass=JSUInt32|powerset=0]*/ value,
  ) {}
}

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 extends Super1 {
  /*member: Class1.method:[exact=JSUInt31|powerset=0]*/
  method() => super[0] /*invoke: [exact=JSUInt31|powerset=0]*/ ++;
}

/*member: superIndexPostfixIncrement:[null|powerset=1]*/
superIndexPostfixIncrement() {
  Class1(). /*invoke: [exact=Class1|powerset=0]*/ method();
}
