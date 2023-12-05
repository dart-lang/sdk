// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DefaultAsset('my_asset')
@DefaultAsset('another_one')
// [error column 2, length 12]
// [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET
// [cfe] There may be at most one @DefaultAsset annotation on a library.
library;

import 'dart:ffi';

void main() {}

const emptyNative = Native<Void Function()>;

@Native<Void Function()>()
external void _valid();

@emptyNative
external void _valid2();

final class MyStruct extends Struct {
  @Int32()
  external int id;
  external Pointer<MyStruct> next;
}

typedef ComplexNativeFunction = MyStruct Function(Long, Double, MyStruct);
const native = Native<ComplexNativeFunction>();

@native
external MyStruct validNative(int a, double b, MyStruct c);

external void notNative();

@Native<Int32 Function(Int32)>()
@Native<Int32 Function(Int32)>(isLeaf: true)
// [error column 2, length 6]
// [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS
external int foo(int v);
//           ^
// [cfe] Native functions must not have more than @Native annotation.

void addressOf() {
  Native.addressOf<NativeFunction<Void Function()>>(notNative);
  //                                               ^
  // [cfe] Argument to 'Native.addressOf' must be annotated with @Native.
  //                                                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_NATIVE

  var boolean = 1 == 2;
  Native.addressOf<NativeFunction<Void Function()>>(boolean ? _valid : _valid2);
  //                                                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_NATIVE
  //                                                        ^
  // [cfe] Argument to 'Native.addressOf' must be annotated with @Native.

  Native.addressOf<NativeFunction>(() => 3);
  //                               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_NATIVE
  // [cfe] Argument to 'Native.addressOf' must be annotated with @Native.
  Native.addressOf<NativeFunction>('malloc');
  //                               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_NATIVE
  // [cfe] Argument to 'Native.addressOf' must be annotated with @Native.

  Native.addressOf(_valid);
//^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
//       ^
// [cfe] Expected type 'NativeType' to be a valid and instantiated subtype of 'NativeType'.

  Native.addressOf<NativeFunction<Void Function(Int)>>(_valid);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
//       ^
// [cfe] Expected type 'void Function()' to be 'void Function(int)', which is the Dart type corresponding to 'NativeFunction<Void Function(Int)>'.

  Native.addressOf<NativeFunction<ComplexNativeFunction>>(validNative);
}
