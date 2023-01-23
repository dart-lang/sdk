// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_native_test_module

import 'dart:ffi';
import 'dart:nativewrappers';

import 'package:expect/expect.dart';

@FfiNative<Void Function()>("ffi.empty")
external void empty();

@FfiNative<Int8 Function(Int8, Int8)>("ffi.addInt8")
external int addInt8(int a, int b);

@FfiNative<Int8 Function(Uint8, Uint8)>("ffi.addUint8")
external int addUint8(int a, int b);

@FfiNative<Int16 Function(Int16, Int16)>("ffi.addInt16")
external int addInt16(int a, int b);

@FfiNative<Uint16 Function(Uint16, Uint16)>("ffi.addUint16")
external int addUint16(int a, int b);

@FfiNative<Int32 Function(Int32, Int32)>("ffi.addInt32")
external int addInt32(int a, int b);

@FfiNative<Uint32 Function(Uint32, Uint32)>("ffi.addUint32")
external int addUint32(int a, int b);

@FfiNative<Int64 Function(Int64, Int64)>("ffi.addInt64")
external int addInt64(int a, int b);

@FfiNative<Uint64 Function(Uint64, Uint64)>("ffi.addUint64")
external int addUint64(int a, int b);

@FfiNative<Bool Function(Bool)>("ffi.negateBool")
external bool negateBool(bool b);

@FfiNative<Bool Function(Int)>("ffi.boolReturn")
external bool boolReturn(int b);

@FfiNative<Void Function()>("ffi.toggleBool")
external void toggleBool();

@FfiNative<Double Function(Double)>("ffi.sqrt")
external double sqrt(double d);

@FfiNative<Char Function(Char)>("ffi.incrementChar")
external int incrementChar(int a);

@FfiNative<UnsignedChar Function(UnsignedChar)>("ffi.incrementUnsignedChar")
external int incrementUnsignedChar(int a);

@FfiNative<SignedChar Function(SignedChar)>("ffi.incrementSignedChar")
external int incrementSignedChar(int a);

@FfiNative<Short Function(Short)>("ffi.incrementShort")
external int incrementShort(int a);

@FfiNative<UnsignedShort Function(UnsignedShort)>("ffi.incrementUnsignedShort")
external int incrementUnsignedShort(int a);

@FfiNative<Int Function(Int)>("ffi.incrementInt")
external int incrementInt(int a);

@FfiNative<UnsignedInt Function(UnsignedInt)>("ffi.incrementUnsignedInt")
external int incrementUnsignedInt(int a);

@FfiNative<Long Function(Long)>("ffi.incrementLong")
external int incrementLong(int a);

@FfiNative<UnsignedLong Function(UnsignedLong)>("ffi.incrementUnsignedLong")
external int incrementUnsignedLong(int a);

@FfiNative<LongLong Function(LongLong)>("ffi.incrementLongLong")
external int incrementLongLong(int a);

@FfiNative<UnsignedLongLong Function(UnsignedLongLong)>(
    "ffi.incrementUnsignedLongLong")
external int incrementUnsignedLongLong(int a);

@FfiNative<IntPtr Function(IntPtr)>("ffi.incrementIntPtr")
external int incrementIntPtr(int a);

@FfiNative<UintPtr Function(UintPtr)>("ffi.incrementUintPtr")
external int incrementUintPtr(int a);

@FfiNative<Size Function(Size)>("ffi.incrementSize")
external int incrementSize(int a);

@FfiNative<WChar Function(WChar)>("ffi.incrementWchar")
external int incrementWchar(int a);

class MyStruct extends Struct implements NativeFieldWrapperClass1 {
  @Double()
  external double x;

  @Int16()
  external int y;
}

@FfiNative<Pointer<MyStruct> Function()>("ffi.getStruct")
external Pointer<MyStruct> getStruct();

@FfiNative<Void Function(Pointer<MyStruct>)>("ffi.clearStruct")
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

  final struct_ = getStruct();
  Expect.equals(struct_.ref.x, 1.0);
  Expect.equals(struct_.ref.y, 2);
  clearStruct(struct_);
  Expect.equals(struct_.ref.x, 0.0);
  Expect.equals(struct_.ref.y, 0);

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
