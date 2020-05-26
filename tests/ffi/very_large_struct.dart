// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Large sample struct for dart:ffi library.
class VeryLargeStruct extends Struct {
  @Int8()
  external int a;

  @Int16()
  external int b;

  @Int32()
  external int c;

  @Int64()
  external int d;

  @Uint8()
  external int e;

  @Uint16()
  external int f;

  @Uint32()
  external int g;

  @Uint64()
  external int h;

  @IntPtr()
  external int i;

  @Double()
  external double j;

  @Float()
  external double k;

  external Pointer<VeryLargeStruct> parent;

  @IntPtr()
  external int numChildren;

  external Pointer<VeryLargeStruct> children;

  @Int8()
  external int smallLastField;
}
