// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*member: listIndexPostfixIncrement:[subclass=JSPositiveInt]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
          /*Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
          /*update: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
          [0]
      /*invoke: [subclass=JSPositiveInt]*/ ++;
}

/*member: listIndexPostfixDecrement:[subclass=JSInt]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
          /*Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          /*update: Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          [0]
      /*invoke: [subclass=JSInt]*/ --;
}

/*member: Super1.:[exact=Super1]*/
class Super1 {
  /*member: Super1.[]:[exact=JSUInt31]*/
  operator [](/*[exact=JSUInt31]*/ index) => 42;

  /*member: Super1.[]=:[null]*/
  operator []=(/*[exact=JSUInt31]*/ index, /*[subclass=JSUInt32]*/ value) {}
}

/*member: Class1.:[exact=Class1]*/
class Class1 extends Super1 {
  /*member: Class1.method:[exact=JSUInt31]*/
  method() => super[0] /*invoke: [exact=JSUInt31]*/ ++;
}

/*member: superIndexPostfixIncrement:[null]*/
superIndexPostfixIncrement() {
  new Class1(). /*invoke: [exact=Class1]*/ method();
}
