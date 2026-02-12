// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

import 'dart:ffi';
import 'dart:nativewrappers';

void main() {
  /* Intentionally empty: Compile-time error tests. */
}

// Error: FFI leaf call must not have Handle return type.
@Native<Handle Function()>(symbol: "foo", isLeaf: true)
external Object foo();
//              ^^^
// [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_RETURN_HANDLE
// [cfe] FFI leaf call must not have Handle return type.

// Error: FFI leaf call must not have Handle argument types.
@Native<Void Function(Handle)>(symbol: "bar",
    isLeaf: true)
external void bar(Object);
//            ^^^
// [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_TAKE_HANDLE
// [cfe] FFI leaf call must not have Handle argument types.

class Classy {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter')
  // [error column 4]
  // [cfe] Unexpected number of Native annotation parameters. Expected 2 but has 1. Native instance method annotation must have receiver as first argument.
  external void badMissingReceiver(int v);
  //            ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted
  // to Pointer.
  @Native<Void Function(Pointer<Void>, IntPtr)>(
  // [error column 4]
  // [cfe] Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.
      symbol: 'doesntmatter')
  external void badHasReceiverPointer(int v);
  //            ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER
}

base class NativeClassy extends NativeFieldWrapperClass1 {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter')
  // [error column 4]
  // [cfe] Unexpected number of Native annotation parameters. Expected 2 but has 1. Native instance method annotation must have receiver as first argument.
  external void badMissingReceiver(int v);
  //            ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER

  // Error: wrong return type.
  @Native<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>(symbol: 'doesntmatter')
  external void toImageSync(int width, int height, Object outImage);
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected type 'void Function(Pointer<Void>, int, int, Object)' to be 'Never Function(Pointer<Void>, int, int, Object?)', which is the Dart type corresponding to 'NativeFunction<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>'.
}

// Error: Too many Native parameters.
@Native<Handle Function(IntPtr, IntPtr)>(
// [error column 2]
// [cfe] Unexpected number of Native annotation parameters. Expected 1 but has 2.
    symbol: 'doesntmatter')
external Object badTooManyFfiParameter(int v);
//              ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS

// Error: Too few Native parameters.
@Native<Handle Function(IntPtr)>(symbol: 'doesntmatter')
// [error column 2]
// [cfe] Unexpected number of Native annotation parameters. Expected 2 but has 1.
external Object badTooFewFfiParameter(int v, int v2);
//              ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS

// Error: Natives must be marked external (and by extension have no body).
@Native<Void Function()>(symbol: 'doesntmatter')
void mustBeMarkedExternal() {}
//   ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FFI_NATIVE_MUST_BE_EXTERNAL
// [cfe] Native functions and fields must be marked external.

// Error: 'Native' can't be declared with optional parameters.
@Native<Void Function([Double])>(symbol: 'doesntmatter')
// [error column 2]
// [cfe] Expected type 'NativeFunction<Void Function([Double])>' to be a valid and instantiated subtype of 'NativeType'.
external static int badOptParam();
//       ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'static' here.
//                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE

// Error: 'Native' can't be declared with named parameters.
@Native<Void Function({Double})>(symbol: 'doesntmatter')
//                           ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '}'.
external static int badNamedParam();
//       ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'static' here.
//                  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
// [cfe] Expected type 'int Function()' to be 'void Function()', which is the Dart type corresponding to 'NativeFunction<Void Function()>'.

@Native<IntPtr Function(Double)>(symbol: 'doesntmatter')
external int wrongFfiParameter(int v);
//           ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'int Function(int)' to be 'int Function(double)', which is the Dart type corresponding to 'NativeFunction<IntPtr Function(Double)>'.

@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter')
external double wrongFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'double Function(int)' to be 'int Function(int)', which is the Dart type corresponding to 'NativeFunction<IntPtr Function(IntPtr)>'.

@Native<IntPtr Function(int)>(symbol: 'doesntmatter')
// [error column 2]
// [cfe] Expected type 'NativeFunction<IntPtr Function(int)>' to be a valid and instantiated subtype of 'NativeType'.
external int nonFfiParameter(int v);
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE

@Native<double Function(IntPtr)>(symbol: 'doesntmatter')
// [error column 2]
// [cfe] Expected type 'NativeFunction<double Function(IntPtr)>' to be a valid and instantiated subtype of 'NativeType'.
external double nonFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
