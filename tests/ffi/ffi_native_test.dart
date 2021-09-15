// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';
import 'dart:nativewrappers';

import 'package:expect/expect.dart';

// Error: FFI leaf call must not have Handle return type.
@FfiNative<Handle Function()>("foo", isLeaf: true)  //# 01: compile-time error
external Object foo();  //# 01: compile-time error

// Error: FFI leaf call must not have Handle argument types.
@FfiNative<Void Function(Handle)>("bar", isLeaf: true)  //# 02: compile-time error
external void bar(Object);  //# 02: compile-time error

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  // Error: FfiNative annotations can only be used on static functions.
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')  //# 03: compile-time error
  external int returnIntPtrMethod(int x);  //# 03: compile-time error
}

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

void main() { /* Intentionally empty: Compile-time error tests. */ }
