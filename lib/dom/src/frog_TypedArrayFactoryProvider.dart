// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _F32(length);
  factory Float32Array.fromList(List<num> list) => _F32(ensureNative(list));
  factory Float32Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  factory Float64Array(int length) => _F64(length);
  factory Float64Array.fromList(List<num> list) => _F64(ensureNative(list));
  factory Float64Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  factory Int8Array(int length) => _I8(length);
  factory Int8Array.fromList(List<num> list) => _I8(ensureNative(list));
  factory Int8Array.fromBuffer(ArrayBuffer buffer,
                               [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  factory Int16Array(int length) => _I16(length);
  factory Int16Array.fromList(List<num> list) => _I16(ensureNative(list));
  factory Int16Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  factory Int32Array(int length) => _I32(length);
  factory Int32Array.fromList(List<num> list) => _I32(ensureNative(list));
  factory Int32Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  factory Uint8Array(int length) => _U8(length);
  factory Uint8Array.fromList(List<num> list) => _U8(ensureNative(list));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  factory Uint16Array(int length) => _U16(length);
  factory Uint16Array.fromList(List<num> list) => _U16(ensureNative(list));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  factory Uint32Array(int length) => _U32(length);
  factory Uint32Array.fromList(List<num> list) => _U32(ensureNative(list));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  factory Uint8ClampedArray(int length) => _U8C(length);
  factory Uint8ClampedArray.fromList(List<num> list) => _U8C(ensureNative(list));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer,
                                       [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static Float32Array _F32(arg) native 'return new Float32Array(arg);';
  static Float64Array _F64(arg) native 'return new Float64Array(arg);';
  static Int8Array _I8(arg) native 'return new Int8Array(arg);';
  static Int16Array _I16(arg) native 'return new Int16Array(arg);';
  static Int32Array _I32(arg) native 'return new Int32Array(arg);';
  static Uint8Array _U8(arg) native 'return new Uint8Array(arg);';
  static Uint16Array _U16(arg) native 'return new Uint16Array(arg);';
  static Uint32Array _U32(arg) native 'return new Uint32Array(arg);';
  static Uint8ClampedArray _U8C(arg) native 'return new Uint8ClampedArray(arg);';

  static Float32Array _F32_2(arg1, arg2) native 'return new Float32Array(arg1, arg2);';
  static Float64Array _F64_2(arg1, arg2) native 'return new Float64Array(arg1, arg2);';
  static Int8Array _I8_2(arg1, arg2) native 'return new Int8Array(arg1, arg2);';
  static Int16Array _I16_2(arg1, arg2) native 'return new Int16Array(arg1, arg2);';
  static Int32Array _I32_2(arg1, arg2) native 'return new Int32Array(arg1, arg2);';
  static Uint8Array _U8_2(arg1, arg2) native 'return new Uint8Array(arg1, arg2);';
  static Uint16Array _U16_2(arg1, arg2) native 'return new Uint16Array(arg1, arg2);';
  static Uint32Array _U32_2(arg1, arg2) native 'return new Uint32Array(arg1, arg2);';
  static Uint8ClampedArray _U8C_2(arg1, arg2) native 'return new Uint8ClampedArray(arg1, arg2);';

  static Float32Array _F32_3(arg1, arg2, arg3) native 'return new Float32Array(arg1, arg2, arg3);';
  static Float64Array _F64_3(arg1, arg2, arg3) native 'return new Float64Array(arg1, arg2, arg3);';
  static Int8Array _I8_3(arg1, arg2, arg3) native 'return new Int8Array(arg1, arg2, arg3);';
  static Int16Array _I16_3(arg1, arg2, arg3) native 'return new Int16Array(arg1, arg2, arg3);';
  static Int32Array _I32_3(arg1, arg2, arg3) native 'return new Int32Array(arg1, arg2, arg3);';
  static Uint8Array _U8_3(arg1, arg2, arg3) native 'return new Uint8Array(arg1, arg2, arg3);';
  static Uint16Array _U16_3(arg1, arg2, arg3) native 'return new Uint16Array(arg1, arg2, arg3);';
  static Uint32Array _U32_3(arg1, arg2, arg3) native 'return new Uint32Array(arg1, arg2, arg3);';
  static Uint8ClampedArray _U8C_3(arg1, arg2, arg3) native 'return new Uint8ClampedArray(arg1, arg2, arg3);';


  // Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
  // copies the list.
  static ensureNative(List list) => list;  // TODO: make sure.
}
