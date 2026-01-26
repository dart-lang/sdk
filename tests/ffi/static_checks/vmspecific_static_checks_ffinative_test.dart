// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';

void main() {
  /* Intentionally empty: Compile-time error tests. */
}

// Error: FFI leaf call must not have Handle return type.
@Native<Handle Function()>(symbol: "foo", isLeaf: true)
external Object foo();
//       ^
// [cfe] FFI leaf call must not have Handle return type.
// [analyzer] COMPILE_TIME_ERROR.FFI_LEAF_CALL_MUST_NOT_HAVE_HANDLE_RETURN_TYPE

// Error: FFI leaf call must not have Handle argument types.
@Native<Void Function(Handle)>(symbol: "bar",
    isLeaf: true)
external void bar(Object o);
//                ^
// [cfe] FFI leaf call must not have Handle argument types.
// [analyzer] COMPILE_TIME_ERROR.FFI_LEAF_CALL_MUST_NOT_HAVE_HANDLE_ARGUMENT_TYPES

class Classy {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter')
  external void badMissingReceiver(int v);
  //            ^^^^^^^^^^^^^^^^^^
  // [cfe] Native instance methods must have a receiver.
  // [analyzer] COMPILE_TIME_ERROR.NATIVE_INSTANCE_METHOD_MISSING_RECEIVER

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted
  // to Pointer.
  @Native<Void Function(Pointer<Void>, IntPtr)>(
      symbol: 'doesntmatter')
  external void badHasReceiverPointer(int v);
  //            ^^^^^^^^^^^^^^^^^^^^^
  // [cfe] Class 'Classy' must extend 'NativeFieldWrapperClass1' to be used as a receiver.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_NATIVE_RECEIVER
}

base class NativeClassy extends NativeFieldWrapperClass1 {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter')
  external void badMissingReceiver(int v);
  //            ^^^^^^^^^^^^^^^^^^
  // [cfe] Native instance methods must have a receiver.
  // [analyzer] COMPILE_TIME_ERROR.NATIVE_INSTANCE_METHOD_MISSING_RECEIVER

  // Error: wrong return type.
  @Native<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>(symbol: 'doesntmatter')
  external void toImageSync(int width, int height, Object outImage);
  //            ^^^^^^^^^^^
  // [cfe] Expected return type 'Object', 'dynamic' or 'void', but got 'Handle'.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_RETURN_TYPE
}

// Error: Too many Native parameters.
@Native<Handle Function(IntPtr, IntPtr)>(
    symbol: 'doesntmatter')
external Object badTooManyFfiParameter(int v);
//              ^^^^^^^^^^^^^^^^^^^^^^
// [cfe] Expected 1 parameters in 'Native' annotation, but got 2.
// [analyzer] COMPILE_TIME_ERROR.MISMATCHED_ANNOTATION_PARAMETERS

// Error: Too few Native parameters.
@Native<Handle Function(IntPtr)>(symbol: 'doesntmatter')
external Object badTooFewFfiParameter(int v, int v2);
//              ^^^^^^^^^^^^^^^^^^^^^
// [cfe] Expected 2 parameters in 'Native' annotation, but got 1.
// [analyzer] COMPILE_TIME_ERROR.MISMATCHED_ANNOTATION_PARAMETERS

// Error: Natives must be marked external (and by extension have no body).
@Native<Void Function()>(symbol: 'doesntmatter')
void mustBeMarkedExternal() {}
//   ^^^^^^^^^^^^^^^^^^^^
// [cfe] Native functions must be marked external.
// [analyzer] COMPILE_TIME_ERROR.NATIVE_FUNCTION_BODY_IN_NON_SDK

// Error: 'Native' can't be declared with optional parameters.
@Native<Void Function([Double])>(symbol: 'doesntmatter')
external static int badOptParam();
//                  ^^^^^^^^^^^
// [cfe] Native functions cannot have optional parameters.
// [analyzer] COMPILE_TIME_ERROR.OPTIONAL_PARAMETER_IN_NATIVE_FUNCTION

// Error: 'Native' can't be declared with named parameters.
@Native<Void Function({Double})>(symbol: 'doesntmatter')
external static int badNamedParam();
//                  ^^^^^^^^^^^^^
// [cfe] Native functions cannot have named parameters.
// [analyzer] COMPILE_TIME_ERROR.NAMED_PARAMETER_IN_NATIVE_FUNCTION

@Native<IntPtr Function(Double)>(symbol: 'doesntmatter')
external int wrongFfiParameter(int v);
//           ^^^^^^^^^^^^^^^^^
// [cfe] Expected type 'double', but got 'int'.
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE

@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter')
external double wrongFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^^^
// [cfe] Expected type 'int', but got 'double'.
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE

@Native<IntPtr Function(int)>(symbol: 'doesntmatter')
external int nonFfiParameter(int v);
//           ^^^^^^^^^^^^^^^
// [cfe] The type 'int' is not a valid FFI type.
// [analyzer] COMPILE_TIME_ERROR.INVALID_FFI_TYPE

@Native<double Function(IntPtr)>(symbol: 'doesntmatter')
external double nonFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^
// [cfe] The type 'double' is not a valid FFI type.
// [analyzer] COMPILE_TIME_ERROR.INVALID_FFI_TYPE

