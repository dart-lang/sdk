// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/*member: main:[null|powerset=1]*/
main() {
  emptyList();
  nullList();
  constList();
  constNullList();
  intList();
  newFilledList();
  newFilledGrowableList();
  newFloat32x4List();
  newInt32x4List();
  newFloat64x2List();
  newFloat32List();
  newFloat64List();
  newInt16List();
  newInt32List();
  newInt32List2();
  newInt8List();
  newUint16List();
  newUint32List();
  newUint8ClampedList();
  newUint8List();
}

/*member: emptyList:Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
emptyList() => [];

/*member: constList:Container([exact=JSUnmodifiableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
constList() => const [];

/*member: nullList:Container([exact=JSExtendableArray|powerset=0], element: [null|powerset=1], length: 1, powerset: 0)*/
nullList() => [null];

/*member: constNullList:Container([exact=JSUnmodifiableArray|powerset=0], element: [null|powerset=1], length: 1, powerset: 0)*/
constNullList() => const [null];

/*member: intList:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 3, powerset: 0)*/
intList() => [1, 2, 3];

/*member: newFilledList:Container([exact=JSFixedArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "", powerset: 0), length: 3, powerset: 0)*/
newFilledList() => List.filled(3, '');

/*member: newFilledGrowableList:Container([exact=JSExtendableArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "", powerset: 0), length: 3, powerset: 0)*/
newFilledGrowableList() => List.filled(3, '', growable: true);

/*member: newFloat32x4List:[exact=NativeFloat32x4List|powerset=0]*/
newFloat32x4List() => Float32x4List(4);

/*member: newInt32x4List:[exact=NativeInt32x4List|powerset=0]*/
newInt32x4List() => Int32x4List(5);

/*member: newFloat64x2List:[exact=NativeFloat64x2List|powerset=0]*/
newFloat64x2List() => Float64x2List(6);

/*member: newFloat32List:Container([exact=NativeFloat32List|powerset=0], element: [subclass=JSNumber|powerset=0], length: 7, powerset: 0)*/
newFloat32List() => Float32List(7);

/*member: newFloat64List:Container([exact=NativeFloat64List|powerset=0], element: [subclass=JSNumber|powerset=0], length: 8, powerset: 0)*/
newFloat64List() => Float64List(8);

/*member: newInt16List:Container([exact=NativeInt16List|powerset=0], element: [subclass=JSInt|powerset=0], length: 9, powerset: 0)*/
newInt16List() => Int16List(9);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using an unchanged non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[exact=JSUInt31|powerset=0]*/
var _field1 = 10;

/*member: newInt32List:Container([exact=NativeInt32List|powerset=0], element: [subclass=JSInt|powerset=0], length: 10, powerset: 0)*/
newInt32List() => Int32List(_field1);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using a changed non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1b:[subclass=JSPositiveInt|powerset=0]*/
var _field1b = 10;

/*member: newInt32List2:Container([exact=NativeInt32List|powerset=0], element: [subclass=JSInt|powerset=0], length: null, powerset: 0)*/
newInt32List2() {
  _field1b /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++;
  return Int32List(_field1b);
}

////////////////////////////////////////////////////////////////////////////////
// Create a Int8List using a final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field2:[exact=JSUInt31|powerset=0]*/
final _field2 = 11;

/*member: newInt8List:Container([exact=NativeInt8List|powerset=0], element: [subclass=JSInt|powerset=0], length: 11, powerset: 0)*/
newInt8List() => Int8List(_field2);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint16List using a const top-level field as length.
////////////////////////////////////////////////////////////////////////////////

const _field3 = 12;

/*member: newUint16List:Container([exact=NativeUint16List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 12, powerset: 0)*/
newUint16List() => Uint16List(_field3);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint32List using a parenthesized literal int as length.
////////////////////////////////////////////////////////////////////////////////

/*member: newUint32List:Container([exact=NativeUint32List|powerset=0], element: [subclass=JSUInt32|powerset=0], length: 13, powerset: 0)*/
newUint32List() => Uint32List((13));

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8ClampedList using a constant multiplication as length.
////////////////////////////////////////////////////////////////////////////////

/*member: newUint8ClampedList:Container([exact=NativeUint8ClampedList|powerset=0], element: [exact=JSUInt31|powerset=0], length: 14, powerset: 0)*/
newUint8ClampedList() => Uint8ClampedList(2 * 7);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8List using a const static field as length.
////////////////////////////////////////////////////////////////////////////////

abstract class Class1 {
  static const field = 15;
}

/*member: newUint8List:Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 15, powerset: 0)*/
newUint8List() => Uint8List(Class1.field);
