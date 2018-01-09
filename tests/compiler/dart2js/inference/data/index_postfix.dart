// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  listIndexPostfixIncrement();
  listIndexPostfixDecrement();
  superIndexPostfixIncrement();
}

/*element: listIndexPostfixIncrement:[subclass=JSPositiveInt]*/
listIndexPostfixIncrement() {
  var list = [0];
  return list
          /*Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
          /*update: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
          [0]
      /*invoke: [subclass=JSPositiveInt]*/ ++;
}

/*element: listIndexPostfixDecrement:[subclass=JSInt]*/
listIndexPostfixDecrement() {
  var list = [0];
  return list
          /*Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          /*update: Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          [0]
      /*invoke: [subclass=JSInt]*/ --;
}

/*element: Super1.:[exact=Super1]*/
class Super1 {
  /*element: Super1.[]:[exact=JSUInt31]*/
  operator [](/*[exact=JSUInt31]*/ index) => 42;

  /*element: Super1.[]=:[null]*/
  operator []=(/*[exact=JSUInt31]*/ index, /*[subclass=JSUInt32]*/ value) {}
}

/*element: Class1.:[exact=Class1]*/
class Class1 extends Super1 {
  /*element: Class1.method:[exact=JSUInt31]*/
  method() => super[0] /*invoke: [exact=JSUInt31]*/ ++;
}

/*element: superIndexPostfixIncrement:[null]*/
superIndexPostfixIncrement() {
  new Class1(). /*invoke: [exact=Class1]*/ method();
}
