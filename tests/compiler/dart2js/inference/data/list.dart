// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/*element: main:[null]*/
main() {
  emptyList();
  nullList();
  constList();
  constNullList();
  intList();
  newList();
  newFixedList();
  newFilledList();
  newFloat32x4List();
  newInt32x4List();
  newFloat64x2List();
  newFloat32List();
  newFloat64List();
  newInt16List();
  newInt32List();
  newInt8List();
  newUint16List();
  newUint32List();
  newUint8ClampedList();
  newUint8List();
}

/*element: emptyList:Container mask: [empty] length: 0 type: [exact=JSExtendableArray]*/
emptyList() => [];

/*element: constList:Container mask: [empty] length: 0 type: [exact=JSUnmodifiableArray]*/
constList() => const [];

/*element: nullList:Container mask: [null] length: 1 type: [exact=JSExtendableArray]*/
nullList() => [null];

/*element: constNullList:Container mask: [null] length: 1 type: [exact=JSUnmodifiableArray]*/
constNullList() => const [null];

/*element: intList:Container mask: [exact=JSUInt31] length: 3 type: [exact=JSExtendableArray]*/
intList() => [1, 2, 3];

/*element: newList:Container mask: [empty] length: 0 type: [exact=JSExtendableArray]*/
newList() => new List();

/*element: newFixedList:Container mask: [null] length: 2 type: [exact=JSFixedArray]*/
newFixedList() => new List(2);

/*element: newFilledList:Container mask: Value mask: [""] type: [exact=JSString] length: 3 type: [exact=JSFixedArray]*/
newFilledList() => new List.filled(3, '');

/*element: newFloat32x4List:[exact=NativeFloat32x4List]*/
newFloat32x4List() => new Float32x4List(4);

/*element: newInt32x4List:[exact=NativeInt32x4List]*/
newInt32x4List() => new Int32x4List(5);

/*element: newFloat64x2List:[exact=NativeFloat64x2List]*/
newFloat64x2List() => new Float64x2List(6);

/*element: newFloat32List:Container mask: [subclass=JSNumber] length: 7 type: [exact=NativeFloat32List]*/
newFloat32List() => new Float32List(7);

/*element: newFloat64List:Container mask: [subclass=JSNumber] length: 8 type: [exact=NativeFloat64List]*/
newFloat64List() => new Float64List(8);

/*element: newInt16List:Container mask: [subclass=JSInt] length: 9 type: [exact=NativeInt16List]*/
newInt16List() => new Int16List(9);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using an unchanged non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[exact=JSUInt31]*/
var _field1 = 10;

/*element: newInt32List:Container mask: [subclass=JSInt] length: null type: [exact=NativeInt32List]*/
newInt32List() => new Int32List(_field1);

////////////////////////////////////////////////////////////////////////////////
// Create a Int8List using a final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field2:[exact=JSUInt31]*/
final _field2 = 11;

/*element: newInt8List:Container mask: [subclass=JSInt] length: 11 type: [exact=NativeInt8List]*/
newInt8List() => new Int8List(_field2);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint16List using a const top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field3:[exact=JSUInt31]*/
const _field3 = 12;

/*element: newUint16List:Container mask: [exact=JSUInt31] length: 12 type: [exact=NativeUint16List]*/
newUint16List() => new Uint16List(_field3);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint32List using a parenthesized literal int as length.
////////////////////////////////////////////////////////////////////////////////

/*ast.element: newUint32List:Container mask: [subclass=JSUInt32] length: null type: [exact=NativeUint32List]*/
/*kernel.element: newUint32List:Container mask: [subclass=JSUInt32] length: 13 type: [exact=NativeUint32List]*/
newUint32List() => new Uint32List((13));

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8ClampedList using a constant multiplication as length.
////////////////////////////////////////////////////////////////////////////////

/*element: newUint8ClampedList:Container mask: [exact=JSUInt31] length: null type: [exact=NativeUint8ClampedList]*/
newUint8ClampedList() =>
    new Uint8ClampedList(2 /*invoke: [exact=JSUInt31]*/ * 7);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8List using a const static field as length.
////////////////////////////////////////////////////////////////////////////////

abstract class Class1 {
  /*element: Class1.field:[exact=JSUInt31]*/
  static const field = 15;
}

/*element: newUint8List:Container mask: [exact=JSUInt31] length: 15 type: [exact=NativeUint8List]*/
newUint8List() => new Uint8List(Class1.field);
