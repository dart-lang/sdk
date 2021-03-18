// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

class Struct8BytesInlineArrayInt extends Struct {
  @Array(2)
  external Array<Pointer<Int8>> a0;
}

void main() {
  final arrayPointer = calloc<Struct8BytesInlineArrayInt>();

  final pointer = Pointer<Int8>.fromAddress(0xdeadbeef);

  final array = arrayPointer.ref.a0;
  print(arrayPointer);
  print(array);
  Expect.type<Array<Pointer<Int8>>>(array);
  Expect.equals(nullptr, array[0]);
  array[0] = pointer;
  Expect.equals(pointer, array[0]);

  calloc.free(arrayPointer);
}
