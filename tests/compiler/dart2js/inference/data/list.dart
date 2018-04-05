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

/*element: emptyList:Container([exact=JSExtendableArray], element: [empty], length: 0)*/
emptyList() => [];

/*element: constList:Container([exact=JSUnmodifiableArray], element: [empty], length: 0)*/
constList() => const [];

/*element: nullList:Container([exact=JSExtendableArray], element: [null], length: 1)*/
nullList() => [null];

/*element: constNullList:Container([exact=JSUnmodifiableArray], element: [null], length: 1)*/
constNullList() => const [null];

/*element: intList:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
intList() => [1, 2, 3];

/*element: newList:Container([exact=JSExtendableArray], element: [empty], length: 0)*/
newList() => new List();

/*element: newFixedList:Container([exact=JSFixedArray], element: [null], length: 2)*/
newFixedList() => new List(2);

/*element: newFilledList:Container([exact=JSFixedArray], element: Value([exact=JSString], value: ""), length: 3)*/
newFilledList() => new List.filled(3, '');

/*element: newFloat32x4List:[exact=NativeFloat32x4List]*/
newFloat32x4List() => new Float32x4List(4);

/*element: newInt32x4List:[exact=NativeInt32x4List]*/
newInt32x4List() => new Int32x4List(5);

/*element: newFloat64x2List:[exact=NativeFloat64x2List]*/
newFloat64x2List() => new Float64x2List(6);

/*element: newFloat32List:Container([exact=NativeFloat32List], element: [subclass=JSNumber], length: 7)*/
newFloat32List() => new Float32List(7);

/*element: newFloat64List:Container([exact=NativeFloat64List], element: [subclass=JSNumber], length: 8)*/
newFloat64List() => new Float64List(8);

/*element: newInt16List:Container([exact=NativeInt16List], element: [subclass=JSInt], length: 9)*/
newInt16List() => new Int16List(9);

////////////////////////////////////////////////////////////////////////////////
// Create a Int32List using an unchanged non-final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[exact=JSUInt31]*/
var _field1 = 10;

/*element: newInt32List:Container([exact=NativeInt32List], element: [subclass=JSInt], length: null)*/
newInt32List() => new Int32List(_field1);

////////////////////////////////////////////////////////////////////////////////
// Create a Int8List using a final top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field2:[exact=JSUInt31]*/
final _field2 = 11;

/*element: newInt8List:Container([exact=NativeInt8List], element: [subclass=JSInt], length: 11)*/
newInt8List() => new Int8List(_field2);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint16List using a const top-level field as length.
////////////////////////////////////////////////////////////////////////////////

/*element: _field3:[exact=JSUInt31]*/
const _field3 = 12;

/*element: newUint16List:Container([exact=NativeUint16List], element: [exact=JSUInt31], length: 12)*/
newUint16List() => new Uint16List(_field3);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint32List using a parenthesized literal int as length.
////////////////////////////////////////////////////////////////////////////////

/*ast.element: newUint32List:Container([exact=NativeUint32List], element: [subclass=JSUInt32], length: null)*/
/*kernel.element: newUint32List:Container([exact=NativeUint32List], element: [subclass=JSUInt32], length: 13)*/
/*strong.element: newUint32List:Container([exact=NativeUint32List], element: [subclass=JSUInt32], length: 13)*/
newUint32List() => new Uint32List((13));

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8ClampedList using a constant multiplication as length.
////////////////////////////////////////////////////////////////////////////////

/*element: newUint8ClampedList:Container([exact=NativeUint8ClampedList], element: [exact=JSUInt31], length: null)*/
newUint8ClampedList() =>
    new Uint8ClampedList(2 /*invoke: [exact=JSUInt31]*/ * 7);

////////////////////////////////////////////////////////////////////////////////
// Create a Uint8List using a const static field as length.
////////////////////////////////////////////////////////////////////////////////

abstract class Class1 {
  /*element: Class1.field:[exact=JSUInt31]*/
  static const field = 15;
}

/*element: newUint8List:Container([exact=NativeUint8List], element: [exact=JSUInt31], length: 15)*/
newUint8List() => new Uint8List(Class1.field);
