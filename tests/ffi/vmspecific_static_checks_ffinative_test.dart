// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';

void main() {
  /* Intentionally empty: Compile-time error tests. */
}

// Error: FFI leaf call must not have Handle return type.
@Native<Handle Function()>(symbol: "foo", isLeaf: true) //# 01: compile-time error
external Object foo(); //# 01: compile-time error

// Error: FFI leaf call must not have Handle argument types.
@Native<Void Function(Handle)>(symbol: "bar", //# 02: compile-time error
    isLeaf: true) //# 02: compile-time error
external void bar(Object); //# 02: compile-time error

class Classy {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter') //# 03: compile-time error
  external void badMissingReceiver(int v); //# 03: compile-time error

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted
  // to Pointer.
  @Native<Void Function(Pointer<Void>, IntPtr)>(//# 04: compile-time error
      symbol: 'doesntmatter') //# 04: compile-time error
  external void badHasReceiverPointer(int v); //# 04: compile-time error
}

base class NativeClassy extends NativeFieldWrapperClass1 {
  // Error: Missing receiver in Native annotation.
  @Native<Void Function(IntPtr)>(symbol: 'doesntmatter') //# 05: compile-time error
  external void badMissingReceiver(int v); //# 05: compile-time error

  // Error: wrong return type.
  @Native<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>(symbol: 'doesntmatter') //# 49471: compile-time error
  external void toImageSync(int width, int height, Object outImage);  //# 49471: compile-time error
}

// Error: Too many Native parameters.
@Native<Handle Function(IntPtr, IntPtr)>(//# 06: compile-time error
    symbol: 'doesntmatter') //# 06: compile-time error
external Object badTooManyFfiParameter(int v); //# 06: compile-time error

// Error: Too few Native parameters.
@Native<Handle Function(IntPtr)>(symbol: 'doesntmatter') //# 07: compile-time error
external Object badTooFewFfiParameter(int v, int v2); //# 07: compile-time error

// Error: Natives must be marked external (and by extension have no body).
@Native<Void Function()>(symbol: 'doesntmatter') //# 08: compile-time error
void mustBeMarkedExternal() {} //# 08: compile-time error

// Error: 'Native' can't be declared with optional parameters.
@Native<Void Function([Double])>(symbol: 'doesntmatter') //# 12: compile-time error
external static int badOptParam(); //# 12: compile-time error

// Error: 'Native' can't be declared with named parameters.
@Native<Void Function({Double})>(symbol: 'doesntmatter') //# 13: compile-time error
external static int badNamedParam(); //# 13: compile-time error

@Native<IntPtr Function(Double)>(symbol: 'doesntmatter') //# 14: compile-time error
external int wrongFfiParameter(int v); //# 14: compile-time error

@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter') //# 15: compile-time error
external double wrongFfiReturnType(int v); //# 15: compile-time error

@Native<IntPtr Function(int)>(symbol: 'doesntmatter') //# 16: compile-time error
external int nonFfiParameter(int v); //# 16: compile-time error

@Native<double Function(IntPtr)>(symbol: 'doesntmatter') //# 17: compile-time error
external double nonFfiReturnType(int v); //# 17: compile-time error
