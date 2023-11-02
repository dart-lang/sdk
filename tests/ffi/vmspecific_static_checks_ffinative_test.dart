// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';
import 'dart:nativewrappers';

void main() {
  /* Intentionally empty: Compile-time error tests. */
}

// Error: FFI leaf call must not have Handle return type.
@FfiNative<Handle Function()>("foo", isLeaf: true) //# 01: compile-time error
external Object foo(); //# 01: compile-time error

// Error: FFI leaf call must not have Handle argument types.
@FfiNative<Void Function(Handle)>("bar", //# 02: compile-time error
    isLeaf: true) //# 02: compile-time error
external void bar(Object); //# 02: compile-time error

class Classy {
  // Error: Missing receiver in FfiNative annotation.
  @FfiNative<Void Function(IntPtr)>('doesntmatter') //# 03: compile-time error
  external void badMissingReceiver(int v); //# 03: compile-time error

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted
  // to Pointer.
  @FfiNative<Void Function(Pointer<Void>, IntPtr)>(//# 04: compile-time error
      'doesntmatter') //# 04: compile-time error
  external void badHasReceiverPointer(int v); //# 04: compile-time error
}

base class NativeClassy extends NativeFieldWrapperClass1 {
  // Error: Missing receiver in FfiNative annotation.
  @FfiNative<Void Function(IntPtr)>('doesntmatter') //# 05: compile-time error
  external void badMissingReceiver(int v); //# 05: compile-time error

  // Error: wrong return type.
  @FfiNative<Handle Function(Pointer<Void>, Uint32, Uint32, Handle)>('doesntmatter') //# 49471: compile-time error
  external void toImageSync(int width, int height, Object outImage);  //# 49471: compile-time error
}

// Error: Too many FfiNative parameters.
@FfiNative<Handle Function(IntPtr, IntPtr)>(//# 06: compile-time error
    'doesntmatter') //# 06: compile-time error
external Object badTooManyFfiParameter(int v); //# 06: compile-time error

// Error: Too few FfiNative parameters.
@FfiNative<Handle Function(IntPtr)>('doesntmatter') //# 07: compile-time error
external Object badTooFewFfiParameter(int v, int v2); //# 07: compile-time error

// Error: FfiNatives must be marked external (and by extension have no body).
@FfiNative<Void Function()>('doesntmatter') //# 08: compile-time error
void mustBeMarkedExternal() {} //# 08: compile-time error

// Error: 'FfiNative' can't be declared with optional parameters.
@FfiNative<Void Function([Double])>('doesntmatter') //# 12: compile-time error
external static int badOptParam(); //# 12: compile-time error

// Error: 'FfiNative' can't be declared with named parameters.
@FfiNative<Void Function({Double})>('doesntmatter') //# 13: compile-time error
external static int badNamedParam(); //# 13: compile-time error

@FfiNative<IntPtr Function(Double)>('doesntmatter') //# 14: compile-time error
external int wrongFfiParameter(int v); //# 14: compile-time error

@FfiNative<IntPtr Function(IntPtr)>('doesntmatter') //# 15: compile-time error
external double wrongFfiReturnType(int v); //# 15: compile-time error

@FfiNative<IntPtr Function(int)>('doesntmatter') //# 16: compile-time error
external int nonFfiParameter(int v); //# 16: compile-time error

@FfiNative<double Function(IntPtr)>('doesntmatter') //# 17: compile-time error
external double nonFfiReturnType(int v); //# 17: compile-time error
