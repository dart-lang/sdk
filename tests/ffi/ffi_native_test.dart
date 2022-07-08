// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';
import 'dart:nativewrappers';

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  @FfiNative<Void Function(Handle, IntPtr)>('doesntmatter')
  external void goodHasReceiverHandle(int v);
}

class NativeClassy extends NativeFieldWrapperClass1 {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  @FfiNative<Void Function(Pointer<Void>, IntPtr)>('doesntmatter')
  external void goodHasReceiverPointer(int v);

  @FfiNative<Void Function(Handle, IntPtr)>('doesntmatter')
  external void goodHasReceiverHandle(int v);
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

void main() {
  /* Intentionally empty: Checks that the transform succeeds. */
}
