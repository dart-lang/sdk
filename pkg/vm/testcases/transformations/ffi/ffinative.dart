// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for @FfiNative related transformations.

// @dart=2.14

import 'dart:ffi';
import 'dart:nativewrappers';

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
external int returnIntPtr(int x);

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);
}

void main() {
  returnIntPtr(13);
  returnIntPtrLeaf(37);
  Classy.returnIntPtrStatic(0xDE);
}
