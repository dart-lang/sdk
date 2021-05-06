// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

abstract class CEByteBuffer extends ByteBuffer {}
//             ^
// [cfe] 'ByteBuffer' is restricted and can't be extended or implemented.
//                                  ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIByteBuffer implements ByteBuffer {}
//             ^
// [cfe] 'ByteBuffer' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMByteBuffer with ByteBuffer {}
//             ^
// [cfe] 'ByteBuffer' is restricted and can't be extended or implemented.
//                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CETypedData extends TypedData {}
//             ^
// [cfe] 'TypedData' is restricted and can't be extended or implemented.
//                                 ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CITypedData implements TypedData {}
//             ^
// [cfe] 'TypedData' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMTypedData with TypedData {}
//             ^
// [cfe] 'TypedData' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIByteData implements ByteData {}
//             ^
// [cfe] 'ByteData' is restricted and can't be extended or implemented.
//                                   ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMByteData with ByteData {}
//             ^
// [cfe] 'ByteData' is restricted and can't be extended or implemented.
//                             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt8List implements Int8List {}
//             ^
// [cfe] 'Int8List' is restricted and can't be extended or implemented.
//                                   ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt8List with Int8List {}
//             ^
// [cfe] 'Int8List' is restricted and can't be extended or implemented.
//                             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUint8List implements Uint8List {}
//             ^
// [cfe] 'Uint8List' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMUint8List with Uint8List {}
//             ^
// [cfe] 'Uint8List' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class Uint8CIClampedList implements Uint8ClampedList {}
//             ^
// [cfe] 'Uint8ClampedList' is restricted and can't be extended or implemented.
//                                           ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class Uint8CMClampedList with Uint8ClampedList {}
//             ^
// [cfe] 'Uint8ClampedList' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt16List implements Int16List {}
//             ^
// [cfe] 'Int16List' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt16List with Int16List {}
//             ^
// [cfe] 'Int16List' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUint16List implements Uint16List {}
//             ^
// [cfe] 'Uint16List' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMUint16List with Uint16List {}
//             ^
// [cfe] 'Uint16List' is restricted and can't be extended or implemented.
//                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt32List implements Int32List {}
//             ^
// [cfe] 'Int32List' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt32List with Int32List {}
//             ^
// [cfe] 'Int32List' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUint32List implements Uint32List {}
//             ^
// [cfe] 'Uint32List' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMUint32List with Uint32List {}
//             ^
// [cfe] 'Uint32List' is restricted and can't be extended or implemented.
//                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt64List implements Int64List {}
//             ^
// [cfe] 'Int64List' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt64List with Int64List {}
//             ^
// [cfe] 'Int64List' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUint64List implements Uint64List {}
//             ^
// [cfe] 'Uint64List' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMUint64List with Uint64List {}
//             ^
// [cfe] 'Uint64List' is restricted and can't be extended or implemented.
//                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat32List implements Float32List {}
//             ^
// [cfe] 'Float32List' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat32List with Float32List {}
//             ^
// [cfe] 'Float32List' is restricted and can't be extended or implemented.
//                                ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat64List implements Float64List {}
//             ^
// [cfe] 'Float64List' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat64List with Float64List {}
//             ^
// [cfe] 'Float64List' is restricted and can't be extended or implemented.
//                                ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt32x4List implements Int32x4List {}
//             ^
// [cfe] 'Int32x4List' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt32x4List with Int32x4List {}
//             ^
// [cfe] 'Int32x4List' is restricted and can't be extended or implemented.
//                                ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat32x4List implements Float32x4List {}
//             ^
// [cfe] 'Float32x4List' is restricted and can't be extended or implemented.
//                                        ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat32x4List with Float32x4List {}
//             ^
// [cfe] 'Float32x4List' is restricted and can't be extended or implemented.
//                                  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat64x2List implements Float64x2List {}
//             ^
// [cfe] 'Float64x2List' is restricted and can't be extended or implemented.
//                                        ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat64x2List with Float64x2List {}
//             ^
// [cfe] 'Float64x2List' is restricted and can't be extended or implemented.
//                                  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIInt32x4 implements Int32x4 {}
//             ^
// [cfe] 'Int32x4' is restricted and can't be extended or implemented.
//                                  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt32x4 with Int32x4 {}
//             ^
// [cfe] 'Int32x4' is restricted and can't be extended or implemented.
//                            ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat32x4 implements Float32x4 {}
//             ^
// [cfe] 'Float32x4' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat32x4 with Float32x4 {}
//             ^
// [cfe] 'Float32x4' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat64x2 implements Float64x2 {}
//             ^
// [cfe] 'Float64x2' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat64x2 with Float64x2 {}
//             ^
// [cfe] 'Float64x2' is restricted and can't be extended or implemented.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

// Endian cannot be used as a superclass or mixin.

abstract class CIEndian implements Endian {}
//             ^
// [cfe] 'Endian' is restricted and can't be extended or implemented.
//                                 ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnByteBufferView implements UnmodifiableByteBufferView {}
//             ^
// [cfe] 'UnmodifiableByteBufferView' is restricted and can't be extended or implemented.
//                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnByteDataView implements UnmodifiableByteDataView {}
//             ^
// [cfe] 'UnmodifiableByteDataView' is restricted and can't be extended or implemented.
//                                         ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnInt8LV implements UnmodifiableInt8ListView {}
//             ^
// [cfe] 'UnmodifiableInt8ListView' is restricted and can't be extended or implemented.
//                                   ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnUint8LV implements UnmodifiableUint8ListView {}
//             ^
// [cfe] 'UnmodifiableUint8ListView' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnUint8ClampedLV implements UnmodifiableUint8ClampedListView {}
//             ^
// [cfe] 'UnmodifiableUint8ClampedListView' is restricted and can't be extended or implemented.
//                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnInt16LV implements UnmodifiableInt16ListView {}
//             ^
// [cfe] 'UnmodifiableInt16ListView' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnUint16LV implements UnmodifiableUint16ListView {}
//             ^
// [cfe] 'UnmodifiableUint16ListView' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnInt32LV implements UnmodifiableInt32ListView {}
//             ^
// [cfe] 'UnmodifiableInt32ListView' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnUint32LV implements UnmodifiableUint32ListView {}
//             ^
// [cfe] 'UnmodifiableUint32ListView' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnInt64LV implements UnmodifiableInt64ListView {}
//             ^
// [cfe] 'UnmodifiableInt64ListView' is restricted and can't be extended or implemented.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnUint64LV implements UnmodifiableUint64ListView {}
//             ^
// [cfe] 'UnmodifiableUint64ListView' is restricted and can't be extended or implemented.
//                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnFloat32LV implements UnmodifiableFloat32ListView {}
//             ^
// [cfe] 'UnmodifiableFloat32ListView' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnFloat64LV implements UnmodifiableFloat64ListView {}
//             ^
// [cfe] 'UnmodifiableFloat64ListView' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnInt32x4LV implements UnmodifiableInt32x4ListView {}
//             ^
// [cfe] 'UnmodifiableInt32x4ListView' is restricted and can't be extended or implemented.
//                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnFloat32x4LV implements UnmodifiableFloat32x4ListView {}
//             ^
// [cfe] 'UnmodifiableFloat32x4ListView' is restricted and can't be extended or implemented.
//                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIUnFloat64x2LV implements UnmodifiableFloat64x2ListView {}
//             ^
// [cfe] 'UnmodifiableFloat64x2ListView' is restricted and can't be extended or implemented.
//                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
