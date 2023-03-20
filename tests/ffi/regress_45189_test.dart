// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

import "package:ffi/ffi.dart";
import 'package:expect/expect.dart';

class Struct8BytesInlineArrayInt extends Struct {
  @Array(8)
  external Array<Uint8> a0;
}

void main() {
  final pointer = calloc<Struct8BytesInlineArrayInt>();
  final array = pointer.ref.a0;
  try {
    array[8]; // RangeError: Invalid value: Not in inclusive range 0..8: 8
  } on RangeError catch (exception) {
    final toString = exception.toString();
    Expect.equals(
        "RangeError: Invalid value: Not in inclusive range 0..7: 8", toString);
  }
  calloc.free(pointer);
}
