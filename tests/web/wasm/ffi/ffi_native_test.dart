// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-ffi
// SharedObjects=ffi_native_test_module

import 'dart:ffi';
import 'dart:nativewrappers';

import 'package:expect/expect.dart';

@Native<Void Function()>()
external void empty();

@Native<Int8 Function(Int8, Int8)>()
external int addInt8(int a, int b);

@Native<Int8 Function(Uint8, Uint8)>()
external int addUint8(int a, int b);

@Native<Int16 Function(Int16, Int16)>()
external int addInt16(int a, int b);

@Native<Uint16 Function(Uint16, Uint16)>()
external int addUint16(int a, int b);

@Native<Int32 Function(Int32, Int32)>()
external int addInt32(int a, int b);

@Native<Uint32 Function(Uint32, Uint32)>()
external int addUint32(int a, int b);

@Native<Int64 Function(Int64, Int64)>()
external int addInt64(int a, int b);

@Native<Uint64 Function(Uint64, Uint64)>()
external int addUint64(int a, int b);

@Native<Bool Function(Bool)>()
external bool negateBool(bool b);

@Native<Bool Function(Int)>()
external bool boolReturn(int b);

@Native<Void Function()>()
external void toggleBool();

@Native<Double Function(Double)>()
external double sqrt(double d);

@Native<Char Function(Char)>()
external int incrementChar(int a);

@Native<UnsignedChar Function(UnsignedChar)>()
external int incrementUnsignedChar(int a);

@Native<SignedChar Function(SignedChar)>()
external int incrementSignedChar(int a);

@Native<Short Function(Short)>()
external int incrementShort(int a);

@Native<UnsignedShort Function(UnsignedShort)>()
external int incrementUnsignedShort(int a);

@Native<Int Function(Int)>()
external int incrementInt(int a);

@Native<UnsignedInt Function(UnsignedInt)>()
external int incrementUnsignedInt(int a);

@Native<Long Function(Long)>()
external int incrementLong(int a);

@Native<UnsignedLong Function(UnsignedLong)>()
external int incrementUnsignedLong(int a);

@Native<LongLong Function(LongLong)>()
external int incrementLongLong(int a);

@Native<UnsignedLongLong Function(UnsignedLongLong)>()
external int incrementUnsignedLongLong(int a);

@Native<IntPtr Function(IntPtr)>()
external int incrementIntPtr(int a);

@Native<UintPtr Function(UintPtr)>()
external int incrementUintPtr(int a);

@Native<Size Function(Size)>()
external int incrementSize(int a);

@Native<WChar Function(WChar)>()
external int incrementWchar(int a);

final class MyStruct extends Struct {
  @Double()
  external double x;

  @Int16()
  external int y;
}

@Native<Pointer<MyStruct> Function()>()
external Pointer<MyStruct> getStruct();

@Native<Void Function(Pointer<MyStruct>)>()
external void clearStruct(Pointer<MyStruct> struct);

void main() {
  empty();

  Expect.equals(addInt8(1, 2), 3);
  Expect.equals(addInt8(127, 10), -119);

  Expect.equals(addUint8(1, 2), 3);
  Expect.equals(addUint8(255, 10), 9);

  Expect.equals(addInt16(1, 2), 3);
  Expect.equals(addInt16(32767, 10), -32759);

  Expect.equals(addUint16(1, 2), 3);
  Expect.equals(addUint16(65535, 10), 9);

  Expect.equals(addInt32(1, 2), 3);
  Expect.equals(addInt32(2147483647, 10), -2147483639);

  Expect.equals(addUint32(1, 2), 3);
  Expect.equals(addUint32(4294967295, 10), 9);

  Expect.equals(addInt64(1, 2), 3);
  Expect.equals(addInt64(9223372036854775807, 10), -9223372036854775799);

  Expect.equals(addUint64(1, 2), 3);
  Expect.equals(addUint64(9223372036854775807, 10), -9223372036854775799);

  Expect.equals(negateBool(true), false);
  Expect.equals(negateBool(false), true);

  Expect.equals(boolReturn(123), true);
  Expect.equals(boolReturn(456), false);
  Expect.equals(boolReturn(789), true);
  toggleBool();
  Expect.equals(boolReturn(789), false);

  final Pointer<MyStruct> structPointer = getStruct();
  final MyStruct struct = structPointer.ref;
  Expect.equals(struct.x, 1.0);
  Expect.equals(struct.y, 2);
  // Structs are Dart objects that are views on top of actual memory (which may
  // be backed by C memory or typed data). The view objects can be accessed
  // dynamically.
  final l = <dynamic>[struct, 1];
  Expect.equals(l[int.parse('0')].x, 1.0);

  clearStruct(structPointer);
  Expect.equals(struct.x, 0.0);
  Expect.equals(struct.y, 0);

  Expect.equals(incrementChar(1), 2);
  Expect.equals(incrementUnsignedChar(3), 4);
  Expect.equals(incrementSignedChar(5), 6);
  Expect.equals(incrementShort(7), 8);
  Expect.equals(incrementUnsignedShort(9), 10);
  Expect.equals(incrementInt(11), 12);
  Expect.equals(incrementUnsignedInt(13), 14);
  Expect.equals(incrementLong(15), 16);
  Expect.equals(incrementUnsignedLong(17), 18);
  Expect.equals(incrementLongLong(19), 20);
  Expect.equals(incrementUnsignedLongLong(21), 22);
  Expect.equals(incrementIntPtr(23), 24);
  Expect.equals(incrementUintPtr(25), 26);
  Expect.equals(incrementSize(27), 28);
  Expect.equals(incrementWchar(29), 30);
}
