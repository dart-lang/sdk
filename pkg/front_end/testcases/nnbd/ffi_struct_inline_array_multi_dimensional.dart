// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:ffi/ffi.dart";

class StructInlineArrayMultiDimensional extends Struct {
  @Array(2, 2, 2)
  external Array<Array<Array<Uint8>>> a0;
}

main() {
  final pointer = calloc<StructInlineArrayMultiDimensional>();
  final struct = pointer.ref;
  final array = struct.a0;
  final subArray = array[0];
  array[1] = subArray;
  calloc.free(pointer);
}
