// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

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
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                                  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMInt32x4 with Int32x4 {}
//             ^
// [cfe] 'Int32x4' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                            ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat32x4 implements Float32x4 {}
//             ^
// [cfe] 'Float32x4' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat32x4 with Float32x4 {}
//             ^
// [cfe] 'Float32x4' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CIFloat64x2 implements Float64x2 {}
//             ^
// [cfe] 'Float64x2' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class CMFloat64x2 with Float64x2 {}
//             ^
// [cfe] 'Float64x2' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

// Endian cannot be used as a superclass or mixin.

abstract class CIEndian implements Endian {}
//             ^
// [cfe] 'Endian' is restricted and can't be extended or implemented.
//                                 ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
