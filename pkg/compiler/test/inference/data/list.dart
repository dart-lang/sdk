// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/*member: main:[null|powerset={null}]*/
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

/*member: emptyList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})*/
emptyList() => [];

/*member: constList:Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [empty|powerset=empty], length: 0, powerset: {I}{U}{I})*/
constList() => const [];

/*member: nullList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|powerset={null}], length: 1, powerset: {I}{G}{M})*/
nullList() => [null];

/*member: constNullList:Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [null|powerset={null}], length: 1, powerset: {I}{U}{I})*/
constNullList() => const [null];

/*member: intList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 3, powerset: {I}{G}{M})*/
intList() => [1, 2, 3];

/*member: newFilledList:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I}), length: 3, powerset: {I}{F}{M})*/
newFilledList() => List.filled(3, '');

/*member: newFilledGrowableList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I}), length: 3, powerset: {I}{G}{M})*/
newFilledGrowableList() => List.filled(3, '', growable: true);

/*member: newFloat32x4List:[exact=NativeFloat32x4List|powerset={N}{O}{N}]*/
newFloat32x4List() => Float32x4List(4);

/*member: newInt32x4List:[exact=NativeInt32x4List|powerset={N}{O}{N}]*/
newInt32x4List() => Int32x4List(5);

/*member: newFloat64x2List:[exact=NativeFloat64x2List|powerset={N}{O}{N}]*/
newFloat64x2List() => Float64x2List(6);

/*member: newFloat32List:Container([exact=NativeFloat32List|powerset={I}{O}{M}], element: [subclass=JSNumber|powerset={I}{O}{N}], length: 7, powerset: {I}{O}{M})*/
newFloat32List() => Float32List(7);

/*member: newFloat64List:Container([exact=NativeFloat64List|powerset={I}{O}{M}], element: [subclass=JSNumber|powerset={I}{O}{N}], length: 8, powerset: {I}{O}{M})*/
newFloat64List() => Float64List(8);

/*member: newInt16List:Container([exact=NativeInt16List|powerset={I}{O}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: 9, powerset: {I}{O}{M})*/
newInt16List() => Int16List(9);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using an unchanged non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[exact=JSUInt31|powerset={I}{O}{N}]*/
var _field1 = 10;

/*member: newInt32List:Container([exact=NativeInt32List|powerset={I}{O}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: 10, powerset: {I}{O}{M})*/
newInt32List() => Int32List(_field1);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using a changed non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1b:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
var _field1b = 10;

/*member: newInt32List2:Container([exact=NativeInt32List|powerset={I}{O}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: null, powerset: {I}{O}{M})*/
newInt32List2() {
  _field1b /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++;
  return Int32List(_field1b);
}

////////////////////////////////////////////////////////////////////////////////
// Create a Int8List using a final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*member: _field2:[exact=JSUInt31|powerset={I}{O}{N}]*/
final _field2 = 11;

/*member: newInt8List:Container([exact=NativeInt8List|powerset={I}{O}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: 11, powerset: {I}{O}{M})*/
newInt8List() => Int8List(_field2);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint16List using a const top-level field as length.
////////////////////////////////////////////////////////////////////////////////

const _field3 = 12;

/*member: newUint16List:Container([exact=NativeUint16List|powerset={I}{O}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 12, powerset: {I}{O}{M})*/
newUint16List() => Uint16List(_field3);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint32List using a parenthesized literal int as length.
////////////////////////////////////////////////////////////////////////////////

/*member: newUint32List:Container([exact=NativeUint32List|powerset={I}{O}{M}], element: [subclass=JSUInt32|powerset={I}{O}{N}], length: 13, powerset: {I}{O}{M})*/
newUint32List() => Uint32List((13));

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8ClampedList using a constant multiplication as length.
////////////////////////////////////////////////////////////////////////////////

/*member: newUint8ClampedList:Container([exact=NativeUint8ClampedList|powerset={I}{O}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 14, powerset: {I}{O}{M})*/
newUint8ClampedList() => Uint8ClampedList(2 * 7);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8List using a const static field as length.
////////////////////////////////////////////////////////////////////////////////

abstract class Class1 {
  static const field = 15;
}

/*member: newUint8List:Container([exact=NativeUint8List|powerset={I}{O}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 15, powerset: {I}{O}{M})*/
newUint8List() => Uint8List(Class1.field);
