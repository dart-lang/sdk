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
// [cfe] Native functions and fields must not have more than @Native annotation.

@Native()
external final MyStruct myStruct0;

@Native<MyStruct>()
external MyStruct myStruct1;

@Native<Pointer<MyStruct>>()
external MyStruct myStructInvalid;
//                ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'MyStruct' to be 'Pointer<MyStruct>', which is the Dart type corresponding to 'Pointer<MyStruct>'.

@Native()
external Pointer<MyStruct> myStructPtr0;

@Native<Pointer<MyStruct>>()
external final Pointer<MyStruct> myStructPtr1;

@Native<MyStruct>()
external Pointer<MyStruct> myStructPtrInvalid;
//                         ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'Pointer<MyStruct>' to be 'MyStruct', which is the Dart type corresponding to 'MyStruct'.

@Native()
external int invalidNoInferrence;
//           ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NATIVE_FIELD_MISSING_TYPE
// [cfe] The native type of this field could not be inferred and must be specified in the annotation.

@Native<Handle>()
external Object invalidUnsupportedHandle;
//              ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NATIVE_FIELD_INVALID_TYPE
// [cfe] Unsupported type for native fields. Native fields only support pointers, compounds and numeric types.

@Native()
external Array<IntPtr> invalidMissingArrayAnnotation;
//                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MISSING_SIZE_ANNOTATION_CARRAY
// [cfe] Field 'invalidMissingArrayAnnotation' must have exactly one 'Array' annotation.

@Native()
@Array(10)
@Array(12)
// [error column 1, length 10]
// [analyzer] COMPILE_TIME_ERROR.EXTRA_SIZE_ANNOTATION_CARRAY
external Array<IntPtr> invalidDuplicateArrayAnnotation;
//                     ^
// [cfe] Field 'invalidDuplicateArrayAnnotation' must have exactly one 'Array' annotation.

@Native()
@Array(1, 2)
// [error column 1, length 12]
// [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
external Array<IntPtr> invalidArrayWrongDimensions;
//                     ^
// [cfe] Field 'invalidArrayWrongDimensions' must have an 'Array' annotation that matches the dimensions.

@Native()
@Array(-10)
//     ^^^
// [analyzer] COMPILE_TIME_ERROR.NON_POSITIVE_ARRAY_DIMENSION
external Array<IntPtr> invalidArrayDimensionSize;
//                     ^
// [cfe] Array dimensions must be positive numbers.

@Native()
@Array(10)
external Array<IntPtr> validArray;

@Native()
@Array(2, 3)
external Array<Array<IntPtr>> validNestedArray;

@Native<NativeFunction<Int Function()>>()
external int Function() invalidUnsupportedType;
//                      ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NATIVE_FIELD_INVALID_TYPE
// [cfe] Unsupported type for native fields. Native fields only support pointers, compounds and numeric types.

@Native<NativeFunction<Int Function(Pointer<Void>)>>()
external int Function() invalidUnsupportedAndMismatchingType;
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'int Function()' to be 'int Function(Pointer<Void>)', which is the Dart type corresponding to 'NativeFunction<Int Function(Pointer<Void>)>'.

class MyClass {
  @Native<Double>()
  external double invalidInstanceField;
  //              ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NATIVE_FIELD_NOT_STATIC
  // [cfe] Native fields must be static.

  @Native<Double>()
  external static double validField;
}

void addressOf() {
  Native.addressOf<NativeFunction<Void Function()>>(notNative);
  //                                                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_NATIVE
  // [cfe] Argument to 'Native.addressOf' must be annotated with @Native.

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

  // dart format off

  Native.addressOf(_valid);
//^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
  //     ^
  // [cfe] Expected type 'NativeType' to be a valid and instantiated subtype of 'NativeType'.

  Native.addressOf<NativeFunction>(_valid);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //     ^
  // [cfe] Expected type 'NativeFunction<Function>' to be a valid and instantiated subtype of 'NativeType'.

  Native.addressOf<NativeFunction<Void Function(Int)>>(_valid);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //     ^
  // [cfe] Expected type 'void Function()' to be 'void Function(int)', which is the Dart type corresponding to 'NativeFunction<Void Function(Int)>'.

  Native.addressOf<NativeFunction<ComplexNativeFunction>>(validNative);

  Native.addressOf(myStruct0);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //     ^
  // [cfe] Expected type 'NativeType' to be a valid and instantiated subtype of 'NativeType'.

  Native.addressOf<MyStruct>(myStruct0);
  Native.addressOf<MyStruct>(myStruct1);
  Native.addressOf<Pointer<MyStruct>>(myStructPtr0);
  Native.addressOf<Pointer<MyStruct>>(myStructPtr1);

  Native.addressOf<Int>(myStruct0);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //     ^
  // [cfe] Expected type 'MyStruct' to be 'int', which is the Dart type corresponding to 'Int'.

  Native.addressOf<Array<IntPtr>>(validArray);

  Native.addressOf<Array<IntPtr>>(validNestedArray);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //     ^
  // [cfe] Expected type 'Array<Array<IntPtr>>' to be 'Array<IntPtr>', which is the Dart type corresponding to 'Array<IntPtr>'.
}
