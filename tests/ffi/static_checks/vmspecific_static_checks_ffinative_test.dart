// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi';

void main() {
  /* Intentionally empty: Compile-time error tests. */
}

// Error: FFI leaf call must not have Handle return type.
@Native<Handle Function()>(symbol: "foo", isLeaf: true) // [cfe] unspecified
external Object foo(); // [cfe] unspecified

// Error: FFI leaf call must not have Handle argument types.
@Native<Void Function(Handle)>(symbol: "bar", isLeaf: true) // [cfe] unspecified
external void bar(Object); // [cfe] unspecified

class Classy {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
  external void badMissingReceiver(int v); // [cfe] unspecified

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted to Pointer.
  @Native<Void Function(Pointer<Void>, IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
  external void badHasReceiverPointer(int v); // [cfe] unspecified
}

base class NativeClassy {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
  external void badMissingReceiver(int v); // [cfe] unspecified

  // Error: wrong return type.
  @Native<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>(symbol: 'doesntmatter') // [cfe] unspecified
  external void toImageSync(int width, int height, Object outImage);  // [cfe] unspecified
}

// Error: Too many Native parameters.
@Native<Handle Function(IntPtr, IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
external Object badTooManyFfiParameter(int v); // [cfe] unspecified

// Error: Too few Native parameters.
@Native<Handle Function(IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
external Object badTooFewFfiParameter(int v, int v2); // [cfe] unspecified

// Error: Natives must be marked external (and by extension have no body).
@Native<Void Function()>(symbol: 'doesntmatter') // [cfe] unspecified
void mustBeMarkedExternal() {} // [cfe] unspecified

// Error: 'Native' can't be declared with optional parameters.
@Native<Void Function([Double])>(symbol: 'doesntmatter') // [cfe] unspecified
external static int badOptParam(); // [cfe] unspecified

// Error: 'Native' can't be declared with named parameters.
@Native<Void Function({Double})>(symbol: 'doesntmatter') // [cfe] unspecified
external static int badNamedParam(); // [cfe] unspecified

@Native<IntPtr Function(Double)>(symbol: 'doesntmatter') // [cfe] unspecified
external int wrongFfiParameter(int v); // [cfe] unspecified

@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
external double wrongFfiReturnType(int v); // [cfe] unspecified

@Native<IntPtr Function(int)>(symbol: 'doesntmatter') // [cfe] unspecified
external int nonFfiParameter(int v); // [cfe] unspecified

@Native<double Function(IntPtr)>(symbol: 'doesntmatter') // [cfe] unspecified
external double nonFfiReturnType(int v); // [cfe] unspecified
