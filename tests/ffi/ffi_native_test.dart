// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';
import 'dart:nativewrappers';

// Error: FFI leaf call must not have Handle return type.
@FfiNative<Handle Function()>("foo", isLeaf: true) //# 01: compile-time error
external Object foo(); //# 01: compile-time error

// Error: FFI leaf call must not have Handle argument types.
@FfiNative<Void Function(Handle)>("bar", //# 02: compile-time error
    isLeaf: true) //# 02: compile-time error
external void bar(Object); //# 02: compile-time error

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  // Error: Missing receiver in FfiNative annotation.
  @FfiNative<Void Function(IntPtr)>('doesntmatter') //# 03: compile-time error
  external void badMissingReceiver(int v); //# 03: compile-time error

  // Error: Class doesn't extend NativeFieldWrapperClass1 - can't be converted
  // to Pointer.
  @FfiNative<Void Function(Pointer<Void>, IntPtr)>(//# 04: compile-time error
      'doesntmatter') //# 04: compile-time error
  external void badHasReceiverPointer(int v); //# 04: compile-time error

  @FfiNative<Void Function(Handle, IntPtr)>('doesntmatter')
  external void goodHasReceiverHandle(int v);
}

class NativeClassy extends NativeFieldWrapperClass1 {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  // Error: Missing receiver in FfiNative annotation.
  @FfiNative<Void Function(IntPtr)>('doesntmatter') //# 05: compile-time error
  external void badMissingReceiver(int v); //# 05: compile-time error

  @FfiNative<Void Function(Pointer<Void>, IntPtr)>('doesntmatter')
  external void goodHasReceiverPointer(int v);

  @FfiNative<Void Function(Handle, IntPtr)>('doesntmatter')
  external void goodHasReceiverHandle(int v);
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

// Regression test: Ensure same-name FfiNative functions don't collide in the
// top-level namespace, but instead live under their parent (Library, Class).
class A {
  @FfiNative<Void Function()>('nop')
  external static void foo();
}

class B {
  @FfiNative<Void Function()>('nop')
  external static void foo();
}

class DoesNotExtend implements NativeFieldWrapperClass1 {
  // Error: Receiver type can't be converted to Pointer since it doesn't extend
  // NativeFieldWrapperClass1.
  @FfiNative<IntPtr Function(Pointer<Void>, Handle)>(//# 09: compile-time error
      'doesntmatter') //# 09: compile-time error
  external int bad1(DoesNotExtend obj); //# 09: compile-time error

  // Error: Parameter type can't be converted to Pointer since it doesn't extend
  // NativeFieldWrapperClass1.
  @FfiNative<IntPtr Function(Handle, Pointer<Void>)>(//# 10: compile-time error
      'doesntmatter') //# 10: compile-time error
  external int bad2(DoesNotExtend obj); //# 10: compile-time error

  // Error: Parameter type can't be converted to Pointer since it doesn't extend
  // NativeFieldWrapperClass1.
  @FfiNative<IntPtr Function(Pointer<Void>)>(//# 11: compile-time error
      'doesntmatter') //# 11: compile-time error
  external static int bad3(DoesNotExtend obj); //# 11: compile-time error
}

void main() {/* Intentionally empty: Compile-time error tests. */}
