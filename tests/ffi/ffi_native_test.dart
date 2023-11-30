// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';

class Classy {
  @Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  @Native<Void Function(Handle, IntPtr)>(symbol: 'doesntmatter')
  external void goodHasReceiverHandle(int v);
}

base class NativeClassy extends NativeFieldWrapperClass1 {
  @Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
  external static int returnIntPtrStatic(int x);

  @Native<Void Function(Pointer<Void>, IntPtr)>(symbol: 'doesntmatter')
  external void goodHasReceiverPointer(int v);

  @Native<Void Function(Handle, IntPtr)>(symbol: 'doesntmatter')
  external void goodHasReceiverHandle(int v);
}

// Regression test: Ensure same-name Native functions don't collide in the
// top-level namespace, but instead live under their parent (Library, Class).
class A {
  @Native<Void Function()>(symbol: 'nop')
  external static void foo();
}

class B {
  @Native<Void Function()>(symbol: 'nop')
  external static void foo();
}

void main() {
  /* Intentionally empty: Checks that the transform succeeds. */
}
